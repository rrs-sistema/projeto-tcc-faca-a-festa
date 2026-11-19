import 'package:app_faca_festa/presentation/widgets/festa_scroll_area.dart';
import 'package:flutter/material.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/data/datasources/remote/abrangencia_remote_datasource.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/condicoes_abrangencia_page.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

class AbrangenciaFornecedorPage extends StatefulWidget {
  const AbrangenciaFornecedorPage({super.key, this.datasource});

  final AbrangenciaRemoteDatasource? datasource;

  @override
  State<AbrangenciaFornecedorPage> createState() =>
      _AbrangenciaFornecedorPageState();
}

class _AbrangenciaFornecedorPageState extends State<AbrangenciaFornecedorPage> {
  late final _datasource = widget.datasource ?? AbrangenciaRemoteDatasource();
  late var _consulta = _datasource.consultarFornecedor();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Scaffold(
      appBar: const FestaAppBar(titulo: 'Território de atendimento'),
      body: FestaContent(
          child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: FestaScrollArea(
              color: Theme.of(context).colorScheme.primary,
              maxWidth: double.infinity,
              child: ListView(
                primary: true,
                padding: const EdgeInsets.all(24),
                children: [
                  Text('Premium de Abrangência', style: tema.headlineSmall),
                  const SizedBox(height: 8),
                  const Text(CondicoesAbrangenciaPage.resumo),
                  const SizedBox(height: 8),
                  const Text('A contratação ainda não está disponível.'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => CondicoesAbrangenciaPage.abrir(context),
                      child: const Text('Ver condições de abrangência'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<AbrangenciaFornecedor>(
                    future: _consulta,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const LinearProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                                'Não foi possível consultar sua cobertura.'),
                            TextButton(
                              onPressed: () => setState(() {
                                _consulta = _datasource.consultarFornecedor();
                              }),
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        );
                      }
                      final dados = snapshot.requireData;
                      final tabela = dados.tabela;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cobertura cadastrada', style: tema.titleMedium),
                          if (dados.territorios.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child:
                                  Text('Nenhum território ativo cadastrado.'),
                            ),
                          for (final territorio in dados.territorios)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.location_on_outlined),
                              title: Text(switch (territorio) {
                                CoberturaCadastrada(tipo: 'regiao') =>
                                  'Região desenhada',
                                CoberturaCadastrada(raioKm: final num raio) =>
                                  '${NumericInput.quantidade(raio)} km de raio',
                                _ => 'Raio a definir',
                              }),
                              subtitle: territorio.descricao.isEmpty
                                  ? null
                                  : Text(territorio.descricao),
                            ),
                          const Divider(height: 32),
                          Text('Tabela mensal de referência',
                              style: tema.titleMedium),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Até ${dados.raioGratuitoKm} km'),
                            trailing: const Text('Gratuito'),
                          ),
                          if (tabela == null)
                            const Text(
                                'As faixas Premium ainda não foram publicadas.'),
                          if (tabela != null) ...[
                            Text(
                              'Vigência desde ${MaterialLocalizations.of(context).formatCompactDate(tabela.vigencia)}',
                            ),
                            for (final faixa in tabela.faixas)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Até ${faixa.ateKm} km'),
                                trailing: Text(
                                  NumericInput.dinheiroCentavos(
                                      faixa.mensalidadeCentavos),
                                ),
                              ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              )),
        ),
      )),
    );
  }
}
