import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Lê o texto do dossiê (nuvem ou cópia local) e devolve um PDF para o titular.
Future<Uint8List> gerarPdfDossieTitular(String texto) async {
  final doc = interpretarDossie(texto);
  final fonte = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
  final fonteNegrito = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
  final documento = pw.Document();
  const teal = PdfColor.fromInt(0xFF0F766E);
  const ink = PdfColor.fromInt(0xFF0F172A);
  const muted = PdfColor.fromInt(0xFF64748B);
  const line = PdfColor.fromInt(0xFFE2E8F0);
  const wash = PdfColor.fromInt(0xFFF0FDFA);

  documento.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 42),
      theme: pw.ThemeData.withFont(base: fonte, bold: fonteNegrito),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Text(
          'Faça a Festa  |  documento do titular  |  ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: muted),
        ),
      ),
      build: (context) => [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: const pw.BoxDecoration(
            color: teal,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Faça a Festa',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Dossiê do titular',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Acesso e portabilidade dos dados pessoais (art. 18 da LGPD)',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
              ),
            ],
          ),
        ),
        if (doc.cabecalho.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: wash,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              border: pw.Border.all(color: line),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final linha in doc.cabecalho) _linhaLeve(linha, ink, muted),
              ],
            ),
          ),
        ],
        for (final secao in doc.secoes) ...[
          pw.SizedBox(height: 16),
          pw.Text(
            secao.titulo,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: teal,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(height: 1.2, color: teal),
          pw.SizedBox(height: 8),
          ..._blocos(secao.linhas, ink, muted, line, wash),
        ],
        if (doc.notaFinal != null) ...[
          pw.SizedBox(height: 16),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8FAFC),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              border: pw.Border.all(color: line),
            ),
            child: pw.Text(
              doc.notaFinal!,
              style: const pw.TextStyle(fontSize: 9, color: muted, lineSpacing: 2),
            ),
          ),
        ],
      ],
    ),
  );

  return documento.save();
}

pw.Widget _linhaLeve(LinhaDossie linha, PdfColor ink, PdfColor muted) {
  if (linha.tipo == TipoLinhaDossie.campo) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '${linha.rotulo}  ',
              style: pw.TextStyle(fontSize: 9, color: muted, fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(
              text: linha.valor,
              style: pw.TextStyle(fontSize: 9, color: ink),
            ),
          ],
        ),
      ),
    );
  }
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Text(linha.valor, style: pw.TextStyle(fontSize: 9, color: ink)),
  );
}

List<pw.Widget> _blocos(
  List<LinhaDossie> linhas,
  PdfColor ink,
  PdfColor muted,
  PdfColor line,
  PdfColor wash,
) {
  final widgets = <pw.Widget>[];
  var i = 0;
  while (i < linhas.length) {
    final linha = linhas[i];
    if (linha.tipo == TipoLinhaDossie.subtitulo) {
      final grupo = <LinhaDossie>[];
      i++;
      while (i < linhas.length && linhas[i].tipo != TipoLinhaDossie.subtitulo) {
        grupo.add(linhas[i]);
        i++;
      }
      widgets.add(
        pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: wash,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: line),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                linha.valor,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: ink),
              ),
              pw.SizedBox(height: 6),
              ...grupo.map((item) => _conteudo(item, ink, muted)),
            ],
          ),
        ),
      );
      continue;
    }
    widgets.add(_conteudo(linha, ink, muted));
    i++;
  }
  return widgets;
}

pw.Widget _conteudo(LinhaDossie linha, PdfColor ink, PdfColor muted) {
  switch (linha.tipo) {
    case TipoLinhaDossie.campo:
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 132,
              child: pw.Text(
                linha.rotulo,
                style: pw.TextStyle(fontSize: 9, color: muted, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                linha.valor,
                style: pw.TextStyle(fontSize: 10, color: ink, lineSpacing: 1.5),
              ),
            ),
          ],
        ),
      );
    case TipoLinhaDossie.item:
      if (linha.valor.isEmpty) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  linha.rotulo,
                  style: pw.TextStyle(fontSize: 10, color: ink, fontWeight: pw.FontWeight.bold),
                ),
              ),
              if (linha.extra.isNotEmpty)
                pw.Text(linha.extra, style: pw.TextStyle(fontSize: 9, color: ink)),
            ],
          ),
        );
      }
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                linha.rotulo,
                style: pw.TextStyle(fontSize: 10, color: ink, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              flex: 5,
              child: pw.Text(
                linha.valor,
                style: pw.TextStyle(fontSize: 9, color: muted),
              ),
            ),
            if (linha.extra.isNotEmpty) ...[
              pw.SizedBox(width: 8),
              pw.Text(
                linha.extra,
                style: pw.TextStyle(fontSize: 9, color: ink),
              ),
            ],
          ],
        ),
      );
    case TipoLinhaDossie.subtitulo:
    case TipoLinhaDossie.texto:
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          linha.valor,
          style: pw.TextStyle(fontSize: 10, color: ink, lineSpacing: 2),
        ),
      );
  }
}

enum TipoLinhaDossie { texto, campo, item, subtitulo }

class LinhaDossie {
  const LinhaDossie.texto(this.valor)
      : tipo = TipoLinhaDossie.texto,
        rotulo = '',
        extra = '';

  const LinhaDossie.campo(this.rotulo, this.valor)
      : tipo = TipoLinhaDossie.campo,
        extra = '';

  const LinhaDossie.item(this.rotulo, this.valor, this.extra)
      : tipo = TipoLinhaDossie.item;

  const LinhaDossie.subtitulo(this.valor)
      : tipo = TipoLinhaDossie.subtitulo,
        rotulo = '',
        extra = '';

  final TipoLinhaDossie tipo;
  final String rotulo;
  final String valor;
  final String extra;
}

class SecaoDossie {
  const SecaoDossie(this.titulo, this.linhas);

  final String titulo;
  final List<LinhaDossie> linhas;
}

class DossieDocumento {
  const DossieDocumento({
    required this.cabecalho,
    required this.secoes,
    this.notaFinal,
  });

  final List<LinhaDossie> cabecalho;
  final List<SecaoDossie> secoes;
  final String? notaFinal;
}

final _iso = RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z');

DossieDocumento interpretarDossie(String texto) {
  final brutas = texto
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((linha) => linha.trim())
      .where((linha) => linha.isNotEmpty)
      .map(_humanizarLinha)
      .toList();

  final cabecalho = <LinhaDossie>[];
  final secoes = <SecaoDossie>[];
  String? notaFinal;
  List<LinhaDossie>? atual;

  for (final linha in brutas) {
    if (_ehTituloDocumento(linha)) continue;
    if (_ehNotaFinal(linha) && atual != null) {
      notaFinal = linha;
      continue;
    }
    if (_ehTituloSecao(linha)) {
      atual = <LinhaDossie>[];
      secoes.add(SecaoDossie(linha, atual));
      continue;
    }
    final interpretada = _interpretarLinha(linha);
    if (atual == null) {
      cabecalho.add(interpretada);
    } else {
      atual.add(interpretada);
    }
  }

  return DossieDocumento(
    cabecalho: cabecalho,
    secoes: secoes,
    notaFinal: notaFinal,
  );
}

bool _ehTituloDocumento(String linha) {
  final normal = linha.toLowerCase();
  return normal.startsWith('faça a festa') || normal.startsWith('faca a festa');
}

bool _ehNotaFinal(String linha) {
  final normal = linha.toLowerCase();
  return normal.startsWith('este arquivo reúne') ||
      normal.startsWith('recorte limitado');
}

bool _ehTituloSecao(String linha) => RegExp(r'^\d+\.\s+\S').hasMatch(linha);

LinhaDossie _interpretarLinha(String linha) {
  if (linha.startsWith('Evento ') && !linha.contains(':')) {
    final nome = linha.replaceFirst(RegExp(r'^Evento\s+'), '').trim();
    return LinhaDossie.subtitulo(nome.isEmpty ? 'Evento' : nome);
  }
  if (linha.startsWith('- ')) {
    final partes = linha
        .substring(2)
        .split('|')
        .map((parte) => parte.trim())
        .where((parte) => parte.isNotEmpty)
        .toList();
    if (partes.length >= 3) {
      return LinhaDossie.item(partes[0], partes[1], partes.sublist(2).join(' | '));
    }
    if (partes.length == 2) {
      return LinhaDossie.item(partes[0], '', partes[1]);
    }
    return LinhaDossie.texto(linha.substring(2));
  }
  final separador = linha.indexOf(': ');
  if (separador > 0 && separador <= 42 && !linha.substring(0, separador).contains('.')) {
    return LinhaDossie.campo(
      linha.substring(0, separador),
      linha.substring(separador + 2),
    );
  }
  return LinhaDossie.texto(linha);
}

String _humanizarLinha(String linha) {
  var texto = linha.replaceAll('—', '-').replaceAllMapped(_iso, (match) {
    return _dataLegivel(match.group(0)!);
  });

  final papel = RegExp(r'^Papel:\s*([OFCA])$').firstMatch(texto);
  if (papel != null) {
    texto = 'Papel: ${_nomePapel(papel.group(1)!)}';
  }

  if (texto == 'Avisos: padrão ligado') {
    texto = 'Avisos: convites, cotações, chat e avaliações ligados';
  } else if (texto.startsWith('Avisos: {')) {
    texto = 'Avisos: ${_avisosJson(texto.substring('Avisos: '.length))}';
  }

  texto = texto.replaceFirstMapped(RegExp(r'^([^:]{1,40}):\s*-\s*$'), (match) {
    final rotulo = match.group(1)!;
    final vazio = rotulo == 'Aceite' || rotulo.toLowerCase().contains('versão')
        ? 'Não registrado'
        : 'Não informado';
    return '$rotulo: $vazio';
  });

  texto = texto
      .replaceAll('| adulto', '| Adulto')
      .replaceAll('| criança', '| Criança')
      .replaceAll('| bebê', '| Bebê')
      .replaceAll('| bebe', '| Bebê')
      .replaceAll('| pendente', '| Pendente')
      .replaceAll('| respondida', '| Respondida')
      .replaceAll('| recusada', '| Recusada')
      .replaceAll('Convidados neste recorte:', 'Convidados neste arquivo:')
      .replaceFirst('Conta: ', 'Identificador da conta: ');

  if (texto.toLowerCase().startsWith('recorte limitado')) {
    return 'Este arquivo reúne até 15 eventos, 40 convidados por evento e 20 cotações. Os demais dados continuam na conta.';
  }
  return texto;
}

String _avisosJson(String bruto) {
  try {
    final decoded = jsonDecode(bruto);
    if (decoded is! Map) return 'preferências salvas na conta';
    const nomes = {
      'convites': 'convites',
      'cotacoes': 'cotações',
      'chat': 'chat',
      'avaliacoes': 'avaliações',
    };
    final partes = <String>[];
    for (final entry in nomes.entries) {
      final valor = decoded[entry.key];
      if (valor is bool) {
        partes.add('${entry.value} ${valor ? 'ligados' : 'desligados'}');
      }
    }
    return partes.isEmpty ? 'preferências salvas na conta' : partes.join(', ');
  } catch (_) {
    return 'preferências salvas na conta';
  }
}

String _nomePapel(String tipo) {
  switch (tipo) {
    case 'O':
      return 'Organizador';
    case 'F':
      return 'Fornecedor';
    case 'C':
      return 'Convidado';
    case 'A':
      return 'Administrador';
    default:
      return tipo;
  }
}

String _dataLegivel(String iso) {
  final data = DateTime.tryParse(iso)?.toLocal();
  if (data == null) return iso;
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(data.day)}/${dois(data.month)}/${data.year} ${dois(data.hour)}:${dois(data.minute)}';
}
