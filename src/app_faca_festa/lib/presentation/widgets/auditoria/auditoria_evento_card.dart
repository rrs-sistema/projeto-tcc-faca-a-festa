import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/auditoria/auditoria_catalogo.dart';
import '../../../domain/entities/auditoria_evento.dart';

class AuditoriaVisualTheme {
  const AuditoriaVisualTheme({
    required this.surface,
    required this.card,
    required this.ink,
    required this.muted,
    required this.border,
    required this.primary,
    required this.danger,
    required this.warning,
    required this.success,
  });

  final Color surface;
  final Color card;
  final Color ink;
  final Color muted;
  final Color border;
  final Color primary;
  final Color danger;
  final Color warning;
  final Color success;
}

class AuditoriaEventoCard extends StatelessWidget {
  const AuditoriaEventoCard({
    super.key,
    required this.evento,
    required this.theme,
  });

  final AuditoriaEvento evento;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    final info = infoAcaoAuditoria(evento.acao);
    final cor = _corAcao(evento, theme);
    final quando = evento.criadoEm == null
        ? ''
        : DateFormat('dd/MM HH:mm', 'pt_BR').format(evento.criadoEm!);
    final ator = _rotuloAtor(evento);
    final origem = _rotuloOrigem(evento);
    final corOrigem = _corOrigem(evento, theme);

    return Material(
      color: theme.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarDetalhes(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _ehSnapshot(evento)
                  ? theme.border
                  : theme.primary.withValues(alpha: 0.34),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(_iconeAcao(evento.area), color: cor, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: theme.ink,
                          ),
                        ),
                        Text(
                          evento.resumo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            height: 1.25,
                            color: theme.ink.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (quando.isNotEmpty)
                    Text(
                      quando,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: theme.muted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  _chip(origem, corOrigem),
                  _chip(info.areaLabel, theme.primary),
                  _chip(_rotuloNivel(evento.nivel), _corNivel(evento, theme)),
                  if ((evento.entidadeNome ?? '').isNotEmpty)
                    _chip(evento.entidadeNome!, theme.ink),
                  if (ator.isNotEmpty) _chip(ator, theme.muted),
                ],
              ),
              if (evento.mudancas.isNotEmpty) ...[
                const SizedBox(height: 7),
                ...evento.mudancas.take(2).map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '${m.campo}: ${_valor(m.de)} → ${_valor(m.para)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.ink,
                          ),
                        ),
                      ),
                    ),
                if (evento.mudancas.length > 2)
                  Text(
                    '+ ${evento.mudancas.length - 2} alterações',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: theme.muted,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  static String _valor(String value) {
    final texto = value.trim();
    return texto.isEmpty ? '—' : texto;
  }

  static String _rotuloAtor(AuditoriaEvento evento) {
    final nome = (evento.atorNome ?? '').trim();
    final email = (evento.atorEmail ?? '').trim();
    final uid = (evento.atorUid ?? '').trim();
    final tipo = _labelTipo(evento.atorTipo);
    if (nome.isEmpty && email.isEmpty && uid.isEmpty) return tipo;
    if (nome.isEmpty && email.isEmpty) return '$tipo · $uid';
    if (email.isEmpty) return '$tipo · $nome';
    if (nome.isEmpty && uid.isNotEmpty) return '$tipo · $uid';
    if (nome.isEmpty) return '$tipo · $email';
    return '$tipo · $nome ($email)';
  }

  static String _rotuloOperacao(String operacao) {
    switch (operacao) {
      case 'created':
        return 'Criação';
      case 'updated':
        return 'Atualização';
      case 'deleted':
        return 'Exclusão';
      default:
        return operacao;
    }
  }

  void _mostrarDetalhes(BuildContext context) {
    final info = infoAcaoAuditoria(evento.acao);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: theme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.86,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          info.titulo,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: theme.ink,
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Copiar evidência',
                        child: IconButton(
                          onPressed: () => _copiarTexto(
                            context,
                            _textoEvidencia(evento),
                            'Evidência copiada',
                          ),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.content_copy_rounded,
                            size: 18,
                            color: theme.primary,
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Fechar',
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: theme.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    evento.resumo,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.3,
                      color: theme.ink.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _chip(_rotuloOrigem(evento), _corOrigem(evento, theme)),
                      _chip(info.areaLabel, theme.primary),
                      _chip(
                          _rotuloNivel(evento.nivel), _corNivel(evento, theme)),
                      if ((evento.operacao ?? '').isNotEmpty)
                        _chip(_rotuloOperacao(evento.operacao!), theme.ink),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DetailSection(
                    title: 'Identificação',
                    rows: [
                      _DetailEntry('ID da auditoria', evento.id),
                      _DetailEntry('Data/hora', _dataCompleta(evento.criadoEm)),
                      _DetailEntry('Ação', evento.acao),
                      _DetailEntry('Área', evento.area),
                      _DetailEntry('Severidade', _rotuloNivel(evento.nivel)),
                    ],
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _DetailSection(
                    title: 'Contexto',
                    rows: [
                      _DetailEntry('Ator', _rotuloAtor(evento)),
                      _DetailEntry('Entidade', evento.entidadeTipo ?? '-'),
                      _DetailEntry('Nome', evento.entidadeNome ?? '-'),
                      _DetailEntry('ID', evento.entidadeId ?? evento.id),
                      _DetailEntry(
                          'Origem técnica', evento.origem ?? 'callable'),
                      _DetailEntry(
                          'Evento origem', evento.sourceEventId ?? '-'),
                      _DetailEntry('Auth', evento.atorAuthType ?? '-'),
                      _DetailEntry('Documento', evento.documentPath ?? '-'),
                    ],
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _DetailSection(
                    title: 'Ambiente',
                    rows: [
                      _DetailEntry('Rota', evento.rota ?? '-'),
                      _DetailEntry('Plataforma', evento.plataforma ?? '-'),
                      _DetailEntry('Hash', evento.hashIntegridade ?? '-'),
                      _DetailEntry('Algoritmo', evento.algoritmoHash ?? '-'),
                      _DetailEntry(
                        'Visível ao fornecedor',
                        evento.visivelFornecedor ? 'Sim' : 'Não',
                      ),
                    ],
                    theme: theme,
                  ),
                  if (evento.mudancas.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _DetailSection(
                      title: 'Alterações',
                      rows: [
                        for (final mudanca in evento.mudancas)
                          _DetailEntry(
                            mudanca.campo,
                            '${_valor(mudanca.de)} -> ${_valor(mudanca.para)}',
                          ),
                      ],
                      theme: theme,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _DetailSection(
                    title: 'Vínculos',
                    rows: [
                      _DetailEntry('Fornecedor', evento.idFornecedor ?? '-'),
                      _DetailEntry('Evento', evento.idEvento ?? '-'),
                      _DetailEntry('Serviço', evento.idServico ?? '-'),
                      _DetailEntry('Cotação', evento.idCotacao ?? '-'),
                      _DetailEntry('Orçamento', evento.idOrcamento ?? '-'),
                    ],
                    theme: theme,
                  ),
                  if ((evento.detalhe ?? {}).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _JsonDetailSection(
                      title: _ehSnapshot(evento)
                          ? 'Dados do registro'
                          : 'Payload de auditoria',
                      value: _jsonAuditoria(evento.detalhe!),
                      theme: theme,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _labelTipo(String? tipo) {
    switch ((tipo ?? '').trim()) {
      case 'A':
        return 'Administrador';
      case 'F':
        return 'Fornecedor';
      case 'O':
        return 'Organizador';
      default:
        return 'Sistema';
    }
  }

  static String _dataCompleta(DateTime? data) {
    if (data == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm:ss', 'pt_BR').format(data);
  }

  static String _jsonAuditoria(Map<String, dynamic> detalhe) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(_normalizarJson(detalhe));
  }

  static String _textoEvidencia(AuditoriaEvento evento) {
    final info = infoAcaoAuditoria(evento.acao);
    final linhas = [
      'Auditoria: ${info.titulo}',
      'ID: ${evento.id}',
      'Data/hora: ${_dataCompleta(evento.criadoEm)}',
      'Ação: ${evento.acao}',
      'Área: ${evento.area}',
      'Severidade: ${_rotuloNivel(evento.nivel)}',
      'Origem: ${evento.origem ?? 'callable'}',
      'Evento origem: ${evento.sourceEventId ?? '-'}',
      'Operação: ${evento.operacao ?? '-'}',
      'Ator: ${_rotuloAtor(evento)}',
      'Entidade: ${evento.entidadeTipo ?? '-'} | ${evento.entidadeId ?? '-'}',
      'Nome: ${evento.entidadeNome ?? '-'}',
      'Documento: ${evento.documentPath ?? '-'}',
      'Fornecedor: ${evento.idFornecedor ?? '-'}',
      'Evento: ${evento.idEvento ?? '-'}',
      'Serviço: ${evento.idServico ?? '-'}',
      'Cotação: ${evento.idCotacao ?? '-'}',
      'Orçamento: ${evento.idOrcamento ?? '-'}',
      'Hash: ${evento.hashIntegridade ?? '-'}',
      'Resumo: ${evento.resumo}',
    ];

    if (evento.mudancas.isNotEmpty) {
      linhas.add('Alterações:');
      for (final mudanca in evento.mudancas) {
        linhas.add(
          '- ${mudanca.campo}: ${_valor(mudanca.de)} -> ${_valor(mudanca.para)}',
        );
      }
    }

    return linhas.join('\n');
  }

  static Future<void> _copiarTexto(
    BuildContext context,
    String texto,
    String mensagem,
  ) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static dynamic _normalizarJson(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _normalizarJson(item)),
      );
    }
    if (value is Iterable) {
      return value.map(_normalizarJson).toList();
    }
    return value.toString();
  }

  static bool _ehSnapshot(AuditoriaEvento evento) {
    return (evento.origem ?? '').trim() == 'snapshot';
  }

  static String _rotuloOrigem(AuditoriaEvento evento) {
    return _ehSnapshot(evento) ? 'Registro do sistema' : 'Evento auditado';
  }

  static String _rotuloNivel(String nivel) {
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
        return nivel.isEmpty ? 'Informativo' : nivel;
    }
  }

  static Color _corOrigem(AuditoriaEvento evento, AuditoriaVisualTheme theme) {
    return _ehSnapshot(evento) ? theme.muted : theme.success;
  }

  static Color _corNivel(AuditoriaEvento evento, AuditoriaVisualTheme theme) {
    switch (evento.nivel) {
      case 'CRITICAL':
      case 'ERROR':
        return theme.danger;
      case 'WARN':
        return theme.warning;
      default:
        return theme.primary;
    }
  }

  static Color _corAcao(AuditoriaEvento evento, AuditoriaVisualTheme theme) {
    switch (evento.nivel) {
      case 'CRITICAL':
      case 'ERROR':
        return theme.danger;
      case 'WARN':
        return theme.warning;
      default:
        switch (evento.area) {
          case 'SERVICO':
          case 'CATALOGO':
            return theme.primary;
          case 'FORNECEDOR':
            return theme.success;
          case 'ORCAMENTO':
          case 'COTACAO':
            return const Color(0xFF7C3AED);
          case 'EVENTO':
            return const Color(0xFF0369A1);
          default:
            return theme.primary;
        }
    }
  }

  static IconData _iconeAcao(String area) {
    switch (area) {
      case 'USUARIO':
      case 'ACESSO':
        return Icons.manage_accounts_rounded;
      case 'FORNECEDOR':
        return Icons.storefront_rounded;
      case 'SERVICO':
        return Icons.design_services_rounded;
      case 'CATALOGO':
        return Icons.category_rounded;
      case 'EVENTO':
        return Icons.event_available_rounded;
      case 'ORCAMENTO':
        return Icons.request_quote_rounded;
      case 'COTACAO':
        return Icons.forum_rounded;
      default:
        return Icons.fact_check_rounded;
    }
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.rows,
    required this.theme,
  });

  final String title;
  final List<_DetailEntry> rows;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: theme.ink,
              ),
            ),
            const SizedBox(height: 6),
            for (final row in rows) ...[
              _DetailRow(entry: row, theme: theme),
              if (row != rows.last) const Divider(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailEntry {
  const _DetailEntry(this.label, this.value);

  final String label;
  final String value;
}

class _JsonDetailSection extends StatelessWidget {
  const _JsonDetailSection({
    required this.title,
    required this.value,
    required this.theme,
  });

  final String title;
  final String value;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: theme.ink,
              ),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: SelectableText(
                  value,
                  style: GoogleFonts.robotoMono(
                    fontSize: 10.5,
                    height: 1.35,
                    color: theme.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.entry,
    required this.theme,
  });

  final _DetailEntry entry;
  final AuditoriaVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    final canCopy = entry.value.trim().isNotEmpty && entry.value != '-';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            entry.label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.muted,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            entry.value,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              height: 1.25,
              color: theme.ink,
            ),
          ),
        ),
        if (canCopy)
          Tooltip(
            message: 'Copiar',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => AuditoriaEventoCard._copiarTexto(
                context,
                entry.value,
                '${entry.label} copiado',
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: theme.muted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
