import '../widgets/calculadora_modal.dart';
import '../widgets/calculadora_ficha_tecnica_dialog.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/services/referencia_porcao_service.dart';
import 'calculadora_rendimento_dialog.dart';
import 'package:app_faca_festa/domain/entities/referencia_contextual.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/services/proposta_refeicao_service.dart';

class CalculadoraRegraManualDialog extends StatefulWidget {
  final ItemEstimativaFinanceira? inicial;
  final String? nome;
  final String? id;
  final UnidadeEstimativa? unidade;
  final String publico;
  final String tipo;
  final Future<void> Function(ItemEstimativaFinanceira)? onSalvar;
  final String confirmarLabel;
  final CatalogoContextual? catalogo;
  final Map<String, dynamic> contextoReferencia;

  const CalculadoraRegraManualDialog(
      {super.key,
      this.inicial,
      this.nome,
      this.id,
      this.unidade,
      this.onSalvar,
      this.confirmarLabel = 'Usar no cálculo',
      this.catalogo,
      this.contextoReferencia = const {},
      this.publico = 'todos',
      this.tipo = 'outro'});

  @override
  State<CalculadoraRegraManualDialog> createState() => _RegraState();
}

class _RegraState extends State<CalculadoraRegraManualDialog>
    with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  final _referenciasTemporarias = <TextEditingController>[];
  final _nomeFocus = FocusNode();
  final _consumoFocus = FocusNode();
  final _precoFocus = FocusNode();
  final _nomeKey = GlobalKey();
  final _consumoKey = GlobalKey();
  final _precoKey = GlobalKey();
  Timer? _rolagemTimer;

  void _selecionarPrecoZerado() {
    if (!_precoFocus.hasFocus) return;
    final valor = _numero(_preco.text);
    if (_preco.text.isNotEmpty && valor != 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_precoFocus.hasFocus) return;
      _preco.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _preco.text.length,
      );
    });
  }

  void _revelarCampo() {
    _rolagemTimer?.cancel();
    // Aguarda a acomodação do teclado e do inset animado do Dialog.
    _rolagemTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final key = _precoFocus.hasFocus
          ? _precoKey
          : _consumoFocus.hasFocus
              ? _consumoKey
              : _nomeFocus.hasFocus
                  ? _nomeKey
                  : null;
      final campo = key?.currentContext;
      if (campo != null) {
        Scrollable.ensureVisible(campo,
            alignment: 0.5, duration: const Duration(milliseconds: 180));
      }
    });
  }

  @override
  void didChangeMetrics() => _revelarCampo();
  late final TextEditingController _nome;
  late final TextEditingController _consumo;
  late final TextEditingController _preco;
  late UnidadeEstimativa _unidade;
  late String _publico;
  late String _tipo;
  late String _grupo;
  late bool _dividirGrupo;
  late bool _ajustarDuracao;
  late String _estado;
  late String _papel;
  late Map<String, dynamic> _premissasEditadas;
  late final TextEditingController _pesoCrianca, _pesoBebe;
  late final TextEditingController _receita;
  late final TextEditingController _servicos;
  String? _erroPremissas;
  String? _erroSalvamento;
  bool _salvando = false;
  late String _unidadeConsumo;
  late final TextEditingController _participacao;
  late final TextEditingController _rendimento;
  late final TextEditingController _embalagem;

  static const _publicos = {
    'todos': 'Todos',
    'adultos': 'Adultos',
    'criancas': 'Crianças',
    'bebes': 'Bebês'
  };
  static const _tipos = {
    'comida': 'Comida',
    'bebida': 'Bebida',
    'sobremesa': 'Sobremesa',
    'bolo': 'Bolo',
    'descartavel': 'Descartáveis',
    'outro': 'Outro'
  };
  static const _unidades = {
    UnidadeEstimativa.unidade: 'Unidade (un)',
    UnidadeEstimativa.cento: 'Cento (100 un)',
    UnidadeEstimativa.quilo: 'Quilo (kg)',
    UnidadeEstimativa.litro: 'Litro (L)',
    UnidadeEstimativa.garrafa: 'Garrafa',
    UnidadeEstimativa.pacote: 'Pacote'
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nomeFocus.addListener(_revelarCampo);
    _consumoFocus.addListener(_revelarCampo);
    _precoFocus.addListener(_revelarCampo);
    _precoFocus.addListener(_selecionarPrecoZerado);
    _nome = TextEditingController(text: widget.inicial?.nome ?? widget.nome);
    _consumo = TextEditingController(
        text: widget.inicial?.quantidadePorConvidadoEquivalente
                .toString()
                .replaceAll('.', ',') ??
            '');
    _preco = TextEditingController(
        text: widget.inicial == null
            ? ''
            : NumericInput.dinheiro(widget.inicial!.valorUnitarioMedio));
    _unidade =
        widget.inicial?.unidade ?? widget.unidade ?? UnidadeEstimativa.unidade;
    final publico = widget.inicial?.publicoAlvo ?? widget.publico;
    _publico = _publicos.containsKey(publico) ? publico : 'todos';
    final meta = widget.inicial?.premissas ?? {};
    _premissasEditadas = Map<String, dynamic>.from(meta);
    _receita = TextEditingController(text: meta['receita']?.toString() ?? '');
    _pesoCrianca = TextEditingController(
        text: (((meta['peso_crianca'] as num?)?.toDouble() ?? .6) * 100)
            .toString());
    _pesoBebe = TextEditingController(
        text:
            (((meta['peso_bebe'] as num?)?.toDouble() ?? .2) * 100).toString());
    final papel = meta['papel_na_refeicao']?.toString();
    _papel = ['principal', 'acompanhamento', 'bebida', 'outro'].contains(papel)
        ? papel!
        : 'a_confirmar';
    _dividirGrupo = meta['dividir_grupo'] == true;
    _ajustarDuracao = meta['ajustar_por_duracao'] == true;
    _servicos =
        TextEditingController(text: (meta['numero_servicos'] ?? 1).toString());
    final estado = meta['estado']?.toString() ?? '';
    _estado =
        ['cru', 'seco', 'pronto'].contains(estado) ? estado : 'não informado';
    _grupo = meta['grupo'] as String? ?? '';
    if (![
      '',
      'proteinas',
      'acompanhamentos',
      'bebidas_sem_alcool',
      'sobremesas'
    ].contains(_grupo)) {
      _grupo = '';
    }
    _unidadeConsumo = meta['unidade_consumo'] as String? ?? _unidade.label;
    _participacao =
        TextEditingController(text: (meta['participacao'] ?? 1).toString());
    _rendimento =
        TextEditingController(text: (meta['rendimento'] ?? 1).toString());
    _embalagem =
        TextEditingController(text: (meta['embalagem'] ?? 0).toString());
    final tipo = widget.inicial?.tipoItem ?? widget.tipo;
    _tipo = _tipos.containsKey(tipo) ? tipo : 'outro';
  }

  double? _numero(String texto) => NumericInput.parse(texto);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rolagemTimer?.cancel();
    for (final controller in _referenciasTemporarias) {
      controller.dispose();
    }
    _nome.dispose();
    _consumo.dispose();
    _preco.dispose();
    _participacao.dispose();
    _rendimento.dispose();
    _embalagem.dispose();
    _servicos.dispose();
    _pesoCrianca.dispose();
    _pesoBebe.dispose();
    _receita.dispose();
    _nomeFocus.dispose();
    _consumoFocus.dispose();
    _precoFocus.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!_form.currentState!.validate()) {
      final consumo = _numero(_consumo.text);
      if (_nome.text.trim().isEmpty) {
        _nomeFocus.requestFocus();
      } else if (consumo == null || !consumo.isFinite || consumo <= 0) {
        _consumoFocus.requestFocus();
      } else {
        _precoFocus.requestFocus();
      }
      return;
    }
    final peso = _numero(_participacao.text);
    final rendimento = _numero(_rendimento.text);
    final embalagem = _numero(_embalagem.text);
    final servicos = _numero(_servicos.text);
    final pesoCrianca = _numero(_pesoCrianca.text),
        pesoBebe = _numero(_pesoBebe.text);
    if (peso == null ||
        !peso.isFinite ||
        peso <= 0 ||
        rendimento == null ||
        !rendimento.isFinite ||
        rendimento <= 0 ||
        embalagem == null ||
        !embalagem.isFinite ||
        embalagem < 0 ||
        servicos == null ||
        !servicos.isFinite ||
        servicos <= 0 ||
        [pesoCrianca, pesoBebe]
            .any((n) => n == null || !n.isFinite || n < 0 || n > 100)) {
      setState(() => _erroPremissas =
          'Revise composição e compra: participação e rendimento '
              'e serviços devem ser maiores que zero; embalagem não pode ser negativa. Pesos de público: 0 a 100%.');
      return;
    }
    final item = ItemEstimativaFinanceira(
      id: widget.id ??
          widget.inicial?.id ??
          'manual_${DateTime.now().microsecondsSinceEpoch}',
      premissas: {
        ..._premissasParaSalvar(),
        'peso_crianca': pesoCrianca! / 100,
        'peso_bebe': pesoBebe! / 100,
        'receita': _receita.text.trim(),
        'grupo': _grupo,
        'dividir_grupo': _dividirGrupo && _grupo.isNotEmpty,
        'ajustar_por_duracao': _ajustarDuracao,
        'numero_servicos': servicos,
        'estado': _estado,
        'papel_na_refeicao': _papel,
        'participacao': _numero(_participacao.text)!,
        'rendimento': _numero(_rendimento.text)!,
        'embalagem': _numero(_embalagem.text)!,
        'unidade_consumo': _unidadeConsumo,
        'revisada_pelo_organizador': true,
        'preco_unidade': _unidade.label,
        'preco_estado': _premissasEditadas['estado_compra'] ?? _estado,
        'preco_fonte': 'organizador',
        'preco_confirmado_em': DateTime.now().toUtc().toIso8601String(),
        'consumo_referencia': widget.inicial?.premissas['consumo_referencia'] ??
            widget.inicial?.quantidadePorConvidadoEquivalente,
      },
      categoria: _tipo,
      nome: _nome.text.trim(),
      tipoItem: _tipo,
      publicoAlvo: _publico,
      unidade: _unidade,
      quantidadePorConvidadoEquivalente: _numero(_consumo.text)!,
      valorUnitarioMedio: _numero(_preco.text) ?? 0,
      selecionado: widget.inicial?.selecionado ?? true,
    );
    setState(() {
      _salvando = true;
      _erroSalvamento = null;
    });
    try {
      await widget.onSalvar?.call(item);
      if (!mounted) return;
      setState(() => _salvando = false);
      Navigator.pop(context, item);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erroSalvamento = e is StateError
            ? e.message.toString()
            : 'Não foi possível salvar o ajuste. Confira sua conexão e tente novamente.';
      });
    }
  }

  Map<String, dynamic> _premissasParaSalvar() {
    final meta = Map<String, dynamic>.from(_premissasEditadas);
    final snapshot = meta['referencia_snapshot'];
    if (snapshot is Map &&
        ((meta['consumo_escolhido'] ?? snapshot['padrao']) !=
                _numero(_consumo.text) ||
            snapshot['papel'] != _papel ||
            snapshot['estado_consumo'] != _estado ||
            snapshot['unidade'] != _unidade.name ||
            !ReferenciaContextual(Map<String, dynamic>.from(snapshot))
                .reconhece(_nome.text))) {
      meta['referencia_origem_snapshot'] = meta.remove('referencia_snapshot');
      meta.remove('referencia_id');
      meta.remove('referencia_versao');
      meta['origem'] = 'ajuste_organizador';
    }
    final rendimentoSnapshot = meta['rendimento_snapshot'];
    if (rendimentoSnapshot is Map &&
        (_numero(_rendimento.text) != rendimentoSnapshot['padrao'] ||
            rendimentoSnapshot['estado_consumo'] != _estado ||
            rendimentoSnapshot['unidade'] != _unidade.name ||
            !ReferenciaContextual(Map<String, dynamic>.from(rendimentoSnapshot))
                .reconhece(_nome.text))) {
      meta['rendimento_origem_snapshot'] = meta.remove('rendimento_snapshot');
      meta.remove('rendimento_referencia');
      meta.remove('rendimento_fonte');
      meta.remove('rendimento_estimado');
    }
    if (meta['rendimento_snapshot'] == null &&
        meta['rendimento_referencia'] != null &&
        (_numero(_rendimento.text) != widget.inicial?.rendimento ||
            _nome.text.trim() != widget.inicial?.nome ||
            _unidade != widget.inicial?.unidade ||
            _estado != 'pronto' ||
            meta['rendimento_medido'] == true)) {
      meta.remove('rendimento_referencia');
      meta.remove('rendimento_fonte');
      meta.remove('rendimento_estimado');
    }
    // Edição explícita passa a ser uma regra própria, protegida de novas propostas.
    if (meta['proposta_refeicao'] != null) {
      meta.remove('consumo_min');
      meta.remove('consumo_max');
      meta.remove('proposta_motivo');
      meta['origem'] = 'ajuste_organizador';
      if (_numero(_rendimento.text) != widget.inicial?.rendimento) {
        meta['rendimento_medido'] = false;
      }
    }
    meta.remove('proposta_refeicao');
    meta.remove('proposta_respostas');
    meta.remove('proposta_apenas_servir');
    if ((meta['referencia_contextual'] != null ||
            meta['origem'] == 'referencia_organizador') &&
        (meta['papel_na_refeicao'] != _papel ||
            meta['estado'] != _estado ||
            meta['consumo_escolhido'] != _numero(_consumo.text) ||
            _unidadeConsumo != (meta['referencia_unidade_consumo'] ?? 'kg') ||
            (meta['nome_referencia'] ?? widget.inicial?.nome ?? _nome.text) !=
                _nome.text ||
            (meta['receita_referencia'] != null &&
                meta['receita_referencia'] != _receita.text.trim()))) {
      meta.remove('referencia_contextual');
      meta.remove('consumo_min');
      meta.remove('consumo_max');
      meta['origem'] = 'ajuste_organizador';
    }
    return meta;
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _buscarReferencia() async {
    if (widget.catalogo != null) {
      await _buscarCatalogo();
      return;
    }
    const service = ReferenciaPorcaoService();
    final refs = service
        .buscar(_nome.text, _papel)
        .where((r) => r.unidade == _unidade)
        .toList();
    if (refs.isEmpty) {
      _aviso(
          'Não há referência publicada para este nome, papel e unidade. Defina a porção para a sua receita; não será presumida uma redução.');
      return;
    }
    final ref = refs.length == 1
        ? refs.first
        : await showDialog<ReferenciaPorcao>(
            context: context,
            builder: (ctx) => SimpleDialog(
                    title: const Text('Escolha a referência'),
                    children: [
                      for (final r in refs)
                        SimpleDialogOption(
                            onPressed: () => Navigator.pop(ctx, r),
                            child: Text('${r.nome} — ${r.fonte}'))
                    ]));
    if (ref == null || !mounted) return;
    String formatar(double v) => ref.unidade == UnidadeEstimativa.quilo
        ? '${(v * 1000).round()} g'
        : ref.unidade == UnidadeEstimativa.litro
            ? '${(v * 1000).round()} ml'
            : '${v.toStringAsFixed(0)} ${ref.unidade.label}';
    final escolha = await showDialog<double>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text('${ref.nome} como $_papel'),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                      'Referência: ${formatar(ref.minimo)} a ${formatar(ref.maximo)} por pessoa, estado ${ref.estado}. Escolha um ponto de partida; crianças e bebês usam os pesos que você configurar. A reserva será adicionada separadamente.'),
                  const SizedBox(height: 12),
                  Text('Contexto: ${ref.contexto}'),
                  Text(
                      'Referência versão 1 · conferida em ${ref.verificadoEm}. A seleção confirma apenas o contexto, não a suficiência para sua festa.'),
                  const SizedBox(height: 8),
                  SelectableText(ref.fonte),
                ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, ref.minimo),
                      child: Text('Usar ${formatar(ref.minimo)}')),
                  if (ref.maximo != ref.minimo)
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, ref.maximo),
                        child: Text('Usar ${formatar(ref.maximo)}'))
                ]));
    if (escolha == null || !mounted) return;
    ({double entrada, double saida})? medicao;
    if (_estado == 'pronto' && ref.estado != 'pronto') {
      medicao = await showDialog<({double entrada, double saida})>(
          context: context,
          builder: (_) => const CalculadoraRendimentoDialog(unidade: 'kg'));
      if (medicao == null || !mounted) return;
    }
    final item = ItemEstimativaFinanceira(
        id: widget.id ?? widget.inicial?.id ?? 'manual',
        nome: _nome.text,
        categoria: _tipo,
        tipoItem: _tipo,
        publicoAlvo: _publico,
        unidade: _unidade,
        quantidadePorConvidadoEquivalente: escolha,
        valorUnitarioMedio: _numero(_preco.text) ?? 0,
        premissas: _premissasEditadas);
    final aplicada = service.aplicar(
        item: item,
        referencia: ref,
        porcao: escolha,
        estadoDestino: _estado == 'pronto' ? 'pronto' : ref.estado,
        pesoBase: medicao?.entrada,
        pesoPronto: medicao?.saida);
    final mudouCompra =
        (_premissasEditadas['estado_compra'] ?? _premissasEditadas['estado']) !=
                aplicada.premissas['estado_compra'] ||
            (_numero(_rendimento.text) ?? 1) != 1;
    setState(() {
      _premissasEditadas = {
        ...aplicada.premissas,
        'consumo_escolhido': aplicada.quantidadePorConvidadoEquivalente
      };
      _consumo.text = aplicada.quantidadePorConvidadoEquivalente
          .toString()
          .replaceAll('.', ',');
      _estado = aplicada.premissas['estado'] as String;
      _unidadeConsumo = ref.unidade.label;
      _rendimento.text = '1';
      _dividirGrupo = false;
      _ajustarDuracao = false;
      if (mudouCompra && (_numero(_preco.text) ?? 0) > 0) {
        _preco.clear();
      }
    });
    if (mudouCompra) {
      _aviso(
          'Confira o preço por ${ref.unidade.label} na nova base de compra. Um preço anterior não foi convertido automaticamente.');
    }
  }

  Future<void> _buscarCatalogo() async {
    final respostas = <String, String>{};
    final catalogo = CatalogoContextual(
        widget.catalogo!.referencias
            .where((r) =>
                r.tipo == 'porcao' &&
                r.dados['papel'] == _papel &&
                r.dados['unidade'] == _unidade.name &&
                r.dados['estado_consumo'] == _estado)
            .toList(),
        estado: widget.catalogo!.estado,
        aviso: widget.catalogo!.aviso);
    final regra = await showDialog<ItemEstimativaFinanceira>(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, rebuild) {
              final p = const PropostaRefeicaoService().gerar(
                  itens: [
                    CardapioItem(
                        idEvento: widget.inicial?.premissas['id_evento']
                                ?.toString() ??
                            'manual',
                        idCardapio: widget.inicial?.premissas['id_cardapio']
                                ?.toString() ??
                            'manual',
                        idItem: 'manual',
                        nome: _nome.text,
                        publicoAlvo: PublicoAlvoCardapio.values
                            .firstWhere((v) => v.name == _publico),
                        unidade: _unidade.label)
                  ],
                  regras: [],
                  catalogo: catalogo,
                  contexto: widget.contextoReferencia,
                  respostas: respostas);
              return AlertDialog(
                  title: const Text('Referência contextual aprovada'),
                  content: SizedBox(
                      width: 520,
                      child: SingleChildScrollView(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            for (final q in p.perguntas)
                              Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: q.opcoes.isEmpty
                                      ? TextFormField(
                                          initialValue: respostas[q.id],
                                          decoration: InputDecoration(
                                              labelText: q.titulo),
                                          onChanged: (v) => rebuild(
                                              () => respostas[q.id] = v))
                                      : DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          value: q.opcoes.containsKey(
                                                  p.respostas[q.id])
                                              ? p.respostas[q.id]
                                              : q.padrao,
                                          decoration: InputDecoration(
                                              labelText: q.titulo),
                                          items: [
                                            for (final e in q.opcoes.entries)
                                              DropdownMenuItem(
                                                  value: e.key,
                                                  child: Text(e.value,
                                                      maxLines: 3,
                                                      overflow: TextOverflow
                                                          .ellipsis))
                                          ],
                                          onChanged: (v) {
                                            if (v != null) {
                                              rebuild(
                                                  () => respostas[q.id] = v);
                                            }
                                          })),
                            for (final texto in [
                              ...p.pendencias,
                              ...p.motivos.values
                            ])
                              Text(texto),
                          ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: p.regras.length != 1
                            ? null
                            : () => Navigator.pop(ctx, p.regras.single),
                        child: const Text('Usar no editor para revisão'))
                  ]);
            }));
    if (regra == null || !mounted) return;
    setState(() {
      _premissasEditadas = {
        ..._premissasEditadas,
        ...regra.premissas,
        'id_evento': widget.inicial?.premissas['id_evento'],
        'id_cardapio': widget.inicial?.premissas['id_cardapio'],
        'id_item_cardapio': widget.inicial?.premissas['id_item_cardapio'],
        'consumo_escolhido': regra.quantidadePorConvidadoEquivalente
      };
      _consumo.text = regra.quantidadePorConvidadoEquivalente.toString();
      _rendimento.text = regra.rendimento.toString();
      _preco.clear();
      _dividirGrupo = false;
      _ajustarDuracao = false;
    });
  }

  Future<void> _referenciaDaReceita() async {
    final atual = _numero(_consumo.text);
    if (atual == null ||
        !atual.isFinite ||
        atual <= 0 ||
        _papel == 'a_confirmar' ||
        !['cru', 'seco', 'pronto'].contains(_estado) ||
        _receita.text.trim().isEmpty) {
      _aviso(
          'Defina receita, papel, estado e porção antes de registrar uma faixa própria.');
      return;
    }
    final minimo = TextEditingController(text: atual.toString());
    final maximo = TextEditingController(text: atual.toString());
    final fonte = TextEditingController();
    _referenciasTemporarias.addAll([minimo, maximo, fonte]);
    final form = GlobalKey<FormState>();
    final salvar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Referência da minha receita'),
                content: SingleChildScrollView(
                    child: Form(
                        key: form,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(
                              'Faixa por adulto equivalente por serviço, em $_unidadeConsumo. É uma referência informada por você; não será tratada como validação externa.'),
                          for (final e in {
                            minimo: 'Mínimo da receita',
                            maximo: 'Máximo da receita'
                          }.entries)
                            TextFormField(
                                controller: e.key,
                                decoration: InputDecoration(labelText: e.value),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [NumericInput.decimal()],
                                validator: (v) {
                                  final n = _numero(v ?? '');
                                  return n == null || !n.isFinite || n <= 0
                                      ? 'Informe um valor positivo'
                                      : null;
                                }),
                          TextFormField(
                              controller: fonte,
                              decoration: const InputDecoration(
                                  labelText:
                                      'Origem ou anotação da referência'),
                              validator: (v) => (v?.trim().isEmpty ?? true)
                                  ? 'Identifique a origem'
                                  : null),
                        ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () {
                        if (!form.currentState!.validate()) return;
                        if (_numero(minimo.text)! > atual ||
                            _numero(maximo.text)! < atual ||
                            _numero(minimo.text)! > _numero(maximo.text)!) {
                          _aviso(
                              'A faixa deve incluir a porção atual, com mínimo menor ou igual ao máximo.');
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      child: const Text('Usar minha referência'))
                ]));
    if (salvar == true && mounted) {
      setState(() {
        _premissasEditadas = {
          ..._premissasEditadas,
          'referencia_contextual': null,
          'origem': 'referencia_organizador',
          'fonte': fonte.text.trim(),
          'consumo_min': _numero(minimo.text),
          'consumo_max': _numero(maximo.text),
          'consumo_escolhido': atual,
          'papel_na_refeicao': _papel,
          'estado': _estado,
          'nome_referencia': _nome.text,
          'receita_referencia': _receita.text.trim(),
          'referencia_unidade_consumo': _unidadeConsumo,
          'ajustar_por_perfil': false
        };
      });
    }
  }

  Future<void> _medirRendimento() async {
    if (!['kg', 'L'].contains(_unidadeConsumo) ||
        _unidade.label != _unidadeConsumo ||
        !['cru', 'seco', 'pronto'].contains(_estado)) {
      _aviso(
          'Defina o estado e use kg→kg ou L→L para medir a receita. Outras conversões usam o rendimento por unidade de compra.');
      return;
    }
    final medicao = await showDialog<({double entrada, double saida})>(
        context: context,
        builder: (_) => CalculadoraRendimentoDialog(unidade: _unidadeConsumo));
    if (medicao == null || !mounted) return;
    final fator = ReferenciaPorcaoService.rendimentoMedido(
        medicao.entrada, medicao.saida);
    setState(() {
      if (_estado != 'pronto') {
        final consumo = _numero(_consumo.text);
        if (consumo != null) {
          _consumo.text = (consumo * fator).toString().replaceAll('.', ',');
        }
        _premissasEditadas['estado_compra'] = _estado;
      }
      _rendimento.text = fator.toString();
      _estado = 'pronto';
      _premissasEditadas.addAll({
        'peso_base_medido': medicao.entrada,
        'peso_pronto_medido': medicao.saida,
        'rendimento_medido': true
      });
    });
  }

  Widget _parametroCompra(TextEditingController controller, String label,
          String hint, bool zero) =>
      TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [NumericInput.decimal()],
          decoration: _campo(label, Icons.tune, hint: hint),
          validator: (v) {
            final n = _numero(v ?? '');
            return n == null || !n.isFinite || (zero ? n < 0 : n <= 0)
                ? 'Informe um valor ${zero ? 'maior ou igual a zero' : 'maior que zero'}'
                : null;
          });

  InputDecoration _campo(String label, IconData icon,
      {String? hint, String? suffix}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      prefixIcon: Icon(icon, size: 20, color: scheme.primary),
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2)),
      errorMaxLines: 3,
    );
  }

  Widget _secao(String titulo, String descricao, List<Widget> fields) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface)),
        const SizedBox(height: 4),
        Text(descricao,
            style: TextStyle(
                fontSize: 12, height: 1.4, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        ...fields,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tecladoAberto = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PopScope(
        canPop: !_salvando,
        child: AbsorbPointer(
            absorbing: _salvando,
            child: CalculadoraModal(
                titulo: 'Regra de consumo',
                icone: Icons.restaurant_menu_rounded,
                ocupado: _salvando,
                onFechar: () => Navigator.pop(context),
                rodape: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (_erroSalvamento != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(_erroSalvamento!,
                                key: const Key('erro_salvar_regra'),
                                style: TextStyle(color: scheme.error))),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                                backgroundColor: scheme.primary,
                                foregroundColor: scheme.onPrimary,
                                iconColor: scheme.onPrimary,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14))),
                            onPressed: _salvando ? null : _salvar,
                            icon: _salvando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.check_rounded),
                            label: Text(
                                _salvando ? 'Salvando…' : widget.confirmarLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          )),
                      if (!tecladoAberto)
                        SizedBox(
                            width: double.infinity,
                            child: TextButton(
                                style: TextButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48)),
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'))),
                    ])),
                child: Form(
                    key: _form,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.inicial != null &&
                              widget.inicial!.avisosCompatibilidade.isNotEmpty)
                            ExpansionTile(
                                title: const Text(
                                    'Conferir dados da regra anterior'),
                                children: [
                                  for (final aviso
                                      in widget.inicial!.avisosCompatibilidade)
                                    Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(aviso))
                                ]),
                          _secao('O que será servido?',
                              'Identifique o item e quem vai consumi-lo.', [
                            TextFormField(
                                controller: _nome,
                                key: _nomeKey,
                                focusNode: _nomeFocus,
                                readOnly: widget.nome != null,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.next,
                                decoration: _campo(
                                    'Nome do item', Icons.edit_outlined,
                                    hint: 'Ex.: Água, bolo ou salgadinhos'),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Informe o nome'
                                    : null),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                                value: _tipo,
                                isExpanded: true,
                                decoration: _campo(
                                    'Categoria', Icons.category_outlined),
                                items: _tipos.entries
                                    .map((e) => DropdownMenuItem(
                                        value: e.key, child: Text(e.value)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _tipo = v);
                                }),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                                value: _publico,
                                isExpanded: true,
                                decoration: _campo('Quem vai consumir?',
                                    Icons.people_outline_rounded),
                                items: _publicos.entries
                                    .map((e) => DropdownMenuItem(
                                        value: e.key, child: Text(e.value)))
                                    .toList(),
                                onChanged: widget.nome != null
                                    ? null
                                    : (v) {
                                        if (v != null) {
                                          setState(() => _publico = v);
                                        }
                                      }),
                            if (widget.nome != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                  'Identificação e público definidos no cardápio.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurfaceVariant)),
                            ],
                          ]),
                          _secao(
                              'Quanto será consumido?',
                              'Considere a refeição e os outros itens servidos.',
                              [
                                DropdownButtonFormField<String>(
                                    value: _papel,
                                    isExpanded: true,
                                    decoration: _campo(
                                        'Papel deste item na refeição',
                                        Icons.restaurant_menu),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'a_confirmar',
                                          child: Text('Preciso definir')),
                                      DropdownMenuItem(
                                          value: 'principal',
                                          child: Text('Prato principal')),
                                      DropdownMenuItem(
                                          value: 'acompanhamento',
                                          child: Text('Acompanhamento')),
                                      DropdownMenuItem(
                                          value: 'bebida',
                                          child: Text('Bebida')),
                                      DropdownMenuItem(
                                          value: 'outro', child: Text('Outro')),
                                    ],
                                    onChanged: (v) => setState(
                                        () => _papel = v ?? 'a_confirmar')),
                                const SizedBox(height: 8),
                                const Text(
                                    'Informe abaixo a porção adequada a esse papel. A seleção não converte automaticamente uma porção de prato principal em acompanhamento.'),
                                TextButton.icon(
                                    onPressed: _buscarReferencia,
                                    icon: const Icon(Icons.menu_book_outlined),
                                    label: const Text(
                                        'Buscar referência para este contexto')),
                                if (_premissasEditadas[
                                        'referencia_contextual'] !=
                                    null)
                                  Text(
                                      'Referência contextual aplicada. A faixa é uma orientação de preparo, não uma probabilidade de suficiência.'),
                                const SizedBox(height: 12),
                                TextFormField(
                                    controller: _receita,
                                    decoration: _campo(
                                        'Receita ou preparo (para histórico)',
                                        Icons.description_outlined,
                                        hint:
                                            'Ex.: Arroz branco da casa. Use o mesmo nome ao comparar consumo.')),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<UnidadeEstimativa>(
                                    value: _unidade,
                                    isExpanded: true,
                                    decoration: _campo('Unidade de medida',
                                        Icons.straighten_rounded),
                                    items: _unidades.entries
                                        .map((e) => DropdownMenuItem(
                                            value: e.key, child: Text(e.value)))
                                        .toList(),
                                    onChanged: widget.unidade != null
                                        ? null
                                        : (v) {
                                            if (v != null) {
                                              setState(() {
                                                if (_unidadeConsumo ==
                                                    _unidade.label) {
                                                  _unidadeConsumo = v.label;
                                                }
                                                if (_unidade != v) {
                                                  _preco.clear();
                                                }
                                                _unidade = v;
                                              });
                                            }
                                          }),
                                const SizedBox(height: 12),
                                TextFormField(
                                    controller: _consumo,
                                    key: _consumoKey,
                                    focusNode: _consumoFocus,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [NumericInput.decimal()],
                                    textInputAction: TextInputAction.next,
                                    decoration: _campo(
                                        'Quantidade por convidado',
                                        Icons.local_dining_outlined,
                                        hint: 'Ex.: 0,6',
                                        suffix: _unidadeConsumo),
                                    validator: (v) {
                                      final n = _numero(v ?? '');
                                      return n == null || !n.isFinite || n <= 0
                                          ? 'Informe um consumo maior que zero'
                                          : null;
                                    }),
                                const SizedBox(height: 10),
                                Text(
                                    'Base: $_unidadeConsumo por ${_tipo == 'descartavel' ? 'pessoa' : 'convidado equivalente'}. '
                                    'O cálculo ajusta o consumo de adultos, crianças e bebês.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        height: 1.5,
                                        color: scheme.onSurfaceVariant)),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                    value: _estado,
                                    isExpanded: true,
                                    decoration: _campo(
                                        'A porção está em qual estado?',
                                        Icons.restaurant),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'não informado',
                                          child: Text('Preciso confirmar')),
                                      DropdownMenuItem(
                                          value: 'cru',
                                          child: Text('Cru, antes do preparo')),
                                      DropdownMenuItem(
                                          value: 'seco',
                                          child:
                                              Text('Seco, antes do preparo')),
                                      DropdownMenuItem(
                                          value: 'pronto',
                                          child: Text('Pronto para servir')),
                                    ],
                                    onChanged: (v) => setState(() {
                                          if (_estado != v &&
                                              (_premissasEditadas[
                                                          'estado_compra'] ==
                                                      null ||
                                                  _premissasEditadas[
                                                          'estado_compra'] ==
                                                      _estado)) {
                                            _preco.clear();
                                          }
                                          _estado = v ?? 'não informado';
                                        })),
                                const SizedBox(height: 12),
                                _parametroCompra(
                                    _servicos,
                                    'Número de serviços deste item',
                                    '1 para um almoço; aumente se a mesma porção será servida novamente.',
                                    false),
                              ]),
                          if (_erroPremissas != null)
                            Text(_erroPremissas!,
                                style: TextStyle(color: scheme.error)),
                          ExpansionTile(
                              title: const Text('Composição e compra'),
                              subtitle: const Text(
                                  'Divisão, rendimento e embalagens'),
                              children: [
                                _secao(
                                    'Composição e compra',
                                    'A porção informada vale integralmente. Ative a divisão apenas '
                                        'se os itens forem alternativas entre si. Cru e pronto não são convertidos sem rendimento informado.',
                                    [
                                      SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text(
                                              'Dividir porções entre alternativas'),
                                          subtitle: const Text(
                                              'Ative também nos outros itens que participarão da divisão.'),
                                          value: _dividirGrupo,
                                          onChanged: (v) => setState(
                                              () => _dividirGrupo = v)),
                                      DropdownButtonFormField<String>(
                                          value: _grupo,
                                          isExpanded: true,
                                          decoration: _campo(
                                              'Grupo de alternativas',
                                              Icons.restaurant_outlined),
                                          items: const [
                                            DropdownMenuItem(
                                                value: '',
                                                child: Text('Independente')),
                                            DropdownMenuItem(
                                                value: 'proteinas',
                                                child: Text(
                                                    'Proteínas alternativas')),
                                            DropdownMenuItem(
                                                value: 'acompanhamentos',
                                                child: Text(
                                                    'Acompanhamentos alternativos')),
                                            DropdownMenuItem(
                                                value: 'bebidas_sem_alcool',
                                                child: Text(
                                                    'Bebidas alternativas')),
                                            DropdownMenuItem(
                                                value: 'sobremesas',
                                                child: Text(
                                                    'Sobremesas alternativas')),
                                          ],
                                          onChanged: (v) =>
                                              setState(() => _grupo = v ?? '')),
                                      const SizedBox(height: 12),
                                      _parametroCompra(
                                          _participacao,
                                          'Peso de participação',
                                          '1 = participação igual',
                                          false),
                                      SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text(
                                              'Ajustar pela duração da festa'),
                                          subtitle: const Text(
                                              'Escala estimada do aplicativo. Deixe desligado para uma porção por refeição.'),
                                          value: _ajustarDuracao,
                                          onChanged: (v) => setState(
                                              () => _ajustarDuracao = v)),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                          value: _unidadeConsumo,
                                          decoration: _campo(
                                              'Unidade da porção consumida',
                                              Icons.straighten),
                                          items: UnidadeEstimativa.values
                                              .map((u) => DropdownMenuItem(
                                                  value: u.label,
                                                  child: Text(u.label)))
                                              .toList(),
                                          onChanged: (v) => setState(() =>
                                              _unidadeConsumo =
                                                  v ?? _unidade.label)),
                                      const SizedBox(height: 12),
                                      _parametroCompra(
                                          _rendimento,
                                          'Rendimento por unidade de compra',
                                          'Ex.: garrafa de 2 L → 2; 1 kg cru rende 3 kg servido → 3. Mesma medida → 1.',
                                          false),
                                      TextButton.icon(
                                          onPressed: _medirRendimento,
                                          icon:
                                              const Icon(Icons.scale_outlined),
                                          label: const Text(
                                              'Medir rendimento da minha receita')),
                                      _parametroCompra(
                                          _pesoCrianca,
                                          'Porção por criança (%)',
                                          'Percentual da porção de adulto. 0 exclui este público do item; não representa uma recomendação por idade.',
                                          true),
                                      const SizedBox(height: 12),
                                      _parametroCompra(
                                          _pesoBebe,
                                          'Porção por bebê (%)',
                                          'Informe quem realmente consumirá este alimento. 0 exclui este público do item.',
                                          true),
                                      const Text(
                                          'Os valores iniciais de 60% e 20% são premissas antigas do aplicativo; ajuste-os ao público e ao alimento.'),
                                      const SizedBox(height: 12),
                                      _parametroCompra(
                                          _embalagem,
                                          'Tamanho da embalagem de compra',
                                          'Ex.: pacote de 5 kg → 5. Avulso → 0. Compra em ${_unidade.label}.',
                                          true),
                                      if (_premissasEditadas['fonte'] !=
                                          null) ...[
                                        const SizedBox(height: 12),
                                        SelectableText(
                                            'Referência: ${_premissasEditadas['fonte']}'),
                                      ],
                                    ]),
                              ]),
                          TextButton.icon(
                              onPressed: _referenciaDaReceita,
                              icon: const Icon(Icons.bookmark_add_outlined),
                              label: const Text(
                                  'Definir referência da minha receita')),
                          TextButton.icon(
                              icon: const Icon(Icons.restaurant_menu),
                              label: Text(
                                  _premissasEditadas['ficha_tecnica'] == null
                                      ? 'Informar ingredientes da receita'
                                      : 'Editar ingredientes da receita'),
                              onPressed: () async {
                                if (_nome.text.trim().isEmpty) {
                                  _aviso('Informe o nome do item.');
                                  return;
                                }
                                final ficha = await showDialog<
                                        Map<String, dynamic>>(
                                    context: context,
                                    builder: (_) =>
                                        CalculadoraFichaTecnicaDialog(
                                            prato: _nome.text.trim(),
                                            unidade: _unidade.label,
                                            estado: (_premissasEditadas[
                                                        'estado_compra'] ??
                                                    _estado)
                                                .toString(),
                                            inicial: _premissasEditadas[
                                                        'ficha_tecnica'] ==
                                                    null
                                                ? null
                                                : OperacaoCalculadoraService
                                                    .mapa(_premissasEditadas[
                                                        'ficha_tecnica'])));
                                if (!mounted || ficha == null) return;
                                setState(() {
                                  if (ficha.isEmpty) {
                                    _premissasEditadas.remove('ficha_tecnica');
                                  } else {
                                    _premissasEditadas['ficha_tecnica'] = ficha;
                                  }
                                });
                              }),
                          _secao(
                              'Preço estimado',
                              'Opcional. Sem preço, você calcula apenas as quantidades.',
                              [
                                TextFormField(
                                    controller: _preco,
                                    key: _precoKey,
                                    focusNode: _precoFocus,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [NumericInput.moeda()],
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) =>
                                        FocusScope.of(context).unfocus(),
                                    decoration: _campo(
                                        'Preço por ${_unidade.label}',
                                        Icons.payments_outlined,
                                        hint: 'Ex.: 0,50 ou 8,50'),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return null;
                                      }
                                      final n = _numero(v);
                                      return n == null || !n.isFinite || n < 0
                                          ? 'Informe um preço válido'
                                          : null;
                                    }),
                              ]),
                        ])))));
  }
}
