import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:app_faca_festa/core/platform/plataforma_app.dart';
import 'package:app_faca_festa/domain/repositories/push_token_repository.dart';

class FirebasePushTokenRepository implements PushTokenRepository {
  FirebasePushTokenRepository({required FirebaseMessaging messaging})
      : _messaging = messaging;

  final FirebaseMessaging _messaging;

  @override
  bool get suportaTokenPush {
    if (PlataformaApp.ehWeb) return true;
    return PlataformaApp.ehAndroidOuIos;
  }

  @override
  Future<void> solicitarPermissao() async {
    await _messaging.requestPermission();
  }

  @override
  Future<String?> obterTokenAtual() {
    return _messaging.getToken();
  }

  @override
  Stream<String> observarAtualizacoesToken() {
    return _messaging.onTokenRefresh;
  }
}
