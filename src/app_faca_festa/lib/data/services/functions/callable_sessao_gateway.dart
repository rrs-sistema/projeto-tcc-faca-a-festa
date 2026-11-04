import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'callable_https_client.dart';
import 'financeiro_callable_gateway.dart';

abstract interface class CallableSessaoGateway {
  String? get usuario;
  Stream<String?> get sessoes;
  Future<Map<String, dynamic>> chamar(
      String funcao, Map<String, dynamic> dados);
}

/// Transporte existente: HTTPS autenticado no Windows e SDK nas demais plataformas.
class FirebaseCallableSessaoGateway implements CallableSessaoGateway {
  FirebaseCallableSessaoGateway(
      {FirebaseAuth? auth,
      FirebaseFunctions? functions,
      CallableHttpsClient? httpsClient,
      FinanceiroCallableGateway? gateway})
      : _auth = auth ?? FirebaseAuth.instance,
        _gateway = gateway ??
            FinanceiroCallableGateway(
                functions: functions ??
                    (Get.isRegistered<FirebaseFunctions>()
                        ? Get.find<FirebaseFunctions>()
                        : FirebaseFunctions.instanceFor(
                            region: 'southamerica-east1')),
                httpsClient: httpsClient ??
                    (Get.isRegistered<CallableHttpsClient>()
                        ? Get.find<CallableHttpsClient>()
                        : null));
  final FirebaseAuth _auth;
  final FinanceiroCallableGateway _gateway;
  @override
  String? get usuario => _auth.currentUser?.uid;
  @override
  Stream<String?> get sessoes =>
      _auth.authStateChanges().map((u) => u?.uid).distinct();
  @override
  Future<Map<String, dynamic>> chamar(
      String funcao, Map<String, dynamic> dados) async {
    try {
      return await _gateway.call(funcao, dados);
    } on FinanceiroCallableException catch (e) {
      throw FirebaseFunctionsException(
          code: e.code,
          message: e.message ?? 'Falha ao processar a operação.',
          details: null);
    }
  }
}
