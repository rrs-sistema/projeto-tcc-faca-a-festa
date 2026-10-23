import 'dart:async';

import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/compromissos_evento_remote.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/services/previsao_financeira_gerente_service.dart';
import 'package:app_faca_festa/domain/services/simulacao_orcamento_evento_service.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';

enum EixoTemporalFinanceiro { mesEvento, mesPagamento }

/// Dashboard do responsável autorizado pelos eventos (dono id_usuario).
/// Sem hierarquia empresarial inventada.
class FinanceiroGerenteController extends GetxController {
  FinanceiroGerenteController({
    required EventoController eventoController,
    required CompromissosEventoRemote compromissosRemote,
    String? Function()? usuarioAtual,
    PrevisaoFinanceiraGerenteService? previsaoService,
  })  : _eventoController = eventoController,
        _compromissosRemote = compromissosRemote,
        _usuarioAtual = usuarioAtual,
        _previsaoService =
            previsaoService ?? const PrevisaoFinanceiraGerenteService();

  final EventoController _eventoController;
  final CompromissosEventoRemote _compromissosRemote;
  final String? Function()? _usuarioAtual;
  final PrevisaoFinanceiraGerenteService _previsaoService;

  final previsoes = <PrevisaoFinanceiraGerente>[].obs;
  final carregando = false.obs;
  final erro = ''.obs;
  final filtroEventoId = ''.obs;
  final filtroCategoria = ''.obs;
  final filtroEstadoComercial = ''.obs;
  final filtroBusca = ''.obs;
  final eixoTemporal = EixoTemporalFinanceiro.mesEvento.obs;
  final periodoInicio = Rxn<DateTime>();
  final periodoFim = Rxn<DateTime>();
  final vencimentoAte = Rxn<DateTime>();

  final detalheAtual = Rxn<PrevisaoFinanceiraGerente>();
  final linhasDetalhe = <LinhaDetalheFinanceiroGerente>[].obs;
  final simulacaoAtual = Rxn<ResultadoSimulacaoOrcamento>();
  final _simulacaoService = const SimulacaoOrcamentoEventoService();

  int _geracao = 0;
  Timer? _erroAdiado;
  final Map<String, StreamSubscription> _subs = {};
  final Map<String, List<Map<String, dynamic>>> _compromissosPorEvento = {};
  final Map<String, List<NecessidadeFinanceiraDescoberta>> _necessidades = {};

  List<Evento> get eventosAcessiveis {
    final uid = _usuarioAtual?.call();
    if (uid == null || uid.isEmpty) return const [];
    return _eventoController.eventosDoUsuario
        .where((e) => e.idUsuario == uid && e.ativo)
        .toList();
  }

  int get totalEventos => previsoesFiltradas.length;
  int get totalContratos =>
      previsoesFiltradas.fold(0, (s, p) => s + p.qtdContratos);
  /// Conta itens/compromissos nas previsões filtradas (não inventa outro agregado).
  int get totalItensServico =>
      previsoesFiltradas.fold(0, (s, p) => s + p.qtdLinhasServico);
  int get totalLinhasServico => totalItensServico;
  int get totalFornecedores {
    final set = <String>{};
    for (final p in previsoesFiltradas) {
      for (final d in p.detalhes) {
        final f = d.fornecedor?.trim();
        if (f != null && f.isNotEmpty) set.add(f);
      }
    }
    return set.length;
  }

  bool get temFiltrosAtivos =>
      filtroBusca.value.trim().isNotEmpty ||
      filtroEstadoComercial.value.isNotEmpty ||
      filtroCategoria.value.isNotEmpty ||
      filtroEventoId.value.isNotEmpty ||
      periodoInicio.value != null ||
      periodoFim.value != null ||
      vencimentoAte.value != null;

  /// Contadores só após consulta com dados ou vazio confirmado (não na falha sem lista).
  bool get mostrarContadores =>
      !carregando.value && (previsoes.isNotEmpty || erro.value.isEmpty);

  String get rotuloEixoTemporal {
    switch (eixoTemporal.value) {
      case EixoTemporalFinanceiro.mesEvento:
        return 'Data do evento';
      case EixoTemporalFinanceiro.mesPagamento:
        return 'Referência de pagamento';
    }
  }

  String get ajudaEixoTemporal {
    switch (eixoTemporal.value) {
      case EixoTemporalFinanceiro.mesEvento:
        return 'Recorte pela data do evento. Totais do evento permanecem completos.';
      case EixoTemporalFinanceiro.mesPagamento:
        return 'Seleciona eventos pela última data de pagamento conhecida. '
            'Totais do evento continuam completos — não é extrato mensal de pagamentos.';
    }
  }

  List<PrevisaoFinanceiraGerente> get previsoesFiltradas {
    final eixo = eixoTemporal.value;
    return previsoes.where((p) {
      if (filtroEventoId.value.isNotEmpty &&
          p.idEvento != filtroEventoId.value) {
        return false;
      }
      if (filtroBusca.value.trim().isNotEmpty) {
        final t = filtroBusca.value.trim().toLowerCase();
        if (!p.nomeEvento.toLowerCase().contains(t) &&
            !p.idEvento.toLowerCase().contains(t)) {
          return false;
        }
      }
      if (filtroEstadoComercial.value.isNotEmpty) {
        final estado = filtroEstadoComercial.value;
        final tem = p.detalhes.any((d) => d.estadoComercial == estado);
        if (!tem) return false;
      }
      if (filtroCategoria.value.isNotEmpty) {
        final cat = filtroCategoria.value.toLowerCase();
        final tem = p.detalhes
            .any((d) => (d.categoria ?? '').toLowerCase().contains(cat));
        if (!tem) return false;
      }
      final dataRef = eixo == EixoTemporalFinanceiro.mesEvento
          ? p.dataEvento
          : _maiorPagamento(p);
      if (!_noPeriodo(dataRef)) return false;
      if (vencimentoAte.value != null) {
        final ate = vencimentoAte.value!;
        final temVenc = p.detalhes.any((d) =>
            d.vencimento != null && !d.vencimento!.isAfter(ate) && d.saldo > 0);
        if (!temVenc) return false;
      }
      return true;
    }).toList();
  }

  void _limparErroConsulta() {
    _erroAdiado?.cancel();
    _erroAdiado = null;
    if (erro.value.isNotEmpty) erro.value = '';
  }

  /// Evita flash "erro → dados" quando o stream falha antes da carga pontual.
  void _agendarErroSeAindaVazio(int geracao) {
    _erroAdiado?.cancel();
    _erroAdiado = Timer(const Duration(milliseconds: 900), () {
      if (geracao != _geracao) return;
      if (carregando.value) return;
      if (previsoes.isNotEmpty) return;
      erro.value = 'Não foi possível atualizar o financeiro.';
    });
  }

  Future<void> iniciar() async {
    final uid = _usuarioAtual?.call();
    final geracao = ++_geracao;
    await _cancelarSubs();
    _erroAdiado?.cancel();
    _erroAdiado = null;
    previsoes.clear();
    detalheAtual.value = null;
    linhasDetalhe.clear();
    _compromissosPorEvento.clear();
    erro.value = '';
    if (uid == null || uid.isEmpty) {
      erro.value = 'Faça login para ver o financeiro dos seus eventos.';
      return;
    }
    carregando.value = true;
    final eventos = eventosAcessiveis;
    if (eventos.isEmpty) {
      carregando.value = false;
      return;
    }
    var falhasCargaPontual = 0;
    for (final evento in eventos) {
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
      _subs[evento.idEvento] = _compromissosRemote
          .observarCompromissosDoEvento(evento.idEvento)
          .listen((lista) {
        if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
        _compromissosPorEvento[evento.idEvento] = lista;
        _recalcularEvento(evento, geracao, uid);
        _limparErroConsulta();
        // Libera spinner cedo só quando já há algo para mostrar.
        if (previsoes.isNotEmpty) carregando.value = false;
      }, onError: (Object e) {
        if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
        // Durante o bootstrap a carga pontual ainda pode preencher a lista.
        // Com dados já na tela, erro pontual do stream não vira banner.
        if (carregando.value) return;
        if (previsoes.isNotEmpty) return;
        if (_compromissosPorEvento[evento.idEvento] != null) return;
        _agendarErroSeAindaVazio(geracao);
      });
      // Primeira carga pontual para tabela rápida.
      try {
        final lista = await _compromissosRemote
            .listarCompromissosDoEvento(evento.idEvento);
        if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
        _compromissosPorEvento[evento.idEvento] = lista;
        _recalcularEvento(evento, geracao, uid);
        _limparErroConsulta();
      } catch (_) {
        falhasCargaPontual++;
      }
    }
    if (geracao != _geracao) return;
    carregando.value = false;
    if (previsoes.isNotEmpty) {
      _limparErroConsulta();
    } else if (falhasCargaPontual == eventos.length) {
      _agendarErroSeAindaVazio(geracao);
    }
  }

  /// Injeta necessidades descobertas (ex.: calculadora) sem reescrever fatos realizados.
  void atualizarNecessidades(
    String idEvento,
    List<NecessidadeFinanceiraDescoberta> lista,
  ) {
    final uid = _usuarioAtual?.call();
    final geracao = _geracao;
    _necessidades[idEvento] = lista;
    Evento? evento;
    for (final e in eventosAcessiveis) {
      if (e.idEvento == idEvento) {
        evento = e;
        break;
      }
    }
    if (evento != null) _recalcularEvento(evento, geracao, uid);
  }

  void abrirDetalhe(String idEvento) {
    final uid = _usuarioAtual?.call();
    PrevisaoFinanceiraGerente? p;
    for (final e in previsoes) {
      if (e.idEvento == idEvento) {
        p = e;
        break;
      }
    }
    if (p == null || uid == null) {
      detalheAtual.value = null;
      linhasDetalhe.clear();
      return;
    }
    Evento? evento;
    for (final e in eventosAcessiveis) {
      if (e.idEvento == idEvento && e.idUsuario == uid) {
        evento = e;
        break;
      }
    }
    if (evento == null) {
      detalheAtual.value = null;
      linhasDetalhe.clear();
      erro.value = 'Sem autorização neste evento.';
      return;
    }
    detalheAtual.value = p;
    var linhas = List<LinhaDetalheFinanceiroGerente>.from(p.detalhes);
    if (filtroCategoria.value.isNotEmpty) {
      final cat = filtroCategoria.value.toLowerCase();
      linhas = linhas
          .where((d) => (d.categoria ?? '').toLowerCase().contains(cat))
          .toList();
    }
    if (filtroEstadoComercial.value.isNotEmpty) {
      linhas = linhas
          .where((d) => d.estadoComercial == filtroEstadoComercial.value)
          .toList();
    }
    linhasDetalhe.assignAll(linhas);
  }

  /// Simulação local: não altera contratos/limite. Alternativas não somadas.
  void simularCenariosEvento(String idEvento) {
    final p = detalheAtual.value;
    if (p == null || p.idEvento != idEvento) return;
    final limite = p.limiteConfirmado;
    if (limite == null) {
      simulacaoAtual.value = null;
      erro.value = 'Limite confirmado ausente — simulação parcial.';
      return;
    }
    final compromissos = _compromissosPorEvento[idEvento] ?? const [];
    final necessidades = _necessidades[idEvento] ?? const [];
    final alts = <String, List<AlternativaCobertura>>{};
    for (final n in necessidades) {
      if (n.eliminada || n.cobertaPorBuffet) continue;
      final preco = n.precoUnitario ?? n.custoEstimadoTotal;
      if (preco == null || !preco.isFinite || preco <= 0) continue;
      final centavos = (preco * 100).round();
      alts[n.id] = [
        AlternativaCobertura(
          id: '${n.id}-a1',
          idNecessidade: n.id,
          rotulo: 'Proposta vigente',
          precoCentavos: centavos,
          fonte: n.fonte,
          versaoFonte: '1',
        ),
      ];
    }
    simulacaoAtual.value = _simulacaoService.simular(
      limiteConfirmadoCentavos: (limite * 100).round(),
      compromissos: compromissos,
      necessidades: necessidades,
      alternativasPorNecessidade: alts,
      horizonte: p.eixoTemporal,
    );
  }

  void limparFiltros() {
    filtroEventoId.value = '';
    filtroCategoria.value = '';
    filtroEstadoComercial.value = '';
    filtroBusca.value = '';
    periodoInicio.value = null;
    periodoFim.value = null;
    vencimentoAte.value = null;
  }

  void _recalcularEvento(Evento evento, int geracao, String? uid) {
    if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
    if (evento.idUsuario != uid) return;
    final compromissos = _compromissosPorEvento[evento.idEvento] ?? const [];
    final necessidades = _necessidades[evento.idEvento] ?? const [];
    final reserva = _reservaDe(evento);
    final previsao = _previsaoService.calcular(
      idEvento: evento.idEvento,
      nomeEvento: evento.nomeEvento,
      dataEvento: evento.data,
      limiteConfirmado: evento.custoEstimado,
      reservaContingencia: reserva,
      compromissos: compromissos,
      necessidades: necessidades,
      eixoTemporal: eixoTemporal.value == EixoTemporalFinanceiro.mesPagamento
          ? 'mes_pagamento'
          : 'mes_evento',
    );
    final idx = previsoes.indexWhere((p) => p.idEvento == evento.idEvento);
    if (idx >= 0) {
      previsoes[idx] = previsao;
    } else {
      previsoes.add(previsao);
    }
    previsoes.refresh();
    if (detalheAtual.value?.idEvento == evento.idEvento) {
      abrirDetalhe(evento.idEvento);
    }
  }

  double _reservaDe(Evento evento) {
    // Campo opcional legado/novo no mapa do evento via extensão futura;
    // Evento tipado ainda não expõe — lê 0 até existir no modelo.
    return 0;
  }

  bool _noPeriodo(DateTime? data) {
    if (periodoInicio.value == null && periodoFim.value == null) return true;
    if (data == null) return false;
    final ini = periodoInicio.value;
    final fim = periodoFim.value;
    if (ini != null && data.isBefore(DateTime(ini.year, ini.month, ini.day))) {
      return false;
    }
    if (fim != null &&
        data.isAfter(DateTime(fim.year, fim.month, fim.day, 23, 59, 59))) {
      return false;
    }
    return true;
  }

  DateTime? _maiorPagamento(PrevisaoFinanceiraGerente p) {
    DateTime? maior;
    for (final d in p.detalhes) {
      if (d.pagoLiquido <= 0) continue;
      final v = d.vencimento ?? p.dataEvento;
      if (v == null) continue;
      if (maior == null || v.isAfter(maior)) maior = v;
    }
    return maior ?? p.dataEvento;
  }

  Future<void> _cancelarSubs() async {
    final antigas = _subs.values.toList();
    _subs.clear();
    await Future.wait(antigas.map((s) => s.cancel()));
  }

  @override
  void onClose() {
    ++_geracao;
    _erroAdiado?.cancel();
    unawaited(_cancelarSubs());
    previsoes.clear();
    detalheAtual.value = null;
    linhasDetalhe.clear();
    super.onClose();
  }

  /// Troca de sessão: invalida geração e limpa dados anteriores.
  void aoTrocarSessao() {
    ++_geracao;
    _erroAdiado?.cancel();
    unawaited(_cancelarSubs());
    previsoes.clear();
    detalheAtual.value = null;
    linhasDetalhe.clear();
    _compromissosPorEvento.clear();
    _necessidades.clear();
    erro.value = '';
  }
}
