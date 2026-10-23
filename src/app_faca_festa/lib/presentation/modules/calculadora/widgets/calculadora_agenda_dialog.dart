import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/ocorrencia_servico.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import '../controllers/calculadora_festa_controller.dart';
import 'calculadora_modal.dart';

/// Lista serviços da festa e atalhos para planejar cada refeição.
class CalculadoraAgendaDialog extends StatelessWidget {
  const CalculadoraAgendaDialog(
      {super.key,
      required this.controller,
      required this.cardapios,
      this.evento});
  final CalculadoraFestaController controller;
  final CardapioController cardapios;
  final Evento? evento;

  void _abrirEditor(BuildContext context,
      {OcorrenciaServico? existente, String? modelo}) {
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CalculadoraOcorrenciaEditor(
            controller: controller,
            cardapios: cardapios,
            evento: evento,
            existente: existente,
            modeloInicial: modelo));
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Obx(() {
      final bloqueado = controller.usandoContextoHistorico.value ||
          controller.escritaContextoPendente.value;
      final agenda = controller.agendaServicos.toList();
      final legados = cardapios.cardapios
          .where((m) =>
              m.idEvento == controller.idEventoAtual.value &&
              m.ativo &&
              m.idModelo == null)
          .toList();
      return CalculadoraModal(
          titulo: 'Agenda de alimentação',
          icone: Icons.event_note_rounded,
          onFechar: () => Navigator.pop(context),
          rodape: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
              child: FilledButton(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Concluir'))),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoBanner(
                    icone: Icons.info_outline_rounded,
                    texto:
                        'Cada refeição é um serviço. Dias do evento não multiplicam porções. Data e horário são opcionais.'),
                const SizedBox(height: 16),
                Text('Serviços na agenda',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cores.onSurface)),
                const SizedBox(height: 8),
                if (agenda.isEmpty)
                  _EmptyCard(
                      icone: Icons.calendar_month_outlined,
                      titulo: 'Nenhuma ocorrência ainda',
                      texto:
                          'Planeje a partir de um cardápio abaixo. Os antigos permanecem sem data presumida.'),
                for (final o in agenda)
                  _ServicoCard(
                      titulo: o.titulo,
                      detalhe: o.resumo,
                      badge: _labelFormato(o.formato),
                      primario: cores.primary,
                      acaoLabel: 'Editar',
                      acaoIcone: Icons.edit_outlined,
                      onAcao: bloqueado
                          ? null
                          : () => _abrirEditor(context, existente: o)),
                if (legados.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Cardápios sem agenda',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cores.onSurface)),
                  const SizedBox(height: 4),
                  Text('Dados preservados. Planeje para definir data e formato.',
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: cores.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  for (final m in legados)
                    _ServicoCard(
                        titulo: m.titulo,
                        detalhe: m.somenteModelo
                            ? 'Modelo reutilizável — fora da soma de serviços'
                            : 'Serviço antigo sem agenda',
                        badge: 'Sem data',
                        primario: cores.primary,
                        acaoLabel: 'Planejar',
                        acaoIcone: Icons.route_outlined,
                        onAcao: bloqueado ||
                                !cardapios.itensPorCardapio
                                    .containsKey(m.idCardapio)
                            ? null
                            : () =>
                                _abrirEditor(context, modelo: m.idCardapio)),
                ],
                if (cardapios.carregando.value) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (cardapios.erro.value.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(cardapios.erro.value,
                      style: TextStyle(color: cores.error)),
                ],
              ]));
    });
  }

  String _labelFormato(String formato) => switch (formato) {
        'buffet' => 'Buffet',
        'empratado' => 'Empratado',
        'volante' => 'Volante',
        'autosservico' => 'Autosserviço',
        _ => 'Formato aberto',
      };
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icone, required this.texto});
  final IconData icone;
  final String texto;
  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 10),
          Expanded(
              child: Text(texto,
                  style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurface))),
        ]));
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(
      {required this.icone, required this.titulo, required this.texto});
  final IconData icone;
  final String titulo, texto;
  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(children: [
          Icon(icone, color: cores.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(texto,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: cores.onSurfaceVariant)),
              ])),
        ]));
  }
}

class _ServicoCard extends StatelessWidget {
  const _ServicoCard(
      {required this.titulo,
      required this.detalhe,
      required this.badge,
      required this.primario,
      required this.acaoLabel,
      required this.acaoIcone,
      required this.onAcao});
  final String titulo, detalhe, badge, acaoLabel;
  final IconData acaoIcone;
  final Color primario;
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE2E8F0))),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                onTap: onAcao,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: primario.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.restaurant_rounded,
                                  color: primario, size: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(titulo,
                                    style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A))),
                                const SizedBox(height: 2),
                                Text(detalhe,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.35,
                                        color: Color(0xFF64748B))),
                                const SizedBox(height: 6),
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius:
                                            BorderRadius.circular(999)),
                                    child: Text(badge,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF475569)))),
                              ])),
                          const SizedBox(width: 4),
                          TextButton.icon(
                              onPressed: onAcao,
                              icon: Icon(acaoIcone, size: 18),
                              label: Text(acaoLabel)),
                        ])))));
  }
}

class CalculadoraOcorrenciaEditor extends StatefulWidget {
  const CalculadoraOcorrenciaEditor(
      {super.key,
      required this.controller,
      required this.cardapios,
      this.evento,
      this.existente,
      this.modeloInicial});
  final CalculadoraFestaController controller;
  final CardapioController cardapios;
  final Evento? evento;
  final OcorrenciaServico? existente;
  final String? modeloInicial;
  @override
  State<CalculadoraOcorrenciaEditor> createState() => _OcorrenciaState();
}

class _OcorrenciaState extends State<CalculadoraOcorrenciaEditor> {
  final titulo = TextEditingController(),
      data = TextEditingController(),
      hora = TextEditingController(),
      fuso = TextEditingController(),
      duracao = TextEditingController();
  final publico = [for (var i = 0; i < 3; i++) TextEditingController()];
  final extra = [for (var i = 0; i < 3; i++) TextEditingController(text: '0')];
  late String id, modelo, pedido, evento, usuario;
  late int revisao;
  bool herdar = true, somenteModelo = true, salvando = false;
  String formato = 'nao_definido', servico = 'nao_definido';
  String? erro;
  OcorrenciaServico? proposta;
  Map<String, dynamic>? configuracao;
  CalculadoraFestaController get c => widget.controller;

  static final _fmtData = DateFormat('yyyy-MM-dd');
  static final _fmtExibir = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final o = widget.existente;
    id = o?.id ?? 'oc_${const Uuid().v4()}';
    pedido = const Uuid().v4();
    evento = c.idEventoAtual.value;
    usuario = c.contextoEvento.usuario;
    revisao = (c.operacaoEvento['revisao'] as num? ?? 0).toInt();
    modelo = o?.modelo ?? widget.modeloInicial ?? '';
    titulo.text =
        o?.titulo ?? widget.cardapios.cardapioPorId(modelo)?.titulo ?? '';
    data.text = o?.dataLocal ?? '';
    hora.text = o?.horaLocal ?? '';
    fuso.text = o?.fuso ?? '';
    duracao.text = o?.duracaoMinutos?.toString() ?? '';
    formato = o?.formato ?? 'nao_definido';
    final cfg = o == null
        ? <String, dynamic>{}
        : const OperacaoCalculadoraService()
            .refeicao(Map.of(c.operacaoEvento), id);
    herdar = cfg['publico'] == null;
    servico = cfg['servico']?.toString() ?? 'nao_definido';
    for (var i = 0; i < 3; i++) {
      final k = ['adultos', 'criancas', 'bebes'][i];
      publico[i].text =
          OperacaoCalculadoraService.mapa(cfg['publico'])[k]?.toString() ?? '';
      extra[i].text =
          (OperacaoCalculadoraService.mapa(cfg['publico_extra'])[k] ?? 0)
              .toString();
    }
  }

  @override
  void dispose() {
    for (final t in [titulo, data, hora, fuso, duracao, ...publico, ...extra]) {
      t.dispose();
    }
    super.dispose();
  }

  String? opcional(TextEditingController t) =>
      t.text.trim().isEmpty ? null : t.text.trim();
  void editar() {
    setState(() => proposta = null);
    pedido = const Uuid().v4();
  }

  Map<String, dynamic> contagem(List<TextEditingController> valores) => {
        for (var i = 0; i < 3; i++)
          ['adultos', 'criancas', 'bebes'][i]: int.tryParse(valores[i].text)
      };

  Future<void> _escolherData() async {
    if (salvando) return;
    final atual = data.text.trim().isEmpty
        ? (widget.evento?.data ?? DateTime.now())
        : (DateTime.tryParse(data.text) ?? DateTime.now());
    final inicio = widget.evento?.data ?? DateTime(atual.year - 1);
    final fim = widget.evento?.dataFim ??
        (widget.evento != null
            ? widget.evento!.data.add(const Duration(days: 30))
            : DateTime(atual.year + 2));
    final escolhida = await showDatePicker(
        context: context,
        initialDate: atual.isBefore(inicio)
            ? inicio
            : (atual.isAfter(fim) ? fim : atual),
        firstDate: inicio,
        lastDate: fim,
        helpText: 'Data deste serviço',
        cancelText: 'Cancelar',
        confirmText: 'Usar data');
    if (!mounted) return;
    if (escolhida == null) {
      // Toque fora / cancelar: não limpa. Limpar via botão dedicado.
      return;
    }
    setState(() {
      data.text = _fmtData.format(escolhida);
      editar();
    });
  }

  Future<void> _escolherHora() async {
    if (salvando) return;
    TimeOfDay inicial = TimeOfDay.now();
    if (hora.text.contains(':')) {
      final p = hora.text.split(':');
      final h = int.tryParse(p[0]), m = int.tryParse(p.length > 1 ? p[1] : '');
      if (h != null && m != null) inicial = TimeOfDay(hour: h, minute: m);
    }
    final escolhida = await showTimePicker(
        context: context,
        initialTime: inicial,
        helpText: 'Início do serviço',
        cancelText: 'Cancelar',
        confirmText: 'Usar horário');
    if (!mounted || escolhida == null) return;
    setState(() {
      hora.text =
          '${escolhida.hour.toString().padLeft(2, '0')}:${escolhida.minute.toString().padLeft(2, '0')}';
      editar();
    });
  }

  void revisar() {
    try {
      if (evento != c.idEventoAtual.value ||
          usuario != c.contextoEvento.usuario ||
          c.usandoContextoHistorico.value) {
        throw StateError('O contexto mudou. Reabra a agenda.');
      }
      final o = OcorrenciaServico(
          id: id,
          evento: evento,
          modelo: modelo,
          cardapio: id,
          titulo: titulo.text.trim(),
          dataLocal: opcional(data),
          horaLocal: opcional(hora),
          fuso: opcional(fuso),
          duracaoMinutos: opcional(duracao) == null
              ? null
              : int.tryParse(duracao.text) ?? -1,
          formato: formato);
      o.validar(
          inicioEvento: widget.evento?.data, fimEvento: widget.evento?.dataFim);
      final cfg = {
        'publico': herdar ? null : contagem(publico),
        'publico_extra': contagem(extra),
        'servico': servico == 'nao_definido' ? null : servico
      };
      const OperacaoCalculadoraService().validarRefeicao(cfg);
      setState(() {
        proposta = o;
        configuracao = cfg;
        erro = null;
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      setState(() => erro = _mensagem(e));
    }
  }

  String _mensagem(Object e) => e is StateError
      ? e.message.toString()
      : e is ArgumentError
          ? e.message.toString()
          : 'Não foi possível guardar. Seus valores foram mantidos.';

  Future<void> confirmar() async {
    if (salvando || proposta == null) return;
    setState(() {
      salvando = true;
      erro = null;
    });
    try {
      if (evento != c.idEventoAtual.value ||
          usuario != c.contextoEvento.usuario) {
        throw StateError('A sessão mudou. Reabra a agenda.');
      }
      await c.confirmarOcorrencia(proposta!,
          revisao: revisao,
          pedido: pedido,
          config: configuracao!,
          itensModelo: widget.cardapios.itensDoCardapio(modelo),
          somenteModelo: somenteModelo);
      if (!mounted) return;
      if (evento != c.idEventoAtual.value ||
          usuario != c.contextoEvento.usuario) {
        throw StateError(
            'A sessão mudou. A confirmação não pertence à tela atual.');
      }
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => erro = _mensagem(e));
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  InputDecoration _decoracao(String label, {String? helper, IconData? icone}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 2,
      prefixIcon: icone == null ? null : Icon(icone, size: 20),
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

  Widget _campoTexto(String label, TextEditingController ctrl,
          {String? helper,
          IconData? icone,
          TextInputType? teclado,
          List<TextInputFormatter>? formatadores}) =>
      Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextField(
              controller: ctrl,
              enabled: !salvando,
              onChanged: (_) => editar(),
              keyboardType: teclado,
              inputFormatters: formatadores,
              scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
              decoration:
                  _decoracao(label, helper: helper, icone: icone)));

  Widget _campoToque({
    required String label,
    required String valor,
    required String vazio,
    required IconData icone,
    required VoidCallback? onTap,
    VoidCallback? onLimpar,
  }) {
    final preenchido = valor.trim().isNotEmpty;
    return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
                decoration: _decoracao(label, icone: icone).copyWith(
                    suffixIcon: preenchido && onLimpar != null
                        ? IconButton(
                            tooltip: 'Limpar',
                            onPressed: salvando ? null : onLimpar,
                            icon: const Icon(Icons.close_rounded, size: 18))
                        : const Icon(Icons.expand_more_rounded)),
                child: Text(preenchido ? valor : vazio,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            preenchido ? FontWeight.w600 : FontWeight.w400,
                        color: preenchido
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF94A3B8))))));
  }

  Widget _secao(String titulo, String? descricao, List<Widget> filhos) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A))),
                if (descricao != null) ...[
                  const SizedBox(height: 4),
                  Text(descricao,
                      style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Color(0xFF64748B))),
                ],
                ...filhos,
              ]));

  Widget _pessoas(String label, List<TextEditingController> controles) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 0),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569)))),
        Row(children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
                child: _campoTexto(['Adultos', 'Crianças', 'Bebês'][i],
                    controles[i],
                    teclado: TextInputType.number,
                    formatadores: [FilteringTextInputFormatter.digitsOnly])),
          ],
        ]),
      ]);

  String get _dataExibida {
    final raw = data.text.trim();
    if (raw.isEmpty) return '';
    final d = DateTime.tryParse(raw);
    return d == null ? raw : _fmtExibir.format(d);
  }

  @override
  Widget build(BuildContext context) {
    final modeloTitulo =
        widget.cardapios.cardapioPorId(modelo)?.titulo ?? modelo;
    final cores = Theme.of(context).colorScheme;
    return PopScope(
        canPop: !salvando,
        child: CalculadoraModal(
            titulo: widget.existente == null
                ? 'Planejar serviço'
                : 'Editar serviço',
            subtitulo: 'Modelo: $modeloTitulo',
            icone: Icons.schedule_rounded,
            ocupado: salvando,
            onFechar: salvando ? null : () => Navigator.pop(context),
            rodape: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                          style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          onPressed: salvando
                              ? null
                              : proposta == null
                                  ? revisar
                                  : confirmar,
                          child: Text(salvando
                              ? 'Guardando…'
                              : proposta == null
                                  ? 'Revisar ocorrência'
                                  : 'Confirmar ocorrência')),
                      TextButton(
                          onPressed:
                              salvando ? null : () => Navigator.pop(context),
                          child: const Text('Cancelar')),
                    ])),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _secao('Identificação', null, [
                    _campoTexto('Nome deste serviço', titulo,
                        icone: Icons.badge_outlined),
                  ]),
                  _secao(
                      'Quando acontece',
                      'Opcional. Use o calendário — sem digitar formato.',
                      [
                        _campoToque(
                            label: 'Data',
                            valor: _dataExibida,
                            vazio: 'Escolher no calendário',
                            icone: Icons.calendar_today_outlined,
                            onTap: salvando ? null : _escolherData,
                            onLimpar: () => setState(() {
                                  data.clear();
                                  editar();
                                })),
                        _campoToque(
                            label: 'Horário de início',
                            valor: hora.text,
                            vazio: 'Escolher horário',
                            icone: Icons.access_time_rounded,
                            onTap: salvando ? null : _escolherHora,
                            onLimpar: () => setState(() {
                                  hora.clear();
                                  editar();
                                })),
                        _campoTexto('Duração (minutos)', duracao,
                            helper: 'Opcional · de 1 a 1.440',
                            icone: Icons.timelapse_rounded,
                            teclado: TextInputType.number,
                            formatadores: [
                              FilteringTextInputFormatter.digitsOnly
                            ]),
                      ]),
                  _secao('Como será servido', null, [
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                        value: formato,
                        isExpanded: true,
                        decoration: _decoracao('Formato de atendimento',
                            icone: Icons.dinner_dining_outlined),
                        items: const {
                          'nao_definido': 'Ainda não definido',
                          'buffet': 'Buffet',
                          'empratado': 'Empratado',
                          'volante': 'Volante',
                          'autosservico': 'Autosserviço'
                        }
                            .entries
                            .map((e) => DropdownMenuItem(
                                value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: salvando
                            ? null
                            : (v) {
                                formato = v!;
                                editar();
                              }),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                        value: servico,
                        isExpanded: true,
                        decoration: _decoracao('Tipo de serviço',
                            icone: Icons.restaurant_menu_outlined),
                        items: const {
                          'nao_definido': 'Ainda não definido',
                          'refeicao': 'Refeição',
                          'lanche': 'Intervalo / lanche'
                        }
                            .entries
                            .map((e) => DropdownMenuItem(
                                value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: salvando
                            ? null
                            : (v) {
                                servico = v!;
                                editar();
                              }),
                  ]),
                  _secao('Público desta ocorrência', null, [
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: herdar,
                        onChanged: salvando
                            ? null
                            : (v) {
                                herdar = v;
                                editar();
                              },
                        title: const Text('Usar o público do planejamento',
                            style: TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                            'Desligue só se esta refeição tiver outro número de pessoas.')),
                    if (!herdar)
                      _pessoas('Público próprio', publico),
                    _pessoas('Equipe / público extra', extra),
                  ]),
                  if (widget.existente == null)
                    CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: somenteModelo,
                        onChanged: salvando
                            ? null
                            : (v) {
                                somenteModelo = v!;
                                editar();
                              },
                        title: const Text('Usar o original só como modelo',
                            style: TextStyle(fontSize: 13.5)),
                        subtitle: const Text(
                            'Mantém o cardápio antigo sem agenda. Compras e reservas existentes exigem preservá-lo.',
                            style: TextStyle(fontSize: 12))),
                  Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('Opções avançadas',
                              style: TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w600)),
                          children: [
                            _campoTexto('Fuso IANA', fuso,
                                helper: 'Ex.: America/Sao_Paulo · opcional',
                                icone: Icons.public_outlined),
                            const SizedBox(height: 8),
                            Text(
                                'Grupos e necessidades são conferidos na alimentação desta ocorrência. O nome do prato não comprova adequação.',
                                style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: cores.onSurfaceVariant)),
                          ])),
                  if (proposta != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _InfoBanner(
                            icone: Icons.check_circle_outline,
                            texto:
                                '${proposta!.resumo}\n${widget.cardapios.itensDoCardapio(modelo).length} itens serão copiados sem quantidades finais. Confirme para guardar.')),
                  if (erro != null) ...[
                    const SizedBox(height: 12),
                    Text(erro!,
                        style: TextStyle(
                            color: cores.error,
                            fontWeight: FontWeight.w600)),
                    TextButton(
                        onPressed: salvando
                            ? null
                            : () {
                                revisao =
                                    (c.operacaoEvento['revisao'] as num? ?? 0)
                                        .toInt();
                                pedido = const Uuid().v4();
                                revisar();
                              },
                        child: const Text('Revisar com os dados atuais')),
                  ],
                ])));
  }
}
