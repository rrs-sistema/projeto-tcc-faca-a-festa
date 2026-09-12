import 'package:get_storage/get_storage.dart';

import 'package:app_faca_festa/domain/services/evento_ativo_store.dart';

export 'package:app_faca_festa/domain/services/evento_ativo_store.dart';

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
