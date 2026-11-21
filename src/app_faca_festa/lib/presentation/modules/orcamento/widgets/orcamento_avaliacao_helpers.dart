part of '../pages/orcamento_screen.dart';

extension _OrcamentoAvaliacao on _OrcamentoScreenState {
  Widget _avaliacaoDoServico(Orcamento orcamento, String? idServico) {
    final servico = idServico?.trim() ?? '';
    final fornecedor = orcamento.idFornecedor?.trim() ?? '';
    if (!orcamento.isFechado ||
        servico.isEmpty ||
        fornecedor.isEmpty ||
        orcamento.idOrcamento.isEmpty ||
        orcamento.idEvento.isEmpty) {
      return const SizedBox.shrink();
    }

    if (orcamento.estadoExecucao == 'aceito') {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () {
            final usuario = appController.usuarioLogado.value;
            if (usuario == null) return;
            final evento = eventoController.eventoAtualEntidade;
            mostrarAvaliarContratacao(
              context,
              idFornecedor: fornecedor,
              idEvento: orcamento.idEvento,
              idOrcamento: orcamento.idOrcamento,
              idServico: servico,
              nomeFornecedor: orcamento.nomeFornecedor,
              nomeEvento: evento?.idEvento == orcamento.idEvento
                  ? evento!.nomeEvento
                  : null,
              controller: avaliacaoController,
              themeController: themeController,
            );
          },
          icon: const Icon(Icons.star_outline_rounded),
          label: const Text('Avaliar contratação'),
        ),
      );
    }

    final mensagem = switch (orcamento.estadoExecucao) {
      'entrega_informada' =>
        'Confirme a entrega no acompanhamento para avaliar.',
      'contestado' => 'A entrega está em contestação.',
      'cancelado_execucao' => 'A entrega foi cancelada.',
      null =>
        'A avaliação abre depois do aceite da entrega, com a nota do fornecedor e a deste serviço.',
      _ => 'Aguarde o fornecedor registrar a entrega para poder confirmá-la.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(mensagem, style: Theme.of(context).textTheme.bodySmall),
        TextButton.icon(
          onPressed: () =>
              Get.toNamed('/acompanhamento-organizador', arguments: {
            'idEvento': orcamento.idEvento,
            'idOrcamento': orcamento.idOrcamento,
          }),
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('Acompanhar entrega'),
        ),
      ],
    );
  }
}
