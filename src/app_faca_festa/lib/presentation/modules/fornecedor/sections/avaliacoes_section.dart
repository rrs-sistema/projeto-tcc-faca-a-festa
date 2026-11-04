import 'package:app_faca_festa/domain/entities/avaliacao.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/widgets/gestao_reputacao_painel.dart';

class AvaliacoesSection extends StatelessWidget {
  const AvaliacoesSection(
      {super.key,
      required this.fornecedorController,
      required this.avaliacaoController});
  final FornecedorController fornecedorController;
  final AvaliacaoServicoController avaliacaoController;
  @override
  Widget build(BuildContext context) => Obx(() {
        final f = fornecedorController.fornecedor.value;
        if (f == null) return const Text('Carregando fornecedor…');
        final legado = avaliacaoController.avaliacoesFornecedor
            .where((a) => a.id.contains('/') && !a.verificada)
            .toList();
        return Column(children: [
          GestaoReputacaoPainel(
              key: ValueKey(f.idFornecedor), idFornecedor: f.idFornecedor),
          if (legado.isNotEmpty)
            _HistoricoAnterior(
                key: ValueKey('legado-${f.idFornecedor}'), itens: legado),
        ]);
      });
}

class _HistoricoAnterior extends StatefulWidget {
  const _HistoricoAnterior({super.key, required this.itens});
  final List<Avaliacao> itens;
  @override
  State<_HistoricoAnterior> createState() => _HistoricoAnteriorState();
}

class _HistoricoAnteriorState extends State<_HistoricoAnterior> {
  int limite = 10;
  @override
  Widget build(BuildContext context) => ExpansionTile(
          title: const Text('Histórico anterior sem verificação'),
          subtitle: const Text(
              'Somente leitura; fora dos indicadores e da gestão de registros canônicos.'),
          children: [
            for (final a in widget.itens.take(limite))
              ListTile(
                  title: Text('${a.nota}/5 · histórico não verificado'),
                  subtitle: Text(a.comentario)),
            if (widget.itens.length > limite)
              TextButton(
                  onPressed: () => setState(() => limite += 10),
                  child: const Text('Mais comentários históricos')),
          ]);
}
