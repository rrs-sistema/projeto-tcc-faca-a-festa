# Indicador do catálogo — análise e correção

## Problemas encontrados

- O selo de 92% usava 12 verificações do perfil, enquanto as sugestões usavam outra regra comercial.
- A lista detalhada vazia aprovava automaticamente foto e preço. Bastava um serviço com foto/preço para aprovar esses itens quando existiam várias ofertas.
- A regra comercial somava pesos de 110 pontos e limitava o resultado a 100. Assim, uma pendência com peso 10 podia coexistir com 100%.
- A descrição comercial só precisava estar preenchida no selo, enquanto as sugestões exigiam 80 caracteres.
- O catálogo detalhado não era garantido na primeira atualização do fornecedor. Lista não consultada podia ser interpretada como catálogo vazio.
- A interface exibia apenas parte das sugestões e usava ícones de conclusão para tarefas pendentes.

## Regra única após a correção

A avaliação é calculada nos dados atuais do fornecedor, compartilhada entre o painel e as sugestões comerciais. O percentual é a soma dos pontos obtidos dividida pela soma real dos pesos, multiplicada por 100. Os pesos e a meta de variedade já existentes foram preservados.

| Critério | Peso |
| --- | ---: |
| Banner do fornecedor | 10 |
| Descrição comercial com ao menos 80 caracteres | 10 |
| Categorias de atendimento | 10 |
| Tipos de evento atendidos | 10 |
| Faixa de preço válida e maior que zero | 10 |
| Pelo menos 3 ofertas ativas (1–2 ofertas recebem 8 pontos) | 15 |
| Todas as ofertas ativas com foto | 10 |
| Todas as ofertas ativas com descrição | 10 |
| Todas as ofertas ativas com preço válido, incluindo promoção | 15 |
| Todas as ofertas ativas com unidade de medida | 10 |
| **Total** | **110** |

Ofertas inativas e de outros fornecedores não entram no cálculo. Catálogo vazio não pontua nos cinco critérios de ofertas. Sem os detalhes consultados com sucesso, a interface mostra dados não disponíveis em vez de percentual ou contagens presumidas. A escuta inicial carrega os detalhes e descarta respostas de consultas canceladas.

O selo e o resumo identificam a preparação do catálogo, abrangendo perfil comercial e ofertas. A lista mostra todas as pendências, onde corrigi-las, os serviços envolvidos e a contribuição restante de cada critério. O detalhamento do cálculo exibe também os critérios atendidos. Percentuais são arredondados somente na apresentação.

Os 92% da captura anterior não comprovam que faltava exatamente um cadastro: a ausência de carga dos detalhes também podia causar os zeros. A correção evita essa inferência.

## Verificação

Testes cobrem catálogo vazio, 100% sem pendências, limite de 79/80 caracteres, pesos normalizados, oferta parcial, serviços inativos/alheios, preços inválidos/promocionais, falha e cancelamento de consulta, carga inicial e transição visual de desconhecido para dados avaliados em celular e desktop.
