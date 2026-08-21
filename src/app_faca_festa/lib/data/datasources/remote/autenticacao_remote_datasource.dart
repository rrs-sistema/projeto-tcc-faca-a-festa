import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../domain/repositories/autenticacao_repository.dart';

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

  String? get nomeUsuarioAtual;

  String? get fotoUsuarioAtual;

  Stream<SessaoUsuarioRemote?> observarSessao();

  bool get sessaoAnonima;

  bool get sessaoVisitanteConvite;

  Future<void> entrarAnonimamente();

  Future<void> entrarComTokenCustomizado(String token);

  Future<void> entrar({
    required String email,
    required String senha,
  });

  /// `true` se autenticou. `false` se o usuário cancelou o seletor.
  Future<bool> entrarComGoogle();

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
  String? get nomeUsuarioAtual => auth.currentUser?.displayName;

  @override
  String? get fotoUsuarioAtual => auth.currentUser?.photoURL;

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
  bool get sessaoAnonima => auth.currentUser?.isAnonymous == true;

  @override
  bool get sessaoVisitanteConvite {
    final usuario = auth.currentUser;
    if (usuario == null) return false;
    if (usuario.isAnonymous) return true;
    return usuario.providerData.isEmpty;
  }

  @override
  Future<void> entrarAnonimamente() async {
    try {
      if (auth.currentUser != null) return;
      await auth.signInAnonymously();
    } on FirebaseAuthException catch (erro) {
      throw AutenticacaoRemoteException(erro.code);
    }
  }

  @override
  Future<void> entrarComTokenCustomizado(String token) async {
    try {
      await auth.signInWithCustomToken(token);
    } on FirebaseAuthException catch (erro) {
      throw AutenticacaoRemoteException(erro.code);
    }
  }

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
  Future<bool> entrarComGoogle() async {
    try {
      if (kIsWeb) {
        return await _entrarComGoogleWeb();
      }

      await _inicializarGoogleSignIn();

      // No celular, o seletor nativo devolve o token no próprio app.
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        return await _entrarComGoogleNativo();
      }

      return await _entrarComGoogleProvedorExterno();
    } on AutenticacaoRemoteException {
      rethrow;
    } on GoogleSignInException catch (erro) {
      if (_googleNativoFoiCancelado(erro)) {
        debugPrint(
          '[AutenticacaoRemote] Google cancelado pelo usuário: '
          '${erro.code.name}',
        );
        return false;
      }
      debugPrint(
        '[AutenticacaoRemote] GoogleSignInException: '
        'code=${erro.code.name} | description=${erro.description}',
      );
      throw AutenticacaoRemoteException(erro.code.name);
    } on FirebaseAuthException catch (erro) {
      if (autenticacaoFoiCancelada(erro.code)) {
        debugPrint(
          '[AutenticacaoRemote] Google cancelado pelo usuário: ${erro.code}',
        );
        return false;
      }
      debugPrint(
        '[AutenticacaoRemote] FirebaseAuthException Google: '
        'code=${erro.code} | message=${erro.message}',
      );
      throw AutenticacaoRemoteException(erro.code);
    } on PlatformException catch (erro) {
      if (autenticacaoFoiCancelada(erro.code)) {
        debugPrint(
          '[AutenticacaoRemote] Google cancelado pelo usuário: ${erro.code}',
        );
        return false;
      }
      debugPrint(
        '[AutenticacaoRemote] PlatformException Google: '
        'code=${erro.code} | message=${erro.message}',
      );
      throw const AutenticacaoRemoteException('google-unexpected-error');
    } catch (erro, stack) {
      debugPrint('[AutenticacaoRemote] Erro inesperado no Google: $erro');
      debugPrint('$stack');
      throw const AutenticacaoRemoteException('google-unexpected-error');
    }
  }

  Future<bool> _entrarComGoogleWeb() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');
    final atual = auth.currentUser;
    if (atual != null && atual.isAnonymous) {
      try {
        await atual.linkWithPopup(provider);
        return true;
      } on FirebaseAuthException catch (erro) {
        if (erro.code == 'credential-already-in-use' &&
            erro.credential != null) {
          await auth.signInWithCredential(erro.credential!);
          return true;
        }
        rethrow;
      }
    }
    await auth.signInWithPopup(provider);
    return true;
  }

  Future<bool> _entrarComGoogleNativo() async {
    try {
      final contaGoogle = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = contaGoogle.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const AutenticacaoRemoteException('google-token-not-found');
      }

      await _aplicarCredencialGoogle(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return true;
    } on GoogleSignInException catch (erro) {
      if (_googleNativoFoiCancelado(erro)) {
        debugPrint(
          '[AutenticacaoRemote] Seletor Google fechado sem conta: '
          '${erro.description}',
        );
        return false;
      }
      rethrow;
    }
  }

  Future<bool> _entrarComGoogleProvedorExterno() async {
    try {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      final atual = auth.currentUser;
      if (atual != null && atual.isAnonymous) {
        try {
          await atual.linkWithProvider(provider);
          return true;
        } on FirebaseAuthException catch (erro) {
          if (erro.code == 'credential-already-in-use' &&
              erro.credential != null) {
            await auth.signInWithCredential(erro.credential!);
            return true;
          }
          rethrow;
        }
      }
      await auth.signInWithProvider(provider);
      return true;
    } on FirebaseAuthException catch (erro) {
      if (autenticacaoFoiCancelada(erro.code)) {
        return false;
      }
      rethrow;
    } on PlatformException catch (erro) {
      if (autenticacaoFoiCancelada(erro.code)) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> _aplicarCredencialGoogle(AuthCredential credencial) async {
    final atual = auth.currentUser;
    if (atual != null && atual.isAnonymous) {
      try {
        await atual.linkWithCredential(credencial);
        return;
      } on FirebaseAuthException catch (erro) {
        if (erro.code == 'credential-already-in-use') {
          await auth.signInWithCredential(credencial);
          return;
        }
        rethrow;
      }
    }
    await auth.signInWithCredential(credencial);
  }

  bool _googleNativoFoiCancelado(GoogleSignInException erro) {
    return erro.code == GoogleSignInExceptionCode.canceled ||
        autenticacaoFoiCancelada(erro.code.name);
  }

  Future<void> _inicializarGoogleSignIn() async {
    if (_googleInicializado) return;
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '300274184803-6vk4dg1e2m1qouquq4jj9dafamh6qk8i.apps.googleusercontent.com',
    );
    _googleInicializado = true;
  }

  @override
  Future<String> criarUsuario({
    required String email,
    required String senha,
  }) async {
    try {
      final atual = auth.currentUser;
      if (atual != null && atual.isAnonymous) {
        final vinculada = await atual.linkWithCredential(
          EmailAuthProvider.credential(email: email, password: senha),
        );
        return vinculada.user!.uid;
      }
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
