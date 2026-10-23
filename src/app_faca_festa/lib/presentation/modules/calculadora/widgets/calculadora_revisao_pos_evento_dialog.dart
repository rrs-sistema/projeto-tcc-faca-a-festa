import 'package:flutter/material.dart';
import '../controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/revisao_pos_evento_service.dart';

class CalculadoraRevisaoPosEventoDialog extends StatefulWidget {
  const CalculadoraRevisaoPosEventoDialog(
      {super.key, required this.controller, required this.onMedir});
  final CalculadoraFestaController controller;
  final ValueChanged<String> onMedir;
  @override
  State<CalculadoraRevisaoPosEventoDialog> createState() => _RevisaoState();
}

class _RevisaoState extends State<CalculadoraRevisaoPosEventoDialog> {
  final respostas = <String, dynamic>{};
  late final String menu;
  late final int revisao;
  bool ocupada = false;
  String? erro;
  @override
  void initState() {
    super.initState();
    menu = widget.controller.idCardapioAtual;
    revisao =
        (widget.controller.operacaoEvento['revisao'] as num? ?? 0).toInt();
    final anterior = OperacaoCalculadoraService.mapa(
        OperacaoCalculadoraService.mapa(
            widget.controller.operacaoEvento['revisao_pos_evento'])[menu]);
    respostas.addAll(OperacaoCalculadoraService.mapa(anterior['itens']));
  }

  Future<bool> salvar(bool concluir) async {
    if (ocupada) return false;
    setState(() {
      ocupada = true;
      erro = null;
    });
    try {
      final c = widget.controller;
      if (c.idCardapioAtual != menu) {
        throw StateError('A refeição mudou. Reabra a revisão.');
      }
      final ids = c.itensCardapio.map((i) => i.idItem).toSet();
      if (concluir && !respostas.keys.toSet().containsAll(ids)) {
        throw StateError('Avalie cada item ou selecione “Não sei avaliar”.');
      }
      await c.alterarOperacao({
        'tipo': 'revisao_pos_evento',
        'id_cardapio': menu,
        'revisao': revisao,
        'itens': {
          for (final id in ids)
            if (respostas.containsKey(id)) id: respostas[id]
        },
        'concluir': concluir,
        'registrado_em': DateTime.now().toUtc().toIso8601String(),
      });
      if (mounted) Navigator.pop(context);
      return true;
    } catch (e) {
      if (mounted) {
        setState(() => erro = e.toString().replaceFirst('Bad state: ', ''));
      }
      return false;
    } finally {
      if (mounted) setState(() => ocupada = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !ocupada,
      child: AlertDialog(
        title: Row(children: [
          const Icon(Icons.fact_check_outlined),
          const SizedBox(width: 12),
          const Expanded(child: Text('Depois da festa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
          IconButton(
              onPressed: ocupada ? null : () => Navigator.pop(context),
              tooltip: 'Fechar',
              icon: const Icon(Icons.close))
        ]),
        content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text(widget.controller.tituloCardapio,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  const Text(
                      'Sobrou, faltou ou foi suficiente? Pesagens são opcionais.'),
                  for (final item in widget.controller.itensCardapio)
                    Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                  value: RevisaoPosEventoService.resultados
                                          .containsKey(respostas[item.idItem])
                                      ? respostas[item.idItem] as String
                                      : null,
                                  isExpanded: true,
                                  decoration:
                                      InputDecoration(labelText: item.nome),
                                  items: RevisaoPosEventoService
                                      .resultados.entries
                                      .map((e) => DropdownMenuItem(
                                          value: e.key, child: Text(e.value)))
                                      .toList(),
                                  onChanged: ocupada
                                      ? null
                                      : (v) => setState(
                                          () => respostas[item.idItem] = v)),
                              TextButton.icon(
                                  onPressed: ocupada
                                      ? null
                                      : () async {
                                          if (await salvar(false)) widget.onMedir(item.idItem);
                                        },
                                  icon: const Icon(Icons.scale_outlined,
                                      size: 18),
                                  label:
                                      const Text('Tenho quantidades medidas')),
                            ])),
                  const SizedBox(height: 12),
                  const Text(
                      'Só medições calibram porções. A revisão não altera pagamentos ou estoque.',
                      style: TextStyle(fontSize: 12)),
                  if (erro != null)
                    Text(erro!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                ]))),
        actions: [
          TextButton(
              onPressed: ocupada ? null : () => salvar(false),
              child: const Text('Salvar para depois')),
          FilledButton(
              onPressed: ocupada ? null : () => salvar(true),
              child: Text(ocupada ? 'Salvando…' : 'Concluir revisão'))
        ],
      ));
}
