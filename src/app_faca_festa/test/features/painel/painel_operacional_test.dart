import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/painel_operacional_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_painel_ao_vivo.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_estatisticas.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';

Map<String, dynamic> fixture([bool falha = false]) => Map<String,
    dynamic>.from(jsonDecode(File(
        'test/fixtures/${falha ? 'painel_operacional_falha_emulador' : 'painel_operacional_emulador'}.json')
    .readAsStringSync()));

class Gateway implements CallableSessaoGateway {
  String? uid = 'f';
  final stream = StreamController<String?>.broadcast();
  Map<String, dynamic> d = fixture();
  bool falha = false;
  Completer<Map<String, dynamic>>? espera;
  @override
  String? get usuario => uid;
  @override
  Stream<String?> get sessoes => stream.stream;
  @override
  Future<Map<String, dynamic>> chamar(
      String fn, Map<String, dynamic> args) async {
    if (falha) throw Exception('rede');
    return espera?.future ?? Future.value(d);
  }

  void trocar(String? u) {
    uid = u;
    stream.add(u);
  }
}

class Usecase extends Fake implements GerenciarFornecedores {
  final espera = Completer<FornecedorEstatisticas>();
  final mensagens = StreamController<int>.broadcast(sync: true);

  @override
  Stream<int> observarMensagensNaoLidas(String uid) => mensagens.stream;

  @override
  Future<FornecedorEstatisticas> carregarEstatisticas(String uid) =>
      espera.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'última leitura fica desatualizada após cinco minutos e falha não inventa total',
      () async {
    final g = Gateway();
    var agora = DateTime.parse(g.d['geradoEm']);
    final c = PainelOperacionalController(gateway: g, clock: () => agora);
    await c.iniciar();
    expect(c.desatualizado.value, false);
    g.falha = true;
    await c.carregar();
    c.verificarAtualizacao();
    expect(c.desatualizado.value, true);
    g.falha = false;
    await c.carregar();
    expect(c.desatualizado.value, false);
    agora = agora.add(const Duration(minutes: 6));
    c.verificarAtualizacao();
    expect(c.desatualizado.value, true);
    g.falha = true;
    await c.carregar();
    expect(c.dados.value!['atendimentos']['primeiraRespostaHoras'], 1);
    expect(c.erro.value, contains('Os dados exibidos são da última consulta'));
    expect(c.erro.value, isNot(contains('se disponíveis')));
    g.falha = false;
    g.d['geradoEm'] = agora.toIso8601String();
    await c.carregar();
    expect(c.desatualizado.value, false);
    c.onClose();
    await g.stream.close();
  });
  test('resultado de sessão anterior é descartado', () async {
    final g = Gateway(), c = PainelOperacionalController(gateway: g);
    await c.iniciar();
    g.espera = Completer();
    final load = c.carregar();
    g.trocar(null);
    await Future<void>.delayed(Duration.zero);
    g.espera!.complete(fixture());
    await load;
    expect(c.dados.value, isNull);
    c.onClose();
    await g.stream.close();
  });
  test('fachada antiga não sobrescreve estatística da nova sessão', () async {
    String usuario = 'f';
    final f = Fornecedor(
        idFornecedor: 'f',
        idUsuario: 'f',
        razaoSocial: 'F',
        telefone: '',
        email: '',
        dataCadastro: DateTime(2030));
    final fornecedor = Rx<Fornecedor?>(f), pendentes = 0.obs, media = 0.0.obs;
    final u = Usecase();
    final p = FornecedorPainelAoVivo(
        fornecedor: fornecedor,
        aptoParaOperar: false.obs,
        solicitacoesPendentes: pendentes,
        mensagensNaoLidas: RxnInt(),
        avaliacaoMedia: media,
        servicosFornecedor: <FornecedorProdutoServico>[].obs,
        erro: ''.obs,
        usecase: () => u,
        usuarioEhFornecedor: () => true,
        usuarioAtual: () => usuario,
        aoAtualizar: (_) {},
        aoLimpar: () {});
    final load = p.atualizarEstatisticas();
    usuario = 'g';
    u.espera.complete(const FornecedorEstatisticas(
        solicitacoesPendentes: 99,
        servicosAtivos: [],
        mensagensNaoLidas: 99,
        avaliacaoMedia: 5));
    await load;
    expect(pendentes.value, 0);
    expect(media.value, 0);
    await p.cancelarEscutas();
    await u.mensagens.close();
  });

  test('contador recebe mensagens e leituras sem aceitar consulta antiga',
      () async {
    String usuario = 'f';
    final u = Usecase();
    final mensagens = RxnInt();
    final painel = FornecedorPainelAoVivo(
      fornecedor: Rx<Fornecedor?>(Fornecedor(
        idFornecedor: 'f',
        idUsuario: 'f',
        razaoSocial: 'Fornecedor',
        telefone: '',
        email: '',
        dataCadastro: DateTime(2026),
      )),
      aptoParaOperar: true.obs,
      solicitacoesPendentes: 0.obs,
      mensagensNaoLidas: mensagens,
      avaliacaoMedia: 0.0.obs,
      servicosFornecedor: <FornecedorProdutoServico>[].obs,
      erro: ''.obs,
      usecase: () => u,
      usuarioEhFornecedor: () => true,
      usuarioAtual: () => usuario,
      aoAtualizar: (_) {},
      aoLimpar: () {},
    );
    await painel.ouvirMensagensNaoLidas('f');
    expect(mensagens.value, isNull);
    u.mensagens.add(0);
    final consulta = painel.atualizarEstatisticas();
    u.mensagens.add(2);
    u.espera.complete(const FornecedorEstatisticas(
      solicitacoesPendentes: 0,
      servicosAtivos: [],
      mensagensNaoLidas: 0,
      avaliacaoMedia: 0,
    ));
    await consulta;
    expect(mensagens.value, 2);
    u.mensagens.add(1);
    expect(mensagens.value, 1);
    u.mensagens.addError(StateError('Consulta indisponível'));
    expect(mensagens.value, isNull);
    u.mensagens.add(0);
    expect(mensagens.value, 0);
    usuario = 'g';
    u.mensagens.add(5);
    expect(mensagens.value, 0);
    await painel.cancelarEscutas();
    expect(mensagens.value, isNull);
    await u.mensagens.close();
  });
}
