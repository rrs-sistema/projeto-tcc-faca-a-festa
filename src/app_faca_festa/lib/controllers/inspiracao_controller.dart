import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import './../data/models/evento/inspiracao_model.dart';

class InspiracaoController extends GetxController {
  static const String _colecaoInspiracoes = 'inspiracoes';
  static const String _colecaoEventos = 'evento';
  static const String _subColecaoReferencias = 'referencias';
  static const String _subColecaoTarefas = 'tarefas';
  static const String _subColecaoOrcamento = 'orcamento';

  final RxList<InspiracaoModel> todasInspiracoes = <InspiracaoModel>[].obs;
  final RxList<InspiracaoModel> inspiracoesFiltradas = <InspiracaoModel>[].obs;
  final RxList<ReferenciaEventoModel> referenciasEvento = <ReferenciaEventoModel>[].obs;

  final RxList<Map<String, dynamic>> tarefasInspiracaoEvento = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> orcamentosInspiracaoEvento = <Map<String, dynamic>>[].obs;

  final RxSet<String> referenciasSalvasIds = <String>{}.obs;
  final RxSet<String> favoritasIds = <String>{}.obs;

  final RxBool loading = false.obs;
  final RxBool loadingReferencias = false.obs;
  final RxBool salvando = false.obs;
  final RxString categoriaSelecionada = 'Tudo'.obs;

  StreamSubscription? _subInspiracoes;
  StreamSubscription? _subReferencias;
  StreamSubscription? _subTarefas;
  StreamSubscription? _subOrcamento;

  String? _tipoEventoAtual;
  String? _eventoIdAtual;
  String? _userIdAtual;

  String? get eventoIdAtual => _eventoIdAtual;
  String? get userIdAtual => _userIdAtual;
  bool get possuiContextoEvento => _temContextoEvento;

  Future<void> carregarInspiracoes(
    String tipoEvento, {
    String? eventoId,
    String? userId,
  }) async {
    try {
      loading.value = true;

      await _subInspiracoes?.cancel();

      _tipoEventoAtual = _normalizeTipoEvento(tipoEvento);

      if (eventoId != null && eventoId.trim().isNotEmpty) {
        _eventoIdAtual = eventoId.trim();
      }

      if (userId != null && userId.trim().isNotEmpty) {
        _userIdAtual = userId.trim();
      }

      if (_temContextoEvento) {
        await _escutarSubcolecoesDoEvento();
      }

      if (kDebugMode) {
        print('🔍 Buscando inspirações...');
        print('🎉 Tipo de evento atual: $_tipoEventoAtual');
        print('📌 Evento atual: $_eventoIdAtual');
        print('👤 Usuário atual: $_userIdAtual');
      }

      _subInspiracoes =
          FirebaseFirestore.instance.collection(_colecaoInspiracoes).snapshots().listen(
        (snapshot) {
          if (kDebugMode) {
            print('📦 Documentos encontrados em inspirações: ${snapshot.docs.length}');
          }

          final lista = snapshot.docs
              .map((doc) => InspiracaoModel.fromFirestore(doc))
              .where(_pertenceAoTipoEventoAtual)
              .map(
                (insp) => insp.copyWith(
                  favorito: favoritasIds.contains(insp.id) || insp.favorito,
                ),
              )
              .toList();

          todasInspiracoes.assignAll(lista);
          _aplicarFiltroAtual();

          loading.value = false;

          if (kDebugMode) {
            print('✨ Inspirações carregadas na tela: ${lista.length}');
          }
        },
        onError: (e) {
          loading.value = false;
          if (kDebugMode) {
            print('❌ Erro ao escutar inspirações: $e');
          }
        },
      );
    } catch (e) {
      loading.value = false;
      if (kDebugMode) {
        print('❌ Erro ao carregar inspirações: $e');
      }
    }
  }

  Future<void> configurarContextoEvento({
    required String eventoId,
    required String userId,
  }) async {
    _eventoIdAtual = eventoId.trim();
    _userIdAtual = userId.trim();

    if (_temContextoEvento) {
      await _escutarSubcolecoesDoEvento();
    }

    if (kDebugMode) {
      print('🎯 Contexto da inspiração configurado');
      print('📌 eventoId: $_eventoIdAtual');
      print('👤 userId: $_userIdAtual');
    }
  }

  Future<void> recarregarReferenciasDoEvento() async {
    await _escutarSubcolecoesDoEvento();
  }

  void aplicarFiltro(String categoria) {
    categoriaSelecionada.value = categoria;
    _aplicarFiltroAtual();
  }

  List<String> categoriasDisponiveis() {
    final categorias = <String>{};

    for (final inspiracao in todasInspiracoes) {
      final categoria = (inspiracao.categoria ?? '').trim();
      if (categoria.isNotEmpty) {
        categorias.add(categoria);
      }
    }

    final lista = categorias.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ['Tudo', ...lista];
  }

  void _aplicarFiltroAtual() {
    final cat = _normalizarTextoFiltro(categoriaSelecionada.value);

    if (cat.isEmpty || cat == 'tudo') {
      inspiracoesFiltradas.assignAll(todasInspiracoes);
      inspiracoesFiltradas.refresh();
      return;
    }

    final filtradas = todasInspiracoes.where((i) {
      final categoria = _normalizarTextoFiltro(i.categoria ?? '');
      final categoriaId = _normalizarTextoFiltro(i.categoriaId ?? '');
      final tags = i.tags.map(_normalizarTextoFiltro).where((tag) => tag.isNotEmpty).toList();

      return categoria == cat || categoriaId == cat || tags.contains(cat);
    }).toList();

    inspiracoesFiltradas.assignAll(filtradas);
    inspiracoesFiltradas.refresh();

    if (kDebugMode) {
      print('🏷️ Categoria selecionada: ${categoriaSelecionada.value}');
      print('🎯 Inspirações filtradas: ${filtradas.length}');
    }
  }

  Future<void> salvarInspiracaoNoEvento(
    InspiracaoModel inspiracao, {
    bool favorito = false,
    bool showSuccessMessage = true,
    String status = 'salva',
    String prioridade = 'media',
    String anotacao = '',
  }) async {
    if (!_temContextoEvento) {
      EasyLoading.showInfo('Carregue o evento antes de salvar uma inspiração.');
      return;
    }

    try {
      salvando.value = true;

      if (showSuccessMessage) {
        EasyLoading.show(status: 'Salvando inspiração...');
      }

      final docId = _referenciaDocId(inspiracao.id);

      await _referenciasCollection.doc(docId).set(
            inspiracao.toReferenciaEventoMap(
              eventoId: _eventoIdAtual!,
              userId: _userIdAtual!,
              favorito: favorito || favoritasIds.contains(inspiracao.id),
              status: status,
              prioridade: prioridade,
              anotacao: anotacao,
              origem: 'inspiracao_app',
            ),
            SetOptions(merge: true),
          );

      referenciasSalvasIds.add(inspiracao.id);

      if (favorito) {
        favoritasIds.add(inspiracao.id);
      }

      referenciasSalvasIds.refresh();
      favoritasIds.refresh();

      _atualizarFavoritosLocais();
      _aplicarFiltroAtual();

      if (showSuccessMessage) {
        EasyLoading.showSuccess('Inspiração salva no evento ✨');
      }
    } catch (e) {
      EasyLoading.showError('Erro ao salvar inspiração');
      if (kDebugMode) {
        print('❌ Erro ao salvar inspiração no evento: $e');
      }
    } finally {
      salvando.value = false;
      EasyLoading.dismiss();
    }
  }

  Future<void> alternarFavorito(String id) async {
    final index = todasInspiracoes.indexWhere((i) => i.id == id);
    if (index == -1) return;

    if (!_temContextoEvento) {
      EasyLoading.showInfo('Carregue o evento antes de favoritar uma inspiração.');
      return;
    }

    final inspiracao = todasInspiracoes[index];
    final novoFavorito = !favoritasIds.contains(id);

    try {
      final docId = _referenciaDocId(id);
      final docRef = _referenciasCollection.doc(docId);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set(
          inspiracao.toReferenciaEventoMap(
            eventoId: _eventoIdAtual!,
            userId: _userIdAtual!,
            favorito: novoFavorito,
            status: 'salva',
            prioridade: 'media',
            origem: 'inspiracao_app',
          ),
        );
        referenciasSalvasIds.add(id);
      } else {
        await docRef.set(
          {
            'favorito': novoFavorito,
            'atualizadoEm': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      if (novoFavorito) {
        favoritasIds.add(id);
      } else {
        favoritasIds.remove(id);
      }

      favoritasIds.refresh();
      referenciasSalvasIds.refresh();

      _atualizarFavoritosLocais();
      _aplicarFiltroAtual();
    } catch (e) {
      EasyLoading.showError('Erro ao favoritar inspiração');
      if (kDebugMode) {
        print('❌ Erro ao favoritar inspiração: $e');
      }
    }
  }

  Future<void> adicionarReferenciaPessoal() async {
    if (!_temContextoEvento) {
      EasyLoading.showInfo('Carregue o evento antes de adicionar uma referência pessoal.');
      return;
    }

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

      if (image == null) {
        EasyLoading.showInfo('Nenhuma imagem selecionada');
        return;
      }

      EasyLoading.show(status: 'Enviando imagem...');

      final file = File(image.path);
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();

      final storageRef = FirebaseStorage.instance.ref().child(
            'eventos/$_eventoIdAtual/referencias/$_userIdAtual/$fileName.jpg',
          );

      await storageRef.putFile(file);
      final url = await storageRef.getDownloadURL();

      final docRef = _referenciasCollection.doc();

      await docRef.set({
        'id': docRef.id,
        'eventoId': _eventoIdAtual,
        'idEvento': _eventoIdAtual,
        'userId': _userIdAtual,
        'idUsuario': _userIdAtual,
        'inspiracaoId': '',
        'titulo': 'Minha referência pessoal',
        'descricao': '',
        'imagemUrl': url,
        'categoria': 'Pessoal',
        'categoriaId': 'pessoal',
        'tags': ['pessoal'],
        'galeriaUrls': <String>[],
        'paletaCores': <String>[],
        'favorito': false,
        'status': 'salva',
        'prioridade': 'media',
        'origem': 'galeria_usuario',
        'anotacao': '',
        'ativo': true,
        'deletado': false,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      EasyLoading.showSuccess('Referência adicionada ao evento ✨');
    } catch (e) {
      EasyLoading.showError('Erro ao adicionar referência');
      if (kDebugMode) {
        print('❌ Erro ao adicionar referência pessoal: $e');
      }
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> gerarChecklistDaInspiracao(InspiracaoModel inspiracao) async {
    if (!_temContextoEvento) {
      EasyLoading.showInfo('Carregue o evento antes de criar checklist.');
      return;
    }

    try {
      EasyLoading.show(status: 'Criando checklist...');

      final batch = FirebaseFirestore.instance.batch();

      final tarefas = inspiracao.tarefasSugeridas.isNotEmpty
          ? inspiracao.tarefasSugeridas
          : [
              {
                'titulo': 'Separar referência visual: ${inspiracao.titulo}',
                'descricao':
                    'Usar esta inspiração como base para conversar com fornecedores e organizar os detalhes do evento.',
                'categoria': inspiracao.categoria ?? 'Inspiração',
              },
              {
                'titulo': 'Solicitar orçamento para ${inspiracao.categoria ?? 'esta ideia'}',
                'descricao':
                    'Enviar a referência visual para pelo menos um fornecedor e comparar valores.',
                'categoria': inspiracao.categoria ?? 'Inspiração',
              },
            ];

      for (final tarefa in tarefas) {
        final docRef = _tarefasCollection.doc();
        final titulo = (tarefa['titulo'] ?? tarefa['nome'] ?? '').toString();

        batch.set(docRef, {
          'id': docRef.id,
          'eventoId': _eventoIdAtual,
          'idEvento': _eventoIdAtual,
          'userId': _userIdAtual,
          'idUsuario': _userIdAtual,
          'nome': titulo,
          'titulo': titulo,
          'descricao': (tarefa['descricao'] ?? '').toString(),
          'categoria': (tarefa['categoria'] ?? inspiracao.categoria ?? '').toString(),
          'statusConclusao': false,
          'concluida': false,
          'origem': 'inspiracao',
          'inspiracaoId': inspiracao.id,
          'referenciaImagemUrl': inspiracao.imagemUrl,
          'ativo': true,
          'deletado': false,
          'criadoEm': FieldValue.serverTimestamp(),
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      await salvarInspiracaoNoEvento(inspiracao, showSuccessMessage: false);

      EasyLoading.showSuccess('Checklist criado a partir da inspiração ✨');
    } catch (e) {
      EasyLoading.showError('Erro ao criar checklist');
      if (kDebugMode) {
        print('❌ Erro ao criar checklist da inspiração: $e');
      }
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> gerarOrcamentoDaInspiracao(InspiracaoModel inspiracao) async {
    if (!_temContextoEvento) {
      EasyLoading.showInfo('Carregue o evento antes de criar orçamento.');
      return;
    }

    try {
      EasyLoading.show(status: 'Criando orçamento...');

      final batch = FirebaseFirestore.instance.batch();

      final itens = inspiracao.itensOrcamentoSugeridos.isNotEmpty
          ? inspiracao.itensOrcamentoSugeridos
          : [
              {
                'categoria': inspiracao.categoria ?? 'Inspiração',
                'item': inspiracao.titulo,
                'custoEstimado': 0.0,
                'custoReal': 0.0,
              }
            ];

      for (final item in itens) {
        final docRef = _orcamentoCollection.doc();

        final custoEstimado = _toDouble(item['custoEstimado']);
        final custoReal = _toDouble(item['custoReal']);

        batch.set(docRef, {
          'id': docRef.id,
          'eventoId': _eventoIdAtual,
          'idEvento': _eventoIdAtual,
          'userId': _userIdAtual,
          'idUsuario': _userIdAtual,
          'categoria': (item['categoria'] ?? inspiracao.categoria ?? '').toString(),
          'item': (item['item'] ?? item['nome'] ?? inspiracao.titulo).toString(),
          'descricao': (item['descricao'] ?? '').toString(),
          'custoEstimado': custoEstimado,
          'custoReal': custoReal,
          'valorPago': 0.0,
          'formaPagamento': '',
          'statusPagamento': 'pendente',
          'pago': false,
          'origem': 'inspiracao',
          'inspiracaoId': inspiracao.id,
          'referenciaImagemUrl': inspiracao.imagemUrl,
          'ativo': true,
          'deletado': false,
          'criadoEm': FieldValue.serverTimestamp(),
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      await salvarInspiracaoNoEvento(inspiracao, showSuccessMessage: false);

      EasyLoading.showSuccess('Orçamento criado a partir da inspiração ✨');
    } catch (e) {
      EasyLoading.showError('Erro ao criar orçamento');
      if (kDebugMode) {
        print('❌ Erro ao criar orçamento da inspiração: $e');
      }
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> atualizarReferenciaPlanejamento({
    required String referenciaId,
    String? status,
    String? prioridade,
    String? anotacao,
    bool? favorito,
  }) async {
    if (!_temContextoEvento) {
      EasyLoading.showInfo('Carregue o evento antes de editar a referência.');
      return;
    }

    final dados = <String, dynamic>{
      'atualizadoEm': FieldValue.serverTimestamp(),
    };

    if (status != null) dados['status'] = status;
    if (prioridade != null) dados['prioridade'] = prioridade;
    if (anotacao != null) dados['anotacao'] = anotacao;
    if (favorito != null) dados['favorito'] = favorito;

    try {
      await _referenciasCollection.doc(referenciaId).set(dados, SetOptions(merge: true));
      EasyLoading.showSuccess('Referência atualizada');
    } catch (e) {
      EasyLoading.showError('Erro ao atualizar referência');
      if (kDebugMode) {
        print('❌ Erro ao atualizar referência: $e');
      }
    }
  }

  Future<void> removerReferenciaDoEvento(String referenciaId) async {
    if (!_temContextoEvento) return;

    try {
      await _referenciasCollection.doc(referenciaId).set({
        'ativo': false,
        'deletado': true,
        'status': 'descartada',
        'atualizadoEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      EasyLoading.showSuccess('Referência removida');
    } catch (e) {
      EasyLoading.showError('Erro ao remover referência');
      if (kDebugMode) {
        print('❌ Erro ao remover referência: $e');
      }
    }
  }

  int totalTarefasPorInspiracao(String inspiracaoId) {
    if (inspiracaoId.isEmpty) return 0;
    return tarefasInspiracaoEvento
        .where((t) => (t['inspiracaoId'] ?? '').toString() == inspiracaoId)
        .length;
  }

  int tarefasConcluidasPorInspiracao(String inspiracaoId) {
    if (inspiracaoId.isEmpty) return 0;
    return tarefasInspiracaoEvento.where((t) {
      final pertence = (t['inspiracaoId'] ?? '').toString() == inspiracaoId;
      final concluida = t['concluida'] == true || t['statusConclusao'] == true;
      return pertence && concluida;
    }).length;
  }

  int totalOrcamentosPorInspiracao(String inspiracaoId) {
    if (inspiracaoId.isEmpty) return 0;
    return orcamentosInspiracaoEvento
        .where((o) => (o['inspiracaoId'] ?? '').toString() == inspiracaoId)
        .length;
  }

  double valorOrcadoPorInspiracao(String inspiracaoId) {
    if (inspiracaoId.isEmpty) return 0.0;

    return orcamentosInspiracaoEvento
        .where((o) => (o['inspiracaoId'] ?? '').toString() == inspiracaoId)
        .fold<double>(0.0, (total, o) {
      final real = _toDouble(o['custoReal']);
      final estimado = _toDouble(o['custoEstimado']);
      return total + (real > 0 ? real : estimado);
    });
  }

  Future<void> _escutarSubcolecoesDoEvento() async {
    await _escutarReferenciasDoEvento();
    await _escutarTarefasDoEvento();
    await _escutarOrcamentoDoEvento();
  }

  Future<void> _escutarReferenciasDoEvento() async {
    await _subReferencias?.cancel();

    if (!_temContextoEvento) {
      referenciasEvento.clear();
      referenciasSalvasIds.clear();
      favoritasIds.clear();
      return;
    }

    loadingReferencias.value = true;

    _subReferencias = _referenciasCollection.snapshots().listen(
      (snapshot) {
        final referencias =
            snapshot.docs.map((d) => ReferenciaEventoModel.fromFirestore(d)).where((ref) {
          final mesmoUsuario = ref.userId.isEmpty || ref.userId == _userIdAtual;
          return ref.ativo && !ref.deletado && mesmoUsuario;
        }).toList();

        referenciasEvento.assignAll(referencias);
        loadingReferencias.value = false;

        final salvas = <String>{};
        final favoritas = <String>{};

        for (final referencia in referencias) {
          if (referencia.inspiracaoId.isEmpty) continue;

          salvas.add(referencia.inspiracaoId);

          if (referencia.favorito) {
            favoritas.add(referencia.inspiracaoId);
          }
        }

        referenciasSalvasIds
          ..clear()
          ..addAll(salvas);

        favoritasIds
          ..clear()
          ..addAll(favoritas);

        referenciasSalvasIds.refresh();
        favoritasIds.refresh();

        _atualizarFavoritosLocais();
        _aplicarFiltroAtual();

        if (kDebugMode) {
          print('🖼️ Referências do evento carregadas: ${referencias.length}');
        }
      },
      onError: (e) {
        loadingReferencias.value = false;
        if (kDebugMode) {
          print('❌ Erro ao escutar referências do evento: $e');
        }
      },
    );
  }

  Future<void> _escutarTarefasDoEvento() async {
    await _subTarefas?.cancel();

    if (!_temContextoEvento) {
      tarefasInspiracaoEvento.clear();
      return;
    }

    _subTarefas = _tarefasCollection.snapshots().listen(
      (snapshot) {
        final tarefas = snapshot.docs.map((doc) {
          final data = doc.data();
          return {'id': doc.id, ...data};
        }).where((tarefa) {
          final ativo = tarefa['ativo'] != false;
          final deletado = tarefa['deletado'] == true;
          final eventoId = (tarefa['eventoId'] ?? tarefa['idEvento'] ?? '').toString();
          final userId = (tarefa['userId'] ?? tarefa['idUsuario'] ?? '').toString();

          final mesmoEvento = eventoId.isEmpty || eventoId == _eventoIdAtual;
          final mesmoUsuario = userId.isEmpty || userId == _userIdAtual;

          return ativo && !deletado && mesmoEvento && mesmoUsuario;
        }).toList();

        tarefasInspiracaoEvento.assignAll(tarefas);
        tarefasInspiracaoEvento.refresh();

        if (kDebugMode) {
          print('✅ Tarefas ligadas às inspirações carregadas: ${tarefas.length}');
        }
      },
      onError: (e) {
        if (kDebugMode) {
          print('❌ Erro ao escutar tarefas do evento: $e');
        }
      },
    );
  }

  Future<void> _escutarOrcamentoDoEvento() async {
    await _subOrcamento?.cancel();

    if (!_temContextoEvento) {
      orcamentosInspiracaoEvento.clear();
      return;
    }

    _subOrcamento = _orcamentoCollection.snapshots().listen(
      (snapshot) {
        final itens = snapshot.docs.map((doc) {
          final data = doc.data();
          return {'id': doc.id, ...data};
        }).where((item) {
          final ativo = item['ativo'] != false;
          final deletado = item['deletado'] == true;
          final eventoId = (item['eventoId'] ?? item['idEvento'] ?? '').toString();
          final userId = (item['userId'] ?? item['idUsuario'] ?? '').toString();

          final mesmoEvento = eventoId.isEmpty || eventoId == _eventoIdAtual;
          final mesmoUsuario = userId.isEmpty || userId == _userIdAtual;

          return ativo && !deletado && mesmoEvento && mesmoUsuario;
        }).toList();

        orcamentosInspiracaoEvento.assignAll(itens);
        orcamentosInspiracaoEvento.refresh();

        if (kDebugMode) {
          print('💰 Orçamentos ligados às inspirações carregados: ${itens.length}');
        }
      },
      onError: (e) {
        if (kDebugMode) {
          print('❌ Erro ao escutar orçamento do evento: $e');
        }
      },
    );
  }

  void _atualizarFavoritosLocais() {
    final atualizadas = todasInspiracoes.map((insp) {
      return insp.copyWith(favorito: favoritasIds.contains(insp.id));
    }).toList();

    todasInspiracoes.assignAll(atualizadas);
  }

  bool _pertenceAoTipoEventoAtual(InspiracaoModel inspiracao) {
    if (!inspiracao.ativo) return false;

    final tipoAtual = _tipoEventoAtual ?? '';
    if (tipoAtual.isEmpty) return true;

    final tipoEvento = _normalizeTipoEvento(inspiracao.tipoEvento);
    final tipoEventoId = _normalizeTipoEvento(inspiracao.tipoEventoId);
    final tipoEventoNormalizado = _normalizeTipoEvento(inspiracao.tipoEventoNormalizado);

    final documentoAntigoSemTipo =
        tipoEvento.isEmpty && tipoEventoId.isEmpty && tipoEventoNormalizado.isEmpty;

    if (documentoAntigoSemTipo) {
      return true;
    }

    return tipoEvento == tipoAtual ||
        tipoEventoId == tipoAtual ||
        tipoEventoNormalizado == tipoAtual ||
        tipoEvento == 'todos' ||
        tipoEventoId == 'todos' ||
        tipoEventoNormalizado == 'todos' ||
        tipoEventoId == 'geral' ||
        tipoEvento == 'geral' ||
        tipoEventoNormalizado == 'geral';
  }

  bool get _temContextoEvento {
    return (_eventoIdAtual != null && _eventoIdAtual!.isNotEmpty) &&
        (_userIdAtual != null && _userIdAtual!.isNotEmpty);
  }

  CollectionReference<Map<String, dynamic>> get _referenciasCollection {
    return FirebaseFirestore.instance
        .collection(_colecaoEventos)
        .doc(_eventoIdAtual!)
        .collection(_subColecaoReferencias);
  }

  CollectionReference<Map<String, dynamic>> get _tarefasCollection {
    return FirebaseFirestore.instance
        .collection(_colecaoEventos)
        .doc(_eventoIdAtual!)
        .collection(_subColecaoTarefas);
  }

  CollectionReference<Map<String, dynamic>> get _orcamentoCollection {
    return FirebaseFirestore.instance
        .collection(_colecaoEventos)
        .doc(_eventoIdAtual!)
        .collection(_subColecaoOrcamento);
  }

  String _referenciaDocId(String inspiracaoId) {
    return 'insp_${_safeDocId(_userIdAtual!)}_${_safeDocId(inspiracaoId)}';
  }

  String _safeDocId(String value) {
    return value
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll('#', '_')
        .replaceAll('?', '_');
  }

  String _normalizeTipoEvento(String tipo) {
    var normalized = tipo.trim().toLowerCase();

    const accents = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    accents.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    normalized = normalized.replaceAll(RegExp(r'_+'), '_');

    if (normalized.startsWith('_')) {
      normalized = normalized.substring(1);
    }
    if (normalized.endsWith('_')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  String _normalizarTextoFiltro(String value) {
    var text = value.trim().toLowerCase();

    const accents = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    accents.forEach((key, value) {
      text = text.replaceAll(key, value);
    });

    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();

    var text = value.toString().trim();
    if (text.isEmpty) return 0.0;

    text = text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    return double.tryParse(text) ?? 0.0;
  }

  @override
  void onClose() {
    _subInspiracoes?.cancel();
    _subReferencias?.cancel();
    _subTarefas?.cancel();
    _subOrcamento?.cancel();
    super.onClose();
  }
}
