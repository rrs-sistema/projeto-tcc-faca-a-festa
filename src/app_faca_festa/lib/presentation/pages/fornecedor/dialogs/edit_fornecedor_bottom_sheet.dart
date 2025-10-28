// ignore_for_file: use_build_context_synchronously

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';

import '../../../widgets/custom_input_field.dart';
import './../../../../controllers/fornecedor_controller.dart';
import './../../../../data/models/model.dart';

class EditFornecedorBottomSheet extends StatefulWidget {
  final FornecedorModel fornecedor;

  const EditFornecedorBottomSheet({super.key, required this.fornecedor});

  @override
  State<EditFornecedorBottomSheet> createState() => _EditFornecedorBottomSheetState();
}

class _EditFornecedorBottomSheetState extends State<EditFornecedorBottomSheet> {
  late TextEditingController _razaoCtrl;
  late TextEditingController _telefoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _descricaoCtrl;

  File? _bannerFile;

  @override
  void initState() {
    super.initState();
    _razaoCtrl = TextEditingController(text: widget.fornecedor.razaoSocial);
    _telefoneCtrl = TextEditingController(text: widget.fornecedor.telefone);
    _emailCtrl = TextEditingController(text: widget.fornecedor.email);
    _descricaoCtrl = TextEditingController(text: widget.fornecedor.descricao ?? '');
  }

  @override
  void dispose() {
    _razaoCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _bannerFile = File(picked.path));
  }

  Future<void> _salvar() async {
    final controller = Get.find<FornecedorController>();
    EasyLoading.show(status: 'Salvando...');

    try {
      String? bannerUrl = widget.fornecedor.bannerUrl;
      if (_bannerFile != null) {
        bannerUrl = await controller.uploadBanner(_bannerFile!);
      }

      final atualizado = widget.fornecedor.copyWith(
        razaoSocial: _razaoCtrl.text.trim(),
        telefone: _telefoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        descricao: _descricaoCtrl.text.trim(),
        bannerUrl: bannerUrl,
      );

      await controller.atualizarFornecedor(atualizado);
      EasyLoading.showSuccess('Dados atualizados!');
      Navigator.pop(context);
    } catch (e) {
      EasyLoading.showError('Erro ao salvar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== CABEÇALHO =====
            Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store_rounded, color: primary, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      "Editar Fornecedor",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),

                // 🔹 Botão de fechar
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.grey.shade600,
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ===== BANNER =====
            GestureDetector(
              onTap: _selecionarImagem,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _bannerFile != null
                    ? Image.file(
                        _bannerFile!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : (widget.fornecedor.bannerUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.fornecedor.bannerUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Colors.grey.shade200),
                            errorWidget: (_, __, ___) => Container(
                              height: 150,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.grey, size: 48),
                            ),
                          )
                        : Container(
                            height: 150,
                            color: Colors.grey.shade100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, color: primary, size: 36),
                                const SizedBox(height: 6),
                                Text(
                                  "Selecionar banner",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )),
              ),
            ),
            const SizedBox(height: 20),

            // ===== CAMPOS =====
            _campo("Razão Social", _razaoCtrl, Icons.business_rounded),
            _campo("Telefone", _telefoneCtrl, Icons.phone_rounded),
            _campo("E-mail", _emailCtrl, Icons.email_rounded),
            _campo("Descrição", _descricaoCtrl, Icons.edit_note_rounded, maxLines: 3),
            const SizedBox(height: 16),

            // ===== BOTÃO SALVAR =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: Text(
                  "Salvar alterações",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return CustomInputField(
      label: label,
      controller: controller,
      icon: icon,
      color: null,
      readOnly: false,
    );
  }
}
