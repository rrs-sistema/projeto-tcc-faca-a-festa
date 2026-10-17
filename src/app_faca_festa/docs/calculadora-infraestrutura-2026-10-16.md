# Infraestrutura da calculadora — 16/10/2026

Autorização: publicar regras e concluir a preparação restante, sem publicar o aplicativo.
Projeto Firebase confirmado: `faca-a-festa`.

## Regras Firestore

Publicadas e conferidas pela API de releases. O conteúdo ativo corresponde integralmente ao arquivo local validado.

- Ruleset: `projects/faca-a-festa/rulesets/4126a52e-cb11-4381-9904-07d4450ede52`.
- Atualização: `2026-10-16T19:41:05.579420Z` (16:41 em São Paulo).
- SHA-256: `eafb3c9ae1e84bc5883d115a21a47d816a0ce42402c5ebb65ecc28bf9adc48ad`.
- A diferença em relação à produção anterior compreendeu o acesso privado a `calculadora_operacao/{idEvento}` e a proteção da cobertura/conferência financeira nos orçamentos.
- As alterações de tarefas e de privacidade de simulações já estavam na versão anterior em produção; não constituíram mudanças adicionais neste deploy.
- Testes de regras da calculadora, tarefas e auditoria passaram no emulador.
- Cópia das regras anteriores e metadados do release preservados em `.dart_tool/deploy-calculadora/`.

## Backend e índices

Deploy concluído da função `analisarCalculadoraFestaIA`, região `southamerica-east1`, estado `ACTIVE`, atualização confirmada pela API em `2026-10-16T19:44:51.294402426Z`. Não inclui outras funções, Hosting, Storage nem distribuição Android/desktop.

O índice `calculadora_festa`: `id_usuario ASCENDING`, `data_atualizacao DESCENDING` foi criado pela API de índices e atingiu o estado `READY`, sem excluir nem alterar índices de outras áreas. Identificador: `CICAgPiftYMK`. O índice de histórico por `consumo_registrado_em` já estava pronto.

## Verificações reais e limites

Acesso anônimo à função retornou HTTP 401/UNAUTHENTICATED e ao documento operacional retornou HTTP 403/PERMISSION_DENIED. As verificações não gravaram documentos nem chamaram o provedor de IA.

A conta Firebase CLI administra a infraestrutura; ela não é uma sessão do organizador dentro do aplicativo. Não houve impersonação de usuário nem extração de credenciais do aparelho. O evento foi identificado pelo usuário e sua configuração foi conferida administrativamente pela API. Isso não constitui navegação autenticada de ponta a ponta na conta do organizador com a nova versão do app. A calibração empírica requer presenças reais, quantidades preparadas, sobras e faltas; esses dados não serão inventados nem gravados como se tivessem sido observados.

O aplicativo publicado permanece na versão anterior. O QA isolado continua com dados fictícios e não constitui validação dos dados reais do organizador.

## Evento real e autorização da base

Evento `5ecae7dc-7b40-4a62-8026-b961870f042f`, início em 23/10/2026 às 18h de São Paulo, fim cadastrado em 25/10/2026 à meia-noite. Ainda não houve refeição.

A lista contém 40 convidados: 26 confirmados (25 adultos e 1 criança), 11 pendentes (4 adultos e 7 crianças), 3 recusados (adultos). O usuário escolheu explicitamente planejar para os **37 não recusados: 29 adultos e 8 crianças**.

Em uma gravação atômica com precondições de concorrência, foram atualizados somente os quatro contadores de público do evento e criado o documento operacional de revisão 1 com essa base nos três cardápios atuais. Commit: `2026-10-16T19:48:34.036799Z`. A releitura confirmou os valores. O cadastro anterior previa 35 pessoas (30 adultos e 5 crianças). A lista de convidados, seus status, itens, compras, pagamentos e orçamento não foram modificados.

A base nos cardápios é um planejamento inicial comum; não declara que todos já confirmaram presença em cada refeição nem define repetição dos serviços. O aplicativo antigo não lê o novo documento operacional: no modo Todos, sua lista ainda contém os 40 convidados, incluindo recusados. Até distribuir a versão nova, usar Manual com 29 adultos/8 crianças evita interpretar o cadastro atualizado como mudança desse modo.

## Conferência com o motor local

Os dados necessários foram consultados com projeção de campos, sem coletar nomes/contatos dos convidados. O motor local foi executado com uma cópia dos cardápios, catálogo de referências ativo, público e orçamento do evento, sem gravação de porções nem chamada à IA. O teste de replay passou e confirmou público 37, quatro resultados no almoço, duas lacunas de regra e financeiro incompleto. Os artefatos de leitura e replay permanecem em `.dart_tool/deploy-calculadora/`, fora do código versionado.

A revisão também corrigiu `faixaDoResultado`: a faixa exibida da referência agora utiliza o público da refeição, assim como o cálculo principal, em vez dos contadores gerais da festa. A regressão verifica uma refeição com 3 adultos e 1 criança frente a uma festa com 10 adultos. A análise estática e os 16 testes operacionais passaram após a correção. Essa alteração do app permanece somente no código local.

## Dados ainda necessários para concluir o planejamento

- Almoço: churrasco, macarrão e arroz estão com unidade inicial `un` e quantidade final zero; refrigerante possui 15 L planejados. Quantidade final não equivale a compra confirmada.
- Lanche da tarde: frutas sem quantidade final e sem regra no catálogo ativo. É necessário definir quais frutas, forma de compra/serviço e porção da receita ou referência escolhida.
- Janta: cachorro-quente sem quantidade final e sem regra no catálogo ativo. É necessário definir tamanho da unidade e composição/rendimento da receita.
- O catálogo ativo tem cinco referências genéricas (arroz, churrasco, macarrão, refrigerante e suco), todas sem preço. Os preços não foram preenchidos com valores inventados. O resumo pode priorizar a conferência de quantidades antes de contar os preços pendentes.
- Definir por refeição o papel dos alimentos, estado cru/seco/pronto, rendimento e se os acompanhamentos compartilham a porção. Não reduzir arroz/macarrão automaticamente pela presença do outro.
- Confirmar se cada cardápio será servido uma ou mais vezes e se há públicos distintos ao longo do período do evento. A duração total não multiplica refeições automaticamente.
- Um orçamento de R$ 6.500 e pagamento registrado de R$ 4.200 resultam em R$ 2.300 ainda a pagar nesse compromisso. A diferença entre o teto de R$ 8.500 e o orçamento é R$ 2.000, mas não é saldo final de compras: custos alimentares e cobertura continuam em conferência.
- Não havia simulações nem consumo observado. O estoque central está sem lotes declarados, e necessidades alimentares ainda não foram informadas; isso não comprova inexistência de estoque ou de restrições.

As lacunas acima são dados operacionais do primeiro evento; a infraestrutura não pode resolvê-las por inferência. A calibração observada somente começa após registrar preparo, presença real, sobras e faltas. A política atual exige pelo menos três eventos distintos comparáveis para adotar uma porção histórica.

## Aceite final desta etapa

- 125 testes de calculadora/cardápios aprovados após a correção da faixa por refeição.
- 16 testes operacionais aprovados, incluindo a regressão ampliada de público.
- Replay local do evento real aprovado.
- Análise estática dos dois arquivos de código alterados sem problemas.
- Backend TypeScript/planejamento/autorização/fallback/limites aprovado.
- Regras da calculadora, tarefas e auditoria aprovadas no emulador.
- Regras ativas conferidas, função `ACTIVE`, índice `READY`, acesso anônimo rejeitado.
- Nenhum build do aplicativo foi publicado; a nova versão não foi instalada sobre o app principal.
