import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/fornecedor/fornecedor_controller.dart';
import './../../../../controllers/contacao/solicitacoes_controller.dart';
import 'solicitacao/solicitacao_fornecedor_card.dart';

class SolicitacoesSection extends StatefulWidget {
  const SolicitacoesSection({super.key});

  @override
  State<SolicitacoesSection> createState() => _SolicitacoesSectionState();
}

class _SolicitacoesSectionState extends State<SolicitacoesSection> {
  late final FornecedorController fornecedorController;
  late final SolicitacoesController solicitacoesController;
  String? _fornecedorInicializado;

  @override
  void initState() {
    super.initState();
    fornecedorController = Get.find<FornecedorController>();
    solicitacoesController = Get.put(SolicitacoesController(), permanent: false);
  }

  void _inicializarSeNecessario(String? idFornecedor) {
    if (idFornecedor == null || idFornecedor.isEmpty || _fornecedorInicializado == idFornecedor) {
      return;
    }
    _fornecedorInicializado = idFornecedor;
    Future.microtask(() => solicitacoesController.inicializar(idFornecedor));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fornecedor = fornecedorController.fornecedor.value;
      _inicializarSeNecessario(fornecedor?.idFornecedor);

      if (fornecedor == null || solicitacoesController.carregando.value) {
        return const _SolicitacoesShell(
          child: SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        );
      }

      if (solicitacoesController.erro.isNotEmpty) {
        return _SolicitacoesShell(
          child: _MensagemEstado(
            icon: Icons.error_outline_rounded,
            title: 'Não foi possível carregar as cotações',
            message: solicitacoesController.erro.value,
            color: Color(0xFFEF4444),
          ),
        );
      }

      final lista = solicitacoesController.solicitacoes;
      return _SolicitacoesShell(
        total: lista.length,
        child: lista.isEmpty
            ? const _MensagemEstado(
                icon: Icons.inbox_outlined,
                title: 'Nenhuma cotação pendente',
                message:
                    'Quando um organizador solicitar orçamento, as oportunidades aparecerão aqui com prioridade de atendimento.',
                color: Color(0xFF6366F1),
              )
            : ListView.separated(
                itemCount: lista.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    SolicitacaoFornecedorCard(solicitacao: lista[index]),
              ),
      );
    });
  }
}

class _SolicitacoesShell extends StatelessWidget {
  final Widget child;
  final int? total;
  const _SolicitacoesShell({required this.child, this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.inbox_rounded, size: 19, color: Color(0xFF111827)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cotações recebidas',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827))),
                    const SizedBox(height: 2),
                    Text('Oportunidades aguardando resposta do fornecedor.',
                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280))),
                  ],
                ),
              ),
              if (total != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(999)),
                  child: Text('$total pendente${total == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4338CA))),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MensagemEstado extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  const _MensagemEstado(
      {required this.icon, required this.title, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.14))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(message,
                    style: GoogleFonts.poppins(
                        fontSize: 12.2, color: const Color(0xFF6B7280), height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
