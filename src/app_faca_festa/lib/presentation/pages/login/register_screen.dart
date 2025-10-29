import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../controllers/categoria/categoria_servico_controller.dart';
import '../../../controllers/categoria/subcategoria_servico_controller.dart';
import '../../../controllers/event_theme_controller.dart';
import '../../../controllers/fornecedor_controller.dart';
import '../../../controllers/register_controller.dart';
import '../../widgets/custom_input_field.dart';
import '../endereco/endereco_section.dart';
import '../login/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final controller = Get.put(RegisterController());
  final fornecedorController = Get.put(FornecedorController());
  final picker = ImagePicker();
  File? bannerFile;

  @override
  Widget build(BuildContext context) {
    final tipo = (Get.arguments?['tipo'] ?? 'O') as String;
    final isFornecedor = tipo == 'F';
    final theme = Get.find<EventThemeController>();
    final primary = theme.primaryColor.value;

    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Fundo
          Container(color: Colors.white.withValues(alpha: 0.1)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    isFornecedor ? 'Cadastro de Fornecedor' : 'Criar Conta',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Campos padrão
                  CustomInputField(
                    label: 'Nome completo',
                    icon: Icons.person_outline,
                    controller: TextEditingController(),
                    color: primary,
                    onChanged: (v) => controller.nome.value = v,
                  ),
                  CustomInputField(
                    label: 'Email',
                    icon: Icons.email_outlined,
                    controller: TextEditingController(),
                    color: primary,
                    onChanged: (v) => controller.email.value = v,
                  ),
                  Obx(() => CustomInputField(
                        label: 'Senha',
                        icon: Icons.lock_outline,
                        controller: TextEditingController(),
                        color: primary,
                        obscureText: !controller.exibirSenha.value,
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.exibirSenha.value ? Icons.visibility_off : Icons.visibility,
                            color: primary,
                          ),
                          onPressed: () => controller.exibirSenha.toggle(),
                        ),
                        onChanged: (v) => controller.senha.value = v,
                      )),

                  // 🔹 Campos adicionais (Fornecedor)
                  if (isFornecedor) ...[
                    CustomInputField(
                      label: 'CNPJ',
                      icon: Icons.badge_outlined,
                      controller: TextEditingController(),
                      color: primary,
                      onChanged: (v) => controller.cnpj.value = v,
                    ),
                    CustomInputField(
                      label: 'Telefone comercial',
                      icon: Icons.phone_outlined,
                      controller: TextEditingController(),
                      color: primary,
                      onChanged: (v) => controller.telefone.value = v,
                    ),
                    CustomInputField(
                      label: 'Descrição do serviço ou empresa',
                      icon: Icons.description_outlined,
                      controller: TextEditingController(),
                      color: primary,
                      maxLength: 200,
                      onChanged: (_) {},
                    ),

                    // 🌟 Categorias e subcategorias
                    Obx(() {
                      final categoriaController = Get.find<CategoriaServicoController>();
                      final subcategoriaController = Get.find<SubcategoriaServicoController>();
                      final selecionadas = controller.categoriasSelecionadas;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Áreas de atuação',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 🧩 Categorias
                          SizedBox(
                            height: 48,
                            child: _HorizontalScrollCategorias(
                              categorias: categoriaController.categorias,
                              selecionadas: selecionadas,
                              primary: primary,
                              onToggle: (cat) {
                                final selecionada =
                                    selecionadas.any((c) => c.idCategoria == cat.id);
                                if (selecionada) {
                                  selecionadas.removeWhere((c) => c.idCategoria == cat.id);
                                } else {
                                  controller.adicionarCategoria(cat);
                                  subcategoriaController.carregarSubcategoriasPorCategoria(cat.id);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 💠 Subcategorias
                          if (selecionadas.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: selecionadas.map((catSel) {
                                final subcats = subcategoriaController
                                        .subcategoriasPorCategoria[catSel.idCategoria] ??
                                    [];

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      child: Text(
                                        catSel.nomeCategoria ?? 'Subcategorias',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: primary,
                                        ),
                                      ),
                                    ),
                                    if (subcats.isNotEmpty)
                                      SizedBox(
                                        height: 52,
                                        child: _HorizontalScrollChips(
                                          subcats: subcats,
                                          catSel: catSel,
                                          primary: primary,
                                          onToggle: (sub, v) =>
                                              controller.alternarSubcategoria(catSel, sub, v),
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.only(left: 6, top: 4),
                                        child: Text(
                                          'Nenhuma subcategoria cadastrada.',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey.shade500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                  ],
                                );
                              }).toList(),
                            ),
                        ],
                      );
                    }),
                    const SizedBox(height: 30),

                    // 🔹 Upload de imagem
                    GestureDetector(
                      onTap: _selecionarImagem,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: primary.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined, color: primary, size: 26),
                            const SizedBox(width: 12),
                            Text(
                              bannerFile == null
                                  ? 'Selecionar logo/banner'
                                  : 'Imagem selecionada ✔',
                              style: GoogleFonts.poppins(
                                color: primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 🔹 Endereço
                  EnderecoSection(
                    cor: primary,
                    controller: controller.enderecoController.value,
                    titulo: isFornecedor ? 'Endereço do Fornecedor' : 'Endereço do Usuário',
                  ),
                  const SizedBox(height: 30),

                  // 🔹 Botão principal
                  Obx(() => ElevatedButton.icon(
                        icon: controller.carregando.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          controller.carregando.value ? 'Cadastrando...' : 'Cadastrar',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                        ),
                        onPressed: controller.carregando.value
                            ? null
                            : () async {
                                await controller.registrarUsuario();
                                if (bannerFile != null && isFornecedor) {
                                  await fornecedorController.uploadBanner(bannerFile!);
                                }
                              },
                      )),
                  const SizedBox(height: 24),

                  // 🔹 Link para login
                  GestureDetector(
                    onTap: () => Get.off(() => const LoginScreen()),
                    child: Text.rich(
                      TextSpan(
                        text: "Já tem conta? ",
                        style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
                        children: [
                          TextSpan(
                            text: "Entrar",
                            style: GoogleFonts.poppins(
                              color: primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    '💡 Faça a Festa por Stephanie Schor',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: primary.withValues(alpha: 0.8),
                      letterSpacing: 0.3,
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

  Future<void> _selecionarImagem() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => bannerFile = File(picked.path));
  }
}

class _HorizontalScrollCategorias extends StatefulWidget {
  final List categorias;
  final List selecionadas;
  final Color primary;
  final void Function(dynamic cat) onToggle;

  const _HorizontalScrollCategorias({
    required this.categorias,
    required this.selecionadas,
    required this.primary,
    required this.onToggle,
  });

  @override
  State<_HorizontalScrollCategorias> createState() => _HorizontalScrollCategoriasState();
}

class _HorizontalScrollCategoriasState extends State<_HorizontalScrollCategorias> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      radius: const Radius.circular(20),
      thickness: 8,
      interactive: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: widget.categorias.map((cat) {
            final selecionada = widget.selecionadas.any((c) => c.idCategoria == cat.id);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: selecionada
                      ? LinearGradient(
                          colors: [
                            primary.withValues(alpha: 0.9),
                            primary.withValues(alpha: 0.6),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.grey.shade200,
                            Colors.grey.shade100,
                          ],
                        ),
                  boxShadow: selecionada
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => widget.onToggle(cat),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selecionada ? Icons.check_circle : Icons.category_outlined,
                          size: 18,
                          color: selecionada ? Colors.white : primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat.nome,
                          style: GoogleFonts.poppins(
                            color: selecionada ? Colors.white : Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _HorizontalScrollChips extends StatefulWidget {
  final List subcats;
  final dynamic catSel;
  final Color primary;
  final void Function(dynamic sub, bool selected) onToggle;

  const _HorizontalScrollChips({
    required this.subcats,
    required this.catSel,
    required this.primary,
    required this.onToggle,
  });

  @override
  State<_HorizontalScrollChips> createState() => _HorizontalScrollChipsState();
}

class _HorizontalScrollChipsState extends State<_HorizontalScrollChips> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 6,
      radius: const Radius.circular(12),
      interactive: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: widget.subcats.map((sub) {
            final selecionada =
                widget.catSel.subcategorias.any((s) => s['idSubcategoria'] == sub.id);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(sub.nome),
                labelStyle: GoogleFonts.poppins(
                  color: selecionada ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: Colors.grey.shade100,
                selectedColor: widget.primary.withValues(alpha: 0.85),
                checkmarkColor: Colors.white,
                selected: selecionada,
                onSelected: (v) => widget.onToggle(sub, v),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
