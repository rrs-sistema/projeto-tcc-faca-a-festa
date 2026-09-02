import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/repositories/fornecedor_migracao_repository.dart';
import 'package:app_faca_festa/domain/usecases/executar_migracao_fornecedores.dart';

class FornecedorMigracaoAdminController extends GetxController {
  FornecedorMigracaoAdminController({
    ExecutarMigracaoFornecedores? migracaoFornecedores,
  }) : _migracaoFornecedores =
            migracaoFornecedores ?? Get.find<ExecutarMigracaoFornecedores>();

  final ExecutarMigracaoFornecedores _migracaoFornecedores;

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

      final data = await _migracaoFornecedores.migrarTiposEventoFornecedores(
        dryRun: dryRun,
        aplicar: aplicar,
        sobrescrever: sobrescrever,
        limite: limite,
      );

      resultado.value = data.toString();

      debugPrint('✅ [Migração Fornecedores] Resultado: $data');

      Get.snackbar(
        dryRun ? 'Simulação concluída' : 'Migração concluída',
        'Verifique o console e o Firestore para conferir o resultado.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FornecedorMigracaoException catch (e, s) {
      erro.value = e.message;

      debugPrint(
        '❌ [Migração Fornecedores] Function: ${e.message}\n$s',
      );

      Get.snackbar(
        'Erro na migração',
        e.message,
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
