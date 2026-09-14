import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/app/bootstrap/uf_cidade_bootstrap.dart';
import 'package:app_faca_festa/data/datasources/remote/evento_remote_ds.dart';
import 'package:app_faca_festa/data/local/evento_ativo_store.dart';
import 'package:app_faca_festa/data/repositories_impl/evento_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/evento_repository.dart';
import 'package:app_faca_festa/domain/services/buscar_cep_service.dart';
import 'package:app_faca_festa/presentation/coordinators/evento_session_coordinator.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/grupo_convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/checklist/controllers/tarefa_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/inspiracao/controllers/inspiracao_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_gasto_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/uf_cidade_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/usuario_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/home_event_nav_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_cadastro_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';

/// Global composition root for the current-event session.
abstract final class EventoBootstrap {
  static void register() {
    UfCidadeBootstrap.register();

    if (!Get.isRegistered<EventoRemoteDatasource>()) {
      Get.put<EventoRemoteDatasource>(
        EventoRemoteDatasource(
          Get.find<FirebaseFirestore>(),
          storage: Get.find<FirebaseStorage>(),
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<EventoRepository>()) {
      Get.put<EventoRepository>(
        EventoRepositoryImpl(Get.find<EventoRemoteDatasource>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<EventoSessionCoordinator>()) {
      Get.put<EventoSessionCoordinator>(
        GetxEventoSessionCoordinator(
          themeControllerOf: () => Get.find<EventThemeController>(),
          orcamentoControllerOf: () => Get.isRegistered<OrcamentoController>()
              ? Get.find<OrcamentoController>()
              : null,
          convidadoControllerOf: () => Get.isRegistered<ConvidadoController>()
              ? Get.find<ConvidadoController>()
              : null,
          cardapioControllerOf: () => Get.isRegistered<CardapioController>()
              ? Get.find<CardapioController>()
              : null,
          grupoControllerOf: () => Get.isRegistered<GrupoConvidadoController>()
              ? Get.find<GrupoConvidadoController>()
              : null,
          tarefaControllerOf: () => Get.isRegistered<TarefaController>()
              ? Get.find<TarefaController>()
              : null,
          inspiracaoControllerOf: () => Get.isRegistered<InspiracaoController>()
              ? Get.find<InspiracaoController>()
              : null,
          usuarioControllerOf: () => Get.isRegistered<UsuarioController>()
              ? Get.find<UsuarioController>()
              : null,
          fornecedorControllerOf: () => Get.isRegistered<FornecedorController>()
              ? Get.find<FornecedorController>()
              : null,
          orcamentoGastoControllerOf: () =>
              Get.isRegistered<OrcamentoGastoController>()
                  ? Get.find<OrcamentoGastoController>()
                  : null,
          calculadoraControllerOf: () =>
              Get.isRegistered<CalculadoraFestaController>()
                  ? Get.find<CalculadoraFestaController>()
                  : null,
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<EventoController>()) {
      Get.put<EventoController>(
        EventoController(
          repository: Get.find<EventoRepository>(),
          sessionCoordinator: Get.find<EventoSessionCoordinator>(),
          eventoAtivoStore: GetStorageEventoAtivoStore(),
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<EventoCadastroController>()) {
      Get.put(
        EventoCadastroController(
          repository: Get.find<EventoRepository>(),
          buscarCepService: Get.find<BuscarCepService>(),
          ufCidadeController: Get.find<UFCidadeController>(),
          appController: Get.isRegistered<AppController>()
              ? Get.find<AppController>()
              : null,
          appControllerResolver: () => Get.isRegistered<AppController>()
              ? Get.find<AppController>()
              : null,
        ),
        permanent: true,
      ).carregarTiposEvento();
    }

    if (!Get.isRegistered<HomeEventNavController>()) {
      Get.put(
        HomeEventNavController(),
        permanent: true,
      );
    }
  }
}
