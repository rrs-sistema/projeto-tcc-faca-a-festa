import 'package:cloud_firestore/cloud_firestore.dart';

import '../usuario/usuario_model.dart';

enum StatusTarefa {
  aFazer,
  emAndamento,
  concluida;

  /// 🔹 Retorna uma string legível para a interface
  String get label {
    switch (this) {
      case StatusTarefa.aFazer:
        return 'A fazer';
      case StatusTarefa.emAndamento:
        return 'Em andamento';
      case StatusTarefa.concluida:
        return 'Concluída';
    }
  }

  /// 🔹 Retorna o valor usado no Firestore
  String get firestoreValue {
    switch (this) {
      case StatusTarefa.aFazer:
        return 'a_fazer';
      case StatusTarefa.emAndamento:
        return 'em_andamento';
      case StatusTarefa.concluida:
        return 'concluida';
    }
  }

  /// 🔹 Converte uma string do Firestore em enum
  static StatusTarefa fromString(String? value) {
    if (value == null) return StatusTarefa.aFazer;

    final normalized = value.trim().toLowerCase();

    switch (normalized) {
      case 'em_andamento':
      case 'em andamento':
      case 'e':
        return StatusTarefa.emAndamento;

      case 'concluida':
      case 'concluído':
      case 'c':
        return StatusTarefa.concluida;

      case 'a_fazer':
      case 'a fazer':
      case 'pendente':
      case 'a':
      default:
        return StatusTarefa.aFazer;
    }
  }
}

class TarefaModel {
  final String idTarefa;
  final String idEvento;
  final String? idResponsavel;
  final String titulo;
  final String? descricao;
  final DateTime? dataPrevista;
  final StatusTarefa status;
  final DateTime dataCadastro;

  /// 🔹 Campo opcional (não salvo no Firestore)
  final UsuarioModel? responsavel;

  TarefaModel({
    required this.idTarefa,
    required this.idEvento,
    required this.titulo,
    this.idResponsavel,
    this.responsavel,
    this.descricao,
    this.dataPrevista,
    this.status = StatusTarefa.aFazer,
    DateTime? dataCadastro,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  /// 🔹 Conversão para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id_tarefa': idTarefa,
      'id_evento': idEvento,
      'id_responsavel': idResponsavel,
      'titulo': titulo,
      'descricao': descricao,
      'data_prevista': dataPrevista != null ? Timestamp.fromDate(dataPrevista!) : null,
      'status': status.firestoreValue,
      'data_cadastro': Timestamp.fromDate(dataCadastro),
    };
  }

  /// 🔹 Conversão a partir do Firestore
  factory TarefaModel.fromMap(Map<String, dynamic> map) {
    return TarefaModel(
      idTarefa: map['id_tarefa'] ?? '',
      idEvento: map['id_evento'] ?? '',
      idResponsavel: map['id_responsavel'],
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'],
      dataPrevista:
          map['data_prevista'] is Timestamp ? (map['data_prevista'] as Timestamp).toDate() : null,
      status: StatusTarefa.fromString(map['status']),
      dataCadastro: map['data_cadastro'] is Timestamp
          ? (map['data_cadastro'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// 🔹 Atualização parcial
  TarefaModel copyWith({
    String? titulo,
    String? descricao,
    DateTime? dataPrevista,
    StatusTarefa? status,
    UsuarioModel? responsavel,
  }) {
    return TarefaModel(
      idTarefa: idTarefa,
      idEvento: idEvento,
      idResponsavel: idResponsavel,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      dataPrevista: dataPrevista ?? this.dataPrevista,
      status: status ?? this.status,
      dataCadastro: dataCadastro,
      responsavel: responsavel ?? this.responsavel,
    );
  }
}
