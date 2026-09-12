class ResultadoEnvioConviteEmail {
  const ResultadoEnvioConviteEmail({
    required this.enviados,
    required this.semEmail,
    required this.falhas,
  });

  final int enviados;
  final List<String> semEmail;
  final List<String> falhas;
}

class EnviarConvitesPorEmailException implements Exception {
  const EnviarConvitesPorEmailException(this.codigo, [this.mensagem]);

  final String codigo;
  final String? mensagem;

  @override
  String toString() => mensagem?.trim().isNotEmpty == true
      ? mensagem!
      : 'Não foi possível enviar os convites.';
}

abstract class ConviteEmailService {
  Future<ResultadoEnvioConviteEmail> enviar({
    required String idEvento,
    required List<String> idsConvidados,
  });
}
