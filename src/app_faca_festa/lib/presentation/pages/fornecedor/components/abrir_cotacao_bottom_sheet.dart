// ignore_for_file: use_build_context_synchronously

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../../data/models/model.dart';
import './../../../../controllers/fornecedor_localizacao_controller.dart';
import './../../../../data/models/DTO/servico_cotado.dart';
import './../../../../controllers/evento_controller.dart';
import './../../../../controllers/app_controller.dart';

class CotacaoBottomSheet extends StatefulWidget {
  final String tipoEventoNome;
  final List<String> fornecedoresSelecionados;
  final List<ServicoCotado> servicosSelecionados;
  final VoidCallback? onCotacaoFinalizada;

  final Color primary;

  const CotacaoBottomSheet({
    super.key,
    required this.tipoEventoNome,
    required this.fornecedoresSelecionados,
    required this.servicosSelecionados,
    required this.primary,
    this.onCotacaoFinalizada,
  });

  @override
  State<CotacaoBottomSheet> createState() => _CotacaoBottomSheetState();
}

class _CotacaoBottomSheetState extends State<CotacaoBottomSheet> {
  final TextEditingController observacaoController = TextEditingController();
  late DateTime dataLimite;
  bool expandirServicos = false;

  // ✅ controladores persistentes
  final List<TextEditingController> qtdControllers = [];
  final List<TextEditingController> valorControllers = [];

  @override
  void initState() {
    super.initState();
    dataLimite = DateTime.now().add(const Duration(days: 7));

    // cria controllers para cada serviço
    for (final s in widget.servicosSelecionados) {
      qtdControllers.add(TextEditingController(text: s.quantidade.toString()));
      valorControllers.add(TextEditingController(
        text: s.valor?.toStringAsFixed(2) ?? '',
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

  Future<void> _enviarCotacao() async {
    final eventoCtrl = Get.find<EventoController>();
    final fornecedorCtrl = Get.find<FornecedorLocalizacaoController>();
    final appCtrl = Get.find<AppController>();
    final db = FirebaseFirestore.instance;

    final evento = eventoCtrl.eventoAtual.value;
    final usuario = appCtrl.usuarioLogado.value;

    if (widget.fornecedoresSelecionados.isEmpty) {
      Get.snackbar('Atenção', 'Selecione pelo menos um fornecedor para enviar a cotação.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (widget.servicosSelecionados.isEmpty) {
      Get.snackbar('Atenção', 'Selecione pelo menos um serviço para cotar.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    // Atualiza os modelos com os controladores
    for (int i = 0; i < widget.servicosSelecionados.length; i++) {
      final qtd = int.tryParse(qtdControllers[i].text) ?? 1;
      final valor = double.tryParse(valorControllers[i].text.replaceAll(',', '.')) ?? 0.0;

      widget.servicosSelecionados[i] = ServicoCotado(
        idProduto: widget.servicosSelecionados[i].idProduto,
        nomeProduto: widget.servicosSelecionados[i].nomeProduto,
        quantidade: qtd,
        valor: valor,
      );
    }

    EasyLoading.show(status: 'Enviando cotações...');

    try {
      // 🔹 1️⃣ Cria a cotação principal
      final cotacaoRef = await db.collection('cotacao').add({
        'id_evento': evento?.idEvento ?? '',
        'id_usuario_solicitante': usuario?.idUsuario ?? '',
        'observacao': observacaoController.text.trim(),
        'data_limite_resposta': Timestamp.fromDate(dataLimite),
        'data_envio': Timestamp.now(),
        'status': StatusCotacao.pendente.firestoreValue,
        'visualizado': false,
        'categoria_nome': widget.tipoEventoNome,
      });

      final batch = db.batch();

      // 🔹 2️⃣ Subcoleção de serviços cotados
      for (final servico in widget.servicosSelecionados) {
        final servicoRef = cotacaoRef.collection('servicos').doc();
        batch.set(servicoRef, {
          'id_produto_servico': servico.idProduto,
          'nome_produto_servico': servico.nomeProduto,
          'quantidade': servico.quantidade,
          'valor_estimado': servico.valor ?? 0.0,
        });
      }

      // 🔹 3️⃣ Subcoleção de fornecedores participantes
      for (final idFornecedor in widget.fornecedoresSelecionados) {
        final fornecedorCotacao = FornecedorCotacaoModel(
          id: db.collection('cotacao/${cotacaoRef.id}/fornecedores').doc().id,
          idCotacao: cotacaoRef.id,
          idFornecedor: idFornecedor,
          status: StatusFornecedorCotacao.aguardando,
        );

        final fornecedorRef = cotacaoRef.collection('fornecedores').doc(fornecedorCotacao.id);
        batch.set(fornecedorRef, fornecedorCotacao.toMap());
      }

      await batch.commit();

      // 🔹 Feedback visual
      EasyLoading.dismiss();
      HapticFeedback.mediumImpact();

      appCtrl.limparServicosSelecionados();
      qtdControllers.clear();
      valorControllers.clear();
      observacaoController.clear();

      Navigator.pop(context);
      Future.delayed(const Duration(milliseconds: 300), () {
        fornecedorCtrl.update();
        widget.onCotacaoFinalizada?.call();
        Get.snackbar(
          'Cotações enviadas!',
          'Os dados foram enviados com sucesso e a tela foi atualizada.',
          backgroundColor: widget.primary,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      });
    } catch (e, s) {
      EasyLoading.dismiss();
      debugPrint('❌ Erro ao enviar cotação: $e\n$s');
      Get.snackbar(
        'Erro',
        'Não foi possível enviar as cotações. Tente novamente.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fornecedorCtrl = Get.find<FornecedorLocalizacaoController>();
    final fornecedores = fornecedorCtrl.fornecedoresFiltrados
        .where((f) => widget.fornecedoresSelecionados.contains(f.fornecedor.idFornecedor))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      maxChildSize: 0.95,
      minChildSize: 0.6,
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
              left: 20,
              right: 20,
              top: 18,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Row(
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
                  ),
                  const SizedBox(height: 10),

                  // Serviços selecionados
                  _buildServicosSelecionados(),

                  const SizedBox(height: 16),

                  Text(
                    'Fornecedores selecionados:',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 8),
                  _buildListaFornecedores(fornecedores),

                  const SizedBox(height: 14),

                  // Observações
                  TextField(
                    controller: observacaoController,
                    decoration: InputDecoration(
                      labelText: 'Observações adicionais (opcional)',
                      prefixIcon: Icon(Icons.edit_note_rounded, color: widget.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 14),

                  // Data limite
                  GestureDetector(
                    onTap: () async {
                      final novaData = await showDatePicker(
                        context: context,
                        initialDate: dataLimite,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        locale: const Locale('pt', 'BR'),
                      );
                      if (novaData != null) {
                        setState(() => dataLimite = novaData);
                      }
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
                  ),

                  const SizedBox(height: 24),

                  // Botão enviar
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      label: Text('Enviar Cotação',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _enviarCotacao,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServicosSelecionados() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.primary.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    'Serviços (${widget.servicosSelecionados.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.primary,
                    ),
                  ),
                ),
                Icon(
                  expandirServicos ? Icons.expand_less : Icons.expand_more,
                  color: widget.primary,
                )
              ],
            ),
          ),

          // 🔹 Exibe a lista de serviços com campos editáveis
          if (expandirServicos)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                for (int i = 0; i < widget.servicosSelecionados.length; i++)
                  _buildServicoItem(widget.servicosSelecionados[i], i),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildServicoItem(ServicoCotado servico, int index) {
    final qtdController = qtdControllers[index];
    final valorController = valorControllers[index];

    double calcularSubtotal() {
      final qtd = int.tryParse(qtdController.text) ?? 1;
      final valor = double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0.0;
      return qtd * valor;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  servico.nomeProduto,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 🔹 Campos editáveis
          Row(
            children: [
              // Quantidade
              Expanded(
                flex: 2,
                child: TextField(
                  controller: qtdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Qtd',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (v) {
                    final qtd = int.tryParse(v) ?? 1;
                    setState(() {
                      widget.servicosSelecionados[index] = ServicoCotado(
                        idProduto: servico.idProduto,
                        nomeProduto: servico.nomeProduto,
                        quantidade: qtd,
                        valor: servico.valor,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Valor estimado
              Expanded(
                flex: 4,
                child: TextField(
                  controller: valorController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor estimado',
                    prefixText: 'R\$ ',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (v) {
                    final valor = double.tryParse(v.replaceAll(',', '.')) ?? servico.valor ?? 0.0;
                    setState(() {
                      widget.servicosSelecionados[index] = ServicoCotado(
                        idProduto: servico.idProduto,
                        nomeProduto: servico.nomeProduto,
                        quantidade: servico.quantidade,
                        valor: valor,
                      );
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 🔹 Subtotal automático
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Subtotal: ',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'R\$ ${calcularSubtotal().toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: widget.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Divider(color: Colors.grey.shade300, height: 10),
        ],
      ),
    );
  }

  Widget _buildListaFornecedores(List fornecedores) {
    if (fornecedores.isEmpty) {
      return Center(
        child: Text('Nenhum fornecedor encontrado.',
            style: GoogleFonts.poppins(color: Colors.grey.shade600)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fornecedores.length,
      itemBuilder: (context, i) {
        final f = fornecedores[i].fornecedor;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: widget.primary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: widget.primary.withValues(alpha: 0.1),
                child: Icon(Icons.storefront, color: widget.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.razaoSocial,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 14.5, color: Colors.black87)),
                    Text(f.email,
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
