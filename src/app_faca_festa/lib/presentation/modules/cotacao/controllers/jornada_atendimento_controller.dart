import 'dart:async';
import 'package:app_faca_festa/data/services/functions/mensagem_falha_operacional.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:app_faca_festa/data/datasources/remote/jornada_atendimento_remote.dart';
import 'package:app_faca_festa/data/local/recebimento_pendente_store.dart';

class JornadaAtendimentoController extends GetxController {
  JornadaAtendimentoController(
      {required this.idCotacao,
      required this.idFornecedor,
      required this.gateway,
      RecebimentoPendenteStore? store,
      DateTime Function()? clock})
      : store = store ??
            RecebimentoPendenteLocalStore(namespace: 'jornada_pendente_v1'),
        clock = clock ?? DateTime.now;
  final String idCotacao, idFornecedor;
  final JornadaGateway gateway;
  final RecebimentoPendenteStore store;
  final DateTime Function() clock;
  final dados = Rxn<Map<String, dynamic>>(),
      pendente = Rxn<Map<String, dynamic>>();
  final carregando = false.obs, enviando = false.obs;
  final erro = ''.obs, mensagem = ''.obs;
  final codigoErroConsulta = ''.obs;
  StreamSubscription<String?>? _sub;
  String? _uid;
  int _g = 0;
  bool _fechado = false;
  int get sessaoVersao => _g;
  bool ativa(int g) =>
      !_fechado && g == _g && _uid != null && _uid == gateway.usuario;
  bool get fornecedor => dados.value?['papel'] == 'fornecedor';
  bool get contratada => dados.value?['estadoComercial'] == 'ganho';
  bool get propostaExpirada {
    final p = dados.value?['proposta'];
    final data =
        p is Map ? DateTime.tryParse(p['validade']?.toString() ?? '') : null;
    return data == null || !data.isAfter(clock().toUtc());
  }

  Future<void> iniciar() async {
    await _sub?.cancel();
    _sub = gateway.sessoes.listen((u) {
      if (u != _uid) unawaited(_trocar(u));
    });
    await _trocar(gateway.usuario);
  }

  Future<void> _trocar(String? uid) async {
    final g = ++_g;
    _uid = uid;
    dados.value = null;
    pendente.value = null;
    erro.value = '';
    codigoErroConsulta.value = '';
    mensagem.value = '';
    enviando.value = false;
    carregando.value = false;
    if (uid == null) {
      erro.value = 'Entre na sessão autorizada.';
      return;
    }
    try {
      final p = await store.ler(uid);
      if (!ativa(g)) return;
      // A intenção pode pertencer a outro atendimento. Não a envia por uma tela diferente.
      pendente.value = p;
      await carregar();
    } catch (e) {
      if (ativa(g)) {
        erro.value = 'Não foi possível iniciar a jornada. Tente novamente.';
      }
    }
  }

  Future<void> carregar() async {
    if (_uid == null || carregando.value) return;
    final g = _g;
    carregando.value = true;
    erro.value = '';
    codigoErroConsulta.value = '';
    try {
      final r = await gateway.chamar('consultarJornadaAtendimentoFn',
          {'idCotacao': idCotacao, 'idFornecedor': idFornecedor});
      if (ativa(g)) dados.value = r;
    } catch (e) {
      if (ativa(g)) {
        dados.value = null;
        codigoErroConsulta.value =
            e is FirebaseFunctionsException ? e.code : 'consulta-incompleta';
        erro.value = codigoErroConsulta.value == 'not-found'
            ? 'O serviço da jornada não foi encontrado neste ambiente. É necessário verificar sua publicação com o suporte.'
            : mensagemFalhaOperacional(e, recurso: 'a jornada do atendimento');
      }
    } finally {
      if (ativa(g)) carregando.value = false;
    }
  }

  Future<bool> comandar(String funcao, Map<String, dynamic> dadosComando,
      {int? sessao}) async {
    if ((sessao != null && !ativa(sessao)) ||
        dados.value == null ||
        enviando.value ||
        pendente.value != null) {
      erro.value =
          'Sessão alterada ou envio pendente. Recarregue/reconcilie antes de agir.';
      return false;
    }
    final uid = _uid!, g = _g;
    enviando.value = true;
    erro.value = '';
    try {
      final chave = const Uuid().v4(),
          op = {
            'chave': chave,
            'pedido': {
              'funcao': funcao,
              'idCotacao': idCotacao,
              'idFornecedor': idFornecedor,
              'dados': {
                ...dadosComando,
                if (funcao == 'abrirCasoMediacaoParte')
                  'chaveIdempotencia': chave
                else
                  'chave': chave
              }
            }
          };
      await store.salvar(uid, op);
      if (!ativa(g)) return false;
      pendente.value = op;
      return await _executar(op, uid, g);
    } catch (e) {
      if (ativa(g)) {
        erro.value =
            'Envio não confirmado; original preservado para reconciliação.';
      }
      return false;
    } finally {
      if (ativa(g)) enviando.value = false;
    }
  }

  bool get pendenteNestaJornada {
    final p = pendente.value?['pedido'];
    return p is Map &&
        p['idCotacao'] == idCotacao &&
        p['idFornecedor'] == idFornecedor;
  }

  Future<bool> retomar() async {
    final op = pendente.value;
    if (op != null && !pendenteNestaJornada) {
      erro.value =
          'Abra o atendimento original para reconciliar o envio pendente.';
      return false;
    }
    if (op == null || _uid == null || enviando.value || !ativa(_g)) {
      return false;
    }
    final g = _g, uid = _uid!;
    enviando.value = true;
    try {
      return await _executar(op, uid, g);
    } finally {
      if (ativa(g)) enviando.value = false;
    }
  }

  Future<bool> _executar(Map<String, dynamic> op, String uid, int g) async {
    try {
      final p = Map<String, dynamic>.from(op['pedido'] as Map);
      if (![
        'responderCotacao',
        'fecharCotacao',
        'movimentarComercialJornadaFn',
        'executarJornadaAtendimentoFn',
        'abrirCasoMediacaoParte'
      ].contains(p['funcao'])) {
        throw StateError('Comando inválido.');
      }
      await gateway.chamar(
          p['funcao'] as String, Map<String, dynamic>.from(p['dados'] as Map));
      await store.limpar(uid, chave: op['chave'] as String);
      if (!ativa(g)) return false;
      pendente.value = null;
      mensagem.value = 'Ação registrada com histórico.';
      await carregar();
      return true;
    } catch (e) {
      final definitivo = e is FirebaseFunctionsException &&
          [
            'invalid-argument',
            'permission-denied',
            'unauthenticated',
            'not-found',
            'failed-precondition',
            'already-exists',
            'aborted'
          ].contains(e.code);
      if (definitivo) await store.limpar(uid, chave: op['chave'] as String);
      if (ativa(g)) {
        if (definitivo) pendente.value = null;
        erro.value = definitivo
            ? (e.message ?? 'Recarregue antes de confirmar.')
            : 'Resultado desconhecido; retome o mesmo envio antes de criar outro.';
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
