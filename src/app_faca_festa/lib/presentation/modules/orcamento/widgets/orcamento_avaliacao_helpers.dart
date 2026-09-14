part of '../pages/orcamento_screen.dart';

void _abrirDialogAvaliacaoServico({
  required String idFornecedor,
  required String idOrcamento,
  required String idServico,
  required String nomeServico,
  required AppController appController,
  required EventoController eventoController,
  required AvaliacaoServicoController avaliacaoController,
  required EventThemeController themeController,
}) {
  final usuario = appController.usuarioLogado.value;
  final evento = eventoController.eventoAtualEntidade;

  Get.dialog(
    EnviarAvaliacaoDialog(
      tipo: TipoAvaliacao.servico,
      idFornecedor: idFornecedor,
      idServico: idServico,
      idCliente: usuario!.idUsuario,
      nomeCliente: usuario.nome,
      idEvento: evento!.idEvento,
      nomeEventoAtual: evento.nomeEvento,
      controller: avaliacaoController,
      themeController: themeController,
    ),
  );
}

String _mensagemMotivoNaoAvaliar(Orcamento o, double totalPago) {
  final custo = o.custoEstimado ?? 0;

  if (o.status != StatusOrcamento.fechado) {
    return "Avaliação liberada após fechar.";
  }

  if (totalPago < custo) {
    final falta = custo - totalPago;
    return "Pague o restante (R\$ ${falta.toStringAsFixed(2)}) para avaliar.";
  }

  return "Avaliação não disponível.";
}
