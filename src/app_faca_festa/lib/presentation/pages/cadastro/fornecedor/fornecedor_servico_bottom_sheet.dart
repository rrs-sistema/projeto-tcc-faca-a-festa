// ignore_for_file: use_build_context_synchronously

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../data/models/servico_produto/subcategoria_servico_model.dart';
import './../../../../controllers/categoria/subcategoria_servico_controller.dart';
import './../../../../data/models/servico_produto/categoria_servico_model.dart';
import './../../../../controllers/categoria/categoria_servico_controller.dart';
import '../../../../app/bootstrap/servico_foto_bootstrap.dart';
import '../../../../data/models/servico_produto/servico_foto_model.dart';
import '../../../../controllers/servico/servico_produto_controller.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../widgets/custom_input_field.dart';
import './../../../../core/utils/form_validators.dart';
import './components/titulo_vinculo_animado.dart';
import './../../../../data/models/model.dart';

Future<void> showFornecedorServicoBottomSheet(
  BuildContext context,
  String idFornecedor, {
  FornecedorProdutoServicoModel? vinculo,
}) async {
  final categoriaController = Get.find<CategoriaServicoController>();
  final subcategoriaController = Get.find<SubcategoriaServicoController>();
  final servicoController = Get.find<ServicoProdutoController>();

  if (categoriaController.categorias.isEmpty) {
    await categoriaController.carregarCategorias();
  }
  if (subcategoriaController.subcategorias.isEmpty) {
    await subcategoriaController.carregarSubcategorias();
  }
  if (servicoController.servicos.isEmpty) {
    await servicoController.carregarServicos();
  }

  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => _FornecedorServicoSheet(
      idFornecedor: idFornecedor,
      vinculo: vinculo,
    ),
  );
}

class _FornecedorServicoSheet extends StatefulWidget {
  const _FornecedorServicoSheet({
    required this.idFornecedor,
    this.vinculo,
  });

  final String idFornecedor;
  final FornecedorProdutoServicoModel? vinculo;

  @override
  State<_FornecedorServicoSheet> createState() => _FornecedorServicoSheetState();
}

class _FornecedorServicoSheetState extends State<_FornecedorServicoSheet> {
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;

  late final TextEditingController precoCtrl;
  late final TextEditingController promocaoCtrl;
  late final TextEditingController urlController;

  CategoriaServicoModel? categoriaSelecionada;
  SubcategoriaServicoModel? subcategoriaSelecionada;
  ServicoProdutoModel? servicoSelecionado;
  late bool ativo;
  String? urlErro;

  late final EventThemeController themeController;
  late final CategoriaServicoController categoriaController;
  late final SubcategoriaServicoController subcategoriaController;
  late final ServicoProdutoController servicoController;
  late final Color primary;

  @override
  void initState() {
    super.initState();
    themeController = Get.find<EventThemeController>();
    categoriaController = Get.find<CategoriaServicoController>();
    subcategoriaController = Get.find<SubcategoriaServicoController>();
    servicoController = Get.find<ServicoProdutoController>();
    primary = themeController.primaryColor.value;

    final vinculo = widget.vinculo;
    precoCtrl = TextEditingController(
      text: vinculo?.preco.toStringAsFixed(2) ?? '',
    );
    promocaoCtrl = TextEditingController(
      text: vinculo?.precoPromocao?.toStringAsFixed(2) ?? '',
    );
    urlController = TextEditingController();
    ativo = vinculo?.ativo ?? true;

    if (vinculo != null) {
      final servico = servicoController.servicos
          .firstWhereOrNull((s) => s.id == vinculo.idProdutoServico);
      final subcategoria = subcategoriaController.subcategorias.firstWhereOrNull(
          (s) => s.id == (servico?.idSubcategoria ?? vinculo.idSubcategoria));
      final categoria = categoriaController.categorias
          .firstWhereOrNull((c) => c.id == subcategoria?.idCategoria);
      categoriaSelecionada = categoria;
      subcategoriaSelecionada = subcategoria;
      servicoSelecionado = servico;
    }
  }

  @override
  void dispose() {
    precoCtrl.dispose();
    promocaoCtrl.dispose();
    urlController.dispose();
    super.dispose();
  }

  InputDecoration _decor(String label, IconData icon, {bool obrigatorio = false}) {
    return InputDecoration(
      labelText: obrigatorio ? '$label *' : label,
      prefixIcon: Icon(icon, color: primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
      ),
      errorMaxLines: 2,
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Future<void> _salvar() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    EasyLoading.show(status: 'Salvando as informações...');
    final promo = FormValidators.parseDinheiro(promocaoCtrl.text);
    final vinculoNovo = FornecedorProdutoServicoModel(
      id: widget.vinculo?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      idProdutoServico: servicoSelecionado!.id,
      idSubcategoria: subcategoriaSelecionada!.id,
      idFornecedor: widget.idFornecedor,
      preco: FormValidators.parseDinheiro(precoCtrl.text),
      precoPromocao: promo > 0 ? promo : null,
      ativo: ativo,
    );

    await servicoController.vincularServico(vinculoNovo);
    EasyLoading.dismiss();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _adicionarFotoUrl() async {
    final erro = FormValidators.url(
      urlController.text,
      obrigatorio: true,
      campo: 'a URL da imagem',
    );
    setState(() => urlErro = erro);
    if (erro != null || servicoSelecionado == null) return;

    EasyLoading.show(status: 'Processando...');
    final novaFoto = ServicoFotoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      idProdutoServico: servicoSelecionado!.id,
      idFornecedor: widget.idFornecedor,
      url: urlController.text.trim(),
      dataUpload: DateTime.now(),
    );
    await ServicoFotoBootstrap.findController().adicionarFotoDireto(novaFoto);
    EasyLoading.dismiss();
    urlController.clear();
    setState(() => urlErro = null);
  }

  @override
  Widget build(BuildContext context) {
    final fotoController = ServicoFotoBootstrap.findController();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.design_services_rounded,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TituloVinculoAnimado(
                                isEdicao: widget.vinculo != null,
                                primary: primary),
                            Text(
                              'Campos com * são obrigatórios',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                DropdownButtonFormField<CategoriaServicoModel>(
                  value: categoriaSelecionada,
                  decoration: _decor(
                    'Categoria',
                    Icons.category_outlined,
                    obrigatorio: true,
                  ),
                  items: categoriaController.categorias
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c.nome)))
                      .toList(),
                  validator: (v) =>
                      FormValidators.selecao(v, campo: 'a categoria'),
                  onChanged: (val) async {
                    setState(() {
                      categoriaSelecionada = val;
                      subcategoriaSelecionada = null;
                      servicoSelecionado = null;
                    });
                    if (val != null) {
                      await subcategoriaController.carregarSubcategorias(val.id);
                      if (mounted) setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<SubcategoriaServicoModel>(
                  value: subcategoriaSelecionada,
                  decoration: _decor(
                    'Subcategoria',
                    Icons.list_alt_outlined,
                    obrigatorio: true,
                  ),
                  isExpanded: true,
                  items: categoriaSelecionada == null
                      ? const []
                      : subcategoriaController.subcategorias
                          .where((s) => s.idCategoria == categoriaSelecionada!.id)
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s.nome)))
                          .toList(),
                  validator: (v) {
                    if (categoriaSelecionada == null) {
                      return 'Selecione a categoria primeiro';
                    }
                    return FormValidators.selecao(v, campo: 'a subcategoria');
                  },
                  onChanged: categoriaSelecionada == null
                      ? null
                      : (val) {
                          setState(() {
                            subcategoriaSelecionada = val;
                            servicoSelecionado = null;
                          });
                        },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<ServicoProdutoModel>(
                  value: servicoSelecionado,
                  decoration: _decor(
                    'Serviço / Produto',
                    Icons.work_outline_rounded,
                    obrigatorio: true,
                  ),
                  items: servicoController.servicos
                      .where((s) =>
                          s.idSubcategoria == subcategoriaSelecionada?.id)
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s.nome)))
                      .toList(),
                  validator: (v) {
                    if (subcategoriaSelecionada == null) {
                      return 'Selecione a subcategoria primeiro';
                    }
                    return FormValidators.selecao(
                      v,
                      campo: 'o serviço / produto',
                    );
                  },
                  onChanged: subcategoriaSelecionada == null
                      ? null
                      : (val) => setState(() => servicoSelecionado = val),
                ),

                const SizedBox(height: 24),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CustomInputField(
                          label: 'Preço padrão (R\$)',
                          icon: Icons.attach_money_rounded,
                          controller: precoCtrl,
                          titleColor: primary,
                          type: InputType.money,
                          isRequired: true,
                          validator: (v) => FormValidators.dinheiro(
                            v,
                            campo: 'o preço padrão',
                          ),
                          onChanged: (_) {
                            if (_autovalidateMode ==
                                AutovalidateMode.onUserInteraction) {
                              _formKey.currentState?.validate();
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        CustomInputField(
                          label: 'Preço promocional (opcional)',
                          icon: Icons.local_offer_outlined,
                          controller: promocaoCtrl,
                          type: InputType.money,
                          titleColor: primary,
                          validator: (v) => FormValidators.dinheiroPromocional(
                            v,
                            preco: precoCtrl.text,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Se informado, deve ser maior que zero e menor que o preço padrão.',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const Divider(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Serviço ativo',
                                style: GoogleFonts.poppins(fontSize: 15)),
                            Switch(
                              value: ativo,
                              activeColor: primary,
                              onChanged: (v) => setState(() => ativo = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (servicoSelecionado != null) ...[
                  Text(
                    'Imagens do serviço (opcional)',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    final fotos = fotoController.fotos;
                    if (fotos.isEmpty) {
                      return Container(
                        height: 100,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                            'Nenhuma imagem ainda.\nAdicione fotos atrativas!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade600)),
                      );
                    }
                    return SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: fotos.length,
                        itemBuilder: (_, i) {
                          final f = fotos[i];
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Material(
                              elevation: 3,
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(f.url,
                                        width: 130,
                                        height: 120,
                                        fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: InkWell(
                                      onTap: () =>
                                          fotoController.removerFoto(f),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black45,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: urlController,
                    keyboardType: TextInputType.url,
                    decoration: _decor(
                      'Cole o link da imagem (URL)',
                      Icons.link_rounded,
                    ).copyWith(
                      errorText: urlErro,
                      helperText: 'Opcional. Use um link http:// ou https://',
                    ),
                    onChanged: (_) {
                      if (urlErro != null) setState(() => urlErro = null);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_link_rounded,
                              color: Colors.white),
                          label: const Text('Adicionar via URL',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _adicionarFotoUrl,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_a_photo_outlined,
                              color: Colors.white),
                          label: const Text('Enviar do dispositivo',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade400,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            EasyLoading.show(status: 'Processando...');
                            await fotoController.adicionarFoto(
                              idFornecedor: widget.idFornecedor,
                              idProdutoServico: servicoSelecionado!.id,
                            );
                            EasyLoading.dismiss();
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded, color: Colors.white),
                    label: const Text(
                      'Salvar',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _salvar,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    icon: const Icon(Icons.exit_to_app_rounded,
                        color: Colors.white),
                    label: const Text(
                      'Sair',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.grey.shade400,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
