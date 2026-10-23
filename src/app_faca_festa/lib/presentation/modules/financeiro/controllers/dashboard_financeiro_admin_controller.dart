import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/dashboard_financeiro_admin_remote.dart';
import 'package:app_faca_festa/domain/entities/financeiro/contratacao_identidade.dart';
import 'package:app_faca_festa/domain/entities/financeiro/dashboard_financeiro_admin.dart';
import 'package:app_faca_festa/domain/services/dashboard_financeiro_admin_service.dart';

typedef ConsultarDashboardAdminFn = Future<Map<String, dynamic>> Function({
  required String eixoTemporal,
  String? periodoInicio,
  String? periodoFim,
  String? idFornecedor,
  String? estado,
});

class DashboardFinanceiroAdminController extends GetxController {
  DashboardFinanceiroAdminController({
    this.remote,
    ConsultarDashboardAdminFn? consultarFn,
    String? Function()? usuarioAtual,
  })  : assert(remote != null || consultarFn != null,
            'Informe remote ou consultarFn'),
        _consultarFn = consultarFn,
        _usuarioAtual = usuarioAtual;

  final DashboardFinanceiroAdminRemote? remote;
  final ConsultarDashboardAdminFn? _consultarFn;
  final String? Function()? _usuarioAtual;

  final carregando = false.obs;
  final erro = ''.obs;
  /// Aviso não-bloqueante (ex.: fallback local enquanto a function não está no ar).
  final aviso = ''.obs;
  final sincronizado = false.obs;
  final filtrosPendentes = false.obs;
  final resumo = Rxn<Map<String, dynamic>>();
  final eixoTemporal = 'data_evento'.obs;
  final filtroFornecedor = ''.obs;
  final filtroEstado = ''.obs;
  final periodoInicio = ''.obs;
  final periodoFim = ''.obs;

  /// Snapshot dos filtros da última consulta bem-sucedida (exportação alinhada).
  String eixoAplicado = 'data_evento';
  String fornecedorAplicado = '';
  String estadoAplicado = '';
  String periodoInicioAplicado = '';
  String periodoFimAplicado = '';

  int _geracao = 0;

  void marcarFiltroAlterado() {
    filtrosPendentes.value = eixoTemporal.value != eixoAplicado ||
        filtroFornecedor.value != fornecedorAplicado ||
        filtroEstado.value != estadoAplicado ||
        periodoInicio.value != periodoInicioAplicado ||
        periodoFim.value != periodoFimAplicado;
  }

  void limparFiltros() {
    eixoTemporal.value = 'data_evento';
    filtroFornecedor.value = '';
    filtroEstado.value = '';
    periodoInicio.value = '';
    periodoFim.value = '';
    marcarFiltroAlterado();
  }

  /// Contratações identificadas do último resumo (Prompt 01 — mediação).
  List<LinhaContratacaoAdmin> get linhasContratacao {
    final r = resumo.value;
    if (r == null) return const [];
    final raw = r['linhasContratacao'] ?? r['linhas_contratacao'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => LinhaContratacaoAdmin.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  int get qtdIdentidadeIncompleta {
    final r = resumo.value;
    if (r == null) return 0;
    final n = r['qtdIdentidadeIncompleta'] ?? r['qtd_identidade_incompleta'];
    if (n is num) return n.toInt();
    return linhasContratacao.where((c) => c.identidadeIncompleta).length;
  }

  bool get consultaTruncada {
    final r = resumo.value;
    if (r == null) return false;
    final p = r['paginacao'];
    if (p is Map && p['truncado'] == true) return true;
    final cons = r['consistencia'];
    return cons is Map && cons['truncado'] == true;
  }

  @override
  void onClose() {
    _geracao++;
    super.onClose();
  }

  void aoTrocarSessao() => _geracao++;

  Future<void> carregar() async {
    final geracao = ++_geracao;
    final uid = _usuarioAtual?.call();
    erro.value = '';
    aviso.value = '';
    carregando.value = true;
    sincronizado.value = false;
    try {
      final fn = _consultarFn ?? remote!.consultar;
      final raw = await fn(
        eixoTemporal: eixoTemporal.value,
        periodoInicio: periodoInicio.value.isEmpty ? null : periodoInicio.value,
        periodoFim: periodoFim.value.isEmpty ? null : periodoFim.value,
        idFornecedor:
            filtroFornecedor.value.isEmpty ? null : filtroFornecedor.value,
        estado: filtroEstado.value.isEmpty ? null : filtroEstado.value,
      );
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
      resumo.value = raw;
      final origem = (raw['origem'] ?? '').toString();
      final avisoRaw = (raw['aviso'] ?? '').toString().trim();
      if (origem == 'fallback_local') {
        // Dados úteis na tela; não tratar como falha dura.
        sincronizado.value = true;
        aviso.value = avisoRaw.isNotEmpty
            ? avisoRaw
            : 'Síntese local (function financeira indisponível neste ambiente).';
        erro.value = '';
      } else {
        sincronizado.value = true;
        aviso.value = avisoRaw;
      }
      eixoAplicado = eixoTemporal.value;
      fornecedorAplicado = filtroFornecedor.value;
      estadoAplicado = filtroEstado.value;
      periodoInicioAplicado = periodoInicio.value;
      periodoFimAplicado = periodoFim.value;
      filtrosPendentes.value = false;
    } catch (e) {
      if (geracao != _geracao) return;
      erro.value = _mensagemErro(e);
      sincronizado.value = false;
      aviso.value = '';
    } finally {
      if (geracao == _geracao) carregando.value = false;
    }
  }

  static String _mensagemErro(Object e) {
    final raw = e.toString();
    if (raw.contains('404') ||
        raw.toLowerCase().contains('not-found') ||
        raw.contains('HTML')) {
      return 'Serviço financeiro indisponível (function não publicada neste ambiente). '
          'Tente novamente após o deploy ou use a síntese local quando disponível.';
    }
    return raw;
  }

  /// Exportação CSV com os mesmos filtros da consulta atual.
  String exportarCsv() {
    final r = resumo.value;
    if (r == null) return '';
    final buf = StringBuffer();
    buf.writeln(
      'id_evento;data;status;servicos;contratos;contratado_centavos;pago_centavos;saldo_centavos;previsao_centavos;comissao_centavos',
    );
    final linhas = r['linhasEvento'] ?? r['linhas_evento'];
    if (linhas is List) {
      for (final raw in linhas) {
        final l = Map<String, dynamic>.from(raw as Map);
        buf.writeln([
          l['id_evento'] ?? l['idEvento'] ?? '',
          l['data_evento'] ?? l['dataEvento'] ?? '',
          l['status'] ?? '',
          l['qtd_servicos'] ?? l['qtdServicos'] ?? '',
          l['qtd_contratos'] ?? l['qtdContratos'] ?? '',
          l['contratado_centavos'] ?? l['contratadoCentavos'] ?? '',
          l['pago_centavos'] ?? l['pagoCentavos'] ?? '',
          l['saldo_centavos'] ?? l['saldoCentavos'] ?? '',
          l['previsao_disponivel_centavos'] ??
              l['previsaoDisponivelCentavos'] ??
              '',
          l['comissao_centavos'] ?? l['comissaoCentavos'] ?? '',
        ].join(';'));
      }
    }
    return buf.toString();
  }

  /// Agregação local determinística (testes / offline sintético).
  DashboardFinanceiroAdmin agregarLocal({
    required List<FatoComercialAdmin> fatos,
    List<FatoComissaoAdmin> comissoes = const [],
    bool politicaAtiva = false,
  }) {
    return DashboardFinanceiroAdminService.agregar(
      fatos: fatos,
      comissoes: comissoes,
      politicaComissaoAtiva: politicaAtiva,
      eixoTemporal: eixoTemporal.value,
    );
  }
}
