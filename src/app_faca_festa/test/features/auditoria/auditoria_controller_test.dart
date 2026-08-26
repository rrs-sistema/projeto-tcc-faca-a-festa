import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/controllers/auditoria/auditoria_controller.dart';
import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/repositories/auditoria_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_auditoria.dart';

void main() {
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

    admin.limparFiltros();
    admin.areaFiltro.value = 'FORNECEDOR';
    expect(admin.visiveis.map((e) => e.id), ['2']);

    admin.limparFiltros();
    admin.acaoFiltro.value = 'SERVICO_FORNECEDOR_SALVO';
    expect(admin.visiveis.map((e) => e.id), ['1']);
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

  test('preserves a user-facing error when listing fails', () async {
    repository.error = StateError('permission-denied');

    await admin.carregar();

    expect(admin.erro.value, 'Não foi possível carregar o histórico de auditoria.');
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
  String? idFornecedor,
  DateTime? criadoEm,
}) {
  return AuditoriaEvento(
    id: id,
    acao: acao,
    area: area,
    nivel: 'INFO',
    resumo: resumo,
    entidadeNome: entidadeNome,
    idFornecedor: idFornecedor,
    criadoEm: criadoEm,
  );
}

class _AuditoriaRepositoryFake implements AuditoriaRepository {
  List<AuditoriaEvento> eventos = [];
  AuditoriaConsulta? ultimaConsulta;
  Object? error;

  @override
  Future<List<AuditoriaEvento>> listar(AuditoriaConsulta consulta) async {
    ultimaConsulta = consulta;
    final currentError = error;
    if (currentError != null) throw currentError;
    return eventos;
  }

  @override
  Future<String> registrar(RegistroAuditoria registro) async => 'ok';
}
