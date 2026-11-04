import 'dart:convert';
import 'package:app_faca_festa/data/services/functions/diagnostico_consulta_financeira.dart';
import 'package:app_faca_festa/data/local/recebimento_pendente_store.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'package:app_faca_festa/data/datasources/remote/financeiro_fornecedor_remote_datasource.dart';
import 'package:app_faca_festa/domain/entities/financeiro/alerta_financeiro.dart';
import 'package:app_faca_festa/domain/services/resumo_financeiro_fornecedor_service.dart';

/// Financeiro privado da empresa fornecedora (proprietário = uid).
class FinanceiroFornecedorController extends GetxController {
  FinanceiroFornecedorController({
    required FirebaseFirestore firestore,
    required this.idFornecedor,
    String? Function()? usuarioAtual,
    FinanceiroFornecedorRemoteDatasource? remote,
    ResumoFinanceiroFornecedorService? resumoService,
    RecebimentoPendenteStore? pendencias,
    RecebimentoPendenteStore? pendenciasCustos,
  })  : _db = firestore,
        _usuarioAtual = usuarioAtual,
        _remote = remote,
        _pendencias = pendencias ?? RecebimentoPendenteLocalStore(),
        _pendenciasCustos = pendenciasCustos ??
            RecebimentoPendenteLocalStore(namespace: "custos_pendentes_v1"),
        _resumoService =
            resumoService ?? const ResumoFinanceiroFornecedorService();

  final FirebaseFirestore _db;
  final String idFornecedor;
  final String? Function()? _usuarioAtual;
  final FinanceiroFornecedorRemoteDatasource? _remote;
  final ResumoFinanceiroFornecedorService _resumoService;
  final _uuid = const Uuid();
  final RecebimentoPendenteStore _pendencias;
  final recebimentoPendente = Rxn<Map<String, dynamic>>();
  final custoPendente = Rxn<Map<String, dynamic>>();
  final RecebimentoPendenteStore _pendenciasCustos;

  final resumo = Rxn<ResumoFinanceiroFornecedor>();

  /// Começa true para a 1ª frame não pintar "Sem resumo ainda" antes do iniciar().
  final carregando = true.obs;

  /// True enquanto a callable de resumo da plataforma ainda não respondeu.
  final aguardandoPlataforma = false.obs;

  /// Só libera empty state depois da 1ª tentativa de carga.
  final primeiraCargaConcluida = false.obs;
  final enviando = false.obs;
  final erro = ''.obs;
  final diagnosticoConsulta = Rxn<DiagnosticoConsultaFinanceira>();

  /// Valores de plataforma ainda não confiáveis (evita mostrar R$ 0,00 / empty falso).
  bool get valoresEmCarga =>
      !primeiraCargaConcluida.value ||
      carregando.value ||
      aguardandoPlataforma.value;
  final filtroEventoId = ''.obs;
  final nomesEventos = <String, String>{}.obs;
  bool _eventosConsultados = false;

  String nomeEvento(String id) {
    final nome = nomesEventos[id]?.trim() ?? '';
    if (nome.isNotEmpty) return nome;
    final servicos = vendas
        .where((v) => v.idEvento == id)
        .map((v) => v.nomeServico?.trim() ?? '')
        .where((n) => n.isNotEmpty)
        .toSet();
    return servicos.isEmpty
        ? 'Evento sem nome'
        : 'Evento sem nome · ${servicos.join(', ')}';
  }

  void _guardarEventos(dynamic lista) {
    if (lista is! List) return;
    for (final e in lista.whereType<Map>()) {
      final id =
          (e['idEvento'] ?? e['id_evento'] ?? e['id'])?.toString().trim() ?? '';
      final nome = (e['nomeEvento'] ?? e['nome_evento'] ?? e['nome'])
              ?.toString()
              .trim() ??
          '';
      if (id.isNotEmpty && (nome.isNotEmpty || !nomesEventos.containsKey(id))) {
        nomesEventos[id] = nome;
      }
    }
  }

  final filtroCategoria = ''.obs;
  final periodoInicio = Rxn<DateTime>();
  final periodoFim = Rxn<DateTime>();
  final vencimentoAte = Rxn<DateTime>();
  final saldoInicialInformado = Rxn<double>();
  final comissaoInformada = Rxn<double>();
  final taxasInformadas = Rxn<double>();
  final tributosInformados = Rxn<double>();

  final vendas = <VendaFornecedorFato>[].obs;
  final custos = <CustoFornecedorFato>[].obs;
  final recebimentos = <RecebimentoCaixaFato>[].obs;
  final movimentos = <MovimentoCaixaFornecedor>[].obs;

  int _geracao = 0;
  int _consulta = 0;
  int _envioRecebimento = 0;
  Timer? _reconsulta;
  bool _recebimentosCarregados = false,
      _movimentosCarregados = false,
      _custosCarregados = false;
  final List<StreamSubscription> _subs = [];

  bool get autorizado {
    final uid = _usuarioAtual?.call();
    return uid != null && uid == idFornecedor;
  }

  /// Eventos da consulta autorizada, preservados ao alternar o filtro.
  List<String> get eventosConhecidosIds {
    final ids = <String>{...nomesEventos.keys};
    for (final v in vendas) {
      if (v.idEvento.trim().isNotEmpty) ids.add(v.idEvento.trim());
    }
    for (final c in custos) {
      if (c.idEvento.trim().isNotEmpty) ids.add(c.idEvento.trim());
    }
    for (final m in movimentos) {
      final id = m.idEvento?.trim() ?? '';
      if (id.isNotEmpty) ids.add(id);
    }
    final atual = filtroEventoId.value.trim();
    if (atual.isNotEmpty) ids.add(atual);
    final lista = ids.toList()
      ..sort((a, b) =>
          nomeEvento(a).toLowerCase().compareTo(nomeEvento(b).toLowerCase()));
    return lista;
  }

  /// Agrupa alertas pela mesma causa (mensagem), preservando eventos distintos.
  List<AlertaAgrupadoFinanceiro> get alertasAgrupados =>
      agruparAlertasFinanceiros(resumo.value?.alertas ?? const []);

  /// Contratos com saldo a receber (para lista na UI).
  List<VendaFornecedorFato> get contratosAReceber =>
      contratosListados.where((v) => v.aReceber > 0.009).toList();

  List<VendaFornecedorFato> get contratosListados {
    final idEv = filtroEventoId.value.trim();
    final daApi = vendas.where((v) {
      if (idEv.isNotEmpty && v.idEvento != idEv) return false;
      return v.valorContratado > 0;
    }).toList();
    if (daApi.isNotEmpty) return daApi;

    // Fallback antes do deploy da function com `contratos`.
    final r = resumo.value;
    if (r == null || r.contratado <= 0) return const [];
    return [
      VendaFornecedorFato(
        id: 'resumo',
        idEvento: r.idEvento ?? idEv,
        nomeServico: 'Contratos fechados',
        valorContratado: r.contratado,
        recebidoConfirmado: r.recebido,
        situacao: r.aReceber > 0.009
            ? (r.recebido > 0 ? 'parcial' : 'aguardando_repasse')
            : 'recebido',
      ),
    ];
  }

  void aplicarFiltroEvento(String? id) {
    filtroEventoId.value = (id ?? '').trim();
  }

  void limparFiltroEvento() {
    filtroEventoId.value = '';
  }

  /// Aplica deduções informadas (comissão/taxas/tributos) e recalcula.
  Future<void> informarDeducoes({
    double? comissao,
    double? taxas,
    double? tributos,
  }) async {
    if (comissao != null) comissaoInformada.value = comissao;
    if (taxas != null) taxasInformadas.value = taxas;
    if (tributos != null) tributosInformados.value = tributos;
    await iniciar();
  }

  /// [forcarLimpeza] zera cache local (pull-to-refresh total).
  Future<void> iniciar({bool forcarLimpeza = false}) async {
    final geracao = ++_geracao;
    final uid = _usuarioAtual?.call();
    await _cancelar();
    erro.value = '';
    diagnosticoConsulta.value = null;
    if (!autorizado) {
      nomesEventos.clear();
      _eventosConsultados = false;
      erro.value = 'Sem autorização para o financeiro privado.';
      carregando.value = false;
      aguardandoPlataforma.value = false;
      primeiraCargaConcluida.value = true;
      return;
    }

    // Não apaga o resumo já visível — evita tela branca enquanto a callable demora.
    if (forcarLimpeza) {
      resumo.value = null;
      vendas.clear();
      custos.clear();
      movimentos.clear();
      recebimentos.clear();
    }
    carregando.value = true;

    // Listeners locais sobem na hora (custos/caixa) em paralelo com a callable.
    _observarPrivado(geracao, uid);

    final remote = _remote;
    if (remote == null) {
      aguardandoPlataforma.value = false;
      carregando.value = false;
      primeiraCargaConcluida.value = true;
      return;
    }

    try {
      unawaited(_recuperarCustoPendente(geracao, uid));
      final pendente = await _pendencias.ler(idFornecedor);
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
      recebimentoPendente.value = pendente;
      if (recebimentoPendente.value != null) {
        await _reconciliarRecebimento(recebimentoPendente.value!);
      }
    } catch (_) {
      // Preserva resultado desconhecido; o botão de retomada usa a mesma chave.
    }
    await _consultarPlataforma(geracao, uid);
  }

  Future<void> _recuperarCustoPendente(int geracao, String? uid) async {
    try {
      final custo = await _pendenciasCustos.ler(idFornecedor);
      if (geracao == _geracao && uid == _usuarioAtual?.call() && autorizado) {
        custoPendente.value = custo;
      }
    } catch (_) {
      if (geracao == _geracao) {
        erro.value = 'Falha ao recuperar custo pendente.';
      }
    }
  }

  Future<void> _carregarNomesEventos(
      FinanceiroFornecedorRemoteDatasource remote,
      int geracao,
      String? uid) async {
    _eventosConsultados = true;
    try {
      final planejamento = await remote.consultarEventosDoPlanejamento();
      if (geracao == _geracao && uid == _usuarioAtual?.call() && autorizado) {
        _guardarEventos(planejamento['resultados']);
      } else if (uid == _usuarioAtual?.call()) {
        _eventosConsultados = false;
      }
    } catch (_) {
      // A identificação não deve atrasar nem invalidar os valores financeiros.
      if (geracao == _geracao) _eventosConsultados = false;
    }
  }

  Future<void> _consultarPlataforma(int geracao, String? uid) async {
    final remote = _remote;
    if (remote == null || geracao != _geracao) return;
    final consulta = ++_consulta;
    aguardandoPlataforma.value = true;
    try {
      final raw = await remote
          .consultarResumo(
            idFornecedor: idFornecedor,
            idEvento:
                filtroEventoId.value.isEmpty ? null : filtroEventoId.value,
            saldoInicial: saldoInicialInformado.value,
            comissao: comissaoInformada.value,
            taxas: taxasInformadas.value,
            tributos: tributosInformados.value,
          )
          .timeout(FinanceiroFornecedorRemoteDatasource.timeoutConsulta);
      if (consulta != _consulta ||
          geracao != _geracao ||
          uid != _usuarioAtual?.call()) {
        return;
      }
      if (raw['origem'] != 'contratos_repasses' ||
          raw['aReceber'] is! num ||
          raw['contratado'] is! num ||
          raw['recebido'] is! num) {
        throw const RespostaFinanceiraIncompativel();
      }
      resumo.value = _mapearResumoRemote(raw);
      vendas.assignAll(_mapearContratosRemote(raw));
      _guardarEventos(raw['eventos']);
      _guardarEventos(raw['contratos']);
      if (raw['eventos'] is! List && !_eventosConsultados) {
        unawaited(_carregarNomesEventos(remote, geracao, uid));
      }
      diagnosticoConsulta.value = null;
      erro.value = '';
    } catch (e) {
      if (consulta != _consulta ||
          geracao != _geracao ||
          uid != _usuarioAtual?.call()) {
        return;
      }
      resumo.value = null;
      vendas.clear();
      final diagnostico = diagnosticarConsultaFinanceira(e);
      diagnosticoConsulta.value = diagnostico;
      erro.value = diagnostico.mensagem;
    } finally {
      if (consulta == _consulta && geracao == _geracao) {
        aguardandoPlataforma.value = false;
        carregando.value = false;
        primeiraCargaConcluida.value = true;
      }
    }
  }

  void _observarPrivado(int geracao, String? uid) {
    _subs.add(_db
        .collection('orcamento')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .snapshots()
        .listen((_) => _agendarConsulta(geracao, uid), onError: (_) {
      if (geracao == _geracao) {
        resumo.value = null;
        vendas.clear();
        erro.value = 'Contratos indisponíveis.';
      }
    }));
    _recebimentosCarregados = false;
    _movimentosCarregados = false;
    _custosCarregados = false;
    final base = _db.collection('fornecedor').doc(idFornecedor);
    _subs.add(base.collection('custos_internos').snapshots().listen((snap) {
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
      _custosCarregados = true;
      custos.assignAll(snap.docs.map((d) {
        final m = d.data();
        return CustoFornecedorFato(
          id: d.id,
          idEvento: (m['id_evento'] ?? '').toString(),
          incorrido: _centavosReais(m['valor_incorrido']),
          restantePrevisto: _centavosReais(m['previsto_restante']),
          desembolsoCaixa: _centavosReais(m['valor_desembolso']),
          origem: (m['origem'] ?? 'manual').toString(),
          tipo: (m['tipo'] ?? 'outro').toString(),
          direto: m['direto'] != false,
          categoria: m['categoria']?.toString(),
        );
      }));
      _recalcularLocal(geracao, uid);
    }, onError: (_) {
      if (geracao == _geracao) {
        erro.value = 'Acesso aos custos privados negado ou indisponível.';
      }
    }));

    _subs.add(base.collection('contas_receber').snapshots().listen((snap) {
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
      _recebimentosCarregados = true;
      try {
        recebimentos.assignAll(snap.docs.map((d) {
          final m = d.data();
          if (m['valor'] is! Map || (m['valor'] as Map)['centavos'] is! int) {
            throw StateError('Valor de recebimento inválido.');
          }
          final alocacoes = <String, int>{};
          if (m['alocacoes'] is List) {
            for (final a in m['alocacoes'] as List) {
              alocacoes[a['id_contrato'].toString()] =
                  (a['centavos'] as num).toInt();
            }
          } else if (m['id_contrato'] != null || m['id_orcamento'] != null) {
            alocacoes[(m['id_contrato'] ?? m['id_orcamento']).toString()] =
                (_centavosReais(m['valor']) * 100).round();
          }
          return RecebimentoCaixaFato(
              id: d.id,
              idEvento: (m['id_evento'] ?? '').toString(),
              valorCentavos: (_centavosReais(m['valor']) * 100).round(),
              tipo: m['origem'] == 'repasse_plataforma'
                  ? 'repasse_plataforma'
                  : m['adiantamento'] == true
                      ? 'adiantamento'
                      : (m['tipo'] ?? 'recebimento_externo').toString(),
              alocacoes: alocacoes,
              referencia: m['referencia_recebimento']?.toString(),
              estornadoCentavos:
                  (m['estornado_centavos'] as num?)?.toInt() ?? 0);
        }));
      } catch (_) {
        resumo.value = null;
        erro.value =
            'Recebimento inválido; dados preservados para conferência.';
        return;
      }
      _recalcularLocal(geracao, uid);
    }, onError: (Object _) {
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
      _recebimentosCarregados = false;
      resumo.value = null;
      erro.value =
          'Recebimentos privados indisponíveis; a operação pendente foi preservada.';
    }));

    _subs.add(base.collection('movimentos_caixa').snapshots().listen((snap) {
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
      _movimentosCarregados = true;
      movimentos.assignAll(snap.docs.map((d) {
        final m = d.data();
        return MovimentoCaixaFornecedor(
          id: d.id,
          valor: _centavosReais(m['valor']),
          entrada: m['entrada'] == true,
          idEvento: m['id_evento']?.toString(),
          descricao: m['origem']?.toString(),
          referenciaRecebimento: m['id_recebimento_origem']?.toString(),
          chaveIdempotencia: m['chave_idempotencia']?.toString(),
        );
      }));
      _recalcularLocal(geracao, uid);
    }, onError: (Object _) {
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
      _movimentosCarregados = false;
      resumo.value = null;
      erro.value = 'Caixa privado indisponível; valores ausentes não são zero.';
    }));
  }

  void _agendarConsulta(int geracao, String? uid) {
    if (_remote == null || geracao != _geracao) return;
    _reconsulta?.cancel();
    _reconsulta = Timer(const Duration(milliseconds: 300),
        () => _consultarPlataforma(geracao, uid));
  }

  void _recalcularLocal(int geracao, String? uid) {
    if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
    if (!autorizado) {
      resumo.value = null;
      return;
    }
    if (_remote != null) {
      _agendarConsulta(geracao, uid);
      return;
    }
    if (!_recebimentosCarregados ||
        !_movimentosCarregados ||
        !_custosCarregados) {
      return;
    }
    final filtradosCustos = custos.where((c) {
      if (filtroEventoId.value.isNotEmpty &&
          c.idEvento != filtroEventoId.value) {
        return false;
      }
      if (filtroCategoria.value.isNotEmpty &&
          (c.categoria ?? '')
                  .toLowerCase()
                  .contains(filtroCategoria.value.toLowerCase()) ==
              false &&
          c.categoria != null) {
        return false;
      }
      return true;
    }).toList();

    // Se remote já preencheu vendas, reusa; senão só custos/caixa locais.
    try {
      final r = _resumoService.calcular(
        idFornecedor: idFornecedor,
        idEvento: filtroEventoId.value.isEmpty ? null : filtroEventoId.value,
        vendas: vendas,
        custos: filtradosCustos,
        movimentos: movimentos,
        recebimentos: recebimentos,
        saldoInicialInformado: saldoInicialInformado.value,
        comissaoInformada: comissaoInformada.value,
        taxasInformadas: taxasInformadas.value,
        tributosInformados: tributosInformados.value,
      );
      resumo.value = r;
    } catch (_) {
      resumo.value = null;
      erro.value =
          'Caixa em conciliação: fato e espelho ainda não concordam. Atualize para conferir.';
      return;
    }
    // Só libera o loading global quando a plataforma já respondeu (ou não há remote).
    if (!aguardandoPlataforma.value) {
      carregando.value = false;
    }
  }

  Future<bool> registrarCustoManual({
    required String idEvento,
    required int valorCentavos,
    String tipo = 'material',
    String origem = 'manual',
    int previstoRestanteCentavos = 0,
    int desembolsoCentavos = 0,
    bool reutilizavel = false,
    String? descricao,
  }) async {
    final pedido = <String, dynamic>{
      'idEvento': idEvento,
      'valorCentavos': valorCentavos,
      'tipo': tipo,
      'origem': origem,
      'previstoRestanteCentavos': previstoRestanteCentavos,
      'desembolsoCentavos':
          origem == 'estoque_consumo' ? 0 : desembolsoCentavos,
      'reutilizavel': reutilizavel,
      'descricao': descricao
    };

    if (!autorizado || _remote == null || enviando.value) return false;
    final g = _geracao, uid = _usuarioAtual?.call();
    enviando.value = true;
    try {
      final anterior = await _pendenciasCustos.ler(idFornecedor);
      if (g != _geracao || uid != _usuarioAtual?.call()) return false;
      if (anterior != null &&
          jsonEncode(anterior['pedido']) != jsonEncode(pedido)) {
        custoPendente.value = anterior;
        erro.value =
            'Há custo pendente. Retome o original antes de lançar outro.';
        return false;
      }
      final op = anterior ?? {'chave': _uuid.v4(), 'pedido': pedido};
      await _pendenciasCustos.salvar(idFornecedor, op);
      if (g != _geracao || uid != _usuarioAtual?.call()) return false;
      custoPendente.value = op;
      return await _executarCustoPendente(op, g, uid);
    } catch (e) {
      if (g == _geracao) {
        erro.value = 'Não foi possível salvar o envio do custo: $e';
      }
      return false;
    } finally {
      if (g == _geracao) enviando.value = false;
    }
  }

  Future<bool> retomarCustoPendente() async {
    if (!autorizado || _remote == null || enviando.value) return false;
    final g = _geracao, uid = _usuarioAtual?.call();
    enviando.value = true;
    try {
      final op = await _pendenciasCustos.ler(idFornecedor);
      if (op == null || g != _geracao || uid != _usuarioAtual?.call()) {
        return false;
      }
      return await _executarCustoPendente(op, g, uid);
    } finally {
      if (g == _geracao) enviando.value = false;
    }
  }

  Future<bool> _executarCustoPendente(
      Map<String, dynamic> op, int geracao, String? uid) async {
    try {
      final p = Map<String, dynamic>.from(op['pedido']);
      await _remote!.registrarCusto(
          idFornecedor: idFornecedor,
          idEvento: p['idEvento'],
          chaveIdempotencia: op['chave'],
          valorCentavos: p['valorCentavos'],
          tipo: p['tipo'],
          origem: p['origem'],
          previstoRestanteCentavos: p['previstoRestanteCentavos'],
          desembolsoCentavos: p['desembolsoCentavos'],
          reutilizavel: p['reutilizavel'],
          descricao: p['descricao']);
      await _pendenciasCustos.limpar(idFornecedor, chave: op['chave']);
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return false;
      custoPendente.value = null;
      return true;
    } catch (e) {
      final definitivo = e is FinanceiroCallableException &&
          [
            'invalid-argument',
            'permission-denied',
            'failed-precondition',
            'not-found',
            'already-exists',
            'unauthenticated'
          ].contains(e.code);
      if (definitivo) {
        await _pendenciasCustos.limpar(idFornecedor, chave: op['chave']);
      }
      if (geracao == _geracao && uid == _usuarioAtual?.call()) {
        if (definitivo) custoPendente.value = null;
        erro.value = definitivo
            ? 'Custo recusado: $e'
            : 'Custo não confirmado; retome o mesmo envio. $e';
      }
      return false;
    } finally {
      if (geracao == _geracao) enviando.value = false;
    }
  }

  Future<bool> registrarRecebimento({
    required String idEvento,
    String? idOrcamento,
    required int valorCentavos,
    String tipo = 'recebimento',
    bool execucaoConfirmada = false,
    List<Map<String, dynamic>>? alocacoes,
    String? referenciaRecebimento,
  }) =>
      _enviarRecebimento({
        'idEvento': idEvento,
        'valorCentavos': valorCentavos,
        'tipo': tipo,
        'execucaoConfirmada': execucaoConfirmada,
        if (idOrcamento != null) 'idOrcamento': idOrcamento,
        if (alocacoes != null) 'alocacoes': alocacoes,
        if (referenciaRecebimento != null)
          'referenciaRecebimento': referenciaRecebimento,
      });

  Future<bool> retomarRecebimentoPendente() async {
    if (!autorizado) return false;
    final p = await _pendencias.ler(idFornecedor);
    if (p == null) return false;
    return _enviarRecebimento(Map<String, dynamic>.from(p['pedido'] as Map));
  }

  Future<bool> _reconciliarRecebimento(Map<String, dynamic> p) async {
    final raw = await _remote!.consultarOperacaoRecebimento(
        idFornecedor: idFornecedor,
        chaveIdempotencia: p['chave'] as String,
        pedido: Map<String, dynamic>.from(p['pedido'] as Map));
    if (raw['encontrado'] != true) return false;
    await _pendencias.limpar(idFornecedor, chave: p['chave'] as String);
    if (autorizado && recebimentoPendente.value?['chave'] == p['chave']) {
      recebimentoPendente.value = null;
    }
    return true;
  }

  String _pedidoCanonico(dynamic valor) {
    dynamic ordenar(dynamic v) {
      if (v is Map) {
        final chaves = v.keys.map((e) => e.toString()).toList()..sort();
        return {for (final k in chaves) k: ordenar(v[k])};
      }
      if (v is List) return v.map(ordenar).toList();
      return v;
    }

    return jsonEncode(ordenar(valor));
  }

  Future<bool> _enviarRecebimento(Map<String, dynamic> pedido) async {
    final remote = _remote;
    if (!autorizado || remote == null || enviando.value) return false;
    enviando.value = true;
    final g = _geracao, uid = _usuarioAtual?.call();
    final envio = ++_envioRecebimento;
    var registrando = false;
    Map<String, dynamic>? operacao;
    try {
      var pendente = await _pendencias.ler(idFornecedor);
      if (g != _geracao || uid != _usuarioAtual?.call()) return false;
      if (pendente != null) {
        recebimentoPendente.value = pendente;
        final igual =
            _pedidoCanonico(pendente['pedido']) == _pedidoCanonico(pedido);
        final conciliado = await _reconciliarRecebimento(pendente);
        if (!igual) {
          erro.value = conciliado
              ? 'Operação anterior confirmada. Revise e envie o novo lançamento.'
              : 'Existe operação com resultado desconhecido. Retome o recebimento pendente antes de mudar os dados.';
          return false;
        }
        if (conciliado) {
          if (g == _geracao && uid == _usuarioAtual?.call()) {
            await _consultarPlataforma(g, uid);
          }
          return true;
        }
      } else {
        pendente = {
          'chave': _uuid.v4(),
          'pedido': jsonDecode(jsonEncode(pedido))
        };
        await _pendencias.salvar(idFornecedor, pendente);
        recebimentoPendente.value = pendente;
      }
      if (g != _geracao || uid != _usuarioAtual?.call()) return false;
      operacao = pendente;
      registrando = true;
      final raw = await remote.registrarRecebimento(
        idFornecedor: idFornecedor,
        chaveIdempotencia: pendente['chave'] as String,
        idEvento: pedido['idEvento'] as String,
        idOrcamento: pedido['idOrcamento'] as String?,
        valorCentavos: pedido['valorCentavos'] as int,
        tipo: pedido['tipo'] as String,
        execucaoConfirmada: pedido['execucaoConfirmada'] == true,
        alocacoes: (pedido['alocacoes'] as List?)
            ?.map((a) => Map<String, dynamic>.from(a as Map))
            .toList(),
        referenciaRecebimento: pedido['referenciaRecebimento'] as String?,
      );
      if (raw['ok'] != true) {
        throw StateError('Resultado do lançamento desconhecido.');
      }
      await _pendencias.limpar(idFornecedor,
          chave: pendente['chave'] as String);
      if (uid == _usuarioAtual?.call() &&
          recebimentoPendente.value?['chave'] == pendente['chave']) {
        recebimentoPendente.value = null;
      }
      if (g != _geracao || uid != _usuarioAtual?.call()) return false;
      recebimentoPendente.value = null;
      await _consultarPlataforma(g, uid);
      return true;
    } catch (e) {
      if (g != _geracao || uid != _usuarioAtual?.call()) return false;
      if (registrando &&
          operacao != null &&
          e is FinanceiroCallableException &&
          [
            'invalid-argument',
            'permission-denied',
            'failed-precondition',
            'already-exists'
          ].contains(e.code)) {
        try {
          final resultado = await remote.consultarOperacaoRecebimento(
              idFornecedor: idFornecedor,
              chaveIdempotencia: operacao['chave'] as String,
              pedido: Map<String, dynamic>.from(operacao['pedido'] as Map));
          if (resultado['encontrado'] == false) {
            await _pendencias.limpar(idFornecedor,
                chave: operacao['chave'] as String);
            recebimentoPendente.value = null;
          }
        } catch (_) {/* Resultado não reconciliado permanece preservado. */}
      }
      erro.value =
          'Não foi possível confirmar o recebimento. A operação foi preservada para conciliação: $e';
      return false;
    } finally {
      if (envio == _envioRecebimento) enviando.value = false;
    }
  }

  void aoTrocarSessao() {
    nomesEventos.clear();
    _eventosConsultados = false;
    ++_geracao;
    custoPendente.value = null;
    ++_envioRecebimento;
    _reconsulta?.cancel();
    unawaited(_cancelar());
    recebimentoPendente.value = null;
    enviando.value = false;
    resumo.value = null;
    vendas.clear();
    custos.clear();
    movimentos.clear();
    recebimentos.clear();
    erro.value = '';
  }

  ResumoFinanceiroFornecedor _mapearResumoRemote(Map<String, dynamic> raw) {
    return ResumoFinanceiroFornecedor(
      idFornecedor: idFornecedor,
      idEvento: raw['idEvento']?.toString(),
      liquidoPrevisto: raw['liquidoPrevisto'] is num
          ? (raw['liquidoPrevisto'] as num).toDouble()
          : null,
      comissaoContratada: raw['comissaoContratada'] is num
          ? (raw['comissaoContratada'] as num).toDouble()
          : null,
      repasseAutorizado: raw['repasseAutorizado'] is num
          ? (raw['repasseAutorizado'] as num).toDouble()
          : null,
      contratado: _num(raw['contratado']),
      recebido: _num(raw['recebido']),
      aReceber: _num(raw['aReceber']),
      recebimentoNaoAlocado: _num(raw['recebimentoNaoAlocado']),
      creditoExcedente: _num(raw['creditoExcedente']),
      custoRealizado: _num(raw['custoRealizado']),
      custoRestantePrevisto: _num(raw['custoRestantePrevisto']),
      custoDiretoPrevisto: _num(raw['custoDiretoPrevisto']),
      outrasDespesasAusentes: raw['outrasDespesasAusentes'] != false,
      comissaoInformada: raw['comissaoDescontadaFornecedor'] is num
          ? (raw['comissaoDescontadaFornecedor'] as num).toDouble()
          : null,
      taxasInformadas: taxasInformadas.value,
      tributosInformados: tributosInformados.value,
      receitaRealizada: _num(raw['receitaRealizada']),
      adiantamentosCaixa: _num(raw['adiantamentosCaixa']),
      resultadoDiretoPrevisto: _num(raw['resultadoDiretoPrevisto']),
      resultadoDiretoRealizado: _num(raw['resultadoDiretoRealizado']),
      margemContribuicao: raw['margemContribuicao'] is num
          ? (raw['margemContribuicao'] as num).toDouble()
          : null,
      entradasCaixa: _num(raw['entradasCaixa']),
      saidasCaixa: _num(raw['saidasCaixa']),
      movimentoLiquido: _num(raw['movimentoLiquido']),
      saldoFinal: raw['saldoFinal'] is num
          ? (raw['saldoFinal'] as num).toDouble()
          : null,
      completo: raw['completo'] == true,
      formulaResultado: (raw['formula'] ?? '').toString(),
      alertas: _alertasDeResumoParcial(raw),
    );
  }

  List<AlertaFinanceiro> _alertasDeResumoParcial(Map<String, dynamic> raw) {
    if (raw['completo'] == true) return const [];
    final lista = <AlertaFinanceiro>[];
    if (_num(raw['repasseLegadoNaoConciliado']) +
            _num(raw['legadoCaixaNaoConciliado']) >
        0) {
      lista.add(const AlertaFinanceiro(
          tipo: TipoAlertaFinanceiro.consultaIncompleta,
          mensagem:
              'Há registro legado de caixa sem origem conciliada. Foi preservado e não somado novamente como entrada.'));
    }
    if (raw['comissaoDescontadaFornecedor'] == null &&
        comissaoInformada.value == null &&
        taxasInformadas.value == null &&
        tributosInformados.value == null) {
      lista.add(const AlertaFinanceiro(
        tipo: TipoAlertaFinanceiro.consultaIncompleta,
        mensagem:
            'Comissão, taxas ou tributos ainda não informados: resultado parcial.',
      ));
    }
    if (raw['outrasDespesasAusentes'] != false) {
      lista.add(const AlertaFinanceiro(
        tipo: TipoAlertaFinanceiro.consultaIncompleta,
        mensagem:
            'Outras despesas não informadas: ficam explícitas como ausentes.',
      ));
    }
    return lista;
  }

  List<VendaFornecedorFato> _mapearContratosRemote(Map<String, dynamic> raw) {
    final lista = raw['contratos'];
    if (lista is! List) return const [];
    return lista
        .whereType<Map>()
        .map((item) {
          final m = Map<String, dynamic>.from(item);
          return VendaFornecedorFato(
            id: (m['id'] ?? '').toString(),
            idEvento: (m['idEvento'] ?? m['id_evento'] ?? '').toString(),
            nomeServico: (m['nomeServico'] ?? m['nome_servico'])?.toString(),
            valorContratado:
                _num(m['valorContratado'] ?? m['valor_contratado']),
            liquidoPrevisto: m['liquidoPrevisto'] is num
                ? (m['liquidoPrevisto'] as num).toDouble()
                : null,
            comissao:
                m['comissao'] is num ? (m['comissao'] as num).toDouble() : null,
            repasseAutorizado: _num(m['repasseAutorizado']),
            recebimentoProprioDeclarado: _num(m['recebimentoProprioDeclarado']),
            revisao: m['revisao']?.toString(),
            recebidoConfirmado: _num(m['recebido'] ?? m['recebido_confirmado']),
            repasseConfirmado: _num(m['repasseConfirmado'] ?? m['recebido']),
            saldoContrato: m['saldoContrato'] is num
                ? (m['saldoContrato'] as num).toDouble()
                : null,
            situacao: (m['situacao'] ?? '').toString(),
            categoria: (m['nomeServico'] ?? m['nome_servico'])?.toString(),
          );
        })
        .where((v) => v.valorContratado > 0)
        .toList();
  }

  double _centavosReais(dynamic map) {
    if (map is Map && map['centavos'] is num) {
      return (map['centavos'] as num).toInt() / 100.0;
    }
    return 0;
  }

  double _num(dynamic v) => v is num && v.isFinite ? v.toDouble() : 0;

  Future<void> _cancelar() async {
    _reconsulta?.cancel();
    final antigas = List<StreamSubscription>.from(_subs);
    _subs.clear();
    await Future.wait(antigas.map((s) => s.cancel()));
  }

  @override
  void onClose() {
    aoTrocarSessao();
    super.onClose();
  }
}

/// Agrupamento de apresentação — não altera a origem dos alertas.
class AlertaAgrupadoFinanceiro {
  const AlertaAgrupadoFinanceiro({
    required this.tipo,
    required this.mensagem,
    required this.eventos,
    required this.quantidade,
  });

  final TipoAlertaFinanceiro tipo;
  final String mensagem;
  final List<String> eventos;
  final int quantidade;
}

List<AlertaAgrupadoFinanceiro> agruparAlertasFinanceiros(
  List<AlertaFinanceiro> alertas,
) {
  if (alertas.isEmpty) return const [];
  final mapa = <String, AlertaAgrupadoFinanceiro>{};
  for (final a in alertas) {
    final chave = '${a.tipo.name}|${a.mensagem}';
    final existente = mapa[chave];
    if (existente == null) {
      mapa[chave] = AlertaAgrupadoFinanceiro(
        tipo: a.tipo,
        mensagem: a.mensagem,
        eventos: [
          if (a.idEvento != null && a.idEvento!.trim().isNotEmpty)
            a.idEvento!.trim(),
        ],
        quantidade: 1,
      );
    } else {
      final evs = [...existente.eventos];
      final id = a.idEvento?.trim() ?? '';
      if (id.isNotEmpty && !evs.contains(id)) evs.add(id);
      mapa[chave] = AlertaAgrupadoFinanceiro(
        tipo: a.tipo,
        mensagem: a.mensagem,
        eventos: evs,
        quantidade: existente.quantidade + 1,
      );
    }
  }
  return mapa.values.toList();
}
