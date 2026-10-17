# Calculadora: correções e aceite operacional

Data: 16/10/2026. Complementa a auditoria `auditoria-inteligencia-calculadora-2026-10-16.md`, preservada como registro anterior às correções. Alterações locais, sem deploy, migração de produção ou modificação dos dados do evento real.

Atualização posterior: público por refeição, estoque central, grupos alimentares e critérios do histórico foram implementados em `calculadora-operacao-completa-2026-10-16.md`. Os limites descritos abaixo registram o estado desta primeira entrega.

## Correções da auditoria

| Lacuna reproduzida | Comportamento implementado |
| --- | --- |
| Embalagens arredondadas antes de descontar disponibilidade | A necessidade de consumo é armazenada separadamente. Primeiro desconta comprado/estoque; arredonda somente a compra restante. Necessidade de 1 kg, disponibilidade de 1 kg e pacote de 2 kg resultam em compra adicional zero. |
| Divisão entre principal e acompanhamento | Grupos com papéis incompatíveis ou participação inválida não reduzem as porções; exigem revisão. |
| Tela e IA com saldos diferentes | O contrato financeiro versão 2 usa orçamento existente mais compras restantes conhecidas. Preços, quantidades, consulta ou cobertura incompletos impedem concluir saldo disponível. Campos inválidos também impedem essa conclusão no backend. |
| Disponibilidade desconhecida tratada como cenário completo | As pendências da lista de compras participam da completude do financeiro e do contexto enviado à IA. |
| Buffet do almoço cobrindo item homônimo do jantar | Cobertura vinculada a evento, cardápio e item, preservando a identidade e unidade. A conversão para orçamento também usa esse escopo. |
| Histórico ignorando porções dos outros alimentos | O contexto de comparação inclui porção, serviços, composição, rendimento e estado/unidade de compra dos demais alimentos. Alterações invalidam a comparação automática. |
| Percentuais de risco/conforto sem calibração | Removida a apresentação desses percentuais no histórico. O callable ativo zera os campos legados; o prompt não solicita probabilidades de suficiência. |

## Integração operacional

- **Festa inteira:** consolidação de compras e projeção financeira dos cardápios ativos, com identificação da refeição na lista. Refeições sem regra, vazias ou ainda não carregadas mantêm o resultado parcial. A sugestão selecionada e os cenários continuam sendo da refeição em edição; a avaliação financeira considera as demais refeições.
- **Mesmas premissas de público:** a consolidação informa que utiliza o público selecionado nas refeições. Serviços e ajustes próprios das regras são mantidos. Não foi implementado um cadastro independente de convidados presentes em cada refeição.
- **Receitas privadas:** reutilização de porção e rendimento salvos nas simulações do próprio organizador. Preço e vínculos antigos não são reaproveitados; o usuário revisa a regra antes de usar.
- **Consumo observado:** adoção de referência exige pelo menos três eventos comparáveis e ausência de falta registrada. A tela mostra a faixa observada. Esse mínimo é uma proteção operacional, não uma validação estatística da suficiência.
- **IA:** cache de sessão de cinco minutos, deduplicação de chamadas simultâneas, espera de 1,5 segundo após alterações e limite por usuário no backend (60 solicitações por cinco minutos, intervalo mínimo de um segundo). Falha da IA não impede calcular as quantidades.
- **Segurança:** fornecedor não pode alterar os vínculos de cobertura do orçamento. A coleção interna de controle de chamadas não fica acessível ao cliente.
- **Histórico:** snapshot preserva refeições, regras, disponibilidade e compromissos do cenário. Simulações anteriores à versão 5 do motor exigem atualização com os dados atuais antes de nova análise da IA.

## Uso no evento real

1. Selecione a refeição e use **Revisar meu cardápio**. Confira público, duração e serviços efetivamente previstos.
2. Confira papel do alimento, porção, estado cru/seco/pronto e rendimento. Divisão de acompanhamentos só deve ser ativada quando os itens realmente compartilham a mesma porção.
3. Informe disponibilidade física e preço na unidade correta. Confirmação de item e pagamento de serviço não significam alimento disponível.
4. Revise a cobertura dos serviços por refeição. Informe somente os itens integralmente incluídos no serviço.
5. Consulte **Ver compras da festa inteira**. Não declare o mesmo estoque disponível em duas refeições; a aplicação ainda não mantém um almoxarifado central com reservas automáticas.
6. Resolva as pendências antes de interpretar saldo como completo. Revise e aplique as sugestões ao cardápio; salvar uma simulação não altera sozinho o planejamento da refeição.
7. Depois da festa, registre consumo, sobra e falta para construir referências comparáveis.

## Compatibilidade de dados anteriores

- Coberturas antigas por nome/unidade/público não são automaticamente consideradas prova de cobertura de uma refeição: precisam ser confirmadas no novo editor.
- Resultados antigos com embalagem e sem necessidade líquida registrada pedem recálculo antes de recomendar compra.
- Histórico com contexto anterior não participa silenciosamente da adoção de porções comparáveis.
- Orçamentos antigos sem vínculo de refeição não são associados automaticamente a um item novo homônimo; é necessária a revisão explícita da cobertura.
- Nenhum desses ajustes reescreve dados publicados automaticamente.

## Verificação

- Suíte Flutter completa aprovada: **425 testes**, incluindo a proteção adicional do histórico legado. Registro em `.dart_tool/cantos-suite-completa-final.log`.
- Jornada de interface exercita cálculo, compras da festa inteira, reutilização de receita e gravação de cobertura com escopo.
- Regressões formais cobrem os defeitos da auditoria, roundtrip dos campos novos, financeiro de almoço/jantar, contexto histórico e cache de IA.
- Análise estática das áreas alteradas aprovada, sem problemas.
- `npm run check:calculadora`: compilação TypeScript sem emissão e verificações de financeiro, callable, autorização, fallback e limite de chamadas.
- Regras Firestore verificadas no emulador, incluindo cobertura, consulta privada de receitas e bloqueio do controle interno de chamadas. Registro: `.dart_tool/cantos-firestore.log`.
- Não foram feitas chamadas ao provedor externo de IA, navegação integral em aparelho físico ou validação dos dados reais de produção. Os testes usam substitutos dos serviços externos.

## Disponibilidade e limites

Não houve deploy. Flutter, functions, regras e índice novos permanecem locais. O aplicativo já publicado não recebe essas alterações até a distribuição da aplicação e publicação coordenada do backend, regras e índice. A consulta de receitas privadas inclui índice composto por usuário e data de atualização.

O código trata as inconsistências verificadas e explicita dados desconhecidos. Ainda é necessário conferir as porções e os dados do evento: não existem medições suficientes para prometer que as quantidades alimentarão todos os convidados. Receitas, rendimento e consumo observado melhoram a base; IA generativa não substitui essa validação.

O workspace já continha alterações extensas. Além das mudanças funcionais descritas, uma execução ampla do formatador normalizou a formatação de arquivos em `lib/data`; esses arquivos não receberam mudanças semânticas intencionais nesta implementação. Não foram revertidas alterações preexistentes.
