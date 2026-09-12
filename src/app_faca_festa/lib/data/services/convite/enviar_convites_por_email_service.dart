import 'package:cloud_functions/cloud_functions.dart';

import 'package:app_faca_festa/domain/services/convite_email_service.dart';

class EnviarConvitesPorEmailService implements ConviteEmailService {
  EnviarConvitesPorEmailService({required FirebaseFunctions functions})
      : _functions = functions;

  final FirebaseFunctions _functions;
  static const maxPorChamada = 40;

  @override
  Future<ResultadoEnvioConviteEmail> enviar({
    required String idEvento,
    required List<String> idsConvidados,
  }) async {
    try {
      var enviados = 0;
      final semEmail = <String>[];
      final falhas = <String>[];

      for (var i = 0; i < idsConvidados.length; i += maxPorChamada) {
        final fim = (i + maxPorChamada < idsConvidados.length)
            ? i + maxPorChamada
            : idsConvidados.length;
        final lote = idsConvidados.sublist(i, fim);
        final resultado = await _enviarLote(
          idEvento: idEvento,
          idsConvidados: lote,
        );
        enviados += resultado.enviados;
        semEmail.addAll(resultado.semEmail);
        falhas.addAll(resultado.falhas);
      }

      return ResultadoEnvioConviteEmail(
        enviados: enviados,
        semEmail: semEmail,
        falhas: falhas,
      );
    } on FirebaseFunctionsException catch (erro) {
      throw EnviarConvitesPorEmailException(erro.code, erro.message);
    }
  }

  Future<ResultadoEnvioConviteEmail> _enviarLote({
    required String idEvento,
    required List<String> idsConvidados,
  }) async {
    final callable = _functions.httpsCallable(
      'enviarConvitesPorEmail',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );
    final result = await callable.call({
      'idEvento': idEvento,
      'idsConvidados': idsConvidados,
    });
    final data = result.data;
    if (data is! Map) {
      throw const EnviarConvitesPorEmailException('internal');
    }
    final mapa = Map<String, dynamic>.from(data);
    final falhasBrutas = mapa['falhas'];
    final falhas = <String>[];
    if (falhasBrutas is List) {
      for (final item in falhasBrutas) {
        if (item is Map && item['id'] != null) {
          falhas.add(item['id'].toString());
        }
      }
    }
    return ResultadoEnvioConviteEmail(
      enviados: (mapa['enviados'] as num?)?.toInt() ?? 0,
      semEmail: _listaIds(mapa['semEmail']),
      falhas: falhas,
    );
  }

  List<String> _listaIds(dynamic valor) {
    if (valor is! List) return const [];
    return valor
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
