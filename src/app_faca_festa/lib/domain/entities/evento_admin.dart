class EventoAdmin {
  EventoAdmin({
    required this.id,
    required this.nome,
    required this.tipoNome,
    required this.organizador,
    this.cidade,
    this.data,
    this.aprovado = false,
    this.ativo = true,
    this.status = '',
    this.totalConvidados = 0,
  });

  final String id;
  final String nome;
  final String tipoNome;
  final String organizador;
  final String? cidade;
  final bool aprovado;
  final bool ativo;
  final String status;
  final int totalConvidados;
  final DateTime? data;

  bool get emCurso {
    const ativos = {
      'rascunho',
      'planejamento',
      'confirmado',
      'emAndamento',
      'em_andamento',
    };
    if (status.isNotEmpty) return ativos.contains(status);
    return ativo &&
        (data == null ||
            !data!.isBefore(DateTime.now().subtract(const Duration(days: 1))));
  }

  String get statusLabel {
    switch (status) {
      case 'rascunho':
        return 'Rascunho';
      case 'planejamento':
        return 'Em planejamento';
      case 'confirmado':
        return 'Confirmado';
      case 'emAndamento':
      case 'em_andamento':
        return 'Em andamento';
      case 'finalizado':
        return 'Finalizado';
      case 'adiado':
        return 'Adiado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return aprovado ? 'Aprovado' : 'Em análise';
    }
  }
}
