import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/auditoria/controllers/auditoria_controller.dart';
import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/repositories/auditoria_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_auditoria.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _AuditoriaRepositoryFake repository;
  late AuditoriaController admin;
  late AuditoriaController fornecedor;

  setUp(() {
    Get.testMode = true;
    repository = _AuditoriaRepositoryFake();
    admin = AuditoriaController(
      gerenciarAuditoria: GerenciarAuditoria(repository),
      escopoAdmin: true,
    );
    fornecedor = AuditoriaController(
      gerenciarAuditoria: GerenciarAuditoria(repository),
      escopoAdmin: false,
      idFornecedor: 'forn-1',
    );
  });

  tearDown(Get.reset);

  test('admin loads global history and derives today/visible counts', () async {
    repository.eventos = [
      _evento(
        id: '1',
        acao: 'FORNECEDOR_APROVADO',
        area: 'FORNECEDOR',
        resumo: 'Fornecedor liberado',
        idFornecedor: 'forn-1',
        criadoEm: DateTime.now(),
      ),
      _evento(
        id: '2',
        acao: 'USUARIO_TIPO_ALTERADO',
        area: 'USUARIO',
        resumo: 'Virou admin',
        criadoEm: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    await admin.carregar();

    expect(admin.totalEventos, 2);
    expect(admin.totalVisiveis, 2);
    expect(admin.totalHoje, 1);
    expect(admin.totalAuditados, 2);
    expect(admin.totalSnapshots, 0);
    expect(admin.erro.value, isEmpty);
    expect(repository.ultimaConsulta?.escopoAdmin, isTrue);
  });

  test('filters by search, area and action without a new query', () async {
    repository.eventos = [
      _evento(
        id: '1',
        acao: 'SERVICO_FORNECEDOR_SALVO',
        area: 'SERVICO',
        resumo: 'Buffet atualizado',
        entidadeNome: 'Buffet premium',
      ),
      _evento(
        id: '2',
        acao: 'FORNECEDOR_EDITADO',
        area: 'FORNECEDOR',
        resumo: 'Perfil atualizado',
        entidadeNome: 'Casa do Sabor',
      ),
    ];

    await admin.carregar();
    admin.busca.value = 'buffet';
    expect(admin.visiveis, hasLength(1));
    expect(admin.visiveis.first.id, '1');

    await admin.limparFiltros();
    admin.areaFiltro.value = 'FORNECEDOR';
    expect(admin.visiveis.map((e) => e.id), ['2']);

    await admin.limparFiltros();
    admin.acaoFiltro.value = 'SERVICO_FORNECEDOR_SALVO';
    expect(admin.visiveis.map((e) => e.id), ['1']);
  });

  test('filters by origin and severity', () async {
    repository.eventos = [
      _evento(
        id: '1',
        acao: 'FORNECEDOR_APROVADO',
        area: 'FORNECEDOR',
        origem: 'callable',
      ),
      _evento(
        id: '2',
        acao: 'EVENTO_REGISTRADO',
        area: 'EVENTO',
        nivel: 'WARN',
        origem: 'snapshot',
      ),
    ];

    await admin.carregar();

    expect(admin.totalAuditados, 1);
    expect(admin.totalSnapshots, 1);
    expect(admin.totalAlertas, 1);
    expect(admin.totalCriticos, 0);
    expect(admin.coberturaAuditoria, 0.5);
    expect(admin.distribuicaoPorArea.first.key, 'Fornecedor');
    expect(admin.distribuicaoPorArea.first.value, 1);
    expect(admin.origensDisponiveis.map((e) => e.key), ['audit', 'snapshot']);

    admin.origemFiltro.value = 'snapshot';
    expect(admin.visiveis.map((e) => e.id), ['2']);

    admin.nivelFiltro.value = 'INFO';
    expect(admin.visiveis, isEmpty);

    await admin.limparFiltros();
    admin.nivelFiltro.value = 'WARN';
    expect(admin.visiveis.map((e) => e.id), ['2']);
  });

  test('sends only one indexed admin filter to the backend query', () async {
    repository.eventos = [
      _evento(
        id: '1',
        acao: 'FORNECEDOR_APROVADO',
        area: 'FORNECEDOR',
      ),
    ];

    admin.areaFiltro.value = 'FORNECEDOR';
    await admin.carregar();

    expect(repository.ultimaConsulta?.area, 'FORNECEDOR');
    expect(repository.ultimaConsulta?.acao, isNull);
    expect(repository.ultimaConsulta?.nivel, isNull);
    expect(repository.ultimaConsulta?.origem, isNull);

    admin.acaoFiltro.value = 'FORNECEDOR_APROVADO';
    await admin.carregar();

    expect(repository.ultimaConsulta?.area, isNull);
    expect(repository.ultimaConsulta?.acao, isNull);

    fornecedor.areaFiltro.value = 'FORNECEDOR';
    await fornecedor.carregar();

    expect(repository.ultimaConsulta?.area, isNull);
    expect(repository.ultimaConsulta?.idFornecedor, 'forn-1');
  });

  test('filters critical events and searches by actor/entity metadata',
      () async {
    repository.eventos = [
      _evento(
        id: '1',
        acao: 'USUARIO_TIPO_ALTERADO',
        area: 'USUARIO',
        nivel: 'CRITICAL',
        atorUid: 'admin-1',
        atorNome: 'Amanda Admin',
        atorEmail: 'admin@faca.festa',
        documentPath: 'usuarios/user-2',
      ),
      _evento(
        id: '2',
        acao: 'EVENTO_ATUALIZADO',
        area: 'EVENTO',
        nivel: 'INFO',
        entidadeId: 'evento-abc',
        idCotacao: 'cotacao-77',
      ),
    ];

    await admin.carregar();

    admin.alternarApenasCriticos(true);
    expect(admin.visiveis.map((e) => e.id), ['1']);

    admin.alternarApenasCriticos(false);
    admin.busca.value = 'evento-abc';
    expect(admin.visiveis.map((e) => e.id), ['2']);

    admin.busca.value = 'usuarios/user-2';
    expect(admin.visiveis.map((e) => e.id), ['1']);
  });

  test('filters by actor, entity document and linked ids', () async {
    repository.eventos = [
      _evento(
        id: '1',
        acao: 'USUARIO_TIPO_ALTERADO',
        area: 'USUARIO',
        atorUid: 'admin-1',
        atorNome: 'Amanda Admin',
        atorEmail: 'admin@faca.festa',
        documentPath: 'usuarios/user-2',
      ),
      _evento(
        id: '2',
        acao: 'COTACAO_FECHADA',
        area: 'COTACAO',
        entidadeTipo: 'cotacao',
        entidadeId: 'cotacao-77',
        idFornecedor: 'forn-9',
        idEvento: 'evento-abc',
        idCotacao: 'cotacao-77',
        idOrcamento: 'orc-33',
      ),
    ];

    await admin.carregar();

    admin.atorFiltro.value = 'admin@faca.festa';
    expect(admin.visiveis.map((e) => e.id), ['1']);

    admin.atorFiltro.value = '';
    admin.entidadeFiltro.value = 'usuarios/user-2';
    expect(admin.visiveis.map((e) => e.id), ['1']);

    admin.entidadeFiltro.value = '';
    admin.vinculoFiltro.value = 'orc-33';
    expect(admin.visiveis.map((e) => e.id), ['2']);

    await admin.limparFiltros();
    expect(admin.atorFiltro.value, isEmpty);
    expect(admin.entidadeFiltro.value, isEmpty);
    expect(admin.vinculoFiltro.value, isEmpty);
    expect(admin.visiveis, hasLength(2));
  });

  test('derives operational dashboard indicators', () async {
    repository.eventos = [
      _evento(
        id: '1',
        acao: 'LOGIN_FALHOU',
        area: 'ACESSO',
        nivel: 'WARN',
        atorTipo: 'S',
        hashIntegridade: 'hash-1',
        criadoEm: DateTime.now(),
      ),
      _evento(
        id: '2',
        acao: 'FORNECEDOR_APROVADO',
        area: 'FORNECEDOR',
        atorTipo: 'A',
        atorNome: 'Amanda Admin',
        hashIntegridade: 'hash-2',
        mudancas: const [
          AuditoriaMudanca(campo: 'status', de: 'pendente', para: 'aprovado'),
        ],
        criadoEm: DateTime.now(),
      ),
      _evento(
        id: '3',
        acao: 'FORNECEDOR_REPROVADO',
        area: 'FORNECEDOR',
        atorEmail: 'operacao@faca.festa',
        hashIntegridade: 'hash-3',
        criadoEm: DateTime.now().subtract(const Duration(days: 1)),
      ),
      _evento(
        id: '4',
        acao: 'COTACAO_FECHADA',
        area: 'COTACAO',
        criadoEm: DateTime.now().subtract(const Duration(days: 8)),
      ),
    ];

    await admin.carregar();

    expect(admin.totalFalhasAcesso, 1);
    expect(admin.totalAlteracoesAdministrativas, 2);
    expect(admin.totalFornecedoresAprovados, 1);
    expect(admin.totalFornecedoresComAtencao, 1);
    expect(admin.totalFluxoComercial, 1);
    expect(admin.totalEventosComDiff, 1);
    expect(admin.totalAuditadosSemHash, 1);
    expect(admin.totalUltimos7d, 3);
    expect(admin.totalUltimos15d, 4);
    expect(admin.totalUltimos30d, 4);
    expect(admin.distribuicaoPorNivel.first.key, 'Informativo');
    expect(admin.distribuicaoPorOrigem.first.key, 'Evento auditado');
    expect(
        admin.principaisAcoes.map((e) => e.key), contains('Cotação fechada'));
    expect(admin.principaisAtores.first.key, 'Sistema');
    expect(admin.atividadeUltimos7Dias, hasLength(7));
    expect(admin.atividadeUltimos7Dias.last.value, 2);
  });

  test('summarizes applied filters for reports', () async {
    repository.eventos = [
      _evento(id: '1', acao: 'LOGIN_FALHOU', area: 'ACESSO'),
    ];

    await admin.carregar();

    expect(admin.resumoFiltrosAplicados, 'Sem filtros aplicados');

    admin.busca.value = 'login';
    admin.atorFiltro.value = 'admin@faca.festa';
    admin.areaFiltro.value = 'ACESSO';
    admin.nivelFiltro.value = 'WARN';
    admin.periodoFiltro.value = '24h';
    admin.apenasCriticos.value = true;

    expect(
      admin.resumoFiltrosAplicados,
      contains('busca: login'),
    );
    expect(admin.resumoFiltrosAplicados, contains('ator: admin@faca.festa'));
    expect(admin.resumoFiltrosAplicados, contains('área: Acessos'));
    expect(admin.resumoFiltrosAplicados, contains('severidade: Atenção'));
    expect(admin.resumoFiltrosAplicados, contains('período: Últimas 24h'));
    expect(admin.resumoFiltrosAplicados, contains('apenas críticos'));
  });

  test('filters by selected period and reloads query interval', () async {
    repository.eventos = [
      _evento(
        id: '1',
        acao: 'FORNECEDOR_ATUALIZADO',
        area: 'FORNECEDOR',
        criadoEm: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      _evento(
        id: '2',
        acao: 'EVENTO_ATUALIZADO',
        area: 'EVENTO',
        criadoEm: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];

    await admin.carregar();
    await admin.alterarPeriodo('24h');

    expect(admin.visiveis.map((e) => e.id), ['1']);
    expect(repository.ultimaConsulta?.criadoDe, isNotNull);
    expect(repository.ultimaConsulta?.criadoAte, isNotNull);
  });

  test('exports visible audit rows as escaped csv', () async {
    repository.eventos = [
      _evento(
        id: '1',
        acao: 'FORNECEDOR_ATUALIZADO',
        area: 'FORNECEDOR',
        resumo: 'Fornecedor "premium", atualizado',
        entidadeNome: 'Casa, Sabor',
        origem: 'firestore_trigger',
        mudancas: const [
          AuditoriaMudanca(campo: 'preco', de: '100', para: '150'),
        ],
      ),
    ];

    await admin.carregar();

    final csv = admin.exportarCsvVisivel();

    expect(csv, contains('"Fornecedor ""premium"", atualizado"'));
    expect(csv, contains('"Casa, Sabor"'));
    expect(csv, contains('"preco: 100 -> 150"'));
  });

  test('exports visible audit rows as pdf bytes', () async {
    repository.eventos = [
      _evento(
        id: '1',
        acao: 'LOGIN_REALIZADO',
        area: 'ACESSO',
        resumo: 'Login realizado',
      ),
    ];

    await admin.carregar();

    final pdf = await admin.exportarPdfVisivel();
    final header = String.fromCharCodes(pdf.take(4));

    expect(header, '%PDF');
    expect(pdf.length, greaterThan(100));
  });

  test('fornecedor query is scoped to the supplier id', () async {
    repository.eventos = [
      _evento(
        id: '1',
        acao: 'SERVICO_FORNECEDOR_SALVO',
        area: 'SERVICO',
        idFornecedor: 'forn-1',
      ),
    ];

    await fornecedor.carregar();

    expect(repository.ultimaConsulta?.escopoAdmin, isFalse);
    expect(repository.ultimaConsulta?.idFornecedor, 'forn-1');
    expect(fornecedor.eventos, hasLength(1));
  });

  test('loads next page using cursor and avoids duplicated events', () async {
    final cursor = DateTime.now().subtract(const Duration(minutes: 5));
    repository.paginas = [
      AuditoriaPagina(
        eventos: [
          _evento(
            id: '1',
            acao: 'FORNECEDOR_ATUALIZADO',
            area: 'FORNECEDOR',
            criadoEm: DateTime.now(),
          ),
        ],
        proximoCursorCriadoEm: cursor,
        temMais: true,
      ),
      AuditoriaPagina(
        eventos: [
          _evento(
            id: '1',
            acao: 'FORNECEDOR_ATUALIZADO',
            area: 'FORNECEDOR',
            criadoEm: DateTime.now(),
          ),
          _evento(
            id: '2',
            acao: 'EVENTO_ATUALIZADO',
            area: 'EVENTO',
            criadoEm: DateTime.now().subtract(const Duration(minutes: 10)),
          ),
        ],
      ),
    ];

    await admin.carregar();
    await admin.carregarMais();

    expect(admin.eventos.map((e) => e.id), ['1', '2']);
    expect(admin.temMais.value, isFalse);
    expect(repository.consultas.last.cursorCriadoEm, cursor);
    expect(repository.consultas.last.incluirSnapshots, isFalse);
  });

  test('preserves a user-facing error when listing fails', () async {
    repository.error = StateError('permission-denied');

    await admin.carregar();

    expect(admin.erro.value,
        'Não foi possível carregar o histórico de auditoria.');
    expect(admin.eventos, isEmpty);
    expect(admin.carregando.value, isFalse);
  });
}

AuditoriaEvento _evento({
  required String id,
  required String acao,
  required String area,
  String resumo = 'Alteração',
  String? entidadeNome,
  String? entidadeTipo,
  String? entidadeId,
  String? idFornecedor,
  String? idEvento,
  String? idServico,
  String? idCotacao,
  String? idOrcamento,
  String? atorUid,
  String? atorNome,
  String? atorEmail,
  String? atorTipo,
  String? atorAuthType,
  String nivel = 'INFO',
  String? origem,
  String? documentPath,
  String? algoritmoHash,
  String? hashIntegridade,
  List<AuditoriaMudanca> mudancas = const [],
  DateTime? criadoEm,
}) {
  return AuditoriaEvento(
    id: id,
    acao: acao,
    area: area,
    nivel: nivel,
    resumo: resumo,
    entidadeTipo: entidadeTipo,
    entidadeId: entidadeId,
    entidadeNome: entidadeNome,
    idFornecedor: idFornecedor,
    idEvento: idEvento,
    idServico: idServico,
    idCotacao: idCotacao,
    idOrcamento: idOrcamento,
    atorUid: atorUid,
    atorNome: atorNome,
    atorEmail: atorEmail,
    atorTipo: atorTipo,
    atorAuthType: atorAuthType,
    origem: origem,
    documentPath: documentPath,
    algoritmoHash: algoritmoHash,
    hashIntegridade: hashIntegridade,
    mudancas: mudancas,
    criadoEm: criadoEm,
  );
}

class _AuditoriaRepositoryFake implements AuditoriaRepository {
  List<AuditoriaEvento> eventos = [];
  List<AuditoriaPagina> paginas = [];
  final consultas = <AuditoriaConsulta>[];
  AuditoriaConsulta? ultimaConsulta;
  Object? error;

  @override
  Future<List<AuditoriaEvento>> listar(AuditoriaConsulta consulta) async {
    final pagina = await listarPagina(consulta);
    return pagina.eventos;
  }

  @override
  Future<AuditoriaPagina> listarPagina(AuditoriaConsulta consulta) async {
    ultimaConsulta = consulta;
    consultas.add(consulta);
    final currentError = error;
    if (currentError != null) throw currentError;
    if (paginas.isNotEmpty) return paginas.removeAt(0);
    return AuditoriaPagina(eventos: eventos);
  }

  @override
  Future<void> registrarFalhaLogin(RegistroFalhaLogin registro) async {}

  @override
  Future<String> registrar(RegistroAuditoria registro) async => 'ok';
}
