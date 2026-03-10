import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'dart:async';
import 'dart:io';

import './presentation/pages/convidado/area/area_convidado_home_screen.dart';
import './controllers/categoria/subcategoria_servico_controller.dart';
import './presentation/pages/fornecedor/fornecedor_home_screen.dart';
import './presentation/modules/gifts/gerenciar_presentes_page.dart';
import './controllers/categoria/categoria_servico_controller.dart';
import './presentation/pages/convidado/convite_redirect_page.dart';
import 'controllers/avaliacao/avaliacao_servico_controller.dart';
import './controllers/convidado/grupo_convidado_controller.dart';
import './presentation/pages/fornecedor/orcamentos_screen.dart';
import './presentation/pages/welcome/welcome_event_screen.dart';
import './presentation/pages/admin/admin_dashboard_screen.dart';
import './presentation/pages/login/guest_register_screen.dart';
import './controllers/admin/admin_territorio_controller.dart';
import 'controllers/usuario/endereco_usuario_controller.dart';
import './controllers/admin/orcamentos_admin_controller.dart';
import './controllers/contacao/solicitacoes_controller.dart';
import './controllers/servico/servico_foto_controller.dart';
import './presentation/pages/convidado/convidado_page.dart';
import './controllers/convidado/convidado_controller.dart';
import './controllers/admin/eventos_admin_controller.dart';
import 'core/services/whatsGw/whatsapp_cloud_service.dart';
import './controllers/convidado/cardapio_controller.dart';
import './presentation/pages/login/register_screen.dart';
import './presentation/whatsapp/whatsapp_templates.dart';
import './controllers/tema/event_theme_controller.dart';
import './controllers/contacao/cotacao_controller.dart';
import './controllers/evento_cadastro_controller.dart';
import './controllers/orcamento_gasto_controller.dart';
import './presentation/pages/login/login_screen.dart';
import 'controllers/usuario/usuario_controller.dart';
import 'core/services/whatsGw/whatsapp_service.dart';
import 'data/datasources/local/gift_local_datasource.dart';
import 'data/datasources/remote/gift_remote_datasource.dart';
import 'data/services/gift/gift_sync_service.dart';
import 'data/services/gift/sync_manager.dart';
import 'presentation/pages/home_event_screen.dart';
import './controllers/fornecedor_controller.dart';
import './controllers/orcamento_controller.dart';
import './controllers/evento_controller.dart';
import './controllers/tarefa_controller.dart';
import 'controllers/ranking_controller.dart';
import './presentation/widgets/splash.dart';
import './controllers/app_controller.dart';
import 'core/database/isar_database.dart';
import './role_selector_screen.dart';
import './firebase_options.dart';

/// =============================================================
/// 🔐 Permite conexões HTTPS mesmo com certificados inválidos (DEV)
/// =============================================================
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, __, ___) => true;
    return client;
  }
}

// =============================================================
//  🔔 NOTIFICAÇÕES PUSH (LOCAL + FCM)
// =============================================================
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _setupNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notificações Importantes',
    description: 'Canal usado para notificações de avaliações',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> _initLocalNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(settings);
}

// =============================================================
//  🔥 HANDLER DE NOTIFICAÇÕES EM FOREGROUND
// =============================================================
void _configureFirebaseForegroundHandler() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    final android = notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Notificações Importantes',
            icon: android.smallIcon,
          ),
        ),
      );
    }
  });
}

// =============================================================
//  MAIN
// =============================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INICIALIZE O FIREBASE PRIMEIRO
  // (Mova isso para o topo)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  HttpOverrides.global = MyHttpOverrides();
  await GetStorage.init();

  final remoteDatasource = GiftRemoteDatasource(FirebaseFirestore.instance);
  Get.put(remoteDatasource, permanent: true);
  final isar = await IsarDatabase.init();

  // 3. Verifica se o Isar iniciou com sucesso (Ou seja, NÃO é Web)
  if (isar != null) {
    Get.put<Isar>(isar, permanent: true);

    final localDatasource = GiftLocalDatasource(isar);
    Get.put(localDatasource, permanent: true);

    final giftSyncService = GiftSyncService(
      local: localDatasource,
      remote: remoteDatasource,
    );

    final syncManager = SyncManager(giftSyncService);
    Get.put(syncManager, permanent: true);
    await syncManager.start();

    print("📱 [MOBILE] Modo Offline-First Ativado!");
  } else {
    // É WEB! Não iniciamos o SyncManager nem o Datasource Local.
    print("🌐 [WEB] App rodando em modo Cloud-Only (Apenas Firebase).");
  }

  await initializeDateFormatting('pt_BR', null);

  // 🔔 Configurações de Push (Já pode usar o FirebaseMessaging também)
  await FirebaseMessaging.instance.requestPermission();
  await FirebaseMessaging.instance.getToken();

  await _initLocalNotifications();
  await _setupNotificationChannel();
  _configureFirebaseForegroundHandler();

  configLoading();

  // =============================================================
  //  🧠 REGISTRO DE CONTROLADORES
  // =============================================================
  Get.lazyPut<AppController>(() => AppController(), fenix: true);
  Get.put(EventoController(), permanent: true);
  Get.put(EventThemeController(), permanent: true);
  Get.put(OrcamentoController(), permanent: true);
  Get.put(EventoCadastroController(), permanent: true).carregarTiposEvento();
  Get.put(FornecedorController(), permanent: true);
  Get.put(OrcamentoGastoController(), permanent: true);
  Get.put(TarefaController(), permanent: true);
  Get.put(CategoriaServicoController(), permanent: true);
  Get.put(SubcategoriaServicoController(), permanent: true);
  Get.put(EventosAdminController(), permanent: true);
  Get.put(OrcamentosAdminController(), permanent: true);
  Get.put(ConvidadoController(), permanent: true);
  Get.put(CardapioController(), permanent: true);
  Get.put(GrupoConvidadoController(), permanent: true);
  Get.put(CotacaoController(), permanent: true);
  Get.put(SolicitacoesController(), permanent: true);
  Get.put(ServicoFotoController(), permanent: true);
  Get.put(AdminTerritorioController(), permanent: true);
  Get.put(EnderecoUsuarioController(), permanent: true);
  Get.put(UsuarioController(), permanent: true);
  Get.put(AvaliacaoServicoController(), permanent: true);
  Get.put(RankingController(), permanent: true);

  Get.put(
    WhatsAppService(apiKey: "64824efa-d959-4617-bccc-9a9f2a03e3b2"),
    permanent: true,
  );

  Get.put(
    WhatsAppCloudService(
      accessToken:
          "EAAQBMdidePwBPzF4bgveCltHv5sfLvJXkgTAYM5DlSakC0moxZBQ3kCWy4fxNYOMNh3IqZBa47KSrXZBYbJtbXsBQaHzF0Vyv8xUKPfDZAwcc3cQvP4Hmoe0kVszuin9kZA68lGW6drUAhoBFTXDN8g30yMPeSgeRNCVN72NBEb0ueP5SfTWEthg0kJP0ZAR5VlEBgnWSLl1eOmco4Dt2rNtiXmR56ie0t0Tx9bCXXYcjbEZCm9PmWNI8DetPxQJrAZD",
      phoneNumberId: "868592606338293",
    ),
    permanent: true,
  );

  Get.put(WhatsAppTemplates(), permanent: true);

  runApp(const FacaFestaApp());
}

class FacaFestaApp extends StatelessWidget {
  const FacaFestaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Faça a Festa',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/HomeEventScreen', page: () => const HomeEventScreen()),
        GetPage(name: '/splash', page: () => const Splash()),
        GetPage(name: '/role', page: () => const RoleSelectorScreen()),
        GetPage(name: '/welcome', page: () => const WelcomeEventScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(name: '/admin', page: () => const AdminDashboardScreen()),
        GetPage(name: '/registerGuest', page: () => const GuestRegisterScreen()),
        GetPage(name: '/convidadosPage', page: () => const ConvidadosPage()),
        GetPage(
          name: '/gerenciarPresentes',
          page: () {
            final args = Get.arguments as Map<String, dynamic>?;
            return GerenciarPresentesPage(
              eventoId: args?['eventoId'],
            );
          },
        ),
        /*
        GetPage(
          name: '/cadastrarPresente',
          page: () {
            final args = Get.arguments as Map<String, dynamic>?;
            return CadastrarPresentePage(
              eventoId: args?['eventoId'],
            );
          },
        ),
        */
        // 🔥 NOVA ROTA DE CONVITE
        GetPage(
          name: '/convite/:token',
          page: () => const ConviteRedirectPage(),
        ),

        GetPage(
          name: '/orcamentos',
          page: () => const OrcamentosScreen(),
          transition: Transition.cupertino,
        ),

        GetPage(name: '/fornecedor', page: () => FornecedorHomeScreen()),

        GetPage(
          name: '/areaconvidado',
          page: () {
            final args = Get.arguments as Map<String, dynamic>?;
            return AreaConvidadoHomeScreen(
              convidado: args?['convidado'],
              evento: args?['evento'],
            );
          },
        ),
      ],
      builder: (context, child) {
        try {
          return EasyLoading.init()(context, child);
        } catch (_) {
          return child ?? const SizedBox();
        }
      },
    );
  }
}

// =============================================================
// 🔧 EASYLOADING
// =============================================================
void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.light
    ..indicatorSize = 45
    ..radius = 10
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.pink.shade100
    ..indicatorColor = Colors.pinkAccent
    ..textColor = Colors.pink.shade800
    ..maskColor = Colors.pink.withValues(alpha: 0.2)
    ..userInteractions = false
    ..dismissOnTap = false;
}
