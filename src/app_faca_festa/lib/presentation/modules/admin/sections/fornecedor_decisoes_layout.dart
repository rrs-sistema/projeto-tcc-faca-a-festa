part of '../pages/fornecedor_decisoes_page.dart';

class _CabecalhoFornecedor extends StatelessWidget {
  const _CabecalhoFornecedor({
    required this.trilha,
    required this.titulo,
    required this.descricao,
    required this.icone,
    this.acao,
  });

  final String trilha, titulo, descricao;
  final IconData icone;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AdminPalette.appBarGradient),
        child: Stack(
          children: [
            const Positioned(
              right: -60,
              top: -156,
              child: ExcludeSemantics(
                child: _ContornoCabecalho(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(builder: (context, constraints) {
                final ladoALado = acao != null && constraints.maxWidth >= 730;
                final identidade = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(icone, size: 17, color: const Color(0xFFA7F3D0)),
                        Text(trilha,
                            style: const TextStyle(
                              color: Color(0xFFD1FAE5),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            )),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      header: true,
                      child: Text(titulo,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: constraints.maxWidth >= 730 ? 32 : 25,
                            height: 1.18,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 630),
                      child: Text(descricao,
                          style: const TextStyle(
                            color: Color(0xFFE2F5F1),
                            fontSize: 14,
                            height: 1.45,
                          )),
                    ),
                  ],
                );
                if (ladoALado) {
                  return Row(children: [
                    Expanded(child: identidade),
                    const SizedBox(width: 24),
                    acao!,
                  ]);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    identidade,
                    if (acao != null) ...[const SizedBox(height: 18), acao!],
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContornoCabecalho extends StatelessWidget {
  const _ContornoCabecalho();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 390,
        height: 390,
        child: Stack(alignment: Alignment.center, children: [
          for (final diametro in [220.0, 300.0, 390.0])
            Container(
              width: diametro,
              height: diametro,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x24FFFFFF)),
              ),
            ),
        ]),
      );
}

class _PainelFornecedor extends StatelessWidget {
  const _PainelFornecedor({
    required this.titulo,
    required this.icone,
    required this.filhos,
    this.descricao,
    this.cor = AdminPalette.primary,
  });
  final String titulo;
  final String? descricao;
  final IconData icone;
  final Color cor;
  final List<Widget> filhos;

  @override
  Widget build(BuildContext context) => AdminCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminLeadingMark(icon: icone, color: cor, size: 38),
                const SizedBox(width: 11),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                        header: true,
                        child: Text(titulo,
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: AdminPalette.ink,
                            ))),
                    if (descricao != null) ...[
                      const SizedBox(height: 3),
                      _NotaFornecedor(descricao!),
                    ],
                  ],
                )),
              ],
            ),
            for (final filho in filhos)
              Padding(padding: const EdgeInsets.only(top: 12), child: filho),
          ],
        ),
      );
}

class _NotaFornecedor extends StatelessWidget {
  const _NotaFornecedor(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Text(texto,
      style: const TextStyle(
        color: AdminPalette.muted,
        fontSize: 13,
        height: 1.45,
      ));
}

class _SituacaoFornecedor extends StatelessWidget {
  const _SituacaoFornecedor(this.texto,
      {this.cor = AdminPalette.muted, this.icone});
  final String texto;
  final Color cor;
  final IconData? icone;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Wrap(
          spacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (icone != null) Icon(icone, size: 14, color: cor),
            Text(texto,
                style: TextStyle(
                    color: cor, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _IndicadorFornecedor {
  const _IndicadorFornecedor(
    this.rotulo,
    this.valor,
    this.icone, {
    this.cor = AdminPalette.primary,
    this.detalhe,
  });
  final String rotulo;
  final Object? valor;
  final IconData icone;
  final Color cor;
  final String? detalhe;
}

Widget _indicadores(List<_IndicadorFornecedor> itens,
        {int colunasMaximas = 4}) =>
    LayoutBuilder(builder: (context, constraints) {
      const intervalo = 12.0;
      final escala = MediaQuery.textScalerOf(context).scale(1);
      final larguraMinima = escala > 1.25 ? 230 : 140;
      final colunas =
          ((constraints.maxWidth + intervalo) / (larguraMinima + intervalo))
              .floor()
              .clamp(1, colunasMaximas);
      final largura =
          (constraints.maxWidth - (colunas - 1) * intervalo) / colunas;
      return Column(
        spacing: intervalo,
        children: [
          for (var inicio = 0; inicio < itens.length; inicio += colunas)
            IntrinsicHeight(
              child: Row(
                spacing: intervalo,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in itens.skip(inicio).take(colunas))
                    SizedBox(
                      width: largura,
                      child: _CartaoIndicador(item,
                          compacto: constraints.maxWidth < 600),
                    ),
                ],
              ),
            ),
        ],
      );
    });

class _CartaoIndicador extends StatelessWidget {
  const _CartaoIndicador(this.item, {required this.compacto});
  final _IndicadorFornecedor item;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final valor = Text(_texto(item.valor),
        style: TextStyle(
          color: item.cor,
          fontSize: 23,
          height: 1.15,
          fontWeight: FontWeight.w800,
        ));
    final marca = AdminLeadingMark(icon: item.icone, color: item.cor, size: 30);
    return AdminCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (compacto)
          Row(spacing: 8, children: [marca, Expanded(child: valor)])
        else ...[marca, const SizedBox(height: 8), valor],
        const SizedBox(height: 5),
        Text(item.rotulo,
            style: const TextStyle(
              color: AdminPalette.ink,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            )),
        if (item.detalhe != null) ...[
          const SizedBox(height: 3),
          _NotaFornecedor(item.detalhe!),
        ],
      ]),
    );
  }
}

class _DistribuicaoAvaliacoes extends StatelessWidget {
  const _DistribuicaoAvaliacoes({required this.notas});
  final List<num> notas;

  @override
  Widget build(BuildContext context) {
    final total = notas.fold<num>(0, (soma, n) => soma + n);
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          const Text('Distribuição das notas verificadas',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AdminPalette.ink,
              )),
          for (var i = notas.length - 1; i >= 0; i--)
            Semantics(
              label: '${i + 1} estrelas, ${notas[i]} avaliações',
              excludeSemantics: true,
              child: Row(spacing: 8, children: [
                Text('${i + 1} ★',
                    style: const TextStyle(color: AdminPalette.ink)),
                Expanded(
                    child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total == 0
                        ? 0
                        : (notas[i] / total).clamp(0.0, 1.0).toDouble(),
                    minHeight: 7,
                    backgroundColor: AdminPalette.border,
                    color: AdminPalette.primary,
                  ),
                )),
                _NotaFornecedor('${notas[i]}'),
              ]),
            ),
        ]);
  }
}

Widget _colunasFornecedor(Widget principal, List<Widget> lateral) =>
    LayoutBuilder(builder: (context, constraints) {
      final complementos = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: lateral);
      if (constraints.maxWidth < 920 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.4) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [principal, complementos]);
      }
      return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 18,
          children: [
            Expanded(flex: 8, child: principal),
            Expanded(flex: 5, child: complementos),
          ]);
    });

Widget _estadoVazio(String titulo, String descricao, IconData icone) =>
    DecoratedBox(
      decoration: BoxDecoration(
        color: AdminPalette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdminLeadingMark(icon: icone, color: AdminPalette.muted, size: 32),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AdminPalette.ink)),
                const SizedBox(height: 3),
                _NotaFornecedor(descricao),
              ])),
        ]),
      ),
    );

Widget _filtro(String titulo, String valor, String atual,
        ValueChanged<String> selecionar,
        {IconData? icone}) =>
    ChoiceChip(
      avatar: icone == null || valor == atual
          ? null
          : Icon(icone, size: 16, color: AdminPalette.primary),
      label: Text(titulo),
      selected: valor == atual,
      selectedColor: const Color(0xFFDCF4EF),
      backgroundColor: Colors.white,
      checkmarkColor: AdminPalette.primary,
      side: BorderSide(
          color:
              valor == atual ? const Color(0xFF9ED9CD) : AdminPalette.border),
      labelStyle: TextStyle(
        color: valor == atual ? AdminPalette.dark : AdminPalette.ink,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      onSelected: (_) => selecionar(valor),
    );
