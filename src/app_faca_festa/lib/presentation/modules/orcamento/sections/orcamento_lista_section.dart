part of '../pages/orcamento_screen.dart';

extension _OrcamentoListaSection on _OrcamentoScreenState {
  Widget _categoriaCard(
    BuildContext context,
    Orcamento orcamento,
    Color primary,
    List<Widget> gastos,
    bool mostrarBotaoAddGasto, {
    required EventThemeController themeController,
    required OrcamentoController orcamentoController,
  }) {
    final double custo = orcamento.custoEstimado ?? 0;
    final bool servicoContratado = !mostrarBotaoAddGasto;
    final double totalPago = servicoContratado
        ? (orcamento.isFechado ? custo : 0)
        : orcamentoController.totalPagoDoOrcamento(orcamento.idOrcamento);
    final double percentPago =
        custo > 0 ? (totalPago / custo).clamp(0.0, 1.0) : 0.0;
    final String estado = servicoContratado
        ? orcamento.status.label
        : totalPago <= 0
            ? 'Nada pago'
            : totalPago >= custo && custo > 0
                ? 'Pago'
                : 'Pago ${_reais(totalPago)}';

    final bool podeAvaliar = servicoContratado &&
        orcamento.status == StatusOrcamento.fechado &&
        totalPago >= custo &&
        orcamento.idServicoFornecido != null &&
        orcamento.idServicoFornecido!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: primary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            iconColor: primary.withValues(alpha: 0.9),
            collapsedIconColor: Colors.grey.shade500,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            childrenPadding:
                const EdgeInsets.only(left: 14, right: 14, bottom: 10),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        primary.withValues(alpha: 0.95),
                        primary.withValues(alpha: 0.65),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Icon(
                    servicoContratado
                        ? Icons.storefront_rounded
                        : Icons.payments_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        orcamento.anotacoes?.trim().isNotEmpty == true
                            ? orcamento.anotacoes!.trim()
                            : (orcamento.nomeFornecedor ?? 'Sem nome'),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        estado,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: percentPago >= 1 && custo > 0
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                        ),
                      ),
                      if (!servicoContratado) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentPago,
                            minHeight: 4,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              percentPago >= 1
                                  ? Colors.green.shade500
                                  : primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _reais(custo),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            children: [
              ...gastos,
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (mostrarBotaoAddGasto)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: primary.withValues(alpha: 0.1),
                        foregroundColor: primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 40),
                      ),
                      onPressed: () => _showAddGastoDialog(
                        context,
                        idOrcamento: orcamento.idOrcamento,
                        categoria: orcamento.anotacoes ?? '',
                        custoEstimado: orcamento.custoEstimado ?? 0,
                        themeController: themeController,
                        orcamentoController: orcamentoController,
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: Text(
                        'Registrar gasto',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      minimumSize: const Size(44, 40),
                    ),
                    onPressed: () async {
                      final confirm = await Get.dialog<bool>(
                        AlertDialog(
                          title: Text(
                            'Excluir orçamento',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          content: Text(
                            'Deseja realmente excluir "${orcamento.anotacoes}"?',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Get.back(result: true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await orcamentoController
                            .excluirOrcamento(orcamento.idOrcamento);

                        Get.snackbar(
                          'Orçamento removido',
                          'O orçamento "${orcamento.anotacoes}" foi excluído.',
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                        );
                      }
                    },
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 16, color: Colors.redAccent.shade700),
                    label: Text(
                      'Excluir',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.redAccent.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              if (!podeAvaliar && servicoContratado)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        _mensagemMotivoNaoAvaliar(orcamento, totalPago),
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gastoItem(
    BuildContext context, {
    String? idOrcamento,
    required String? idServico,
    required String idFornecedor,
    required String? idGasto,
    required String nome,
    required double custo,
    required double pago,
    required EventThemeController themeController,
    required AppController appController,
    required EventoController eventoController,
    required AvaliacaoServicoController avaliacaoController,
    required OrcamentoGastoController? gastoController,
  }) {
    final restante = (custo - pago).clamp(0.0, custo);
    final percentPago = (custo > 0) ? (pago / custo).clamp(0.0, 1.0) : 0.0;

    final podeAvaliar = restante == 0 && idGasto != null && idOrcamento != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.8),
          ],
        ),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 16, color: Colors.teal.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  nome,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              if (restante == 0)
                Icon(Icons.check_circle_rounded,
                    color: Colors.green.shade600, size: 18)
              else if (idOrcamento != null && idGasto != null)
                InkWell(
                  onTap: () async {
                    Biblioteca.showConfirmDialog(
                      context,
                      title: 'Marcar como pago',
                      message:
                          'Confirma que $nome foi pago por inteiro?',
                      confirmLabel: 'Pagar',
                      color: themeController.primaryColor.value,
                      onConfirm: () async {
                        EasyLoading.show(status: 'Processando...');
                        final gastoC = gastoController ??
                            orcamentoController.gastoController(idOrcamento);

                        await gastoC.marcarComoPago(
                            idOrcamento, idGasto, custo);

                        gastoC.escutarGastos(idOrcamento);

                        Get.snackbar(
                          "Pago!",
                          "$nome marcado como pago.",
                          backgroundColor: Colors.green.shade600,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
                        );
                        EasyLoading.dismiss();
                        return true;
                      },
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    alignment: Alignment.center,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      "Pagar",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ),
              if (idOrcamento != null && idGasto != null)
                InkWell(
                  onTap: () =>
                      _confirmarExcluirGasto(context, idOrcamento, idGasto),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(10, 8, 4, 8),
                    child: Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFE57373), size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentPago,
              minHeight: 4,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                percentPago >= 1 ? Colors.green.shade500 : Colors.teal.shade400,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pago: ${_reais(pago)}',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal.shade800),
              ),
              Text(
                'Restante: ${_reais(restante)}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: restante > 0
                      ? Colors.orange.shade700
                      : Colors.green.shade700,
                ),
              ),
            ],
          ),
          if (podeAvaliar)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 24),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () {
                  _abrirDialogAvaliacaoServico(
                    idServico: idServico ?? '',
                    idFornecedor: idFornecedor,
                    idOrcamento: idOrcamento,
                    nomeServico: nome,
                    appController: appController,
                    eventoController: eventoController,
                    avaliacaoController: avaliacaoController,
                    themeController: themeController,
                  );
                },
                icon: const Icon(Icons.star_rate_rounded,
                    color: Colors.amber, size: 16),
                label: Text(
                  "Avaliar",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Colors.amber.shade700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmarExcluirGasto(
      BuildContext context, String idOrcamento, String idGasto) async {
    final gastoController = orcamentoController.gastoController(idOrcamento);
    await Biblioteca.showConfirmDialog(
      context,
      title: 'Excluir gasto',
      message: 'Este lançamento sai do item. O previsto do item não muda.',
      confirmLabel: 'Excluir',
      color: Colors.red,
      onConfirm: () async {
        await gastoController.removerGasto(idOrcamento, idGasto);
        await Future.delayed(const Duration(milliseconds: 150));
        return await Future.value(true);
      },
    );
  }
}
