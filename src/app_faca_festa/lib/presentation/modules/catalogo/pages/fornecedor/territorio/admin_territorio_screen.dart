import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:app_faca_festa/domain/entities/territorio.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_territorio_controller.dart';
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

  /// Itens únicos por `idFornecedor`. Se o território apontar para um ID
  /// que não está na lista (fornecedor removido/não carregado), inclui um
  /// item sentinela para o [DropdownButtonFormField] não quebrar.
  List<DropdownMenuItem<String>> _itensDropdownFornecedor(String idAtual) {
    final vistos = <String>{};
    final itens = <DropdownMenuItem<String>>[];

    for (final f in fornecedorController.fornecedores) {
      final id = f.idFornecedor.trim();
      if (id.isEmpty || !vistos.add(id)) continue;
      itens.add(
        DropdownMenuItem(
          value: id,
          child: Text(
            f.razaoSocial.trim().isEmpty ? id : f.razaoSocial,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (idAtual.isNotEmpty && vistos.add(idAtual)) {
      itens.add(
        DropdownMenuItem(
          value: idAtual,
          child: Text(
            'Fornecedor não encontrado ($idAtual)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return itens;
  }

  InputDecoration _fieldDecoration({String? hint, Color? accent}) {
    final borderColor = (accent ?? AdminPalette.primary).withValues(alpha: 0.28);
    return InputDecoration(
      filled: true,
      fillColor: AdminPalette.surface,
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accent ?? AdminPalette.primary, width: 1.4),
      ),
    );
  }

  Widget _labelCampo(String texto) {
    return Text(
      texto,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AdminPalette.muted,
      ),
    );
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
        body: Row(
          children: [
            Expanded(flex: 3, child: _buildLista(context)),
            Expanded(flex: 5, child: _buildMapa()),
          ],
        ),
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
                        onTap: () => controller.definirFiltroStatus(
                            FiltroStatusTerritorio.todos),
                      ),
                      _filtroChip(
                        label: 'Ativos',
                        selected: controller.filtroStatus.value ==
                            FiltroStatusTerritorio.ativos,
                        onTap: () => controller.definirFiltroStatus(
                            FiltroStatusTerritorio.ativos),
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
                  message:
                      'Defina a área de cobertura de cada fornecedor.',
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

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                itemCount: lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final t = lista[i];
                  return _TerritorioCard(
                    territorio: t,
                    nomeFornecedor: _getNomeFornecedor(t.idFornecedor),
                    fornecedorOrfao: !_fornecedorExiste(t.idFornecedor),
                    selecionado:
                        controller.idTerritorioSelecionado.value ==
                            t.idTerritorio,
                    onSelect: () => controller.selecionarTerritorio(t),
                    onEdit: () =>
                        _abrirDialogTerritorio(context, existente: t),
                    onToggle: (v) => controller.toggleAtivo(t, v),
                  );
                },
              );
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
      controller.idTerritorioSelecionado.value;
      final selecionadoId = controller.idTerritorioSelecionado.value;
      final ativos = controller.territorios.where((t) => t.ativo).toList();
      final temSelecao = selecionadoId != null;

      return Stack(
        children: [
          FlutterMap(
            mapController: controller.mapController,
            options: MapOptions(
              initialCenter: AdminTerritorioController.centroBrasil,
              initialZoom: 4.3,
              onMapReady: () {
                if (temSelecao) {
                  controller.ajustarMapaParaSelecionado();
                } else {
                  controller.ajustarMapaParaTerritorios();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'app_faca_festa',
              ),
              CircleLayer(
                circles: ativos
                    .where((t) =>
                        t.tipoCobertura == 'raio' &&
                        t.latitude != null &&
                        t.longitude != null)
                    .map((t) {
                  final sel = t.idTerritorio == selecionadoId;
                  return CircleMarker(
                    point: LatLng(t.latitude!, t.longitude!),
                    radius: (t.raioKm ?? 10) * 1000,
                    color: (sel ? AdminPalette.primary : Colors.blueAccent)
                        .withValues(alpha: sel ? 0.28 : 0.12),
                    borderStrokeWidth: sel ? 2.5 : 1.2,
                    borderColor:
                        sel ? AdminPalette.primary : Colors.blueAccent,
                    useRadiusInMeter: true,
                  );
                }).toList(),
              ),
              PolygonLayer(
                polygons: ativos
                    .where((t) =>
                        t.tipoCobertura == 'regiao' &&
                        t.regioes != null &&
                        t.regioes!.isNotEmpty)
                    .map((t) {
                  final sel = t.idTerritorio == selecionadoId;
                  return Polygon(
                    points: t.regioes!.map((r) {
                      final parts = r.split(',');
                      return LatLng(
                        double.parse(parts[0]),
                        double.parse(parts[1]),
                      );
                    }).toList(),
                    color: (sel ? AdminPalette.primary : Colors.teal)
                        .withValues(alpha: sel ? 0.28 : 0.12),
                    borderColor:
                        sel ? AdminPalette.primary : Colors.teal.shade700,
                    borderStrokeWidth: sel ? 2.5 : 1.2,
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: ativos
                    .where((t) => t.latitude != null && t.longitude != null)
                    .map((t) {
                  final sel = t.idTerritorio == selecionadoId;
                  final nome = _getNomeFornecedor(t.idFornecedor);
                  return Marker(
                    point: LatLng(t.latitude!, t.longitude!),
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
                          size: sel ? 40 : 30,
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
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
                      temSelecao
                          ? 'Focado: ${_getNomeFornecedor(controller.territorioSelecionado?.idFornecedor ?? '')}'
                          : '${ativos.length} cobertura${ativos.length == 1 ? '' : 's'} ativa${ativos.length == 1 ? '' : 's'} no mapa',
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
                if (temSelecao) ...[
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
      );
    });
  }

  void _abrirDialogTerritorio(BuildContext context, {Territorio? existente}) {
    final cor = AdminPalette.primary;
    final formKey = GlobalKey<FormState>();

    var t = existente ??
        Territorio(
          idTerritorio: DateTime.now().millisecondsSinceEpoch.toString(),
          idFornecedor: '',
          tipoCobertura: 'raio',
          ativo: true,
          raioKm: 10,
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(builder: (context, setState) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AdminPalette.border,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: cor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  existente == null
                                      ? Icons.add_location_alt_rounded
                                      : Icons.edit_location_alt_rounded,
                                  color: cor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  existente == null
                                      ? 'Novo Território'
                                      : 'Editar Território',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AdminPalette.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _labelCampo('Fornecedor'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: t.idFornecedor.trim().isNotEmpty
                                ? t.idFornecedor.trim()
                                : null,
                            items: _itensDropdownFornecedor(
                                t.idFornecedor.trim()),
                            decoration: _fieldDecoration(accent: cor),
                            onChanged: (v) => setState(() {
                              t = t.copyWith(idFornecedor: v ?? '');
                            }),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Selecione um fornecedor'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _labelCampo('Tipo de Cobertura'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: t.tipoCobertura,
                            items: const [
                              DropdownMenuItem(
                                  value: 'raio',
                                  child: Text('Cobertura por Raio')),
                              DropdownMenuItem(
                                  value: 'regiao',
                                  child: Text('Cobertura por Região')),
                            ],
                            decoration: _fieldDecoration(),
                            onChanged: (v) => setState(() {
                              t = t.copyWith(tipoCobertura: v ?? 'raio');
                            }),
                          ),
                          const SizedBox(height: 16),
                          if (t.tipoCobertura == 'raio') ...[
                            _labelCampo('Raio de Cobertura (km)'),
                            const SizedBox(height: 6),
                            TextFormField(
                              initialValue: t.raioKm == null
                                  ? ''
                                  : NumericInput.quantidade(t.raioKm!),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [NumericInput.decimal()],
                              decoration: _fieldDecoration(
                                  hint: 'Ex: 10', accent: cor),
                              onChanged: (v) => setState(() {
                                t = t.copyWith(raioKm: Biblioteca.toDouble(v));
                              }),
                            ),
                            const SizedBox(height: 16),
                          ],
                          _labelCampo('Descrição'),
                          const SizedBox(height: 6),
                          TextFormField(
                            initialValue: t.descricao,
                            maxLines: 2,
                            decoration: _fieldDecoration(
                              hint:
                                  'Ex: Zona Sul — raio de atendimento principal',
                              accent: cor,
                            ),
                            onChanged: (v) => setState(() {
                              t = t.copyWith(descricao: v);
                            }),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AdminPalette.surface,
                              border: Border.all(color: AdminPalette.border),
                            ),
                            child: SwitchListTile(
                              title: Text(
                                'Território ativo',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: AdminPalette.ink,
                                ),
                              ),
                              subtitle: Text(
                                'Inativos não aparecem no mapa de cobertura',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: AdminPalette.muted,
                                ),
                              ),
                              value: t.ativo,
                              activeColor: cor,
                              onChanged: (v) => setState(() {
                                t = t.copyWith(ativo: v);
                              }),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              TextButton(
                                onPressed: Get.back,
                                child: Text(
                                  'Cancelar',
                                  style: GoogleFonts.poppins(
                                    color: AdminPalette.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              FilledButton.icon(
                                icon: const Icon(Icons.save_rounded, size: 18),
                                label: Text(
                                  existente == null ? 'Salvar' : 'Atualizar',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: cor,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  await controller.salvarTerritorio(t);
                                  Get.back();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
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
                icon: tipoRaio
                    ? Icons.radar_rounded
                    : Icons.pentagon_outlined,
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
