import 'package:app_faca_festa/presentation/widgets/festa_scroll_area.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/data/datasources/remote/abrangencia_remote_datasource.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';

class TabelasAbrangenciaAdminPage extends StatefulWidget {
  const TabelasAbrangenciaAdminPage({super.key, this.datasource});

  final AbrangenciaRemoteDatasource? datasource;

  @override
  State<TabelasAbrangenciaAdminPage> createState() =>
      _TabelasAbrangenciaAdminPageState();
}

class _TabelasAbrangenciaAdminPageState
    extends State<TabelasAbrangenciaAdminPage> {
  late final _datasource = widget.datasource ?? AbrangenciaRemoteDatasource();
  late var _consulta = _datasource.consultarAdmin();

  void _recarregar() {
    setState(() {
      _consulta = _datasource.consultarAdmin();
    });
  }

  Future<void> _editar(AbrangenciaAdmin dados, TabelaAbrangencia? base) async {
    final publicada = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PublicarTabelaDialog(
        dados: dados,
        base: base,
        datasource: _datasource,
      ),
    );
    if (publicada == true && mounted) {
      _recarregar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tabela publicada com sucesso.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminPalette.surface,
      appBar: AdminBackAppBar(
        title: 'Faixas de abrangência',
        subtitle: 'Premium do fornecedor',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Recarregar tabelas',
            onPressed: _recarregar,
          ),
        ],
      ),
      body: FestaContent(
          child: FutureBuilder<AbrangenciaAdmin>(
        future: _consulta,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AdminEmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Não foi possível carregar as tabelas.',
              actionLabel: 'Tentar novamente',
              onAction: _recarregar,
            );
          }
          return _conteudo(snapshot.requireData);
        },
      )),
    );
  }

  Widget _conteudo(AbrangenciaAdmin dados) {
    final vigente = dados.vigente;
    final datasAgendadas = <DateTime>{};
    final agendadas = <TabelaAbrangencia>[];
    final anteriores = <TabelaAbrangencia>[];
    TabelaAbrangencia? publicacaoVigente;
    for (final tabela in dados.historico) {
      if (tabela.id == vigente?.id) {
        publicacaoVigente = tabela;
      } else if (tabela.vigencia.isAfter(dados.hoje) &&
          datasAgendadas.add(tabela.vigencia)) {
        agendadas.add(tabela);
      } else {
        anteriores.add(tabela);
      }
    }
    agendadas.sort((a, b) => a.vigencia.compareTo(b.vigencia));
    final texto = Theme.of(context).textTheme;
    final datas = MaterialLocalizations.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: FestaScrollArea(
            color: AdminPalette.primary,
            maxWidth: double.infinity,
            child: ListView(
              primary: true,
              padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    Text('Preços de cobertura',
                        style: texto.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AdminPalette.ink)),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminPalette.primary,
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: () => _editar(dados, vigente),
                      icon: const Icon(Icons.add),
                      label: const Text('Publicar tabela'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AdminCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 32,
                        runSpacing: 12,
                        children: [
                          Text('Até ${dados.raioGratuitoKm} km gratuitos',
                              style: texto.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AdminPalette.primary)),
                          Text('Expansão em faixas de ${dados.incrementoKm} km',
                              style: texto.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A mensalidade soma os adicionais das faixas. '
                        'A cobrança é separada das comissões por serviço.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (vigente == null)
                  AdminCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nenhuma tabela vigente', style: texto.titleLarge),
                        const SizedBox(height: 8),
                        Text(agendadas.isEmpty
                            ? 'Publique os valores das faixas para definir a mensalidade do Premium.'
                            : 'A primeira tabela entra em vigor em ${datas.formatCompactDate(agendadas.first.vigencia)}.'),
                      ],
                    ),
                  )
                else
                  AdminCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Tabela vigente',
                            style: texto.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                            'Em vigor desde ${datas.formatCompactDate(vigente.vigencia)}'),
                        const SizedBox(height: 20),
                        _FaixasTabela(
                            tabela: vigente,
                            raioGratuitoKm: dados.raioGratuitoKm),
                        const SizedBox(height: 12),
                        Text('Vigência pelo horário de Brasília.',
                            style: texto.bodySmall
                                ?.copyWith(color: AdminPalette.muted)),
                        _DadosPublicacao(tabela: publicacaoVigente ?? vigente),
                      ],
                    ),
                  ),
                if (agendadas.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('Próximas vigências', style: texto.titleLarge),
                  const SizedBox(height: 12),
                  for (final tabela in agendadas)
                    _PublicacaoCard(
                      tabela: tabela,
                      raioGratuitoKm: dados.raioGratuitoKm,
                      agendada: true,
                      onUsarComoBase: () => _editar(dados, tabela),
                    ),
                ],
                if (anteriores.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('Histórico de publicações', style: texto.titleLarge),
                  const SizedBox(height: 4),
                  const Text(
                      'Consulte os valores anteriores ou use uma publicação como base.'),
                  const SizedBox(height: 12),
                  for (final tabela in anteriores)
                    _PublicacaoCard(
                      tabela: tabela,
                      raioGratuitoKm: dados.raioGratuitoKm,
                      agendada: false,
                      onUsarComoBase: () => _editar(dados, tabela),
                    ),
                ],
              ],
            )),
      ),
    );
  }
}

class _PublicacaoCard extends StatelessWidget {
  const _PublicacaoCard({
    required this.tabela,
    required this.raioGratuitoKm,
    required this.agendada,
    required this.onUsarComoBase,
  });

  final TabelaAbrangencia tabela;
  final int raioGratuitoKm;
  final bool agendada;
  final VoidCallback onUsarComoBase;

  @override
  Widget build(BuildContext context) {
    final datas = MaterialLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdminCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey(tabela.id),
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title:
                Text('Vigência em ${datas.formatCompactDate(tabela.vigencia)}'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  agendada
                      ? AdminStatusChip.warning('Agendada')
                      : AdminStatusChip.neutral('Substituída'),
                  Text('${tabela.faixas.length} faixas Premium'),
                ],
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FaixasTabela(
                        tabela: tabela, raioGratuitoKm: raioGratuitoKm),
                    _DadosPublicacao(tabela: tabela),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onUsarComoBase,
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        label: const Text('Usar como base'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DadosPublicacao extends StatelessWidget {
  const _DadosPublicacao({required this.tabela});

  final TabelaAbrangencia tabela;

  @override
  Widget build(BuildContext context) {
    final datas = MaterialLocalizations.of(context);
    final publicadaEm = tabela.publicadaEm?.toLocal();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (publicadaEm != null)
            Text(
                'Publicada em ${datas.formatCompactDate(publicadaEm)} às '
                '${datas.formatTimeOfDay(TimeOfDay.fromDateTime(publicadaEm), alwaysUse24HourFormat: true)}',
                style: Theme.of(context).textTheme.bodySmall),
          if (tabela.autorId != null || tabela.autorNome != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Responsável pela publicação: '
                '${tabela.autorNome?.trim().isNotEmpty == true ? tabela.autorNome!.trim() : 'Usuário indisponível'}',
              ),
            ),
        ],
      ),
    );
  }
}

class _FaixasTabela extends StatelessWidget {
  const _FaixasTabela({required this.tabela, required this.raioGratuitoKm});

  final TabelaAbrangencia tabela;
  final int raioGratuitoKm;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final valores = [
      ('Até $raioGratuitoKm km', 'Incluído', 'Gratuito'),
      for (final faixa in tabela.faixas)
        (
          'Até ${faixa.ateKm} km',
          NumericInput.dinheiroCentavos(faixa.adicionalCentavos),
          NumericInput.dinheiroCentavos(faixa.mensalidadeCentavos),
        ),
    ];
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.15),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AdminPalette.surface),
          children: [
            for (final titulo in [
              'Cobertura',
              'Adicional mensal',
              'Total mensal'
            ])
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text(titulo,
                    style: texto.labelMedium?.copyWith(
                        color: AdminPalette.muted,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        for (final (cobertura, adicional, total) in valores)
          TableRow(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminPalette.border))),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                child: Text(cobertura, style: texto.bodyMedium),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                child: Text(adicional, style: texto.bodyMedium),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                child: Text(total,
                    style: texto.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.primary)),
              ),
            ],
          ),
      ],
    );
  }
}

class _PublicarTabelaDialog extends StatefulWidget {
  const _PublicarTabelaDialog({
    required this.dados,
    required this.base,
    required this.datasource,
  });

  final AbrangenciaAdmin dados;
  final TabelaAbrangencia? base;
  final AbrangenciaRemoteDatasource datasource;

  @override
  State<_PublicarTabelaDialog> createState() => _PublicarTabelaDialogState();
}

class _PublicarTabelaDialogState extends State<_PublicarTabelaDialog> {
  final _form = GlobalKey<FormState>();
  late final _valores = widget.base?.faixas
          .map(
              (faixa) => NumericInput.dinheiroCentavos(faixa.adicionalCentavos))
          .toList() ??
      <String>[''];
  late final _chaves = List.generate(_valores.length, (_) => UniqueKey());
  late DateTime _vigencia = switch (widget.base) {
    final TabelaAbrangencia base
        when base.vigencia.isAfter(widget.dados.hoje) =>
      base.vigencia,
    _ => widget.dados.hoje,
  };
  bool _publicando = false;
  String? _erro;
  String? _pedidoId;
  String? _ultimaTentativa;

  Future<void> _escolherData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _vigencia,
      firstDate: widget.dados.hoje,
      lastDate: DateTime(9999, 12, 31),
    );
    if (data != null && mounted) setState(() => _vigencia = data);
  }

  Future<void> _publicar() async {
    if (_publicando || !_form.currentState!.validate()) return;
    final valores = _valores
        .map((valor) => (NumericInput.parseMoeda(valor)! * 100).round())
        .toList(growable: false);
    final tentativa = '$_vigencia/${valores.join(',')}';
    if (_ultimaTentativa != tentativa) {
      _ultimaTentativa = tentativa;
      _pedidoId = const Uuid().v4();
    }
    setState(() {
      _publicando = true;
      _erro = null;
    });
    try {
      await widget.datasource.publicar(
        vigencia: _vigencia,
        valoresCentavos: valores,
        pedidoId: _pedidoId!,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseFunctionsException catch (erro) {
      if (mounted) {
        setState(
          () => _erro = erro.message ?? 'Não foi possível publicar a tabela.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível publicar a tabela.');
      }
    } finally {
      if (mounted) setState(() => _publicando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final datas = MaterialLocalizations.of(context);
    final dados = widget.dados;
    final texto = Theme.of(context).textTheme;
    final totais = <int?>[];
    int? acumulado = 0;
    for (final valor in _valores) {
      final reais = NumericInput.parseMoeda(valor);
      acumulado = reais == null || reais <= 0 || acumulado == null
          ? null
          : acumulado + (reais * 100).round();
      totais.add(acumulado);
    }
    return PopScope(
      canPop: !_publicando,
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Publicar tabela de abrangência'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        content: SizedBox(
          width: 560,
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Defina o adicional de cada faixa. O total mensal soma os '
                    'valores das faixas anteriores.',
                    style: texto.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _publicando ? null : _escolherData,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      'Vigência em ${datas.formatCompactDate(_vigencia)}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _vigencia == dados.hoje
                        ? 'Entra em vigor hoje, pelo horário de Brasília.'
                        : 'Entra em vigor na data escolhida, pelo horário de Brasília.',
                    style: texto.bodySmall?.copyWith(color: AdminPalette.muted),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AdminPalette.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Até ${dados.raioGratuitoKm} km • Gratuito',
                        style: texto.titleSmall?.copyWith(
                            color: AdminPalette.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _valores.length; i++)
                    Container(
                      key: _chaves[i],
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AdminPalette.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Acima de ${dados.raioGratuitoKm + dados.incrementoKm * i} até '
                            '${dados.raioGratuitoKm + dados.incrementoKm * (i + 1)} km',
                            style: texto.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: _valores[i],
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            enabled: !_publicando,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [NumericInput.moeda()],
                            decoration: InputDecoration(
                              labelText: 'Valor adicional mensal',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              hintText: r'R$ 0,00',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (valor) =>
                                setState(() => _valores[i] = valor),
                            validator: (texto) =>
                                (NumericInput.parseMoeda(texto) ?? 0) <= 0
                                    ? 'Informe um valor maior que zero.'
                                    : null,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            totais[i] == null
                                ? 'Preencha os valores até esta faixa para ver o total.'
                                : 'Total até ${dados.raioGratuitoKm + dados.incrementoKm * (i + 1)} km '
                                    '${NumericInput.dinheiroCentavos(totais[i]!)}/mês',
                            style: texto.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: totais[i] == null
                                  ? AdminPalette.muted
                                  : AdminPalette.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: _publicando
                            ? null
                            : () => setState(() {
                                  _valores.add('');
                                  _chaves.add(UniqueKey());
                                }),
                        icon: const Icon(Icons.add),
                        label: Text('Adicionar ${dados.incrementoKm} km'),
                      ),
                      TextButton(
                        onPressed: _publicando || _valores.length == 1
                            ? null
                            : () => setState(() {
                                  _valores.removeLast();
                                  _chaves.removeLast();
                                }),
                        child: const Text('Remover última faixa'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uma nova publicação para a mesma vigência substitui a anterior.',
                    style: texto.bodySmall?.copyWith(color: AdminPalette.muted),
                  ),
                  if (_erro case final String erro)
                    Semantics(
                      liveRegion: true,
                      child: Text(erro,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          )),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _publicando ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AdminPalette.primary,
              minimumSize: const Size(96, 48),
            ),
            onPressed: _publicando ? null : _publicar,
            child: Text(_publicando ? 'Publicando…' : 'Publicar'),
          ),
        ],
      ),
    );
  }
}
