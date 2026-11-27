import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/data/local/cache_offline_store.dart';
import 'package:app_faca_festa/data/models/convidado/convidado_model.dart';
import 'package:app_faca_festa/data/models/evento/evento_model.dart';
import 'package:app_faca_festa/domain/services/abrir_convite_por_token.dart';
import '../functions/callable_https_client.dart';

class AbrirConvitePorTokenService implements AbrirConvitePorToken {
  AbrirConvitePorTokenService({
    required FirebaseFunctions functions,
    required FirebaseAuth auth,
    required CallableHttpsClient httpsClient,
    CacheOfflineStore? cache,
  })  : _functions = functions,
        _auth = auth,
        _httpsClient = httpsClient,
        _cache = cache ?? GetStorageCacheOffline();

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final CallableHttpsClient _httpsClient;
  final CacheOfflineStore _cache;

  static const mensagemSemCache =
      'Abra este convite uma vez com internet para ver depois sem conexão.';

  @override
  Future<AbrirConvitePorTokenResultado> abrir(String token) async {
    final chave = 'convite_${chaveEstavel(token.trim())}';
    if (ConectividadeService.offlineAgora) return _doAparelho(chave);
    try {
      final mapa = await _chamar(token.trim());
      final tokenSessao = mapa['tokenSessao']?.toString() ?? '';
      if (tokenSessao.isNotEmpty) {
        await _auth.signInWithCustomToken(tokenSessao);
      } else {
        await _auth.currentUser?.getIdToken(true);
      }

      final resultado = _resultado(mapa);
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _cache.gravar(chave, {
          'uid': uid,
          'convidado': mapa['convidado'],
          'evento': mapa['evento'],
        });
      }
      return resultado;
    } on FirebaseFunctionsException catch (erro) {
      if (erroDeRede(erro)) return _doAparelho(chave);
      throw AbrirConvitePorTokenException(erro.code, erro.message);
    } on FirebaseAuthException catch (erro) {
      if (erroDeRede(erro)) return _doAparelho(chave);
      throw AbrirConvitePorTokenException(erro.code, erro.message);
    } on CallableHttpsException catch (erro) {
      if (erroDeRede(erro)) return _doAparelho(chave);
      throw AbrirConvitePorTokenException(erro.code, erro.message);
    } catch (erro) {
      if (erro is! AbrirConvitePorTokenException && erroDeRede(erro)) {
        return _doAparelho(chave);
      }
      rethrow;
    }
  }

  /// Último convite aberto neste aparelho, só para a mesma sessão de convidado
  /// que o abriu (a sessão do Firebase Auth também fica salva no aparelho).
  AbrirConvitePorTokenResultado _doAparelho(String chave) {
    final salvo = _cache.ler(chave);
    final uid = _auth.currentUser?.uid;
    if (salvo == null || uid == null || salvo['uid'] != uid) {
      throw const AbrirConvitePorTokenException('unavailable', mensagemSemCache);
    }
    return _resultado(salvo);
  }

  AbrirConvitePorTokenResultado _resultado(Map<String, dynamic> mapa) {
    final convidado = mapa['convidado'];
    final evento = mapa['evento'];
    if (convidado is! Map || evento is! Map) {
      throw const AbrirConvitePorTokenException('internal');
    }
    final convidadoModel = ConvidadoModel.fromMap(
      Map<String, dynamic>.from(convidado),
    );
    final eventoModel = EventoModel.fromMap(
      Map<String, dynamic>.from(evento),
    );
    if (convidadoModel.idConvidado.isEmpty || eventoModel.idEvento.isEmpty) {
      throw const AbrirConvitePorTokenException('not-found');
    }
    return AbrirConvitePorTokenResultado(
      convidado: convidadoModel,
      evento: eventoModel,
    );
  }

  Future<Map<String, dynamic>> _chamar(String token) async {
    final data = {'token': token};
    if (CallableHttpsClient.necessarioNaPlataformaAtual) {
      return _httpsClient.call('abrirConvitePorToken', data);
    }

    final callable = _functions.httpsCallable(
      'abrirConvitePorToken',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final result = await callable.call(data);
    final payload = result.data;
    if (payload is! Map) {
      throw const AbrirConvitePorTokenException('internal');
    }
    return Map<String, dynamic>.from(payload);
  }
}
