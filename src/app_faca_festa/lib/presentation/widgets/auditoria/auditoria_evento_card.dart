import 'package:flutter/material.dart';
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

    return Container(
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconeAcao(evento.area), color: cor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.titulo,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: theme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      evento.resumo,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        height: 1.35,
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
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(info.areaLabel, theme.primary),
              if ((evento.entidadeNome ?? '').isNotEmpty)
                _chip(evento.entidadeNome!, theme.ink),
              if (ator.isNotEmpty) _chip(ator, theme.muted),
            ],
          ),
          if (evento.mudancas.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...evento.mudancas.take(4).map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${m.campo}: ${_valor(m.de)} → ${_valor(m.para)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.ink,
                      ),
                    ),
                  ),
                ),
          ],
          if ((evento.plataforma ?? '').isNotEmpty ||
              (evento.rota ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              [
                if ((evento.plataforma ?? '').isNotEmpty) evento.plataforma,
                if ((evento.rota ?? '').isNotEmpty) evento.rota,
                if ((evento.entidadeId ?? '').isNotEmpty)
                  'ID ${evento.entidadeId}',
              ].join(' · '),
              style: GoogleFonts.poppins(fontSize: 11, color: theme.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
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
    final tipo = _labelTipo(evento.atorTipo);
    if (nome.isEmpty && email.isEmpty) return tipo;
    if (email.isEmpty) return '$tipo · $nome';
    if (nome.isEmpty) return '$tipo · $email';
    return '$tipo · $nome ($email)';
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
