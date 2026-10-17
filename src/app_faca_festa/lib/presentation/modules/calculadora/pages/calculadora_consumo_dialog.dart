import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:flutter/material.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/registro_consumo_calculadora.dart';
import 'calculadora_rendimento_dialog.dart';

class CalculadoraConsumoDialog extends StatefulWidget {
  final String idEvento;
  final RegistroConsumoCalculadora? anterior;
  final ItemEstimativaFinanceira regra;
  final String Function(ItemEstimativaFinanceira, {int? duracaoObservada})
      contexto;
  final Future<void> Function(RegistroConsumoCalculadora) onSalvar;
  const CalculadoraConsumoDialog(
      {super.key,
      required this.idEvento,
      required this.regra,
      this.anterior,
      required this.contexto,
      required this.onSalvar});
  @override
  State<CalculadoraConsumoDialog> createState() => _ConsumoState();
}

class _ConsumoState extends State<CalculadoraConsumoDialog> {
  final receita = TextEditingController(), adultos = TextEditingController();
  final criancas = TextEditingController(text: '0'),
      bebes = TextEditingController(text: '0');
  final quantidade = TextEditingController(),
      sobra = TextEditingController(text: '0');
  final desperdicio = TextEditingController(text: '0');
  final duracao = TextEditingController(), servicos = TextEditingController();
  bool faltou = false, salvando = false;
  String? erro;
  DateTime? diaConsumo;
  ({double entrada, double saida})? medicao;
  @override
  void initState() {
    super.initState();
    diaConsumo = widget.anterior?.dataConsumo;
    receita.text = widget.regra.premissas['receita']?.toString() ?? '';
    servicos.text = widget.regra.numeroServicos.toString();
    final anterior = widget.anterior;
    if (anterior != null &&
        anterior.idEvento == widget.idEvento &&
        anterior.regra.id == widget.regra.id) {
      adultos.text = anterior.adultos.toString();
      criancas.text = anterior.criancas.toString();
      bebes.text = anterior.bebes.toString();
      duracao.text = anterior.duracaoHoras.toString();
      servicos.text = anterior.regra.numeroServicos.toString();
      quantidade.text = anterior.disponibilizado.toString();
      sobra.text = anterior.sobra.toString();
      desperdicio.text = anterior.desperdicio.toString();
      faltou = anterior.faltou;
      if (anterior.pesoBaseMedido != null &&
          anterior.pesoProntoMedido != null) {
        medicao = (
          entrada: anterior.pesoBaseMedido!,
          saida: anterior.pesoProntoMedido!
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      receita,
      adultos,
      criancas,
      bebes,
      quantidade,
      sobra,
      desperdicio,
      duracao,
      servicos
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double numero(TextEditingController c) =>
      NumericInput.parse(c.text) ?? double.nan;
  int inteiro(TextEditingController c) => int.tryParse(c.text) ?? -1;
  Widget campo(TextEditingController c, String texto, {bool inteiro = false}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextField(
              controller: c,
              keyboardType: TextInputType.numberWithOptions(decimal: !inteiro),
              inputFormatters:
                  inteiro ? NumericInput.inteiro : [NumericInput.decimal()],
              decoration: InputDecoration(
                  labelText: texto, border: const OutlineInputBorder())));

  Future<void> salvar() async {
    try {
      if (!numero(servicos).isFinite ||
          numero(servicos) <= 0 ||
          inteiro(duracao) <= 0) {
        throw ArgumentError(
            'Informe serviços e duração observados maiores que zero.');
      }
      final regra = widget.regra.copyWith(premissas: {
        ...widget.regra.premissas,
        'receita': receita.text.trim(),
        'numero_servicos': numero(servicos)
      });
      if (diaConsumo == null) {
        throw ArgumentError('Informe a data em que o consumo aconteceu.');
      }
      final r = RegistroConsumoCalculadora(
          idEvento: widget.idEvento,
          contexto: widget.contexto(regra, duracaoObservada: inteiro(duracao)),
          dataRegistro: DateTime.now(),
          dataConsumo: diaConsumo,
          regra: regra,
          adultos: inteiro(adultos),
          criancas: inteiro(criancas),
          bebes: inteiro(bebes),
          duracaoHoras: inteiro(duracao),
          disponibilizado: numero(quantidade),
          sobra: numero(sobra),
          desperdicio: numero(desperdicio),
          faltou: faltou,
          pesoBaseMedido: medicao?.entrada,
          pesoProntoMedido: medicao?.saida);
      r.validar();
      setState(() {
        salvando = true;
        erro = null;
      });
      await widget.onSalvar(r);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          erro = e is ArgumentError
              ? e.message.toString()
              : 'Não foi possível salvar. O registro não foi confirmado; tente novamente.';
          salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unidade =
        widget.regra.premissas['unidade_consumo'] ?? widget.regra.unidade.label;
    return PopScope(
        canPop: !salvando,
        child: Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 780),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Consumo real: ${widget.regra.nome}',
                        style: Theme.of(context).textTheme.titleLarge)),
                Flexible(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                  'Preencha depois da festa. Registre o alimento pronto na mesma medida em todos os campos. Não subtraia sobra pronta de peso cru comprado.'),
                              const Text(
                                  'Salvar novamente substitui o registro deste item nesta simulação. Você pode conferir o último registro na comparação com seu histórico.'),
                              if (widget.anterior != null)
                                const Text(
                                    'Último registro real desta festa preenchido para conferência. Nenhuma quantidade foi copiada da estimativa.',
                                    style: TextStyle(fontSize: 12)),
                              const SizedBox(height: 16),
                              TextField(
                                  controller: receita,
                                  decoration: const InputDecoration(
                                      labelText: 'Receita ou preparo',
                                      helperText:
                                          'Use a mesma identificação na regra de uma próxima festa.')),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                  onPressed: salvando
                                      ? null
                                      : () async {
                                          final dia = await showDatePicker(
                                              context: context,
                                              initialDate:
                                                  diaConsumo ?? DateTime.now(),
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime.now());
                                          if (dia != null && mounted) {
                                            setState(() => diaConsumo = dia);
                                          }
                                        },
                                  icon:
                                      const Icon(Icons.calendar_today_outlined),
                                  label: Text(diaConsumo == null
                                      ? 'Informar data do consumo'
                                      : 'Consumo em ${diaConsumo!.day.toString().padLeft(2, '0')}/${diaConsumo!.month.toString().padLeft(2, '0')}/${diaConsumo!.year}')),
                              const SizedBox(height: 12),
                              campo(
                                  adultos, 'Adultos que realmente participaram',
                                  inteiro: true),
                              campo(criancas,
                                  'Crianças que realmente participaram',
                                  inteiro: true),
                              campo(bebes, 'Bebês que realmente participaram',
                                  inteiro: true),
                              campo(duracao,
                                  'Duração observada do serviço (horas)',
                                  inteiro: true),
                              campo(servicos,
                                  'Quantas vezes esta porção foi servida'),
                              campo(quantidade,
                                  'Total pronto disponibilizado ($unidade)'),
                              campo(sobra,
                                  'Sobra pronta que não foi servida ($unidade)'),
                              campo(desperdicio,
                                  'Desperdício medido nos pratos ($unidade)'),
                              const Text(
                                  'Consumo observado = disponibilizado − sobra − desperdício. Informe medições, não a quantidade sugerida pela calculadora.'),
                              CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: faltou,
                                  title: const Text('Faltou este item'),
                                  subtitle: const Text(
                                      'O registro será preservado e impedirá adotar uma redução baseada nesse histórico.'),
                                  onChanged: salvando
                                      ? null
                                      : (v) =>
                                          setState(() => faltou = v ?? false)),
                              if (widget.regra.premissas['estado'] !=
                                  'pronto') ...[
                                Text(
                                    'A porção da regra está em ${widget.regra.premissas['estado'] ?? 'estado não definido'}. '
                                    'Para compará-la à comida pronta, meça o rendimento deste preparo.'),
                                TextButton.icon(
                                    onPressed: salvando
                                        ? null
                                        : () async {
                                            final r = await showDialog<
                                                    ({
                                                      double entrada,
                                                      double saida
                                                    })>(
                                                context: context,
                                                builder: (_) =>
                                                    CalculadoraRendimentoDialog(
                                                        unidade: unidade
                                                            .toString()));
                                            if (r != null && mounted) {
                                              setState(() => medicao = r);
                                            }
                                          },
                                    icon: const Icon(Icons.scale),
                                    label: Text(medicao == null
                                        ? 'Informar rendimento medido'
                                        : 'Rendimento: ${(medicao!.saida / medicao!.entrada).toStringAsFixed(2)}')),
                              ],
                              if (erro != null)
                                Text(erro!,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error)),
                              const SizedBox(height: 16),
                            ]))),
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: salvando ? null : salvar,
                              child: Text(salvando
                                  ? 'Salvando…'
                                  : 'Salvar consumo e simulação'))),
                      TextButton(
                          onPressed:
                              salvando ? null : () => Navigator.pop(context),
                          child: const Text('Cancelar')),
                    ])),
              ])),
        ));
  }
}
