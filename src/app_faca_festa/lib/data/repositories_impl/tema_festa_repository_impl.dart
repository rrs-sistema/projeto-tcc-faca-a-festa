import 'package:app_faca_festa/domain/entities/tema_festa.dart';
import 'package:app_faca_festa/domain/exceptions/tema_festa_exception.dart';
import 'package:app_faca_festa/domain/repositories/tema_festa_repository.dart';
import '../datasources/remote/tema_festa_remote_datasource.dart';
import '../models/evento/tema_festa_model.dart';
import '../seeds/tema_festa_seed.dart';
import '../services/functions/callable_https_client.dart';

class TemaFestaRepositoryImpl implements TemaFestaRepository {
  TemaFestaRepositoryImpl(this.remote);

  final TemaFestaRemoteDatasource remote;

  @override
  Future<List<TemaFesta>> carregar() {
    return remote.carregar();
  }

  @override
  Future<TemaFesta?> buscarPorId(String idTema) {
    return remote.buscarPorId(idTema);
  }

  @override
  Future<void> salvar(TemaFesta tema) {
    return remote.salvar(TemaFestaModel.fromEntity(tema));
  }

  @override
  Future<void> excluir(String idTema) {
    return remote.excluir(idTema);
  }

  @override
  Future<String?> enviarCapa({
    required String idTema,
    required List<int> bytes,
  }) {
    return _traduzirErroCallable(
      () => remote.enviarCapa(idTema: idTema, bytes: bytes),
    );
  }

  @override
  Future<void> removerCapaStorage({required String idTema}) {
    return _traduzirErroCallable(
      () => remote.removerCapaStorage(idTema: idTema),
    );
  }

  @override
  @override
  List<TemaFesta> catalogoInicial() {
    return List<TemaFesta>.unmodifiable(temasFestaIniciais);
  }

  @override
  Future<void> popularTemasIniciais({
    required List<TemaFesta> temasExistentes,
  }) {
    return remote.popularTemasIniciais(
      temasExistentes: temasExistentes.map(TemaFestaModel.fromEntity).toList(),
    );
  }

  Future<T> _traduzirErroCallable<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on CallableHttpsException catch (e) {
      throw TemaFestaException(e.code, e.message);
    }
  }
}
