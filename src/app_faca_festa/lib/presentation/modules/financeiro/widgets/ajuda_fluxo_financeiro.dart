import 'package:flutter/material.dart';

enum PerfilAjudaFinanceira { organizador, fornecedor, administrador }

typedef ContextoAjudaFinanceira = ({
  String contrato,
  String situacao,
  String proximoPasso,
  String? responsavel,
});

class AjudaFluxoFinanceiro extends StatelessWidget {
  const AjudaFluxoFinanceiro({
    super.key,
    required this.perfil,
    this.contrato,
    this.rotulo,
  });

  final PerfilAjudaFinanceira perfil;
  final ContextoAjudaFinanceira? contrato;
  final String? rotulo;

  String get _titulo => switch (perfil) {
        PerfilAjudaFinanceira.organizador => 'Entenda o pagamento',
        PerfilAjudaFinanceira.fornecedor => 'Como funciona o repasse',
        PerfilAjudaFinanceira.administrador => 'Guia de recebimento e repasse',
      };

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _abrir(context),
      icon: const Icon(Icons.help_outline_rounded, size: 18),
      label: Text(rotulo ?? _titulo),
    );
  }

  void _abrir(BuildContext context) {
    final atual = contrato;
    final responsavel = switch (atual?.responsavel) {
      'cliente' => 'Organizador',
      'fornecedor' => 'Fornecedor',
      'plataforma' || 'configuracao' => 'Plataforma',
      final nome => nome,
    };
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) {
        final tema = Theme.of(context);
        return FractionallySizedBox(
          heightFactor: 0.86,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(_titulo, style: tema.textTheme.titleLarge)),
                    IconButton(
                      tooltip: 'Fechar ajuda',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    if (atual != null) ...[
                      Card(
                        elevation: 0,
                        color: tema.colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(atual.contrato,
                                  style: tema.textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text(atual.situacao),
                              const SizedBox(height: 12),
                              Text('Próximo passo',
                                  style: tema.textTheme.titleSmall),
                              Text(atual.proximoPasso),
                              if (responsavel != null &&
                                  responsavel.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('Quem age • $responsavel'),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    for (final (titulo, texto) in _etapas[perfil]!)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titulo, style: tema.textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(texto),
                          ],
                        ),
                      ),
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

const _etapas = {
  PerfilAjudaFinanceira.organizador: [
    (
      'Pague e declare',
      'Siga as instruções de pagamento da plataforma. Depois de pagar, declare o valor e envie o comprovante pelo app. A cobrança é manual.'
    ),
    (
      'Aguarde a conferência',
      'A plataforma confere a entrada e vincula o valor ao contrato. Até lá, o valor declarado continua em conferência e o saldo a pagar usa apenas os recebimentos confirmados.'
    ),
    (
      'Acompanhe a entrega e o repasse',
      'Confirme a entrega quando receber o serviço. O repasse depende do recebimento conferido e da finalização do evento. Para liberar antes disso, use Autorizar pagamento antecipado no contrato, se desejar. A plataforma ainda precisa conferir as demais condições.'
    ),
  ],
  PerfilAjudaFinanceira.fornecedor: [
    (
      'Valor previsto',
      'O líquido previsto é o valor a receber segundo as condições do contrato. O pagamento do cliente passa por conferência e vinculação na plataforma. O valor só entra no seu caixa quando o repasse é confirmado.'
    ),
    (
      'Repasse autorizado',
      'A plataforma reservou um valor para pagar. A liberação depende de recebimento conferido, evento finalizado ou autorização antecipada do organizador, além da política e dos bloqueios do contrato.'
    ),
    (
      'Repasse confirmado',
      'A plataforma registra a confirmação depois da transferência bancária. Para acompanhar a execução, informe a entrega após prestar o serviço. O cliente registra o aceite.'
    ),
  ],
  PerfilAjudaFinanceira.administrador: [
    (
      'Conferir e registrar o recebimento',
      'Consulte o evento. Compare a declaração e o comprovante com a entrada na conta. Registre o valor efetivamente recebido e a referência da transação.'
    ),
    (
      'Alocar ao contrato',
      'Selecione o recebimento conferido e vincule o valor ao contrato correto. O valor pode ficar disponível para alocação antes de aparecer no saldo do contrato.'
    ),
    (
      'Conferir a elegibilidade e autorizar',
      'Confira o saldo alocado, a comissão, a política ativa e eventuais bloqueios. A liberação exige evento finalizado ou autorização antecipada do organizador.'
    ),
    (
      'Transferir e confirmar',
      'Faça a transferência ao fornecedor pelo meio bancário adotado pela plataforma. Depois registre a confirmação com referência ou comprovante em Recebimentos e repasses.'
    ),
  ],
};
