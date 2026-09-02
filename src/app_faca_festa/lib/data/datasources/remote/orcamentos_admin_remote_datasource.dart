import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/admin/orcamento_admin_model.dart';
import '../../models/orcamento/orcamento_model.dart';

class OrcamentosAdminRemoteDatasource {
  OrcamentosAdminRemoteDatasource({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;
  final Map<String, String> _cacheCategorias = {};

  Future<List<OrcamentoAdminModel>> listarOrcamentosComEventoDetalhes() async {
    final snap = await _db.collection('orcamento').get();
    final futures = snap.docs.map(_montarOrcamentoAdmin);

    return Future.wait(futures);
  }

  Future<OrcamentoAdminModel> _montarOrcamentoAdmin(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final orcamento = OrcamentoModel.fromMap(doc.data());
    final eventoDetalhes = await _buscarEventoDetalhes(orcamento.idEvento);
    final categoriaDetalhes = await _buscarCategoriaDetalhes(orcamento);

    return OrcamentoAdminModel(
      id: orcamento.idOrcamento,
      eventoNome: eventoDetalhes.nome,
      tipoEvento: eventoDetalhes.tipo,
      cidade: eventoDetalhes.cidade,
      dataEvento: eventoDetalhes.data,
      categoria: categoriaDetalhes.nome,
      custoEstimado: categoriaDetalhes.custoEstimado,
      pago: categoriaDetalhes.valorPago,
      status: orcamento.status.label,
      custoTotalEvento: eventoDetalhes.custoTotal,
    );
  }

  Future<_EventoDetalhes> _buscarEventoDetalhes(String idEvento) async {
    if (idEvento.isEmpty) return _EventoDetalhes.empty();

    final eventoSnap = await _db.collection('evento').doc(idEvento).get();
    if (!eventoSnap.exists) return _EventoDetalhes.empty();

    final eventoData = eventoSnap.data();
    final idTipoEvento = eventoData?['id_tipo_evento'];

    return _EventoDetalhes(
      nome: (eventoData?['nome'] ?? 'Evento não identificado').toString(),
      tipo: await _buscarTipoEvento(idTipoEvento),
      cidade: (eventoData?['cidade'] ?? '-').toString(),
      data: _toDateTime(eventoData?['data']),
      custoTotal: _toDouble(eventoData?['custo_estimado']),
    );
  }

  Future<String> _buscarTipoEvento(dynamic idTipoEvento) async {
    const tipoPadrao = 'Tipo não informado';
    if (idTipoEvento == null) return tipoPadrao;

    final tipoSnap = await _db
        .collection('tipo_evento')
        .where('id_tipo_evento', isEqualTo: idTipoEvento)
        .limit(1)
        .get();
    if (tipoSnap.docs.isEmpty) return tipoPadrao;

    return (tipoSnap.docs.first.data()['nome'] ?? tipoPadrao).toString();
  }

  Future<_CategoriaDetalhes> _buscarCategoriaDetalhes(
    OrcamentoModel orcamento,
  ) async {
    var categoriaNome = orcamento.anotacoes ?? 'Outros';
    var custoEstimado = orcamento.custoEstimado ?? 0;
    var valorPago = 0.0;

    final idCategoria = orcamento.idCategoria;
    if (idCategoria != null && idCategoria.isNotEmpty) {
      categoriaNome = await _buscarNomeCategoria(idCategoria, categoriaNome);
    } else {
      final gastos = await _buscarGastosDoOrcamento(orcamento.idOrcamento);
      if (gastos != null) {
        categoriaNome = gastos.nome;
        custoEstimado = gastos.custoEstimado;
        valorPago = gastos.valorPago;
      }
    }

    return _CategoriaDetalhes(
      nome: categoriaNome,
      custoEstimado: custoEstimado,
      valorPago: valorPago,
    );
  }

  Future<String> _buscarNomeCategoria(
      String idCategoria, String fallback) async {
    final nomeEmCache = _cacheCategorias[idCategoria];
    if (nomeEmCache != null) return nomeEmCache;

    final catSnap =
        await _db.collection('categoria_servico').doc(idCategoria).get();
    if (!catSnap.exists) return fallback;

    final categoriaNome = (catSnap.data()?['nome'] ?? fallback).toString();
    _cacheCategorias[idCategoria] = categoriaNome;
    return categoriaNome;
  }

  Future<_CategoriaDetalhes?> _buscarGastosDoOrcamento(
      String idOrcamento) async {
    final gastosSnap = await _db
        .collection('orcamento')
        .doc(idOrcamento)
        .collection('orcamento_gasto')
        .get();

    if (gastosSnap.docs.isEmpty) return null;

    var somaCustos = 0.0;
    var somaPagos = 0.0;
    final nomesCategorias = <String>[];

    for (final doc in gastosSnap.docs) {
      final data = doc.data();
      nomesCategorias.add((data['nome'] ?? 'Outros').toString());
      somaCustos += _toDouble(data['custo']);
      somaPagos += _toDouble(data['pago']);
    }

    final categoriaNome = nomesCategorias.join(', ');
    _cacheCategorias[idOrcamento] = categoriaNome;

    return _CategoriaDetalhes(
      nome: categoriaNome,
      custoEstimado: somaCustos,
      valorPago: somaPagos,
    );
  }

  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class _EventoDetalhes {
  const _EventoDetalhes({
    required this.nome,
    required this.tipo,
    required this.cidade,
    required this.data,
    required this.custoTotal,
  });

  factory _EventoDetalhes.empty() {
    return const _EventoDetalhes(
      nome: 'Evento não identificado',
      tipo: 'Tipo não informado',
      cidade: '-',
      data: null,
      custoTotal: 0,
    );
  }

  final String nome;
  final String tipo;
  final String cidade;
  final DateTime? data;
  final double custoTotal;
}

class _CategoriaDetalhes {
  const _CategoriaDetalhes({
    required this.nome,
    required this.custoEstimado,
    required this.valorPago,
  });

  final String nome;
  final double custoEstimado;
  final double valorPago;
}
