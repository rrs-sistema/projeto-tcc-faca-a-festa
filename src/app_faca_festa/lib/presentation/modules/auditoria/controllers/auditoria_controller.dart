import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:app_faca_festa/data/models/auditoria/auditoria_catalogo.dart';
import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_auditoria.dart';

class AuditoriaController extends GetxController {
  AuditoriaController({
    required GerenciarAuditoria gerenciarAuditoria,
    required this.escopoAdmin,
    this.idFornecedor,
  }) : _gerenciarAuditoria = gerenciarAuditoria;

  final GerenciarAuditoria _gerenciarAuditoria;
  final bool escopoAdmin;
  final String? idFornecedor;

  final eventos = <AuditoriaEvento>[].obs;
  final busca = ''.obs;
  final atorFiltro = ''.obs;
  final entidadeFiltro = ''.obs;
  final vinculoFiltro = ''.obs;
  final areaFiltro = ''.obs;
  final acaoFiltro = ''.obs;
  final origemFiltro = ''.obs;
  final nivelFiltro = ''.obs;
  final periodoFiltro = ''.obs;
  final apenasCriticos = false.obs;
  final dashboardExpandido = false.obs;
  final limite = 150.obs;
  final carregando = false.obs;
  final carregandoMais = false.obs;
  final temMais = false.obs;
  final erro = ''.obs;
  DateTime? _proximoCursorCriadoEm;

  List<AuditoriaEvento> get visiveis {
    final termo = busca.value.trim().toLowerCase();
    final ator = atorFiltro.value.trim().toLowerCase();
    final entidade = entidadeFiltro.value.trim().toLowerCase();
    final vinculo = vinculoFiltro.value.trim().toLowerCase();
    final area = areaFiltro.value;
    final acao = acaoFiltro.value;
    final origem = origemFiltro.value;
    final nivel = nivelFiltro.value;
    final intervalo = _intervaloPeriodo(periodoFiltro.value);

    return eventos.where((evento) {
      if (area.isNotEmpty && evento.area != area) return false;
      if (acao.isNotEmpty && evento.acao != acao) return false;
      if (origem.isNotEmpty && _origemEvento(evento) != origem) return false;
      if (nivel.isNotEmpty && evento.nivel != nivel) return false;
      if (apenasCriticos.value && !_ehCritico(evento)) return false;
      if (!_ocorreuNoIntervalo(evento, intervalo)) return false;
      if (ator.isNotEmpty && !_contemAtor(evento, ator)) return false;
      if (entidade.isNotEmpty && !_contemEntidade(evento, entidade)) {
        return false;
      }
      if (vinculo.isNotEmpty && !_contemVinculo(evento, vinculo)) {
        return false;
      }
      if (termo.isEmpty) return true;
      final info = infoAcaoAuditoria(evento.acao);
      final blob = [
        info.titulo,
        evento.resumo,
        evento.entidadeNome ?? '',
        evento.entidadeTipo ?? '',
        evento.entidadeId ?? '',
        evento.idFornecedor ?? '',
        evento.idEvento ?? '',
        evento.idServico ?? '',
        evento.idCotacao ?? '',
        evento.idOrcamento ?? '',
        evento.atorUid ?? '',
        evento.atorNome ?? '',
        evento.atorEmail ?? '',
        evento.atorTipo ?? '',
        evento.atorAuthType ?? '',
        evento.acao,
        evento.area,
        evento.nivel,
        evento.origem ?? '',
        evento.operacao ?? '',
        evento.documentPath ?? '',
        evento.sourceEventId ?? '',
        evento.algoritmoHash ?? '',
        evento.hashIntegridade ?? '',
        evento.rota ?? '',
        evento.plataforma ?? '',
        _labelOrigem(evento),
      ].join(' ').toLowerCase();
      return blob.contains(termo);
    }).toList();
  }

  int get totalEventos => eventos.length;
  int get totalVisiveis => visiveis.length;
  int get totalHoje => eventos.where((e) => e.ocorreuHoje).length;
  int get totalUltimas24h => eventos.where((e) {
        final data = e.criadoEm;
        if (data == null) return false;
        return data.isAfter(DateTime.now().subtract(const Duration(hours: 24)));
      }).length;
  int get totalUltimos7d => eventos.where((e) {
        final data = e.criadoEm;
        if (data == null) return false;
        return data.isAfter(DateTime.now().subtract(const Duration(days: 7)));
      }).length;
  int get totalUltimos15d => eventos.where((e) {
        final data = e.criadoEm;
        if (data == null) return false;
        return data.isAfter(DateTime.now().subtract(const Duration(days: 15)));
      }).length;
  int get totalUltimos30d => eventos.where((e) {
        final data = e.criadoEm;
        if (data == null) return false;
        return data.isAfter(DateTime.now().subtract(const Duration(days: 30)));
      }).length;
  int get totalAuditados =>
      eventos.where((e) => _origemEvento(e) == 'audit').length;
  int get totalSnapshots =>
      eventos.where((e) => _origemEvento(e) == 'snapshot').length;
  int get totalCriticos => eventos.where(_ehCritico).length;
  int get totalAlertas => eventos.where((e) => e.nivel == 'WARN').length;
  int get totalFalhasAcesso =>
      eventos.where((e) => e.acao == 'LOGIN_FALHOU').length;
  int get totalAlteracoesAdministrativas =>
      eventos.where(_ehAlteracaoAdministrativa).length;
  int get totalFornecedoresAprovados =>
      eventos.where((e) => e.acao == 'FORNECEDOR_APROVADO').length;
  int get totalFornecedoresComAtencao =>
      eventos.where(_ehMovimentoFornecedorComAtencao).length;
  int get totalFluxoComercial =>
      eventos.where((e) => e.area == 'COTACAO' || e.area == 'ORCAMENTO').length;
  int get totalEventosComDiff =>
      eventos.where((e) => e.mudancas.isNotEmpty).length;
  int get totalAuditadosSemHash => eventos.where((e) {
        if (_origemEvento(e) == 'snapshot') return false;
        return (e.hashIntegridade ?? '').trim().isEmpty;
      }).length;
  double get coberturaAuditoria {
    if (eventos.isEmpty) return 0;
    return totalAuditados / eventos.length;
  }

  List<MapEntry<String, String>> get areasDisponiveis {
    final usadas = eventos.map((e) => e.area).toSet();
    final entradas = <MapEntry<String, String>>[];
    for (final area in usadas) {
      entradas.add(MapEntry(area, areasAuditoriaLabels[area] ?? area));
    }
    entradas.sort((a, b) => a.value.compareTo(b.value));
    return entradas;
  }

  List<MapEntry<String, String>> get acoesDisponiveis {
    final usadas = eventos.map((e) => e.acao).toSet();
    final entradas = <MapEntry<String, String>>[];
    for (final acao in usadas) {
      entradas.add(MapEntry(acao, infoAcaoAuditoria(acao).titulo));
    }
    entradas.sort((a, b) => a.value.compareTo(b.value));
    return entradas;
  }

  List<MapEntry<String, String>> get origensDisponiveis {
    final usadas = eventos.map(_origemEvento).toSet();
    final entradas = <MapEntry<String, String>>[];
    for (final origem in usadas) {
      entradas.add(MapEntry(origem, _labelOrigemCodigo(origem)));
    }
    entradas.sort((a, b) => a.value.compareTo(b.value));
    return entradas;
  }

  List<MapEntry<String, String>> get niveisDisponiveis {
    final usadas =
        eventos.map((e) => e.nivel).where((e) => e.isNotEmpty).toSet();
    final entradas = <MapEntry<String, String>>[];
    for (final nivel in usadas) {
      entradas.add(MapEntry(nivel, _labelNivel(nivel)));
    }
    entradas.sort((a, b) => a.value.compareTo(b.value));
    return entradas;
  }

  List<MapEntry<String, int>> get distribuicaoPorArea {
    final contagem = <String, int>{};
    for (final evento in eventos) {
      final label = areasAuditoriaLabels[evento.area] ?? evento.area;
      contagem[label] = (contagem[label] ?? 0) + 1;
    }
    final entradas = contagem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entradas;
  }

  List<MapEntry<String, int>> get distribuicaoPorNivel {
    final contagem = <String, int>{};
    for (final evento in eventos) {
      final label = _labelNivel(evento.nivel);
      contagem[label] = (contagem[label] ?? 0) + 1;
    }
    final entradas = contagem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entradas;
  }

  List<MapEntry<String, int>> get distribuicaoPorOrigem {
    final contagem = <String, int>{};
    for (final evento in eventos) {
      final label = _labelOrigem(evento);
      contagem[label] = (contagem[label] ?? 0) + 1;
    }
    final entradas = contagem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entradas;
  }

  List<MapEntry<String, int>> get principaisAcoes {
    final contagem = <String, int>{};
    for (final evento in eventos) {
      final label = infoAcaoAuditoria(evento.acao).titulo;
      contagem[label] = (contagem[label] ?? 0) + 1;
    }
    final entradas = contagem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entradas.take(8).toList();
  }

  List<MapEntry<String, int>> get principaisAtores {
    final contagem = <String, int>{};
    for (final evento in eventos) {
      final ator = _labelAtorPainel(evento);
      if (ator.isEmpty) continue;
      contagem[ator] = (contagem[ator] ?? 0) + 1;
    }
    final entradas = contagem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entradas.take(5).toList();
  }

  List<MapEntry<String, int>> get atividadeUltimos7Dias {
    return _atividadeUltimosDias(7);
  }

  List<MapEntry<String, int>> get atividadeUltimos15Dias {
    return _atividadeUltimosDias(15);
  }

  List<MapEntry<String, int>> _atividadeUltimosDias(int totalDias) {
    final hoje = DateTime.now();
    final dias = <String, int>{};
    for (var offset = totalDias - 1; offset >= 0; offset--) {
      final dia = DateTime(hoje.year, hoje.month, hoje.day)
          .subtract(Duration(days: offset));
      dias[_chaveDia(dia)] = 0;
    }

    for (final evento in eventos) {
      final data = evento.criadoEm;
      if (data == null) continue;
      final chave = _chaveDia(data);
      if (!dias.containsKey(chave)) continue;
      dias[chave] = (dias[chave] ?? 0) + 1;
    }

    return dias.entries.toList();
  }

  List<MapEntry<String, String>> get periodosDisponiveis {
    return const [
      MapEntry('24h', 'Últimas 24h'),
      MapEntry('7d', 'Últimos 7 dias'),
      MapEntry('30d', 'Últimos 30 dias'),
      MapEntry('90d', 'Últimos 90 dias'),
      MapEntry('', 'Todo o histórico'),
    ];
  }

  String get resumoFiltrosAplicados {
    final filtros = <String>[];
    if (busca.value.trim().isNotEmpty) {
      filtros.add('busca: ${busca.value.trim()}');
    }
    if (atorFiltro.value.trim().isNotEmpty) {
      filtros.add('ator: ${atorFiltro.value.trim()}');
    }
    if (entidadeFiltro.value.trim().isNotEmpty) {
      filtros.add('entidade: ${entidadeFiltro.value.trim()}');
    }
    if (vinculoFiltro.value.trim().isNotEmpty) {
      filtros.add('vínculo: ${vinculoFiltro.value.trim()}');
    }
    if (areaFiltro.value.isNotEmpty) {
      filtros.add('área: ${_labelArea(areaFiltro.value)}');
    }
    if (acaoFiltro.value.isNotEmpty) {
      filtros.add('ação: ${infoAcaoAuditoria(acaoFiltro.value).titulo}');
    }
    if (origemFiltro.value.isNotEmpty) {
      filtros.add('origem: ${_labelOrigemCodigo(origemFiltro.value)}');
    }
    if (nivelFiltro.value.isNotEmpty) {
      filtros.add('severidade: ${_labelNivel(nivelFiltro.value)}');
    }
    if (periodoFiltro.value.isNotEmpty) {
      filtros.add('período: ${_labelPeriodo(periodoFiltro.value)}');
    }
    if (apenasCriticos.value) {
      filtros.add('apenas críticos');
    }
    return filtros.isEmpty ? 'Sem filtros aplicados' : filtros.join(' | ');
  }

  Future<void> carregar() async {
    try {
      carregando.value = true;
      temMais.value = false;
      _proximoCursorCriadoEm = null;
      erro.value = '';
      final pagina = await _gerenciarAuditoria.listarPagina(
        _consulta(incluirSnapshots: true),
      );
      eventos.value = pagina.eventos;
      temMais.value = pagina.temMais;
      _proximoCursorCriadoEm = pagina.proximoCursorCriadoEm;
    } catch (e) {
      erro.value = 'Não foi possível carregar o histórico de auditoria.';
    } finally {
      carregando.value = false;
    }
  }

  Future<void> carregarMais() async {
    if (carregando.value || carregandoMais.value || !temMais.value) return;
    final cursor = _proximoCursorCriadoEm;
    if (cursor == null) {
      temMais.value = false;
      return;
    }

    try {
      carregandoMais.value = true;
      erro.value = '';
      final pagina = await _gerenciarAuditoria.listarPagina(
        _consulta(cursor: cursor, incluirSnapshots: false),
      );
      final idsAtuais = eventos.map((e) => e.id).toSet();
      eventos.addAll(pagina.eventos.where((e) => !idsAtuais.contains(e.id)));
      temMais.value = pagina.temMais;
      _proximoCursorCriadoEm = pagina.proximoCursorCriadoEm;
    } catch (e) {
      erro.value = 'Não foi possível carregar mais eventos de auditoria.';
    } finally {
      carregandoMais.value = false;
    }
  }

  Future<void> limparFiltros() async {
    busca.value = '';
    atorFiltro.value = '';
    entidadeFiltro.value = '';
    vinculoFiltro.value = '';
    areaFiltro.value = '';
    acaoFiltro.value = '';
    origemFiltro.value = '';
    nivelFiltro.value = '';
    periodoFiltro.value = '';
    apenasCriticos.value = false;
    await carregar();
  }

  void alternarApenasCriticos(bool value) {
    apenasCriticos.value = value;
  }

  void alternarDashboard() {
    dashboardExpandido.value = !dashboardExpandido.value;
  }

  Future<void> alterarLimite(int novoLimite) async {
    if (limite.value == novoLimite) return;
    limite.value = novoLimite;
    await carregar();
  }

  Future<void> alterarPeriodo(String periodo) async {
    if (periodoFiltro.value == periodo) return;
    periodoFiltro.value = periodo;
    await carregar();
  }

  AuditoriaConsulta _consulta({
    DateTime? cursor,
    required bool incluirSnapshots,
  }) {
    final intervalo = _intervaloPeriodo(periodoFiltro.value);
    final filtrosServidor = _filtrosServidorAdministrativos();
    return AuditoriaConsulta(
      escopoAdmin: escopoAdmin,
      idFornecedor: idFornecedor,
      area: filtrosServidor.area,
      acao: filtrosServidor.acao,
      origem: filtrosServidor.origem,
      nivel: filtrosServidor.nivel,
      criadoDe: intervalo?.inicio,
      criadoAte: intervalo?.fim,
      cursorCriadoEm: cursor,
      incluirSnapshots: incluirSnapshots,
      limite: limite.value,
    );
  }

  _AuditoriaFiltrosServidor _filtrosServidorAdministrativos() {
    if (!escopoAdmin) return const _AuditoriaFiltrosServidor();

    final filtros = <String, String>{
      if (areaFiltro.value.isNotEmpty) 'area': areaFiltro.value,
      if (acaoFiltro.value.isNotEmpty) 'acao': acaoFiltro.value,
      if (origemFiltro.value.isNotEmpty) 'origem': origemFiltro.value,
      if (nivelFiltro.value.isNotEmpty) 'nivel': nivelFiltro.value,
    };

    if (filtros.length != 1) return const _AuditoriaFiltrosServidor();

    return _AuditoriaFiltrosServidor(
      area: filtros['area'],
      acao: filtros['acao'],
      origem: filtros['origem'],
      nivel: filtros['nivel'],
    );
  }

  String exportarCsvVisivel() {
    final linhas = <List<String>>[
      [
        'id',
        'origem',
        'acao',
        'area',
        'nivel',
        'resumo',
        'entidade_tipo',
        'entidade_id',
        'entidade_nome',
        'ator_uid',
        'ator_nome',
        'ator_email',
        'ator_tipo',
        'auth',
        'id_fornecedor',
        'id_evento',
        'id_servico',
        'id_cotacao',
        'id_orcamento',
        'operacao',
        'documento',
        'source_event_id',
        'algoritmo_hash',
        'hash_integridade',
        'rota',
        'plataforma',
        'criado_em',
        'mudancas',
      ],
      for (final evento in visiveis)
        [
          evento.id,
          _labelOrigem(evento),
          evento.acao,
          evento.area,
          evento.nivel,
          evento.resumo,
          evento.entidadeTipo ?? '',
          evento.entidadeId ?? '',
          evento.entidadeNome ?? '',
          evento.atorUid ?? '',
          evento.atorNome ?? '',
          evento.atorEmail ?? '',
          evento.atorTipo ?? '',
          evento.atorAuthType ?? '',
          evento.idFornecedor ?? '',
          evento.idEvento ?? '',
          evento.idServico ?? '',
          evento.idCotacao ?? '',
          evento.idOrcamento ?? '',
          evento.operacao ?? '',
          evento.documentPath ?? '',
          evento.sourceEventId ?? '',
          evento.algoritmoHash ?? '',
          evento.hashIntegridade ?? '',
          evento.rota ?? '',
          evento.plataforma ?? '',
          evento.criadoEm?.toIso8601String() ?? '',
          evento.mudancas
              .map((m) => '${m.campo}: ${m.de} -> ${m.para}')
              .join(' | '),
        ],
    ];

    return linhas.map((linha) => linha.map(_csv).join(',')).join('\n');
  }

  Future<Uint8List> exportarPdfVisivel({
    String titulo = 'Auditoria da plataforma',
  }) async {
    final documento = pw.Document();
    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    );
    final geradoEm = DateTime.now();
    final linhas = visiveis.take(300).toList();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (context) => [
          pw.Text(
            titulo,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Gerado em ${geradoEm.toIso8601String()} | ${linhas.length} registros visíveis',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            resumoFiltrosAplicados,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(4),
            headers: const [
              'Data',
              'Origem',
              'Ação',
              'Área',
              'Nível',
              'Ator',
              'Entidade',
              'Documento',
              'Evento origem',
              'Hash',
              'Resumo',
            ],
            data: [
              for (final evento in linhas)
                [
                  evento.criadoEm?.toIso8601String() ?? '-',
                  _labelOrigem(evento),
                  evento.acao,
                  evento.area,
                  evento.nivel,
                  _atorCsv(evento),
                  [
                    evento.entidadeTipo,
                    evento.entidadeNome,
                    evento.entidadeId,
                  ].where((e) => (e ?? '').trim().isNotEmpty).join(' | '),
                  evento.documentPath ?? '-',
                  _curto(evento.sourceEventId),
                  _curto(evento.hashIntegridade),
                  evento.resumo,
                ],
            ],
          ),
          if (visiveis.length > linhas.length) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Exportação PDF limitada aos primeiros ${linhas.length} registros visíveis. Use CSV para extração completa.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ],
      ),
    );

    return documento.save();
  }

  static String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static String _atorCsv(AuditoriaEvento evento) {
    return [
      evento.atorNome,
      evento.atorEmail,
      evento.atorUid,
      evento.atorTipo,
    ].where((e) => (e ?? '').trim().isNotEmpty).join(' | ');
  }

  static String _curto(String? value, [int max = 16]) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty) return '-';
    if (texto.length <= max) return texto;
    return '${texto.substring(0, max)}...';
  }

  static _AuditoriaIntervalo? _intervaloPeriodo(String periodo) {
    final agora = DateTime.now();
    switch (periodo) {
      case '24h':
        return _AuditoriaIntervalo(
            agora.subtract(const Duration(hours: 24)), agora);
      case '7d':
        return _AuditoriaIntervalo(
            agora.subtract(const Duration(days: 7)), agora);
      case '30d':
        return _AuditoriaIntervalo(
            agora.subtract(const Duration(days: 30)), agora);
      case '90d':
        return _AuditoriaIntervalo(
            agora.subtract(const Duration(days: 90)), agora);
      default:
        return null;
    }
  }

  static bool _ocorreuNoIntervalo(
    AuditoriaEvento evento,
    _AuditoriaIntervalo? intervalo,
  ) {
    if (intervalo == null) return true;
    final data = evento.criadoEm;
    if (data == null) return false;
    return !data.isBefore(intervalo.inicio) && !data.isAfter(intervalo.fim);
  }

  static String _origemEvento(AuditoriaEvento evento) {
    final origem = (evento.origem ?? '').trim();
    if (origem == 'snapshot') return 'snapshot';
    return 'audit';
  }

  static String _labelOrigem(AuditoriaEvento evento) {
    return _labelOrigemCodigo(_origemEvento(evento));
  }

  static String _labelOrigemCodigo(String origem) {
    switch (origem) {
      case 'snapshot':
        return 'Registro do sistema';
      default:
        return 'Evento auditado';
    }
  }

  static String _labelNivel(String nivel) {
    switch (nivel) {
      case 'CRITICAL':
        return 'Crítico';
      case 'ERROR':
        return 'Erro';
      case 'WARN':
        return 'Atenção';
      case 'INFO':
        return 'Informativo';
      default:
        return nivel;
    }
  }

  static String _labelArea(String area) {
    return areasAuditoriaLabels[area] ?? area;
  }

  static String _labelPeriodo(String periodo) {
    switch (periodo) {
      case '24h':
        return 'Últimas 24h';
      case '7d':
        return 'Últimos 7 dias';
      case '30d':
        return 'Últimos 30 dias';
      case '90d':
        return 'Últimos 90 dias';
      default:
        return 'Todo o histórico';
    }
  }

  static bool _ehCritico(AuditoriaEvento evento) {
    return evento.nivel == 'CRITICAL' || evento.nivel == 'ERROR';
  }

  static bool _ehAlteracaoAdministrativa(AuditoriaEvento evento) {
    if (evento.atorTipo == 'A') return true;
    if (evento.area == 'USUARIO') return true;
    return const {
      'FORNECEDOR_APROVADO',
      'FORNECEDOR_REPROVADO',
      'FORNECEDOR_ATIVADO',
      'FORNECEDOR_DESATIVADO',
      'SERVICO_CATALOGO_CRIADO',
      'SERVICO_CATALOGO_ATUALIZADO',
      'SERVICO_CATALOGO_EXCLUIDO',
      'CATEGORIA_CRIADA',
      'CATEGORIA_ATUALIZADA',
      'CATEGORIA_EXCLUIDA',
      'SUBCATEGORIA_CRIADA',
      'SUBCATEGORIA_ATUALIZADA',
      'SUBCATEGORIA_EXCLUIDA',
    }.contains(evento.acao);
  }

  static bool _ehMovimentoFornecedorComAtencao(AuditoriaEvento evento) {
    return const {
      'FORNECEDOR_REPROVADO',
      'FORNECEDOR_DESATIVADO',
      'FORNECEDOR_EXCLUIDO',
    }.contains(evento.acao);
  }

  static String _labelAtorPainel(AuditoriaEvento evento) {
    final nome = (evento.atorNome ?? '').trim();
    if (nome.isNotEmpty) return nome;
    final email = (evento.atorEmail ?? '').trim();
    if (email.isNotEmpty) return email;
    final uid = (evento.atorUid ?? '').trim();
    if (uid.isNotEmpty) return uid;
    return evento.atorTipo == 'S' ? 'Sistema' : '';
  }

  static String _chaveDia(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes';
  }

  static bool _contemAtor(AuditoriaEvento evento, String termo) {
    return _blob([
      evento.atorUid,
      evento.atorNome,
      evento.atorEmail,
      evento.atorTipo,
      evento.atorAuthType,
    ]).contains(termo);
  }

  static bool _contemEntidade(AuditoriaEvento evento, String termo) {
    return _blob([
      evento.entidadeTipo,
      evento.entidadeId,
      evento.entidadeNome,
      evento.documentPath,
      evento.sourceEventId,
      evento.operacao,
    ]).contains(termo);
  }

  static bool _contemVinculo(AuditoriaEvento evento, String termo) {
    return _blob([
      evento.idFornecedor,
      evento.idEvento,
      evento.idServico,
      evento.idCotacao,
      evento.idOrcamento,
      evento.rota,
      evento.plataforma,
    ]).contains(termo);
  }

  static String _blob(Iterable<String?> valores) {
    return valores
        .where((v) => (v ?? '').trim().isNotEmpty)
        .join(' ')
        .toLowerCase();
  }
}

class _AuditoriaIntervalo {
  const _AuditoriaIntervalo(this.inicio, this.fim);

  final DateTime inicio;
  final DateTime fim;
}

class _AuditoriaFiltrosServidor {
  const _AuditoriaFiltrosServidor({
    this.area,
    this.acao,
    this.origem,
    this.nivel,
  });

  final String? area;
  final String? acao;
  final String? origem;
  final String? nivel;
}
