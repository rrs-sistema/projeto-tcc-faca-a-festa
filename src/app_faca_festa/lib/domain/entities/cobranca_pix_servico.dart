class CobrancaPixServico {
  const CobrancaPixServico({
    required this.id,
    required this.status,
    required this.valorCentavos,
    required this.copiaCola,
    required this.qrCodeBase64,
    this.expiraEm,
    this.nomeServico,
    this.aviso,
    this.reutilizada = false,
  });

  final String id;
  final String status;
  final int valorCentavos;
  final String copiaCola;
  final String qrCodeBase64;
  final String? expiraEm;
  final String? nomeServico;
  final String? aviso;
  final bool reutilizada;

  bool get confirmado => status == 'APPROVED';

  bool get encerrado =>
      status == 'REJECTED' ||
      status == 'CANCELLED' ||
      status == 'REFUNDED' ||
      status == 'FALHA';

  factory CobrancaPixServico.fromMap(Map<String, dynamic> raw) {
    final aninhada = raw['cobranca'];
    final map = aninhada is Map
        ? Map<String, dynamic>.from(aninhada)
        : raw;
    return CobrancaPixServico(
      id: map['id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'PENDING',
      valorCentavos: (map['valorCentavos'] as num?)?.toInt() ?? 0,
      copiaCola: map['copiaCola']?.toString() ?? '',
      qrCodeBase64: map['qrCodeBase64']?.toString() ?? '',
      expiraEm: map['expiraEm']?.toString(),
      nomeServico: map['nomeServico']?.toString(),
      aviso: raw['aviso']?.toString(),
      reutilizada: raw['reutilizada'] == true,
    );
  }
}
