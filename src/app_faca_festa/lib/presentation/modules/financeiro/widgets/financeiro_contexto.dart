import 'package:flutter/material.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';

/// Ajuda disponível por toque, mouse e teclado; não depende de hover.
class FinanceiroAjuda extends StatelessWidget {
  const FinanceiroAjuda(
      {super.key,
      required this.itens,
      this.titulo = 'Como funciona esta tela'});

  final Map<String, String> itens;
  final String titulo;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AdminPalette.primary.withValues(alpha: .14))),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: const Icon(Icons.help_outline_rounded,
              color: AdminPalette.primary),
          title: Text(titulo,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: itens.entries
              .map((e) => Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(e.key,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(e.value,
                              style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AdminPalette.muted)),
                        ]),
                  ))
              .toList(),
        ),
      );
}

class FinanceiroProximoPasso extends StatelessWidget {
  const FinanceiroProximoPasso(
      {super.key,
      required this.titulo,
      required this.mensagem,
      this.bloqueado = false});
  final String titulo;
  final String mensagem;
  final bool bloqueado;

  @override
  Widget build(BuildContext context) {
    final cor = bloqueado ? AdminPalette.warning : AdminPalette.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cor.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cor.withValues(alpha: .18))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(
            bloqueado
                ? Icons.lock_outline_rounded
                : Icons.assistant_direction_outlined,
            color: cor,
            size: 22),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(mensagem,
              style: const TextStyle(
                  fontSize: 14, height: 1.45, color: AdminPalette.muted)),
        ])),
      ]),
    );
  }
}

const ajudaFinanceira = {
  'Valor contratado':
      'Total dos serviços com contratação confirmada. Oportunidades representam estimativas e ainda não são cobranças confirmadas.',
  'Comissão da plataforma':
      'Remuneração da plataforma pelo contrato. Comissão gerada é prevista; comissão recebida já possui registro de recebimento.',
  'Recebido do cliente':
      'Dinheiro conferido e vinculado à contratação. Uma declaração de pagamento ainda não conferida não libera repasse.',
  'Saldo do fornecedor':
      'Valor ainda não pago ao fornecedor. Saldo pendente não significa dinheiro disponível para pagar.',
  'Quando pagar o fornecedor':
      'Após o evento finalizado ou com autorização explícita do organizador, respeitando saldo confirmado e ausência de bloqueios. A transferência bancária é manual.',
};

const ajudaMediacao = {
  'Ver contratação':
      'Consulte as partes, a execução do serviço, os valores e os registros de mediação.',
  'Recebimentos e repasses':
      'Confira o recebimento, vincule o dinheiro ao contrato e prepare o pagamento ao fornecedor. Vincular um recebimento não transfere dinheiro.',
  'Mediação e bloqueios':
      'Registre a análise e a decisão antes de encerrar o caso. Encerrar a mediação não paga nem reembolsa valores.',
  'Regularizar a execução':
      'Após uma decisão, a regularização cancela reservas pendentes e revoga autorizações antecipadas anteriores. Confira novamente antes de preparar outro repasse.',
};
