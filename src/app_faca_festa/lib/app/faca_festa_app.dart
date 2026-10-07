import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/legal/widgets/vigia_aceite_politica.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'routes/app_routes.dart';

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
      initialRoute: AppRoutes.initialRoute(),
      unknownRoute: AppRoutes.unknownRoute,
      getPages: AppRoutes.pages,
      builder: (context, child) {
        final page = VigiaAceitePolitica(
          child: child ?? const EntradaAppPage(),
        );
        try {
          return EasyLoading.init()(context, page);
        } catch (_) {
          return page;
        }
      },
    );
  }
}

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
