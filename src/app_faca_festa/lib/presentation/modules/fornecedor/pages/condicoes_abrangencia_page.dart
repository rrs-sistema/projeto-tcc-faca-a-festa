import 'package:flutter/material.dart';

import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

class CondicoesAbrangenciaPage extends StatelessWidget {
  const CondicoesAbrangenciaPage({super.key});

  static const resumo =
      'A cobertura gratuita é de até 20 km a partir do endereço de atendimento '
      'cadastrado. O Premium de Abrangência amplia esse limite em faixas de '
      '5 km, com mensalidade separada das comissões sobre serviços prestados.';

  static Future<void> abrir(BuildContext context) =>
      Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => const CondicoesAbrangenciaPage(),
      ));

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    const condicoes = [
      (
        'Cobertura gratuita e ampliação',
        '$resumo A distância é medida em linha reta. A mesma distância máxima '
            'se aplica às áreas desenhadas no mapa.',
      ),
      (
        'Preços e renovação',
        'O valor mensal soma as faixas contratadas acima de 20 km. O fornecedor '
            'vê o total e a data da próxima cobrança antes de confirmar. '
            'O preço do ciclo já pago é preservado, e a plataforma avisa '
            'antes de aplicar reajustes na renovação.',
      ),
      (
        'Contratação e aumento',
        'O fornecedor pode solicitar a ampliação quando quiser. O administrador '
            'também pode iniciar uma alteração em nome dele. Toda nova cobrança '
            'ou aumento de valor depende do aceite do fornecedor. Se a ampliação '
            'ocorrer durante o ciclo, a diferença é proporcional ao tempo '
            'restante. O novo limite é liberado após a confirmação do pagamento.',
      ),
      (
        'Redução, cancelamento e pagamento pendente',
        'O fornecedor pode reduzir o raio em uso imediatamente. A redução da '
            'assinatura passa a valer na próxima renovação. Ao voltar ao plano '
            'gratuito, o raio em uso fica limitado a 20 km e a mensalidade deixa '
            'de ser cobrada no próximo ciclo. Se a renovação ficar pendente, a '
            'cobertura paga termina ao fim do período confirmado.',
      ),
      (
        'Eventos já contratados',
        'As mudanças de cobertura se aplicam a novas oportunidades. O '
            'atendimento de eventos já contratados segue o que foi combinado.',
      ),
      (
        'Entrada em vigor',
        'A contratação será disponibilizada junto à ativação do Premium de '
            'Abrangência. Fornecedores que já atendem além de 20 km serão '
            'avisados antes da mudança, com a data de aplicação do limite '
            'e as opções disponíveis. A cobrança começa após a adesão.',
      ),
    ];

    return Scaffold(
      appBar: const FestaAppBar(titulo: 'Condições de abrangência'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Condições de Abrangência do Fornecedor',
                  style: texto.headlineSmall),
              const SizedBox(height: 8),
              Text('Versão 1', style: texto.bodySmall),
              for (final (titulo, corpo) in condicoes) ...[
                const SizedBox(height: 24),
                Text(titulo, style: texto.titleMedium),
                const SizedBox(height: 6),
                Text(corpo, style: texto.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
