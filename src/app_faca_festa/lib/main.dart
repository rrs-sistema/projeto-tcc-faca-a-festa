import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import './presentation/pages/convidado/area/area_convidado_home_screen.dart';
import './presentation/pages/fornecedor/fornecedor_home_screen.dart';
import './presentation/pages/welcome/welcome_event_screen.dart';
import './presentation/pages/admin/admin_dashboard_screen.dart';
import './presentation/pages/login/register_screen.dart';
import './presentation/pages/login/login_screen.dart';
import './controllers/app_controller.dart';
import './role_selector_screen.dart';
import './firebase_options.dart';
import './popular_firebase.dart';
import 'controllers/categoria_servico_controller.dart';
import 'controllers/event_theme_controller.dart';
import 'controllers/evento_cadastro_controller.dart';
import 'controllers/fornecedor_controller.dart';
import 'controllers/orcamento_controller.dart';
import 'controllers/orcamento_gasto_controller.dart';
import 'presentation/pages/convidado/convidado_page.dart';
import 'presentation/pages/fornecedor/orcamentos_screen.dart';
import 'presentation/pages/login/guest_register_screen.dart';
import 'presentation/widgets/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  configLoading();
  await popularFirebase(); // popula Firestore se vazio

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
      initialBinding: BindingsBuilder(() {
        Get.put(AppController(), permanent: true);
        Get.put(EventThemeController(), permanent: true);
        Get.put(OrcamentoController(), permanent: true);
        Get.put(EventoCadastroController(), permanent: true).carregarTiposEvento();
        Get.put(FornecedorController(), permanent: true);
        Get.put(CategoriaServicoController(), permanent: true);
        Get.put(OrcamentoGastoController(), permanent: true);
      }),
      initialRoute: '/splash',
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
          page: () {
            return FornecedorHomeScreen();
          },
        ),
        // 🔹 Corrigido: usa Get.arguments para receber parâmetros
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
        /*
          // Como chamar:
          Get.offAll(
            () => AreaConvidadoHomeScreen(convidado: usuario, evento: evento),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 600),
          );
            ou 
          Get.offAllNamed(
            '/areaconvidado',
            arguments: {
              'convidado': usuario,
              'evento': evento,
            },
          );
        */
      ],
      builder: EasyLoading.init(),
    );
  }
}

/// =============================
/// ⚙️ EASY LOADING
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
}
