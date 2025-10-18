import 'package:cloud_firestore/cloud_firestore.dart';

class TarefaModel {
  final String idTarefa;
  final String idEvento;
  final String? idResponsavel;
  final String nome;
  final String? descricao;
  final DateTime? dataPrevista;
  final String? status; // A = a fazer, E = em andamento, C = concluída
  final DateTime dataCadastro;

  TarefaModel({
    required this.idTarefa,
    required this.idEvento,
    required this.nome,
    this.idResponsavel,
    this.descricao,
    this.dataPrevista,
    this.status = 'A',
    DateTime? dataCadastro,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  /// 🔹 Conversão para Firestore / API
  Map<String, dynamic> toMap() {
    return {
      'id_tarefa': idTarefa,
      'id_evento_evento': idEvento,
      'id_responsavel': idResponsavel,
      'nome': nome,
      'descricao': descricao,
      'data_prevista': dataPrevista != null ? Timestamp.fromDate(dataPrevista!) : null,
      'status': status,
      'data_cadastro': Timestamp.fromDate(dataCadastro),
    };
  }

  /// 🔹 Conversão a partir do Firestore
  factory TarefaModel.fromMap(Map<String, dynamic> map) {
    return TarefaModel(
      idTarefa: map['id_tarefa'] ?? '',
      idEvento: map['id_evento_evento'] ?? '',
      idResponsavel: map['id_responsavel'],
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      dataPrevista:
          map['data_prevista'] is Timestamp ? (map['data_prevista'] as Timestamp).toDate() : null,
      status: map['status'] ?? 'A',
      dataCadastro: map['data_cadastro'] is Timestamp
          ? (map['data_cadastro'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// 🔹 Atualização parcial
  TarefaModel copyWith({
    String? nome,
    String? descricao,
    DateTime? dataPrevista,
    String? status,
  }) {
    return TarefaModel(
      idTarefa: idTarefa,
      idEvento: idEvento,
      idResponsavel: idResponsavel,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      dataPrevista: dataPrevista ?? this.dataPrevista,
      status: status ?? this.status,
      dataCadastro: dataCadastro,
    );
  }

  /// 🔹 Descrição legível do status
  String get statusDescricao {
    switch (status) {
      case 'C':
        return 'Concluída';
      case 'E':
        return 'Em andamento';
      default:
        return 'A fazer';
    }
  }
}
