import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum EscolhaNovoCardapio { gerarComIa, criarManualmente }

Future<EscolhaNovoCardapio?> mostrarEscolhaNovoCardapio({
  required BuildContext context,
  required Color primaryColor,
}) {
  return showModalBottomSheet<EscolhaNovoCardapio>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Como deseja montar o cardápio?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Receba sugestões com IA ou cadastre manualmente.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Opcao(
                    icon: Icons.auto_awesome_rounded,
                    titulo: 'Gerar com IA',
                    descricao:
                        'Sugestões de comidas, bebidas e quantidades.',
                    cor: primaryColor,
                    preenchido: true,
                    onTap: () => Navigator.pop(
                      context,
                      EscolhaNovoCardapio.gerarComIa,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Opcao(
                    icon: Icons.edit_note_rounded,
                    titulo: 'Criar manualmente',
                    descricao: 'Monte categorias e itens do seu jeito.',
                    cor: primaryColor,
                    preenchido: false,
                    onTap: () => Navigator.pop(
                      context,
                      EscolhaNovoCardapio.criarManualmente,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Opcao extends StatelessWidget {
  const _Opcao({
    required this.icon,
    required this.titulo,
    required this.descricao,
    required this.cor,
    required this.preenchido,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String descricao;
  final Color cor;
  final bool preenchido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: preenchido ? cor : cor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: preenchido
                      ? Colors.white.withValues(alpha: 0.18)
                      : cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: preenchido ? Colors.white : cor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: preenchido
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      descricao,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: preenchido
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: preenchido
                    ? Colors.white.withValues(alpha: 0.85)
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
