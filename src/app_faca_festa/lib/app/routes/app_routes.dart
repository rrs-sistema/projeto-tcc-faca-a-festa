import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/utils/convite_link.dart';
import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/domain/services/buscar_cep_service.dart';
import 'package:app_faca_festa/domain/usecases/get_gifts/gift_usecases.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_dashboard_controller.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_territorio_controller.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/eventos_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/orcamentos_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/login_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/password_reset_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/register_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/totp_mfa_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_itens_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/fornecedor_migracao_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_foto_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/grupo_convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/checklist/controllers/tarefa_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/cotacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/solicitacoes_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_cadastro_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/home_event_nav_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_recomendacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/gifts/controllers/gift_controller.dart';
import 'package:app_faca_festa/presentation/modules/gifts/gerenciar_presentes_page.dart';
import 'package:app_faca_festa/presentation/modules/inspiracao/controllers/inspiracao_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/inspiracao/controllers/inspiracao_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/tema_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/uf_cidade_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/usuario_controller.dart';
import 'package:app_faca_festa/presentation/modules/admin/pages/admin_dashboard_screen.dart';
import 'package:app_faca_festa/presentation/modules/admin/pages/auditoria_admin_screen.dart';
import 'package:app_faca_festa/presentation/modules/admin/pages/auditoria_dashboard_screen.dart';
import 'package:app_faca_festa/presentation/modules/convidado/pages/area/area_convidado_home_screen.dart';
import 'package:app_faca_festa/presentation/modules/convidado/pages/convidado_page.dart';
import 'package:app_faca_festa/presentation/modules/convidado/pages/convite_nao_encontrado_screen.dart';
import 'package:app_faca_festa/presentation/modules/convidado/pages/convite_redirect_page.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/auditoria_fornecedor_screen.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/fornecedor_aguardando_aprovacao_screen.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/fornecedor_home_screen.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/fornecedor_localizacao_screen.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/orcamentos_screen.dart';
import 'package:app_faca_festa/presentation/modules/eventos/pages/home_event_screen.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/forgot_password_screen.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/login_screen.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/register_screen.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/totp_setup_screen.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/totp_verify_screen.dart';
import 'package:app_faca_festa/presentation/modules/eventos/pages/welcome_event_screen.dart';
import 'package:app_faca_festa/presentation/widgets/splash.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/role_selector_screen.dart';
import '../bindings/gift_binding.dart';
import '../bootstrap/auditoria_bootstrap.dart';
import '../middleware/papel_middleware.dart';

class EntradaAppPage extends StatelessWidget {
  const EntradaAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (ConviteLink.tokenDaUrl() != null) {
      return ConviteRedirectPage(appController: Get.find<AppController>());
    }
    return Splash(appController: Get.find<AppController>());
  }
}

class AppRoutes {
  const AppRoutes._();

  static String initialRoute() {
    if (kIsWeb) {
      final token = ConviteLink.tokenDaUrl();
      if (token != null && token.isNotEmpty) {
        return '/convite/${Uri.encodeComponent(token)}';
      }
    }
    return '/splash';
  }

  static GetPage<dynamic> get unknownRoute => GetPage(
        name: '/notfound',
        page: () => const EntradaAppPage(),
      );

  static List<GetPage<dynamic>> get pages => [
        GetPage(
          name: '/HomeEventScreen',
          page: () => HomeEventScreen(
            appController: Get.find<AppController>(),
            convidadoController: Get.find<ConvidadoController>(),
            orcamentoController: Get.find<OrcamentoController>(),
            tarefaController: Get.find<TarefaController>(),
            eventoController: Get.find<EventoController>(),
            homeEventNavController: Get.find<HomeEventNavController>(),
            fornecedorController: Get.find<FornecedorLocalizacaoController>(),
            fornecedorCadastroController: Get.find<FornecedorController>(),
            fornecedorRecomendacaoController:
                Get.find<FornecedorRecomendacaoController>(),
            avaliacaoController: Get.find<AvaliacaoServicoController>(),
            themeController: Get.find<EventThemeController>(),
            cotacaoController: Get.find<CotacaoController>(),
            solicitacoesController: Get.find<SolicitacoesController>(),
            inspiracaoController: Get.find<InspiracaoController>(),
            usuarioController: Get.find<UsuarioController>(),
            eventoCadastroController: Get.find<EventoCadastroController>(),
            grupoConvidadoController: Get.find<GrupoConvidadoController>(),
            cardapioController: Get.find<CardapioController>(),
            calculadoraController: Get.find<CalculadoraFestaController>(),
            calculadoraItensAdminController:
                Get.find<CalculadoraItensAdminController>(),
            fornecedorMigracaoAdminController:
                Get.find<FornecedorMigracaoAdminController>(),
            inspiracaoAdminController: Get.find<InspiracaoAdminController>(),
            temaFestaController: Get.find<TemaFestaController>(),
          ),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['O'])
          ],
        ),
        GetPage(
          name: '/splash',
          page: () => Splash(appController: Get.find<AppController>()),
        ),
        GetPage(
          name: '/role',
          page: () => RoleSelectorScreen(
            eventoCadastroController: Get.find<EventoCadastroController>(),
          ),
        ),
        GetPage(
          name: '/welcome',
          page: () => WelcomeEventScreen(
            themeController: Get.find<EventThemeController>(),
            appController: Get.find<AppController>(),
            eventoController: Get.find<EventoController>(),
            eventoCadastroController: Get.find<EventoCadastroController>(),
            calculadoraController: Get.find<CalculadoraFestaController>(),
            cardapioController: Get.find<CardapioController>(),
            fornecedorMigracaoAdminController:
                Get.find<FornecedorMigracaoAdminController>(),
            temaFestaController: Get.find<TemaFestaController>(),
          ),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['O'])
          ],
        ),
        GetPage(
          name: '/login',
          page: () => LoginScreen(
            controller: Get.find<LoginController>(),
            themeController: Get.find<EventThemeController>(),
            appController: Get.find<AppController>(),
          ),
        ),
        GetPage(
          name: '/loginTotpSetup',
          page: () => TotpSetupScreen(
            controller: Get.find<TotpMfaController>(),
            themeController: Get.find<EventThemeController>(),
          ),
        ),
        GetPage(
          name: '/loginTotp',
          page: () => TotpVerifyScreen(
            controller: Get.find<TotpMfaController>(),
            themeController: Get.find<EventThemeController>(),
          ),
        ),
        GetPage(
          name: '/forgotPassword',
          page: () => ForgotPasswordScreen(
            controller: Get.find<PasswordResetController>(),
            themeController: Get.find<EventThemeController>(),
          ),
        ),
        GetPage(
          name: '/register',
          page: () => RegisterScreen(
            controller: Get.find<RegisterController>(),
            fornecedorController: Get.find<FornecedorController>(),
            themeController: Get.find<EventThemeController>(),
            categoriaController: Get.find<CategoriaServicoController>(),
            subcategoriaController: Get.find<SubcategoriaServicoController>(),
            servicoController: Get.find<ServicoProdutoController>(),
          ),
        ),
        GetPage(
          name: '/admin',
          page: () => AdminDashboardScreen(
            controller: Get.find<AdminDashboardController>(),
            theme: Get.find<EventThemeController>(),
            appController: Get.find<AppController>(),
            categoriaController: Get.find<CategoriaServicoController>(),
            subcategoriaController: Get.find<SubcategoriaServicoController>(),
            fornecedorController: Get.find<FornecedorController>(),
            fornecedorLocalizacaoController:
                Get.find<FornecedorLocalizacaoController>(),
            avaliacaoController: Get.find<AvaliacaoServicoController>(),
            usuarioController: Get.find<UsuarioController>(),
            buscarCepService: Get.find<BuscarCepService>(),
            ufCidadeController: Get.find<UFCidadeController>(),
            servicoProdutoController: Get.find<ServicoProdutoController>(),
            servicoFotoController: Get.find<ServicoFotoController>(),
            eventosAdminController: Get.find<EventosAdminController>(),
            temaFestaController: Get.find<TemaFestaController>(),
            orcamentosAdminController: Get.find<OrcamentosAdminController>(),
            adminTerritorioController: Get.find<AdminTerritorioController>(),
          ),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['A'])
          ],
        ),
        GetPage(
          name: '/admin/auditoria',
          page: () => AuditoriaAdminScreen(
            controller: AuditoriaBootstrap.controllerAdmin(),
            themeController: Get.find<EventThemeController>(),
          ),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['A'])
          ],
        ),
        GetPage(
          name: '/admin/auditoria/dashboard',
          page: () => AuditoriaDashboardScreen(
            controller: AuditoriaBootstrap.controllerAdmin(),
            themeController: Get.find<EventThemeController>(),
          ),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['A'])
          ],
        ),
        GetPage(
          name: '/convidadosPage',
          page: () => ConvidadosPage(
            themeController: Get.find<EventThemeController>(),
            appController: Get.find<AppController>(),
            eventoController: Get.find<EventoController>(),
            grupoController: Get.find<GrupoConvidadoController>(),
            convidadoController: Get.find<ConvidadoController>(),
            cardapioController: Get.find<CardapioController>(),
          ),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['O'])
          ],
        ),
        GetPage(
          name: '/gerenciarPresentes',
          binding: GiftBinding(),
          page: () {
            final args = GerenciarPresentesArgs.maybeOf(Get.arguments);
            return GerenciarPresentesPage(
              eventoId: args?.eventoId ?? '',
              controller: Get.find<GiftController>(),
              themeController: Get.find<EventThemeController>(),
            );
          },
        ),
        GetPage(
          name: '/',
          page: () => const EntradaAppPage(),
        ),
        GetPage(
          name: '/convite',
          page: () =>
              ConviteRedirectPage(appController: Get.find<AppController>()),
        ),
        GetPage(
          name: '/convite/:token',
          page: () =>
              ConviteRedirectPage(appController: Get.find<AppController>()),
        ),
        GetPage(
          name: '/orcamentos',
          page: () => OrcamentosScreen(
            controller: Get.find<OrcamentoController>(),
            idFornecedor:
                Get.find<AppController>().usuarioLogado.value?.idUsuario ?? '',
          ),
          transition: Transition.cupertino,
        ),
        GetPage(
          name: '/fornecedores',
          page: () => FornecedorLocalizacaoScreen(
            showLeading: true,
            appController: Get.find<AppController>(),
            themeController: Get.find<EventThemeController>(),
            controllerLocalizacao: Get.find<FornecedorLocalizacaoController>(),
            eventoController: Get.find<EventoController>(),
            recomendacaoController:
                Get.find<FornecedorRecomendacaoController>(),
            fornecedorCadastroController: Get.find<FornecedorController>(),
            avaliacaoController: Get.find<AvaliacaoServicoController>(),
            cotacoes: Get.find<CotacaoController>().gerenciarCotacoes,
          ),
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['O'])
          ],
        ),
        GetPage(
          name: '/fornecedor',
          page: () {
            final fornecedorController = Get.find<FornecedorController>();
            final appController = Get.find<AppController>();

            if (!fornecedorController.aptoParaOperar.value) {
              return FornecedorAguardandoAprovacaoScreen(
                appController: appController,
                fornecedorController: fornecedorController,
              );
            }

            return FornecedorHomeScreen(
              controller: fornecedorController,
              appController: appController,
              themeController: Get.find<EventThemeController>(),
              cotacoes: Get.find<CotacaoController>().gerenciarCotacoes,
              avaliacaoController: Get.find<AvaliacaoServicoController>(),
              solicitacoesController: Get.find<SolicitacoesController>(),
              servicoController: Get.find<ServicoProdutoController>(),
              fotoController: Get.find<ServicoFotoController>(),
              categoriaController: Get.find<CategoriaServicoController>(),
              subcategoriaController: Get.find<SubcategoriaServicoController>(),
            );
          },
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['F'])
          ],
        ),
        GetPage(
          name: '/fornecedor/auditoria',
          page: () {
            final fornecedorController = Get.find<FornecedorController>();
            final id =
                (fornecedorController.fornecedor.value?.idFornecedor ?? '')
                    .trim();
            final controller =
                id.isEmpty ? null : AuditoriaBootstrap.controllerFornecedor(id);
            controller?.carregar();
            return AuditoriaFornecedorScreen(
              fornecedorController: fornecedorController,
              controller: controller,
            );
          },
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['F'])
          ],
        ),
        GetPage(
          name: '/conviteNaoEncontrado',
          page: () => ConviteNaoEncontradoScreen(
            appController: Get.find<AppController>(),
          ),
        ),
        GetPage(
          name: '/areaconvidado',
          page: () {
            final args = AreaConvidadoArgs.maybeOf(Get.arguments);
            return AreaConvidadoHomeScreen(
              convidado: args!.convidado,
              evento: args.evento,
              convidadoController: Get.find<ConvidadoController>(),
              eventoController: Get.find<EventoController>(),
              tarefaController: Get.find<TarefaController>(),
              theme: Get.find<EventThemeController>(),
              appController: Get.find<AppController>(),
              giftUseCases: Get.find<GiftUseCases>(),
            );
          },
          middlewares: [
            PapelMiddleware(tiposPermitidos: const ['C'])
          ],
        ),
      ];
}
