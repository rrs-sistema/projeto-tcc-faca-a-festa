import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class FornecedorMigracaoAdminController extends GetxController {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  final RxBool carregando = false.obs;
  final RxString resultado = ''.obs;
  final RxString erro = ''.obs;

  Future<void> migrarTiposEventoFornecedores({
    required bool dryRun,
    bool aplicar = false,
    bool sobrescrever = false,
    int limite = 500,
  }) async {
    try {
      carregando.value = true;
      erro.value = '';
      resultado.value = '';

      debugPrint(
        '🛠️ [Migração Fornecedores] Iniciando | '
        'dryRun=$dryRun | aplicar=$aplicar | '
        'sobrescrever=$sobrescrever | limite=$limite',
      );

      final callableUpdate = FirebaseFunctions.instanceFor(
        region: 'southamerica-east1',
      ).httpsCallable(
        'atualizarFornecedoresTiposEventoManual',
      );

      final result = await callableUpdate.call({
        'dryRun': true,
        'aplicar': false,
        'sobrescrever': true,
        'limparCache': false,
      });
      debugPrint(result.data.toString());

      final callable = _functions.httpsCallable(
        'atualizarFornecedoresTiposEventoManual',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 120),
        ),
      );

      final response = await callable.call({
        'dryRun': dryRun,
        'aplicar': aplicar,
        'sobrescrever': sobrescrever,
        'limite': limite,
      });

      final data = Map<String, dynamic>.from(response.data as Map);

      resultado.value = data.toString();

      debugPrint('✅ [Migração Fornecedores] Resultado: $data');

      Get.snackbar(
        dryRun ? 'Simulação concluída' : 'Migração concluída',
        'Verifique o console e o Firestore para conferir o resultado.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseFunctionsException catch (e, s) {
      erro.value = e.message ?? 'Erro ao executar migração.';

      debugPrint(
        '❌ [Migração Fornecedores] Function: ${e.code} | ${e.message}\n$s',
      );

      Get.snackbar(
        'Erro na migração',
        e.message ?? 'Erro ao executar migração.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, s) {
      erro.value = 'Erro inesperado ao executar migração.';

      debugPrint('❌ [Migração Fornecedores] $e\n$s');

      Get.snackbar(
        'Erro na migração',
        'Erro inesperado ao executar migração.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      carregando.value = false;
    }
  }
}
