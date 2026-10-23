import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_cadastro_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/uf_cidade_controller.dart';
import 'package:app_faca_festa/domain/entities/endereco_cep_resultado.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/tipo_evento.dart';
import 'package:app_faca_festa/domain/entities/uf_cidade.dart';
import 'package:app_faca_festa/domain/repositories/evento_repository.dart';
import 'package:app_faca_festa/domain/repositories/uf_cidade_repository.dart';
import 'package:app_faca_festa/domain/services/buscar_cep_service.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_ufs_cidades.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  late _EventoRepositoryFake repository;
  late EventoCadastroController controller;

  setUp(() {
    repository = _EventoRepositoryFake();
    controller = EventoCadastroController(
      repository: repository,
      buscarCepService: _BuscarCepServiceFake(),
      ufCidadeController: UFCidadeController(
        ufsCidades: GerenciarUfsCidades(_UfCidadeRepositoryFake()),
      ),
    );
  });

  tearDown(() {
    controller.onClose();
  });

  test(
      'legado recupera total conhecido sem inventar adultos e mantém zero explícito',
      () {
    Evento evento({int? adultos, int? criancas, int? bebes, int total = 40}) =>
        Evento(
            idEvento: 'evento',
            idTipoEvento: 'retiro',
            idUsuario: 'usuario',
            nomeEvento: 'Retiro',
            localEvento: '',
            data: DateTime(2026),
            totalConvidados: total,
            totalAdultos: adultos,
            totalCriancas: criancas,
            totalBebes: bebes);
    controller.carregarEvento(evento());
    expect(controller.totalConvidados.text, '40');
    expect(controller.totalAdultos.text, isEmpty);
    expect(controller.totalCriancas.text, isEmpty);
    expect(controller.totalBebes.text, isEmpty);
    controller
        .carregarEvento(evento(total: 0, adultos: 0, criancas: 0, bebes: 0));
    expect(controller.totalConvidados.text, '0');
    expect(controller.totalAdultos.text, '0');
    expect(controller.totalCriancas.text, '0');
    expect(controller.totalBebes.text, '0');
  });

  group('planejamento com campos opcionais', () {
    test('um dia é o padrão e não exige término, hora ou custo', () {
      expect(controller.eventoVariosDias.value, isFalse);
      expect(controller.validarTermino(''), isNull);
      expect(controller.validarHora(''), isNull);
      expect(controller.validarCusto(''), isNull);
      expect(controller.custoEstimadoInformado, isNull);
    });

    test('vários dias exige término posterior ao início', () {
      controller.dataFesta.text = '14/10/2026';
      controller.definirEventoVariosDias(true);
      expect(controller.validarTermino(''), isNotNull);
      expect(controller.validarTermino('13/10/2026'), isNotNull);
      expect(controller.validarTermino('14/10/2026'), isNotNull);
      expect(controller.validarTermino('31/02/2026'), isNotNull);
      expect(controller.validarTermino('19/10/2026'), isNull);
    });

    test('voltar para um dia limpa o término e remove a exigência', () {
      controller.definirEventoVariosDias(true);
      controller.dataFimFesta.text = '19/10/2026';
      controller.definirEventoVariosDias(false);
      expect(controller.dataFimFesta.text, isEmpty);
      expect(controller.validarTermino(''), isNull);
    });

    test('campos opcionais preenchidos continuam sendo validados', () {
      expect(controller.validarHora('25:80'), isNotNull);
      expect(controller.validarHora('18:30'), isNull);
      expect(controller.validarCusto('-10,00'), isNotNull);
      controller.custoEstimado.text = 'R\$ 0,00';
      expect(controller.validarCusto(controller.custoEstimado.text), isNull);
      expect(controller.custoEstimadoInformado, 0);
      controller.custoEstimado.clear();
      expect(controller.custoEstimadoInformado, isNull);
      controller.custoEstimado.text = 'R\$ 0,50';
      expect(controller.validarCusto(controller.custoEstimado.text), isNull);
      expect(controller.custoEstimadoInformado, 0.5);
    });

    test(
        'edição recupera vários dias e limpa o término ao carregar evento de um dia',
        () {
      Evento evento({DateTime? fim}) => Evento(
            idEvento: 'evento',
            idTipoEvento: 'retiro',
            idUsuario: 'usuario',
            nomeEvento: 'Retiro',
            localEvento: 'Chácara',
            data: DateTime(2026, 10, 14),
            dataFim: fim,
          );
      controller.carregarEvento(evento(fim: DateTime(2026, 10, 19)));
      expect(controller.eventoVariosDias.value, isTrue);
      expect(controller.dataFimFesta.text, '19/10/2026');
      controller.carregarEvento(evento());
      expect(controller.eventoVariosDias.value, isFalse);
      expect(controller.dataFimFesta.text, isEmpty);
      expect(controller.horaFesta.text, isEmpty);
      expect(controller.custoEstimadoInformado, isNull);
    });

    test('novo cadastro não herda período do evento anterior', () {
      controller.definirEventoVariosDias(true);
      controller.dataFimFesta.text = '19/10/2026';
      controller.limpar(manterEndereco: true);
      expect(controller.eventoVariosDias.value, isFalse);
      expect(controller.dataFimFesta.text, isEmpty);
    });
  });

  test('loads active event types from repository unchanged', () async {
    const casamento = TipoEvento(
      idTipoEvento: 'casamento',
      nome: 'Casamento',
    );
    const formatura = TipoEvento(
      idTipoEvento: 'formatura',
      nome: 'Formatura',
    );
    repository.tiposAtivos = [casamento, formatura];

    await controller.carregarTiposEvento();

    expect(controller.tiposEvento, [same(casamento), same(formatura)]);
  });

  test('keeps the current type list when repository loading fails', () async {
    const existente = TipoEvento(
      idTipoEvento: 'existente',
      nome: 'Existente',
    );
    controller.tiposEvento.add(existente);
    repository.error = StateError('failure');

    await controller.carregarTiposEvento();

    expect(controller.tiposEvento, [same(existente)]);
  });
}

class _BuscarCepServiceFake implements BuscarCepService {
  @override
  Future<EnderecoCepResultado> buscar({required String cep}) async {
    return EnderecoCepResultado(
      cep: cep,
      formatado: cep,
      logradouro: '',
      numero: '',
      bairro: '',
      cidade: '',
      uf: '',
      latitude: null,
      longitude: null,
      possuiCoordenadas: false,
      origemCalculo: '',
    );
  }
}

class _EventoRepositoryFake implements EventoRepository {
  List<TipoEvento> tiposAtivos = const [];
  Object? error;

  @override
  Future<List<TipoEvento>> listarTiposAtivos() async {
    if (error case final repositoryError?) {
      throw repositoryError;
    }
    return tiposAtivos;
  }

  @override
  Future<Evento?> buscarPorId(String idEvento) async => null;

  @override
  Future<Evento?> buscarUltimoPorUsuario(String idUsuario) async => null;

  @override
  Future<TipoEvento?> buscarTipoPorId(String idTipoEvento) async => null;

  @override
  Future<void> excluir(String idEvento) async {}

  @override
  Stream<List<Evento>> listarPorUsuario(String idUsuario) =>
      const Stream.empty();

  @override
  Stream<Evento?> observarPorId(String idEvento) => const Stream.empty();

  @override
  Stream<Evento?> observarUltimoPorUsuario(String idUsuario) =>
      const Stream.empty();

  @override
  Future<void> salvar(Evento evento) async {}

  @override
  Future<String> enviarCapa({
    required String idEvento,
    required List<int> bytes,
  }) async {
    return 'https://example.com/$idEvento.jpg';
  }

  @override
  Future<void> removerArquivoCapa(String idEvento) async {}

  @override
  Future<void> atualizarImagemCapa({
    required String idEvento,
    String? imagemCapaUrl,
  }) async {}

  @override
  Future<void> atualizarRotuloBanner({
    required String idEvento,
    String? rotuloBanner,
  }) async {}
}

class _UfCidadeRepositoryFake implements UfCidadeRepository {
  @override
  Future<List<Estado>> carregarEstados() async => const [];

  @override
  Future<List<Cidade>> carregarCidades(String idEstado) async => const [];
}
