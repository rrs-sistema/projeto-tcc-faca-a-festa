// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import './../../../domain/entities/gift/gift.dart';
import '../tema/controllers/event_theme_controller.dart';
import './cadastrar_presente_page.dart';
import 'controllers/gift_controller.dart';

class GerenciarPresentesPage extends StatefulWidget {
  final String eventoId;

  const GerenciarPresentesPage({super.key, required this.eventoId});

  @override
  State<GerenciarPresentesPage> createState() => _GerenciarPresentesPageState();
}

class _GerenciarPresentesPageState extends State<GerenciarPresentesPage> {
  final GiftController controller = Get.find<GiftController>();
  final EventThemeController themeController = Get.find<EventThemeController>();

  late final TextEditingController _searchCtrl;

  String _busca = '';
  GiftType? _tipoFiltro;
  GiftStatus? _statusFiltro;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _limparFiltros() {
    _searchCtrl.clear();
    setState(() {
      _busca = '';
      _tipoFiltro = null;
      _statusFiltro = null;
    });
  }

  List<Gift> _filtrar(List<Gift> gifts) {
    final termo = _busca.trim().toLowerCase();

    return gifts.where((gift) {
      final matchTexto = termo.isEmpty ||
          gift.nome.toLowerCase().contains(termo) ||
          (gift.descricao ?? '').toLowerCase().contains(termo) ||
          (gift.loja ?? '').toLowerCase().contains(termo);

      final matchTipo = _tipoFiltro == null || gift.tipo == _tipoFiltro;
      final matchStatus = _statusFiltro == null || gift.status == _statusFiltro;

      return matchTexto && matchTipo && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final primary = themeController.primaryColor.value;
      final gradient = themeController.gradient.value;
      final todos = controller.gifts.toList(growable: false);
      final gifts = _filtrar(todos);
      final stats = _GiftStats.from(todos);

      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'novo_presente_${widget.eventoId}',
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded, size: 21),
          label: Text(
            'Novo presente',
            style: GoogleFonts.poppins(
                fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
          onPressed: () => abrirDialogCadastrarPresente(context),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _PremiumGiftHeader(
                gradient: gradient,
                primary: primary,
                stats: stats,
                onBack: () => Get.back(),
                onAdd: () => abrirDialogCadastrarPresente(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _StatsPanel(primary: primary, stats: stats),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _FilterPanel(
                  primary: primary,
                  busca: _busca,
                  tipoSelecionado: _tipoFiltro,
                  statusSelecionado: _statusFiltro,
                  totalFiltrado: gifts.length,
                  onSearch: (value) => setState(() => _busca = value),
                  onTipoChanged: (value) => setState(() => _tipoFiltro = value),
                  onStatusChanged: (value) =>
                      setState(() => _statusFiltro = value),
                  searchController: _searchCtrl,
                  onClear: _limparFiltros,
                ),
              ),
            ),
            if (todos.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _PremiumEmptyState(
                  primary: primary,
                  title: 'Sua lista de presentes ainda está vazia',
                  message:
                      'Cadastre presentes físicos, contribuições por PIX ou presentes coletivos para deixar o espaço dos convidados mais completo.',
                  actionLabel: 'Cadastrar primeiro presente',
                  onAction: () => abrirDialogCadastrarPresente(context),
                ),
              )
            else if (gifts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _PremiumEmptyState(
                  primary: primary,
                  title: 'Nenhum presente encontrado',
                  message:
                      'Ajuste os filtros ou pesquise por outro nome, loja ou descrição.',
                  actionLabel: 'Limpar filtros',
                  onAction: _limparFiltros,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index.isOdd) return const SizedBox(height: 12);
                      final gift = gifts[index ~/ 2];
                      return _PremiumGiftCard(
                        gift: gift,
                        primary: primary,
                        onEdit: () => abrirDialogCadastrarPresente(context,
                            presente: gift),
                        onDelete: () =>
                            _confirmarExclusao(context, gift, primary),
                      );
                    },
                    childCount: gifts.length * 2 - 1,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  void _confirmarExclusao(BuildContext context, Gift gift, Color primary) {
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Remover presente?',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF111827),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'O presente “${gift.nome}” será removido da lista. Essa ação não poderá ser desfeita.',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF64748B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () async {
                          await controller.excluirPresente(gift.id);
                          Get.back();
                          Get.snackbar(
                            'Presente removido',
                            'A lista foi atualizada com sucesso.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: primary,
                            colorText: Colors.white,
                            margin: const EdgeInsets.all(12),
                            borderRadius: 16,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Remover',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumGiftHeader extends StatelessWidget {
  final Gradient gradient;
  final Color primary;
  final _GiftStats stats;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  const _PremiumGiftHeader({
    required this.gradient,
    required this.primary,
    required this.stats,
    required this.onBack,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          Positioned(
              right: -58,
              top: -52,
              child: _GlowCircle(size: 170, opacity: 0.12)),
          Positioned(
              left: -46,
              bottom: -66,
              child: _GlowCircle(size: 148, opacity: 0.10)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: onBack,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gerenciar presentes',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sugestões para o espaço dos convidados',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _GlassIconButton(
                        icon: Icons.add_rounded,
                        onTap: onAdd,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Uma lista bonita, clara e fácil de escolher.',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Organize presentes físicos, PIX e metas coletivas com aparência profissional para seus convidados.',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: 12.2,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _HeaderPill(
                        icon: Icons.card_giftcard_rounded,
                        label: '${stats.total} cadastrados',
                      ),
                      const SizedBox(width: 8),
                      _HeaderPill(
                        icon: Icons.check_circle_rounded,
                        label: '${stats.disponiveis} disponíveis',
                      ),
                    ],
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

class _StatsPanel extends StatelessWidget {
  final Color primary;
  final _GiftStats stats;

  const _StatsPanel({required this.primary, required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 760 ? 4 : 2;
        final cardHeight = constraints.maxWidth >= 760 ? 112.0 : 118.0;

        final cards = [
          _StatCard(
            primary: primary,
            icon: Icons.card_giftcard_rounded,
            title: 'Total',
            value: stats.total.toString(),
            subtitle: 'presentes',
          ),
          _StatCard(
            primary: primary,
            icon: Icons.check_circle_rounded,
            title: 'Disponíveis',
            value: stats.disponiveis.toString(),
            subtitle: 'para escolha',
          ),
          _StatCard(
            primary: primary,
            icon: Icons.lock_clock_rounded,
            title: 'Reservados',
            value: stats.reservados.toString(),
            subtitle: 'já sinalizados',
          ),
          _StatCard(
            primary: primary,
            icon: Icons.savings_rounded,
            title: 'Arrecadado',
            value: _money(stats.valorArrecadado),
            subtitle: 'coletivos',
            isMoney: true,
          ),
        ];

        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (_, index) => cards[index],
        );
      },
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final Color primary;
  final TextEditingController searchController;
  final String busca;
  final GiftType? tipoSelecionado;
  final GiftStatus? statusSelecionado;
  final int totalFiltrado;
  final ValueChanged<String> onSearch;
  final ValueChanged<GiftType?> onTipoChanged;
  final ValueChanged<GiftStatus?> onStatusChanged;
  final VoidCallback onClear;

  const _FilterPanel({
    required this.primary,
    required this.searchController,
    required this.busca,
    required this.tipoSelecionado,
    required this.statusSelecionado,
    required this.totalFiltrado,
    required this.onSearch,
    required this.onTipoChanged,
    required this.onStatusChanged,
    required this.onClear,
  });

  bool get _temFiltro =>
      busca.trim().isNotEmpty ||
      tipoSelecionado != null ||
      statusSelecionado != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Catálogo de presentes',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$totalFiltrado item${totalFiltrado == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                    color: primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: onSearch,
            style: GoogleFonts.poppins(
              color: const Color(0xFF111827),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar por presente, descrição ou loja...',
              hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF94A3B8), fontSize: 12),
              prefixIcon: Icon(Icons.search_rounded, color: primary),
              suffixIcon: _temFiltro
                  ? IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFF64748B)),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE5EAF3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: primary, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _FilterChipButton(
                  primary: primary,
                  selected: tipoSelecionado == null,
                  label: 'Todos',
                  icon: Icons.apps_rounded,
                  onTap: () => onTipoChanged(null),
                ),
                ...GiftType.values.map(
                  (tipo) => _FilterChipButton(
                    primary: primary,
                    selected: tipoSelecionado == tipo,
                    label: _tipoLabel(tipo),
                    icon: _tipoIcon(tipo),
                    onTap: () => onTipoChanged(tipo),
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChipButton(
                  primary: primary,
                  selected: statusSelecionado == GiftStatus.disponivel,
                  label: 'Disponíveis',
                  icon: Icons.check_circle_outline_rounded,
                  onTap: () => onStatusChanged(
                    statusSelecionado == GiftStatus.disponivel
                        ? null
                        : GiftStatus.disponivel,
                  ),
                ),
                _FilterChipButton(
                  primary: primary,
                  selected: statusSelecionado == GiftStatus.reservado,
                  label: 'Reservados',
                  icon: Icons.lock_clock_rounded,
                  onTap: () => onStatusChanged(
                    statusSelecionado == GiftStatus.reservado
                        ? null
                        : GiftStatus.reservado,
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

class _PremiumGiftCard extends StatelessWidget {
  final Gift gift;
  final Color primary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PremiumGiftCard({
    required this.gift,
    required this.primary,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final reservado = gift.status == GiftStatus.reservado;
    final isColetivo = gift.tipo == GiftType.coletivo;
    final isFisico = gift.tipo == GiftType.fisico;
    final temImagem = isFisico && (gift.imagem ?? '').trim().isNotEmpty;
    final progress = isColetivo && (gift.metaValor ?? 0) > 0
        ? (gift.valorArrecadado / gift.metaValor!).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(22),
                      border:
                          Border.all(color: primary.withValues(alpha: 0.10)),
                    ),
                    child: temImagem
                        ? Image.network(
                            gift.imagem!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                                _tipoIcon(gift.tipo),
                                color: primary,
                                size: 30),
                          )
                        : Icon(_tipoIcon(gift.tipo), color: primary, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _SoftBadge(
                              label: _tipoLabel(gift.tipo),
                              icon: _tipoIcon(gift.tipo),
                              color: primary,
                            ),
                            const SizedBox(width: 6),
                            _SoftBadge(
                              label: reservado ? 'Reservado' : 'Disponível',
                              icon: reservado
                                  ? Icons.lock_clock_rounded
                                  : Icons.check_circle_rounded,
                              color: reservado
                                  ? Colors.orange.shade800
                                  : Colors.green.shade700,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          gift.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF111827),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        if ((gift.descricao ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            gift.descricao!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF64748B),
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Ações',
                    icon: const Icon(Icons.more_vert_rounded,
                        color: Color(0xFF64748B)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: _MenuItem(
                            icon: Icons.edit_rounded, label: 'Editar'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: _MenuItem(
                          icon: Icons.delete_outline_rounded,
                          label: 'Remover',
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isColetivo) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Meta coletiva',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF64748B),
                        fontSize: 11.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_money(gift.valorArrecadado)} / ${_money(gift.metaValor ?? 0)}',
                      style: GoogleFonts.poppins(
                        color: primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    color: primary,
                    backgroundColor: const Color(0xFFE5EAF3),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5EAF3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _GiftInfoLine(
                        icon: isFisico
                            ? Icons.storefront_rounded
                            : Icons.payments_rounded,
                        label: isFisico ? 'Loja' : 'Valor',
                        value: isFisico
                            ? _fallback(gift.loja, 'Não informada')
                            : _money(gift.valor ?? 0),
                      ),
                    ),
                    Container(
                        width: 1, height: 34, color: const Color(0xFFE5EAF3)),
                    Expanded(
                      child: _GiftInfoLine(
                        icon: isFisico ? Icons.link_rounded : Icons.pix_rounded,
                        label: isFisico ? 'Link' : 'PIX',
                        value: isFisico
                            ? ((gift.link ?? '').trim().isEmpty
                                ? 'Sem link'
                                : 'Informado')
                            : _fallback(gift.pix, 'Não informado'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumEmptyState extends StatelessWidget {
  final Color primary;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _PremiumEmptyState({
    required this.primary,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE5EAF3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(24),
                ),
                child:
                    Icon(Icons.card_giftcard_rounded, color: primary, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF111827),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontSize: 12.3,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 20),
                  label: Text(
                    actionLabel,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GiftInfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _GiftInfoLine(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF94A3B8),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF334155),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final Color primary;
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final bool isMoney;

  const _StatCard({
    required this.primary,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.isMoney = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: primary, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF111827),
                  fontSize: isMoney ? 15.5 : 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final Color primary;
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.primary,
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? primary : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(999),
            border:
                Border.all(color: selected ? primary : const Color(0xFFE5EAF3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 15,
                  color: selected ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: selected ? Colors.white : const Color(0xFF475569),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SoftBadge(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? const Color(0xFF334155);

    return Row(
      children: [
        Icon(icon, size: 18, color: itemColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: itemColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _GlowCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _GiftStats {
  final int total;
  final int disponiveis;
  final int reservados;
  final double valorArrecadado;

  const _GiftStats({
    required this.total,
    required this.disponiveis,
    required this.reservados,
    required this.valorArrecadado,
  });

  factory _GiftStats.from(List<Gift> gifts) {
    return _GiftStats(
      total: gifts.length,
      disponiveis:
          gifts.where((gift) => gift.status == GiftStatus.disponivel).length,
      reservados:
          gifts.where((gift) => gift.status == GiftStatus.reservado).length,
      valorArrecadado:
          gifts.fold<double>(0, (sum, gift) => sum + gift.valorArrecadado),
    );
  }
}

IconData _tipoIcon(GiftType tipo) {
  if (tipo == GiftType.pix) return Icons.pix_rounded;
  if (tipo == GiftType.coletivo) return Icons.groups_2_rounded;
  return Icons.card_giftcard_rounded;
}

String _tipoLabel(GiftType tipo) {
  if (tipo == GiftType.pix) return 'PIX';
  if (tipo == GiftType.coletivo) return 'Coletivo';
  return 'Físico';
}

String _money(double value) {
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

String _fallback(String? value, String fallback) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}
