import 'dart:convert';
import 'cadastro_armazenamento.dart';

abstract interface class RecebimentoPendenteStore {
  Future<Map<String, dynamic>?> ler(String usuario);
  Future<void> salvar(String usuario, Map<String, dynamic> operacao);
  Future<void> limpar(String usuario, {String? chave});
}

/// Reusa a persistência local com arquivo temporário, flush e rename no desktop.
/// Não usa GetStorage.write, cujo Future termina antes do flush em disco.
class RecebimentoPendenteLocalStore implements RecebimentoPendenteStore {
  RecebimentoPendenteLocalStore(
      {ArmazenamentoCadastroLocal? arquivos,
      this.namespace = 'recebimento_pendente_v1'})
      : _arquivos = arquivos ?? criarArmazenamentoCadastro();
  final ArmazenamentoCadastroLocal _arquivos;
  final String namespace;
  static final Map<String, Future<void>> _filas = {};
  String _chave(String uid) =>
      '${namespace}_${base64Url.encode(utf8.encode(uid))}';
  @override
  Future<Map<String, dynamic>?> ler(String usuario) async {
    final chave = _chave(usuario);
    final dado = (await _arquivos.listar(chave))[chave];
    if (dado == null) return null;
    final m = Map<String, dynamic>.from(jsonDecode(dado) as Map);
    if (m['chave'] is! String || m['pedido'] is! Map) {
      throw const FormatException(
          'Operação pendente inválida; original preservado.');
    }
    return m;
  }

  Future<void> _serializar(String uid, Future<void> Function() acao) async {
    final anterior = _filas[uid] ?? Future<void>.value();
    final atual = anterior.catchError((Object _) {}).then((_) => acao());
    _filas[uid] = atual;
    try {
      await atual;
    } finally {
      if (identical(_filas[uid], atual)) _filas.remove(uid);
    }
  }

  @override
  Future<void> salvar(String usuario, Map<String, dynamic> operacao) =>
      _serializar(usuario, () async {
        final anterior = await ler(usuario);
        if (anterior != null && anterior['chave'] != operacao['chave']) {
          throw StateError('Outra operação pendente já está preservada.');
        }
        await _arquivos.gravar(_chave(usuario), jsonEncode(operacao));
      });
  @override
  Future<void> limpar(String usuario, {String? chave}) =>
      _serializar(usuario, () async {
        if (chave != null && (await ler(usuario))?['chave'] != chave) return;
        await _arquivos.remover(_chave(usuario));
      });
}
