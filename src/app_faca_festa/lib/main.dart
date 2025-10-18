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
import 'controllers/event_theme_controller.dart';
import 'controllers/evento_cadastro_controller.dart';
import 'controllers/fornecedor_controller.dart';
import 'presentation/pages/convidado/convidado_page.dart';
import 'presentation/pages/login/guest_register_screen.dart';

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
        Get.put(FornecedoreController(), permanent: true);
        Get.put(EventoCadastroController(), permanent: true).carregarTiposEvento();
      }),
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/role', page: () => const RoleSelectorScreen()),
        GetPage(name: '/welcome', page: () => const WelcomeEventScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(name: '/admin', page: () => const AdminDashboardScreen()),
        GetPage(name: '/registerGuest', page: () => const GuestRegisterScreen()),
        GetPage(name: '/convidadosPage', page: () => const ConvidadosPage()),
        GetPage(
          name: '/fornecedor',
          page: () {
            final args = Get.arguments as Map<String, dynamic>?;
            return FornecedorHomeScreen(
              fornecedor: args?['fornecedor'],
            );
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
/// 🎬 SPLASH SCREEN
/// =============================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // ⏳ Espera 3 segundos antes de redirecionar
    await Future.delayed(const Duration(seconds: 3));

    final appController = Get.find<AppController>();

    if (appController.usuarioLogado.value != null) {
      if (appController.usuarioLogado.value!.tipo == 'F') {
        final fornecedor =
            await appController.buscarFornecedor(appController.usuarioLogado.value!.idUsuario);
        Get.offAllNamed(
          '/fornecedor',
          arguments: {'fornecedor': fornecedor},
        );
      } else if (appController.usuarioLogado.value!.tipo == '') {
        Get.offAllNamed('/role');
      }
    } else {
      Get.offAllNamed('/role');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF9C4), Color(0xFFFFC1E3), Color(0xFFB3E5FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, color: Colors.pink, size: 80),
              const SizedBox(height: 20),
              Text(
                "Faça a Festa",
                style: TextStyle(
                  color: Colors.pink.shade800,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const CircularProgressIndicator(color: Colors.pinkAccent),
              const SizedBox(height: 16),
              Text(
                "Carregando o seu evento...",
                style: TextStyle(
                  color: Colors.pink.shade800.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
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
