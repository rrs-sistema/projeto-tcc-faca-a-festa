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
  })  : _db = firestore,
        _usuarioAtual = usuarioAtual,
        _remote = remote,
        _resumoService =
            resumoService ?? const ResumoFinanceiroFornecedorService();

  final FirebaseFirestore _db;
  final String idFornecedor;
  final String? Function()? _usuarioAtual;
  final FinanceiroFornecedorRemoteDatasource? _remote;
  final ResumoFinanceiroFornecedorService _resumoService;
  final _uuid = const Uuid();

  final resumo = Rxn<ResumoFinanceiroFornecedor>();
  /// Começa true para a 1ª frame não pintar "Sem resumo ainda" antes do iniciar().
  final carregando = true.obs;
  /// True enquanto a callable de resumo da plataforma ainda não respondeu.
  final aguardandoPlataforma = false.obs;
  /// Só libera empty state depois da 1ª tentativa de carga.
  final primeiraCargaConcluida = false.obs;
  final enviando = false.obs;
  final erro = ''.obs;

  /// Valores de plataforma ainda não confiáveis (evita mostrar R$ 0,00 / empty falso).
  bool get valoresEmCarga =>
      !primeiraCargaConcluida.value ||
      carregando.value ||
      aguardandoPlataforma.value;
  final filtroEventoId = ''.obs;
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
  final movimentos = <MovimentoCaixaFornecedor>[].obs;

  int _geracao = 0;
  final List<StreamSubscription> _subs = [];

  bool get autorizado {
    final uid = _usuarioAtual?.call();
    return uid != null && uid == idFornecedor;
  }

  /// IDs de evento já presentes nos fatos locais (sem fonte de nome autorizada).
  List<String> get eventosConhecidosIds {
    final ids = <String>{};
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
    final lista = ids.toList()..sort();
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
    if (!autorizado) {
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
          .timeout(const Duration(seconds: 12));
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
      resumo.value = _mapearResumoRemote(raw);
      vendas.assignAll(_mapearContratosRemote(raw));
      erro.value = '';
    } catch (_) {
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
      // Callable lenta/indisponível: mantém o que os listeners locais montarem.
      if (resumo.value == null) {
        erro.value =
            'Resumo da plataforma demorou. Mostrando dados locais disponíveis.';
      }
    } finally {
      if (geracao == _geracao) {
        aguardandoPlataforma.value = false;
        carregando.value = false;
        primeiraCargaConcluida.value = true;
      }
    }
  }

  void _observarPrivado(int geracao, String? uid) {
    final base = _db.collection('fornecedor').doc(idFornecedor);
    _subs.add(base.collection('custos_internos').snapshots().listen((snap) {
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
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
      // Recebimentos alimentam recalculo junto com orçamentos via remote;
      // localmente atualizamos movimentos de adiantamento.
      _recalcularLocal(geracao, uid);
    }));

    _subs.add(base.collection('movimentos_caixa').snapshots().listen((snap) {
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
      movimentos.assignAll(snap.docs.map((d) {
        final m = d.data();
        return MovimentoCaixaFornecedor(
          id: d.id,
          valor: _centavosReais(m['valor']),
          entrada: m['entrada'] == true,
          idEvento: m['id_evento']?.toString(),
          descricao: m['origem']?.toString(),
        );
      }));
      _recalcularLocal(geracao, uid);
    }));
  }

  void _recalcularLocal(int geracao, String? uid) {
    if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
    if (!autorizado) {
      resumo.value = null;
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
    final r = _resumoService.calcular(
      idFornecedor: idFornecedor,
      idEvento: filtroEventoId.value.isEmpty ? null : filtroEventoId.value,
      vendas: vendas,
      custos: filtradosCustos,
      movimentos: movimentos,
      saldoInicialInformado: saldoInicialInformado.value,
      comissaoInformada: comissaoInformada.value,
      taxasInformadas: taxasInformadas.value,
      tributosInformados: tributosInformados.value,
    );
    // Preserva contratado/recebido do remote se existir.
    final atual = resumo.value;
    if (atual != null && vendas.isEmpty) {
      resumo.value = ResumoFinanceiroFornecedor(
        idFornecedor: idFornecedor,
        idEvento: filtroEventoId.value.isEmpty ? null : filtroEventoId.value,
        contratado: atual.contratado,
        recebido: atual.recebido,
        aReceber: atual.aReceber,
        custoRealizado: r.custoRealizado,
        custoRestantePrevisto: r.custoRestantePrevisto,
        custoDiretoPrevisto: r.custoDiretoPrevisto,
        outrasDespesasInformadas: r.outrasDespesasInformadas,
        outrasDespesasAusentes: r.outrasDespesasAusentes,
        comissaoInformada: r.comissaoInformada,
        taxasInformadas: r.taxasInformadas,
        tributosInformados: r.tributosInformados,
        receitaRealizada: atual.receitaRealizada,
        adiantamentosCaixa: atual.adiantamentosCaixa,
        resultadoDiretoPrevisto: atual.contratado -
            r.custoDiretoPrevisto -
            (r.comissaoInformada ?? 0) -
            (r.taxasInformadas ?? 0) -
            (r.tributosInformados ?? 0) -
            r.outrasDespesasInformadas,
        resultadoDiretoRealizado: atual.receitaRealizada -
            r.custoRealizado -
            (r.comissaoInformada ?? 0) -
            (r.taxasInformadas ?? 0) -
            (r.tributosInformados ?? 0),
        margemContribuicao: atual.receitaRealizada > 0
            ? atual.receitaRealizada - r.custoRealizado
            : null,
        saldoInicialInformado: r.saldoInicialInformado,
        entradasCaixa: r.entradasCaixa + atual.recebido,
        saidasCaixa: r.saidasCaixa,
        saldoFinal: r.saldoInicialInformado != null
            ? r.saldoInicialInformado! +
                (r.entradasCaixa + atual.recebido - r.saidasCaixa)
            : null,
        movimentoLiquido: r.entradasCaixa + atual.recebido - r.saidasCaixa,
        contasVencidas: atual.contasVencidas,
        completo: atual.completo && r.completo,
        formulaResultado: r.formulaResultado,
        // Não concatenar: cada recálculo regenera o conjunto completo.
        alertas: r.alertas,
      );
    } else if (aguardandoPlataforma.value && vendas.isEmpty && atual == null) {
      // Não publica stub zerado antes da callable — a UI mostra skeleton.
      return;
    } else {
      resumo.value = r;
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
    final remoteCusto = _remote;
    if (!autorizado || remoteCusto == null) {
      erro.value = 'Sem autorização.';
      return false;
    }
    if (enviando.value) return false;
    enviando.value = true;
    final geracao = _geracao;
    final uid = _usuarioAtual?.call();
    try {
      await remoteCusto.registrarCusto(
        idFornecedor: idFornecedor,
        idEvento: idEvento,
        chaveIdempotencia: _uuid.v4(),
        valorCentavos: valorCentavos,
        tipo: tipo,
        origem: origem,
        previstoRestanteCentavos: previstoRestanteCentavos,
        desembolsoCentavos:
            origem == 'estoque_consumo' ? 0 : desembolsoCentavos,
        reutilizavel: reutilizavel,
        descricao: descricao,
      );
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return false;
      return true;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      if (geracao == _geracao) enviando.value = false;
    }
  }

  Future<bool> registrarRecebimento({
    required String idEvento,
    required int valorCentavos,
    String tipo = 'recebimento',
    bool execucaoConfirmada = false,
  }) async {
    final remoteRec = _remote;
    if (!autorizado || remoteRec == null) {
      erro.value = 'Sem autorização.';
      return false;
    }
    if (enviando.value) return false;
    enviando.value = true;
    final geracao = _geracao;
    final uid = _usuarioAtual?.call();
    try {
      await remoteRec.registrarRecebimento(
        idFornecedor: idFornecedor,
        idEvento: idEvento,
        chaveIdempotencia: _uuid.v4(),
        valorCentavos: valorCentavos,
        tipo: tipo,
        execucaoConfirmada: execucaoConfirmada,
      );
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return false;
      await iniciar();
      return true;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      if (geracao == _geracao) enviando.value = false;
    }
  }

  void aoTrocarSessao() {
    ++_geracao;
    unawaited(_cancelar());
    resumo.value = null;
    vendas.clear();
    custos.clear();
    movimentos.clear();
    erro.value = '';
  }

  ResumoFinanceiroFornecedor _mapearResumoRemote(Map<String, dynamic> raw) {
    return ResumoFinanceiroFornecedor(
      idFornecedor: idFornecedor,
      idEvento: raw['idEvento']?.toString(),
      contratado: _num(raw['contratado']),
      recebido: _num(raw['recebido']),
      aReceber: _num(raw['aReceber']),
      custoRealizado: _num(raw['custoRealizado']),
      custoRestantePrevisto: _num(raw['custoRestantePrevisto']),
      custoDiretoPrevisto: _num(raw['custoDiretoPrevisto']),
      outrasDespesasAusentes: raw['outrasDespesasAusentes'] != false,
      comissaoInformada: comissaoInformada.value,
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
    if (comissaoInformada.value == null &&
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
    return lista.whereType<Map>().map((item) {
      final m = Map<String, dynamic>.from(item);
      return VendaFornecedorFato(
        id: (m['id'] ?? '').toString(),
        idEvento: (m['idEvento'] ?? m['id_evento'] ?? '').toString(),
        nomeServico: (m['nomeServico'] ?? m['nome_servico'])?.toString(),
        valorContratado: _num(m['valorContratado'] ?? m['valor_contratado']),
        recebidoConfirmado: _num(m['recebido'] ?? m['recebido_confirmado']),
        situacao: (m['situacao'] ?? '').toString(),
        categoria: (m['nomeServico'] ?? m['nome_servico'])?.toString(),
      );
    }).where((v) => v.valorContratado > 0).toList();
  }

  double _centavosReais(dynamic map) {
    if (map is Map && map['centavos'] is num) {
      return (map['centavos'] as num).toInt() / 100.0;
    }
    return 0;
  }

  double _num(dynamic v) => v is num && v.isFinite ? v.toDouble() : 0;

  Future<void> _cancelar() async {
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
