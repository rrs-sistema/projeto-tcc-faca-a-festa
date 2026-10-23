import 'package:app_faca_festa/domain/entities/confirmacao_configuracao_calculadora.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/services/capacidade_alimentos_service.dart';
import 'package:app_faca_festa/domain/services/plano_evento_service.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import '../controllers/calculadora_festa_controller.dart';
import 'calculadora_modal.dart';

class CalculadoraCapacidadeDialog extends StatefulWidget {
  const CalculadoraCapacidadeDialog(
      {super.key,
      required this.controller,
      required this.calculo,
      required this.cardapios,
      required this.itens,
      required this.regras,
      required this.consultaCompleta,
      this.assinaturaFonte});
  final CalculadoraFestaController controller;
  final CalculadoraFesta calculo;
  final List<Cardapio> cardapios;
  final Map<String, List<CardapioItem>> itens;
  final List<ItemEstimativaFinanceira> regras;
  final bool consultaCompleta;
  final String Function()? assinaturaFonte;
  @override
  State<CalculadoraCapacidadeDialog> createState() => _CapacidadeState();
}

class _CapacidadeState extends State<CalculadoraCapacidadeDialog> {
  late final TextEditingController verba;
  late String assinatura;
  CapacidadeAlimentos? resultado;
  String? erro;
  bool salvando = false;
  ConfirmacaoConfiguracaoCalculadora? tentativa;
  String get contextoAtual =>
      '${widget.controller.sessaoPlanejador}|${widget.controller.assinaturaProposta}|${widget.controller.orcamentoDisponivel.value}|${widget.assinaturaFonte?.call() ?? ''}';

  @override
  void initState() {
    super.initState();
    assinatura = contextoAtual;
    final valor = widget.controller.verbaAlimentacao.value;
    verba = TextEditingController(
        text: valor == null ? '' : NumericInput.dinheiro(valor));
  }

  @override
  void dispose() {
    verba.dispose();
    super.dispose();
  }

  String? get _verbaConfirmadaEm {
    final cfg = widget.controller.operacaoEvento['configuracao_planejamento'];
    if (cfg is! Map) return null;
    final conf = cfg['verba_confirmacao'];
    if (conf is! Map) return null;
    if (conf['valor'] != widget.controller.verbaAlimentacao.value) return null;
    final bruto = conf['confirmado_em']?.toString();
    if (bruto == null || bruto.isEmpty) return null;
    final data = DateTime.tryParse(bruto);
    if (data == null) return bruto;
    return DateFormat("dd/MM/yyyy 'às' HH:mm").format(data.toLocal());
  }

  void simular() {
    final c = widget.controller;
    try {
      if (assinatura != contextoAtual) {
        throw StateError('O planejamento mudou. Reabra a simulação.');
      }
      final valor = NumericInput.parse(verba.text);
      if (valor == null || !valor.isFinite || valor <= 0) {
        throw ArgumentError('Informe a verba para estes alimentos.');
      }
      if (c.orcamentoDisponivel.value != null &&
          valor > c.orcamentoDisponivel.value!) {
        throw ArgumentError(
            'A verba dos alimentos supera o limite total do evento.');
      }
      final operacao = Map<String, dynamic>.from(c.operacaoEvento);
      final ids = widget.cardapios
          .where((m) => m.ativo && m.idEvento == widget.calculo.idEvento)
          .map((m) => m.idCardapio)
          .toSet();
      final especifico = widget.calculo.totalCriancas > 0 ||
          widget.calculo.totalBebes > 0 ||
          ids.any((id) {
            final cfg =
                const OperacaoCalculadoraService().refeicao(operacao, id);
            return cfg['publico'] != null ||
                OperacaoCalculadoraService.lista(cfg['grupos']).isNotEmpty ||
                OperacaoCalculadoraService.mapa(cfg['destinos_itens'])
                    .values
                    .any((d) =>
                        OperacaoCalculadoraService.mapa(d)['modo'] != 'todos');
          }) ||
          widget.cardapios.any((m) =>
              ids.contains(m.idCardapio) &&
              m.escopo == EscopoCardapio.compartilhado);
      final nova = const CapacidadeAlimentosService().simular(
          verba: valor,
          publicoEspecifico: especifico,
          consultaCompleta: widget.consultaCompleta,
          gerar: (n) => const PlanoEventoService().gerar(
              catalogo: widget.controller.catalogoParaPropostas,
              calculo: widget.calculo
                  .copyWith(totalAdultos: n, totalCriancas: 0, totalBebes: 0),
              cardapios: widget.cardapios,
              itensPorCardapio: widget.itens,
              regras: widget.regras,
              operacao: operacao,
              consultaCompleta: widget.consultaCompleta));
      FocusScope.of(context).unfocus();
      setState(() {
        resultado = nova;
        erro = null;
      });
    } catch (e) {
      setState(() {
        erro = e is StateError
            ? e.message.toString()
            : e is ArgumentError
                ? e.message.toString()
                : 'Não foi possível simular com os dados atuais.';
        resultado = null;
      });
    }
  }

  Future<void> aplicarVerba() async {
    if (salvando) return;
    setState(() {
      salvando = true;
      erro = null;
    });
    try {
      if (assinatura != contextoAtual) {
        throw StateError('Simule novamente antes de usar esta verba.');
      }
      final valor = NumericInput.parse(verba.text);
      if (valor == null || !valor.isFinite || valor < 0) {
        throw ArgumentError('Informe uma verba válida.');
      }
      final c = widget.controller;
      if (c.verbaAlimentacao.value != valor) {
        c.medicaoUso.registrarCampo('verba_alimentacao');
      }
      tentativa ??=
          c.prepararConfirmacaoConfiguracao({'verba_alimentacao': valor});
      await c.confirmarConfiguracao(tentativa!);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.pop(context);
      messenger?.showSnackBar(SnackBar(
          content: Text(
        'Verba de ${NumericInput.dinheiro(valor)} aplicada ao planejamento.',
      )));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erro = e is StateError
            ? e.message.toString()
            : e is ArgumentError
                ? e.message.toString()
                : 'Não foi possível aplicar a verba. Tente novamente.';
      });
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() {
        final mudou = contextoAtual != assinatura;
        final scheme = Theme.of(context).colorScheme;
        final confirmadaEm = _verbaConfirmadaEm;

        return PopScope(
          canPop: !salvando,
          child: CalculadoraModal(
            titulo: 'Simular verba dos alimentos',
            icone: Icons.account_balance_wallet_outlined,
            ocupado: salvando,
            onFechar: salvando ? null : () => Navigator.pop(context),
            rodape: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                calculadoraModalRodape(
                  context: context,
                  confirmar: 'Usar esta verba',
                  iconeConfirmar: Icons.check_rounded,
                  ocupado: salvando,
                  onConfirmar: salvando || mudou ? null : aplicarVerba,
                  onCancelar: null,
                  cancelar: 'Cancelar',
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: salvando || mudou ? null : simular,
                  child: const Text('Simular capacidade'),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CalculadoraModalBanner(
                  texto:
                      'Quanto separar para comprar integralmente os alimentos deste cenário? O limite total do evento também precisa atender aos demais serviços.',
                ),
                const SizedBox(height: 16),
                CalculadoraModalSecao(
                  titulo: 'Verba alimentar',
                  descricao:
                      'Informe o valor e use no planejamento. A simulação de capacidade é opcional.',
                  filhos: [
                    if (confirmadaEm != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.verified_outlined,
                                size: 18, color: scheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Confirmada em $confirmadaEm',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (widget.controller.alertaVerbaAlimentacao != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          widget.controller.alertaVerbaAlimentacao!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF80591A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    TextField(
                      controller: verba,
                      enabled: !salvando,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [NumericInput.moeda()],
                      decoration: calculadoraModalCampo(
                        context,
                        'Verba para estes alimentos',
                        Icons.payments_outlined,
                        hint: 'R\$ 0,00',
                      ),
                      onChanged: (_) => setState(() {
                        resultado = null;
                        tentativa = null;
                        erro = null;
                      }),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Cenário teórico de adultos, com a reserva escolhida. Não desconta estoque ou serviços e não inclui frete, preparo ou outros custos sem registro.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (erro != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(erro!,
                        style: TextStyle(color: scheme.error, fontSize: 13)),
                  ),
                if (mudou)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'O planejamento mudou. Reabra a simulação para atualizar os dados.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF80591A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (resultado != null && !mudou)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(
                      resultado!.pessoas == null
                          ? 'Não foi possível estimar a capacidade\n${resultado!.motivo}\n\n'
                              'Para simular um único público de adultos, revise Público e estoque no cardápio. '
                              'Você pode usar esta verba no planejamento sem estimar a capacidade.'
                          : '${resultado!.limiteBusca ? 'Pelo menos ' : ''}${resultado!.pessoas} adultos neste cenário de compra\n'
                              'Alimentos: ${NumericInput.dinheiro(resultado!.custo!)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      });
}
