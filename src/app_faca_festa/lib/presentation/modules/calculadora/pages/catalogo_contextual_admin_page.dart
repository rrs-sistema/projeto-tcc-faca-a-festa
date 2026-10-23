import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:app_faca_festa/domain/entities/referencia_contextual.dart';
import 'package:app_faca_festa/domain/repositories/catalogo_contextual_repository.dart';
import 'package:app_faca_festa/data/services/calculadora/catalogo_contextual_legado.dart';
import '../controllers/calculadora_itens_admin_controller.dart';
import '../widgets/calculadora_modal.dart';

class CatalogoContextualAdminPage extends StatefulWidget {
  const CatalogoContextualAdminPage({super.key, required this.controller});
  final CalculadoraItensAdminController controller;
  @override
  State<CatalogoContextualAdminPage> createState() => _CatalogoAdminState();
}

class _CatalogoAdminState extends State<CatalogoContextualAdminPage> {
  String? erro;
  bool carregando = true;
  CatalogoContextualRepository? get repo =>
      widget.controller.repository is CatalogoContextualRepository
          ? widget.controller.repository as CatalogoContextualRepository
          : null;
  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() => carregando = true);
    try {
      await widget.controller.carregarItensBase();
    } catch (_) {
      erro = 'Não foi possível consultar o catálogo.';
    }
    if (mounted) setState(() => carregando = false);
  }

  Future<void> editar({String? id, ReferenciaContextual? inicial}) async {
    try {
      final r =
          inicial ?? (id == null ? null : await repo!.carregarReferencia(id));
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              ReferenciaContextualEditor(repository: repo!, inicial: r));
      await carregar();
    } catch (e) {
      if (mounted) setState(() => erro = 'Falha ao abrir referência: $e');
    }
  }

  Future<void> selecionar(String id) async {
    try {
      final r = await repo!.carregarReferencia(id);
      if (!mounted || r == null) return;
      final ultima = r.dados['aprovado_por'] != null ? r.versao : r.versao - 1;
      if (ultima < 1) {
        throw StateError('Ainda não existe uma versão publicada.');
      }
      await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => CatalogoSelecaoDialog(
              repository: repo! as GovernancaCatalogoRepository,
              id: id,
              ultima: ultima));
      await carregar();
    } catch (_) {
      if (mounted) {
        setState(() =>
            erro = 'Não foi possível abrir a seleção. Atualize o catálogo.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Referências e modelos')),
      body: repo == null
          ? const Center(child: Text('Repositório indisponível.'))
          : ListView(padding: const EdgeInsets.all(16), children: [
              const Text(
                  'Rascunhos não entram nas propostas. Publicar cria uma versão imutável, identifica o aprovador e oferece revisão aos clientes compatíveis. Não altera receitas ou históricos.'),
              if (erro != null) Text(erro!),
              if (carregando) const LinearProgressIndicator(),
              Wrap(spacing: 8, children: [
                FilledButton(
                    onPressed: () => editar(),
                    child: const Text('Nova referência ou modelo')),
                TextButton(onPressed: carregar, child: const Text('Atualizar')),
              ]),
              ExpansionTile(
                  title: const Text('Revisar referências locais existentes'),
                  children: [
                    const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                            'Valores e fontes do código anterior. O enquadramento precisa de revisão; nenhuma fonte foi consultada novamente. Salvar rascunho não publica.')),
                    for (final r in CatalogoContextualLegado.propostas())
                      ListTile(
                          title: Text(r.nome),
                          subtitle: Text(r.id),
                          onTap: () => editar(id: r.id, inicial: r)),
                  ]),
              const Text('Catálogo existente — abrir publicação ou rascunho'),
              for (final item in widget.controller.itensBase)
                ListTile(
                    title: Text(item.nome),
                    subtitle: Text(item.id),
                    trailing: repo is GovernancaCatalogoRepository
                        ? IconButton(
                            tooltip: 'Selecionar versão ou desativar',
                            onPressed: () => selecionar(item.id),
                            icon: const Icon(Icons.history))
                        : null,
                    onTap: () => editar(id: item.id)),
            ]));
}

class ReferenciaContextualEditor extends StatefulWidget {
  const ReferenciaContextualEditor(
      {super.key, required this.repository, this.inicial});
  final CatalogoContextualRepository repository;
  final ReferenciaContextual? inicial;
  @override
  State<ReferenciaContextualEditor> createState() => _ReferenciaEditorState();
}

class _ReferenciaEditorState extends State<ReferenciaContextualEditor> {
  final campos = <String, TextEditingController>{};
  final labels = {
    'id': 'Identificador estável (letras minúsculas, números e _)',
    'nome': 'Nome editorial',
    'aliases': 'Nomes exatos aceitos, separados por vírgula',
    'alimento_receita': 'Alimento ou receita coberta',
    'contexto': 'Contexto de uso',
    'limitacoes': 'Limitações e o que a referência não cobre',
    'fonte': 'Fonte HTTPS ou origem codigo:',
    'verificado_em': 'Data de verificação real, opcional (AAAA-MM-DD)',
    'revisao_editorial': 'Parecer desta revisão editorial',
    'minimo': 'Mínimo por pessoa',
    'maximo': 'Máximo por pessoa',
    'padrao': 'Ponto de partida dentro da faixa',
    'publicos': 'Públicos: adultos, criancas, bebes ou todos (vírgulas)',
    'obtencoes': 'Obtenção: servir, pronto ou preparar (vírgulas)',
    'periodos': 'Períodos: manha, tarde, noite ou qualquer (vírgulas)',
    'infraestrutura':
        'Recursos exigidos, opcionais: cozinha, refrigeracao, aquecimento, equipe_preparo (vírgulas)',
    'hora_inicio': 'Início da faixa horária, opcional (HH:mm)',
    'hora_fim': 'Fim da faixa horária, opcional (HH:mm)',
    'duracao_minima': 'Duração mínima coberta, opcional (minutos)',
    'duracao_maxima': 'Duração máxima coberta, opcional (minutos)',
    'itens':
        'Itens do modelo: um por linha, nome | comida/bebida/bolo/sobremesa/outro',
  };
  String tipo = 'porcao',
      servico = 'refeicao',
      formato = 'buffet',
      papel = 'outro',
      unidade = 'quilo',
      estado = 'pronto',
      compra = 'pronto';
  bool salvando = false;
  bool aprovada = false;
  String? erro;
  ReferenciaContextual? proposta;
  String pedido = const Uuid().v4();
  int esperada = 0;
  @override
  void initState() {
    super.initState();
    final r = widget.inicial, d = r?.dados ?? {};
    esperada = r == null
        ? 0
        : d['aprovado_por'] != null
            ? r.versao
            : r.versao - 1;
    for (final k in labels.keys) {
      final valor = d[k];
      campos[k] = TextEditingController(
          text: k == 'itens' && valor is List
              ? valor.map((i) => '${i['nome']} | ${i['tipo']}').join('\n')
              : valor is List
                  ? valor.join(', ')
                  : valor?.toString() ?? '');
    }
    for (final e in {
      'publicos': 'adultos',
      'obtencoes': 'servir',
      'periodos': 'qualquer'
    }.entries) {
      if (campos[e.key]!.text.isEmpty) campos[e.key]!.text = e.value;
    }
    tipo = d['tipo'] ?? tipo;
    servico = (d['servicos'] as List?)?.first ?? servico;
    formato = (d['formatos'] as List?)?.first ?? formato;
    papel = d['papel'] ?? papel;
    unidade = d['unidade'] ?? unidade;
    estado = d['estado_consumo'] ?? estado;
    compra = d['estado_compra'] ?? compra;
  }

  @override
  void dispose() {
    for (final c in campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  void mudou() {
    setState(() {
      proposta = null;
      aprovada = false;
    });
    pedido = const Uuid().v4();
  }

  Future<void> aprovar() async {
    if (proposta == null ||
        widget.repository is! GovernancaCatalogoRepository) {
      return;
    }
    setState(() => salvando = true);
    try {
      await (widget.repository as GovernancaCatalogoRepository)
          .aprovarReferencia(proposta!, esperada, '${pedido}_aprovar');
      if (mounted) setState(() => aprovada = true);
    } catch (_) {
      if (mounted) {
        setState(() => erro =
            'A aprovação não foi confirmada. Seus campos foram mantidos.');
      }
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  void revisar() {
    try {
      final d = <String, dynamic>{
        ...widget.inicial?.dados ?? {},
        'schema': 1,
        'motor_minimo': 1,
        'versao': esperada + 1,
        'tipo': tipo,
        'servicos': [servico],
        'formatos': [formato],
        'papel': papel,
        'unidade': unidade,
        'estado_consumo': estado,
        'estado_compra': compra,
        'aprovado_por': null,
        'aprovado_em': null
      };
      for (final e in campos.entries) {
        final v = e.value.text.trim();
        if (['aliases', 'publicos', 'obtencoes', 'periodos', 'infraestrutura']
            .contains(e.key)) {
          d[e.key] = v
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        } else if (['minimo', 'maximo', 'padrao'].contains(e.key)) {
          if (tipo != 'modelo') {
            d[e.key] = double.tryParse(v.replaceAll(',', '.'));
          }
        } else if (['duracao_minima', 'duracao_maxima'].contains(e.key)) {
          d[e.key] = v.isEmpty ? null : int.tryParse(v);
          if (v.isNotEmpty && d[e.key] == null) {
            throw ArgumentError('Informe minutos inteiros.');
          }
        } else if (e.key == 'itens') {
          if (tipo == 'modelo') {
            d[e.key] = v.split('\n').where((l) => l.trim().isNotEmpty).map((l) {
              final p = l.split('|');
              return {
                'nome': p.first.trim(),
                'tipo': p.length == 2 ? p.last.trim() : ''
              };
            }).toList();
          }
        } else {
          d[e.key] =
              ['verificado_em', 'hora_inicio', 'hora_fim'].contains(e.key) &&
                      v.isEmpty
                  ? null
                  : v;
        }
      }
      final r = ReferenciaContextual(d);
      setState(() {
        proposta = r;
        erro = null;
      });
    } catch (e) {
      setState(() => erro = 'Confira os campos: $e');
    }
  }

  Future<void> guardar(bool publicar) async {
    if (proposta == null) return;
    setState(() => salvando = true);
    try {
      if (publicar) {
        await widget.repository.publicarReferencia(proposta!, esperada, pedido);
      } else {
        await widget.repository.salvarRascunhoReferencia(proposta!, esperada);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => erro =
            'Não foi possível confirmar. Seus campos foram mantidos: $e');
      }
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  Widget select(String label, String atual, List<String> valores,
          ValueChanged<String> mudar) =>
      Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DropdownButtonFormField<String>(
              value: atual,
              isExpanded: true,
              decoration: InputDecoration(
                  labelText: label, border: const OutlineInputBorder()),
              items: [
                for (final v in valores)
                  DropdownMenuItem(value: v, child: Text(v))
              ],
              onChanged: salvando
                  ? null
                  : (v) {
                      if (v != null) {
                        mudar(v);
                        mudou();
                      }
                    }));
  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !salvando,
      child: AlertDialog(
          title: Text('Revisão editorial · versão ${esperada + 1}'),
          content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    const Text(
                        'Publique somente os contextos efetivamente cobertos pela fonte. Não informe uma data de verificação que não ocorreu. Não há preços nesta referência.'),
                    select('Tipo', tipo, ['porcao', 'modelo', 'rendimento'],
                        (v) => tipo = v),
                    for (final e in campos.entries)
                      if (!(['minimo', 'maximo', 'padrao'].contains(e.key) &&
                              tipo == 'modelo') &&
                          !(e.key == 'itens' && tipo != 'modelo'))
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TextField(
                                controller: e.value,
                                enabled: !salvando &&
                                    (e.key != 'id' || widget.inicial == null),
                                minLines: 1,
                                maxLines: [
                                  'contexto',
                                  'limitacoes',
                                  'revisao_editorial',
                                  'itens'
                                ].contains(e.key)
                                    ? 5
                                    : 1,
                                onChanged: (_) => mudou(),
                                decoration: InputDecoration(
                                    labelText: labels[e.key],
                                    border: const OutlineInputBorder()))),
                    select('Serviço coberto', servico, ['refeicao', 'lanche'],
                        (v) => servico = v),
                    select(
                        'Formato coberto',
                        formato,
                        ['buffet', 'empratado', 'volante', 'autosservico'],
                        (v) => formato = v),
                    select(
                        'Papel',
                        papel,
                        ['principal', 'acompanhamento', 'bebida', 'outro'],
                        (v) => papel = v),
                    select('Unidade', unidade, ['quilo', 'litro', 'unidade'],
                        (v) => unidade = v),
                    select('Estado de consumo', estado,
                        ['cru', 'seco', 'pronto'], (v) => estado = v),
                    select('Estado de compra', compra,
                        ['cru', 'seco', 'pronto'], (v) => compra = v),
                    if (erro != null) Text(erro!),
                    if (aprovada)
                      const Text(
                          'Aprovação registrada. A referência ainda aguarda publicação.'),
                    if (proposta != null)
                      Text(
                          'Revisão pronta: ${proposta!.nome} · ${proposta!.chave}. Fonte: ${proposta!.dados['fonte']}. Publicar identifica você como responsável e mantém as versões anteriores.'),
                    if (salvando) const LinearProgressIndicator(),
                  ]))),
          actions: [
            TextButton(
                onPressed: salvando ? null : () => Navigator.pop(context),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: salvando ? null : revisar,
                child: const Text('Revisar')),
            if (proposta != null)
              TextButton(
                  onPressed: salvando ? null : () => guardar(false),
                  child: const Text('Salvar rascunho')),
            if (proposta != null)
              TextButton(
                  onPressed: salvando || aprovada ? null : aprovar,
                  child: const Text('Aprovar referência')),
            if (proposta != null)
              FilledButton(
                  onPressed: salvando ? null : () => guardar(true),
                  child: Text(aprovada
                      ? 'Publicar versão aprovada'
                      : 'Aprovar e publicar')),
          ]));
}

class CatalogoSelecaoDialog extends StatefulWidget {
  const CatalogoSelecaoDialog(
      {super.key,
      required this.repository,
      required this.id,
      required this.ultima});
  final GovernancaCatalogoRepository repository;
  final String id;
  final int ultima;
  @override
  State<CatalogoSelecaoDialog> createState() => _CatalogoSelecaoState();
}

class _CatalogoSelecaoState extends State<CatalogoSelecaoDialog> {
  final versao = TextEditingController();
  final pedido = const Uuid().v4();
  bool ocupado = false, desativar = false;
  String? erro;
  @override
  void dispose() {
    versao.dispose();
    super.dispose();
  }

  Future<void> confirmar() async {
    final alvo = int.tryParse(versao.text.trim());
    if (!desativar && (alvo == null || alvo < 1 || alvo > widget.ultima)) {
      setState(() =>
          erro = 'Informe uma versão publicada entre 1 e ${widget.ultima}.');
      return;
    }
    setState(() => ocupado = true);
    try {
      await widget.repository.selecionarVersao(widget.id, widget.ultima,
          desativar ? null : alvo, '${pedido}_${desativar ? 'off' : alvo}');
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => erro =
            'Seleção não confirmada. Atualize se outra revisão foi publicada.');
      }
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !ocupado,
      child: CalculadoraModal(
          titulo: 'Selecionar referência publicada',
          icone: Icons.history,
          ocupado: ocupado,
          onFechar: () => Navigator.pop(context),
          rodape: FilledButton(
              onPressed: ocupado ? null : confirmar,
              child: const Text('Confirmar seleção')),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text(
                'A seleção muda apenas novas propostas. Receitas, históricos aprovados, compras e pagamentos são preservados.'),
            CheckboxListTile(
                value: desativar,
                title: const Text('Desativar seleção desta referência'),
                onChanged:
                    ocupado ? null : (v) => setState(() => desativar = v!)),
            if (!desativar)
              TextField(
                  controller: versao,
                  enabled: !ocupado,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'Versão publicada (1 a ${widget.ultima})')),
            if (erro != null) Text(erro!),
          ])));
}
