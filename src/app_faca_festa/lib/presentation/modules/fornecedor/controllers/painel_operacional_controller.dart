import 'dart:async';
import 'package:app_faca_festa/data/services/consultas_em_andamento.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';

class PainelOperacionalController extends GetxController {
  PainelOperacionalController(
      {required this.gateway,
      this.lerFontesDisponiveis,
      this.consultarConsolidado = true,
      DateTime Function()? clock})
      : clock = clock ?? DateTime.now;
  final CallableSessaoGateway gateway;
  final Future<Map<String, dynamic>> Function(String)? lerFontesDisponiveis;
  final bool consultarConsolidado;
  final fontesDisponiveis = Rxn<Map<String, dynamic>>();
  final DateTime Function() clock;
  final dados = Rxn<Map<String, dynamic>>();
  final carregando = false.obs, desatualizado = false.obs;
  final erro = ''.obs;
  StreamSubscription<String?>? _sessao;
  Timer? _timer;
  String? _uid;
  int _g = 0, _consulta = 0;
  bool _fechado = false, _falhaUltimaConsulta = false;
  Future<void>? _inicio;
  final _leituras = ConsultasEmAndamento<void>();
  bool _valido(int g) =>
      !_fechado && g == _g && _uid != null && _uid == gateway.usuario;
  Future<void> iniciar() {
    if (_fechado) return Future.value();
    return _inicio ??= _iniciar();
  }

  Future<void> _iniciar() async {
    _sessao = gateway.sessoes.listen((u) {
      if (u != _uid) unawaited(_trocar(u));
    });
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      verificarAtualizacao();
    });
    await _trocar(gateway.usuario);
  }

  Future<void> _trocar(String? u) async {
    ++_g;
    ++_consulta;
    _uid = u;
    dados.value = null;
    fontesDisponiveis.value = null;
    _falhaUltimaConsulta = false;
    erro.value = '';
    carregando.value = false;
    desatualizado.value = false;
    if (u == null) {
      erro.value = 'Entre como fornecedor.';
      return;
    }
    await carregar();
  }

  void verificarAtualizacao() {
    final gerado = DateTime.tryParse(dados.value?['geradoEm'] ?? '');
    desatualizado.value = dados.value != null &&
        (_falhaUltimaConsulta ||
            (gerado != null &&
                clock().toUtc().difference(gerado).inMinutes >= 5));
  }

  Future<void> carregar({bool aposAlteracao = false}) {
    if (aposAlteracao) _leituras.invalidar();
    return _leituras.executar('$_g', _carregar);
  }

  Future<void> _carregar() async {
    final g = _g, q = ++_consulta;
    if (!_valido(g)) return;
    carregando.value = true;
    erro.value = '';
    final fontes = _carregarFontes(g, q);
    try {
      // A visão de cartões já obtém suas métricas nas fontes diretas.
      // Não calcula agenda, caixa ou fila detalhada que ela não apresenta.
      if (!consultarConsolidado) {
        await fontes;
        if (!_valido(g) || q != _consulta) return;
        final locais = fontesDisponiveis.value;
        if (locais == null) throw StateError('Indicadores indisponíveis.');
        final agora = clock().toUtc();
        dados.value = {
          'geradoEm': locais['consultadoEm'] ?? agora.toIso8601String(),
          'periodo': {
            'de': agora.subtract(const Duration(hours: 720)).toIso8601String(),
            'ate': agora.toIso8601String(),
            'fuso': 'America/Sao_Paulo',
          },
        };
        _falhaUltimaConsulta = false;
        verificarAtualizacao();
        return;
      }
      final r = await gateway.chamar('consultarPainelFornecedorFn', {}).timeout(
          const Duration(seconds: 15));
      if (!_valido(g) || q != _consulta) return;
      _falhaUltimaConsulta = false;
      dados.value = r;
      verificarAtualizacao();
    } catch (_) {
      if (_valido(g) && q == _consulta) {
        _falhaUltimaConsulta = true;
        erro.value = dados.value == null
            ? 'Tente novamente em instantes para consultar suas pendências.'
            : 'Os dados exibidos são da última consulta. Tente atualizar novamente.';
        desatualizado.value = dados.value != null;
      }
    } finally {
      await fontes;
      if (_valido(g) && q == _consulta) carregando.value = false;
    }
  }

  Future<void> _carregarFontes(int g, int q) async {
    final ler = lerFontesDisponiveis;
    if (ler == null || _uid == null) return;
    try {
      final r = await ler(_uid!);
      if (_valido(g) && q == _consulta) fontesDisponiveis.value = r;
    } catch (_) {
      if (_valido(g) && q == _consulta) fontesDisponiveis.value = null;
    }
  }

  @override
  void onClose() {
    _fechado = true;
    ++_g;
    ++_consulta;
    unawaited(_sessao?.cancel());
    _timer?.cancel();
    dados.value = null;
    fontesDisponiveis.value = null;
    super.onClose();
  }
}
