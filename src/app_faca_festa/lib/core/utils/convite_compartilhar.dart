import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

enum ResultadoCompartilhamento { compartilhou, copiou }

/// Tenta a folha nativa; se o plugin não estiver no build, copia o texto.
Future<ResultadoCompartilhamento> compartilharTextoConvite({
  required String texto,
  String? assunto,
}) async {
  try {
    await Share.share(texto, subject: assunto);
    return ResultadoCompartilhamento.compartilhou;
  } on MissingPluginException {
    await Clipboard.setData(ClipboardData(text: texto));
    return ResultadoCompartilhamento.copiou;
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: texto));
    return ResultadoCompartilhamento.copiou;
  }
}
