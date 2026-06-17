import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/fornecedor/fornecedor_controller.dart';
import './../../../../controllers/contacao/solicitacoes_controller.dart';
import 'solicitacao/solicitacao_fornecedor_card.dart';

class SolicitacoesSection extends StatefulWidget {
  const SolicitacoesSection({super.key});

  @override
  State<SolicitacoesSection> createState() => _SolicitacoesSectionState();
}

class _SolicitacoesSectionState extends State<SolicitacoesSection> {
  late final FornecedorController fornecedorController;
  late final SolicitacoesController solicitacoesController;
  String? _fornecedorInicializado;

  @override
  void initState() {
    super.initState();
    fornecedorController = Get.find<FornecedorController>();
    solicitacoesController = Get.put(SolicitacoesController(), permanent: false);
  }

  void _inicializarSeNecessario(String? idFornecedor) {
    if (idFornecedor == null || idFornecedor.isEmpty || _fornecedorInicializado == idFornecedor) {
      return;
    }
    _fornecedorInicializado = idFornecedor;
    Future.microtask(() => solicitacoesController.inicializar(idFornecedor));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fornecedor = fornecedorController.fornecedor.value;
      _inicializarSeNecessario(fornecedor?.idFornecedor);

      if (fornecedor == null || solicitacoesController.carregando.value) {
        return const _CotacoesShell(
          child: SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        );
      }

      if (solicitacoesController.erro.isNotEmpty) {
        return _CotacoesShell(
          child: _MensagemEstado(
            icon: Icons.error_outline_rounded,
            title: 'Não foi possível carregar as cotações',
            message: solicitacoesController.erro.value,
            color: const Color(0xFFEF4444),
          ),
        );
      }

      final lista = solicitacoesController.solicitacoes;
      final quentes = fornecedorController.scoresCotacoes.values.where((s) => s.score >= 75).length;

      return _CotacoesShell(
        total: lista.length,
        quentes: quentes,
        onAtualizarIa: lista.isEmpty
            ? null
            : () => fornecedorController.carregarAiDasSolicitacoesPendentes(forceRefresh: true),
        child: lista.isEmpty
            ? const _MensagemEstado(
                icon: Icons.inbox_outlined,
                title: 'Nenhuma cotação pendente',
                message:
                    'Quando um organizador solicitar orçamento, as oportunidades aparecerão aqui com score inteligente.',
                color: Color(0xFF6366F1),
              )
            : ListView.separated(
                itemCount: lista.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = lista[index];
                  final idCotacao = _readString(item, const ['idCotacao', 'id_cotacao', 'id']) ??
                      'cotacao_$index';
                  final score = fornecedorController.scoresCotacoes[idCotacao];
                  return _CotacaoInteligenteCard(
                    solicitacao: item,
                    idCotacao: idCotacao,
                    score: score?.score,
                    nivel: score?.nivel,
                    motivos: score?.motivosPositivos ?? const [],
                    alertas: score?.alertas ?? const [],
                    onGerarResposta: () async {
                      await fornecedorController.carregarAiDasSolicitacoesPendentes(
                          forceRefresh: true);
                      if (!context.mounted) return;
                      _abrirRespostaSugerida(context, item);
                    },
                    onResponder: () => _abrirSolicitacaoOriginal(context, item),
                  );
                },
              ),
      );
    });
  }

  void _abrirSolicitacaoOriginal(BuildContext context, dynamic solicitacao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF6F7FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: SolicitacaoFornecedorCard(solicitacao: solicitacao),
            ),
          );
        },
      ),
    );
  }

  void _abrirRespostaSugerida(BuildContext context, dynamic solicitacao) {
    final categoria =
        _readString(solicitacao, const ['categoriaNome', 'categoria_nome', 'categoria']) ??
            'serviço solicitado';
    final nome =
        _readString(solicitacao, const ['nomeSolicitante', 'nome_usuario_solicitante', 'nome']) ??
            'organizador';

    final mensagem = 'Olá, $nome! Recebemos sua solicitação para $categoria. '
        'Podemos preparar uma proposta com disponibilidade, detalhes do serviço e condições de atendimento. '
        'Para deixar o orçamento mais preciso, confirme por favor a data, local completo e quantidade de convidados.';

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF4F46E5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Resposta sugerida pela IA local',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                mensagem,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: const Color(0xFF334155), height: 1.45),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma mensagem foi enviada automaticamente. Revise antes de responder.',
              style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _abrirSolicitacaoOriginal(context, solicitacao);
                },
                icon: const Icon(Icons.edit_note_rounded),
                label: Text('Revisar e responder',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CotacoesShell extends StatelessWidget {
  final Widget child;
  final int? total;
  final int quentes;
  final VoidCallback? onAtualizarIa;

  const _CotacoesShell({
    required this.child,
    this.total,
    this.quentes = 0,
    this.onAtualizarIa,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 600;
              final header = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        const Icon(Icons.receipt_long_rounded, size: 19, color: Color(0xFF4F46E5)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cotações inteligentes',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF111827))),
                        const SizedBox(height: 2),
                        Text('Priorize oportunidades com maior chance de fechar.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                ],
              );

              final chips = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (total != null)
                    _Chip(
                        text: '$total pendente${total == 1 ? '' : 's'}',
                        color: const Color(0xFF4F46E5)),
                  if (quentes > 0)
                    _Chip(
                        text: '$quentes quente${quentes == 1 ? '' : 's'}',
                        color: const Color(0xFFEF4444)),
                  if (onAtualizarIa != null)
                    OutlinedButton.icon(
                      onPressed: onAtualizarIa,
                      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: Text('Calcular IA',
                          style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w800)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4F46E5),
                        side: const BorderSide(color: Color(0xFFC7D2FE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              );

              if (compact) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [header, const SizedBox(height: 12), chips]);
              }

              return Row(children: [Expanded(child: header), const SizedBox(width: 12), chips]);
            },
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CotacaoInteligenteCard extends StatelessWidget {
  final dynamic solicitacao;
  final String idCotacao;
  final double? score;
  final String? nivel;
  final List<String> motivos;
  final List<String> alertas;
  final VoidCallback onGerarResposta;
  final VoidCallback onResponder;

  const _CotacaoInteligenteCard({
    required this.solicitacao,
    required this.idCotacao,
    required this.score,
    required this.nivel,
    required this.motivos,
    required this.alertas,
    required this.onGerarResposta,
    required this.onResponder,
  });

  @override
  Widget build(BuildContext context) {
    final categoria =
        _readString(solicitacao, const ['categoriaNome', 'categoria_nome', 'categoria']) ??
            'Cotação';
    final solicitante =
        _readString(solicitacao, const ['nomeSolicitante', 'nome_usuario_solicitante', 'nome']) ??
            'Organizador';
    final descricao = _readString(solicitacao, const ['descricao', 'observacao', 'mensagem']) ??
        'Solicitação aguardando resposta.';
    final valor =
        _readDouble(solicitacao, const ['valorEstimadoTotal', 'valor_estimado_total', 'valor']);
    final scoreValue = score;
    final color = _scoreColor(scoreValue);
    final scoreLabel = scoreValue == null ? 'Em análise' : '${scoreValue.toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final top = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScoreBadge(score: scoreLabel, nivel: nivel, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categoria,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827))),
                    const SizedBox(height: 3),
                    Text(solicitante,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: const Color(0xFF64748B), height: 1.35)),
                    if (valor != null && valor > 0) ...[
                      const SizedBox(height: 7),
                      Text('Valor estimado: R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F766E))),
                    ],
                  ],
                ),
              ),
            ],
          );

          final reasons =
              [...motivos.take(2), ...alertas.take(1).map((e) => 'Atenção: $e')].toList();
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onGerarResposta,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text('Gerar resposta com IA',
                    style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  side: const BorderSide(color: Color(0xFFC7D2FE)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onResponder,
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: Text('Responder',
                    style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              top,
              if (reasons.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: reasons.map((r) => _ReasonPill(text: r, color: color)).toList(),
                ),
              ],
              const SizedBox(height: 12),
              compact
                  ? SizedBox(width: double.infinity, child: actions)
                  : Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        },
      ),
    );
  }

  static Color _scoreColor(double? score) {
    if (score == null) return const Color(0xFF64748B);
    if (score >= 75) return const Color(0xFFEF4444);
    if (score >= 45) return const Color(0xFFF59E0B);
    return const Color(0xFF64748B);
  }
}

class _ScoreBadge extends StatelessWidget {
  final String score;
  final String? nivel;
  final Color color;

  const _ScoreBadge({required this.score, required this.nivel, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(score,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text((nivel ?? 'score').toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 8.5, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _MensagemEstado extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _MensagemEstado({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(message,
                    style: GoogleFonts.poppins(
                        fontSize: 12.2, color: const Color(0xFF6B7280), height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;

  const _Chip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
      child: Text(text,
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _ReasonPill extends StatelessWidget {
  final String text;
  final Color color;

  const _ReasonPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
              fontSize: 10.8, fontWeight: FontWeight.w700, color: const Color(0xFF475569))),
    );
  }
}

String? _readString(dynamic source, List<String> keys) {
  if (source == null) return null;

  if (source is Map) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  for (final key in keys) {
    try {
      final value = _readDynamicProperty(source, key);
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    } catch (_) {}
  }

  return null;
}

double? _readDouble(dynamic source, List<String> keys) {
  final raw = _readString(source, keys);
  if (raw == null) return null;
  return double.tryParse(raw.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim());
}

dynamic _readDynamicProperty(dynamic source, String key) {
  switch (key) {
    case 'idCotacao':
      return source.idCotacao;
    case 'id_cotacao':
      return source.idCotacao;
    case 'id':
      return source.id;
    case 'categoriaNome':
      return source.categoriaNome;
    case 'categoria_nome':
      return source.categoriaNome;
    case 'descricao':
      return source.descricao;
    case 'observacao':
      return source.observacao;
    case 'nomeSolicitante':
      return source.nomeSolicitante;
    case 'nome_usuario_solicitante':
      return source.nomeSolicitante;
    case 'valorEstimadoTotal':
      return source.valorEstimadoTotal;
    case 'valor_estimado_total':
      return source.valorEstimadoTotal;
  }
  return null;
}
