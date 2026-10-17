# Campos numéricos — revisão de 16/10/2026

Alterações locais, sem deploy, migração de dados ou alteração de versão.

## Padrão de entrada

- Moeda: entrada em centavos, conforme o cadastro rápido indicado pelo usuário. Digitar `23` mostra `R$ 0,23`; digitar `3300` mostra `R$ 33,00`. O cursor acompanha a entrada à direita. O valor persistido continua em reais: `R$ 33,00` é salvo como o número 33.
- Decimais: entrada natural, com vírgula e até seis casas de precisão. Quantidades não recebem o deslocamento de centavos nem zeros automáticos durante a digitação. `33` continua sendo 33 e `0,000125` conserva sua precisão. Ponto decimal também é aceito e convertido.
- Inteiros: somente dígitos, conservando os limites de tamanho já definidos por campo.
- Colagem e edição: rejeição de letras, negativos, notação científica e separadores inválidos em moedas e quantidades. A máscara monetária segue a edição do pacote, com cursor à direita; quantidades conservam a seleção para editar a fração.
- Apagar um valor continua possível. Obrigatoriedade e limites de negócio continuam sendo verificados pelos formulários.
- CPF, CNPJ, CEP e telefone mantêm suas máscaras específicas; códigos de acesso preservam zeros à esquerda.

`NumericInput` concentra máscaras, apresentação e conversão. `FormMasks.dinheiro`, `FormValidators.parseDinheiro` e `Biblioteca.toDouble` foram integrados para evitar que um ponto decimal seja removido indiscriminadamente. Em moeda, `1.234` é reconhecido como milhar brasileiro; em quantidade, `0.125` continua sendo uma fração.

A regra de conversão acima se refere a valores já formatados para leitura/persistência. Durante a entrada monetária, os dígitos representam centavos: a sequência `1234` gera `R$ 12,34`.

## Referência e pacote

Foi inspecionado `D:/repository/flutter/pdv/cardapio_digital/lib/app/page/gestao/widgets/cadastro_rapido_bottom_sheet.dart`, incluindo `app_grade_input_row.dart` e `safe_money_masked_text_controller.dart`. A referência usa `flutter_masked_text2` com um controller que protege a leitura de campos sem dígitos.

No Faça Festa, a formatação monetária passou a ser delegada a `currency_text_input_formatter` 2.3.0, já disponível no projeto, com a mesma entrada em centavos. A máscara própria anterior de moeda foi retirada. O adaptador trata somente entradas inválidas, limites e os espaços/símbolos de valores carregados, pois o pacote rejeita espaços na edição. Não foi acrescentada dependência nem alterado o projeto de referência.

## Cobertura do levantamento

A busca de configurações de teclado numérico encontrou 62 ocorrências em 28 arquivos da apresentação. O total inclui componentes compartilhados e configurações de documentos/códigos, portanto não representa 62 campos novos ou 28 telas visitadas manualmente.

| Área | Campos revisados |
| --- | --- |
| Calculadora | Público, quantidade por pessoa, preço, limite financeiro, consumo real, rendimento, participação, embalagem, pesos, serviços, faixas da receita e administração de regras/itens |
| Cardápio | Quantidades compradas e disponíveis em estoque |
| Evento | Idade, contagens de convidados e custo estimado |
| Orçamento | Valor previsto, custo total, valor pago e estimativa de cotação |
| Fornecedor | Preço, promoção, proposta de orçamento, quantidade na cotação e raio de atendimento |
| Presentes | Valor sugerido, meta coletiva e valor no modal Pix |
| Administração | Ordem de categorias, regras de sugestões e custos/quantidades de referências de inspiração |
| Convidados | Número de mesa |
| Componentes compartilhados | Entrada numérica por tipo ou teclado, moedas e preservação das máscaras de identificação |

Também foram corrigidos os valores iniciais de edição e a validação numérica da regra administrativa: uma quantidade válida de `1` não pode ser rejeitada por uma regra de tamanho mínimo de título.

## Verificação

- Rodada do pacote: 111 testes de core, calculadora e cardápio aprovados. Análise estática do utilitário e dos testes de entrada sem problemas.
- Testes atualizados para o comportamento do pacote: entrada em centavos, backspace, exclusão total, zero inicial, símbolo com espaço inseparável, colagem e edição de valores já salvos. Quantidades têm testes separados de precisão e seleção.
- Testes do formatador: digitação, colagem, edição no meio do texto, exclusão de agrupamento, valores acima de mil, duas casas monetárias e precisão de porções.
- Conversão de valores brasileiros e de ponto decimal sem alteração de escala.
- Teste de tela do limite financeiro: abrir R$ 8.500,00, digitar a sequência `3300`, visualizar R$ 33,00 e receber o número 33 ao aplicar.
- Teste de disponibilidade verifica tanto o bloqueio pela máscara quanto a rejeição de um negativo inserido programaticamente no controller.
- Regressão de calculadora e cardápio, incluindo o fluxo de compras e edição de porções.
- A suíte completa executada nesta revisão teve 406 aprovações e uma falha em `test/features/comunidade/comunidade_controller_test.dart`, no teste `observes posts through the use case`. A falha se repetiu na verificação separada: o teste chama `onInit`, enquanto o controller existente inicia a escuta por `garantirEscuta` com autenticação. Esses arquivos não foram alterados nesta tarefa.

Não foi feita navegação manual por todas as telas em um aparelho físico. A cobertura combina levantamento do código, análise estática e testes automatizados.
