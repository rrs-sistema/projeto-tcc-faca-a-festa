import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

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
import 'controllers/calculadora_festa_controller.dart';
import 'controllers/inspiracao_controller.dart';
import 'controllers/usuario/endereco_usuario_controller.dart';
import './controllers/admin/orcamentos_admin_controller.dart';
import 'data/datasources/remote/gift_remote_datasource.dart';
import './controllers/contacao/solicitacoes_controller.dart';
import './controllers/servico/servico_foto_controller.dart';
import './presentation/pages/convidado/convidado_page.dart';
import './controllers/convidado/convidado_controller.dart';
import './controllers/admin/eventos_admin_controller.dart';
import 'data/datasources/local/gift_local_datasource.dart';
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

import 'core/services/push/notification_service.dart';
import 'core/database/database.dart';

import './data/services/gift/gift_sync_service.dart';
import './presentation/pages/home_event_screen.dart';
import './controllers/fornecedor_controller.dart';
import './controllers/orcamento_controller.dart';
import './data/services/gift/sync_manager.dart';
import './controllers/evento_controller.dart';
import './controllers/tarefa_controller.dart';
import 'controllers/ranking_controller.dart';
import './presentation/widgets/splash.dart';
import './controllers/app_controller.dart';
import 'core/database/app_database.dart';
import './role_selector_screen.dart';
import './firebase_options.dart';
import 'data/repositories/evento/calculadora_festa_remote_ai_service.dart';
import 'data/repositories/i_calculadora_festa_ai_service.dart';

// =============================================================
//  MAIN
// =============================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    providerAndroid: AndroidDebugProvider(),
    providerApple: AppleDebugProvider(),
  );

  /*
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode ? AndroidDebugProvider() : AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode ? AppleDebugProvider() : AppleDeviceCheckProvider(),
  );
  */

  await GetStorage.init();

  final remoteDatasource = GiftRemoteDatasource(FirebaseFirestore.instance);
  Get.put<GiftRemoteDatasource>(remoteDatasource, permanent: true);

  try {
    final db = await constructDb();
    Get.put<AppDatabase>(db, permanent: true);

    final localDatasource = GiftLocalDatasource(db);
    Get.put<GiftLocalDatasource>(localDatasource, permanent: true);

    final giftSyncService = GiftSyncService(
      local: localDatasource,
      remote: remoteDatasource,
    );
    Get.put<GiftSyncService>(giftSyncService, permanent: true);

    final syncManager = SyncManager(giftSyncService);
    Get.put<SyncManager>(syncManager, permanent: true);
    await syncManager.start();

    debugPrint(
      kIsWeb
          ? '🌐 [WEB] Offline-First com Drift/Wasm ativado!'
          : '📱/🖥️ Offline-First com Drift ativado!',
    );
  } catch (e) {
    debugPrint('⚠️ Falha ao iniciar banco local: $e');
  }

  await initializeDateFormatting('pt_BR', null);

  await initLocalNotifications();
  await setupNotificationChannel();
  await initPushNotifications();

  configLoading();
  _registerControllers();

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

void _registerControllers() {
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
  Get.put(InspiracaoController(), permanent: true);
  Get.put(CalculadoraFestaController(), permanent: true);
  Get.lazyPut<ICalculadoraFestaAIService>(
    () => CalculadoraFestaRemoteAIService(
      executor: (payload) async {
        final callable = FirebaseFunctions.instanceFor(
          region: 'southamerica-east1',
        ).httpsCallable(
          'analisarCalculadoraFestaIA',
          options: HttpsCallableOptions(
            timeout: const Duration(seconds: 60),
          ),
        );
        final result = await callable.call(payload);
        final data = result.data;
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        throw Exception(
          'Resposta inválida da Cloud Function analisarCalculadoraFestaIA.',
        );
      },
    ),
    fenix: true,
  );

  Get.lazyPut<CalculadoraFestaController>(
    () => CalculadoraFestaController(
      aiService: Get.find<ICalculadoraFestaAIService>(),
    ),
    fenix: true,
  );

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
