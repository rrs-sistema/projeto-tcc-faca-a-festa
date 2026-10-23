import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/entities/confirmacao_configuracao_calculadora.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/services/publico_planejamento_service.dart';
import '../controllers/calculadora_festa_controller.dart';
import 'calculadora_modal.dart';

class CalculadoraConfiguracaoDialog extends StatefulWidget {
  const CalculadoraConfiguracaoDialog(
      {super.key, required this.controller, this.perfilInicial});
  final CalculadoraFestaController controller;
  final TipoPerfilFesta? perfilInicial;
  @override
  State<CalculadoraConfiguracaoDialog> createState() => _ConfiguracaoState();
}

class _ConfiguracaoState extends State<CalculadoraConfiguracaoDialog> {
  late final TextEditingController duracao,
      adultos,
      criancas,
      bebes,
      margem,
      verba;
  late BaseCalculoFesta base;
  late String perfil;
  late int revisao;
  late String evento, usuario;
  bool salvando = false;
  String? erro;
  ConfirmacaoConfiguracaoCalculadora? tentativa;
  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    evento = c.idEventoAtual.value;
    usuario = c.contextoEvento.usuario;
    revisao = (c.operacaoEvento['revisao'] as num? ?? 0).toInt();
    base = c.baseCalculo.value;
    perfil = (widget.perfilInicial ?? c.perfilSelecionado.value.tipo).name;
    duracao = TextEditingController(text: '${c.duracaoHoras.value}');
    adultos = TextEditingController(
        text: c.publicoPlanejado.semDistribuicao
            ? ''
            : '${c.totalAdultos.value}');
    criancas = TextEditingController(
        text: c.publicoPlanejado.semDistribuicao
            ? ''
            : '${c.totalCriancas.value}');
    bebes = TextEditingController(
        text:
            c.publicoPlanejado.semDistribuicao ? '' : '${c.totalBebes.value}');
    margem = TextEditingController(
        text: c.margemPersonalizada.value == null
            ? ''
            : NumericInput.dinheiro(c.margemPersonalizada.value! * 100));
    verba = TextEditingController(
        text: c.verbaAlimentacao.value == null
            ? ''
            : NumericInput.dinheiro(c.verbaAlimentacao.value!));
  }

  @override
  void dispose() {
    for (final c in [duracao, adultos, criancas, bebes, margem, verba]) {
      c.dispose();
    }
    super.dispose();
  }

  void mudou() {
    tentativa = null;
  }

  Future<void> confirmar() async {
    if (salvando) return;
    setState(() {
      salvando = true;
      erro = null;
    });
    try {
      final c = widget.controller;
      if (usuario != c.contextoEvento.usuario ||
          evento != c.idEventoAtual.value ||
          c.usandoContextoHistorico.value) {
        throw StateError('O evento mudou. Reabra o editor.');
      }
      final patch = <String, dynamic>{
        'base': valorBasePublico(base),
        'base_confirmada': true,
        'duracao': int.tryParse(duracao.text),
        'perfil': perfil,
        'margem': margem.text.trim().isEmpty
            ? null
            : (NumericInput.parse(margem.text) ?? double.nan) / 100,
        'verba_alimentacao': verba.text.trim().isEmpty
            ? null
            : NumericInput.parse(verba.text) ?? double.nan,
        if (base == BaseCalculoFesta.manual)
          'publico': {
            'adultos': int.tryParse(adultos.text),
            'criancas': int.tryParse(criancas.text),
            'bebes': int.tryParse(bebes.text)
          }
      };
      tentativa ??= ConfirmacaoConfiguracaoCalculadora(
          id: c.prepararConfirmacaoConfiguracao(patch).id,
          revisaoEsperada: revisao,
          idEvento: evento,
          idUsuario: usuario.isEmpty ? null : usuario,
          alteracoes: patch);
      await c.confirmarConfiguracao(tentativa!);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => erro = e is StateError
            ? e.message.toString()
            : e is ArgumentError
                ? e.message.toString()
                : 'Não foi possível confirmar. Seus valores foram mantidos.');
      }
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  String get resumoGuardado {
    final cfg = widget.controller.operacaoEvento['configuracao_planejamento'];
    if (cfg is! Map) return 'O evento ainda não possui escolhas guardadas.';
    return 'No evento: ${cfg['duracao'] ?? 4} horas, perfil ${cfg['perfil'] ?? 'padrao'}, verba ${cfg['verba_alimentacao'] == null ? 'não definida' : NumericInput.dinheiro((cfg['verba_alimentacao'] as num).toDouble())}.';
  }

  InputDecoration _decoracao(String label, IconData icone,
      {String? hint, String? helper, String? prefixo, String? sufixo}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 2,
      prefixText: prefixo,
      suffixText: sufixo,
      prefixIcon: Icon(icone, size: 20, color: scheme.primary),
      filled: true,
      fillColor: const Color(0xFFF8FAF9),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2)),
    );
  }

  Widget _campo(TextEditingController controller, InputDecoration decoracao,
          {List<TextInputFormatter>? formatadores,
          bool decimal = false,
          String? chave}) =>
      Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextField(
              key: chave == null ? null : ValueKey(chave),
              controller: controller,
              enabled: !salvando,
              onChanged: (_) => mudou(),
              keyboardType: TextInputType.numberWithOptions(decimal: decimal),
              inputFormatters: formatadores,
              // Espaço para o rodapé fixo do modal ao rolar o campo focado.
              scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
              decoration: decoracao));

  Widget _secao(String titulo, String descricao, List<Widget> campos) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(titulo,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface)),
            const SizedBox(height: 4),
            Text(descricao,
                style: TextStyle(
                    fontSize: 12, height: 1.4, color: scheme.onSurfaceVariant)),
            ...campos,
          ]),
    );
  }

  Widget _aviso(IconData icone, Color cor, List<Widget> conteudo) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: cor.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icone, size: 18, color: cor),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: conteudo)),
      ]));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const perfis = {
      'economico': 'Econômico',
      'padrao': 'Padrão',
      'premium': 'Premium'
    };
    return PopScope(
        canPop: !salvando,
        child: CalculadoraModal(
            titulo: 'Escolhas do planejamento',
            icone: Icons.tune_rounded,
            ocupado: salvando,
            onFechar: () => Navigator.pop(context),
            rodape: _rodape(scheme),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      widget.controller.possuiEventoVinculado
                          ? 'Confirme para guardar no evento. Cancelar mantém as escolhas anteriores.'
                          : 'Confirme para aplicar à estimativa.',
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  _secao(
                      'Público e duração',
                      'De onde vem o número de pessoas e quanto tempo dura a festa.',
                      [
                        const SizedBox(height: 12),
                        DropdownButtonFormField<BaseCalculoFesta>(
                            isExpanded: true,
                            value: base,
                            decoration: _decoracao(
                                'Fonte do público', Icons.groups_outlined),
                            items: BaseCalculoFesta.values
                                .map((b) => DropdownMenuItem(
                                    value: b, child: Text(b.label)))
                                .toList(),
                            onChanged: salvando
                                ? null
                                : (v) => setState(() {
                                      base = v!;
                                      mudou();
                                    })),
                        if (base == BaseCalculoFesta.manual) ...[
                          _campo(adultos,
                              _decoracao('Adultos', Icons.person_outline),
                              formatadores: NumericInput.inteiro),
                          _campo(criancas,
                              _decoracao('Crianças', Icons.child_care_outlined),
                              formatadores: NumericInput.inteiro),
                          _campo(
                              bebes,
                              _decoracao('Bebês',
                                  Icons.baby_changing_station_outlined),
                              formatadores: NumericInput.inteiro),
                        ],
                        _campo(
                            duracao,
                            _decoracao('Duração de referência',
                                Icons.schedule_outlined,
                                sufixo: 'horas', helper: 'De 1 a 24 horas'),
                            formatadores: NumericInput.inteiro,
                            chave: 'cfg_duracao'),
                      ]),
                  _secao('Perfil e margem',
                      'Define o nível das porções e a folga de segurança.', [
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: perfil,
                        decoration: _decoracao(
                            'Perfil', Icons.workspace_premium_outlined),
                        items: perfis.entries
                            .map((e) => DropdownMenuItem(
                                value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: salvando
                            ? null
                            : (v) => setState(() {
                                  perfil = v!;
                                  mudou();
                                })),
                    _campo(
                        margem,
                        _decoracao('Margem extra', Icons.trending_up_rounded,
                            sufixo: '%',
                            helper: 'Deixe vazio para usar o padrão do perfil'),
                        decimal: true,
                        chave: 'cfg_margem'),
                  ]),
                  _secao(
                      'Alimentação',
                      'Valor que você pretende reservar para comida e bebida.',
                      [
                        _campo(
                            verba,
                            _decoracao(
                                'Verba alimentar', Icons.payments_outlined,
                                hint: 'Ex.: 1.500,00', helper: 'Opcional'),
                            formatadores: [NumericInput.moeda()],
                            decimal: true,
                            chave: 'cfg_verba'),
                        const SizedBox(height: 12),
                        _aviso(Icons.info_outline_rounded, scheme.primary, [
                          Text(
                              'A verba não altera o limite total do evento. As refeições com público próprio permanecem iguais.',
                              style: TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: scheme.onSurface)),
                        ]),
                      ]),
                  if (erro != null)
                    Semantics(
                        liveRegion: true,
                        child:
                            _aviso(Icons.error_outline_rounded, scheme.error, [
                          Text(erro!,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.error)),
                          const SizedBox(height: 6),
                          Text(resumoGuardado,
                              style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: scheme.onSurfaceVariant)),
                          TextButton.icon(
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(48, 40)),
                              onPressed: salvando
                                  ? null
                                  : () => setState(() {
                                        revisao =
                                            (widget.controller.operacaoEvento[
                                                        'revisao'] as num? ??
                                                    0)
                                                .toInt();
                                        tentativa = null;
                                        erro =
                                            'Revisão atual consultada. Confira seus valores e confirme novamente.';
                                      }),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Revisar com a versão atual')),
                        ])),
                ])));
  }

  Widget _rodape(ColorScheme scheme) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    iconColor: scheme.onPrimary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: salvando ? null : confirmar,
                icon: salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_rounded),
                label: Text(salvando ? 'Guardando…' : 'Confirmar escolhas',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            TextButton(
                style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                onPressed: salvando ? null : () => Navigator.pop(context),
                child: const Text('Cancelar')),
          ]));
}
