import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/convidado.dart';
import '../../../domain/entities/tarefa.dart';

export '../../../domain/entities/tarefa.dart';

extension StatusTarefaPersistence on StatusTarefa {
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
}

class TarefaModel extends Tarefa {
  TarefaModel({
    required super.idTarefa,
    required super.idEvento,
    required super.titulo,
    super.idResponsavel,
    super.responsavel,
    super.descricao,
    super.dataPrevista,
    super.status,
    super.dataCadastro,
  });

  factory TarefaModel.fromEntity(Tarefa tarefa) => TarefaModel(
        idTarefa: tarefa.idTarefa,
        idEvento: tarefa.idEvento,
        idResponsavel: tarefa.idResponsavel,
        titulo: tarefa.titulo,
        descricao: tarefa.descricao,
        dataPrevista: tarefa.dataPrevista,
        status: tarefa.status,
        dataCadastro: tarefa.dataCadastro,
        responsavel: tarefa.responsavel,
      );

  Map<String, dynamic> toMap() => {
        'id_tarefa': idTarefa,
        'id_evento': idEvento,
        'id_responsavel': idResponsavel,
        'titulo': titulo,
        'descricao': descricao,
        'data_prevista':
            dataPrevista == null ? null : Timestamp.fromDate(dataPrevista!),
        'status': status.firestoreValue,
        'data_cadastro': Timestamp.fromDate(dataCadastro),
      };

  factory TarefaModel.fromMap(Map<String, dynamic> map) => TarefaModel(
        idTarefa: map['id_tarefa'] ?? '',
        idEvento: map['id_evento'] ?? '',
        idResponsavel: map['id_responsavel'],
        titulo: map['titulo'] ?? '',
        descricao: map['descricao'],
        dataPrevista: map['data_prevista'] is Timestamp
            ? (map['data_prevista'] as Timestamp).toDate()
            : null,
        status: StatusTarefa.fromString(map['status']),
        dataCadastro: map['data_cadastro'] is Timestamp
            ? (map['data_cadastro'] as Timestamp).toDate()
            : DateTime.now(),
      );

  @override
  TarefaModel copyWith({
    String? idTarefa,
    String? idEvento,
    String? idResponsavel,
    String? titulo,
    String? descricao,
    DateTime? dataPrevista,
    StatusTarefa? status,
    DateTime? dataCadastro,
    Convidado? responsavel,
  }) =>
      TarefaModel(
        idTarefa: idTarefa ?? this.idTarefa,
        idEvento: idEvento ?? this.idEvento,
        idResponsavel: idResponsavel ?? this.idResponsavel,
        titulo: titulo ?? this.titulo,
        descricao: descricao ?? this.descricao,
        dataPrevista: dataPrevista ?? this.dataPrevista,
        status: status ?? this.status,
        dataCadastro: dataCadastro ?? this.dataCadastro,
        responsavel: responsavel ?? this.responsavel,
      );
}
