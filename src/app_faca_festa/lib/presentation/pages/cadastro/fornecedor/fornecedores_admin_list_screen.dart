import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controllers/event_theme_controller.dart';
import '../../../../controllers/fornecedor_controller.dart';
import '../../../../core/utils/biblioteca.dart';
import '../../../../core/utils/no_sqflite_cache_manager.dart';
import '../servico/fornecedor_servico_list_screen.dart';

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
      final primary = theme.primaryColor.value;

      return Scaffold(
        appBar: AppBar(
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
        body: controller.carregando.value
            ? const Center(child: CircularProgressIndicator())
            : controller.fornecedoresFiltrados.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum fornecedor cadastrado',
                      style: GoogleFonts.poppins(color: Colors.grey.shade700),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 50), // ⬅️ espaço extra no fim
                    itemCount: controller.fornecedoresFiltrados.length,
                    itemBuilder: (_, i) {
                      final f = controller.fornecedoresFiltrados[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: isCelular ? 70 : 100, // ✅ tamanho fixo horizontal
                              height: isCelular ? 70 : 100, // ✅ tamanho fixo vertical
                              child: f.bannerUrl != null && f.bannerUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: f.bannerUrl!,
                                      cacheManager: AdaptiveCacheManager.instance,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          Container(color: Colors.grey.shade300),
                                      errorWidget: (_, __, ___) => _bannerPlaceholder(primary),
                                      memCacheHeight: 250,
                                      memCacheWidth: 250,
                                      fadeInDuration: const Duration(milliseconds: 250),
                                    )
                                  : _bannerPlaceholder(primary),
                            ),
                          ),
                          title: Text(
                            f.razaoSocial,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                f.descricao ?? '',
                                style:
                                    GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.email_outlined, size: 15, color: primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      f.email,
                                      style: GoogleFonts.poppins(
                                          fontSize: 12, color: Colors.grey.shade600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Wrap(
                            direction: Axis.vertical,
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            children: [
                              if (f.aptoParaOperar)
                                Icon(Icons.verified_rounded, color: Colors.green.shade600, size: 26)
                              else
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline,
                                      color: Colors.blue, size: 28),
                                  tooltip: 'Aprovar fornecedor',
                                  onPressed: () => controller.aprovarFornecedor(f.idFornecedor),
                                ),
                              IconButton(
                                icon: const Icon(Icons.design_services_outlined,
                                    color: Colors.orange, size: 22),
                                tooltip: 'Ver serviços',
                                onPressed: () =>
                                    Get.to(() => FornecedorServicoListScreen(fornecedor: f)),
                              ),
                            ],
                          ),
                          onLongPress: () => _confirmarDesativacao(
                              context, controller, f.idFornecedor, f.razaoSocial),
                        ),
                      );
                    },
                  ),
      );
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

    final categorias = controller.categoriasFornecedor.map((c) => c.idCategoria).toSet().toList();

    String cidadeSelecionada = controller.filtroCidade.value ?? '';
    String categoriaSelecionada = controller.filtroCategoria.value ?? '';

    bool? apenasAprovados = controller.filtroAprovado.value;
    final nomeCtrl = TextEditingController(text: controller.filtroNome.value);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_alt_rounded, size: 36, color: Colors.deepPurple),
              const SizedBox(height: 12),
              Text('Filtros de Fornecedores',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(),
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Buscar por nome',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: cidadeSelecionada.isEmpty ? null : cidadeSelecionada,
                items: cidades.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => cidadeSelecionada = v ?? '',
                decoration: const InputDecoration(
                  labelText: 'Cidade',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: categoriaSelecionada.isEmpty ? null : categoriaSelecionada,
                items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => categoriaSelecionada = v ?? '',
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Somente aprovados'),
                value: apenasAprovados ?? false,
                onChanged: (v) => apenasAprovados = v,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all),
                    onPressed: () {
                      controller.limparFiltros();
                      Navigator.pop(context);
                    },
                    label: const Text('Limpar'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      controller.aplicarFiltros(
                        nome: nomeCtrl.text,
                        cidade: cidadeSelecionada,
                        categoria: categoriaSelecionada,
                        aprovado: apenasAprovados,
                      );
                      Navigator.pop(context);
                    },
                    label: const Text('Aplicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarDesativacao(
    BuildContext context,
    FornecedorController controller,
    String idFornecedor,
    String nome,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desativar fornecedor'),
        content: Text(
          'Deseja realmente desativar "$nome"?',
          style: GoogleFonts.poppins(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await controller.desativarFornecedor(idFornecedor);
    }
  }

  // 🔸 Placeholder elegante e leve
  Widget _bannerPlaceholder(Color primary) {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.3),
            primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_rounded, color: Colors.white54, size: 32),
      ),
    );
  }
}
