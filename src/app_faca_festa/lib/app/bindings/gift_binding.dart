import 'package:get/get.dart';

import 'package:app_faca_festa/app/bootstrap/gift_bootstrap.dart';

/// GetX route hook. Registration lives in [GiftBootstrap].
class GiftBinding extends Bindings {
  @override
  void dependencies() {
    GiftBootstrap.registerRoute();
  }
}
