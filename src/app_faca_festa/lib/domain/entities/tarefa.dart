import 'convidado.dart';

enum StatusTarefa {
  aFazer,
  emAndamento,
  concluida;

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

  static StatusTarefa fromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'em_andamento':
      case 'em andamento':
      case 'e':
        return StatusTarefa.emAndamento;
      case 'concluida':
      case 'concluído':
      case 'c':
        return StatusTarefa.concluida;
      default:
        return StatusTarefa.aFazer;
    }
  }
}

class Tarefa {
  final String idTarefa;
  final String idEvento;
  final String? idResponsavel;
  final String titulo;
  final String? descricao;
  final DateTime? dataPrevista;
  final StatusTarefa status;
  final DateTime dataCadastro;
  final Convidado? responsavel;

  Tarefa({
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

  Tarefa copyWith({
    String? idTarefa,
    String? idEvento,
    String? idResponsavel,
    String? titulo,
    String? descricao,
    DateTime? dataPrevista,
    StatusTarefa? status,
    DateTime? dataCadastro,
    Convidado? responsavel,
  }) {
    return Tarefa(
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
}
