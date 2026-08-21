import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../functions/callable_https_client.dart';

class AbrirConvitePorTokenException implements Exception {
  const AbrirConvitePorTokenException(this.codigo, [this.mensagem]);

  final String codigo;
  final String? mensagem;
}

class AbrirConvitePorTokenResultado {
  const AbrirConvitePorTokenResultado({
    required this.convidado,
    required this.evento,
  });

  final Map<String, dynamic> convidado;
  final Map<String, dynamic> evento;
}

class AbrirConvitePorTokenService {
  AbrirConvitePorTokenService({
    FirebaseFunctions? functions,
    CallableHttpsClient? httpsClient,
  })  : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'southamerica-east1'),
        _httpsClient = httpsClient ?? CallableHttpsClient();

  final FirebaseFunctions _functions;
  final CallableHttpsClient _httpsClient;

  Future<AbrirConvitePorTokenResultado> abrir(String token) async {
    try {
      final mapa = await _chamar(token.trim());
      final tokenSessao = mapa['tokenSessao']?.toString() ?? '';
      if (tokenSessao.isNotEmpty) {
        await FirebaseAuth.instance.signInWithCustomToken(tokenSessao);
      } else {
        await FirebaseAuth.instance.currentUser?.getIdToken(true);
      }

      final convidado = mapa['convidado'];
      final evento = mapa['evento'];
      if (convidado is! Map || evento is! Map) {
        throw const AbrirConvitePorTokenException('internal');
      }
      return AbrirConvitePorTokenResultado(
        convidado: Map<String, dynamic>.from(convidado),
        evento: Map<String, dynamic>.from(evento),
      );
    } on FirebaseFunctionsException catch (erro) {
      throw AbrirConvitePorTokenException(erro.code, erro.message);
    } on FirebaseAuthException catch (erro) {
      throw AbrirConvitePorTokenException(erro.code, erro.message);
    } on CallableHttpsException catch (erro) {
      throw AbrirConvitePorTokenException(erro.code, erro.message);
    }
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
