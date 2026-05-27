import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/calculadora_festa_controller.dart';
import '../../data/models/evento/analise_calculadora_ia_model.dart';
import '../../data/models/evento/calculadora_festa_item_model.dart';
import '../../data/models/evento/calculadora_festa_model.dart';

class MinhasSimulacoesCalculadoraBottomSheet extends StatelessWidget {
  final CalculadoraFestaController controller;

  const MinhasSimulacoesCalculadoraBottomSheet({
    super.key,
    required this.controller,
  });

  static Future<bool?> show({
    required BuildContext context,
    required CalculadoraFestaController controller,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => MinhasSimulacoesCalculadoraBottomSheet(
        controller: controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Container(
      // Altura reduzida para 80% para dar sensação de BottomSheet e não de tela cheia
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.carregandoSimulacoes.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final simulacoes = controller.simulacoesSalvas;

              if (simulacoes.isEmpty) {
                return _EmptyState(
                  primary: primary,
                  onRefresh: controller.carregarSimulacoesSalvas,
                );
              }

              return RefreshIndicator(
                onRefresh: controller.carregarSimulacoesSalvas,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                  itemCount: simulacoes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final simulacao = simulacoes[index];
                    return _SimulacaoCard(
                      controller: controller,
                      simulacao: simulacao,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CalculadoraFestaController controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 1)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle superior (Grabber)
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minhas simulações',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Obx(() => Text(
                            '${controller.simulacoesSalvas.length} cenários salvos',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          )),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.carregarSimulacoesSalvas,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimulacaoCard extends StatelessWidget {
  final CalculadoraFestaController controller;
  final CalculadoraFestaModel simulacao;

  const _SimulacaoCard({
    required this.controller,
    required this.simulacao,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final statusColor = _statusColor(simulacao.statusSimulacao);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          dense: true, // Torna o cabeçalho do tile mais compacto
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: primary.withValues(alpha: 0.1),
            child: Icon(Icons.auto_graph_rounded, color: primary, size: 18),
          ),
          title: Text(
            '${simulacao.perfilFesta.nome} • ${_formatDate(simulacao.dataCalculo)}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SingleChildScrollView(
              // Garante que chips não quebrem linha se for pequeno
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ChipInfo(
                    icon: Icons.payments_rounded,
                    label: _formatMoney(simulacao.custoTotalEstimado),
                    color: primary,
                  ),
                  const SizedBox(width: 6),
                  _ChipInfo(
                    icon: Icons.groups_rounded,
                    label: '${simulacao.totalConvidados}',
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 6),
                  _ChipInfo(
                    icon: Icons.check_circle_outline,
                    label: simulacao.statusSimulacao.label,
                    color: statusColor,
                  ),
                ],
              ),
            ),
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            _ResumoSimulacao(simulacao: simulacao),
            const SizedBox(height: 10),
            _ItensSimulacaoPreview(
              controller: controller,
              simulacao: simulacao,
            ),
            const SizedBox(height: 12),
            _AcoesSimulacao(
              controller: controller,
              simulacao: simulacao,
            ),
          ],
        ),
      ),
    );
  }

  static Color _statusColor(StatusSimulacaoCalculadora status) {
    switch (status) {
      case StatusSimulacaoCalculadora.rascunho:
        return Colors.blueGrey;
      case StatusSimulacaoCalculadora.aprovada:
        return Colors.teal;
      case StatusSimulacaoCalculadora.convertidaOrcamento:
        return Colors.deepPurple;
      case StatusSimulacaoCalculadora.cancelada:
        return Colors.redAccent;
    }
  }
}

class _ResumoSimulacao extends StatelessWidget {
  final CalculadoraFestaModel simulacao;
  const _ResumoSimulacao({required this.simulacao});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ResumoItem(label: 'Adultos', value: '${simulacao.totalAdultos}'),
              _ResumoItem(label: 'Crianças', value: '${simulacao.totalCriancas}'),
              _ResumoItem(label: 'Bebês', value: '${simulacao.totalBebes}'),
              _ResumoItem(label: 'Tempo', value: '${simulacao.duracaoHoras}h'),
            ],
          ),
          if (simulacao.analiseIA != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
            ),
            _AnaliseIASimulacaoCompacta(analise: simulacao.analiseIA!),
          ],
        ],
      ),
    );
  }
}

class _AnaliseIASimulacaoCompacta extends StatelessWidget {
  final AnaliseCalculadoraIAModel analise;

  const _AnaliseIASimulacaoCompacta({required this.analise});

  @override
  Widget build(BuildContext context) {
    final sugestao = analise.sugestoes.isNotEmpty ? analise.sugestoes.first : null;
    final resumo = analise.resumo.trim().isNotEmpty
        ? analise.resumo.trim()
        : sugestao?.descricao.trim() ?? 'Análise inteligente salva para esta simulação.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ChipInfo(
              icon: Icons.psychology_alt_rounded,
              label: 'IA',
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 6),
            _ChipInfo(
              icon: Icons.favorite_rounded,
              label: '${analise.indiceConforto.clamp(0, 100).round()}%',
              color: Colors.teal,
            ),
            const SizedBox(width: 6),
            _ChipInfo(
              icon: Icons.warning_amber_rounded,
              label: '${analise.indiceRiscoFaltarItens.clamp(0, 100).round()}%',
              color: analise.indiceRiscoFaltarItens >= 70 ? Colors.redAccent : Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          resumo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 11,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (sugestao != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.tips_and_updates_rounded,
                size: 14,
                color: Colors.amber.shade700,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  sugestao.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF111827),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ItensSimulacaoPreview extends StatelessWidget {
  final CalculadoraFestaController controller;
  final CalculadoraFestaModel simulacao;

  const _ItensSimulacaoPreview({required this.controller, required this.simulacao});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CalculadoraFestaItemModel>>(
      future: controller.listarItensDaSimulacao(simulacao.idCalculo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LinearProgressIndicator());
        }

        final itens = snapshot.data ?? [];
        if (itens.isEmpty) return const SizedBox.shrink();

        // Mostrar apenas 2 itens para economizar espaço
        final totalPreview = itens.length > 2 ? 2 : itens.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in itens.take(totalPreview)) _ItemPreviewTile(item: item),
            if (itens.length > totalPreview)
              Text(
                '+ ${itens.length - totalPreview} outros itens...',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AcoesSimulacao extends StatelessWidget {
  final CalculadoraFestaController controller;
  final CalculadoraFestaModel simulacao;

  const _AcoesSimulacao({required this.controller, required this.simulacao});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Obx(() {
      final convertendo = controller.convertendoOrcamento.value;
      final aprovada = simulacao.statusSimulacao == StatusSimulacaoCalculadora.aprovada;
      final convertida = simulacao.convertidoEmOrcamento ||
          simulacao.statusSimulacao == StatusSimulacaoCalculadora.convertidaOrcamento;
      final podeConverter = aprovada && !convertida;

      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: convertida
                    ? Colors.deepPurple
                    : podeConverter
                        ? Colors.teal
                        : Colors.blueGrey,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: (!podeConverter || convertendo)
                  ? null
                  : () => controller.transformarSimulacaoEmOrcamento(simulacao),
              icon: convertendo
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(
                      convertida ? Icons.price_check_rounded : Icons.request_quote_rounded,
                      size: 18,
                    ),
              label: Text(
                convertida
                    ? 'Já convertida em orçamento'
                    : aprovada
                        ? 'Transformar em orçamento'
                        : 'Aprove para gerar orçamento',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await controller.carregarSimulacaoNoEditor(simulacao);
                      Get.back(result: true);
                    },
                    child: Text(
                      'Aplicar',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: convertida || aprovada
                    ? null
                    : () => controller.aprovarSimulacao(simulacao.idCalculo),
                icon: Icon(
                  Icons.check_circle_outline,
                  color: convertida || aprovada ? Colors.grey : Colors.teal,
                  size: 22,
                ),
                tooltip: 'Aprovar',
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: convertendo ? null : () => _confirmarExclusao(context),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                tooltip: 'Excluir',
              ),
            ],
          ),
        ],
      );
    });
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final confirmar = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Excluir?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text('Deseja remover esta simulação?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Não')),
          TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Sim', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar == true) await controller.excluirSimulacao(simulacao.idCalculo);
  }
}

class _ResumoItem extends StatelessWidget {
  final String label;
  final String value;

  const _ResumoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 10)),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 13)),
      ],
    );
  }
}

class _ItemPreviewTile extends StatelessWidget {
  final CalculadoraFestaItemModel item;
  const _ItemPreviewTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            item.quantidadeFormatada,
            style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _ChipInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ChipInfo({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color primary;
  final Future<void> Function() onRefresh;

  const _EmptyState({required this.primary, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_motion_rounded,
                color: primary.withValues(alpha: 0.2), size: 48),
            const SizedBox(height: 12),
            Text('Nada salvo ainda',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Gere um cálculo e salve para ver aqui.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            TextButton(onPressed: onRefresh, child: const Text('Atualizar')),
          ],
        ),
      ),
    );
  }
}

// Funções auxiliares mantidas iguais
String _formatMoney(double value) {
  final normalized = value.toStringAsFixed(2).replaceAll('.', ',');
  final parts = normalized.split(',');
  final integer = parts.first.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return 'R\$ $integer,${parts.last}';
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
