import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/fornecedor/fornecedor_controller.dart';
import '../../../../controllers/tema/admin_theme.dart';
import '../../../../controllers/tema/event_theme_controller.dart';
import './../../../../core/utils/biblioteca.dart';
import '../../../widgets/admin/admin_kit.dart';
import './components/fornecedor_list_tile.dart';

class FornecedoresAdminListScreen extends StatefulWidget {
  const FornecedoresAdminListScreen({super.key});

  @override
  State<FornecedoresAdminListScreen> createState() => _FornecedoresAdminListScreenState();
}

class _FornecedoresAdminListScreenState extends State<FornecedoresAdminListScreen> {
  late final FornecedorController controller;
  final buscaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<FornecedorController>()
        ? Get.find<FornecedorController>()
        : Get.put(FornecedorController());
    buscaCtrl.text = controller.filtroNome.value;
    controller.carregarTodosFornecedores();
  }

  @override
  void dispose() {
    buscaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final bool isCelular = Biblioteca.isCelular(context);

    return Theme(
      data: theme.adminThemeData,
      child: Scaffold(
        backgroundColor: AdminPalette.surface,
        appBar: AdminBackAppBar(
          title: 'Gestão de Fornecedores',
          subtitle: 'Aprovação, catálogo e cobertura',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Atualizar lista',
              onPressed: controller.carregarTodosFornecedores,
            ),
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
              tooltip: 'Filtros',
              onPressed: () => _abrirFiltroBottomSheet(context, controller),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  AdminSearchField(
                    controller: buscaCtrl,
                    hint: 'Buscar por nome, e-mail ou descrição',
                    onChanged: (v) => controller.filtroNome.value = v,
                    onClear: () {
                      buscaCtrl.clear();
                      controller.filtroNome.value = '';
                    },
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          AdminSummaryChip(
                            label: 'Total',
                            value: '${controller.fornecedores.length}',
                            color: AdminPalette.primary,
                            icon: Icons.storefront_rounded,
                            onTap: () {
                              controller.filtroAprovado.value = null;
                              controller.filtroAtivo.value = null;
                            },
                          ),
                          const SizedBox(width: 8),
                          AdminSummaryChip(
                            label: 'Aptos',
                            value: '${controller.totalAptos}',
                            color: AdminPalette.success,
                            icon: Icons.verified_rounded,
                            onTap: () {
                              controller.filtroAtivo.value = true;
                              controller.filtroAprovado.value = true;
                            },
                          ),
                          const SizedBox(width: 8),
                          AdminSummaryChip(
                            label: 'Em análise',
                            value: '${controller.totalPendentes}',
                            color: AdminPalette.warning,
                            icon: Icons.pending_actions_rounded,
                            onTap: () {
                              controller.filtroAtivo.value = true;
                              controller.filtroAprovado.value = false;
                            },
                          ),
                          const SizedBox(width: 8),
                          AdminSummaryChip(
                            label: 'Inativos',
                            value: '${controller.totalInativos}',
                            color: AdminPalette.danger,
                            icon: Icons.block_rounded,
                            onTap: () {
                              controller.filtroAprovado.value = null;
                              controller.filtroAtivo.value = false;
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Obx(() {
                    return Row(
                      children: [
                        Icon(Icons.sort_rounded, color: AdminPalette.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Ordenar',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AdminPalette.ink,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AdminPalette.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: controller.ordenacaoSelecionada.value,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'status',
                                    child: Text('Status (aprovados primeiro)'),
                                  ),
                                  DropdownMenuItem(value: 'nome', child: Text('Nome A-Z')),
                                  DropdownMenuItem(
                                    value: 'recentes',
                                    child: Text('Mais recentes'),
                                  ),
                                ],
                                onChanged: (v) {
                                  controller.ordenacaoSelecionada.value = v!;
                                  controller.ordenarFornecedores();
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.carregando.value && controller.fornecedores.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.erro.isNotEmpty && controller.fornecedores.isEmpty) {
                  return AdminEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Falha ao carregar fornecedores',
                    message: controller.erro.value,
                    actionLabel: 'Tentar de novo',
                    onAction: controller.carregarTodosFornecedores,
                  );
                }

                final fornecedores = controller.fornecedoresFiltrados;
                if (fornecedores.isEmpty) {
                  return AdminEmptyState(
                    icon: Icons.store_mall_directory_outlined,
                    title: controller.fornecedores.isEmpty
                        ? 'Nenhum fornecedor cadastrado'
                        : 'Nenhum fornecedor neste filtro',
                    message: 'Ajuste a busca ou limpe os filtros para ver a base completa.',
                    actionLabel: 'Limpar filtros',
                    onAction: () {
                      buscaCtrl.clear();
                      controller.limparFiltros();
                    },
                  );
                }

                return RefreshIndicator(
                  color: AdminPalette.primary,
                  onRefresh: controller.carregarTodosFornecedores,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: fornecedores.length,
                    itemBuilder: (_, i) {
                      final f = fornecedores[i];
                      return FornecedorListTile(
                        fornecedor: f,
                        controller: controller,
                        isCelular: isCelular,
                        primary: AdminPalette.primary,
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirFiltroBottomSheet(
    BuildContext context,
    FornecedorController controller,
  ) async {
    final cidades = controller.enderecos
        .map((e) => e.nomeCidade ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    final categorias = controller.categoriasServico
        .where((c) => c['ativo'] != false)
        .map((c) => {'id': c['id'], 'nome': c['nome']})
        .toList();

    String cidadeSelecionada = controller.filtroCidade.value ?? '';
    String categoriaSelecionada = controller.filtroCategoria.value ?? '';
    String subcategoriaSelecionada = '';

    bool? aprovado = controller.filtroAprovado.value;
    bool? ativo = controller.filtroAtivo.value;

    final nomeCtrl = TextEditingController(text: controller.filtroNome.value);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          final subcategorias = controller.subcategoriasServico
              .where((s) => s['id_categoria'] == categoriaSelecionada)
              .map((s) => {'id': s['id'], 'nome': s['nome']})
              .toList();

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filtros de fornecedores',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nomeCtrl,
                    decoration: adminInputDecoration(
                      label: 'Buscar por nome',
                      icon: Icons.search,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: cidadeSelecionada.isEmpty ? null : cidadeSelecionada,
                    items: cidades.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => cidadeSelecionada = v ?? ''),
                    decoration: adminInputDecoration(
                      label: 'Cidade',
                      icon: Icons.location_city_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: categoriaSelecionada.isEmpty ? null : categoriaSelecionada,
                    items: categorias
                        .map((c) => DropdownMenuItem<String>(
                              value: c['id'] as String?,
                              child: Text(c['nome'] as String? ?? 'Sem nome'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => categoriaSelecionada = v ?? ''),
                    decoration: adminInputDecoration(
                      label: 'Categoria',
                      icon: Icons.category_outlined,
                    ),
                  ),
                  if (categoriaSelecionada.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: subcategoriaSelecionada.isEmpty ? null : subcategoriaSelecionada,
                      items: subcategorias
                          .map((s) => DropdownMenuItem<String>(
                                value: s['id'] as String?,
                                child: Text(s['nome'] as String? ?? ''),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => subcategoriaSelecionada = v ?? ''),
                      decoration: adminInputDecoration(
                        label: 'Subcategoria',
                        icon: Icons.label_important_outline_rounded,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: aprovado == null ? null : (aprovado! ? 'Aprovados' : 'Aguardando'),
                    items: const [
                      DropdownMenuItem(value: 'Aprovados', child: Text('Aprovados para operar')),
                      DropdownMenuItem(value: 'Aguardando', child: Text('Aguardando aprovação')),
                    ],
                    onChanged: (v) {
                      setState(() {
                        aprovado = v == null ? null : v == 'Aprovados';
                      });
                    },
                    decoration: adminInputDecoration(
                      label: 'Status de aprovação',
                      icon: Icons.verified_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: ativo == null ? null : (ativo! ? 'Ativos' : 'Desativados'),
                    items: const [
                      DropdownMenuItem(value: 'Ativos', child: Text('Ativos')),
                      DropdownMenuItem(value: 'Desativados', child: Text('Desativados')),
                    ],
                    onChanged: (v) {
                      setState(() {
                        ativo = v == null ? null : v == 'Ativos';
                      });
                    },
                    decoration: adminInputDecoration(
                      label: 'Status de atividade',
                      icon: Icons.power_settings_new_outlined,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all),
                        onPressed: () {
                          setState(() {
                            nomeCtrl.clear();
                            cidadeSelecionada = '';
                            categoriaSelecionada = '';
                            subcategoriaSelecionada = '';
                            aprovado = null;
                            ativo = null;
                          });
                          controller.limparFiltros();
                        },
                        label: const Text('Limpar'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: AdminPalette.primary),
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          controller.aplicarFiltros(
                            nome: nomeCtrl.text,
                            cidade: cidadeSelecionada,
                            categoria: subcategoriaSelecionada.isNotEmpty
                                ? subcategoriaSelecionada
                                : categoriaSelecionada,
                            aprovado: aprovado,
                            ativo: ativo,
                          );
                          buscaCtrl.text = nomeCtrl.text;
                          Navigator.pop(context);
                        },
                        label: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
