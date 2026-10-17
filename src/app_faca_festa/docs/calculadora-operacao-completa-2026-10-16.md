# Calculadora: público, estoque, alimentação e validação

Data: 16/10/2026. Esta entrega complementa `calculadora-correcao-ponta-a-ponta-2026-10-16.md` e resolve as pendências técnicas listadas após aquela entrega. Sem publicação em produção.

## O que mudou

| Ponto | Funcionamento implementado |
| --- | --- |
| Público por refeição | Cada cardápio pode herdar a base de participantes da calculadora ou ter quantidades próprias de adultos, crianças e bebês. A base da festa é preservada. Quantidades, fórmulas, compras, cenários e consolidação financeira usam o público correspondente. |
| Estoque central | Lotes identificados por nome, unidade e estado possuem um único total e reservas por cardápio/item. Escritas usam transação Firestore e revisão do documento. Não é possível reservar acima do saldo, reduzir o lote abaixo do reservado ou alterar sua identidade mantendo reservas. Zero libera uma reserva, inclusive de item removido. |
| Grupos alimentares | Participantes são divididos em grupos sem sobreposição declarada, com combinações de necessidades (por exemplo, vegetariano e sem leite). Contagens não podem superar o público. Ingredientes, preparo e contato cruzado são conferidos explicitamente pelo organizador. Nenhuma adequação é inferida pelo nome. |
| Consumo por grupo | Cada item pode atender a toda a refeição, somente aos grupos selecionados ou às pessoas fora dos grupos. A quantidade é calculada para esse público; uma opção exclusiva não é automaticamente multiplicada pela festa inteira. Alternativas com públicos distintos não dividem porções. |
| Destinação de porções | O organizador destina parte do total calculado a cada grupo, na unidade e estado de compra indicados. A destinação não é somada novamente à compra. O motor verifica falta de opção, porção destinada, faixas de público e excesso de destinação. Alterar a regra exige conferir novamente a destinação. |
| Histórico | Data do consumo separada da data de registro; janela operacional de 365 dias; pelo menos três eventos distintos comparáveis; registros de falta impedem adoção. Valores atípicos são sinalizados, sem correção automática. |
| Avaliação temporal | Cada medição posterior é comparada com uma mediana formada somente por eventos anteriores. A tela mostra número de avaliações, faltas e erro absoluto mediano observado. Isso não é um percentual de confiança ou uma promessa de suficiência. |
| Referências | Catálogo contextual ampliado, com fonte, versão, data de conferência e condições de uso exibidas antes da escolha. Estado pronto não é tratado como peso cru. Variedades não recebem cada uma a porção do conjunto. |
| IA e fallback | Recebem os públicos e pendências operacionais. O servidor preserva as pendências de alimentação na resposta, inclusive quando a IA está indisponível. Não declara os grupos atendidos enquanto houver pendências conhecidas. |

## Onde usar

No passo de sugestões, junto ao seletor de cardápio:

- **Público e alimentação desta refeição:** ajuste as presenças, o tipo de serviço (refeição principal ou lanche/coquetel), os grupos, suas porções e quem consome cada item.
- **Estoque e reservas da festa:** cadastre os lotes e destine quantidades aos itens de cada refeição. O saldo livre aparece junto ao total e às reservas existentes.
- **Ver compras da festa inteira:** confira os itens por refeição e as pendências alimentares antes de concluir compras.

Os recursos avançados de grupos e consumo por item ficam recolhidos até serem necessários. Contagens aceitam inteiros; quantidades usam a formatação decimal comum do aplicativo. Botões de confirmação ficam fora da área rolável dos formulários.

Comprado permanece sendo uma declaração de compra para o item daquela refeição. Não registre o mesmo alimento em Comprado e também como lote de estoque. O aplicativo não identifica automaticamente que duas declarações manuais se referem à mesma compra física.

## Compatibilidade e concorrência

- Estoque local antigo não é descontado silenciosamente pela calculadora. Cadastre o lote, reserve-o e salve a disponibilidade com o estoque local zerado. O editor direciona novas reservas ao controle central.
- Uma edição aberta antes de outra alteração não sobrescreve silenciosamente o novo estado. O formulário pede reabertura e conferência.
- Falha de consulta de público/estoque mantém o resumo parcial; não equivale a estoque zero confirmado.
- Uma reserva com nome, público, unidade ou estado incompatível exige conferência. Excluir um item não libera sua reserva automaticamente; o organizador pode liberar o vínculo no estoque central.
- Simulações preservam a configuração operacional e a base da festa separadamente. Versões anteriores ao motor 6 precisam ser atualizadas antes de uma nova análise da IA.
- Reutilizar receitas não copia público de grupos, reservas, vínculos antigos ou preços. Consumo observado usa participantes reais, sem reaplicar o público planejado do grupo.
- Registros sem data do consumo permanecem preservados, mas não calibram uma nova porção. Contextos anteriores não são considerados equivalentes silenciosamente.

## Critérios verificáveis do histórico

Os critérios são proteções operacionais versionadas, não uma calibração estatística comprovada. A janela é de 365 dias. A mediana só pode ser adotada com três eventos comparáveis sem falta. Com cinco ou mais amostras, desvios maiores que o máximo entre três desvios absolutos medianos escalados e metade da mediana são sinalizados para revisão. Não há exclusão silenciosa desses valores.

Na avaliação temporal, uma previsão só utiliza datas de consumo estritamente anteriores ao evento avaliado e precisa ter pelo menos três medições anteriores sem falta. Uma falta é registrada separadamente: o que foi disponibilizado num evento com falta não revela quanto as pessoas teriam consumido se houvesse mais comida.

## Fontes das referências

As referências continuam sendo pontos de partida escolhidos pelo organizador. Não são aplicadas automaticamente por semelhança vaga do nome.

- [SENAR-PR, A arte do churrasco, 2025, p. 11](https://www.sistemafaep.org.br/wp-content/uploads/2026/01/PR.0391-A-arte-do-churrasco-basico_web.pdf#page=13): total de carnes já assadas por adulto. Rendimento cru/pronto da receita deve ser medido; não foi presumido a partir das perdas exemplificadas no material.
- [Assaí, cálculo para churrasco](https://www.assai.com.br/blog/churrasco-no-assai-atacadista): água e refrigerante em contextos de churrasco. A fonte não define um limite numérico de horas para curta/média/longa duração; a seleção é explícita.
- [Padaria Brasileira, cardápio de encomendas, p. 11](https://padariabrasileira.com.br/wp-content/uploads/2023/11/V7_cardapio_encomenda_19x22cm_FINAL.pdf#page=11): referências de salgados por duração e combinação do serviço, frios, bolo e docinhos. Substitui a oferta ativa anterior de docinhos baseada em um PDF cuja consulta integral ficou indisponível nesta revisão; snapshots antigos não foram reescritos.
- [Cristal Alimentos](https://cristalalimentos.com.br/quanto-preparar-como-calcular-arroz-feijao-e-macarrao-sem-desperdicio/): arroz e feijão crus, massa seca conforme papel. Conferida novamente nesta entrega.
- [Barilla](https://www.barilla.com/pt-br/ajuda-com/novidades/guia-medidor-de-massa): porção de massa seca. Conferida novamente nesta entrega.

## Verificação e alcance

Suíte completa: **441 testes aprovados**, registrada em `.dart_tool/calculadora-operacao-suite-aceite-final.log`. Inclui regressões do motor, persistência de snapshots, público por refeição, destino exclusivo por grupo, concorrência por revisão, saldo compartilhado de lote, histórico temporal, datas ausentes e jornada de cadastro/reserva de estoque. Há testes de interface para salvar grupos alimentares e para tela pequena com texto ampliado.

As regras foram executadas no emulador Firestore: o organizador acessa sua configuração; outro organizador, fornecedor e usuário sem autenticação não acessam o documento operacional. O backend verifica financeiro, autorização, fallback, preservação de pendências alimentares e limitação de chamadas.

Foi criado um alvo Android exclusivo de QA, `tool/calculadora_qa_aparelho.dart`, com dados fictícios em memória e sem inicialização Firebase. Seu pacote é `com.rrs.system.technology.facafesta.calculadoraqa`, diferente do aplicativo principal. Para compilar, use `flutter build apk --debug --dart-define=CALCULADORA_QA=true -t tool/calculadora_qa_aparelho.dart`. O alvo de QA bloqueia execução sem a opção de QA e bloqueia compilação de release. Confira o identificador do APK antes de instalar; não use o APK de QA para distribuir o aplicativo.

No aparelho SM G990E (Android 16), o fluxo percorreu os três passos. O almoço foi alterado de 21 adultos e 5 crianças para 12 adultos e 3 crianças: o diagnóstico exibiu 15 pessoas e a referência de churrasco passou de 10,56 kg para 6,08 kg. O botão de salvar permaneceu acessível com o teclado aberto. Foram abertos os controles de grupos e de estoque. A conferência identificou contraste insuficiente nos rótulos de grupos; as duas listas de seleção receberam cores explícitas de texto, fundo e seleção, com regressão incluída no teste de interface. Os 16 testes operacionais passaram novamente após essa alteração, e a análise estática dos arquivos revisados terminou sem problemas. O APK de QA foi recompilado e instalado novamente; o contraste corrigido foi confirmado no aparelho em `.dart_tool/qa-aparelho/16-final-contraste.png`. Não foram encontradas exceções Flutter no log do processo de QA durante o fluxo de alteração de público.

Teste em aparelho não equivale a teste dos dados reais de produção. Não houve autenticação na conta real do organizador, alteração do evento real ou chamada paga ao provedor externo de IA nesta entrega. A validação empírica de porções depende de medições reais dos eventos; o código agora registra, filtra e avalia essas medições sem fabricar uma conclusão antecipada.

Não houve deploy. O novo documento privado `calculadora_operacao/{idEvento}` exige a publicação coordenada das regras e do aplicativo quando o organizador decidir disponibilizar a versão. A instalação isolada de QA não atualiza o aplicativo publicado.

## Atualização de infraestrutura após autorização

Em 16/10/2026, o usuário autorizou a publicação da infraestrutura, mantendo o app sem distribuição. Regras Firestore e função da calculadora foram publicadas, o índice de receitas ficou pronto, e a base do evento real foi conferida e atualizada conforme a escolha de 37 participantes. O relato anterior de ausência de deploy descreve a etapa inicial. Consulte [o registro de infraestrutura e pendências do evento](calculadora-infraestrutura-2026-10-16.md) para o estado atual e os limites da verificação.
