import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';

import './components/categoria_subcategoria_servico_section.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import '../../../controllers/fornecedor/fornecedor_controller.dart';
import './../../../controllers/register_controller.dart';
import './../../widgets/primary_action_button.dart';
import './../../widgets/custom_input_field.dart';
import './../endereco/endereco_section.dart';

class RegisterFornecedorForm extends StatefulWidget {
  final RegisterController controller;
  final FornecedorController fornecedorController;
  final ImagePicker picker;
  final File? bannerFile;
  final Function(File) onImageSelected;

  const RegisterFornecedorForm({
    super.key,
    required this.controller,
    required this.fornecedorController,
    required this.picker,
    required this.bannerFile,
    required this.onImageSelected,
  });

  @override
  State<RegisterFornecedorForm> createState() => _RegisterFornecedorFormState();
}

class _RegisterFornecedorFormState extends State<RegisterFornecedorForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nomeCtrl;
  late final TextEditingController razaoCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController senhaCtrl;
  late final TextEditingController cnpjCtrl;
  late final TextEditingController telefoneCtrl;
  late final TextEditingController descCtrl;

  final List<_TipoEventoCadastro> _tiposEventoSelecionados = <_TipoEventoCadastro>[];

  static const List<_TipoEventoCadastro> _tiposEventoDisponiveis = [
    _TipoEventoCadastro(
      id: '1eab2c53-a7d3-4a97-b473-02572464e779',
      slug: 'cha_de_bebe',
      nome: 'Chá de Bebê',
      titulo: '🍼 Chá de Bebê',
      icon: Icons.child_care_rounded,
    ),
    _TipoEventoCadastro(
      id: '7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda',
      slug: 'aniversario',
      nome: 'Aniversário',
      titulo: '🎂 Aniversário',
      icon: Icons.cake_rounded,
    ),
    _TipoEventoCadastro(
      id: 'ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8',
      slug: 'festa_infantil',
      nome: 'Festa Infantil',
      titulo: '🎈 Festa Infantil',
      icon: Icons.toys_rounded,
    ),
    _TipoEventoCadastro(
      id: 'WlLdfdmu4Chvw2p8daUm',
      slug: 'formatura',
      nome: 'Formatura',
      titulo: '🎓 Formatura',
      icon: Icons.school_rounded,
    ),
    _TipoEventoCadastro(
      id: '302191a2-dbf3-4ac6-ba53-08273b384cab',
      slug: 'casamento',
      nome: 'Casamento',
      titulo: '💍 Casamento',
      icon: Icons.favorite_rounded,
    ),
    _TipoEventoCadastro(
      id: 'lXf0M5vMNvyRn52yQ2fY',
      slug: 'evento_corporativo',
      nome: 'Evento Corporativo',
      titulo: '💼 Evento Corporativo',
      icon: Icons.business_center_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    nomeCtrl = TextEditingController();
    razaoCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    senhaCtrl = TextEditingController();
    cnpjCtrl = TextEditingController();
    telefoneCtrl = TextEditingController();
    descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    nomeCtrl.dispose();
    razaoCtrl.dispose();
    emailCtrl.dispose();
    senhaCtrl.dispose();
    cnpjCtrl.dispose();
    telefoneCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final primary = theme.primaryColor.value;
    final controller = widget.controller;
    final fornecedorController = widget.fornecedorController;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _camposBasicos(primary, controller),
          const SizedBox(height: 10),
          _uploadBanner(primary),
          const SizedBox(height: 10),
          EnderecoSection(
            cor: primary,
            controller: controller.enderecoController.value,
            titulo: 'Dados de endereço',
          ),
          const SizedBox(height: 20),
          CategoriaSubcategoriaServicoSection(
            controller: controller,
            primary: primary,
          ),
          const SizedBox(height: 20),
          _tiposEventoSection(primary),
          const SizedBox(height: 20),
          PrimaryActionButton(
            label: 'Cadastrar',
            color: primary,
            carregando: controller.carregando,
            onPressed: () async {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              if (!_validarTiposEvento()) return;

              _aplicarTiposEventoNoController(controller);

              if (widget.bannerFile != null) {
                controller.bannerUrl = await fornecedorController.uploadBanner(widget.bannerFile!);
              }

              await controller.registrarUsuario();
            },
          ),
          const SizedBox(height: 20),
          PrimaryActionButton(
            label: 'Cancelar/Sair',
            color: Colors.grey,
            carregando: controller.carregando,
            icon: Icons.close,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _camposBasicos(Color primary, RegisterController controller) => Column(
        children: [
          CustomInputField(
            label: 'Nome do responsável',
            hintlabel: 'Informe o nome do responsável',
            icon: Icons.person_outline,
            controller: nomeCtrl,
            color: primary,
            isRequired: true,
            onChanged: (v) => controller.nome.value = v,
          ),
          const SizedBox(height: 10),
          CustomInputField(
            label: 'Razão social',
            hintlabel: 'Informe a razão social',
            icon: Icons.business_outlined,
            controller: razaoCtrl,
            color: primary,
            isRequired: true,
            onChanged: (v) => controller.razaoSocial.value = v,
          ),
          const SizedBox(height: 10),
          CustomInputField(
            label: 'E-mail comercial',
            hintlabel: 'Informe um e-mail comercial',
            icon: Icons.email_outlined,
            controller: emailCtrl,
            color: primary,
            type: InputType.email,
            isRequired: true,
            onChanged: (v) => controller.email.value = v,
          ),
          const SizedBox(height: 10),
          Obx(
            () => CustomInputField(
              label: 'Senha',
              hintlabel: 'Informe a senha',
              icon: Icons.lock_outline,
              controller: senhaCtrl,
              color: primary,
              type: InputType.password,
              isRequired: true,
              obscureText: !controller.exibirSenha.value,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.exibirSenha.value ? Icons.visibility_off : Icons.visibility,
                  color: primary.withValues(alpha: 0.8),
                ),
                onPressed: () => controller.exibirSenha.toggle(),
              ),
              onChanged: (v) => controller.senha.value = v,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomInputField(
                  label: 'CNPJ',
                  hintlabel: 'Somente números',
                  icon: Icons.badge_outlined,
                  controller: cnpjCtrl,
                  color: primary,
                  type: InputType.cpfCnpj,
                  // Remove a máscara na hora de salvar, pegando apenas os dígitos
                  onChanged: (v) => controller.cnpj.value = v.replaceAll(RegExp(r'\D'), ''),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomInputField(
                  label: 'Telefone',
                  hintlabel: 'Com DDD',
                  icon: Icons.phone_outlined,
                  controller: telefoneCtrl,
                  type: InputType.phone,
                  isRequired: true,
                  color: primary,
                  // Remove a máscara na hora de salvar, pegando apenas os dígitos
                  onChanged: (v) => controller.telefone.value = v.replaceAll(RegExp(r'\D'), ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomInputField(
            label: 'Descrição dos serviços',
            hintlabel: 'Informe quais serviços você fornece',
            icon: Icons.description_outlined,
            controller: descCtrl,
            color: primary,
            maxLength: 200,
            maxLines: 3,
          ),
        ],
      );

  Widget _uploadBanner(Color color) => GestureDetector(
        onTap: () async {
          final picked = await widget.picker.pickImage(
            source: ImageSource.gallery,
          );
          if (picked != null) widget.onImageSelected(File(picked.path));
        },
        child: Container(
          width: double.infinity,
          height: widget.bannerFile == null ? null : 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              style: widget.bannerFile == null ? BorderStyle.solid : BorderStyle.none,
            ),
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.9),
            image: widget.bannerFile != null
                ? DecorationImage(
                    image: FileImage(widget.bannerFile!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.4),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          padding: widget.bannerFile == null ? const EdgeInsets.all(16) : EdgeInsets.zero,
          child: widget.bannerFile == null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, color: color),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Selecionar logo/banner',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Trocar Imagem',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );

  Widget _tiposEventoSection(Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tipos de evento atendidos',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildIaBadge(primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione os eventos em que este fornecedor costuma atuar. '
            'Esses dados serão usados pela IA para recomendar fornecedores mais compatíveis.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tiposEventoDisponiveis.map((tipo) {
              final selected = _tiposEventoSelecionados.any(
                (item) => item.id == tipo.id,
              );

              return FilterChip(
                selected: selected,
                showCheckmark: false,
                avatar: Icon(
                  selected ? Icons.check_circle_rounded : tipo.icon,
                  size: 18,
                  color: selected ? Colors.white : primary,
                ),
                label: Text(tipo.titulo),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey.shade800,
                ),
                selectedColor: primary,
                backgroundColor: Colors.white.withValues(alpha: 0.92),
                side: BorderSide(
                  color: selected
                      ? primary.withValues(alpha: 0.0)
                      : Colors.white.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                onSelected: (_) => _alternarTipoEvento(tipo),
              );
            }).toList(),
          ),
          if (_tiposEventoSelecionados.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${_tiposEventoSelecionados.length} tipo(s) selecionado(s)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIaBadge(Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: primary.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology_rounded,
            color: primary,
            size: 15,
          ),
          const SizedBox(width: 4),
          Text(
            'IA',
            style: GoogleFonts.poppins(
              color: primary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _alternarTipoEvento(_TipoEventoCadastro tipo) {
    setState(() {
      final jaSelecionado = _tiposEventoSelecionados.any(
        (item) => item.id == tipo.id,
      );

      if (jaSelecionado) {
        _tiposEventoSelecionados.removeWhere((item) => item.id == tipo.id);
      } else {
        _tiposEventoSelecionados.add(tipo);
      }
    });
  }

  bool _validarTiposEvento() {
    if (_tiposEventoSelecionados.isNotEmpty) {
      return true;
    }

    Get.snackbar(
      'Tipos de evento',
      'Selecione pelo menos um tipo de evento atendido pelo fornecedor.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(14),
      borderRadius: 14,
      icon: const Icon(
        Icons.event_busy_rounded,
        color: Colors.white,
      ),
    );

    return false;
  }

  void _aplicarTiposEventoNoController(RegisterController controller) {
    final dynamic c = controller;

    final ids = _tiposEventoSelecionados.map((item) => item.id).toList();
    final slugs = _tiposEventoSelecionados.map((item) => item.slug).toList();
    final nomes = _tiposEventoSelecionados
        .expand((item) => <String>[item.nome, item.titulo])
        .toSet()
        .toList();

    bool aplicado = false;

    try {
      c.tipoEventoIds.assignAll(ids);
      aplicado = true;
    } catch (_) {}
    try {
      c.tipoEventoIds.value = ids;
      aplicado = true;
    } catch (_) {}
    try {
      c.tipoEventoIds = ids;
      aplicado = true;
    } catch (_) {}

    try {
      c.tipoEventoSlugs.assignAll(slugs);
      aplicado = true;
    } catch (_) {}
    try {
      c.tipoEventoSlugs.value = slugs;
      aplicado = true;
    } catch (_) {}
    try {
      c.tipoEventoSlugs = slugs;
      aplicado = true;
    } catch (_) {}

    try {
      c.tipoEventoNomes.assignAll(nomes);
      aplicado = true;
    } catch (_) {}
    try {
      c.tipoEventoNomes.value = nomes;
      aplicado = true;
    } catch (_) {}
    try {
      c.tipoEventoNomes = nomes;
      aplicado = true;
    } catch (_) {}

    if (!aplicado) {
      debugPrint(
        '⚠️ [RegisterFornecedorForm] Tipos de evento selecionados, '
        'mas o RegisterController ainda não possui os campos '
        'tipoEventoIds, tipoEventoSlugs e tipoEventoNomes.',
      );
    } else {
      debugPrint(
        '✅ [RegisterFornecedorForm] Tipos de evento aplicados ao controller | '
        'ids=$ids | slugs=$slugs | nomes=$nomes',
      );
    }
  }
}

class _TipoEventoCadastro {
  final String id;
  final String slug;
  final String nome;
  final String titulo;
  final IconData icon;

  const _TipoEventoCadastro({
    required this.id,
    required this.slug,
    required this.nome,
    required this.titulo,
    required this.icon,
  });
}
