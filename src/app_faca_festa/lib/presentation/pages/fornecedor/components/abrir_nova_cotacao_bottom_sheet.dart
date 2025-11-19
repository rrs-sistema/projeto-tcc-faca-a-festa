// ignore_for_file: use_build_context_synchronously

import 'package:app_faca_festa/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:app_faca_festa/presentation/widgets/button/botao_cancelar.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:ui';

import '../../../widgets/custom_input_field.dart';
import './../../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import './../../../../controllers/evento_controller.dart';
import './../../../../controllers/app_controller.dart';
import './../../../../data/models/model.dart';

class CotacaoNovaBottomSheet extends StatefulWidget {
  final String tipoEventoNome;
  final List<String> fornecedoresSelecionados;
  final List<FornecedorServicoDetalhadoDto> servicosSelecionados;
  final VoidCallback? onCotacaoFinalizada;
  final Color primary;

  const CotacaoNovaBottomSheet({
    super.key,
    required this.tipoEventoNome,
    required this.fornecedoresSelecionados,
    required this.servicosSelecionados,
    required this.primary,
    this.onCotacaoFinalizada,
  });

  @override
  State<CotacaoNovaBottomSheet> createState() => _CotacaoNovaBottomSheetState();
}

class _CotacaoNovaBottomSheetState extends State<CotacaoNovaBottomSheet> {
  late List<FornecedorServicoDetalhadoDto> servicosInternal;
  final fornecedorController = Get.find<FornecedorController>();
  final eventoCtrl = Get.find<EventoController>();
  final appCtrl = Get.find<AppController>();

  final observacaoController = TextEditingController();
  final precoDesejadoController = TextEditingController();
  late DateTime dataLimite;
  final scrollController = ScrollController();

  bool expandirServicos = true;

  final List<TextEditingController> qtdControllers = [];
  final List<TextEditingController> valorControllers = [];

  @override
  void initState() {
    super.initState();
    dataLimite = DateTime.now().add(const Duration(days: 7));
    for (final s in widget.servicosSelecionados) {
      qtdControllers.add(
        TextEditingController(text: s.quantidade.toString()),
      );

      valorControllers.add(TextEditingController(
        text: s.precoPromocao?.toStringAsFixed(2) ?? s.preco.toStringAsFixed(2),
      ));
    }
    servicosInternal = widget.servicosSelecionados.map((e) => e.copyWith()).toList();
  }

  @override
  void dispose() {
    observacaoController.dispose();
    precoDesejadoController.dispose();
    scrollController.dispose();
    for (final c in qtdControllers) {
      c.dispose();
    }
    for (final c in valorControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ==========================================================
  // === ENVIO
  // ==========================================================

  Future<void> _enviarCotacao() async {
    final evento = eventoCtrl.eventoAtual.value;
    final usuario = appCtrl.usuarioLogado.value;
    final db = FirebaseFirestore.instance;

    if (widget.fornecedoresSelecionados.isEmpty) {
      Get.snackbar('Atenção', 'Selecione pelo menos um fornecedor.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (widget.servicosSelecionados.isEmpty) {
      Get.snackbar('Atenção', 'Selecione ao menos um serviço.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    EasyLoading.show(status: 'Enviando cotações...');

    try {
      // 🔹 Cria o documento principal da cotação
      final cotacaoRef = await db.collection('cotacao').add({
        'id_evento': evento?.idEvento ?? '',
        'id_usuario_solicitante': usuario?.idUsuario ?? '',
        'nome_usuario_solicitante': usuario?.nome ?? '',
        'observacao': observacaoController.text.trim(),
        'valor_estimado_total': Biblioteca.toDouble(precoDesejadoController.text),
        'data_limite_resposta': Timestamp.fromDate(dataLimite),
        'data_envio': Timestamp.now(),
        'status': StatusCotacao.pendente.firestoreValue,
        'visualizado': false,
        'categoria_nome': widget.tipoEventoNome,
      });

      final batch = db.batch();

      // 🔹 Para cada fornecedor selecionado
      for (final idFornecedor in widget.fornecedoresSelecionados) {
        final fornecedor = fornecedorController.fornecedores
            .firstWhereOrNull((f) => f.idFornecedor == idFornecedor);
        if (fornecedor == null) continue;

        final fornecedorRef = cotacaoRef.collection('fornecedores').doc(idFornecedor);

        batch.set(fornecedorRef, {
          'id_fornecedor': fornecedor.idFornecedor,
          'nome_fornecedor': fornecedor.razaoSocial,
          'email': fornecedor.email,
          'telefone': fornecedor.telefone,
          'status': StatusFornecedorCotacao.aguardando.firestoreValue,
          'data_envio': Timestamp.now(),
          'respondido': false,
        });

        // 🔹 Filtra apenas os serviços pertencentes a este fornecedor
        final servicosDoFornecedor =
            widget.servicosSelecionados.where((s) => s.idFornecedor == idFornecedor).toList();

        for (int i = 0; i < servicosDoFornecedor.length; i++) {
          final s = servicosDoFornecedor[i];
          final qtd = int.tryParse(qtdControllers[i].text) ?? 1;

          final servicoRef = fornecedorRef.collection('servicos').doc(s.idProdutoServico);

          batch.set(servicoRef, {
            'id_produto_servico': s.idProdutoServico,
            'nome_produto_servico': s.nomeServico,
            'quantidade': qtd,
            'valor_estimado': s.preco,
            'subtotal': qtd * s.preco,
            'status': 'pendente',
            'data_adicionado': Timestamp.now(),
          });
        }
      }

      await batch.commit();

      EasyLoading.dismiss();
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
      widget.onCotacaoFinalizada?.call();

      Get.snackbar(
        'Cotação enviada!',
        'Os fornecedores foram notificados.',
        backgroundColor: widget.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Erro ao enviar',
        'Tente novamente mais tarde.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // ==========================================================
  // === INTERFACE MODERNA COM SCROLL E ANIMAÇÕES
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final fornecedores = widget.fornecedoresSelecionados
        .map(
            (id) => fornecedorController.fornecedores.firstWhereOrNull((f) => f.idFornecedor == id))
        .whereType<FornecedorModel>()
        .toList();

    final gradient = LinearGradient(
      colors: [
        widget.primary.withValues(alpha: 0.12),
        widget.primary.withValues(alpha: 0.04),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 10,
              right: 10,
              top: 18,
              bottom: MediaQuery.of(context).viewInsets.bottom + 18,
            ),
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (_) => false,
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader().animate().fadeIn(duration: 350.ms).slideY(begin: -0.2),
                    const SizedBox(height: 10),
                    _buildServicosSelecionados()
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.2),
                    const SizedBox(height: 10),
                    _buildFornecedores(fornecedores)
                        .animate()
                        .fadeIn(duration: 450.ms)
                        .slideX(begin: 0.2),
                    const SizedBox(height: 20),
                    _buildValorDesejado().animate().fadeIn(duration: 480.ms),
                    const SizedBox(height: 10),
                    _buildObservacao().animate().fadeIn(duration: 480.ms),
                    const SizedBox(height: 10),
                    _buildDataLimite().animate().fadeIn(duration: 520.ms),
                    const SizedBox(height: 22),
                    _buildEnviarButton()
                        .animate()
                        .fadeIn(duration: 550.ms)
                        .scale(begin: const Offset(0.9, 0.9)),
                    const SizedBox(height: 22),
                    _buildCancelarButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // === COMPONENTES ELEGANTES
  // ==========================================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.request_quote_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text('Nova Cotação',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildServicosSelecionados() => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: widget.primary.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => expandirServicos = !expandirServicos),
              child: Row(
                children: [
                  Icon(Icons.design_services_rounded, color: widget.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Serviços selecionados (${widget.servicosSelecionados.length})',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: widget.primary,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expandirServicos ? Icons.expand_less : Icons.expand_more,
                    color: widget.primary,
                  ),
                ],
              ),
            ),
            if (expandirServicos)
              ...widget.servicosSelecionados.asMap().entries.map((entry) {
                final index = entry.key;
                final s = entry.value;

                final quantidadeController = qtdControllers[index];

                return Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.nomeServico ?? 'Serviço sem nome',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.primary.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.numbers_rounded, color: widget.primary, size: 14),
                            const SizedBox(width: 2),
                            _buildQuantidadeSelector(
                              index: index,
                              s: s,
                              controller: quantidadeController,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "x R\$ ${Biblioteca.formatarValorDecimal(s.preco)}",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            _buildTotalAnimado(
                              servicosInternal[index].preco * servicosInternal[index].quantidade,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      );

  Widget _buildQuantidadeSelector({
    required int index,
    required FornecedorServicoDetalhadoDto s,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      decoration: BoxDecoration(
        color: widget.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---------------- BOTÃO - ----------------
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              SystemSound.play(SystemSoundType.click);

              final atual = int.tryParse(controller.text) ?? 1;
              final novo = (atual > 1) ? atual - 1 : 1;

              controller.text = novo.toString();

              setState(() {
                servicosInternal[index] = servicosInternal[index].copyWith(quantidade: novo);
              });
            },
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: widget.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.remove_rounded, size: 16),
            ),
          ),

          // ---------------- CAMPO CENTRAL ----------------
          SizedBox(
            width: 38,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
              ),

              // Quando digita
              onChanged: (value) {
                final qtd = int.tryParse(value) ?? 1;

                setState(() {
                  servicosInternal[index] = servicosInternal[index].copyWith(quantidade: qtd);
                });
              },
            ),
          ),

          // ---------------- BOTÃO + ----------------
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              SystemSound.play(SystemSoundType.click);

              final atual = int.tryParse(controller.text) ?? 1;
              final novo = atual + 1;

              controller.text = novo.toString();

              setState(() {
                servicosInternal[index] = servicosInternal[index].copyWith(quantidade: novo);
              });
            },
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAnimado(double total) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),
      tween: Tween<double>(begin: 0, end: total),
      builder: (_, value, child) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: 1,
          child: Transform.translate(
            offset: const Offset(0, -2),
            child: Text(
              "R\$ ${Biblioteca.formatarValorDecimal(value)}",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: widget.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFornecedores(List<FornecedorModel> fornecedores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fornecedores da cotação:',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
        const SizedBox(height: 8),
        ...fornecedores.map((f) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: widget.primary.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: widget.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.storefront_rounded, color: Colors.black87),
                ),
                title: Text(f.razaoSocial,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                //subtitle: Text(f.email, style: GoogleFonts.poppins(fontSize: 12.5)),
              ),
            )),
      ],
    );
  }

  Widget _buildValorDesejado() => Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            Future.delayed(const Duration(milliseconds: 300), () {
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              );
            });
          }
        },
        child: CustomInputField(
          label: "Oferta desejada (R\$)",
          icon: Icons.attach_money_rounded,
          controller: precoDesejadoController,
          type: InputType.money,
          hintlabel: 'Informe a sua oferta',
          titleColor: Colors.white,
        ),
      );

  Widget _buildObservacao() => Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            Future.delayed(const Duration(milliseconds: 300), () {
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              );
            });
          }
        },
        child: CustomInputField(
          label: "Observações adicionais (opcional)",
          icon: Icons.chat_bubble_outline_rounded,
          controller: observacaoController,
          type: InputType.multiline,
          hintlabel: 'Descreva sua oferta para os fornecedores',
          titleColor: Colors.white,
          maxLines: 4,
        ),
      );

  Widget _buildDataLimite() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: widget.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: widget.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Prazo de resposta: ${DateFormat("dd/MM/yyyy").format(dataLimite)}',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: () async {
                final novaData = await showDatePicker(
                  context: context,
                  initialDate: dataLimite,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  locale: const Locale('pt', 'BR'),
                );
                if (novaData != null) setState(() => dataLimite = novaData);
              },
              child: Text('Alterar', style: TextStyle(color: widget.primary)),
            ),
          ],
        ),
      );

  Widget _buildEnviarButton() => SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.send_rounded, color: Colors.white),
          label: Text('Enviar Cotação',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: widget.primary.withValues(alpha: 0.3),
          ),
          onPressed: _enviarCotacao,
        ),
      );

  Widget _buildCancelarButton() =>
      BotaoCancelar(texto: 'Cancelar', onPressed: () => Navigator.pop(context));
}
