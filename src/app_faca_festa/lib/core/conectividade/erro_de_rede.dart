/// Erros que significam "não deu para falar com o servidor", não recusa.
bool erroDeRede(Object erro) {
  final texto = erro.toString().toLowerCase();
  final codigo = _codigo(erro);
  return const {
        'unavailable',
        'deadline-exceeded',
        'network-request-failed',
        'sem-conexao',
      }.contains(codigo) ||
      texto.contains('timeoutexception') ||
      texto.contains('socketexception') ||
      texto.contains('failed host lookup') ||
      texto.contains('connection refused') ||
      texto.contains('connection reset') ||
      texto.contains('network is unreachable') ||
      texto.contains('unable to resolve host') ||
      texto.contains('failed to connect');
}

String _codigo(Object erro) {
  try {
    final codigo = (erro as dynamic).code;
    if (codigo is String) return codigo;
  } catch (_) {}
  try {
    final codigo = (erro as dynamic).codigo;
    if (codigo is String) return codigo;
  } catch (_) {}
  return '';
}
