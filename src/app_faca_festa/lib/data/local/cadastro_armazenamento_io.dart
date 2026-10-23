import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'cadastro_armazenamento_contrato.dart';

ArmazenamentoCadastroLocal criarArmazenamentoCadastro() => CadastroArquivos();

/// Um arquivo por identidade evita regravar rascunhos de outros usuários.
class CadastroArquivos implements ArmazenamentoCadastroLocal {
  CadastroArquivos({this.diretorio});
  final Directory? diretorio;
  static final Map<String, Future<void>> _filas = {};
  Future<void> _serializar(String chave, Future<void> Function() acao) async {
    final pasta = await _pasta();
    final identidade = '${pasta.absolute.path}/$chave';
    final anterior = _filas[identidade] ?? Future<void>.value();
    final atual = anterior.catchError((Object _) {}).then((_) => acao());
    _filas[identidade] = atual;
    try {
      await atual;
    } finally {
      if (identical(_filas[identidade], atual)) _filas.remove(identidade);
    }
  }

  Future<Directory> _pasta() async {
    final pasta = diretorio ??
        Directory(
            '${(await getApplicationSupportDirectory()).path}/rascunhos_eventos');
    await pasta.create(recursive: true);
    return pasta;
  }

  Future<File> _arquivo(String chave) async {
    if (!RegExp(r'^[a-zA-Z0-9_=\-]+$').hasMatch(chave)) {
      throw ArgumentError('Chave inválida');
    }
    return File('${(await _pasta()).path}/$chave.json');
  }

  @override
  Future<Map<String, String>> listar(String prefixo) async {
    final pasta = await _pasta();
    final resultado = <String, String>{};
    await for (final item in pasta.list()) {
      if (item is! File) continue;
      final nome = item.uri.pathSegments.last;
      if (!nome.startsWith(prefixo) || !nome.endsWith('.json')) continue;
      resultado[nome.substring(0, nome.length - 5)] = await item.readAsString();
    }
    return resultado;
  }

  @override
  Future<void> gravar(String chave, String valor) =>
      _serializar(chave, () async {
        final arquivo = await _arquivo(chave);
        final temporario = File('${arquivo.path}.tmp');
        await temporario.writeAsString(valor, flush: true);
        await temporario.rename(arquivo.path);
      });
  @override
  Future<void> remover(String chave) => _serializar(chave, () async {
        final arquivo = await _arquivo(chave);
        if (await arquivo.exists()) await arquivo.delete();
      });
}
