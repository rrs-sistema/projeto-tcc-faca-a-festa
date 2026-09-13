import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/orcamento_gasto.dart';


class OrcamentoGastoModel extends OrcamentoGasto {
  OrcamentoGastoModel({
    required super.idGasto,
    required super.idOrcamento,
    super.idServicoContratado,
    super.nomeServicoContratado,
    required super.nome,
    required super.custo,
    required super.pago,
    super.dataCadastro,
  });

  // 🔹 Converter para Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id_gasto': idGasto,
      'id_orcamento': idOrcamento,
      'id_servico': idServicoContratado,
      'nome_servico': nomeServicoContratado,
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
      idServicoContratado: map['id_servico'] ?? '',
      nomeServicoContratado: map['nome_servico'] ?? '',
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
}
