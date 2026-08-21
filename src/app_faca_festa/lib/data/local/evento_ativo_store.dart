import 'package:get_storage/get_storage.dart';

/// Persists which event the organizer last had open, per user.
abstract interface class EventoAtivoStore {
  String? ler(String idUsuario);

  void salvar(String idUsuario, String idEvento);

  void limpar(String idUsuario);
}

class GetStorageEventoAtivoStore implements EventoAtivoStore {
  GetStorageEventoAtivoStore([GetStorage? storage])
      : _storage = storage ?? GetStorage();

  final GetStorage _storage;

  static String chave(String idUsuario) => 'evento_ativo_$idUsuario';

  @override
  String? ler(String idUsuario) {
    final valor = _storage.read(chave(idUsuario));
    if (valor is String && valor.trim().isNotEmpty) return valor.trim();
    return null;
  }

  @override
  void salvar(String idUsuario, String idEvento) {
    if (idUsuario.trim().isEmpty || idEvento.trim().isEmpty) return;
    _storage.write(chave(idUsuario), idEvento.trim());
  }

  @override
  void limpar(String idUsuario) {
    _storage.remove(chave(idUsuario));
  }
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
