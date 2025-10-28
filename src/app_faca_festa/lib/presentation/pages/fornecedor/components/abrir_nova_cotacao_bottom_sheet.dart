// ignore_for_file: use_build_context_synchronously

import 'package:app_faca_festa/controllers/fornecedor_controller.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import './../../../../controllers/fornecedor_localizacao_controller.dart';
import './../../../../controllers/evento_controller.dart';
import './../../../../controllers/app_controller.dart';
import '../../../../data/models/model.dart';

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
  final fornecedorController = Get.find<FornecedorController>();
  final fornecedorLocalizacaoCtrl = Get.find<FornecedorLocalizacaoController>();
  final eventoCtrl = Get.find<EventoController>();
  final appCtrl = Get.find<AppController>();

  final observacaoController = TextEditingController();
  late DateTime dataLimite;

  bool expandirServicos = true;

  final List<TextEditingController> qtdControllers = [];
  final List<TextEditingController> valorControllers = [];

  @override
  void initState() {
    super.initState();
    dataLimite = DateTime.now().add(const Duration(days: 7));

    for (final s in widget.servicosSelecionados) {
      qtdControllers.add(TextEditingController(text: '1'));
      valorControllers.add(TextEditingController(
        text: s.precoPromocao?.toStringAsFixed(2) ?? s.preco.toStringAsFixed(2),
      ));
    }
  }

  @override
  void dispose() {
    observacaoController.dispose();
    for (final c in qtdControllers) {
      c.dispose();
    }
    for (final c in valorControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ==========================================================
  // === ENVIO DA COTAÇÃO
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
      Get.snackbar('Atenção', 'Selecione ao menos um serviço para cotar.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    EasyLoading.show(status: 'Enviando cotações...');

    try {
      // 🔹 Cria cotação principal
      final cotacaoRef = await db.collection('cotacao').add({
        'id_evento': evento?.idEvento ?? '',
        'id_usuario_solicitante': usuario?.idUsuario ?? '',
        'nome_usuario_solicitante': usuario?.nome ?? '',
        'observacao': observacaoController.text.trim(),
        'data_limite_resposta': Timestamp.fromDate(dataLimite),
        'data_envio': Timestamp.now(),
        'status': StatusCotacao.pendente.firestoreValue,
        'visualizado': false,
        'categoria_nome': widget.tipoEventoNome,
        'data_fechamento': null,
        'fechado_por': null,
      });

      final batch = db.batch();

      // 🔹 Subcoleção de serviços cotados
      for (int i = 0; i < widget.servicosSelecionados.length; i++) {
        final s = widget.servicosSelecionados[i];
        final qtd = int.tryParse(qtdControllers[i].text) ?? 1;
        final valor = double.tryParse(valorControllers[i].text.replaceAll(',', '.')) ?? s.preco;

        final servicoRef = cotacaoRef.collection('servicos').doc();
        batch.set(servicoRef, {
          'id_produto_servico': s.idProdutoServico,
          'nome_produto_servico': s.nomeServico,
          'quantidade': qtd,
          'valor_estimado': valor,
          'subtotal': qtd * valor,
        });
      }

      // 🔹 Subcoleção de fornecedores participantes
      for (final idFornecedor in widget.fornecedoresSelecionados) {
        final fornecedor = fornecedorController.fornecedores
            .firstWhereOrNull((f) => f.idFornecedor == idFornecedor);

        if (fornecedor != null) {
          final fornecedorRef = cotacaoRef.collection('fornecedores').doc();
          batch.set(fornecedorRef, {
            'id_fornecedor': fornecedor.idFornecedor,
            'nome_fornecedor': fornecedor.razaoSocial,
            'email': fornecedor.email,
            'telefone': fornecedor.telefone,
            'status': StatusFornecedorCotacao.aguardando.firestoreValue,
          });
        }
      }

      await batch.commit();

      EasyLoading.dismiss();
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
      widget.onCotacaoFinalizada?.call();

      Get.snackbar(
        'Cotação enviada com sucesso!',
        'Os fornecedores foram notificados.',
        backgroundColor: widget.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } catch (e, s) {
      EasyLoading.dismiss();
      debugPrint('❌ Erro ao enviar cotação: $e\n$s');
      Get.snackbar(
        'Erro ao enviar cotação',
        'Tente novamente mais tarde.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // ==========================================================
  // === INTERFACE
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final fornecedores = fornecedorLocalizacaoCtrl.fornecedoresFiltrados
        .where((f) => widget.fornecedoresSelecionados.contains(f.fornecedor.idFornecedor))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: widget.primary.withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 10),
                  _buildServicosSelecionados(),
                  const SizedBox(height: 20),
                  _buildFornecedores(fornecedores),
                  const SizedBox(height: 20),
                  _buildObservacao(),
                  const SizedBox(height: 20),
                  _buildDataLimite(),
                  const SizedBox(height: 28),
                  _buildEnviarButton(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // === SEÇÕES DA UI
  // ==========================================================
  Widget _buildHeader() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Nova Cotação',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.primary,
              )),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );

  Widget _buildServicosSelecionados() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => expandirServicos = !expandirServicos),
            child: Row(
              children: [
                Icon(Icons.design_services_rounded, color: widget.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Serviços selecionados (${widget.servicosSelecionados.length})',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600, color: widget.primary),
                  ),
                ),
                Icon(
                  expandirServicos ? Icons.expand_less : Icons.expand_more,
                  color: widget.primary,
                ),
              ],
            ),
          ),
          if (expandirServicos) ...[
            const SizedBox(height: 10),
            for (int i = 0; i < widget.servicosSelecionados.length; i++)
              _buildServicoItem(widget.servicosSelecionados[i], i),
          ],
        ],
      ),
    );
  }

  Widget _buildServicoItem(FornecedorServicoDetalhadoDto s, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔹 Texto do serviço
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.nomeServico ?? 'Serviço sem nome',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey.shade900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 3,
                    width: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.primary.withValues(alpha: 0.9),
                          widget.primary.withValues(alpha: 0.4),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFornecedores(List fornecedores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fornecedores selecionados:',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800)),
        const SizedBox(height: 8),
        if (fornecedores.isEmpty)
          Text('Nenhum fornecedor encontrado.',
              style: GoogleFonts.poppins(color: Colors.grey.shade600)),
        for (final f in fornecedores)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: widget.primary.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.storefront_rounded, color: widget.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    f.fornecedor.razaoSocial,
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildObservacao() => TextField(
        controller: observacaoController,
        decoration: InputDecoration(
          labelText: 'Observações adicionais (opcional)',
          prefixIcon: Icon(Icons.edit_note_rounded, color: widget.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        minLines: 2,
        maxLines: 4,
      );

  Widget _buildDataLimite() => GestureDetector(
        onTap: () async {
          final novaData = await showDatePicker(
            context: context,
            initialDate: dataLimite,
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
            locale: const Locale('pt', 'BR'),
          );
          if (novaData != null) setState(() => dataLimite = novaData);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: widget.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                'Responder até: ${DateFormat("dd/MM/yyyy").format(dataLimite)}',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
        ),
      );

  Widget _buildEnviarButton() => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.send_rounded, color: Colors.white),
          label: Text('Enviar Cotação',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 5,
          ),
          onPressed: _enviarCotacao,
        ),
      );
}
