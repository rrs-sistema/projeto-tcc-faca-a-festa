part of 'auditoria_controller.dart';

extension AuditoriaExport on AuditoriaController {
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
}
