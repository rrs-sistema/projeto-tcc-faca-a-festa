/// Persists which event the organizer last had open, per user.
abstract interface class EventoAtivoStore {
  String? ler(String idUsuario);

  void salvar(String idUsuario, String idEvento);

  void limpar(String idUsuario);
}

class MemoriaEventoAtivoStore implements EventoAtivoStore {
  final Map<String, String> valores = {};

  @override
  String? ler(String idUsuario) => valores[idUsuario];

  @override
  void salvar(String idUsuario, String idEvento) {
    valores[idUsuario] = idEvento;
  }

  @override
  void limpar(String idUsuario) {
    valores.remove(idUsuario);
  }
}

class NoOpEventoAtivoStore implements EventoAtivoStore {
  const NoOpEventoAtivoStore();

  @override
  String? ler(String idUsuario) => null;

  @override
  void salvar(String idUsuario, String idEvento) {}

  @override
  void limpar(String idUsuario) {}
}
