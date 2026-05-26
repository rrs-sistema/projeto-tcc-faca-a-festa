// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/tema/event_theme_controller.dart';
import '../../../../data/models/cardapio/cardapio_model.dart';
import './../../../../controllers/convidado/cardapio_controller.dart';
import './../../../../data/models/cardapio/cardapio_item_model.dart';

class AddItemCardapioBottomSheet extends StatefulWidget {
  final String idCardapio;

  /// Opcional para não quebrar as chamadas atuais.
  /// Se não for informado, o bottom sheet tenta encontrar o idEvento
  /// pelo CardapioController usando o idCardapio.
  final String? idEvento;

  const AddItemCardapioBottomSheet({
    super.key,
    required this.idCardapio,
    this.idEvento,
  });

  @override
  State<AddItemCardapioBottomSheet> createState() => _AddItemCardapioBottomSheetState();
}

class _AddItemCardapioBottomSheetState extends State<AddItemCardapioBottomSheet> {
  final nomeCtrl = TextEditingController();

  /// Agora o tipo não é mais String.
  /// O novo CardapioItemModel espera TipoItemCardapio.
  final Rx<TipoItemCardapio> tipo = TipoItemCardapio.comida.obs;

  @override
  void dispose() {
    nomeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CardapioController>();
    final theme = Get.find<EventThemeController>();

    return FractionallySizedBox(
      heightFactor: 0.80,
      child: Container(
        decoration: BoxDecoration(
          gradient: theme.gradient.value,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ─────────────────────────────────────────────
            // HEADER ELEGANTE
            // ─────────────────────────────────────────────
            Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  Icons.add_circle_rounded,
                  size: 40,
                  color: theme.secondaryColor.value,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Novo Item do Cardápio',
                    style: GoogleFonts.poppins(
                      color: theme.secondaryColor.value,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
              ],
            ),

            const SizedBox(height: 20),

            // ─────────────────────────────────────────────
            // SCROLL DO CONTEÚDO
            // ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.40),
                          width: 1.4,
                        ),
                      ),
                      child: TextField(
                        controller: nomeCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nome do item',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: Icon(
                            Icons.fastfood_rounded,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Tipo de Item',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => Wrap(
                        spacing: 16,
                        runSpacing: 10,
                        children: [
                          _tipoChip(
                            label: 'Comida',
                            valor: TipoItemCardapio.comida,
                            tipoSelecionado: tipo,
                            theme: theme,
                          ),
                          _tipoChip(
                            label: 'Bebida',
                            valor: TipoItemCardapio.bebida,
                            tipoSelecionado: tipo,
                            theme: theme,
                          ),
                          _tipoChip(
                            label: 'Sobremesa',
                            valor: TipoItemCardapio.sobremesa,
                            tipoSelecionado: tipo,
                            theme: theme,
                          ),
                          _tipoChip(
                            label: 'Bolo',
                            valor: TipoItemCardapio.bolo,
                            tipoSelecionado: tipo,
                            theme: theme,
                          ),
                          _tipoChip(
                            label: 'Descartável',
                            valor: TipoItemCardapio.descartavel,
                            tipoSelecionado: tipo,
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ─────────────────────────────────────────────
            // BOTÃO FIXO PARA SALVAR
            // ─────────────────────────────────────────────
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Obx(() {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor.value,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () async {
                      await _salvarItem(
                        context: context,
                        controller: controller,
                        primaryColor: theme.primaryColor.value,
                      );
                    },
                    child: Text(
                      'Adicionar Item',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvarItem({
    required BuildContext context,
    required CardapioController controller,
    required Color primaryColor,
  }) async {
    final nome = nomeCtrl.text.trim();

    if (nome.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Informe o nome do item',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    final idEvento = _resolverIdEvento(controller);

    if (idEvento.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Não foi possível identificar o evento deste cardápio.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final novoItem = CardapioItemModel(
      idItem: '',
      idEvento: idEvento,
      idCardapio: widget.idCardapio,
      nome: nome,
      tipo: tipo.value,
      publicoAlvo: PublicoAlvoCardapio.todos,
      quantidadeSugerida: 0,
      quantidadeFinal: 0,
      unidade: 'un',
      confirmado: false,
      geradoPelaCalculadora: false,
    );

    await controller.addItem(widget.idCardapio, novoItem);

    Navigator.pop(context);

    Get.snackbar(
      'Item adicionado',
      nome,
      backgroundColor: primaryColor,
      colorText: Colors.white,
    );
  }

  String _resolverIdEvento(CardapioController controller) {
    final idEventoInformado = widget.idEvento?.trim() ?? '';

    if (idEventoInformado.isNotEmpty) {
      return idEventoInformado;
    }

    for (final cardapio in controller.cardapios) {
      if (cardapio.idCardapio == widget.idCardapio) {
        return cardapio.idEvento;
      }
    }

    return '';
  }

  // ──────────────────────────────────────────────────────────
  // CHIP ESTILIZADO PREMIUM
  // ──────────────────────────────────────────────────────────
  Widget _tipoChip({
    required String label,
    required TipoItemCardapio valor,
    required Rx<TipoItemCardapio> tipoSelecionado,
    required EventThemeController theme,
  }) {
    final bool selected = tipoSelecionado.value == valor;
    final primary = theme.primaryColor.value;

    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          color: selected ? Colors.white : Colors.grey.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
      checkmarkColor: selected ? Colors.white : Colors.grey.withValues(alpha: 0.85),
      selected: selected,
      onSelected: (_) => tipoSelecionado.value = valor,
      selectedColor: primary.withValues(alpha: 0.85),
      backgroundColor: Colors.white.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      pressElevation: 0,
      visualDensity: VisualDensity.compact,
      shadowColor: Colors.transparent,
    );
  }
}
