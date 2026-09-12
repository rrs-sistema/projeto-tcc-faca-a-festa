import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:app_faca_festa/data/repositories_impl/push_token_repository_impl.dart';
import 'package:app_faca_festa/data/services/convite/abrir_convite_por_token_service.dart';
import 'package:app_faca_festa/data/services/endereco/buscar_cep_google_service.dart';
import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/domain/repositories/push_token_repository.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/repositories/convite_convidado_repository.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import 'package:app_faca_festa/domain/services/abrir_convite_por_token.dart';
import 'package:app_faca_festa/domain/services/buscar_cep_service.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_auditoria.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_documentos.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_convite_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/checklist/controllers/tarefa_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/cotacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/inspiracao/controllers/inspiracao_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_gasto_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/usuario_controller.dart';

abstract final class AppControllerBootstrap {
  /// Services needed by feature bootstraps that run before [AppController].
  static void registerSharedServices() {
    if (!Get.isRegistered<BuscarCepService>()) {
      Get.lazyPut<BuscarCepService>(() => BuscarCepGoogleService(),
          fenix: true);
    }
  }

  static void register() {
    registerSharedServices();

    if (!Get.isRegistered<PushTokenRepository>()) {
      Get.lazyPut<PushTokenRepository>(
        () => FirebasePushTokenRepository(
          messaging: Get.find<FirebaseMessaging>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AbrirConvitePorToken>()) {
      Get.lazyPut<AbrirConvitePorToken>(
        () => AbrirConvitePorTokenService(
          functions: Get.find<FirebaseFunctions>(),
          auth: Get.find<FirebaseAuth>(),
          httpsClient: Get.find<CallableHttpsClient>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AppConviteController>()) {
      Get.lazyPut<AppConviteController>(
        () => AppConviteController(
          autenticacao: Get.find<AutenticacaoRepository>(),
          abrirConvitePorToken: Get.find<AbrirConvitePorToken>(),
          convites: Get.find<ConviteConvidadoRepository>(),
          eventos: Get.find<EventoController>(),
          theme: Get.find<EventThemeController>(),
          convidados: Get.find<ConvidadoController>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AppController>()) {
      Get.lazyPut<AppController>(
        () => AppController(
          autenticacaoRepository: Get.find<AutenticacaoRepository>(),
          perfilUsuarioRepository: Get.find<PerfilUsuarioRepository>(),
          pushTokenRepository: Get.find<PushTokenRepository>(),
          documentos: Get.find<GerenciarDocumentos>(),
          fornecedores: Get.find<GerenciarFornecedores>(),
          convite: Get.find<AppConviteController>(),
          eventoController: Get.find<EventoController>(),
          orcamentoController: Get.find<OrcamentoController>(),
          cotacaoController: Get.find<CotacaoController>(),
          fornecedorController: Get.find<FornecedorController>(),
          tarefaController: Get.find<TarefaController>(),
          avaliacaoController: Get.find<AvaliacaoServicoController>(),
          servicoController: Get.find<ServicoProdutoController>(),
          themeController: Get.find<EventThemeController>(),
          auditoria: Get.isRegistered<GerenciarAuditoria>()
              ? Get.find<GerenciarAuditoria>()
              : null,
          auditoriaResolver: () => Get.isRegistered<GerenciarAuditoria>()
              ? Get.find<GerenciarAuditoria>()
              : null,
          orcamentoGastoController: Get.isRegistered<OrcamentoGastoController>()
              ? Get.find<OrcamentoGastoController>()
              : null,
          orcamentoGastoControllerResolver: () =>
              Get.isRegistered<OrcamentoGastoController>()
                  ? Get.find<OrcamentoGastoController>()
                  : null,
          fornecedorLocalizacaoController:
              Get.isRegistered<FornecedorLocalizacaoController>()
                  ? Get.find<FornecedorLocalizacaoController>()
                  : null,
          fornecedorLocalizacaoControllerResolver: () =>
              Get.isRegistered<FornecedorLocalizacaoController>()
                  ? Get.find<FornecedorLocalizacaoController>()
                  : null,
          inspiracaoController: Get.isRegistered<InspiracaoController>()
              ? Get.find<InspiracaoController>()
              : null,
          inspiracaoControllerResolver: () =>
              Get.isRegistered<InspiracaoController>()
                  ? Get.find<InspiracaoController>()
                  : null,
          usuarioController: Get.isRegistered<UsuarioController>()
              ? Get.find<UsuarioController>()
              : null,
          usuarioControllerResolver: () => Get.isRegistered<UsuarioController>()
              ? Get.find<UsuarioController>()
              : null,
        ),
        fenix: true,
      );
    }
  }
}
