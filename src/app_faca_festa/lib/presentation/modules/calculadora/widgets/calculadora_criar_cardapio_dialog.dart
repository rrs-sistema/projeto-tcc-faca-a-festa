import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:flutter/material.dart';
import 'package:app_faca_festa/domain/services/plano_evento_service.dart';

/// Mantém a revisão aberta em caso de falha. Uma nova tentativa usa a mesma
/// identidade no repositório e não substitui um cardápio já criado.
class CalculadoraCriarCardapioDialog extends StatefulWidget {
  const CalculadoraCriarCardapioDialog(
      {super.key, required this.destino, required this.onSalvar});
  final DestinoPlanoEvento destino;
  final Future<void> Function(String titulo) onSalvar;
  @override
  State<CalculadoraCriarCardapioDialog> createState() => _Estado();
}

class _Estado extends State<CalculadoraCriarCardapioDialog> {
  late final titulo = TextEditingController(
      text: widget.destino.cardapio.titulo
          .replaceAll(' sugerido', '')
          .replaceAll(' sugerida', ''));
  bool salvando = false;
  String? erro;
  @override
  void dispose() {
    titulo.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (salvando) return;
    if (titulo.text.trim().isEmpty || titulo.text.trim().length > 80) {
      setState(() => erro = 'Informe um nome de até 80 caracteres.');
      return;
    }
    setState(() {
      salvando = true;
      erro = null;
    });
    try {
      await widget.onSalvar(titulo.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          erro = error is StateError
              ? error.message.toString()
              : 'Não foi possível criar. Confira conexão, permissão de organizador e se o planejamento mudou. Você pode tentar novamente; seus dados anteriores são preservados.';
          salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !salvando,
      child: AlertDialog(
        title: const Text('Criar seu cardápio',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text(
                      '${widget.destino.pessoas} pessoas · ${widget.destino.resultados.length} itens'),
                  const SizedBox(height: 12),
                  TextField(
                      controller: titulo,
                      enabled: !salvando,
                      maxLength: 80,
                      decoration: const InputDecoration(
                          labelText: 'Nome do cardápio',
                          border: OutlineInputBorder(),
                          isDense: true)),
                  for (final r in widget.destino.resultados) ...[
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('${r.nome} · ${r.quantidadeFormatada}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600))),
                    Text(
                        widget.destino.proposta.regras
                                    .firstWhere((p) =>
                                        p.premissas['id_item_cardapio'] ==
                                        r.idItemCardapio)
                                    .premissas['proposta_apenas_servir'] ==
                                true
                            ? 'Pronto para servir · compra ainda não convertida'
                            : 'Medida de referência · confira antes de comprar',
                        style: const TextStyle(fontSize: 12)),
                  ],
                  const SizedBox(height: 12),
                  if (widget.destino.resultados
                      .any((r) => r.valorUnitarioMedio <= 0))
                    const Text('Preços pendentes · custo ainda incompleto',
                        style: TextStyle(fontSize: 12)),
                  const Text(
                      'Serão criados o cardápio com quantidades sugeridas e uma simulação no seu histórico. Compras, pagamentos e quantidades finais precisam de confirmação própria.',
                      style: TextStyle(fontSize: 12)),
                  ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Premissas e referências',
                          style: TextStyle(fontSize: 14)),
                      children: [
                        for (final r in widget.destino.proposta.regras)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                  '${r.nome}: ${NumericInput.quantidade(r.quantidadePorConvidadoEquivalente)} ${r.unidade.label} por adulto equivalente. ${r.premissas['proposta_motivo'] ?? ''} Fonte: ${r.premissas['fonte'] ?? r.premissas['referencia_url'] ?? 'consulte a regra'}.',
                                  style: const TextStyle(fontSize: 12))),
                        for (final p in widget.destino.pendencias)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(p,
                                  style: const TextStyle(fontSize: 12))),
                      ]),
                  if (erro != null)
                    Text(erro!,
                        key: const Key('erro_criar_cardapio'),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                ]))),
        actions: [
          TextButton(
              onPressed: salvando ? null : () => Navigator.pop(context),
              child: const Text('Voltar')),
          FilledButton.icon(
              onPressed: salvando ? null : salvar,
              icon: salvando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(salvando ? 'Criando…' : 'Criar cardápio')),
        ],
      ));
}
