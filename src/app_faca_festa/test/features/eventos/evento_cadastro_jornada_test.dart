import 'package:app_faca_festa/domain/services/rascunho_calculadora_store.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/entities/tipo_evento.dart';
import 'package:app_faca_festa/domain/entities/rascunho_calculadora.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/repositories/evento_repository.dart';
import 'package:app_faca_festa/domain/repositories/uf_cidade_repository.dart';
import 'package:app_faca_festa/domain/services/buscar_cep_service.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_ufs_cidades.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_cadastro_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/uf_cidade_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

class AppCadastro extends Fake implements AppController {
  @override
  final Rx<Usuario?> usuarioLogado = Rx<Usuario?>(const Usuario(
      idUsuario: 'owner',
      nome: 'Organizador',
      email: 'teste@example.com',
      tipo: 'O'));
  Evento? ativado;
  int homes = 0;
  @override
  Future<void> ativarEventoOrganizador(Evento evento) async {
    ativado = evento;
  }

  @override
  void abrirHomeOrganizador() {
    homes++;
  }
}

class RepoCadastro extends Fake implements EventoRepository {
  final gravacoes = <Evento>[];
  @override
  Future<void> salvar(Evento evento) async {
    gravacoes.add(evento);
  }
}

class Cidades extends Fake implements UfCidadeRepository {}

class Cep extends Fake implements BuscarCepService {}

class RascunhosMemoria implements RascunhoCalculadoraStore {
  final dados = <String, Map<String, dynamic>>{};
  @override
  RascunhoCalculadora? ler(String usuario, String evento) {
    final d = dados['$usuario/$evento'];
    return d == null ? null : RascunhoCalculadora.fromMap(d);
  }

  @override
  Future<void> salvar(
      String usuario, String evento, RascunhoCalculadora r) async {
    dados['$usuario/$evento'] = r.toMap();
  }

  @override
  Future<void> remover(String usuario, String evento) async {
    dados.remove('$usuario/$evento');
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  EventoCadastroController criar(RepoCadastro repo, AppCadastro app,
      {RascunhoCalculadoraStore? store}) {
    final c = EventoCadastroController(
        repository: repo,
        rascunhos: store,
        buscarCepService: Cep(),
        ufCidadeController:
            UFCidadeController(ufsCidades: GerenciarUfsCidades(Cidades())),
        appController: app);
    // Exercita as validações de negócio sem depender de endereço ou do formulário visual.
    c.configurarCadastroComoConvidado(true);
    c.tipoEventoSelecionado.value =
        const TipoEvento(idTipoEvento: 'formatura', nome: 'Formatura');
    c.dataFesta.text = '23/10/2026';
    addTearDown(c.onClose);
    return c;
  }

  RascunhoCalculadora rascunho(String id) => RascunhoCalculadora(
      id: id,
      tipoEvento: 'Formatura',
      adultos: 10,
      criancas: 2,
      bebes: 0,
      duracaoHoras: 4,
      perfil: PerfilFesta.padrao(),
      criadoEm: DateTime(2026, 10, 16),
      limite: 1500,
      contexto: {});

  testWidgets(
      'salvar legado preserva 40 sem idades e edição explícita aceita zero',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    final repo = RepoCadastro(), app = AppCadastro();
    final c = criar(repo, app);
    c.tiposEvento
        .add(const TipoEvento(idTipoEvento: 'formatura', nome: 'Formatura'));
    c.carregarEvento(Evento(
        idEvento: 'legado',
        idUsuario: 'owner',
        idTipoEvento: 'formatura',
        nomeEvento: 'Formatura',
        localEvento: '',
        data: DateTime(2026, 10, 23),
        totalConvidados: 40));
    await c.salvarEvento(aoConcluir: (_, __) async {});
    expect(repo.gravacoes.single.totalConvidados, 40);
    expect(repo.gravacoes.single.totalAdultos, isNull);
    expect(repo.gravacoes.single.totalCriancas, isNull);
    expect(repo.gravacoes.single.totalBebes, isNull);
    c.totalAdultos.text = '0';
    c.totalCriancas.text = '0';
    c.totalBebes.text = '0';
    await c.salvarEvento(aoConcluir: (_, __) async {});
    expect(repo.gravacoes.last.totalConvidados, 0);
    expect(repo.gravacoes.last.totalAdultos, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'falha de vínculo mantém rascunho e repetir cadastro reutiliza o evento já criado',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    final repo = RepoCadastro(), app = AppCadastro();
    final store = RascunhosMemoria();
    final c = criar(repo, app, store: store);
    c.receberRascunho(rascunho(c.idRascunho));
    var tentativas = 0;
    final ids = <String>[];
    Future<void> vincular(RascunhoCalculadora r, Evento evento) async {
      ids.add(evento.idEvento);
      if (++tentativas == 1) throw StateError('Sem conexão');
    }

    await c.salvarEvento(vincularRascunho: vincular);
    await tester.pumpAndSettle();
    expect(repo.gravacoes.length, 1);
    expect(c.idEvento.value, repo.gravacoes.single.idEvento);
    expect(c.rascunhoCalculadora, isNotNull);
    expect(c.isEditando, false);
    expect(app.ativado, isNull);
    expect(app.homes, 0);
    expect(find.text('Evento salvo; estimativa pendente'), findsOneWidget);
    expect(store.ler('outro', c.idEvento.value), isNull);
    final reaberto = criar(repo, app, store: store);
    reaberto.tiposEvento
        .add(const TipoEvento(idTipoEvento: 'formatura', nome: 'Formatura'));
    reaberto.carregarEvento(repo.gravacoes.single);
    reaberto.recuperarRascunho();
    expect(reaberto.rascunhoCalculadora!.id, c.rascunhoCalculadora!.id);
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
    await c.salvarEvento(vincularRascunho: vincular);
    await tester.pumpAndSettle();
    expect(ids.toSet().length, 1);
    expect(repo.gravacoes.map((e) => e.idEvento).toSet().length, 1);
    expect(c.rascunhoCalculadora, isNull);
    expect(store.ler('owner', c.idEvento.value), isNull);
    expect(app.ativado!.totalAdultos, 10);
    expect(app.ativado!.custoEstimado, 1500);
    expect(app.homes, 1);
    // O estado de novo cadastro não vaza ao abrir uma edição existente.
    c.limpar(manterEndereco: true);
    c.tipoEventoSelecionado.value =
        const TipoEvento(idTipoEvento: 'formatura', nome: 'Formatura');
    c.dataFesta.text = '23/10/2026';
    c.receberRascunho(rascunho(c.idRascunho));
    await c.salvarEvento(
        vincularRascunho: (_, __) async => throw StateError('Falha'));
    expect(c.isEditando, false);
    c.carregarEvento(repo.gravacoes.first);
    expect(c.isEditando, true);
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'editar evento preserva ciclo de vida, data de cadastro e campos fora do formulário',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    final repo = RepoCadastro(), app = AppCadastro();
    final c = criar(repo, app);
    final original = Evento(
        idEvento: 'existente',
        idUsuario: 'owner',
        idTipoEvento: 'formatura',
        nomeEvento: 'Formatura',
        localEvento: 'Salão',
        data: DateTime(2026, 10, 23),
        status: StatusEvento.finalizado,
        ativo: false,
        dataCadastro: DateTime(2025, 4, 1),
        siteEvento: 'https://example.com/evento',
        hashtagEvento: '#Formatura',
        mensagemConvidado: 'Bem-vindo');
    c.tiposEvento
        .add(const TipoEvento(idTipoEvento: 'formatura', nome: 'Formatura'));
    c.carregarEvento(original);
    c.nomeEvento.text = 'Nome atualizado';
    await c.salvarEvento();
    await tester.pumpAndSettle();
    final salvo = repo.gravacoes.single;
    expect(salvo.status, StatusEvento.finalizado);
    expect(salvo.ativo, false);
    expect(salvo.dataCadastro, original.dataCadastro);
    expect(salvo.siteEvento, original.siteEvento);
    expect(salvo.mensagemConvidado, original.mensagemConvidado);
    expect(salvo.nomeEvento, 'Nome atualizado');
    expect(app.homes, 0);
    expect(tester.takeException(), isNull);
  });

  test(
      'novo cadastro descarta somente seu rascunho e gera identidade diferente',
      () {
    final c = criar(RepoCadastro(), AppCadastro());
    final id = c.idRascunho;
    c.receberRascunho(rascunho(id));
    expect(c.rascunhoCalculadora, isNotNull);
    c.limpar(manterEndereco: true);
    expect(c.rascunhoCalculadora, isNull);
    expect(c.idRascunho, isNot(id));
    c.receberRascunho(rascunho(id));
    expect(c.rascunhoCalculadora, isNull);
  });
}
