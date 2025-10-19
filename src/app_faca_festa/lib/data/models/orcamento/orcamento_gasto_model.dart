import 'package:cloud_firestore/cloud_firestore.dart';

class OrcamentoGastoModel {
  final String idGasto;
  final String idOrcamento;
  final String nome;
  final double custo;
  final double pago;
  final DateTime dataCadastro;

  OrcamentoGastoModel({
    required this.idGasto,
    required this.idOrcamento,
    required this.nome,
    required this.custo,
    required this.pago,
    DateTime? dataCadastro,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  // 🔹 Converter para Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id_gasto': idGasto,
      'id_orcamento': idOrcamento,
      'nome': nome,
      'custo': custo,
      'pago': pago,
      'data_cadastro': Timestamp.fromDate(dataCadastro),
    };
  }

  // 🔹 Criar a partir de Map (Firestore)
  factory OrcamentoGastoModel.fromMap(Map<String, dynamic> map) {
    return OrcamentoGastoModel(
      idGasto: map['id_gasto'] ?? '',
      idOrcamento: map['id_orcamento'] ?? '',
      nome: map['nome'] ?? '',
      custo: (map['custo'] ?? 0).toDouble(),
      pago: (map['pago'] ?? 0).toDouble(),
      dataCadastro: _toDateTime(map['data_cadastro']),
    );
  }

  // 🔹 Conversor auxiliar
  static DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  // 🔹 Cálculos auxiliares
  double get restante => (custo - pago).clamp(0, custo);
  double get percentualPago => (custo > 0) ? (pago / custo).clamp(0.0, 1.0) : 0.0;
}
