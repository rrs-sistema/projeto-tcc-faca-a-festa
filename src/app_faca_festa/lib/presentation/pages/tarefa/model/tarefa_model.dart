class TarefaModel {
  final String id;
  final String titulo;
  final String descricao;
  final DateTime dataPrevista;
  final bool concluida;
  final String responsavelNome; // organizador ou convidado
  final String responsavelFotoUrl;

  TarefaModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.dataPrevista,
    required this.concluida,
    required this.responsavelNome,
    required this.responsavelFotoUrl,
  });
}
