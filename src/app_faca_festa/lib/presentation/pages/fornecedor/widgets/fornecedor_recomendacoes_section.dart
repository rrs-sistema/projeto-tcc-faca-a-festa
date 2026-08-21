import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/bootstrap/fornecedor_recomendacao_bootstrap.dart';
import '../../../../controllers/fornecedor/fornecedor_recomendacao_controller.dart';
import '../../../../data/models/fornecedor/fornecedor_recomendacao_model.dart';
import 'fornecedor_recomendado_card.dart';

class FornecedorRecomendacoesSection extends StatefulWidget {
  final String idEvento;
  final String idUsuario;
  final String? tipoEventoId;
  final String? tipoEventoNome;
  final String? cidade;
  final int limite;
  final bool modoDemo;
  final bool gerarAoIniciar;
  final EdgeInsetsGeometry margin;
  final ValueChanged<FornecedorRecomendacaoModel>? onAbrirFornecedor;
  final ValueChanged<FornecedorRecomendacaoModel>? onReservar;
  final ValueChanged<FornecedorRecomendacaoModel>? onPedirOrcamento;

  const FornecedorRecomendacoesSection({
    super.key,
    required this.idEvento,
    required this.idUsuario,
    this.tipoEventoId,
    this.tipoEventoNome,
    this.cidade,
    this.limite = 10,
    this.modoDemo = false,
    this.gerarAoIniciar = true,
    this.margin = const EdgeInsets.fromLTRB(16, 12, 16, 12),
    this.onAbrirFornecedor,
    this.onReservar,
    this.onPedirOrcamento,
  });

  @override
  State<FornecedorRecomendacoesSection> createState() =>
      _FornecedorRecomendacoesSectionState();
}

class _FornecedorRecomendacoesSectionState
    extends State<FornecedorRecomendacoesSection> {
  late final FornecedorRecomendacaoController controller;

  @override
  void initState() {
    super.initState();

    controller = FornecedorRecomendacaoBootstrap.findController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarInicial();
    });
  }

  @override
  void didUpdateWidget(covariant FornecedorRecomendacoesSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    final mudouContexto = oldWidget.idEvento != widget.idEvento ||
        oldWidget.idUsuario != widget.idUsuario ||
        oldWidget.tipoEventoId != widget.tipoEventoId ||
        oldWidget.tipoEventoNome != widget.tipoEventoNome ||
        oldWidget.cidade != widget.cidade;

    if (mudouContexto) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _carregarInicial();
      });
    }
  }

  Future<void> _carregarInicial() async {
    if (!mounted) return;

    if (widget.idEvento.trim().isEmpty || widget.idUsuario.trim().isEmpty) {
      return;
    }

    await controller.garantirRecomendacoes(
      idEvento: widget.idEvento,
      idUsuario: widget.idUsuario,
      limite: widget.limite,
      gerarSeVazio: widget.gerarAoIniciar,
      modoDemo: widget.modoDemo,
    );
  }

  Future<void> _atualizar() {
    return controller.atualizarRecomendacoes(
      idEvento: widget.idEvento,
      idUsuario: widget.idUsuario,
      limite: widget.limite,
      modoDemo: widget.modoDemo,
    );
  }

  Future<void> _visualizar(FornecedorRecomendacaoModel item) async {
    await controller.visualizarFornecedor(
      idEvento: widget.idEvento,
      idFornecedor: item.idFornecedor,
      tipoEventoId: widget.tipoEventoId,
      tipoEventoNome: widget.tipoEventoNome,
      cidade: widget.cidade,
    );

    widget.onAbrirFornecedor?.call(item);
  }

  Future<void> _pedirOrcamento(FornecedorRecomendacaoModel item) async {
    await controller.pedirOrcamentoFornecedor(
      idEvento: widget.idEvento,
      idFornecedor: item.idFornecedor,
      tipoEventoId: widget.tipoEventoId,
      tipoEventoNome: widget.tipoEventoNome,
      cidade: widget.cidade,
    );

    widget.onPedirOrcamento?.call(item);
  }

  Future<void> _reservar(FornecedorRecomendacaoModel item) async {
    await controller.reservarFornecedor(
      idEvento: widget.idEvento,
      idFornecedor: item.idFornecedor,
      tipoEventoId: widget.tipoEventoId,
      tipoEventoNome: widget.tipoEventoNome,
      cidade: widget.cidade,
    );

    widget.onReservar?.call(item);
  }

  Future<void> _dispensar(FornecedorRecomendacaoModel item) async {
    await controller.dispensarFornecedor(
      idEvento: widget.idEvento,
      idFornecedor: item.idFornecedor,
      tipoEventoId: widget.tipoEventoId,
      tipoEventoNome: widget.tipoEventoNome,
      cidade: widget.cidade,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.idEvento.trim().isEmpty || widget.idUsuario.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      margin: widget.margin,
      child: Obx(() {
        final loading = controller.carregando.value || controller.gerando.value;
        final erro = controller.erro.value;
        final lista = controller.recomendacoes.take(widget.limite).toList();

        if (loading && lista.isEmpty) {
          return _RecomendacaoSkeleton(primary: primary);
        }

        if (lista.isEmpty) {
          return _EmptyRecomendacaoCard(
            primary: primary,
            loading: loading,
            erro: erro,
            tipoEventoNome: widget.tipoEventoNome,
            onGerar: _atualizar,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              primary: primary,
              loading: loading,
              total: lista.length,
              tipoEventoNome: widget.tipoEventoNome,
              cidade: widget.cidade,
              onRefresh: _atualizar,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 272,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: lista.length,
                itemBuilder: (_, index) {
                  final item = lista[index];

                  return FornecedorRecomendadoCard(
                    recomendacao: item,
                    onTap: () => _visualizar(item),
                    onPedirOrcamento: () => _pedirOrcamento(item),
                    onReservar: () => _reservar(item),
                    onDispensar: () => _dispensar(item),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final Color primary;
  final bool loading;
  final int total;
  final String? tipoEventoNome;
  final String? cidade;
  final VoidCallback onRefresh;

  const _SectionHeader({
    required this.primary,
    required this.loading,
    required this.total,
    required this.onRefresh,
    this.tipoEventoNome,
    this.cidade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tipoEventoTexto = tipoEventoNome?.trim() ?? '';
    final cidadeTexto = cidade?.trim() ?? '';
    final evento = tipoEventoTexto.isNotEmpty ? tipoEventoTexto : 'seu evento';
    final local = cidadeTexto.isNotEmpty ? ' • $cidadeTexto' : '';

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.auto_awesome_rounded, color: primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fornecedores ideais para seu evento',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$total sugestão${total == 1 ? '' : 'ões'} para $evento$local',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Atualizar recomendações',
          onPressed: loading ? null : onRefresh,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _EmptyRecomendacaoCard extends StatelessWidget {
  final Color primary;
  final bool loading;
  final String erro;
  final String? tipoEventoNome;
  final VoidCallback onGerar;

  const _EmptyRecomendacaoCard({
    required this.primary,
    required this.loading,
    required this.erro,
    required this.onGerar,
    this.tipoEventoNome,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tipoEventoTexto = tipoEventoNome?.trim() ?? '';
    final evento =
        tipoEventoTexto.isNotEmpty ? tipoEventoTexto : 'o perfil do seu evento';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fornecedores ideais para seu evento',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  erro.isNotEmpty
                      ? erro
                      : 'Use a IA para encontrar fornecedores compatíveis com $evento.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: erro.isNotEmpty
                        ? Colors.redAccent
                        : theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.72),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : onGerar,
                    icon: loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.psychology_alt_rounded, size: 18),
                    label: Text(
                      loading ? 'Analisando...' : 'Gerar recomendações',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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

class _RecomendacaoSkeleton extends StatelessWidget {
  final Color primary;

  const _RecomendacaoSkeleton({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBox(width: 44, height: 44, radius: 16, primary: primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(
                        width: double.infinity, height: 14, primary: primary),
                    const SizedBox(height: 8),
                    _SkeletonBox(width: 190, height: 10, primary: primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SkeletonBox(
              width: double.infinity,
              height: 180,
              radius: 20,
              primary: primary),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color primary;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.primary,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
