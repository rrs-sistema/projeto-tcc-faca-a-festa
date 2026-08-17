import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AutenticacaoRemoteException implements Exception {
  const AutenticacaoRemoteException(this.codigo);

  final String codigo;
}

class SessaoUsuarioRemote {
  const SessaoUsuarioRemote({required this.idUsuario, this.email});

  final String idUsuario;
  final String? email;
}

abstract interface class AutenticacaoRemoteDatasource {
  String? get idUsuarioAtual;

  String? get emailUsuarioAtual;

  Stream<SessaoUsuarioRemote?> observarSessao();

  Future<void> entrar({
    required String email,
    required String senha,
  });

  Future<void> entrarComGoogle();

  Future<String> criarUsuario({
    required String email,
    required String senha,
  });

  Future<void> sair();
}

class FirebaseAutenticacaoRemoteDatasource
    implements AutenticacaoRemoteDatasource {
  FirebaseAutenticacaoRemoteDatasource(this.auth);

  final FirebaseAuth auth;
  bool _googleInicializado = false;

  @override
  String? get idUsuarioAtual => auth.currentUser?.uid;

  @override
  String? get emailUsuarioAtual => auth.currentUser?.email;

  @override
  Stream<SessaoUsuarioRemote?> observarSessao() => auth.authStateChanges().map(
        (usuario) => usuario == null
            ? null
            : SessaoUsuarioRemote(
                idUsuario: usuario.uid,
                email: usuario.email,
              ),
      );

  @override
  Future<void> entrar({
    required String email,
    required String senha,
  }) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: senha);
    } on FirebaseAuthException catch (erro) {
      throw AutenticacaoRemoteException(erro.code);
    }
  }

  @override
  Future<void> entrarComGoogle() async {
    try {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');

      if (kIsWeb) {
        await auth.signInWithPopup(provider);
        return;
      }

      try {
        await auth.signInWithProvider(provider);
        return;
      } on UnimplementedError {
        debugPrint(
          '[AutenticacaoRemote] signInWithProvider não implementado. '
          'Usando fallback do google_sign_in.',
        );
      } on FirebaseAuthException catch (erro) {
        debugPrint(
          '[AutenticacaoRemote] signInWithProvider falhou: '
          'code=${erro.code} | message=${erro.message}',
        );

        if (!_deveTentarFallbackGoogle(erro.code)) {
          rethrow;
        }
      }

      await _inicializarGoogleSignIn();

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const AutenticacaoRemoteException('google-sign-in-unsupported');
      }

      final contaGoogle = await GoogleSignIn.instance.authenticate();
      final autenticacaoGoogle = contaGoogle.authentication;
      final idToken = autenticacaoGoogle.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const AutenticacaoRemoteException('google-token-not-found');
      }

      final credencial = GoogleAuthProvider.credential(idToken: idToken);
      await auth.signInWithCredential(credencial);
    } on GoogleSignInException catch (erro) {
      debugPrint(
        '[AutenticacaoRemote] GoogleSignInException: '
        'code=${erro.code.name} | description=${erro.description} | details=${erro.details}',
      );
      throw AutenticacaoRemoteException(erro.code.name);
    } on FirebaseAuthException catch (erro) {
      debugPrint(
        '[AutenticacaoRemote] FirebaseAuthException Google: '
        'code=${erro.code} | message=${erro.message}',
      );
      throw AutenticacaoRemoteException(erro.code);
    } catch (erro, stack) {
      debugPrint('[AutenticacaoRemote] Erro inesperado no Google: $erro');
      debugPrint('$stack');
      throw const AutenticacaoRemoteException('google-unexpected-error');
    }
  }

  Future<void> _inicializarGoogleSignIn() async {
    if (_googleInicializado) return;
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '300274184803-6vk4dg1e2m1qouquq4jj9dafamh6qk8i.apps.googleusercontent.com',
    );
    _googleInicializado = true;
  }

  bool _deveTentarFallbackGoogle(String code) {
    return code == 'operation-not-supported-in-this-environment' ||
        code == 'unimplemented' ||
        code == 'unknown';
  }

  @override
  Future<String> criarUsuario({
    required String email,
    required String senha,
  }) async {
    try {
      final credencial = await auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );
      return credencial.user!.uid;
    } on FirebaseAuthException catch (erro) {
      throw AutenticacaoRemoteException(erro.code);
    }
  }

  @override
  Future<void> sair() async {
    try {
      if (!kIsWeb) {
        await _inicializarGoogleSignIn();
        await GoogleSignIn.instance.signOut();
      }
      await auth.signOut();
    } on FirebaseAuthException catch (erro) {
      throw AutenticacaoRemoteException(erro.code);
    }
  }
}
