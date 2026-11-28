import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/data/datasources/remote/acompanhamento_partes_remote.dart';
import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/acompanhamento_partes_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/usuario_controller.dart';

/// Tag do financeiro do organizador. Usada pela rota e pelo Pix logo após contratar.
const tagAcompanhamentoOrganizador = 'acompanhamento-org';

/// Registra (uma vez) e devolve o controller do financeiro do organizador.
AcompanhamentoPartesController garantirAcompanhamentoOrganizador() {
  if (!Get.isRegistered<AcompanhamentoPartesController>(
      tag: tagAcompanhamentoOrganizador)) {
    Get.put(
      AcompanhamentoPartesController(
        remote: AcompanhamentoPartesRemote(
          functions: Get.find<FirebaseFunctions>(),
          httpsClient: Get.find<CallableHttpsClient>(),
        ),
      ),
      tag: tagAcompanhamentoOrganizador,
    );
  }
  return Get.find<AcompanhamentoPartesController>(
      tag: tagAcompanhamentoOrganizador);
}

/// CPF do usuário logado, somente se for válido. Null quando não há ou é inválido.
String? cpfDoPerfilLogado() {
  if (!Get.isRegistered<UsuarioController>()) return null;
  final digitos = FormValidators.somenteDigitos(
    Get.find<UsuarioController>().usuario.value?.cpf,
  );
  if (FormValidators.cpf(digitos, obrigatorio: true) != null) return null;
  return digitos;
}
