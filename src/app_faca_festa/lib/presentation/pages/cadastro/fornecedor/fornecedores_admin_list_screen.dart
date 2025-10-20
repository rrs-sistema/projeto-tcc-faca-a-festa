import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/event_theme_controller.dart';
import './../../../../controllers/fornecedor_controller.dart';
import './../../../../core/utils/biblioteca.dart';
import './components/fornecedor_list_tile.dart';

class FornecedoresAdminListScreen extends StatelessWidget {
  const FornecedoresAdminListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FornecedorController());
    final theme = Get.find<EventThemeController>();
    final bool isCelular = Biblioteca.isCelular(context);

    // 🔹 Carrega todos os fornecedores ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.carregarTodosFornecedores();
    });

    return Obx(() {
      final gradient = theme.gradient.value;

      return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              tooltip: 'Voltar',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'Gestão de Fornecedores',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
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
          backgroundColor: Colors.grey.shade100,
          body: Obx(() {
            final fornecedores = controller.fornecedoresFiltrados;
            final primary = theme.primaryColor.value;

            return Column(
              children: [
                // 🔹 Barra de ordenação
                Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sort_rounded, color: primary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Ordenar por:',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8), // 🔹 espaço de respiro
                        Flexible(
                          // ⬅️ permite o dropdown reduzir se faltar espaço
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primary.withValues(alpha: 0.3)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded:
                                    true, // ⬅️ faz o dropdown ocupar toda a largura disponível
                                value: controller.ordenacaoSelecionada.value,
                                icon: Icon(Icons.arrow_drop_down_rounded, color: primary, size: 26),
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'status',
                                    child: Row(
                                      children: [
                                        Icon(Icons.verified_rounded, color: Colors.green, size: 18),
                                        SizedBox(width: 6),
                                        Text('Status (aprovados primeiro)'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'nome',
                                    child: Row(
                                      children: [
                                        Icon(Icons.sort_by_alpha_rounded,
                                            color: Colors.indigo, size: 18),
                                        SizedBox(width: 6),
                                        Text('Nome A-Z'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'recentes',
                                    child: Row(
                                      children: [
                                        Icon(Icons.schedule_rounded,
                                            color: Colors.orange, size: 18),
                                        SizedBox(width: 6),
                                        Text('Mais recentes'),
                                      ],
                                    ),
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
                    )),

                const Divider(height: 1),

                // 🔹 Lista de fornecedores
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                    itemCount: fornecedores.length,
                    itemBuilder: (_, i) {
                      final f = fornecedores[i];
                      return FornecedorListTile(
                        fornecedor: f,
                        controller: controller,
                        isCelular: isCelular,
                        primary: primary,
                      );
                    },
                  ),
                ),
              ],
            );
          }));
    });
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
        .where((c) => c['ativo'] == true)
        .map((c) => {'id': c['id'], 'nome': c['nome']})
        .toList();

    // 🔹 Valores iniciais
    String cidadeSelecionada = controller.filtroCidade.value ?? '';
    String categoriaSelecionada = controller.filtroCategoria.value ?? '';
    String subcategoriaSelecionada = '';

    bool? aprovado = controller.filtroAprovado.value;
    bool? ativo = controller.filtroAtivo.value;

    final nomeCtrl = TextEditingController(text: controller.filtroNome.value);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          // 🔹 Subcategorias filtradas
          final subcategorias = controller.subcategoriasServico
              .where((s) => s['id_categoria'] == categoriaSelecionada)
              .map((s) => {'id': s['id'], 'nome': s['nome']})
              .toList();

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_alt_rounded, size: 36, color: Colors.deepPurple),
                  const SizedBox(height: 12),
                  Text(
                    'Filtros de Fornecedores',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Divider(),

                  // 🔹 Nome
                  TextField(
                    controller: nomeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Buscar por nome',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔹 Cidade
                  DropdownButtonFormField<String>(
                    value: cidadeSelecionada.isEmpty ? null : cidadeSelecionada,
                    items: cidades.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => cidadeSelecionada = v ?? ''),
                    decoration: const InputDecoration(
                      labelText: 'Cidade',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔹 Categoria principal
                  DropdownButtonFormField<String>(
                    value: categoriaSelecionada.isEmpty ? null : categoriaSelecionada,
                    items: categorias
                        .map((c) => DropdownMenuItem<String>(
                              value: c['id'] as String,
                              child: Text(c['nome'] as String? ?? 'Sem nome'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => categoriaSelecionada = v ?? ''),
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔹 Subcategoria (opcional)
                  if (categoriaSelecionada.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: subcategoriaSelecionada.isEmpty ? null : subcategoriaSelecionada,
                      items: subcategorias
                          .map((s) => DropdownMenuItem<String>(
                                value: s['id'] as String,
                                child: Text(s['nome'] as String? ?? ''),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => subcategoriaSelecionada = v ?? ''),
                      decoration: const InputDecoration(
                        labelText: 'Subcategoria',
                        prefixIcon: Icon(Icons.label_important_outline_rounded),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // 🔹 Status de aprovação
                  DropdownButtonFormField<String>(
                    value: aprovado == null ? null : (aprovado! ? 'Aprovados' : 'Aguardando'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Aprovados',
                        child: Text('Aprovados para operar'),
                      ),
                      DropdownMenuItem(
                        value: 'Aguardando',
                        child: Text('Aguardando aprovação'),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        if (v == null) {
                          aprovado = null;
                        } else {
                          aprovado = (v == 'Aprovados');
                        }
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Status de aprovação',
                      prefixIcon: Icon(Icons.verified_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔹 Status de atividade
                  DropdownButtonFormField<String>(
                    //value: ativo == null ? null : (ativo ?? false ? 'Ativos' : 'Desativados'),
                    value: ativo == null ? null : (ativo! ? 'Ativos' : 'Desativados'),
                    items: const [
                      DropdownMenuItem(value: 'Ativos', child: Text('Ativos')),
                      DropdownMenuItem(value: 'Desativados', child: Text('Desativados')),
                    ],
                    onChanged: (v) {
                      setState(() {
                        if (v == null) {
                          ativo = null;
                        } else {
                          ativo = (v == 'Ativos');
                        }
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Status de atividade',
                      prefixIcon: Icon(Icons.power_settings_new_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔹 Botões
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all),
                        onPressed: () {
                          setState(() {
                            // 🔹 Limpa os valores locais
                            nomeCtrl.clear();
                            cidadeSelecionada = '';
                            categoriaSelecionada = '';
                            subcategoriaSelecionada = '';
                            aprovado = null;
                            ativo = null;
                          });

                          // 🔹 Limpa também os filtros do controller (mantém sincronia)
                          controller.limparFiltros();
                        },
                        label: const Text('Limpar'),
                      ),
                      ElevatedButton.icon(
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
                          Navigator.pop(context);
                        },
                        label: const Text('Aplicar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
