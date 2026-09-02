import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/calculadora_festa_repository.dart';
import '../models/cardapio/cardapio_item_model.dart';
import '../models/convidado/convidado_model.dart';
import '../models/evento/calculadora_festa_item_model.dart';
import '../models/evento/calculadora_festa_model.dart';
import '../models/model.dart';
import '../../domain/entities/cardapio.dart';

/// Repository responsável pela persistência das simulações da calculadora.
///
/// Mantém o controller limpo e centraliza todos os acessos ao Firestore
/// relacionados à coleção `calculadora_festa`.
class CalculadoraFestaRepositoryImpl implements CalculadoraFestaRepository {
  final FirebaseFirestore _db;

  static const String collectionCalculadora = 'calculadora_festa';
  static const String collectionConvidado = 'convidado';
  static const String collectionCardapios = 'cardapios';
  static const String collectionOrcamentos = 'orcamento';
  static const String subcollectionItens = 'itens';

  CalculadoraFestaRepositoryImpl({required FirebaseFirestore firestore})
      : _db = firestore;

  CollectionReference<Map<String, dynamic>> get _calculadoraCollection {
    return _db.collection(collectionCalculadora);
  }

  @override
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
  @override
  Future<void> salvarSimulacao({
    required CalculadoraFestaModel calculo,
    required List<CalculadoraFestaItemModel> itens,
  }) async {
    if (calculo.idCalculo.trim().isEmpty) {
      throw ArgumentError('idCalculo não pode ser vazio.');
    }

    final calculoRef = _calculoRef(calculo.idCalculo);
    final batch = _db.batch();

    batch.set(
      calculoRef,
      calculo.toMap(),
      SetOptions(merge: true),
    );

    for (final item in itens) {
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
  @override
  Future<List<CalculadoraFestaModel>> listarSimulacoesPorEvento(
      String idEvento) async {
    final id = idEvento.trim();
    if (id.isEmpty) return [];

    final snapshot =
        await _calculadoraCollection.where('id_evento', isEqualTo: id).get();

    final result = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id_calculo'] = data['id_calculo'] ?? doc.id;
      return CalculadoraFestaModel.fromMap(data);
    }).toList();

    result.sort((a, b) => b.dataCalculo.compareTo(a.dataCalculo));
    return result;
  }

  /// Stream para telas reativas, como "Minhas simulações".
  @override
  Stream<List<CalculadoraFestaModel>> observarSimulacoesPorEvento(
      String idEvento) {
    final id = idEvento.trim();
    if (id.isEmpty) return Stream<List<CalculadoraFestaModel>>.value(const []);

    return _calculadoraCollection
        .where('id_evento', isEqualTo: id)
        .snapshots()
        .map((snapshot) {
      final result = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id_calculo'] = data['id_calculo'] ?? doc.id;
        return CalculadoraFestaModel.fromMap(data);
      }).toList();

      result.sort((a, b) => b.dataCalculo.compareTo(a.dataCalculo));
      return result;
    });
  }

  @override
  Future<CalculadoraFestaModel?> buscarSimulacaoPorId(String idCalculo) async {
    final id = idCalculo.trim();
    if (id.isEmpty) return null;

    final doc = await _calculoRef(id).get();
    if (!doc.exists || doc.data() == null) return null;

    final data = Map<String, dynamic>.from(doc.data()!);
    data['id_calculo'] = data['id_calculo'] ?? doc.id;
    return CalculadoraFestaModel.fromMap(data);
  }

  @override
  Future<List<CalculadoraFestaItemModel>> listarItensDaSimulacao(
      String idCalculo) async {
    final id = idCalculo.trim();
    if (id.isEmpty) return [];

    final snapshot = await _itensCollection(id).get();

    final result = snapshot.docs.map((doc) {
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
  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
  Future<Map<String, String>> transformarSimulacaoEmOrcamento({
    required CalculadoraFestaModel simulacao,
    required List<CalculadoraFestaItemModel> itensPendentes,
  }) async {
    final agora = DateTime.now();
    WriteBatch batch = _db.batch();
    var operations = 0;
    final idsOrcamentoPorItem = <String, String>{};

    for (final item in itensPendentes) {
      final idOrcamento = _gerarIdOrcamento(
        idCalculo: simulacao.idCalculo,
        idItemResultado: item.idItemResultado,
        nome: item.nome,
      );
      idsOrcamentoPorItem[item.idItemResultado] = idOrcamento;

      final orcamentoRef =
          _db.collection(collectionOrcamentos).doc(idOrcamento);
      final itemCalculadoraRef =
          _itensCollection(simulacao.idCalculo).doc(item.idItemResultado);

      batch.set(
        orcamentoRef,
        _mapearItemCalculadoraParaOrcamento(
          simulacao: simulacao,
          item: item,
          idOrcamento: idOrcamento,
          data: agora,
        ),
        SetOptions(merge: true),
      );
      operations++;

      batch.set(
        itemCalculadoraRef,
        item
            .copyWith(
              adicionadoAoOrcamento: true,
              idOrcamentoGerado: idOrcamento,
              dataAdicionadoAoOrcamento: agora,
            )
            .toMap(),
        SetOptions(merge: true),
      );
      operations++;

      if (operations >= 440) {
        await batch.commit();
        batch = _db.batch();
        operations = 0;
      }
    }

    batch.set(
      _calculoRef(simulacao.idCalculo),
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

    await batch.commit();
    return idsOrcamentoPorItem;
  }

  @override
  Future<void> enviarResultadoParaCardapio({
    required CalculadoraFestaModel calculo,
    required List<CalculadoraFestaItemModel> itens,
    required String idCardapio,
  }) async {
    final batch = _db.batch();
    final cardapioRef = _db.collection(collectionCardapios).doc(idCardapio);

    for (final item in itens) {
      final idItemCardapio = _gerarIdItemCardapio(calculo.idCalculo, item.nome);
      final cardapioItem = CardapioItemModel(
        idItem: idItemCardapio,
        idEvento: calculo.idEvento,
        idCardapio: idCardapio,
        nome: item.nome,
        tipo: TipoItemCardapio.fromString(item.tipoItem),
        publicoAlvo: PublicoAlvoCardapio.fromString(item.publicoAlvo),
        quantidadeSugerida: item.quantidade,
        quantidadeFinal: item.quantidade,
        unidade: item.unidade,
        confirmado: false,
        geradoPelaCalculadora: true,
        observacao:
            '${item.regraAplicada}\nCusto estimado: ${item.custoEstimadoFormatado}. Valor médio: ${item.valorUnitarioFormatado}.',
      );

      batch.set(
        cardapioRef.collection('itens').doc(idItemCardapio),
        cardapioItem.toMap(),
        SetOptions(merge: true),
      );

      batch.set(
        _itensCollection(calculo.idCalculo).doc(item.idItemResultado),
        item.copyWith(adicionadoAoCardapio: true).toMap(),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    await atualizarTotaisDoCardapio(idCardapio);
  }

  @override
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

  String _gerarIdOrcamento({
    required String idCalculo,
    required String idItemResultado,
    required String nome,
  }) {
    final safeCalculo = _normalizarIdTexto(idCalculo, fallback: 'calculo');
    final safeItem = _normalizarIdTexto(idItemResultado, fallback: nome);
    return 'orc_calc_${safeCalculo}_$safeItem';
  }

  String _gerarIdItemCardapio(String idCalculo, String nome) {
    final safeCalculo = _normalizarIdTexto(idCalculo, fallback: 'calculo');
    final safeNome = _normalizarIdTexto(nome, fallback: 'item');
    return 'card_calc_${safeCalculo}_$safeNome';
  }

  String _normalizarIdTexto(String value, {required String fallback}) {
    final source = value.trim().isEmpty ? fallback : value.trim();

    final normalized = source
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúâêîôûãõç]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+'), '')
        .replaceAll(RegExp(r'_+$'), '');

    return normalized.isEmpty ? 'item' : normalized;
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
      'id_calculo_origem': simulacao.idCalculo,
      'id_item_calculadora': item.idItemResultado,
      'origem': 'calculadora_ia',
      'categoria': item.categoria,
      'item': item.nome,
      'nome': item.nome,
      'descricao': 'Gerado automaticamente pela Calculadora Inteligente.',
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
