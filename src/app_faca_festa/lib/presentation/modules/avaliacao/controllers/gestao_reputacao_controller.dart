import 'dart:async';
import 'package:app_faca_festa/data/services/functions/mensagem_falha_operacional.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:app_faca_festa/data/local/recebimento_pendente_store.dart';
import 'package:app_faca_festa/data/datasources/remote/gestao_reputacao_remote.dart';
import 'package:app_faca_festa/domain/entities/gestao_reputacao.dart';

class GestaoReputacaoController extends GetxController {
  GestaoReputacaoController(
      {required this.gateway,
      this.idFornecedor,
      this.idAvaliacao,
      this.moderacao = false,
      RecebimentoPendenteStore? store,
      DateTime Function()? clock})
      : store = store ??
            RecebimentoPendenteLocalStore(namespace: 'reputacao_pendente_v1'),
        clock = clock ?? DateTime.now;
  final ReputacaoGateway gateway;
  final RecebimentoPendenteStore store;
  final String? idFornecedor, idAvaliacao;
  final bool moderacao;
  final DateTime Function() clock;
  final itens = <ComentarioReputacao>[].obs;
  final casos = <Map<String, dynamic>>[].obs;
  final resumo = Rxn<Map<String, dynamic>>();
  final carregando = false.obs,
      enviando = false.obs,
      temMais = false.obs,
      autorizado = false.obs;
  final erro = ''.obs, mensagem = ''.obs;
  final pendente = Rxn<Map<String, dynamic>>();
  final nota = 0.obs, dias = 0.obs;
  final resposta = 'todas'.obs, tipo = 'fornecedor'.obs, situacao = 'todas'.obs;
  String? _cursor, _usuario;
  int _geracao = 0;
  Map<String, dynamic>? _consultaAtiva;
  int get sessaoVersao => _geracao;
  bool sessaoAtiva(int v) =>
      v == _geracao && autorizado.value && gateway.usuario == _usuario;
  Future<Map<String, dynamic>> historico(ComentarioReputacao a) async {
    final g = _geracao, uid = _usuario;
    final r = await gateway.chamar('historicoRespostaReputacaoFn',
        {'idFornecedor': idFornecedor, 'idAvaliacao': a.id});
    if (!_valido(g, uid)) throw StateError('Sessão alterada.');
    return r;
  }

  StreamSubscription<String?>? _sessao;
  bool _fechado = false;
  Future<void> iniciar() async {
    await _sessao?.cancel();
    _sessao = gateway.sessoes.listen((uid) {
      if (uid != _usuario) unawaited(_trocarSessao(uid));
    });
    await _trocarSessao(gateway.usuario);
  }

  Future<void> _trocarSessao(String? uid) async {
    final g = ++_geracao;
    _usuario = uid;
    itens.clear();
    casos.clear();
    resumo.value = null;
    pendente.value = null;
    erro.value = '';
    mensagem.value = '';
    _cursor = null;
    _consultaAtiva = null;
    temMais.value = false;
    enviando.value = false;
    carregando.value = false;
    autorizado.value = false;
    if (uid == null || (!moderacao && uid != idFornecedor)) {
      erro.value = 'Acesse com a sessão autorizada.';
      return;
    }
    try {
      if (moderacao) {
        final p = await gateway.chamar('consultarPermissaoReputacaoFn', {});
        if (!_valido(g, uid)) return;
        if (p['moderar'] != true) {
          erro.value = 'Permissão específica de moderação necessária.';
          return;
        }
      }
      if (!_valido(g, uid)) return;
      autorizado.value = true;
      final salvo = await store.ler(uid);
      if (!_valido(g, uid)) return;
      pendente.value = salvo;
      if (salvo != null) {
        await retomar();
      } else {
        await carregar();
      }
    } catch (e) {
      if (_valido(g, uid)) {
        erro.value = mensagemFalhaOperacional(e,
            recurso: moderacao ? 'a fila de moderação' : 'suas avaliações');
      }
    }
  }

  bool _valido(int g, String? uid) =>
      !_fechado && g == _geracao && gateway.usuario == uid && _usuario == uid;
  Map<String, dynamic> _filtros() => moderacao
      ? {'situacao': situacao.value}
      : {
          'idFornecedor': idFornecedor,
          if (idAvaliacao != null) 'idAvaliacao': idAvaliacao,
          'tipo': tipo.value,
          'resposta': resposta.value,
          if (nota.value != 0) 'nota': nota.value,
          if (dias.value != 0)
            'de': clock()
                .toUtc()
                .subtract(Duration(days: dias.value))
                .toIso8601String()
        };
  Future<void> carregar({bool mais = false}) async {
    if (!autorizado.value || carregando.value) return;
    final uid = _usuario, g = _geracao;
    carregando.value = true;
    erro.value = '';
    try {
      if (!mais || _consultaAtiva == null) _consultaAtiva = _filtros();
      final r = await gateway.chamar(
          moderacao ? 'listarFilaReputacaoFn' : 'consultarGestaoReputacaoFn', {
        ..._consultaAtiva!,
        'limite': 10,
        if (mais && _cursor != null) 'cursor': _cursor
      });
      if (!_valido(g, uid)) return;
      if (!mais) {
        itens.clear();
        casos.clear();
      }
      final rows =
          (r['itens'] as List).map((v) => Map<String, dynamic>.from(v as Map));
      if (moderacao) {
        for (final row in rows) {
          if (!casos.any((v) => v['id'] == row['id'])) casos.add(row);
        }
      } else {
        for (final row in rows) {
          if (!itens.any((v) => v.id == row['id'])) {
            itens.add(ComentarioReputacao.fromMap(row));
          }
        }
        resumo.value = Map<String, dynamic>.from(r['resumo'] as Map);
      }
      _cursor = r['cursor'] as String?;
      temMais.value = _cursor != null;
    } catch (e) {
      if (_valido(g, uid)) {
        if (!mais) {
          itens.clear();
          casos.clear();
          resumo.value = null;
        }
        erro.value = mensagemFalhaOperacional(e,
            recurso: moderacao ? 'a fila de moderação' : 'suas avaliações');
      }
    } finally {
      if (_valido(g, uid)) carregando.value = false;
    }
  }

  Future<void> filtrar() async {
    if (enviando.value) return;
    ++_geracao;
    carregando.value = false;
    itens.clear();
    casos.clear();
    resumo.value = null;
    _cursor = null;
    temMais.value = false;
    await carregar();
  }

  Future<bool> responder(ComentarioReputacao a, String texto) =>
      _enviar('responderReputacaoFn', {
        'idFornecedor': idFornecedor,
        'idAvaliacao': a.id,
        'texto': texto.trim(),
        'versaoEsperada': a.resposta?['versao'] ?? 0
      });
  Future<bool> denunciar(
          ComentarioReputacao a, String motivo, String descricao) =>
      _enviar('denunciarReputacaoFn', {
        'idFornecedor': idFornecedor,
        'idAvaliacao': a.id,
        'motivo': motivo,
        'descricao': descricao.trim()
      });
  Future<bool> decidir(Map<String, dynamic> c, String acao, String decisao,
          String fundamento, String interna) =>
      _enviar('decidirDenunciaReputacaoFn', {
        'idCaso': c['id'],
        'acao': acao,
        if (acao == 'encerrar') 'decisao': decisao,
        'fundamentacao': fundamento.trim(),
        'notaInterna': interna.trim(),
        'versaoEsperada': c['versao']
      });
  Future<bool> _enviar(String funcao, Map<String, dynamic> dados) async {
    if (!autorizado.value || enviando.value || pendente.value != null) {
      erro.value = 'Reconcilie o envio pendente antes de criar outro.';
      return false;
    }
    final uid = _usuario, g = _geracao;
    if (uid == null) return false;
    enviando.value = true;
    erro.value = '';
    try {
      final chave = const Uuid().v4(),
          op = {
            'chave': chave,
            'pedido': {
              'funcao': funcao,
              'dados': {...dados, 'chave': chave}
            }
          };
      await store.salvar(uid, op);
      if (!_valido(g, uid)) return false;
      pendente.value = op;
      return await _executar(op, uid, g);
    } catch (e) {
      if (_valido(g, uid)) {
        erro.value = 'Não foi possível preservar o envio. Tente novamente.';
      }
      return false;
    } finally {
      if (_valido(g, uid)) enviando.value = false;
    }
  }

  Future<bool> retomar() async {
    final op = pendente.value, uid = _usuario, g = _geracao;
    if (op == null || uid == null || enviando.value || !autorizado.value) {
      return false;
    }
    enviando.value = true;
    try {
      return await _executar(op, uid, g);
    } finally {
      if (_valido(g, uid)) enviando.value = false;
    }
  }

  Future<bool> _executar(Map<String, dynamic> op, String uid, int g) async {
    try {
      final p = Map<String, dynamic>.from(op['pedido'] as Map);
      if (![
        'responderReputacaoFn',
        'denunciarReputacaoFn',
        'decidirDenunciaReputacaoFn'
      ].contains(p['funcao'])) {
        throw StateError('Operação inválida.');
      }
      await gateway.chamar(
          p['funcao'] as String, Map<String, dynamic>.from(p['dados'] as Map));
      await store.limpar(uid, chave: op['chave'] as String);
      if (!_valido(g, uid)) return false;
      pendente.value = null;
      mensagem.value = 'Registro confirmado e histórico preservado.';
      erro.value = '';
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
      if (_valido(g, uid)) {
        if (definitivo) pendente.value = null;
        erro.value = definitivo
            ? (e.message ?? 'Conflito: recarregue antes de editar.')
            : 'Resultado desconhecido. Envio preservado; use Retomar envio.';
      }
      return false;
    }
  }

  @override
  void onClose() {
    _fechado = true;
    ++_geracao;
    unawaited(_sessao?.cancel());
    super.onClose();
  }
}
