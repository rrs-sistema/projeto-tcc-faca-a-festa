import 'package:app_faca_festa/controllers/convidado/convidado_controller.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/repositories/convidado_repository.dart';
import 'package:app_faca_festa/domain/repositories/presente_reservation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _ConvidadoRepositoryFake repository;
  late ConvidadoController controller;

  setUp(() {
    repository = _ConvidadoRepositoryFake();
    controller = ConvidadoController(
      repository: repository,
      presenteReservationRepository: _PresenteReservationRepositoryFake(),
    );
  });

  tearDown(() {
    controller.onClose();
  });

  test('search by id exposes the pure domain entity', () async {
    final convidado = _convidado(nome: 'Ana');
    repository.convidado = convidado;

    final result = await controller.buscarPeloIdConvidado('convidado-1');

    expect(repository.idBuscado, 'convidado-1');
    expect(result, same(convidado));
    expect(result?.nome, 'Ana');
    expect(controller.convidadoAtual.value, same(result));
    expect(controller.carregando.value, isFalse);
  });

  test('event listener delegates, sorts and exposes domain entities', () async {
    final zelia = _convidado(id: 'convidado-zelia', nome: 'Zélia');
    final ana = _convidado(id: 'convidado-ana', nome: 'Ana');
    repository.convidados = [zelia, ana];

    await controller.escutarConvidados('evento-1');
    await Future<void>.delayed(Duration.zero);

    expect(repository.eventoObservado, 'evento-1');
    expect(controller.convidados.map((item) => item.nome), ['Ana', 'Zélia']);
    expect(controller.carregando.value, isFalse);
  });

  test('adicionarConvidado shows the guest in the list immediately', () async {
    final ana = _convidado(id: 'convidado-ana', nome: 'Ana');

    await controller.adicionarConvidado(ana);

    expect(repository.convidadoSalvo?.idConvidado, 'convidado-ana');
    expect(controller.convidados.map((item) => item.nome), ['Ana']);
    expect(controller.carregando.value, isFalse);
  });

  test('save and delete delegate pure domain values', () async {
    final convidado = _convidado(nome: 'Ana');

    await controller.adicionarConvidado(convidado);
    await controller.excluirConvidado('convidado-1');

    expect(repository.convidadoSalvo, same(convidado));
    expect(repository.idExcluido, 'convidado-1');
  });

  test('status update preserves parameters delegated to repository', () async {
    await controller.atualizarStatus(
      'convidado-1',
      StatusConvidado.confirmado,
    );

    expect(repository.idStatus, 'convidado-1');
    expect(repository.status, StatusConvidado.confirmado);
    expect(repository.dataResposta, isNotNull);
  });

  test('invite links persist the token without claiming WhatsApp or SMS delivery',
      () async {
    final convidado = _convidado(nome: 'Ana');

    final preparados = await controller.garantirLinksConvite([convidado]);

    expect(repository.tokensConvite, {'convidado-1': 'convidado-1'});
    expect(preparados.single.tokenParaLink, 'convidado-1');
    expect(
      controller.urlConvite(preparados.single, origem: 'https://faca-a-festa.web.app'),
      'https://faca-a-festa.web.app/#/convite/convidado-1',
    );
    expect(
      controller.textoCompartilhamento(
        convidados: preparados,
        evento: _evento(),
        origem: 'https://faca-a-festa.web.app',
      ),
      contains('/#/convite/convidado-1'),
    );
    expect(
      controller.textoCompartilhamento(
        convidados: preparados,
        evento: _evento(),
        origem: 'https://faca-a-festa.web.app',
      ),
      isNot(contains('WhatsApp')),
    );
  });
}

class _PresenteReservationRepositoryFake
    implements PresenteReservationRepository {
  @override
  Future<void> reservar({
    required String idEvento,
    required String idPresente,
    required String idConvidado,
    required String nomeConvidado,
    required DateTime dataReserva,
  }) async {}
}

Convidado _convidado({required String nome, String id = 'convidado-1'}) {
  final now = DateTime(2026, 8, 14);
  return Convidado(
    idConvidado: id,
    idEvento: 'evento-1',
    nome: nome,
    contato: '44999999999',
    conviteToken: id,
    dataCadastro: now,
    dataAtualizacao: now,
  );
}

Evento _evento() {
  return Evento(
    idEvento: 'evento-1',
    idTipoEvento: 'tipo-1',
    idUsuario: 'organizador-1',
    nomeEvento: 'Festa da Ana',
    localEvento: 'Salão',
    data: DateTime(2026, 9, 1),
  );
}

class _ConvidadoRepositoryFake implements ConvidadoRepository {
  Convidado? convidado;
  List<Convidado> convidados = const [];
  String? idBuscado;
  String? eventoObservado;
  Convidado? convidadoSalvo;
  String? idExcluido;
  String? idStatus;
  StatusConvidado? status;
  DateTime? dataResposta;
  MigracaoTipoConvidadoResultado migracaoResultado =
      const MigracaoTipoConvidadoResultado(
    totalEncontrados: 0,
    totalAtualizados: 0,
    totalIgnorados: 0,
  );
  Map<String, String> tokensConvite = {};

  @override
  Future<Convidado?> buscarPorId(String idConvidado) async {
    idBuscado = idConvidado;
    return convidado;
  }

  @override
  Future<Convidado?> buscarPrimeiroPorEvento(String idEvento) async =>
      convidado;

  @override
  Future<Convidado?> buscarPorToken(String token) async => convidado;

  @override
  Stream<List<Convidado>> observarPorEvento(String idEvento) {
    eventoObservado = idEvento;
    return Stream.value(convidados);
  }

  @override
  Future<void> salvar(Convidado convidado) async {
    convidadoSalvo = convidado;
  }

  @override
  Future<void> excluir(String idConvidado) async {
    idExcluido = idConvidado;
  }

  @override
  Future<void> atualizarStatus(
    String idConvidado,
    StatusConvidado status,
    DateTime dataResposta,
  ) async {
    idStatus = idConvidado;
    this.status = status;
    this.dataResposta = dataResposta;
  }

  @override
  Future<MigracaoTipoConvidadoResultado> migrarTiposLegados() async {
    return migracaoResultado;
  }

  @override
  Future<void> garantirTokensConvite(Map<String, String> tokensPorId) async {
    tokensConvite = Map<String, String>.from(tokensPorId);
  }
}
