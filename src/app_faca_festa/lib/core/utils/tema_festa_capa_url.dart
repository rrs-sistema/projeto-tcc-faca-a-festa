abstract final class TemaFestaCapaUrl {
  static const storageBucket = 'faca-a-festa.firebasestorage.app';

  static String? urlCapaStorage(
    String? idTema, {
    String slugOutro = 'outro',
  }) {
    final id = (idTema ?? '').trim();
    if (id.isEmpty || id == slugOutro) return null;
    final path = Uri.encodeComponent('temas/$id/capa.jpg');
    return 'https://firebasestorage.googleapis.com/v0/b/$storageBucket/o/$path?alt=media';
  }

  static String? capaEfetiva({
    required String idTema,
    String? imagemCapaUrl,
    String slugOutro = 'outro',
  }) {
    final gravada = (imagemCapaUrl ?? '').trim();
    if (gravada.isNotEmpty) return gravada;
    return urlCapaStorage(idTema, slugOutro: slugOutro);
  }
}
