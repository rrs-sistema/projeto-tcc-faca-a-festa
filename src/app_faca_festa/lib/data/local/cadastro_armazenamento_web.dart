import 'dart:js_interop';
import 'cadastro_armazenamento_contrato.dart';

@JS('localStorage')
external _Storage get _storage;
extension type _Storage._(JSObject _) implements JSObject {
  external int get length;
  external JSString? key(int index);
  external JSString? getItem(JSString chave);
  external void setItem(JSString chave, JSString valor);
  external void removeItem(JSString chave);
}
ArmazenamentoCadastroLocal criarArmazenamentoCadastro() => _CadastroNavegador();

class _CadastroNavegador implements ArmazenamentoCadastroLocal {
  @override
  Future<Map<String, String>> listar(String prefixo) async {
    final registros = <String, String>{};
    for (var i = 0; i < _storage.length; i++) {
      final chave = _storage.key(i)?.toDart;
      if (chave != null && chave.startsWith(prefixo)) {
        registros[chave] = _storage.getItem(chave.toJS)!.toDart;
      }
    }
    return registros;
  }

  @override
  Future<void> gravar(String chave, String valor) async {
    _storage.setItem(chave.toJS, valor.toJS);
  }

  @override
  Future<void> remover(String chave) async {
    _storage.removeItem(chave.toJS);
  }
}
