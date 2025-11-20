// ================================
// 🔹 Controller reativo GetX
// ================================
// ignore_for_file: avoid_print

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:io';

import './../data/models/servico_produto/subcategoria_servico_model.dart';
import './../data/models/servico_produto/fornecedor_categoria_model.dart';
import './../presentation/dialogs/show_novo_orcamento_bottom_sheet.dart';
import './../data/models/servico_produto/categoria_servico_model.dart';
import './../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../data/models/servico_produto/servico_foto_model.dart';
import './../data/models/model.dart';
import './app_controller.dart';

class FornecedorController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 🔹 Dados principais do fornecedor logado
  final Rx<FornecedorModel?> fornecedor = Rx<FornecedorModel?>(null);
  final RxList<FornecedorModel> fornecedores = <FornecedorModel>[].obs;

  /// 🔹 Serviços (coleção `fornecedor_servico`)
  final RxList<FornecedorProdutoServicoModel> servicosFornecedor =
      <FornecedorProdutoServicoModel>[].obs;

  final RxList<FornecedorServicoDetalhadoDto> servicosDetalhado =
      <FornecedorServicoDetalhadoDto>[].obs;

  final RxList<FornecedorProdutoServicoModel> allServicosFornecedor =
      <FornecedorProdutoServicoModel>[].obs;

  /// 🔹 Catálogo global (`servico_produto`)
  final RxList<ServicoProdutoModel> catalogoServicos = <ServicoProdutoModel>[].obs;

  /// 🔹 Fotos dos serviços (`servico_foto`)
  final RxList<ServicoFotoModel> fotosServico = <ServicoFotoModel>[].obs;

  final RxList<CategoriaServicoModel> categorias = <CategoriaServicoModel>[].obs;

  final RxList<SubcategoriaServicoModel> subCategorias = <SubcategoriaServicoModel>[].obs;

  final categoriasServico = <Map<String, dynamic>>[].obs;
  final subcategoriasServico = <Map<String, dynamic>>[].obs;
  StreamSubscription<QuerySnapshot>? _fornecedorSubscription;

  //tempoMedioResposta

  final isLoadingServicos = false.obs;
  final isLoadingFotos = false.obs;

  StreamSubscription? _solicitacoesSub;

  /// 🔹 Estatísticas do painel
  final ordenacaoSelecionada = 'status'.obs; // status | nome | recentes
  final RxInt solicitacoesPendentes = 0.obs;
  final RxInt mensagensNaoLidas = 0.obs;
  final RxDouble avaliacaoMedia = 0.0.obs;
  final RxDouble faturamentoMes = 0.0.obs;

  final RxInt totalFotos = 0.obs;
  final RxDouble tempoMedioResposta = 0.0.obs;

  /// 🔹 Estado geral
  final RxBool aptoParaOperar = false.obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;
  late AppController appController; // 🔹 Define, mas sem inicializar aqui

  final filtroNome = ''.obs;
  final filtroCidade = RxnString();
  final filtroCategoria = RxnString();
  final filtroAprovado = RxnBool();
  final filtroAtivo = RxnBool();

  final filtroAvaliacaoMinima = 0.0.obs;
  // 🔹 Dados auxiliares carregados de outras coleções
  final enderecos = <EnderecoUsuarioModel>[].obs;
  final categoriasFornecedor = <FornecedorCategoriaModel>[].obs;
  final List<StreamSubscription> _mensagemListeners = [];

  Future<void> logoutFornecedor() async {
    fornecedores.clear();
    servicosFornecedor.clear();
    servicosFornecedor.clear();
    servicosDetalhado.clear();
    allServicosFornecedor.clear();
    catalogoServicos.clear();
    fotosServico.clear();
    categorias.clear();
    subCategorias.clear();
    categoriasServico.clear();
    subcategoriasServico.clear();
    _solicitacoesSub?.cancel();
    fornecedor.value = null;
  }

  @override
  void onInit() {
    super.onInit();

    Future.delayed(Duration.zero, () {
      appController = Get.find<AppController>();
      ever(appController.usuarioLogado, (usuario) async {
        carregarTodosFornecedores();
      });
    });
  }

  Future<void> ouvirMensagensNaoLidas(String idFornecedor) async {
    debugPrint('\n📡 [MSG] Iniciando listener de mensagens NÃO lidas para $idFornecedor');

    // Cancelar listeners antigos
    for (var l in _mensagemListeners) {
      await l.cancel();
    }
    _mensagemListeners.clear();

    // Buscar todas as subcoleções "fornecedores" onde id_fornecedor = idFornecedor
    FirebaseFirestore.instance
        .collectionGroup("fornecedores")
        .where("id_fornecedor", isEqualTo: idFornecedor)
        .snapshots()
        .listen((fornecedorSnap) {
      debugPrint("📌 Fornecedor está em ${fornecedorSnap.docs.length} cotações.");

      mensagensNaoLidas.value = 0; // reset total

      for (final f in fornecedorSnap.docs) {
        final cotacaoRef = f.reference.parent.parent!; // pega a cotação pai
        final idCotacao = cotacaoRef.id;

        debugPrint("🔎 Listening mensagens da cotação $idCotacao");

        final sub = cotacaoRef
            .collection("fornecedores")
            .doc(idFornecedor)
            .collection("mensagens")
            .where("id_usuario", isNotEqualTo: idFornecedor) // recebidas
            .where("lido", isEqualTo: false)
            .snapshots()
            .listen((msgSnap) {
          final count = msgSnap.docs.length;

          debugPrint("💬 Cotação $idCotacao → não lidas: $count");

          mensagensNaoLidas.value += count;

          debugPrint("📊 Total atualizado: ${mensagensNaoLidas.value}");
        });

        _mensagemListeners.add(sub);
      }

      debugPrint("📌 Listeners ativos: ${_mensagemListeners.length}");
    });
  }

  /// 🟢 Inicia o listener do fornecedor logado
  void iniciarListenerFornecedor(String idFornecedor) {
    final db = FirebaseFirestore.instance;

    print('📡 Iniciando listener para fornecedor $idFornecedor...');

    // Cancela qualquer listener anterior
    _fornecedorSubscription?.cancel();

    _fornecedorSubscription = db
        .collection('fornecedor')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('ativo', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        fornecedor.value = FornecedorModel.fromMap(data);
        print('✅ Fornecedor atualizado: ${fornecedor.value!.razaoSocial}');
      } else {
        print('⚠️ Nenhum fornecedor ativo encontrado.');
        fornecedor.value = null;
      }
    }, onError: (e) {
      print('❌ Erro ao escutar fornecedor: $e');
    });
  }

  /// 🛑 Cancela o listener (ex: ao sair da conta)
  Future<void> pararListenerFornecedor() async {
    print('🛑 Parando listener de fornecedor...');
    await _fornecedorSubscription?.cancel();
    _fornecedorSubscription = null;
    fornecedor.value = null;
  }

  Future<List<ServicoProdutoModel>> buscarServicosFornecedorPorCategorias(
      String idFornecedor) async {
    final db = FirebaseFirestore.instance;

    try {
      // 1️⃣ Buscar todas as categorias vinculadas ao fornecedor
      final catSnap = await db
          .collection('fornecedor_categoria')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get();

      if (catSnap.docs.isEmpty) return [];

      // 2️⃣ Extrair todas as subcategorias (agora dentro do mesmo documento)
      final List<String> subcategoriasIds = [];
      for (var doc in catSnap.docs) {
        final data = doc.data();
        final subs = (data['subcategorias'] as List?)
                ?.map((s) => s['idSubcategoria']?.toString())
                .whereType<String>()
                .toList() ??
            [];
        subcategoriasIds.addAll(subs);
      }

      if (subcategoriasIds.isEmpty) return [];

      // 3️⃣ Buscar os serviços/produtos vinculados às subcategorias
      final servSnap = await db
          .collection('servico_produto')
          .where('id_subcategoria', whereIn: subcategoriasIds)
          .where('ativo', isEqualTo: true)
          .get();

      // 4️⃣ Converter o resultado em lista de modelos
      final servicos =
          servSnap.docs.map((d) => ServicoProdutoModel.fromMap({'id': d.id, ...d.data()})).toList();

      return servicos;
    } catch (e, s) {
      debugPrint('Erro ao buscar serviços do fornecedor: $e\n$s');
      return [];
    }
  }

  /// 🔹 Atualiza os dados de um fornecedor existente no Firestore
  Future<void> atualizarFornecedor(FornecedorModel fornecedor) async {
    try {
      await _db.collection('fornecedor').doc(fornecedor.idFornecedor).update(fornecedor.toMap());
    } catch (e) {
      throw Exception("Erro ao atualizar fornecedor: $e");
    }
  }

  /// 🔹 Faz upload de imagem para o Firebase Storage e retorna a URL pública
  Future<String> uploadBanner(File imageFile, {Uint8List? bytesWeb}) async {
    try {
      final String fileName =
          'banners_fornecedores/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final Reference ref = _storage.ref().child(fileName);

      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception("Erro ao enviar banner: $e");
    }
  }

  Future<void> carregarTodosFornecedores() async {
    try {
      carregando.value = true;
      erro.value = '';

      // ================================
      // 🔸 Fornecedores
      // ================================
      final fornecedoresSnap = await _db.collection('fornecedor').get();
      final listaFornecedores =
          fornecedoresSnap.docs.map((d) => FornecedorModel.fromMap(d.data())).toList();

      // ✅ ORDENAR: aprovados > pendentes > desativados, e nome A-Z
      listaFornecedores.sort((a, b) {
        // 1️⃣ Status ativo primeiro
        if (a.ativo != b.ativo) return b.ativo ? 1 : -1;

        // 2️⃣ Depois, aprovados primeiro
        if (a.aptoParaOperar != b.aptoParaOperar) return b.aptoParaOperar ? 1 : -1;

        // 3️⃣ Por fim, ordem alfabética
        return a.razaoSocial.toLowerCase().compareTo(b.razaoSocial.toLowerCase());
      });

      fornecedores.value = listaFornecedores;

      // ================================
      // 🔸 Endereços (subcoleção)
      // ================================
      final endSnap = await _db.collectionGroup('enderecos').get();
      enderecos.value = endSnap.docs.map((d) => EnderecoUsuarioModel.fromMap(d.data())).toList();

      // ================================
      // 🔸 Categorias do fornecedor
      // ================================
      final catSnap = await _db.collection('fornecedor_categoria').get();
      categoriasFornecedor.value =
          catSnap.docs.map((d) => FornecedorCategoriaModel.fromMap(d.data())).toList();

      // ================================
      // 🔸 Categorias principais
      // ================================
      final catServSnap = await _db.collection('categoria_servico').get();
      categoriasServico.value = catServSnap.docs
          .map((d) => {
                'id': d['id'],
                'nome': d['nome'],
                'descricao': d['descricao'],
                'ativo': d['ativo'],
              })
          .toList();

      categorias.value =
          catServSnap.docs.map((d) => CategoriaServicoModel.fromMap(d.data())).toList();

      // ================================
      // 🔸 Subcategorias
      // ================================
      final subcatSnap = await _db.collection('subcategoria_servico').get();
      subcategoriasServico.value = subcatSnap.docs
          .map((d) => {
                'id': d['id'],
                'nome': d['nome'],
                'id_categoria': d['id_categoria'],
                'descricao': d['descricao'],
                'ativo': d['ativo'],
              })
          .toList();

      subCategorias.value =
          subcatSnap.docs.map((d) => SubcategoriaServicoModel.fromMap(d.data())).toList();

      final servicosSnap = await _db.collection('fornecedor_servico').get();

      final listaServicos = servicosSnap.docs.map((doc) {
        final data = doc.data();
        final idDoc = doc.id;

        // 🔹 Captura os dois padrões de campos (camelCase e snake_case)
        final idFornecedor = data['id_fornecedor'] ?? data['id_fornecedor'] ?? '';
        final idProdutoServico = data['id_produto_servico'] ?? data['idProdutoServico'] ?? '';
        final idSubcategoria = data['id_subcategoria'] ?? data['idSubcategoria'];
        final preco = (data['preco'] as num?)?.toDouble() ?? 0.0;
        final precoPromocao = (data['preco_promocao'] as num?)?.toDouble();
        final ativo = data['ativo'] ?? true;

        return FornecedorProdutoServicoModel(
          id: idDoc, // ✅ usa o ID real do documento Firestore
          idFornecedor: idFornecedor,
          idProdutoServico: idProdutoServico,
          idSubcategoria: idSubcategoria,
          preco: preco,
          precoPromocao: precoPromocao,
          ativo: ativo,
          dataCadastro: FornecedorProdutoServicoModel.toDateTime(data['data_cadastro']),
        );
      }).toList();

      allServicosFornecedor.assignAll(listaServicos);
    } catch (e) {
      erro.value = 'Erro ao carregar fornecedores: $e';
    } finally {
      carregando.value = false;
    }
  }

  Future<FornecedorModel?> buscarFornecedor(String idUsuario) async {
    try {
      final snapshot = await _db
          .collection('fornecedor')
          .where('id_usuario', isEqualTo: idUsuario)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return FornecedorModel.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      debugPrint("❌ Erro ao buscar último evento: $e");
      return null;
    }
  }

  /// 🔹 Escuta em tempo real todas as solicitações com status = 'aguardando'
  Future<void> escutarSolicitacoesPendentes(String? idFornecedor) async {
    if (idFornecedor == null) return;

    // Cancela a escuta anterior, se já existir
    await _solicitacoesSub?.cancel();

    try {
      erro.value = '';

      _solicitacoesSub = _db
          .collectionGroup('fornecedores')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .where('status', isEqualTo: 'aguardando')
          .snapshots()
          .listen((snapshot) {
        // 🔹 Atualiza automaticamente o valor reativo
        solicitacoesPendentes.value = snapshot.docs.length;
      });
    } catch (e, s) {
      debugPrint('❌ Erro ao escutar solicitações pendentes: $e\n$s');
      erro.value = 'Erro ao escutar solicitações pendentes';
    }
  }

  // =============================================================
  // 🔸 LISTA FILTRADA
  // =============================================================
  List<FornecedorModel> get fornecedoresFiltrados {
    final resultado = fornecedores.where((f) {
      // 🔹 Busca endereço e categoria vinculados
      final endereco = enderecos.firstWhereOrNull((e) => e.idUsuario == f.idUsuario);
      final cat = categoriasFornecedor
          .firstWhereOrNull((c) => c.idFornecedor == f.idFornecedor)
          ?.idCategoria;

      // 🔹 Avalia filtros
      final matchNome = filtroNome.value.isEmpty ||
          f.razaoSocial.toLowerCase().contains(filtroNome.value.toLowerCase()) ||
          (f.descricao?.toLowerCase().contains(filtroNome.value.toLowerCase()) ?? false) ||
          f.email.toLowerCase().contains(filtroNome.value.toLowerCase());

      final matchCidade = filtroCidade.value == null ||
          (endereco?.nomeCidade?.toLowerCase().contains(filtroCidade.value!.toLowerCase()) ??
              false);

      final matchCategoria = filtroCategoria.value == null || cat == filtroCategoria.value;

      final matchStatusAprovacao =
          filtroAprovado.value == null || f.aptoParaOperar == filtroAprovado.value;

      final matchStatusAtivo = filtroAtivo.value == null || f.ativo == filtroAtivo.value;

      final passou =
          matchNome && matchCidade && matchCategoria && matchStatusAprovacao && matchStatusAtivo;

      return passou;
    }).toList();
    return resultado;
  }

  void ordenarFornecedores() {
    final lista = [...fornecedores];
    switch (ordenacaoSelecionada.value) {
      case 'nome':
        lista.sort((a, b) => a.razaoSocial.toLowerCase().compareTo(b.razaoSocial.toLowerCase()));
        break;
      case 'recentes':
        lista.sort((a, b) => (b.dataCadastro).compareTo(a.dataCadastro));
        break;
      default:
        lista.sort((a, b) {
          if (a.ativo != b.ativo) return b.ativo ? 1 : -1;
          if (a.aptoParaOperar != b.aptoParaOperar) return b.aptoParaOperar ? 1 : -1;
          return a.razaoSocial.toLowerCase().compareTo(b.razaoSocial.toLowerCase());
        });
    }
    fornecedores.assignAll(lista);
  }

  // =============================================================
  // 🔸 Aprovação e desativação
  // =============================================================
  Future<void> aprovarFornecedor(String idFornecedor) async {
    try {
      await _db.collection('fornecedor').doc(idFornecedor).update({'apto_para_operar': true});
      final f = fornecedores.firstWhereOrNull((x) => x.idFornecedor == idFornecedor);
      if (f != null) {
        fornecedores[fornecedores.indexOf(f)] = f.copyWith(aptoParaOperar: true);
      }
    } catch (e) {
      debugPrint('❌ Erro ao aprovar fornecedor $idFornecedor: $e');
    }
  }

  Future<void> desativarFornecedor(String idFornecedor) async {
    try {
      await _db.collection('fornecedor').doc(idFornecedor).update({'ativo': false});
      fornecedores.removeWhere((f) => f.idFornecedor == idFornecedor);
    } catch (e) {
      debugPrint('❌ Erro ao desativar fornecedor $idFornecedor: $e');
    }
  }

  Future<void> reprovarFornecedor(String idFornecedor) async {
    try {
      await _db.collection('fornecedor').doc(idFornecedor).update({'apto_para_operar': false});
      final f = fornecedores.firstWhereOrNull((x) => x.idFornecedor == idFornecedor);
      if (f != null) {
        fornecedores[fornecedores.indexOf(f)] = f.copyWith(aptoParaOperar: false);
      }
    } catch (e) {
      debugPrint('❌ Erro ao reprovar fornecedor $idFornecedor: $e');
    }
  }

  Future<void> ativarFornecedor(String idFornecedor) async {
    try {
      await _db.collection('fornecedor').doc(idFornecedor).update({'ativo': true});
      final f = fornecedores.firstWhereOrNull((x) => x.idFornecedor == idFornecedor);
      if (f != null) {
        fornecedores[fornecedores.indexOf(f)] = f.copyWith(ativo: true);
      }
    } catch (e) {
      debugPrint('❌ Erro ao ativar fornecedor $idFornecedor: $e');
    }
  }

  // ==========================================================
  // === 🔹 1. Busca produtos do fornecedor pelo CÓDIGO DO EVENTO
  // ==========================================================
  Future<void> carregarServicosPorEvento(String idEvento) async {
    try {
      carregando.value = true;
      erro.value = '';

      // 🔹 Busca orçamentos relacionados
      final orcamentosSnap =
          await _db.collection('orcamento').where('id_evento', isEqualTo: idEvento).get();

      if (orcamentosSnap.docs.isEmpty) {
        servicosFornecedor.clear();
        return;
      }

      // 🔹 Extrai os IDs dos documentos de fornecedor_servico vinculados ao evento
      final fornecedoresIds = orcamentosSnap.docs
          .map((d) => d.data()['id_servico_fornecido'])
          .where((id) => id != null && id.toString().isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      // 🚨 Correção: evita erro "whereIn vazio"
      if (fornecedoresIds.isEmpty) {
        servicosFornecedor.clear();
        return;
      }

      // 🚨 Correção: busca usando o ID REAL do documento
      final servicosSnap = await _db
          .collection('fornecedor_servico')
          .where(FieldPath.documentId, whereIn: fornecedoresIds)
          .get();

      final listaServicos = servicosSnap.docs
          .map((d) => FornecedorProdutoServicoModel.fromMap({
                'id': d.id,
                ...d.data(),
              }))
          .toList();

      servicosFornecedor.assignAll(listaServicos);

      // 🔹 Carrega catálogo e fotos
      final idsProdutos = listaServicos.map((s) => s.idProdutoServico).toList();
      await carregarCatalogoServicos();

      for (final fornecedorId in fornecedoresIds) {
        await carregarFotosServicos(idsProdutos, fornecedorId);
      }
    } catch (e, s) {
      erro.value = 'Erro ao carregar serviços do evento: $e';
      debugPrint('❌ $e\n$s');
    } finally {
      carregando.value = false;
    }
  }

  // ==========================================================
  // === 🔹 Escuta os serviços de um fornecedor específico
  // ==========================================================
  Future<void> escutarServicosFornecedor(String idFornecedor) async {
    if (idFornecedor.isEmpty) return;

    _db
        .collection('fornecedor_servico')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .snapshots()
        .listen((snapshot) async {
      final lista =
          snapshot.docs.map((d) => FornecedorProdutoServicoModel.fromMap(d.data())).toList();

      servicosFornecedor.assignAll(lista);

      final ids = lista.map((e) => e.idProdutoServico).toList();
      await carregarCatalogoServicos();
      await carregarFotosServicos(ids, idFornecedor);
      await escutarSolicitacoesPendentes(idFornecedor);
    });
  }

  Future<void> listarServicosFornecedor(String idFornecedor) async {
    try {
      carregando.value = true;
      erro.value = '';
      servicosDetalhado.clear();

      // 1️⃣ Buscar categorias do fornecedor
      final allSnap = await _db.collection('fornecedor_categoria').get();

      final catDocs = allSnap.docs.where((d) {
        final data = d.data();
        final idForn = (data['id_fornecedor'] ?? '').toString().trim();
        return idForn == idFornecedor.trim();
      }).toList();

      if (catDocs.isEmpty) {
        return;
      }

      // 2️⃣ Mapear subcategorias e vínculos
      final Map<String, String> mapaSubcategorias = {};
      final Map<String, String> mapaCategorias = {};
      final Map<String, String> mapaSubParaCat = {};
      final List<String> subcategoriasIds = [];

      for (var doc in catDocs) {
        final data = doc.data();
        final idCat = (data['id_categoria'] ?? '').toString();
        final nomeCat = (data['nome_categoria'] ?? '').toString();
        mapaCategorias[idCat] = nomeCat;

        final subs = (data['subcategorias'] as List?) ?? [];
        for (final sub in subs) {
          if (sub is Map<String, dynamic>) {
            final idSub = (sub['idSubcategoria'] ?? '').toString();
            final nomeSub = (sub['nomeSubcategoria'] ?? '').toString();
            if (idSub.isNotEmpty) {
              mapaSubcategorias[idSub] = nomeSub;
              mapaSubParaCat[idSub] = idCat;
              subcategoriasIds.add(idSub);
            }
          }
        }
      }

      if (subcategoriasIds.isEmpty) {
        return;
      }

      // 3️⃣ Buscar serviços das subcategorias
      final servSnap = await _db
          .collection('servico_produto')
          .where('id_subcategoria', whereIn: subcategoriasIds)
          .where('ativo', isEqualTo: true)
          .get();

      if (servSnap.docs.isEmpty) {
        return;
      }

      // 4️⃣ Montar lista final
      final List<FornecedorServicoDetalhadoDto> lista = [];

      for (final d in servSnap.docs) {
        final data = d.data();

        final idSub = (data['id_subcategoria'] ?? '').toString();
        final idCat = mapaSubParaCat[idSub] ?? '';
        final nomeServico = (data['nome'] ?? 'Serviço sem nome').toString();
        final descricao = (data['descricao'] ?? '').toString();
        final preco = (data['preco'] as num?)?.toDouble() ?? 0.0;
        final precoPromocao = (data['preco_promocao'] as num?)?.toDouble();
        final ativo = data['ativo'] ?? true;
        final nomeCat = mapaCategorias[idCat] ?? 'Sem categoria';
        final nomeSub = mapaSubcategorias[idSub] ?? 'Sem subcategoria';

        lista.add(FornecedorServicoDetalhadoDto(
            id: d.id,
            idFornecedor: idFornecedor,
            idProdutoServico: d.id, // ✅ correto agora
            idSubcategoria: idSub,
            nomeServico: nomeServico,
            descricaoServico: descricao,
            preco: preco,
            precoPromocao: precoPromocao,
            nomeCategoria: nomeCat,
            nomeSubcategoria: nomeSub,
            ativo: ativo,
            quantidade: 1));
      }

      servicosDetalhado.assignAll(lista);
    } catch (e, s) {
      erro.value = 'Erro ao carregar serviços: $e';
      debugPrint('❌ Erro ao listar serviços: $e\n$s');
    } finally {
      carregando.value = false;
    }
  }

  // ==========================================================
  // === 🔹 Carrega catálogo de serviços (coleção: servico_produto)
  // ==========================================================
  Future<void> carregarCatalogoServicos() async {
    final snapshot = await _db.collection('servico_produto').where('ativo', isEqualTo: true).get();

    final lista = snapshot.docs.map((d) {
      return ServicoProdutoModel.fromMap({
        'id': d.id,
        ...d.data(),
      });
    }).toList();

    catalogoServicos.assignAll(lista);
  }

  // ==========================================================
  // === 🔹 Carrega fotos dos serviços
  // ==========================================================
  Future<void> carregarFotosServicos(List<String> idsProdutoServico, String idFornecedor) async {
    if (idsProdutoServico.isEmpty) return;

    try {
      isLoadingFotos.value = true;

      final snapshot = await _db
          .collection('servico_foto')
          .where('id_produto_servico', whereIn: idsProdutoServico)
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get();

      final lista = snapshot.docs.map((d) => ServicoFotoModel.fromMap(d.data())).toList();
      fotosServico.assignAll(lista);
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar fotos: $e');
    } finally {
      isLoadingFotos.value = false;
    }
  }

  // ==========================================================
  // === 🔹 Busca um serviço pelo ID
  // ==========================================================
  ServicoProdutoModel? buscarServicoPorId(String idProdutoServico) {
    return catalogoServicos.firstWhereOrNull((s) => s.id == idProdutoServico);
  }

  // ==========================================================
  // === 🔹 Abre o BottomSheet para orçamento
  // ==========================================================
  Future<void> abrirCotacao({
    required BuildContext context,
    required String idEvento,
    required FornecedorProdutoServicoModel servicoFornecedor,
    String acao = 'solicitar',
    String? idOrcamento,
  }) async {
    final servicoProduto = buscarServicoPorId(servicoFornecedor.idProdutoServico);
    if (servicoProduto == null) {
      Get.snackbar(
        "Serviço não encontrado",
        "Não foi possível carregar o serviço solicitado.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final statusInicial = acao == 'reservar'
        ? StatusOrcamento.emNegociacao
        : acao == 'solicitar'
            ? StatusOrcamento.fechado
            : StatusOrcamento.pendente;

    await showNovoOrcamentoBottomSheet(
      context: context,
      idEvento: idEvento,
      idFornecedor: servicoFornecedor.idFornecedor,
      servico: servicoFornecedor,
      statusInicial: statusInicial,
      idOrcamento: idOrcamento,
    );
  }

  Future<void> carregarFornecedoresDoEvento(String idEvento) async {
    try {
      carregando.value = true;
      erro.value = '';

      // 🔹 Busca todos os orçamentos do evento
      final orcamentosSnap = await FirebaseFirestore.instance
          .collection('orcamento')
          .where('id_evento', isEqualTo: idEvento)
          .get();

      // 🔹 Extrai IDs válidos dos serviços fornecidos (filtrando nulos)
      final servicoFornecidoIds = orcamentosSnap.docs
          .map((d) => d.data()['id_servico_fornecido'])
          .where((id) => id != null && id.toString().isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      if (servicoFornecidoIds.isEmpty) {
        return;
      }

      final fornecedorServicosSnap = await FirebaseFirestore.instance
          .collection('fornecedor_servico')
          .where(FieldPath.documentId, whereIn: servicoFornecidoIds)
          .get();

      // 🔹 Busca fornecedores desses serviços (somente IDs válidos)
      final fornecidoIds = fornecedorServicosSnap.docs
          .map((d) => d.data()['id_fornecedor'])
          .where((id) => id != null && id.toString().isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final fornecedoresSnap = await FirebaseFirestore.instance
          .collection('fornecedor')
          .where(FieldPath.documentId, whereIn: fornecidoIds)
          .get();

      fornecedores.assignAll(fornecedoresSnap.docs.map((d) {
        return FornecedorModel.fromMap(d.data());
      }).toList());
    } catch (e) {
      erro.value = 'Erro ao carregar fornecedores: $e';
    } finally {
      carregando.value = false;
    }
  }

  Future<void> limparDuplicatasFornecedorCategoria() async {
    final db = FirebaseFirestore.instance;
    print('🧹 Iniciando limpeza da coleção fornecedor_categoria...');

    final snap = await db.collection('fornecedor_categoria').get();
    final docs = snap.docs;

    print('📄 Total de documentos encontrados: ${docs.length}');
    final Map<String, List<QueryDocumentSnapshot>> agrupados = {};

    // 🔹 Agrupa por fornecedor + categoria
    for (final doc in docs) {
      final data = doc.data();
      final fornecedor = data['id_fornecedor'] ?? '';
      final categoria = data['id_categoria'] ?? '';
      if (fornecedor.isEmpty || categoria.isEmpty) continue;

      final chave = '$fornecedor|$categoria';
      agrupados.putIfAbsent(chave, () => []);
      agrupados[chave]!.add(doc);
    }

    int duplicatasRemovidas = 0;

    for (final entry in agrupados.entries) {
      final lista = entry.value;
      if (lista.length <= 1) continue; // ✅ Sem duplicata

      // 🔹 Ordena por data_cadastro (mantém o mais antigo)
      lista.sort((a, b) {
        final da = (a.data() as Map<String, dynamic>)['data_cadastro'];
        final dbt = (b.data() as Map<String, dynamic>)['data_cadastro'];
        return da.toString().compareTo(dbt.toString());
      });

      final principal = lista.first;
      final idPrincipal = principal.id;
      final dataPrincipal = Map<String, dynamic>.from(principal.data() as Map<String, dynamic>);
      final subcategoriasPrincipais =
          List<Map<String, dynamic>>.from(dataPrincipal['subcategorias'] ?? []);

      print('🧩 Unificando duplicatas para fornecedor_categoria [$idPrincipal]');

      // 🔹 Mescla subcategorias das duplicatas
      for (final duplicada in lista.skip(1)) {
        final dataDup = Map<String, dynamic>.from(duplicada.data() as Map<String, dynamic>);
        final subs = List<Map<String, dynamic>>.from(dataDup['subcategorias'] ?? []);

        for (final sub in subs) {
          final idSub = sub['idSubcategoria'];
          final jaExiste = subcategoriasPrincipais.any((s) => s['idSubcategoria'] == idSub);
          if (!jaExiste) {
            subcategoriasPrincipais.add(sub);
            print('   ➕ Subcategoria adicionada: ${sub['nomeSubcategoria']}');
          }
        }

        // 🔹 Remove duplicata
        await db.collection('fornecedor_categoria').doc(duplicada.id).delete();
        duplicatasRemovidas++;
        print('   ❌ Documento duplicado removido: ${duplicada.id}');
      }

      // 🔹 Atualiza documento principal consolidado
      await db.collection('fornecedor_categoria').doc(idPrincipal).update({
        'subcategorias': subcategoriasPrincipais,
        'nome_categoria': dataPrincipal['nome_categoria'] ?? '',
      });

      print(
          '✅ Documento principal atualizado com ${subcategoriasPrincipais.length} subcategorias.');
    }

    print('🧹 Limpeza concluída! Duplicatas removidas: $duplicatasRemovidas');
  }

  // ==========================================================
  // === 🔹 Estatísticas básicas
  // ==========================================================

  Future<void> atualizarEstatisticasFornecedor() async {
    final f = fornecedor.value;
    if (f == null) return;

    try {
      // === 🔹 Solicitações pendentes / em negociação ===
      final orcSnap =
          await _db.collection('orcamento').where('id_fornecedor', isEqualTo: f.idFornecedor).get();

      final pendentes = orcSnap.docs.where((d) {
        final status = d['status']?.toString().toLowerCase();
        return status == 'pendente' || status == 'em_negociacao';
      }).length;
      solicitacoesPendentes.value = pendentes;

      // === 🔹 Serviços ativos ===
      final servSnap = await _db
          .collection('fornecedor_servico')
          .where('id_fornecedor', isEqualTo: f.idFornecedor)
          .where('ativo', isEqualTo: true)
          .get();
      servicosFornecedor
          .assignAll(servSnap.docs.map((d) => FornecedorProdutoServicoModel.fromMap(d.data())));

      // === 🔹 Mensagens não lidas ===
      final msgSnap = await _db
          .collectionGroup('mensagens')
          .where('id_fornecedor', isEqualTo: f.idFornecedor)
          .where('lida', isEqualTo: false)
          .get();
      mensagensNaoLidas.value = msgSnap.docs.length;

      // === 🔹 Avaliação média ===
      final avalSnap = await _db
          .collection('avaliacoes')
          .where('id_fornecedor', isEqualTo: f.idFornecedor)
          .get();

      if (avalSnap.docs.isNotEmpty) {
        final soma = avalSnap.docs.map((d) => (d['nota'] ?? 0).toDouble()).reduce((a, b) => a + b);
        avaliacaoMedia.value = soma / avalSnap.docs.length;
      } else {
        avaliacaoMedia.value = 0;
      }
    } catch (e, s) {
      debugPrint('❌ Erro ao atualizar estatísticas: $e\n$s');
    }
  }

  Future<List<Map<String, dynamic>>> buscarSolicitacoesPendentesDetalhadas() async {
    final f = fornecedor.value;
    if (f == null) return [];

    final resultado = <Map<String, dynamic>>[];

    // 🔹 Busca todos os registros "aguardando" em qualquer cotação
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('fornecedores')
        .where('id_fornecedor', isEqualTo: f.idFornecedor)
        .where('status', isEqualTo: 'aguardando')
        .get();

    for (final doc in snapshot.docs) {
      final dataFornecedor = doc.data();
      final cotacaoRef = doc.reference.parent.parent; // cotacao/{id}
      if (cotacaoRef == null) continue;

      final cotacaoSnap = await cotacaoRef.get();
      if (!cotacaoSnap.exists) continue;

      final dataCotacao = cotacaoSnap.data() as Map<String, dynamic>;

      resultado.add({
        'idCotacao': cotacaoRef.id,
        'categoriaNome': dataCotacao['categoria_nome'] ?? 'Cotação',
        'descricao': dataCotacao['observacao'] ?? '',
        'dataEnvio': dataCotacao['data_envio'],
        'dataLimite': dataCotacao['data_limite_resposta'],
        'status': dataCotacao['status'],
        'idEvento': dataCotacao['id_evento'],
        'idUsuarioSolicitante': dataCotacao['id_usuario_solicitante'],
        'prazoEntrega': dataFornecedor['prazo_entrega'],
        'condicaoPagamento': dataFornecedor['condicao_pagamento'],
        'observacaoFornecedor': dataFornecedor['observacao_fornecedor'],
        'nomeSolicitante': dataCotacao['nome_usuario_solicitante'],
        'valorEstimadoTotal': dataCotacao['valor_estimado_total'] ?? 0.0,
      });
    }

    return resultado;
  }

  // =============================================================
  // 🔸 FILTROS
  // =============================================================
  void aplicarFiltros({
    String? nome,
    String? cidade,
    String? categoria,
    bool? aprovado,
    bool? ativo,
  }) {
    filtroNome.value = nome ?? '';
    filtroCidade.value = cidade?.isEmpty ?? true ? null : cidade;
    filtroCategoria.value = categoria?.isEmpty ?? true ? null : categoria;
    filtroAprovado.value = aprovado;
    filtroAtivo.value = ativo;
  }

  void limparFiltros() {
    filtroNome.value = '';
    filtroCidade.value = null;
    filtroCategoria.value = null;
    filtroAprovado.value = null;
    filtroAtivo.value = null;
    update();
  }

  @override
  void onClose() {
    _solicitacoesSub?.cancel();
    pararListenerFornecedor();
    super.onClose();
  }
}
