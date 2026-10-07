import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './components/categoria_subcategoria_servico_section.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/register_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/widgets/auth_festa_brand.dart';
import 'package:app_faca_festa/presentation/widgets/cadastro_passos_bar.dart';
import 'package:app_faca_festa/presentation/widgets/custom_input_field.dart';
import 'package:app_faca_festa/presentation/modules/legal/widgets/aceite_privacidade_tile.dart';
import 'package:app_faca_festa/presentation/modules/legal/widgets/direito_imagem_dialog.dart';
import 'package:app_faca_festa/presentation/modules/usuario/components/endereco/endereco_section.dart';

class RegisterFornecedorForm extends StatefulWidget {
  final RegisterController controller;
  final FornecedorController fornecedorController;
  final ImagePicker picker;
  final Uint8List? bannerBytes;
  final Future<void> Function(XFile arquivo, Uint8List bytes) onBannerSelected;
  final Color primary;
  final CategoriaServicoController categoriaController;
  final SubcategoriaServicoController subcategoriaController;
  final ServicoProdutoController servicoController;

  const RegisterFornecedorForm({
    super.key,
    required this.controller,
    required this.fornecedorController,
    required this.picker,
    required this.bannerBytes,
    required this.onBannerSelected,
    required this.primary,
    required this.categoriaController,
    required this.subcategoriaController,
    required this.servicoController,
  });

  @override
  State<RegisterFornecedorForm> createState() => _RegisterFornecedorFormState();
}

class _RegisterFornecedorFormState extends State<RegisterFornecedorForm> {
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;
  var _cadastroGoogle = false;
  var _passo = 0;
  var _aceitePrivacidade = false;

  static const _titulosPassos = ['Você', 'Empresa', 'Endereço', 'Atuação'];

  late final TextEditingController nomeCtrl;
  late final TextEditingController razaoCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController senhaCtrl;
  late final TextEditingController cnpjCtrl;
  late final TextEditingController telefoneCtrl;
  late final TextEditingController descCtrl;

  final List<_TipoEventoCadastro> _tiposEventoSelecionados =
      <_TipoEventoCadastro>[];

  static const List<_TipoEventoCadastro> _tiposEventoDisponiveis = [
    _TipoEventoCadastro(
      id: '1eab2c53-a7d3-4a97-b473-02572464e779',
      slug: 'cha_de_bebe',
      nome: 'Chá de Bebê',
      titulo: 'Chá de Bebê',
      icon: Icons.child_care_rounded,
    ),
    _TipoEventoCadastro(
      id: '7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda',
      slug: 'aniversario',
      nome: 'Aniversário',
      titulo: 'Aniversário',
      icon: Icons.cake_rounded,
    ),
    _TipoEventoCadastro(
      id: 'ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8',
      slug: 'festa_infantil',
      nome: 'Festa Infantil',
      titulo: 'Festa Infantil',
      icon: Icons.toys_rounded,
    ),
    _TipoEventoCadastro(
      id: 'WlLdfdmu4Chvw2p8daUm',
      slug: 'formatura',
      nome: 'Formatura',
      titulo: 'Formatura',
      icon: Icons.school_rounded,
    ),
    _TipoEventoCadastro(
      id: '302191a2-dbf3-4ac6-ba53-08273b384cab',
      slug: 'casamento',
      nome: 'Casamento',
      titulo: 'Casamento',
      icon: Icons.favorite_rounded,
    ),
    _TipoEventoCadastro(
      id: 'lXf0M5vMNvyRn52yQ2fY',
      slug: 'evento_corporativo',
      nome: 'Evento Corporativo',
      titulo: 'Evento Corporativo',
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

  Future<void> _cadastrar({required bool comGoogle}) async {
    setState(() {
      _cadastroGoogle = comGoogle;
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_aceitePrivacidade) return;

    final controller = widget.controller;
    controller.aceitePrivacidade.value = true;
    _aplicarTiposEventoNoController(controller);
    controller.bannerBytes = widget.bannerBytes;

    if (comGoogle) {
      await controller.registrarComGoogle();
      return;
    }

    await controller.registrarUsuario();
  }

  void _avancar() {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _autovalidateMode = AutovalidateMode.disabled;
      _passo++;
    });
  }

  void _continuarComGoogle() {
    _cadastroGoogle = true;
    _avancar();
  }

  void _voltar() {
    if (_passo == 0) return;
    setState(() {
      _autovalidateMode = AutovalidateMode.disabled;
      _passo--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    final controller = widget.controller;

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CadastroPassosBar(
            atual: _passo,
            titulos: _titulosPassos,
            cor: primary,
          ),
          if (_passo == 0) ..._passoConta(primary, controller),
          if (_passo == 1) ..._passoEmpresa(primary, controller),
          if (_passo == 2) ..._passoEndereco(primary, controller),
          if (_passo == 3) ..._passoAtuacao(primary, controller),
          if (_passo == 3) ...[
            const SizedBox(height: 12),
            AceitePrivacidadeTile(
              aceito: _aceitePrivacidade,
              cor: primary,
              onChanged: (valor) {
                setState(() => _aceitePrivacidade = valor);
                controller.aceitePrivacidade.value = valor;
              },
            ),
          ],
          const SizedBox(height: 20),
          Obx(
            () => CadastroPassosAcoes(
              cor: primary,
              continuarLabel: _passo == 3 ? 'Cadastrar' : 'Continuar',
              habilitado: _passo < 3 || _aceitePrivacidade,
              onContinuar: _passo == 3
                  ? () => _cadastrar(comGoogle: _cadastroGoogle)
                  : _avancar,
              onVoltar: _passo == 0 ? null : _voltar,
              carregando: controller.carregando.value,
            ),
          ),
          if (_passo == 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ou',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade200)),
              ],
            ),
            const SizedBox(height: 16),
            Obx(
              () => AuthFestaGoogleButton(
                label: 'Continuar com Google',
                onPressed: controller.carregando.value
                    ? null
                    : _continuarComGoogle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _passoConta(Color primary, RegisterController controller) => [
        CustomInputField(
          label: 'Nome do responsável',
          hintlabel: 'Informe o nome do responsável',
          icon: Icons.person_outline,
          controller: nomeCtrl,
          color: primary,
          isRequired: true,
          textInputAction: TextInputAction.next,
          validator: (v) => FormValidators.nomeCompleto(
            v,
            campo: 'o nome completo do responsável',
          ),
          onChanged: (v) => controller.nome.value = v,
        ),
        const SizedBox(height: 10),
        CustomInputField(
          label: 'E-mail comercial',
          hintlabel: 'Informe um e-mail comercial',
          icon: Icons.email_outlined,
          controller: emailCtrl,
          color: primary,
          type: InputType.email,
          isRequired: !_cadastroGoogle,
          textInputAction: TextInputAction.next,
          validator: (v) => FormValidators.email(
            v,
            obrigatorio: !_cadastroGoogle,
          ),
          onChanged: (v) => controller.email.value = v,
        ),
        const SizedBox(height: 10),
        CustomInputField(
          label: 'Senha',
          hintlabel: 'Mínimo 6 caracteres, com letra e número',
          icon: Icons.lock_outline,
          controller: senhaCtrl,
          color: primary,
          type: InputType.password,
          isRequired: !_cadastroGoogle,
          textInputAction: TextInputAction.next,
          validator: (v) => FormValidators.senha(
            v,
            obrigatorio: !_cadastroGoogle,
          ),
          onChanged: (v) => controller.senha.value = v,
        ),
        const SizedBox(height: 10),
        CustomInputField(
          label: 'Telefone',
          hintlabel: 'Com DDD',
          icon: Icons.phone_outlined,
          controller: telefoneCtrl,
          type: InputType.phone,
          isRequired: true,
          textInputAction: TextInputAction.done,
          validator: FormValidators.telefone,
          onFieldSubmitted: (_) => _avancar(),
          color: primary,
          onChanged: (v) =>
              controller.telefone.value = FormValidators.somenteDigitos(v),
        ),
      ];

  List<Widget> _passoEmpresa(Color primary, RegisterController controller) => [
        CustomInputField(
          label: 'Razão social',
          hintlabel: 'Informe a razão social',
          icon: Icons.business_outlined,
          controller: razaoCtrl,
          color: primary,
          isRequired: true,
          validator: FormValidators.razaoSocial,
          onChanged: (v) => controller.razaoSocial.value = v,
        ),
        const SizedBox(height: 10),
        CustomInputField(
          label: 'CNPJ',
          hintlabel: '00.000.000/0000-00',
          icon: Icons.badge_outlined,
          controller: cnpjCtrl,
          color: primary,
          type: InputType.cnpj,
          isRequired: true,
          validator: FormValidators.cnpj,
          onChanged: (v) =>
              controller.cnpj.value = FormValidators.somenteDigitos(v),
        ),
        const SizedBox(height: 10),
        _uploadBanner(primary),
        const SizedBox(height: 10),
        CustomInputField(
          label: 'Descrição dos serviços (opcional)',
          hintlabel: 'Se informar, use pelo menos 10 caracteres',
          icon: Icons.description_outlined,
          controller: descCtrl,
          color: primary,
          maxLength: 200,
          maxLines: 3,
          validator: FormValidators.descricaoServicos,
          onChanged: (v) => controller.descricao.value = v,
        ),
      ];

  List<Widget> _passoEndereco(
    Color primary,
    RegisterController controller,
  ) =>
      [
        EnderecoSection(
          cor: primary,
          controller: controller.enderecoController.value,
          titulo: 'Endereço de atendimento',
        ),
      ];

  List<Widget> _passoAtuacao(
    Color primary,
    RegisterController controller,
  ) =>
      [
        CategoriaSubcategoriaServicoSection(
          controller: controller,
          primary: primary,
          categoriaController: widget.categoriaController,
          subcategoriaController: widget.subcategoriaController,
          servicoController: widget.servicoController,
        ),
        const SizedBox(height: 20),
        _tiposEventoSection(primary),
      ];

  Widget _uploadBanner(Color color) => GestureDetector(
        onTap: () async {
          final autorizado = await confirmarDireitoImagem();
          if (!autorizado) return;
          final picked = await widget.picker.pickImage(
            source: ImageSource.gallery,
          );
          if (picked != null) {
            final bytes = await picked.readAsBytes();
            await widget.onBannerSelected(picked, bytes);
          }
        },
        child: Container(
          width: double.infinity,
          height: widget.bannerBytes == null ? null : 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              style: widget.bannerBytes == null
                  ? BorderStyle.solid
                  : BorderStyle.none,
            ),
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.9),
            image: widget.bannerBytes != null
                ? DecorationImage(
                    image: MemoryImage(widget.bannerBytes!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.4),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          padding: widget.bannerBytes == null
              ? const EdgeInsets.all(16)
              : EdgeInsets.zero,
          child: widget.bannerBytes == null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, color: color),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Selecionar logo/banner (opcional)',
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
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 28),
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
    return FormField<List<_TipoEventoCadastro>>(
      validator: (_) => FormValidators.selecao(
        _tiposEventoSelecionados,
        campo: 'pelo menos um tipo de evento atendido',
      ),
      builder: (state) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: state.hasError
                  ? Colors.redAccent.withValues(alpha: 0.85)
                  : const Color(0xFFF0E6EC),
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
                      'Tipos de evento atendidos *',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Em quais festas você costuma trabalhar?',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: const Color(0xFF6B7280),
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
                          : Colors.grey.shade200,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    onSelected: (_) {
                      _alternarTipoEvento(tipo);
                      state.didChange(_tiposEventoSelecionados);
                    },
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
              if (state.hasError) ...[
                const SizedBox(height: 10),
                Text(
                  state.errorText!,
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
