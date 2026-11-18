import 'package:get/get.dart';

import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/domain/entities/demanda_latente.dart';

class DemandaLatenteController extends GetxController {
  DemandaLatenteController({required CallableSessaoGateway gateway})
      : _gateway = gateway;

  final CallableSessaoGateway _gateway;

  final carregando = false.obs;
  final erro = ''.obs;
  final resumo = Rxn<DemandaLatenteResumo>();

  Future<void> carregar({bool forcar = false}) async {
    if (carregando.value) return;
    if (!forcar && resumo.value != null) return;
    try {
      carregando.value = true;
      erro.value = '';
      final raw =
          await _gateway.chamar('consultarDemandaLatenteFornecedor', {});
      resumo.value = DemandaLatenteResumo.fromMap(raw);
    } catch (e) {
      erro.value = 'Não foi possível carregar a demanda latente.';
      resumo.value = null;
    } finally {
      carregando.value = false;
    }
  }
}
