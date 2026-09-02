import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import './presentation/pages/convidado/area/area_convidado_home_screen.dart';
import './presentation/pages/fornecedor/fornecedor_home_screen.dart';
import './presentation/pages/fornecedor/auditoria_fornecedor_screen.dart';
import './presentation/pages/fornecedor/fornecedor_localizacao_screen.dart';
import './presentation/modules/gifts/gerenciar_presentes_page.dart';
import './presentation/pages/convidado/convite_nao_encontrado_screen.dart';
import './presentation/pages/convidado/convite_redirect_page.dart';
import 'core/utils/convite_link.dart';
import './presentation/pages/fornecedor/orcamentos_screen.dart';
import './presentation/pages/welcome/welcome_event_screen.dart';
import './presentation/pages/admin/admin_dashboard_screen.dart';
import './presentation/pages/admin/auditoria_admin_screen.dart';
import './presentation/pages/admin/auditoria_dashboard_screen.dart';
import './presentation/pages/convidado/convidado_page.dart';
import './presentation/pages/login/register_screen.dart';
import './presentation/pages/login/forgot_password_screen.dart';
import './presentation/pages/login/totp_setup_screen.dart';
import './presentation/pages/login/totp_verify_screen.dart';
import './presentation/pages/login/login_screen.dart';
import './presentation/modules/tema/controllers/event_theme_controller.dart';

import 'core/services/push/notification_service.dart';
import './presentation/pages/home_event_screen.dart';
import './presentation/widgets/splash.dart';
import './role_selector_screen.dart';
import './firebase_options.dart';
import 'app/bindings/gift_binding.dart';
import 'app/bootstrap/app_bootstrap.dart';
import 'app/bootstrap/app_check_bootstrap.dart';
import 'app/bootstrap/firebase_services_bootstrap.dart';
import 'app/bootstrap/gift_offline_bootstrap.dart';
import 'app/middleware/papel_middleware.dart';

// =============================================================
//  MAIN
// =============================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
  } catch (e, s) {
    debugPrint('⚠️ Firebase.initializeApp: $e\n$s');
  }
  FirebaseServicesBootstrap.register();

  unawaited(AppCheckBootstrap.activate());

  try {
    await GetStorage.init().timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('⚠️ GetStorage.init: $e');
  }

  if (!kIsWeb) {
    try {
      await GiftOfflineBootstrap.initialize()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('⚠️ Falha ao iniciar banco local: $e');
    }
  }

  try {
    await initializeDateFormatting('pt_BR', null)
        .timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('⚠️ initializeDateFormatting: $e');
  }

  if (!kIsWeb) {
    await initLocalNotifications();
    await setupNotificationChannel();
    await initPushNotifications(messaging: Get.find<FirebaseMessaging>());
  }

  configLoading();
  AppBootstrap.registerControllers();

  runApp(const FacaFestaApp());
}

String rotaInicial() {
  if (kIsWeb) {
    final token = ConviteLink.tokenDaUrl();
    if (token != null && token.isNotEmpty) {
      return '/convite/${Uri.encodeComponent(token)}';
    }
  }
  return '/splash';
}

class EntradaAppPage extends StatelessWidget {
  const EntradaAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (ConviteLink.tokenDaUrl() != null) {
      return const ConviteRedirectPage();
    }
    return const Splash();
  }
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
      theme: EventThemeController.montarThemeData(
        const Color(0xFF009688),
        const Color(0xFFE0F2F1),
      ),
      initialRoute: rotaInicial(),
      unknownRoute: GetPage(
        name: '/notfound',
        page: () => const EntradaAppPage(),
      ),
      getPages: [
        GetPage(
          name: '/HomeEventScreen',
          page: () => const HomeEventScreen(),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['O'])
          ],
        ),
        GetPage(name: '/splash', page: () => const Splash()),
        GetPage(name: '/role', page: () => const RoleSelectorScreen()),
        GetPage(
          name: '/welcome',
          page: () => const WelcomeEventScreen(),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['O'])
          ],
        ),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(
          name: '/loginTotpSetup',
          page: () => const TotpSetupScreen(),
        ),
        GetPage(
          name: '/loginTotp',
          page: () => const TotpVerifyScreen(),
        ),
        GetPage(
          name: '/forgotPassword',
          page: () => const ForgotPasswordScreen(),
        ),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(
          name: '/admin',
          page: () => const AdminDashboardScreen(),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['A'])
          ],
        ),
        GetPage(
          name: '/admin/auditoria',
          page: () => AuditoriaAdminScreen(),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['A'])
          ],
        ),
        GetPage(
          name: '/admin/auditoria/dashboard',
          page: () => AuditoriaDashboardScreen(),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['A'])
          ],
        ),
        GetPage(
          name: '/convidadosPage',
          page: () => const ConvidadosPage(),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['O'])
          ],
        ),
        GetPage(
          name: '/gerenciarPresentes',
          binding: GiftBinding(),
          page: () {
            final args = Get.arguments as Map<String, dynamic>?;
            return GerenciarPresentesPage(
              eventoId: args?['eventoId'] ?? '',
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
        GetPage(
          name: '/',
          page: () => const EntradaAppPage(),
        ),
        GetPage(
          name: '/convite',
          page: () => const ConviteRedirectPage(),
        ),
        GetPage(
          name: '/convite/:token',
          page: () => const ConviteRedirectPage(),
        ),
        GetPage(
          name: '/orcamentos',
          page: () => const OrcamentosScreen(),
          transition: Transition.cupertino,
        ),
        GetPage(
          name: '/fornecedores',
          page: () => const FornecedorLocalizacaoScreen(showLeading: true),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['O'])
          ],
        ),
        GetPage(
          name: '/fornecedor',
          page: () => const FornecedorHomeScreen(),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['F'])
          ],
        ),
        GetPage(
          name: '/fornecedor/auditoria',
          page: () => AuditoriaFornecedorScreen(),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['F'])
          ],
        ),
        GetPage(
          name: '/conviteNaoEncontrado',
          page: () => const ConviteNaoEncontradoScreen(),
        ),
        GetPage(
          name: '/areaconvidado',
          page: () {
            final args = Get.arguments as Map<String, dynamic>?;
            return AreaConvidadoHomeScreen(
              convidado: args?['convidado'],
              evento: args?['evento'],
            );
          },
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['C'])
          ],
        ),
      ],
      builder: (context, child) {
        final page = child ?? const EntradaAppPage();
        try {
          return EasyLoading.init()(context, page);
        } catch (_) {
          return page;
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
    ..progressColor = const Color(0xFF009688)
    ..backgroundColor = const Color(0xFFE0F2F1)
    ..indicatorColor = const Color(0xFF009688)
    ..textColor = const Color(0xFF00695C)
    ..maskColor = const Color(0xFF009688).withValues(alpha: 0.2)
    ..userInteractions = false
    ..dismissOnTap = false;
}
