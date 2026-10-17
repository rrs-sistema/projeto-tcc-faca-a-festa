import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/services/receitas_salvas_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/conversao_orcamento_service.dart';
import 'dart:async';
import 'package:app_faca_festa/domain/services/compromisso_planejamento_service.dart';
import 'package:app_faca_festa/domain/services/revisao_cardapio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/cardapio/cardapio_item_model.dart';
import '../../models/convidado/convidado_model.dart';
import '../../models/evento/calculadora_festa_item_model.dart';
import '../../models/evento/calculadora_festa_model.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/registro_consumo_calculadora.dart';

/// Datasource de persistência das simulações da calculadora.
///
/// Centraliza os acessos ao Firestore
/// relacionados à coleção `calculadora_festa`.
class CalculadoraFestaRemoteDatasource {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const String collectionCalculadora = 'calculadora_festa';
  static const String collectionConvidado = 'convidado';
  static const String collectionCardapios = 'cardapios';
  static const String collectionOrcamentos = 'orcamento';
  static const String subcollectionItens = 'itens';

  CalculadoraFestaRemoteDatasource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _db = firestore,
        _auth = auth;

  CollectionReference<Map<String, dynamic>> get _calculadoraCollection {
    return _db.collection(collectionCalculadora);
  }

  Stream<Map<String, dynamic>> observarOperacaoEvento(String idEvento) =>
      _db.collection('calculadora_operacao').doc(idEvento).snapshots().map((s) {
        final dados = s.data() ?? <String, dynamic>{};
        const OperacaoCalculadoraService().validarDocumento(dados);
        return dados;
      });

  Future<Map<String, dynamic>> alterarOperacaoEvento(
      String idEvento, Map<String, dynamic> acao) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || idEvento.isEmpty) {
      throw StateError('Entre na sua conta e selecione o evento.');
    }
    final ref = _db.collection('calculadora_operacao').doc(idEvento);
    return _db.runTransaction((tx) async {
      final evento = await tx.get(_db.collection('evento').doc(idEvento));
      if (evento.data()?['id_usuario'] != uid) {
        throw StateError('Somente o organizador pode alterar o planejamento.');
      }
      final doc = await tx.get(ref);
      if (acao['tipo'] == 'refeicao' ||
          (acao['tipo'] == 'reservar' &&
              OperacaoCalculadoraService.numero(OperacaoCalculadoraService.mapa(
                      acao['reserva'])['quantidade']) >
                  0)) {
        final reserva = OperacaoCalculadoraService.mapa(acao['reserva']);
        final menuId =
            (acao['id_cardapio'] ?? reserva['refeicao'])?.toString() ?? '';
        final menu = await tx.get(_db.collection('cardapios').doc(menuId));
        if (menu.data()?['id_evento'] != idEvento ||
            menu.data()?['ativo'] == false) {
          throw StateError('A refeição mudou ou foi removida.');
        }
        if (acao['tipo'] == 'reservar' &&
            OperacaoCalculadoraService.numero(reserva['quantidade']) > 0) {
          final item = await tx.get(menu.reference
              .collection('itens')
              .doc(reserva['item'].toString()));
          if (!item.exists ||
              item.data()?['nome'] != reserva['nome'] ||
              (item.data()?['publico_alvo'] ?? 'todos') != reserva['publico']) {
            throw StateError('O item mudou. Reabra a reserva.');
          }
        }
      }
      final novo =
          const OperacaoCalculadoraService().aplicar(doc.data() ?? {}, acao);
      final data = {...novo, 'id_evento': idEvento, 'id_usuario': uid};
      tx.set(ref, data);
      return data;
    });
  }

  Future<void> registrarConsumo(
      String idCalculo, RegistroConsumoCalculadora registro) async {
    registro.validar();
    final uid = _auth.currentUser?.uid;
    if (uid == null ||
        registro.regra.id.isEmpty ||
        registro.regra.id.length > 200) {
      throw StateError('Entre na sua conta e selecione um item válido.');
    }
    final ref = _calculoRef(idCalculo);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final dados = doc.data();
      if (dados == null ||
          dados['id_evento'] != registro.idEvento ||
          dados['id_usuario'] != uid) {
        throw StateError(
            'A simulação não pertence a este organizador e evento.');
      }
      final registros =
          Map<String, dynamic>.from(dados['consumo_observado'] as Map? ?? {});
      if (!registros.containsKey(registro.regra.id) &&
          registros.length >= 100) {
        throw StateError('Limite de registros por simulação atingido.');
      }
      registros[registro.regra.id] = registro.toMap();
      tx.update(ref, {
        'consumo_observado': registros,
        'consumo_registrado_em': DateTime.now().toUtc().toIso8601String()
      });
    });
  }

  Future<List<RegistroConsumoCalculadora>> listarConsumosDoOrganizador() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    final docs = await _calculadoraCollection
        .where('id_usuario', isEqualTo: uid)
        .orderBy('consumo_registrado_em', descending: true)
        .limit(100)
        .get();
    final registros = <RegistroConsumoCalculadora>[];
    for (final doc in docs.docs) {
      final mapa = doc.data()['consumo_observado'];
      if (mapa is! Map) continue;
      for (final raw in mapa.values) {
        try {
          final r = RegistroConsumoCalculadora.fromMap(
              Map<String, dynamic>.from(raw as Map));
          if (r.idEvento == doc.data()['id_evento']) registros.add(r);
        } on Object {
          // Documentos legados/malformados não participam da calibração.
        }
      }
    }
    return registros;
  }

  Future<List<ItemEstimativaFinanceira>> listarReceitasDoOrganizador() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    final docs = await _calculadoraCollection
        .where('id_usuario', isEqualTo: uid)
        .orderBy('data_atualizacao', descending: true)
        .limit(100)
        .get();
    return const ReceitasSalvasCalculadoraService().extrair(
        docs.docs.map((doc) => {...doc.data(), 'id_calculo': doc.id}).toList());
  }

  Future<void> salvarConferenciaFinanceira(
      String id, Map<String, dynamic> conferencia) {
    if (!['revisar', 'realizado', 'sem_itens'].contains(conferencia['modo'])) {
      throw ArgumentError('Conferência inválida.');
    }
    return _db
        .collection(collectionOrcamentos)
        .doc(id)
        .update({'calculadora_conferencia_financeira': conferencia});
  }

  Future<void> salvarLimiteEvento(String id, double? limite) =>
      _db.collection('evento').doc(id).update({'custo_estimado': limite});

  Future<void> salvarCoberturaOrcamento(String id, List<String> identidades) =>
      _db.collection(collectionOrcamentos).doc(id).update({
        'calculadora_cobre_itens': identidades.toSet().toList(),
      });

  Future<List<Map<String, dynamic>>> listarCompromissosDoEvento(
      String idEvento) async {
    final snapshot = await _db
        .collection(collectionOrcamentos)
        .where('id_evento', isEqualTo: idEvento)
        .get();
    final resultados = await Future.wait(snapshot.docs.map((doc) async {
      final gastos = await doc.reference.collection('orcamento_gasto').get();
      return const CompromissoPlanejamentoService().mapear(doc.id, doc.data(),
          gastos: gastos.docs.map((g) => g.data()).toList());
    }));
    return resultados.whereType<Map<String, dynamic>>().toList();
  }

  Stream<List<Map<String, dynamic>>> observarCompromissosDoEvento(
      String idEvento) {
    late StreamController<List<Map<String, dynamic>>> saida;
    StreamSubscription? pais;
    final filhos = <StreamSubscription>[];
    var versao = 0;
    saida = StreamController<List<Map<String, dynamic>>>(onListen: () {
      pais = _db
          .collection(collectionOrcamentos)
          .where('id_evento', isEqualTo: idEvento)
          .snapshots()
          .listen((snapshot) async {
        final atual = ++versao;
        final antigos = filhos.toList();
        filhos.clear();
        await Future.wait(antigos.map((s) => s.cancel()));
        if (atual != versao || saida.isClosed) return;
        final cache = <String, Map<String, dynamic>?>{};
        if (snapshot.docs.isEmpty) saida.add([]);
        for (final doc in snapshot.docs) {
          filhos.add(doc.reference
              .collection('orcamento_gasto')
              .snapshots()
              .listen((gastos) {
            if (atual != versao || saida.isClosed) return;
            cache[doc.id] = const CompromissoPlanejamentoService().mapear(
                doc.id, doc.data(),
                gastos: gastos.docs.map((g) => g.data()).toList());
            if (cache.length == snapshot.docs.length) {
              saida
                  .add(cache.values.whereType<Map<String, dynamic>>().toList());
            }
          }, onError: (Object e) {
            if (atual == versao && !saida.isClosed) saida.addError(e);
          }));
        }
      }, onError: (Object e) {
        if (!saida.isClosed) saida.addError(e);
      });
    }, onCancel: () async {
      versao++;
      await pais?.cancel();
      await Future.wait(filhos.map((s) => s.cancel()));
    });
    return saida.stream;
  }

  Future<List<ConvidadoModel>> listarConvidadosDoEvento(String idEvento) async {
    final id = idEvento.trim();
    if (id.isEmpty) return [];

    final snapshot = await _db
        .collection(collectionConvidado)
        .where('id_evento', isEqualTo: id)
        .get();

    final mapa = <String, ConvidadoModel>{};
    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id_convidado'] = data['id_convidado'] ?? doc.id;
      data['id_evento'] = data['id_evento'] ?? data['id_evento_evento'] ?? id;
      final convidado = ConvidadoModel.fromMap(data);
      mapa[convidado.idConvidado] = convidado;
    }
    return mapa.values.toList();
  }

  DocumentReference<Map<String, dynamic>> _calculoRef(String idCalculo) {
    return _calculadoraCollection.doc(idCalculo);
  }

  CollectionReference<Map<String, dynamic>> _itensCollection(String idCalculo) {
    return _calculoRef(idCalculo).collection(subcollectionItens);
  }

  /// Salva ou atualiza uma simulação e seus itens calculados.
  ///
  /// Usa batch para garantir que o documento principal e os itens sejam
  /// gravados de forma consistente.
  Future<void> salvarSimulacao({
    required CalculadoraFesta calculo,
    required List<CalculadoraFestaItem> itens,
  }) async {
    if (calculo.idCalculo.trim().isEmpty) {
      throw ArgumentError('idCalculo não pode ser vazio.');
    }

    final calculoModel = CalculadoraFestaModel.fromEntity(calculo);
    final calculoRef = _calculoRef(calculo.idCalculo);
    final anteriores = await _itensCollection(calculo.idCalculo).get();
    final idsAtuais = itens.map((item) => item.idItemResultado).toSet();
    if (anteriores.docs.where((doc) => !idsAtuais.contains(doc.id)).length +
            itens.length +
            1 >
        500) {
      throw StateError('A simulação excede o limite de itens por salvamento.');
    }
    final batch = _db.batch();
    for (final doc in anteriores.docs) {
      if (!idsAtuais.contains(doc.id)) batch.delete(doc.reference);
    }

    batch.set(
      calculoRef,
      _mapComDono(calculoModel.toMap()),
      SetOptions(merge: true),
    );

    for (final entity in itens) {
      final item = CalculadoraFestaItemModel.fromEntity(entity);
      if (item.idItemResultado.trim().isEmpty) continue;

      batch.set(
        _itensCollection(calculo.idCalculo).doc(item.idItemResultado),
        item.toMap(),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  /// Lista todas as simulações de um evento.
  ///
  /// A ordenação é feita em memória para evitar exigir índice composto no
  /// Firestore durante esta etapa do projeto.
  Future<List<CalculadoraFestaModel>> listarSimulacoesPorEvento(
      String idEvento) async {
    final id = idEvento.trim();
    if (id.isEmpty) return [];

    final snapshot =
        await _calculadoraCollection.where('id_evento', isEqualTo: id).get();

    final result = snapshot.docs
        .where((doc) =>
            (doc.data()['data_calculo'] ?? doc.data()['data_criacao']) != null)
        .map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id_calculo'] = data['id_calculo'] ?? doc.id;
      return CalculadoraFestaModel.fromMap(data);
    }).toList();

    result.sort((a, b) => b.dataCalculo.compareTo(a.dataCalculo));
    return result;
  }

  /// Stream para telas reativas, como "Minhas simulações".
  Stream<List<CalculadoraFestaModel>> observarSimulacoesPorEvento(
      String idEvento) {
    final id = idEvento.trim();
    if (id.isEmpty) return Stream<List<CalculadoraFestaModel>>.value(const []);

    return _calculadoraCollection
        .where('id_evento', isEqualTo: id)
        .snapshots()
        .map((snapshot) {
      final result = snapshot.docs
          .where((doc) =>
              (doc.data()['data_calculo'] ?? doc.data()['data_criacao']) !=
              null)
          .map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id_calculo'] = data['id_calculo'] ?? doc.id;
        return CalculadoraFestaModel.fromMap(data);
      }).toList();

      result.sort((a, b) => b.dataCalculo.compareTo(a.dataCalculo));
      return result;
    });
  }

  Future<CalculadoraFestaModel?> buscarSimulacaoPorId(String idCalculo) async {
    final id = idCalculo.trim();
    if (id.isEmpty) return null;

    final doc = await _calculoRef(id).get();
    if (!doc.exists || doc.data() == null) return null;

    final data = Map<String, dynamic>.from(doc.data()!);
    data['id_calculo'] = data['id_calculo'] ?? doc.id;
    return CalculadoraFestaModel.fromMap(data);
  }

  Future<List<CalculadoraFestaItemModel>> listarItensDaSimulacao(
      String idCalculo) async {
    final id = idCalculo.trim();
    if (id.isEmpty) return [];

    final snapshot = await _itensCollection(id).get();

    final result = snapshot.docs
        .where((doc) =>
            (doc.data()['data_calculo'] ?? doc.data()['data_criacao']) != null)
        .map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id_item_resultado'] = data['id_item_resultado'] ?? doc.id;
      data['id_calculo'] = data['id_calculo'] ?? id;
      return CalculadoraFestaItemModel.fromMap(data);
    }).toList();

    result.sort((a, b) {
      final categoriaCompare = a.categoria.compareTo(b.categoria);
      if (categoriaCompare != 0) return categoriaCompare;
      return a.nome.compareTo(b.nome);
    });

    return result;
  }

  /// Exclui a simulação e a subcoleção de itens.
  ///
  /// Firestore não exclui subcoleções automaticamente, por isso removemos os
  /// itens antes do documento principal.
  Future<void> excluirSimulacao(String idCalculo) async {
    final id = idCalculo.trim();
    if (id.isEmpty) return;

    final itensSnapshot = await _itensCollection(id).get();
    WriteBatch batch = _db.batch();
    int operations = 0;

    for (final doc in itensSnapshot.docs) {
      batch.delete(doc.reference);
      operations++;

      if (operations == 450) {
        await batch.commit();
        batch = _db.batch();
        operations = 0;
      }
    }

    batch.delete(_calculoRef(id));
    await batch.commit();
  }

  Future<void> atualizarStatusSimulacao({
    required String idCalculo,
    required StatusSimulacaoCalculadora status,
  }) async {
    final id = idCalculo.trim();
    if (id.isEmpty) return;

    await _calculoRef(id).set(
      {
        'status_simulacao': status.value,
        'status_simulacao_label': status.label,
        'data_atualizacao': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> marcarComoConvertidaEmOrcamento(String idCalculo) async {
    final id = idCalculo.trim();
    if (id.isEmpty) return;

    final agora = DateTime.now();

    await _calculoRef(id).set(
      {
        'status_simulacao':
            StatusSimulacaoCalculadora.convertidaOrcamento.value,
        'status_simulacao_label':
            StatusSimulacaoCalculadora.convertidaOrcamento.label,
        'convertido_em_orcamento': true,
        'data_conversao_orcamento': agora.toIso8601String(),
        'data_atualizacao': agora.toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> marcarItemComoAdicionadoAoOrcamento({
    required String idCalculo,
    required String idItemResultado,
    required String idOrcamentoGerado,
  }) async {
    final calculoId = idCalculo.trim();
    final itemId = idItemResultado.trim();
    final orcamentoId = idOrcamentoGerado.trim();

    if (calculoId.isEmpty || itemId.isEmpty || orcamentoId.isEmpty) return;

    await _itensCollection(calculoId).doc(itemId).set(
      {
        'adicionado_ao_orcamento': true,
        'id_orcamento_gerado': orcamentoId,
        'data_adicionado_ao_orcamento': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> marcarItensComoAdicionadosAoOrcamento({
    required String idCalculo,
    required Map<String, String> idsOrcamentoPorItem,
  }) async {
    final calculoId = idCalculo.trim();
    if (calculoId.isEmpty || idsOrcamentoPorItem.isEmpty) return;

    final agora = DateTime.now();
    final batch = _db.batch();

    idsOrcamentoPorItem.forEach((idItemResultado, idOrcamentoGerado) {
      final itemId = idItemResultado.trim();
      final orcamentoId = idOrcamentoGerado.trim();
      if (itemId.isEmpty || orcamentoId.isEmpty) return;

      batch.set(
        _itensCollection(calculoId).doc(itemId),
        {
          'adicionado_ao_orcamento': true,
          'id_orcamento_gerado': orcamentoId,
          'data_adicionado_ao_orcamento': agora.toIso8601String(),
        },
        SetOptions(merge: true),
      );
    });

    await batch.commit();
  }

  Future<Map<String, String>> transformarSimulacaoEmOrcamento({
    required CalculadoraFesta simulacao,
    required List<CalculadoraFestaItem> itensPendentes,
  }) async {
    if (itensPendentes.length > 240) {
      throw StateError('Converta até 240 itens por vez.');
    }
    final model = CalculadoraFestaModel.fromEntity(simulacao);
    final existentes = await _db
        .collection(collectionOrcamentos)
        .where('id_evento', isEqualTo: simulacao.idEvento)
        .get();
    const conversao = ConversaoOrcamentoService();
    final ids = conversao.destinos(simulacao.idEvento, itensPendentes,
        existentes.docs.map((doc) => {...doc.data(), '__id': doc.id}).toList());
    final propostas = conversao.propostas(itensPendentes, ids);
    await _db.runTransaction((transaction) async {
      final ref = _calculoRef(simulacao.idCalculo);
      final atual = await transaction.get(ref);
      if (!atual.exists ||
          atual.data()?['status_simulacao'] !=
              StatusSimulacaoCalculadora.aprovada.value ||
          atual.data()?['id_evento'] != simulacao.idEvento ||
          atual.data()?['convertido_em_orcamento'] == true) {
        throw StateError('A simulação não está aprovada ou já foi convertida.');
      }
      final gastos = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final id in ids.values.toSet()) {
        final gasto =
            await transaction.get(_db.collection(collectionOrcamentos).doc(id));
        if (gasto.exists && gasto.data()?['id_evento'] != simulacao.idEvento) {
          throw StateError('O orçamento pertence a outra festa.');
        }
        gastos[id] = gasto;
      }
      final destinosAtuais = conversao.destinos(
          simulacao.idEvento,
          itensPendentes,
          gastos.values
              .where((d) => d.exists)
              .map((d) => {...d.data()!, '__id': d.id})
              .toList());
      if (ids.entries.any((e) => destinosAtuais[e.key] != e.value)) {
        throw StateError(
            'A cobertura do orçamento mudou. Revise antes de converter.');
      }
      final atualizados = <String>{};
      final agora = DateTime.now();
      for (var i = 0; i < itensPendentes.length; i++) {
        final item = CalculadoraFestaItemModel.fromEntity(itensPendentes[i]);
        final gasto = gastos[ids[item.idItemResultado]]!;
        if (!gasto.exists) {
          transaction.set(
              gasto.reference,
              _mapearItemCalculadoraParaOrcamento(
                  simulacao: model,
                  item: item,
                  idOrcamento: gasto.id,
                  data: agora));
        } else if (atualizados.add(gasto.id)) {
          // Um serviço pode cobrir vários itens: proposta separada, custo real intacto.
          final grupo = propostas[gasto.id]!;
          transaction.update(gasto.reference, {
            'propostas_calculadora': grupo,
            'quantidade_sugerida_calculadora': grupo.length == 1
                ? (grupo.values.single as Map)['quantidade']
                : FieldValue.delete(),
            'custo_sugerido_calculadora': grupo.values.fold<double>(
                0,
                (total, proposta) =>
                    total + ((proposta as Map)['custo'] as num).toDouble()),
            'id_ultima_simulacao': simulacao.idCalculo,
          });
        }
        transaction.set(
            _itensCollection(simulacao.idCalculo).doc(item.idItemResultado),
            item
                .copyWith(
                    adicionadoAoOrcamento: true,
                    idOrcamentoGerado: gasto.id,
                    dataAdicionadoAoOrcamento: agora)
                .toMap(),
            SetOptions(merge: true));
      }
      transaction.update(ref, {
        'status_simulacao':
            StatusSimulacaoCalculadora.convertidaOrcamento.value,
        'status_simulacao_label':
            StatusSimulacaoCalculadora.convertidaOrcamento.label,
        'convertido_em_orcamento': true,
        'data_conversao_orcamento': agora.toIso8601String(),
        'data_atualizacao': agora.toIso8601String(),
      });
    });
    return ids;
  }

  Future<void> enviarResultadoParaCardapio({
    required CalculadoraFesta calculo,
    required List<CalculadoraFestaItem> itens,
    required String idCardapio,
    List<CalculadoraFestaItem>? itensSimulacao,
  }) async {
    final historico = itensSimulacao ?? itens;
    final selecionados = itens.map((item) => item.idItemResultado).toSet();
    final anteriores = await _itensCollection(calculo.idCalculo).get();
    final idsHistorico = historico.map((item) => item.idItemResultado).toSet();
    final removidos =
        anteriores.docs.where((doc) => !idsHistorico.contains(doc.id)).toList();
    if (historico.length + itens.length + removidos.length + 1 > 500) {
      throw StateError('A aplicação excede o limite de itens por operação.');
    }
    final cardapioRef = _db.collection(collectionCardapios).doc(idCardapio);
    final snapshot = await cardapioRef.collection('itens').get();
    final existentes = snapshot.docs
        .map((doc) => CardapioItemModel.fromMap({
              ...doc.data(),
              'id_item': doc.id,
              'id_cardapio': idCardapio,
            }))
        .toList();
    final destinos = <String, String>{};
    for (final item in itens) {
      final chave = RevisaoCardapioService.identidade(
          item.nome, item.unidade, item.publicoAlvo);
      final candidatos = existentes
          .where((atual) =>
              RevisaoCardapioService.identidade(
                  atual.nome, atual.unidade, atual.publicoAlvo.name) ==
              chave)
          .toList();
      if (candidatos.length > 1) {
        throw StateError(
            'Há itens duplicados para ${item.nome}. Revise o cardápio antes de aplicar.');
      }
      final inicial =
          const RevisaoCardapioService().correspondente(item, existentes);
      final prefixo = '${calculo.idCalculo}_menu_${idCardapio}_';
      if (item.idItemResultado.startsWith(prefixo)) {
        final origem = item.idItemResultado.substring(prefixo.length);
        final conhecidos = existentes.where((i) => i.idItem == origem);
        if (conhecidos.isNotEmpty &&
            RevisaoCardapioService.unidade(conhecidos.first.unidade) !=
                RevisaoCardapioService.unidade(item.unidade) &&
            !const RevisaoCardapioService()
                .podeAjustarUnidade(conhecidos.first, item)) {
          throw StateError(
              'A unidade ou a quantidade final de ${item.nome} mudou. Revise antes de aplicar.');
        }
      }
      final id = candidatos.isNotEmpty
          ? candidatos.single.idItem
          : inicial?.idItem ?? 'card_calc_${Uri.encodeComponent(chave)}';
      if (destinos.containsValue(id)) {
        throw StateError('Há sugestões duplicadas para ${item.nome}.');
      }
      destinos[item.idItemResultado] = id;
    }
    await _db.runTransaction((transaction) async {
      final cardapio = await transaction.get(cardapioRef);
      if (!cardapio.exists ||
          cardapio.data()?['id_evento'] != calculo.idEvento) {
        throw StateError('O cardápio não pertence à festa selecionada.');
      }
      final refs = itens
          .map((item) => cardapioRef
              .collection('itens')
              .doc(destinos[item.idItemResultado]!))
          .toList();
      final atuais = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final ref in refs) {
        atuais.add(await transaction.get(ref));
      }
      // Mantém o pai completo, inclusive quando o envio precede o botão Salvar.
      transaction.set(
          _calculoRef(calculo.idCalculo),
          _mapComDono(CalculadoraFestaModel.fromEntity(calculo).toMap()),
          SetOptions(merge: true));
      for (var i = 0; i < itens.length; i++) {
        final item = itens[i];
        final data = atuais[i].data();
        final ajusteInicial = data != null &&
            const RevisaoCardapioService().podeAjustarUnidade(
                CardapioItemModel.fromMap({
                  ...data,
                  'id_item': refs[i].id,
                  'id_cardapio': idCardapio
                }),
                item);
        if (data != null &&
            !ajusteInicial &&
            RevisaoCardapioService.identidade(
                    (data['nome'] ?? '').toString(),
                    (data['unidade'] ?? 'un').toString(),
                    (data['publico_alvo'] ?? 'todos').toString()) !=
                RevisaoCardapioService.identidade(
                    item.nome, item.unidade, item.publicoAlvo)) {
          throw StateError('O cardápio mudou. Revise as sugestões novamente.');
        }
        final tipo = _tipoCardapio(item);
        if (data == null) {
          transaction.set(
              refs[i],
              CardapioItemModel(
                idItem: refs[i].id,
                idEvento: calculo.idEvento,
                idCardapio: idCardapio,
                nome: item.nome,
                tipo: tipo,
                publicoAlvo: PublicoAlvoCardapio.fromString(item.publicoAlvo),
                quantidadeSugerida: item.quantidade,
                quantidadeFinal: 0,
                unidade: item.unidade,
                geradoPelaCalculadora: true,
                observacao: item.regraAplicada,
              ).toMap());
        } else {
          transaction.update(refs[i], {
            'quantidade_sugerida': item.quantidade,
            if (ajusteInicial) 'unidade': item.unidade,
            'id_calculo_origem': calculo.idCalculo,
            if (data['gerado_pela_calculadora'] == true &&
                data['tipo'] == 'outro')
              'tipo': tipo.name,
          });
        }
      }
      for (final item in historico) {
        transaction.set(
            _itensCollection(calculo.idCalculo).doc(item.idItemResultado),
            CalculadoraFestaItemModel.fromEntity(item.copyWith(
              adicionadoAoCardapio:
                  selecionados.contains(item.idItemResultado) ||
                      item.adicionadoAoCardapio,
            )).toMap(),
            SetOptions(merge: true));
      }
      for (final doc in removidos) {
        transaction.delete(doc.reference);
      }
    });
    await atualizarTotaisDoCardapio(idCardapio);
  }

  TipoItemCardapio _tipoCardapio(CalculadoraFestaItem item) =>
      RevisaoCardapioService.tipo(item.nome, item.categoria, item.tipoItem);

  Future<void> atualizarTotaisDoCardapio(String idCardapio) async {
    final itensSnap = await _db
        .collection(collectionCardapios)
        .doc(idCardapio)
        .collection('itens')
        .get();

    var totalItens = 0;
    var totalComidas = 0;
    var totalBebidas = 0;
    var totalSobremesas = 0;

    for (final doc in itensSnap.docs) {
      final data = doc.data();
      if (data['ativo'] == false) continue;

      totalItens++;
      final tipo = data['tipo']?.toString().toLowerCase();

      switch (tipo) {
        case 'comida':
        case 'bolo':
          totalComidas++;
          break;
        case 'bebida':
          totalBebidas++;
          break;
        case 'sobremesa':
          totalSobremesas++;
          break;
      }
    }

    await _db.collection(collectionCardapios).doc(idCardapio).set(
      {
        'total_itens': totalItens,
        'total_comidas': totalComidas,
        'total_bebidas': totalBebidas,
        'total_sobremesas': totalSobremesas,
      },
      SetOptions(merge: true),
    );
  }

  Map<String, dynamic> _mapComDono(Map<String, dynamic> dados) {
    final uid = _auth.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) {
      throw StateError(
        'É preciso estar autenticado para salvar a simulação da calculadora.',
      );
    }

    dados['id_usuario'] = uid;
    return dados;
  }

  Map<String, dynamic> _mapearItemCalculadoraParaOrcamento({
    required CalculadoraFestaModel simulacao,
    required CalculadoraFestaItemModel item,
    required String idOrcamento,
    required DateTime data,
  }) {
    return {
      'id_orcamento': idOrcamento,
      'id_evento': simulacao.idEvento,
      'id_cardapio': item.idCardapio,
      'id_item_cardapio': item.idItemCardapio,
      'id_calculo_origem': simulacao.idCalculo,
      'id_item_calculadora': item.idItemResultado,
      'origem': 'calculadora_ia',
      'categoria': item.categoria,
      'item': item.nome,
      'nome': item.nome,
      'descricao': 'Gerado automaticamente pela Calculadora Inteligente.',
      'anotacoes': item.nome,
      'id_solicitante': simulacao.idUsuario ?? _auth.currentUser?.uid,
      'data_cadastro': Timestamp.fromDate(data),
      'quantidade': item.quantidade,
      'unidade': item.unidade,
      'custo_estimado': item.custoEstimado,
      'custo_real': 0.0,
      'valor_unitario_medio': item.valorUnitarioMedio,
      'forma_pagamento': '',
      'status_pagamento': 'pendente',
      'status_orcamento': 'pendente',
      'pago': false,
      'tipo_evento': simulacao.tipoEvento,
      'perfil_festa': simulacao.perfilFesta.nome,
      'regra_aplicada': item.regraAplicada,
      'publico_alvo': item.publicoAlvo,
      'tipo_item': item.tipoItem,
      'observacao':
          '${item.regraAplicada}\nQuantidade sugerida: ${item.quantidadeFormatada}.\n'
              'Valor médio: ${item.valorUnitarioFormatado}.\n'
              'Custo estimado: ${item.custoEstimadoFormatado}.',
      'ativo': true,
      'deletado': false,
      'data_criacao': data.toIso8601String(),
      'data_atualizacao': data.toIso8601String(),
    };
  }
}
