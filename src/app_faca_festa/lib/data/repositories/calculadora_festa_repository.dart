import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/evento/calculadora_festa_item_model.dart';
import '../models/evento/calculadora_festa_model.dart';

/// Repository responsável pela persistência das simulações da calculadora.
///
/// Mantém o controller limpo e centraliza todos os acessos ao Firestore
/// relacionados à coleção `calculadora_festa`.
class CalculadoraFestaRepository {
  final FirebaseFirestore _db;

  static const String collectionCalculadora = 'calculadora_festa';
  static const String subcollectionItens = 'itens';

  CalculadoraFestaRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _calculadoraCollection {
    return _db.collection(collectionCalculadora);
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
  Future<List<CalculadoraFestaModel>> listarSimulacoesPorEvento(String idEvento) async {
    final id = idEvento.trim();
    if (id.isEmpty) return [];

    final snapshot = await _calculadoraCollection.where('id_evento', isEqualTo: id).get();

    final result = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id_calculo'] = data['id_calculo'] ?? doc.id;
      return CalculadoraFestaModel.fromMap(data);
    }).toList();

    result.sort((a, b) => b.dataCalculo.compareTo(a.dataCalculo));
    return result;
  }

  /// Stream para telas reativas, como "Minhas simulações".
  Stream<List<CalculadoraFestaModel>> observarSimulacoesPorEvento(String idEvento) {
    final id = idEvento.trim();
    if (id.isEmpty) return Stream<List<CalculadoraFestaModel>>.value(const []);

    return _calculadoraCollection.where('id_evento', isEqualTo: id).snapshots().map((snapshot) {
      final result = snapshot.docs.map((doc) {
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

  Future<List<CalculadoraFestaItemModel>> listarItensDaSimulacao(String idCalculo) async {
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
        'status_simulacao': StatusSimulacaoCalculadora.convertidaOrcamento.value,
        'status_simulacao_label': StatusSimulacaoCalculadora.convertidaOrcamento.label,
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
}
