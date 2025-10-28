import 'dart:io';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
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
import './controllers/categoria/categoria_servico_controller.dart';
import './presentation/pages/fornecedor/orcamentos_screen.dart';
import './presentation/pages/welcome/welcome_event_screen.dart';
import './presentation/pages/admin/admin_dashboard_screen.dart';
import './presentation/pages/login/guest_register_screen.dart';
import './controllers/admin/orcamentos_admin_controller.dart';
import './presentation/pages/convidado/convidado_page.dart';
import './controllers/admin/eventos_admin_controller.dart';
import './presentation/pages/login/register_screen.dart';
import './controllers/orcamento_gasto_controller.dart';
import './controllers/evento_cadastro_controller.dart';
import './presentation/pages/login/login_screen.dart';
import './controllers/event_theme_controller.dart';
import './controllers/fornecedor_controller.dart';
import './controllers/orcamento_controller.dart';
import './controllers/tarefa_controller.dart';
import './presentation/widgets/splash.dart';

import './controllers/app_controller.dart';
import './role_selector_screen.dart';
import './firebase_options.dart';
import 'controllers/avaliacao/avaliacao_controller.dart';
import 'controllers/contacao/cotacao_controller.dart';
import 'controllers/convidado/cardapio_controller.dart';
import 'controllers/convidado/convidado_controller.dart';
import 'controllers/convidado/grupo_convidado_controller.dart';
import 'controllers/evento_controller.dart';
import 'controllers/servico/servico_foto_controller.dart';
//import 'popular_firebase.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return client;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await initializeDateFormatting('pt_BR', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔹 Configuração segura do EasyLoading
  configLoading();

  ///await popularFirebase();

  Get.put(AppController(), permanent: true);
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
  Get.put(AvaliacaoController(), permanent: true);
  Get.put(ServicoFotoController(), permanent: true);

  HttpOverrides.global = MyHttpOverrides();

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

      initialRoute: '/admin',
      getPages: [
        GetPage(name: '/splash', page: () => Splash()),
        GetPage(name: '/role', page: () => const RoleSelectorScreen()),
        GetPage(name: '/welcome', page: () => const WelcomeEventScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(name: '/admin', page: () => const AdminDashboardScreen()),
        GetPage(name: '/registerGuest', page: () => const GuestRegisterScreen()),
        GetPage(name: '/convidadosPage', page: () => const ConvidadosPage()),
        GetPage(
          name: '/orcamentos',
          page: () => const OrcamentosScreen(),
          transition: Transition.cupertino,
        ),
        GetPage(
          name: '/fornecedor',
          page: () => FornecedorHomeScreen(),
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
        ),
      ],

      /// 🔹 Builder: EasyLoading com proteção de múltiplas abas
      builder: (context, child) {
        try {
          return EasyLoading.init()(context, child);
        } catch (e) {
          debugPrint('⚠️ Falha ao inicializar EasyLoading: $e');
          return child ?? const SizedBox();
        }
      },
    );
  }
}

/// =============================
/// ⚙️ EASY LOADING CONFIGURADO
/// =============================
void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.light
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.pink.shade100
    ..indicatorColor = Colors.pinkAccent
    ..textColor = Colors.pink.shade800
    ..maskColor = Colors.pink.withValues(alpha: 0.2)
    ..userInteractions = false
    ..dismissOnTap = false;

  // 🔹 Ajuste especial para Web (evita "Unexpected null value")
  if (kIsWeb) {
    try {
      EasyLoading.instance.overlayEntry?.remove();
      EasyLoading.instance.overlayEntry = null;
      debugPrint('🧱 EasyLoading isolado nesta aba Web');
    } catch (e) {
      debugPrint('⚠️ Falha ao isolar overlay: $e');
    }
  }
}
