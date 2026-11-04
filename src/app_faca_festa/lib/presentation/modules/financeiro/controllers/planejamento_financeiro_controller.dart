import 'dart:async';
import 'package:app_faca_festa/data/services/functions/mensagem_falha_operacional.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/data/local/recebimento_pendente_store.dart';

class PlanejamentoFinanceiroController extends GetxController {
  PlanejamentoFinanceiroController(
      {required this.gateway, RecebimentoPendenteStore? store})
      : store = store ??
            RecebimentoPendenteLocalStore(
                namespace: 'planejamento_financeiro_v1');
  final CallableSessaoGateway gateway;
  final RecebimentoPendenteStore store;
  final filtros = <String, dynamic>{};
  final dados = Rxn<Map<String, dynamic>>(),
      pendente = Rxn<Map<String, dynamic>>();
  final carregando = false.obs, enviando = false.obs;
  final erro = ''.obs;
  StreamSubscription<String?>? _sub;
  String? _uid;
  int _g = 0;
  bool _fechado = false;
  int get geracao => _g;
  bool ativa(int g) =>
      !_fechado && g == _g && _uid != null && gateway.usuario == _uid;
  Future<void> iniciar() async {
    _sub = gateway.sessoes.listen((u) {
      if (u != _uid) unawaited(_trocar(u));
    });
    await _trocar(gateway.usuario);
  }

  Future<void> _trocar(String? u) async {
    final g = ++_g;
    _uid = u;
    filtros.clear();
    dados.value = null;
    pendente.value = null;
    erro.value = '';
    carregando.value = false;
    enviando.value = false;
    if (u == null) {
      erro.value = 'Entre como fornecedor.';
      return;
    }
    try {
      final p = await store.ler(u);
      if (ativa(g)) pendente.value = p;
      await carregar();
    } catch (_) {
      if (ativa(g)) erro.value = 'Falha ao recuperar envio pendente.';
    }
  }

  Future<void> carregar() async {
    final g = _g;
    if (!ativa(g)) return;
    carregando.value = true;
    erro.value = '';
    try {
      final r =
          await gateway.chamar('consultarPlanejamentoFornecedorFn', filtros);
      if (ativa(g)) dados.value = r;
    } catch (e) {
      if (ativa(g)) {
        dados.value = null;
        erro.value =
            mensagemFalhaOperacional(e, recurso: 'o planejamento financeiro');
      }
    } finally {
      if (ativa(g)) carregando.value = false;
    }
  }

  Future<bool> comandar(String f, Map<String, dynamic> d,
      {required int geracao}) async {
    if (!ativa(geracao) ||
        enviando.value ||
        pendente.value != null ||
        dados.value == null) {
      return false;
    }
    final uid = _uid!;
    enviando.value = true;
    try {
      final chave = const Uuid().v4();
      final op = {
        'chave': chave,
        'funcao': f,
        'dados': {
          ...d,
          'chave': chave,
          if (f == 'retirarEstoqueFornecedor' ||
              f == 'devolverEstoqueFornecedor')
            'chaveIdempotencia': chave
        }
      };
      await store.salvar(uid, op);
      if (!ativa(geracao)) return false;
      pendente.value = op;
      return await _executar(op, uid, geracao);
    } catch (_) {
      if (ativa(geracao)) {
        erro.value = 'Resultado desconhecido. Retome o mesmo envio.';
      }
      return false;
    } finally {
      if (ativa(geracao)) enviando.value = false;
    }
  }

  Future<bool> retomar() async {
    if (pendente.value == null || enviando.value || !ativa(_g)) return false;
    final g = _g;
    enviando.value = true;
    try {
      return await _executar(pendente.value!, _uid!, g);
    } finally {
      if (ativa(g)) enviando.value = false;
    }
  }

  Future<bool> _executar(Map<String, dynamic> op, String uid, int g) async {
    try {
      if (!['comandarPlanejamentoFornecedorFn'].contains(op['funcao'])) {
        throw StateError('Comando inválido.');
      }
      await gateway.chamar(
          op['funcao'], Map<String, dynamic>.from(op['dados']));
      await store.limpar(uid, chave: op['chave']);
      if (!ativa(g)) return false;
      pendente.value = null;
      await carregar();
      return true;
    } catch (e) {
      final definitivo = e is FirebaseFunctionsException &&
          [
            'permission-denied',
            'invalid-argument',
            'failed-precondition',
            'unauthenticated',
            'not-found',
            'already-exists',
            'aborted'
          ].contains(e.code);
      if (definitivo) await store.limpar(uid, chave: op['chave']);
      if (ativa(g)) {
        if (definitivo) pendente.value = null;
        erro.value = definitivo
            ? e.message ?? 'Atualize antes de confirmar.'
            : 'Resultado desconhecido. Retome o mesmo envio.';
      }
      return false;
    }
  }

  @override
  void onClose() {
    _fechado = true;
    ++_g;
    unawaited(_sub?.cancel());
    super.onClose();
  }
}
