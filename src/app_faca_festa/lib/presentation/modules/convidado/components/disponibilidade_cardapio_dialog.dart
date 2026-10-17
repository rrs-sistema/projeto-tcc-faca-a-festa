import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:flutter/material.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/disponibilidade_cardapio.dart';

/// Mesmo registro na calculadora e no cardápio, sem alterar quantidades planejadas.
class DisponibilidadeCardapioDialog extends StatefulWidget {
  const DisponibilidadeCardapioDialog(
      {super.key,
      required this.item,
      required this.onSalvar,
      this.unidade,
      this.estado});
  final CardapioItem item;
  final String? unidade, estado;
  final Future<void> Function(DisponibilidadeCardapio) onSalvar;
  @override
  State<DisponibilidadeCardapioDialog> createState() =>
      _DisponibilidadeCardapioDialogState();
}

class _DisponibilidadeCardapioDialogState
    extends State<DisponibilidadeCardapioDialog> {
  final form = GlobalKey<FormState>();
  late final TextEditingController comprado, estoque;
  late String unidade, estado;
  bool salvando = false;
  String? erro;
  static const unidades = ['kg', 'L', 'un', 'cento', 'garrafa', 'pacote'];
  static const estados = [
    'Preciso confirmar',
    'cru',
    'seco',
    'pronto',
    'não se aplica'
  ];
  @override
  void initState() {
    super.initState();
    final inicial = widget.item.disponibilidade;
    comprado = TextEditingController(
        text: inicial?.comprado.toString().replaceAll('.', ',') ?? '0');
    estoque = TextEditingController(text: '0');
    unidade = inicial?.unidade ?? widget.unidade ?? widget.item.unidade;
    if (!unidades.contains(unidade)) unidade = 'un';
    estado = inicial?.estado ?? widget.estado ?? 'Preciso confirmar';
    if (!estados.contains(estado)) estado = 'Preciso confirmar';
  }

  @override
  void dispose() {
    comprado.dispose();
    estoque.dispose();
    super.dispose();
  }

  double? numero(String? s) => NumericInput.parse(s);
  InputDecoration campo(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FAF9),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));
  Future<void> salvar() async {
    if (!form.currentState!.validate()) return;
    final value = DisponibilidadeCardapio(
        comprado: numero(comprado.text)!,
        estoque: 0,
        unidade: unidade,
        estado: estado,
        nome: widget.item.nome,
        publico: widget.item.publicoAlvo.name);
    if (!value.valida) {
      setState(() => erro = 'Confira as quantidades informadas.');
      return;
    }
    setState(() {
      salvando = true;
      erro = null;
    });
    try {
      await widget.onSalvar(value);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          salvando = false;
          erro =
              'Não foi possível salvar. Confira se o item ou o cálculo mudou e tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !salvando,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(children: [
                    const Expanded(
                        child: Text('O que já tenho',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700))),
                    IconButton(
                        tooltip: 'Fechar',
                        onPressed:
                            salvando ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded)),
                  ])),
              const Divider(height: 1),
              Flexible(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                          key: form,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(widget.item.nome,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                const Text(
                                    'Registre apenas o que está disponível e reservado para esta refeição. Não inclua o que o fornecedor ainda vai entregar.',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(height: 16),
                                Theme(
                                    data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                        tilePadding: EdgeInsets.zero,
                                        initiallyExpanded:
                                            estado == 'Preciso confirmar',
                                        title: Text(
                                            'Medida: $unidade · $estado',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                        children: [
                                          DropdownButtonFormField<String>(
                                              isExpanded: true,
                                              value: unidade,
                                              decoration:
                                                  campo('Unidade do registro'),
                                              items: unidades
                                                  .map((u) => DropdownMenuItem(
                                                      value: u, child: Text(u)))
                                                  .toList(),
                                              onChanged: salvando
                                                  ? null
                                                  : (v) => setState(
                                                      () => unidade = v!)),
                                          const SizedBox(height: 12),
                                          DropdownButtonFormField<String>(
                                              isExpanded: true,
                                              value: estado,
                                              validator: (v) => v ==
                                                      'Preciso confirmar'
                                                  ? 'Confirme o estado do item'
                                                  : null,
                                              decoration:
                                                  campo('Estado do item'),
                                              items: estados
                                                  .map((e) => DropdownMenuItem(
                                                      value: e, child: Text(e)))
                                                  .toList(),
                                              onChanged: salvando
                                                  ? null
                                                  : (v) => setState(
                                                      () => estado = v!)),
                                          const SizedBox(height: 12),
                                        ])),
                                const SizedBox(height: 12),
                                for (final entry in {
                                  comprado: 'Comprado para esta refeição',
                                  estoque: 'Estoque: gerenciado na calculadora'
                                }.entries) ...[
                                  TextFormField(
                                      controller: entry.key,
                                      enabled:
                                          !salvando && entry.key != estoque,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      inputFormatters: [NumericInput.decimal()],
                                      decoration: campo(entry.value)
                                          .copyWith(suffixText: unidade),
                                      validator: (v) {
                                        final n = numero(v);
                                        return n == null || !n.isFinite || n < 0
                                            ? 'Informe zero ou uma quantidade válida'
                                            : null;
                                      }),
                                  const SizedBox(height: 12),
                                ],
                                const Text(
                                    'Cadastre e reserve o estoque em Calculadora → Estoque e reservas da festa. Não inclua o mesmo lote em Comprado. Ao salvar, o estoque local antigo será zerado; transfira-o ao controle central antes de concluir as compras.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569))),
                                if (erro != null)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(erro!,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error))),
                              ])))),
              const Divider(height: 1),
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: salvando ? null : salvar,
                          style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48)),
                          child: Text(salvando
                              ? 'Salvando…'
                              : 'Salvar disponibilidade')))),
            ])),
      ));
}
