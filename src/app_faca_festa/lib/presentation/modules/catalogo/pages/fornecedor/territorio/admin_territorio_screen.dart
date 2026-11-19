import 'package:app_faca_festa/presentation/widgets/festa_scroll_area.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:app_faca_festa/presentation/widgets/festa_leitura.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/territorio.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_territorio_controller.dart';
import 'package:app_faca_festa/presentation/modules/admin/pages/tabelas_abrangencia_admin_page.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/pages/fornecedor/components/territorio_mapa_zoom.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/pages/fornecedor/territorio/admin_territorio_form.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';

class AdminTerritorioScreen extends StatelessWidget {
  final AdminTerritorioController controller;
  final FornecedorController fornecedorController;
  final EventThemeController themeController;

  AdminTerritorioScreen({
    super.key,
    required this.controller,
    required this.fornecedorController,
    required this.themeController,
  }) {
    Future.microtask(controller.carregarTerritorios);
  }

  bool _fornecedorExiste(String idFornecedor) {
    return fornecedorController.fornecedores
            .firstWhereOrNull((x) => x.idFornecedor == idFornecedor) !=
        null;
  }

  String _getNomeFornecedor(String idFornecedor) {
    final f = fornecedorController.fornecedores
        .firstWhereOrNull((x) => x.idFornecedor == idFornecedor);
    return f?.razaoSocial.trim().isNotEmpty == true
        ? f!.razaoSocial
        : 'Fornecedor não encontrado';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeController.adminThemeData,
      child: Scaffold(
        backgroundColor: AdminPalette.surface,
        appBar: AdminBackAppBar(
          title: 'Gerenciar Territórios',
          subtitle: 'Cobertura dos fornecedores',
          actions: [
            IconButton(
              icon:
                  const Icon(Icons.price_change_outlined, color: Colors.white),
              tooltip: 'Faixas de abrangência',
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => Theme(
                    data: themeController.adminThemeData,
                    child: const TabelasAbrangenciaAdminPage(),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Recarregar',
              onPressed: controller.carregarTerritorios,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _abrirDialogTerritorio(context),
          backgroundColor: AdminPalette.dark,
          icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
          label: Text(
            'Novo Território',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: FestaContent(
            child: Row(
          children: [
            Expanded(flex: 3, child: _buildLista(context)),
            Expanded(flex: 5, child: _buildMapa()),
          ],
        )),
      ),
    );
  }

  Widget _buildLista(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AdminPalette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Obx(() {
              final total = controller.territorios.length;
              final ativos = controller.totalAtivos;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Territórios',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AdminPalette.ink,
                          ),
                        ),
                      ),
                      Text(
                        '$ativos ativos · $total',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AdminPalette.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AdminSearchField(
                    controller: controller.buscaCtrl,
                    hint: 'Buscar fornecedor ou descrição…',
                    onChanged: controller.atualizarBusca,
                    onClear: controller.busca.value.isEmpty
                        ? null
                        : controller.limparBusca,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _filtroChip(
                        label: 'Todos',
                        selected: controller.filtroStatus.value ==
                            FiltroStatusTerritorio.todos,
                        onTap: () => controller
                            .definirFiltroStatus(FiltroStatusTerritorio.todos),
                      ),
                      _filtroChip(
                        label: 'Ativos',
                        selected: controller.filtroStatus.value ==
                            FiltroStatusTerritorio.ativos,
                        onTap: () => controller
                            .definirFiltroStatus(FiltroStatusTerritorio.ativos),
                      ),
                      _filtroChip(
                        label: 'Inativos',
                        selected: controller.filtroStatus.value ==
                            FiltroStatusTerritorio.inativos,
                        onTap: () => controller.definirFiltroStatus(
                            FiltroStatusTerritorio.inativos),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
          Expanded(
            child: Obx(() {
              // Dependências reativas explícitas
              controller.busca.value;
              controller.filtroStatus.value;
              controller.idTerritorioSelecionado.value;
              final lista = controller.filtrarComNomes(_getNomeFornecedor);

              if (controller.territorios.isEmpty) {
                return AdminEmptyState(
                  icon: Icons.map_outlined,
                  title: 'Nenhum território cadastrado',
                  message: 'Defina a área de cobertura de cada fornecedor.',
                  actionLabel: 'Novo Território',
                  onAction: () => _abrirDialogTerritorio(context),
                );
              }

              if (lista.isEmpty) {
                return const AdminEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Nenhum resultado',
                  message: 'Ajuste a busca ou o filtro de status.',
                );
              }

              return FestaScrollArea(
                  color: AdminPalette.primary,
                  maxWidth: double.infinity,
                  child: ListView.separated(
                    primary: true,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final t = lista[i];
                      return _TerritorioCard(
                        territorio: t,
                        nomeFornecedor: _getNomeFornecedor(t.idFornecedor),
                        fornecedorOrfao: !_fornecedorExiste(t.idFornecedor),
                        selecionado: controller.idTerritorioSelecionado.value ==
                            t.idTerritorio,
                        onSelect: () => controller.selecionarTerritorio(t),
                        onEdit: () =>
                            _abrirDialogTerritorio(context, existente: t),
                        onToggle: (v) => controller.toggleAtivo(t, v),
                      );
                    },
                  ));
            }),
          ),
        ],
      ),
    );
  }

  Widget _filtroChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? AdminPalette.primary.withValues(alpha: 0.12)
                : AdminPalette.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AdminPalette.primary.withValues(alpha: 0.35)
                  : AdminPalette.border,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: selected ? AdminPalette.primary : AdminPalette.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapa() {
    return Obx(() {
      final previa = controller.previaCobertura;
      final selecionado = previa ?? controller.territorioSelecionado;
      final selecionadoId = selecionado?.idTerritorio;
      final ativos = controller.territorios.where((t) => t.ativo).toList();
      final areasVisiveis = [if (selecionado != null) selecionado];
      final territoriosComMarcador = [
        ...ativos.where((t) => t.idTerritorio != selecionadoId),
        if (selecionado != null) selecionado,
      ];

      return FestaGestosProprios(
          child: Stack(
        children: [
          FlutterMap(
            mapController: controller.mapController,
            options: MapOptions(
              initialCenter: AdminTerritorioController.centroBrasil,
              initialZoom: 4.3,
              minZoom: 0,
              maxZoom: 19,
              onMapReady: () {
                if (selecionado != null) {
                  controller.ajustarMapaParaSelecionado();
                } else {
                  controller.ajustarMapaParaTerritorios();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'app_faca_festa',
              ),
              CircleLayer(
                circles: areasVisiveis
                    .where((t) =>
                        t.tipoCobertura == 'raio' &&
                        t.latitude != null &&
                        t.longitude != null)
                    .map((t) {
                  return CircleMarker(
                    point: LatLng(t.latitude!, t.longitude!),
                    radius: (t.raioKm ?? 10) * 1000,
                    color: AdminPalette.primary.withValues(alpha: 0.28),
                    borderStrokeWidth: 2.5,
                    borderColor: AdminPalette.primary,
                    useRadiusInMeter: true,
                  );
                }).toList(),
              ),
              PolygonLayer(
                polygons: areasVisiveis
                    .where((t) =>
                        t.tipoCobertura == 'regiao' &&
                        t.regioes?.isNotEmpty == true)
                    .map((t) {
                      final pontos = controller.pontosDeCobertura(t);
                      if (pontos.length < 3) return null;
                      return Polygon(
                        points: pontos,
                        color: AdminPalette.primary.withValues(alpha: 0.28),
                        borderColor: AdminPalette.primary,
                        borderStrokeWidth: 2.5,
                      );
                    })
                    .whereType<Polygon>()
                    .toList(),
              ),
              MarkerLayer(
                markers: territoriosComMarcador
                    .map((t) {
                      final ponto = _pontoDoTerritorio(t);
                      if (ponto == null) return null;
                      final sel = t.idTerritorio == selecionadoId;
                      final nome = _getNomeFornecedor(t.idFornecedor);
                      return Marker(
                        point: ponto,
                        width: sel ? 46 : 38,
                        height: sel ? 46 : 38,
                        child: Tooltip(
                          message:
                              '$nome\n${t.descricao?.isNotEmpty == true ? t.descricao! : 'Sem descrição'}',
                          child: GestureDetector(
                            onTap: () => controller.selecionarTerritorio(t),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: sel
                                  ? AdminPalette.primary
                                  : AdminPalette.danger.withValues(alpha: 0.85),
                              size: sel ? 40 : (selecionado == null ? 30 : 18),
                            ),
                          ),
                        ),
                      );
                    })
                    .whereType<Marker>()
                    .toList(),
              ),
              const Positioned(
                right: 16,
                bottom: 84,
                child: TerritorioMapaZoom(cor: AdminPalette.primary),
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminPalette.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      previa != null
                          ? 'Prévia da cobertura'
                          : selecionado != null
                              ? 'Focado: ${_getNomeFornecedor(selecionado.idFornecedor)}'
                              : '${ativos.length} território${ativos.length == 1 ? ' ativo' : 's ativos'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminPalette.ink,
                      ),
                    ),
                  ),
                ),
                if (selecionado != null && previa == null) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 1,
                    shadowColor: Colors.black26,
                    child: InkWell(
                      onTap: controller.verTodos,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_out_map_rounded,
                                size: 16, color: AdminPalette.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Ver todos',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AdminPalette.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ));
    });
  }

  LatLng? _pontoDoTerritorio(Territorio territorio) {
    final latitude = territorio.latitude;
    final longitude = territorio.longitude;
    if (latitude != null && longitude != null) {
      return LatLng(latitude, longitude);
    }
    if (territorio.tipoCobertura != 'regiao') return null;
    final vertices = controller.pontosDeCobertura(territorio);
    return vertices.length < 3
        ? null
        : LatLngBounds.fromPoints(vertices).center;
  }

  void _abrirDialogTerritorio(BuildContext context, {Territorio? existente}) {
    mostrarFormularioTerritorioAdmin(
      context,
      controller: controller,
      fornecedores: fornecedorController.fornecedores,
      existente: existente,
    );
  }
}

class _TerritorioCard extends StatelessWidget {
  final Territorio territorio;
  final String nomeFornecedor;
  final bool fornecedorOrfao;
  final bool selecionado;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  const _TerritorioCard({
    required this.territorio,
    required this.nomeFornecedor,
    required this.fornecedorOrfao,
    required this.selecionado,
    required this.onSelect,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final tipoRaio = territorio.tipoCobertura == 'raio';
    final descricao = territorio.descricao?.trim().isNotEmpty == true
        ? territorio.descricao!
        : 'Sem descrição';
    final cobertura = tipoRaio
        ? 'Raio${territorio.raioKm != null ? ' · ${territorio.raioKm!.toStringAsFixed(0)} km' : ''}'
        : 'Região';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: adminCardDecoration(highlighted: selecionado).copyWith(
            border: Border.all(
              color: fornecedorOrfao
                  ? AdminPalette.warning.withValues(alpha: 0.45)
                  : selecionado
                      ? AdminPalette.primary.withValues(alpha: 0.45)
                      : AdminPalette.border,
              width: selecionado || fornecedorOrfao ? 1.4 : 1,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminLeadingMark(
                icon: tipoRaio ? Icons.radar_rounded : Icons.pentagon_outlined,
                color: fornecedorOrfao
                    ? AdminPalette.warning
                    : (territorio.ativo
                        ? AdminPalette.primary
                        : AdminPalette.muted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeFornecedor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: fornecedorOrfao
                            ? AdminPalette.warning
                            : AdminPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descricao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AdminPalette.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        AdminMetricChip(
                          icon: tipoRaio
                              ? Icons.circle_outlined
                              : Icons.map_outlined,
                          label: cobertura,
                        ),
                        if (fornecedorOrfao)
                          AdminStatusChip.warning(
                            'Sem fornecedor',
                            icon: Icons.warning_amber_rounded,
                          ),
                        if (!territorio.ativo)
                          AdminStatusChip.neutral('Inativo'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                children: [
                  AdminIconAction(
                    icon: Icons.edit_outlined,
                    tooltip: 'Editar',
                    onPressed: onEdit,
                    color: AdminPalette.primary,
                  ),
                  AdminCompactSwitch(
                    value: territorio.ativo,
                    onChanged: onToggle,
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
