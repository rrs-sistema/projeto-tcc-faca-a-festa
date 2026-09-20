/// Monta o URL público `/convite/{token}` compartilhado com o convidado.
///
/// GetX na web usa hash routing por padrão, então o caminho efetivo é
/// `/#/convite/{token}` — o mesmo que [ConviteRedirectPage] já trata.
abstract final class ConviteLink {
  static const origemPublicaPadrao = 'https://faca-a-festa.web.app';
  static final _tokenNoCaminho =
      RegExp(r'/(?:convite|areaconvidado)/([^/?#\s]+)');

  static String rotaConvite(String? token) {
    final tokenLimpo = (token ?? '').trim();
    if (tokenLimpo.isEmpty) return '/convite';
    return '/convite/${Uri.encodeComponent(tokenLimpo)}';
  }

  static String rotaAreaConvidado(String? token) {
    final tokenLimpo = (token ?? '').trim();
    if (tokenLimpo.isEmpty) return '/areaconvidado';
    return '/areaconvidado/${Uri.encodeComponent(tokenLimpo)}';
  }

  static String url(String token, {String? origem}) {
    final tokenLimpo = token.trim();
    if (tokenLimpo.isEmpty) return '';

    final base = (origem ?? origemPublicaPadrao).replaceAll(RegExp(r'/+$'), '');
    return '$base/#/convite/${Uri.encodeComponent(tokenLimpo)}';
  }

  /// Lê o token em hash (`#/convite/{id}`), path ou URL completa.
  static String? tokenDaUrl([Uri? uri]) {
    final atual = uri ?? Uri.base;
    for (final bruto in [atual.fragment, atual.path, atual.toString()]) {
      final token = _tokenDoTrecho(bruto);
      if (token != null) return token;
    }
    return null;
  }

  /// Lê o token de um texto colado: URL, trecho de mensagem ou o id cru.
  static String? tokenDeTexto(String bruto) {
    final texto = bruto.trim();
    if (texto.isEmpty) return null;

    final noTexto = _tokenDoTrecho(texto);
    if (noTexto != null) return noTexto;

    final uri = Uri.tryParse(texto);
    if (uri != null) {
      final daUrl = tokenDaUrl(uri);
      if (daUrl != null && daUrl.isNotEmpty) return daUrl;
    }

    if (texto.contains('/') || RegExp(r'\s').hasMatch(texto)) return null;
    if (texto.length < 8) return null;
    return texto;
  }

  static String? _tokenDoTrecho(String bruto) {
    final match = _tokenNoCaminho.firstMatch(bruto);
    if (match == null) return null;
    final extraido = match.group(1)?.replaceAll(RegExp(r'[.,;!?]+$'), '') ?? '';
    if (extraido.isEmpty) return null;
    try {
      final token = Uri.decodeComponent(extraido).trim();
      return token.isEmpty ? null : token;
    } on ArgumentError {
      return extraido;
    }
  }
}
