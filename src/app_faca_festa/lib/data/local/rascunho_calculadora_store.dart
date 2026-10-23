import 'cadastro_armazenamento.dart';
import 'dart:convert';
import 'package:app_faca_festa/domain/entities/cadastro_evento_rascunho.dart';
import 'package:get_storage/get_storage.dart';
import 'package:app_faca_festa/domain/entities/rascunho_calculadora.dart';
import 'package:app_faca_festa/domain/services/rascunho_calculadora_store.dart';

/// Recuperação local de uma vinculação pendente; não expõe a simulação no
/// documento público do evento. A chave é separada por organizador e evento.
class GetStorageRascunhoCalculadoraStore
    implements RascunhoCalculadoraStore, CadastroEventoRascunhoStore {
  GetStorageRascunhoCalculadoraStore(
      [GetStorage? storage, ArmazenamentoCadastroLocal? arquivos])
      : _storage = storage ?? GetStorage(),
        _arquivos = arquivos ?? criarArmazenamentoCadastro();
  final ArmazenamentoCadastroLocal _arquivos;
  final GetStorage _storage;
  String _chave(String usuario, String evento) =>
      'rascunho_calculadora_v1_${usuario}_$evento';
  @override
  RascunhoCalculadora? ler(String usuario, String evento) {
    final valor = _storage.read(_chave(usuario, evento));
    if (valor == null) return null;
    try {
      return RascunhoCalculadora.fromMap(
          Map<String, dynamic>.from(valor as Map));
    } catch (_) {
      // Preserva o original para recuperação; corrupção não vira ausência.
      throw const FormatException(
          'A estimativa local não pôde ser lida. O original foi preservado.');
    }
  }

  String _prefixo(String usuario) =>
      'cadastro_evento_v2_${base64Url.encode(utf8.encode(usuario))}_';
  String _cadastro(String usuario, String id) =>
      '${_prefixo(usuario)}${base64Url.encode(utf8.encode(id))}';
  @override
  Future<LeituraCadastrosLocais> listarCadastros(String usuario) async {
    final validos = <CadastroEventoRascunho>[];
    final corrompidos = <String>[];
    final registros = await _arquivos.listar(_prefixo(usuario));
    for (final chave in registros.keys) {
      if (!chave.startsWith(_prefixo(usuario))) continue;
      try {
        final c = CadastroEventoRascunho.fromMap(
            Map<String, dynamic>.from(jsonDecode(registros[chave]!) as Map));
        if (c.usuario != usuario || _cadastro(usuario, c.id) != chave) {
          throw const FormatException('Identidade local divergente.');
        }
        validos.add(c);
      } catch (_) {
        corrompidos.add(chave);
      }
    }
    validos.sort((a, b) => b.atualizadoEm.compareTo(a.atualizadoEm));
    return LeituraCadastrosLocais(
        List.unmodifiable(validos), List.unmodifiable(corrompidos));
  }

  @override
  Future<void> salvarCadastro(CadastroEventoRascunho cadastro) async {
    await _arquivos.gravar(
        _cadastro(cadastro.usuario, cadastro.id), jsonEncode(cadastro.toMap()));
  }

  @override
  Future<void> removerCadastro(String usuario, String id) async {
    await _arquivos.remover(_cadastro(usuario, id));
  }

  @override
  Future<void> salvar(
      String usuario, String evento, RascunhoCalculadora rascunho) async {
    await _storage.write(_chave(usuario, evento), rascunho.toMap());
  }

  @override
  Future<void> remover(String usuario, String evento) async {
    await _storage.remove(_chave(usuario, evento));
  }
}
