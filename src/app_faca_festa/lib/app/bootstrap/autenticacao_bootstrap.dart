import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/autenticacao_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/autenticacao_repository_impl.dart';
import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import 'package:app_faca_festa/domain/services/buscar_cep_service.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_catalogo_servico.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_auditoria.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_servicos_produto.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/login_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/password_reset_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/register_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/totp_mfa_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/uf_cidade_controller.dart';

abstract final class AutenticacaoBootstrap {
  static void register() {
    if (!Get.isRegistered<AutenticacaoRemoteDatasource>()) {
      Get.put<AutenticacaoRemoteDatasource>(
        FirebaseAutenticacaoRemoteDatasource(
          Get.find<FirebaseAuth>(),
          functions: Get.find<FirebaseFunctions>(),
          httpsClient: Get.find<CallableHttpsClient>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<AutenticacaoRepository>()) {
      Get.put<AutenticacaoRepository>(
        AutenticacaoRepositoryImpl(
          Get.find<AutenticacaoRemoteDatasource>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<LoginController>()) {
      Get.lazyPut<LoginController>(
        () => LoginController(
          autenticacaoRepository: Get.find<AutenticacaoRepository>(),
          perfilRepository: Get.find<PerfilUsuarioRepository>(),
          appController: Get.isRegistered<AppController>()
              ? Get.find<AppController>()
              : null,
          appControllerResolver: () => Get.isRegistered<AppController>()
              ? Get.find<AppController>()
              : null,
          gerenciarAuditoria: Get.isRegistered<GerenciarAuditoria>()
              ? Get.find<GerenciarAuditoria>()
              : null,
          gerenciarAuditoriaResolver: () =>
              Get.isRegistered<GerenciarAuditoria>()
                  ? Get.find<GerenciarAuditoria>()
                  : null,
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<RegisterController>()) {
      Get.lazyPut<RegisterController>(
        () => RegisterController(
          autenticacaoRepository: Get.find<AutenticacaoRepository>(),
          perfilUsuarioRepository: Get.find<PerfilUsuarioRepository>(),
          fornecedores: Get.find<GerenciarFornecedores>(),
          servicosProduto: Get.find<GerenciarServicosProduto>(),
          catalogoServico: Get.find<GerenciarCatalogoServico>(),
          appController: Get.find<AppController>(),
          buscarCepService: Get.find<BuscarCepService>(),
          ufCidadeController: Get.find<UFCidadeController>(),
          uploadBanner: ({
            required bytes,
            required nomeArquivo,
            uid,
          }) =>
              Get.find<FornecedorController>().uploadBanner(
                bytes: bytes,
                nomeArquivo: nomeArquivo,
                uid: uid,
              ),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<PasswordResetController>()) {
      Get.lazyPut<PasswordResetController>(
        () => PasswordResetController(
          autenticacaoRepository: Get.find<AutenticacaoRepository>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<TotpMfaController>()) {
      Get.lazyPut<TotpMfaController>(
        () => TotpMfaController(
          autenticacaoRepository: Get.find<AutenticacaoRepository>(),
          appController: Get.find<AppController>(),
        ),
        fenix: true,
      );
    }
  }
}
