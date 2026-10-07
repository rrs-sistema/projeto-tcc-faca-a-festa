import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/domain/entities/sugestao_resposta_cotacao_ai.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/solicitacoes_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/components/show_responder_cotacao_bottom_sheet.dart';
import 'package:app_faca_festa/presentation/modules/legal/widgets/aviso_lgpd_card.dart';

class SolicitacoesSection extends StatefulWidget {
  const SolicitacoesSection({
    super.key,
    required this.fornecedorController,
    required this.solicitacoesController,
    required this.themeController,
    required this.cotacoes,
  });

  final FornecedorController fornecedorController;
  final SolicitacoesController solicitacoesController;
  final EventThemeController themeController;
  final GerenciarCotacoes cotacoes;

  @override
  State<SolicitacoesSection> createState() => _SolicitacoesSectionState();
}

class _SolicitacoesSectionState extends State<SolicitacoesSection> {
  String? _fornecedorInicializado;

  FornecedorController get fornecedorController => widget.fornecedorController;
  SolicitacoesController get solicitacoesController =>
      widget.solicitacoesController;

  void _inicializarSeNecessario(String? idFornecedor) {
    if (idFornecedor == null ||
        idFornecedor.isEmpty ||
        _fornecedorInicializado == idFornecedor) {
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
            height: 96,
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
      final quentes = fornecedorController.ai.scoresCotacoes.values
          .where((s) => s.score >= 75)
          .length;

      return _CotacoesShell(
        total: lista.length,
        quentes: quentes,
        onAtualizarIa: lista.isEmpty
            ? null
            : () => fornecedorController.ai.carregarAiDasSolicitacoesPendentes(
                forceRefresh: true),
        child: lista.isEmpty
            ? const _MensagemEstado(
                icon: Icons.inbox_outlined,
                title: 'Nenhum pedido de preço',
                message:
                    'Quando um organizador pedir preço, as oportunidades aparecem aqui.',
                color: Color(0xFF6366F1),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final usarDuasColunas = constraints.maxWidth >= 860;

                  if (usarDuasColunas) {
                    final itemWidth = (constraints.maxWidth - 12) / 2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(lista.length, (index) {
                        return SizedBox(
                          width: itemWidth,
                          child:
                              _buildCotacaoCard(context, lista[index], index),
                        );
                      }),
                    );
                  }

                  return ListView.separated(
                    itemCount: lista.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (context, index) =>
                        _buildCotacaoCard(context, lista[index], index),
                  );
                },
              ),
      );
    });
  }

  Widget _buildCotacaoCard(BuildContext context, Cotacao item, int index) {
    final idCotacao = item.id.trim().isEmpty ? 'cotacao_$index' : item.id;
    final score = fornecedorController.ai.scoresCotacoes[idCotacao];
    final isGerando =
        fornecedorController.ai.isGerandoRespostaCotacaoAi(idCotacao);

    return _CotacaoInteligenteCard(
      solicitacao: item,
      idCotacao: idCotacao,
      score: score?.score,
      nivel: score?.nivel,
      motivos: score?.motivosPositivos ?? const [],
      alertas: score?.alertas ?? const [],
      isGerandoResposta: isGerando,
      onGerarResposta: isGerando
          ? null
          : () async {
              final sugestao =
                  await fornecedorController.ai.gerarRespostaCotacaoComIa(
                solicitacao: item,
                forceRefresh: true,
              );

              if (!context.mounted) return;
              _abrirRespostaSugerida(context, item, sugestao);
            },
      onResponder: () => _abrirResponderCotacao(context, item),
    );
  }

  void _abrirResponderCotacao(BuildContext context, Cotacao solicitacao) {
    final idCotacao = solicitacao.id.trim();

    if (idCotacao.isEmpty) {
      Get.snackbar(
        'Cotação',
        'Não foi possível identificar a cotação para responder.',
        backgroundColor: const Color(0xFF111827),
        colorText: Colors.white,
      );
      return;
    }

    final nomeSolicitante = solicitacao.nomeUsuarioSolicitante.trim();

    showResponderCotacaoBottomSheet(
      context: context,
      idCotacao: idCotacao,
      categoriaNome: (solicitacao.categoriaNome ?? '').trim().isEmpty
          ? 'Categoria não informada'
          : solicitacao.categoriaNome!,
      descricao: (solicitacao.descricao ?? '').trim().isEmpty
          ? 'Sem descrição'
          : solicitacao.descricao!,
      nomeSolicitante:
          nomeSolicitante.isEmpty ? 'Organizador' : nomeSolicitante,
      dataLimite: _formatarDataCotacao(solicitacao.dataCadastro),
      ofertaDesejada: solicitacao.valorEstimadoTotal ?? 0.0,
      theme: widget.themeController,
      fornecedorController: fornecedorController,
      cotacoes: widget.cotacoes,
    );
  }

  void _abrirRespostaSugerida(
    BuildContext context,
    Cotacao solicitacao,
    SugestaoRespostaCotacaoAi sugestao,
  ) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.90,
        minChildSize: 0.48,
        maxChildSize: 0.96,
        builder: (context, scrollController) {
          return _RespostaCotacaoAiBottomSheet(
            sugestao: sugestao,
            scrollController: scrollController,
            onResponder: () {
              Navigator.pop(context);
              _abrirResponderCotacao(context, solicitacao);
            },
          );
        },
      ),
    );
  }
}

class _RespostaCotacaoAiBottomSheet extends StatefulWidget {
  final SugestaoRespostaCotacaoAi sugestao;
  final ScrollController scrollController;
  final VoidCallback onResponder;

  const _RespostaCotacaoAiBottomSheet({
    required this.sugestao,
    required this.scrollController,
    required this.onResponder,
  });

  @override
  State<_RespostaCotacaoAiBottomSheet> createState() =>
      _RespostaCotacaoAiBottomSheetState();
}

class _RespostaCotacaoAiBottomSheetState
    extends State<_RespostaCotacaoAiBottomSheet> {
  late final TextEditingController _mensagemController;

  @override
  void initState() {
    super.initState();
    _mensagemController =
        TextEditingController(text: widget.sugestao.respostaSugerida);
  }

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  Future<void> _copiar(String texto) async {
    final value = texto.trim();

    if (value.isEmpty) {
      Get.snackbar(
        'Resposta com IA',
        'Não há texto para copiar.',
        backgroundColor: const Color(0xFF111827),
        colorText: Colors.white,
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: value));
    Get.snackbar(
      'Resposta copiada',
      'A mensagem foi copiada para a área de transferência.',
      backgroundColor: const Color(0xFF111827),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final sugestao = widget.sugestao;
    final confiancaColor = _confidenceColor(sugestao.nivelConfianca);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF6F7FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final horizontal = isWide ? 24.0 : 14.0;

            return SingleChildScrollView(
              controller: widget.scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding:
                  EdgeInsets.fromLTRB(horizontal, 10, horizontal, 18 + bottom),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _BottomSheetHeader(
                        confianca: sugestao.nivelConfianca,
                        confiancaColor: confiancaColor,
                      ),
                      const SizedBox(height: 12),
                      _PremiumCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(
                              icon: Icons.edit_note_rounded,
                              title: 'Resposta sugerida',
                              action: TextButton.icon(
                                onPressed: () =>
                                    _copiar(_mensagemController.text),
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Copiar'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _mensagemController,
                              minLines: isWide ? 4 : 5,
                              maxLines: 9,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                hintText: 'Edite a resposta antes de enviar...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF6366F1), width: 1.4),
                                ),
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                height: 1.45,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'Nada será enviado automaticamente. Revise e envie manualmente no próximo passo.',
                              style: GoogleFonts.poppins(
                                fontSize: 11.2,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _versaoCurtaCard(sugestao)),
                            const SizedBox(width: 10),
                            Expanded(
                                child:
                                    _confiancaCard(sugestao, confiancaColor)),
                          ],
                        )
                      else ...[
                        _versaoCurtaCard(sugestao),
                        const SizedBox(height: 10),
                        _confiancaCard(sugestao, confiancaColor),
                      ],
                      const SizedBox(height: 10),
                      _listasInfoResponsive(sugestao, isWide),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 540;
                          final copiar = OutlinedButton.icon(
                            onPressed: () => _copiar(_mensagemController.text),
                            icon: const Icon(Icons.copy_rounded, size: 17),
                            label: Text(
                              'Copiar resposta',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4F46E5),
                              side: const BorderSide(color: Color(0xFFC7D2FE)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 13, horizontal: 14),
                            ),
                          );

                          final responder = ElevatedButton.icon(
                            onPressed: widget.onResponder,
                            icon: const Icon(Icons.reply_rounded, size: 17),
                            label: Text(
                              'Revisar e responder',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFF111827),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 13, horizontal: 14),
                            ),
                          );

                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                copiar,
                                const SizedBox(height: 8),
                                responder
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: copiar),
                              const SizedBox(width: 10),
                              Expanded(child: responder),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _versaoCurtaCard(SugestaoRespostaCotacaoAi sugestao) {
    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Versão curta',
            action: TextButton.icon(
              onPressed: () => _copiar(sugestao.versaoCurta),
              icon: const Icon(Icons.copy_rounded, size: 15),
              label: const Text('Copiar'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sugestao.versaoCurta.trim().isEmpty
                ? 'Sem versão curta disponível.'
                : sugestao.versaoCurta,
            style: GoogleFonts.poppins(
                fontSize: 12.2, height: 1.42, color: const Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  Widget _confiancaCard(SugestaoRespostaCotacaoAi sugestao, Color color) {
    return _PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.verified_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confiança ${sugestao.nivelConfianca.toUpperCase()}',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sugestao.motivoNivelConfianca.trim().isEmpty
                      ? 'Revise os dados antes de enviar.'
                      : sugestao.motivoNivelConfianca,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _listasInfoResponsive(
      SugestaoRespostaCotacaoAi sugestao, bool isWide) {
    final cards = <Widget>[
      _InfoListCard(
        icon: Icons.fact_check_outlined,
        title: 'Pontos para revisar',
        items: sugestao.pontosParaRevisar,
        empty: 'Sem pontos de revisão informados.',
        color: const Color(0xFF4F46E5),
      ),
      _InfoListCard(
        icon: Icons.help_outline_rounded,
        title: 'Perguntas faltantes',
        items: sugestao.perguntasFaltantes,
        empty: 'Nenhuma pergunta faltante.',
        color: const Color(0xFF0F766E),
      ),
      _InfoListCard(
        icon: Icons.warning_amber_rounded,
        title: 'Alertas',
        items: sugestao.alertas,
        empty: 'Sem alertas.',
        color: const Color(0xFFEF4444),
      ),
      _InfoListCard(
        icon: Icons.data_object_rounded,
        title: 'Dados utilizados',
        items: sugestao.dadosUtilizados,
        empty: 'Sem dados listados.',
        color: const Color(0xFF64748B),
      ),
    ];

    if (!isWide) {
      return Column(
        children: cards
            .map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: card,
                ))
            .toList(),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cards
          .map(
            (card) => SizedBox(
              width: 445,
              child: card,
            ),
          )
          .toList(),
    );
  }

  static Color _confidenceColor(String value) {
    switch (value) {
      case 'alto':
        return const Color(0xFF10B981);
      case 'medio':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }
}

class _BottomSheetHeader extends StatelessWidget {
  final String confianca;
  final Color confiancaColor;

  const _BottomSheetHeader(
      {required this.confianca, required this.confiancaColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resposta sugerida',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Revise, edite e copie. Nada será enviado automaticamente.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: confiancaColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: confiancaColor.withValues(alpha: 0.28)),
            ),
            child: Text(
              confianca.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final header = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedidos de preço',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: compact ? 15 : 16,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Responda o que chegou hoje. O organizador espera o valor e o prazo.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 11.5, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final chips = Wrap(
                spacing: 7,
                runSpacing: 7,
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
                    SizedBox(
                      height: 34,
                      child: OutlinedButton.icon(
                        onPressed: onAtualizarIa,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                        label: Text(
                          'Calcular IA',
                          style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                          side: const BorderSide(color: Color(0xFFC7D2FE)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11)),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [header, const SizedBox(height: 10), chips],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: header),
                  const SizedBox(width: 12),
                  chips
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const AvisoLgpdCard(texto: AvisoLgpdCard.acessoRestritoCotacao),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CotacaoInteligenteCard extends StatelessWidget {
  final Cotacao solicitacao;
  final String idCotacao;
  final double? score;
  final String? nivel;
  final List<String> motivos;
  final List<String> alertas;
  final bool isGerandoResposta;
  final VoidCallback? onGerarResposta;
  final VoidCallback onResponder;

  const _CotacaoInteligenteCard({
    required this.solicitacao,
    required this.idCotacao,
    required this.score,
    required this.nivel,
    required this.motivos,
    required this.alertas,
    required this.isGerandoResposta,
    required this.onGerarResposta,
    required this.onResponder,
  });

  @override
  Widget build(BuildContext context) {
    final categoria = (solicitacao.categoriaNome ?? '').trim().isEmpty
        ? 'Cotação'
        : solicitacao.categoriaNome!;
    final solicitante = solicitacao.nomeUsuarioSolicitante.trim().isEmpty
        ? 'Organizador'
        : solicitacao.nomeUsuarioSolicitante;
    final descricao = (solicitacao.descricao ?? '').trim().isEmpty
        ? 'Solicitação aguardando resposta.'
        : solicitacao.descricao!;
    final valor = solicitacao.valorEstimadoTotal;

    final color = _scoreColor(score);
    final scoreLabel = score == null ? 'IA' : '${score!.toStringAsFixed(0)}%';
    final reasons = [
      ...motivos.take(1),
      ...alertas.take(1).map((e) => 'Atenção: $e'),
    ].where((e) => e.trim().isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final veryCompact = constraints.maxWidth < 430;

          final header = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScoreBadge(score: scoreLabel, nivel: nivel, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoria,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      solicitante,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.3,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        height: 1.25,
                      ),
                    ),
                    if (valor != null && valor > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Valor estimado: ${_formatCurrency(valor)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.2,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final aiButton = _CompactActionButton(
            label: isGerandoResposta ? 'Gerando...' : 'Gerar IA',
            tooltip: 'Gerar resposta com IA',
            icon: isGerandoResposta ? null : Icons.auto_awesome_rounded,
            loading: isGerandoResposta,
            outlined: true,
            onTap: onGerarResposta,
          );

          final responderButton = _CompactActionButton(
            label: 'Responder',
            icon: Icons.reply_rounded,
            onTap: onResponder,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              if (reasons.isNotEmpty) ...[
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: reasons
                      .map((r) => _ReasonPill(text: r, color: color))
                      .toList(),
                ),
              ],
              const SizedBox(height: 10),
              if (veryCompact)
                Row(
                  children: [
                    Expanded(child: aiButton),
                    const SizedBox(width: 8),
                    Expanded(child: responderButton)
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(child: aiButton),
                    const SizedBox(width: 8),
                    Flexible(child: responderButton),
                  ],
                ),
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

class _CompactActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? tooltip;
  final bool loading;
  final bool outlined;
  final VoidCallback? onTap;

  const _CompactActionButton({
    required this.label,
    this.icon,
    this.tooltip,
    this.loading = false,
    this.outlined = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (icon != null)
          Icon(icon, size: 15),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );

    final button = SizedBox(
      height: 36,
      child: outlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFFC7D2FE)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: child,
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: child,
            ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _ScoreBadge extends StatelessWidget {
  final String score;
  final String? nivel;
  final Color color;

  const _ScoreBadge(
      {required this.score, required this.nivel, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 1),
          Text(
            (nivel ?? 'score').toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF94A3B8),
            ),
          ),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final Widget child;

  const _PremiumCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? action;

  const _SectionTitle({required this.icon, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13.2,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF111827),
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _InfoListCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final String empty;
  final Color color;

  const _InfoListCard({
    required this.icon,
    required this.title,
    required this.items,
    required this.empty,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final lista = items.where((e) => e.trim().isNotEmpty).take(4).toList();

    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (lista.isEmpty)
            Text(
              empty,
              style: GoogleFonts.poppins(
                  fontSize: 11.5, color: const Color(0xFF64748B)),
            )
          else
            ...lista.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 6),
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          height: 1.35,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
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
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
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
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 10.4,
          color: const Color(0xFF475569),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatCurrency(double value) {
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

String _formatarDataCotacao(DateTime? data) {
  if (data == null) return 'Data não informada';
  return DateFormat('dd/MM/yyyy • HH:mm').format(data);
}
