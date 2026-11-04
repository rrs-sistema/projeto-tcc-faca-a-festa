/// Compartilha apenas leituras simultâneas; não guarda respostas nem comandos.
class ConsultasEmAndamento<T> {
  final _consultas = <String, Future<T>>{};

  Future<T> executar(String chave, Future<T> Function() ler) {
    final existente = _consultas[chave];
    if (existente != null) return existente;
    late final Future<T> consulta;
    consulta = Future<T>.sync(ler).whenComplete(() {
      if (identical(_consultas[chave], consulta)) {
        _consultas.remove(chave);
      }
    });
    _consultas[chave] = consulta;
    return consulta;
  }

  /// Uma gravação exige nova leitura, mesmo se a anterior ainda não terminou.
  void invalidar() => _consultas.clear();
}
