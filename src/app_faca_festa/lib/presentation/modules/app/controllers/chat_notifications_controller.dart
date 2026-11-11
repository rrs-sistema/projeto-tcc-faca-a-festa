import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/platform/plataforma_app.dart';
import 'package:app_faca_festa/data/repositories_impl/push_token_repository_impl.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/cotacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/chat/chat_mensagens_page.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

/// Registro de push após validar a sessão/MFA.
class ChatNotificationsController extends GetxService {
  ChatNotificationsController(this.messaging);
  final FirebaseMessaging messaging;
  late final _push = FirebasePushTokenRepository(messaging: messaging);
  Usuario? _usuario;
  DocumentReference<Map<String, dynamic>>? _dispositivo;
  bool _registroConfirmado = false;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _mensagemSub;
  StreamSubscription<RemoteMessage>? _aberturaSub;
  RemoteMessage? _pendente;
  int _geracao = 0;
  Future<void> _gravacao = Future.value();

  Future<void> initialize() async {
    if (!_push.suportaTokenPush || !await messaging.isSupported()) return;
    _mensagemSub = FirebaseMessaging.onMessage.listen((m) {
      if (!_destinadoAoUsuario(m)) return;
      final repasse = m.data['screen'] == 'autorizacao_repasse';
      Get.snackbar(
        m.notification?.title ??
            (repasse
                ? 'Autorização de pagamento antecipado'
                : 'Nova mensagem no chat'),
        m.notification?.body ??
            (repasse
                ? 'O organizador registrou a autorização.'
                : 'Você recebeu uma mensagem.'),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 6),
        mainButton: TextButton(
          onPressed: () => unawaited(_abrir(m)),
          child: Text(repasse ? 'Ver contrato' : 'Abrir conversa'),
        ),
      );
    });
    _aberturaSub = FirebaseMessaging.onMessageOpenedApp.listen((m) {
      _pendente = m;
      abrirPendente();
    });
    _pendente = await messaging.getInitialMessage();
    if (PlataformaApp.ehWeb) {
      final params = Uri.base.queryParameters;
      final screen = params['push_screen'];
      if (screen == 'chat_cotacao' || screen == 'autorizacao_repasse') {
        _pendente = RemoteMessage(data: {
          'screen': screen,
          'id_cotacao': params['push_cotacao'] ?? '',
          'id_fornecedor': params['push_fornecedor'] ?? '',
          'id_orcamento': params['push_orcamento'] ?? '',
          'id_destinatario': params['push_destinatario'] ?? '',
        });
      }
    }
  }

  bool _destinadoAoUsuario(RemoteMessage m) =>
      _usuario != null &&
      FirebaseAuth.instance.currentUser?.uid == _usuario!.idUsuario &&
      (m.data['screen'] == 'chat_cotacao' ||
          (m.data['screen'] == 'autorizacao_repasse' &&
              _usuario!.tipo == 'F')) &&
      m.data['id_destinatario'] == _usuario!.idUsuario;

  Future<void> iniciar(Usuario usuario) async {
    if (!_push.suportaTokenPush || _usuario?.idUsuario == usuario.idUsuario) {
      return;
    }
    await encerrar(limparPendente: false);
    if (FirebaseAuth.instance.currentUser?.uid != usuario.idUsuario) return;
    _usuario = usuario;
    final geracao = _geracao;
    try {
      // A assinatura precede getToken para não perder uma renovação inicial.
      _tokenSub = _push.observarAtualizacoesToken().listen(
            (token) => _registrar(token, usuario.idUsuario, geracao),
            onError: (Object e) =>
                debugPrint('Falha ao renovar token push: ${e.runtimeType}'),
          );
      await _push.solicitarPermissao();
      final token = await _push.obterTokenAtual();
      if (token != null) _registrar(token, usuario.idUsuario, geracao);
    } catch (e) {
      debugPrint('Não foi possível habilitar notificações: ${e.runtimeType}');
    }
    abrirPendente();
  }

  Future<void> habilitarNotificacoes() async {
    final usuario = _usuario;
    if (usuario == null) return;
    // Mantém a solicitação vinculada ao clique em navegadores que exigem gesto.
    await _push.solicitarPermissao();
    await encerrar(limparPendente: false);
    await iniciar(usuario);
    await _gravacao;
    final settings = await messaging.getNotificationSettings();
    final permitida =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    Get.snackbar(
      'Notificações do chat',
      permitida && _registroConfirmado
          ? 'Notificações habilitadas neste dispositivo.'
          : 'Não foi possível habilitar os avisos. Verifique a permissão de notificações nas configurações do navegador ou dispositivo.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _registrar(String token, String uid, int geracao) {
    _gravacao = _gravacao.then((_) async {
      if (token.isEmpty ||
          geracao != _geracao ||
          FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }
      final ref = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('dispositivos_push')
          .doc(sha256.convert(utf8.encode(token)).toString());
      if (_dispositivo != null && _dispositivo!.path != ref.path) {
        await _dispositivo!.delete();
      }
      if (geracao != _geracao) return;
      _dispositivo = ref;
      _registroConfirmado = false;
      await ref.set({
        'token': token,
        'plataforma': PlataformaApp.identificador,
        'atualizado_em': FieldValue.serverTimestamp(),
      });
      if (geracao == _geracao) _registroConfirmado = true;
    }).catchError((Object e) {
      debugPrint('Falha ao registrar dispositivo push: ${e.runtimeType}');
    });
  }

  void abrirPendente() {
    final m = _pendente;
    if (m == null || _usuario == null) return;
    _pendente = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_abrir(m)));
  }

  Future<void> _abrir(RemoteMessage m) async {
    if (!_destinadoAoUsuario(m)) return;
    final usuario = _usuario!;
    if (m.data['screen'] == 'autorizacao_repasse') {
      final idOrcamento = m.data['id_orcamento']?.toString() ?? '';
      if (idOrcamento.isEmpty || idOrcamento.contains('/')) return;
      await Get.toNamed('/acompanhamento-fornecedor',
          arguments: {
            'idFornecedor': usuario.idUsuario,
            'idOrcamento': idOrcamento,
          },
          preventDuplicates: false);
      return;
    }
    final idCotacao = m.data['id_cotacao']?.toString() ?? '';
    final idFornecedor = m.data['id_fornecedor']?.toString() ?? '';
    if (idCotacao.isEmpty ||
        idFornecedor.isEmpty ||
        idCotacao.contains('/') ||
        idFornecedor.contains('/')) {
      return;
    }
    try {
      final db = FirebaseFirestore.instance;
      final cotacao = await db.collection('cotacao').doc(idCotacao).get();
      final outroId = usuario.idUsuario == idFornecedor
          ? (cotacao.data()?['id_usuario_solicitante']?.toString())
          : idFornecedor;
      if (outroId == null || !_destinadoAoUsuario(m)) return;
      final fornecedor = await db
          .collection('cotacao')
          .doc(idCotacao)
          .collection('fornecedores')
          .doc(idFornecedor)
          .get();
      if (!fornecedor.exists || !_destinadoAoUsuario(m)) return;
      final dadosCotacao = cotacao.data();
      final data = dadosCotacao?['data_envio'] ?? fornecedor.data()?['data_envio'];
      await Get.to(() => ChatMensagensPage(
            idCotacao: idCotacao,
            idFornecedor: idFornecedor,
            nomeFornecedor: usuario.idUsuario == idFornecedor
                ? (dadosCotacao?['nome_usuario_solicitante']?.toString() ??
                    'Cliente')
                : (fornecedor.data()?['nome_fornecedor']?.toString() ??
                    'Fornecedor'),
            dataSolicitacao: data is Timestamp ? data.toDate() : null,
            categoriaPedido: dadosCotacao?['categoria_nome']?.toString(),
            observacaoPedido:
                (dadosCotacao?['observacao'] ?? dadosCotacao?['descricao'])
                    ?.toString(),
            cotacoes: Get.find<CotacaoController>().gerenciarCotacoes,
            theme: Get.find<EventThemeController>(),
            usuario: usuario,
          ));
    } catch (e) {
      debugPrint('Falha ao abrir conversa da notificação: ${e.runtimeType}');
    }
  }

  Future<void> encerrar({bool limparPendente = true}) async {
    ++_geracao;
    _usuario = null;
    if (limparPendente) _pendente = null;
    await _tokenSub?.cancel();
    _tokenSub = null;
    // Firestore pode manter escritas pendentes offline; isso não deve prender o logout.
    try {
      await _gravacao.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      debugPrint('Registro push pendente durante encerramento da sessão.');
    }
    final ref = _dispositivo;
    _dispositivo = null;
    _registroConfirmado = false;
    try {
      await ref?.delete().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Falha ao remover dispositivo push: ${e.runtimeType}');
    }
  }

  @override
  void onClose() {
    unawaited(_mensagemSub?.cancel());
    unawaited(_aberturaSub?.cancel());
    unawaited(encerrar());
    super.onClose();
  }
}
