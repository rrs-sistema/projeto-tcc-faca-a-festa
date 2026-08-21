/// Monta o URL público `/convite/{token}` compartilhado com o convidado.
///
/// GetX na web usa hash routing por padrão, então o caminho efetivo é
/// `/#/convite/{token}` — o mesmo que [ConviteRedirectPage] já trata.
abstract final class ConviteLink {
  static const origemPublicaPadrao = 'https://faca-a-festa.web.app';
  static final _tokenNoCaminho = RegExp(r'/convite/([^/?#]+)');

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
      final match = _tokenNoCaminho.firstMatch(bruto);
      if (match == null) continue;
      final token = Uri.decodeComponent(match.group(1)!.trim());
      if (token.isNotEmpty) return token;
    }
    return null;
  }
}
