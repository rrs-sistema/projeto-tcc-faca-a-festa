# Demora no financeiro do fornecedor — 04/11/2026

Investigação do acesso a `localhost:52658/#/fornecedor/financeiro`. Ambiente Firebase `faca-a-festa` consultado somente em leitura. Nenhum deploy, alteração de configuração ou gravação financeira foi realizado. Código da aplicação preservado; esta entrega registra o diagnóstico.

## Conclusão

Há uma combinação de processamento lento no backend, consultas simultâneas disparadas pela tela e um prazo de espera menor que o tempo observado no primeiro acesso. A Function termina com HTTP 200, mas a tela já pode ter descartado a espera como timeout.

A investigação anterior de 27/10 encontrou uma versão antiga do protocolo. Esse diagnóstico não deve ser reutilizado como explicação deste acesso: a versão publicada foi atualizada em 27/10 às 12:03:16 de São Paulo e já contém `origem: "contratos_repasses"`. Os arquivos de comandos financeiros e projeção contratual, tanto TypeScript como JavaScript compilado, foram comparados com o pacote versionado do deploy e são idênticos aos arquivos locais. O planejamento publicado tem diferenças locais, mas também executa as releituras descritas abaixo.

## Evidência do acesso de hoje

Horários abaixo em São Paulo, UTC−3. O timestamp de cada log HTTP representa o início da requisição, não sua conclusão.

| Evento | Horário | Duração/status |
| --- | --- | --- |
| Três requisições OPTIONS | 08:06:32.417–32.419 | HTTP 204; uma levou 3,918 s |
| Inicialização de três instâncias | 08:06:32.461 | Mensagem de autoscaling |
| Containers prontos | 08:06:36.571–36.592 | Cerca de 4,1 s após a inicialização |
| POST 1 | 08:06:36.653 | 10,194 s; HTTP 200 |
| POST 2 | 08:06:36.661 | 9,429 s; HTTP 200 |
| POST 3 | 08:06:36.669 | 10,271 s; HTTP 200 |

As três verificações de autenticação foram válidas. As conclusões dos POSTs ocorreram aproximadamente às 08:06:46–47. Do início dos OPTIONS até as respostas, a janela observada foi de aproximadamente 13,7–14,5 s. Isso explica como o limite local de 12 s pode expirar mesmo com sucesso posterior do servidor. Essa janela é uma inferência dos timestamps; não é uma medição ponta a ponta no navegador.

Há três POSTs simultâneos no serviço no horário da captura. Sem rastreamento por requisição no navegador, os logs não provam isoladamente que todos vieram da mesma aba; o controller possui, porém, um caminho explícito para gerar essas duplicações.

Evidência: [logs sanitizados](diagnostico-financeiro-2026-11-04/logs-sanitizados.json).

## Gargalos encontrados no código

### 1. Limites diferentes na mesma consulta

- `lib/presentation/modules/financeiro/controllers/financeiro_fornecedor_controller.dart:244`: `.timeout(Duration(seconds: 12))`.
- `lib/data/datasources/remote/financeiro_fornecedor_remote_datasource.dart:38`: prazo de 15 s no gateway/SDK.
- `functions/src/functions/financeiro/comandosFinanceiroFornecedor.ts:125`: servidor permite 60 s.

O primeiro limite a vencer controla o erro da tela. O `Future.timeout` externo não cancela o processamento no servidor, e sua resposta posterior não preenche mais o resumo por esse Future. Aumentar apenas os 15 s do datasource não resolveria o limite de 12 s do controller.

### 2. A entrada na tela pode iniciar consultas sobrepostas

`iniciar()` liga os listeners antes de consultar o resumo (`financeiro_fornecedor_controller.dart:191–212`). O primeiro snapshot de `orcamento` agenda uma consulta. Os primeiros snapshots de custos, recebimentos e movimentos também chegam a `_agendarConsulta` via `_recalcularLocal` (`:280–406`).

O timer de 300 ms agrupa somente notificações próximas. Não há controle de consulta em andamento. Uma notificação posterior pode iniciar outra callable enquanto a anterior continua ativa. O contador `_consulta` faz a tela ignorar o resultado da anterior, sem cancelar seu processamento. Portanto, a primeira resposta válida pode ser descartada em favor de outra mais recente e ainda pendente.

### 3. O resumo calcula duas vezes a projeção de contratos

`functions/src/functions/financeiro/comandosFinanceiroFornecedor.ts:141` chama `visoesFinanceirasFornecedor`. Depois de receber e processar os fatos, chama `consultarPlanejamento` (`:208`).

`consultarPlanejamento` volta a verificar usuário/fornecedor e abre outra transação de leitura. Nela, relê contratos, custos, recebimentos e movimentos, além das contas a pagar e configuração (`functions/src/services/financeiro/planejamentoFornecedorService.ts:49–52`).

A projeção contratual faz `await` por contrato para comissão e `await` por alias para repasses, dentro de laços (`visaoFinanceiraContratoService.ts:23–29`). O planejamento repete a projeção e depois consulta novamente os repasses para montar os movimentos. Também consulta liquidações por obrigação e dados por evento. O trabalho cresce com os contratos e inclui várias esperas sequenciais de rede. Não há medição individual por etapa para atribuir uma porcentagem dos 9–10 s a cada uma delas.

### 4. Function e banco estão em localidades diferentes

A Function está em `southamerica-east1`, São Paulo; o banco `(default)` está em `nam5`, Estados Unidos. A correspondência dessas localidades está na [documentação oficial do Firestore](https://firebase.google.com/docs/firestore/locations). A distância tende a aumentar a latência de cada ida sequencial ao banco; a parcela exata não foi medida.

A configuração publicada não informa instâncias mínimas. Os logs confirmam que houve inicialização no acesso analisado. Esse custo adicional não explica sozinho a demora persistente dos POSTs.

Evidências: [configuração da Function](diagnostico-financeiro-2026-11-04/configuracao-function.json) e [localização do banco](diagnostico-financeiro-2026-11-04/localizacao-firestore.json).

## Comparação com a revisão anterior

Amostra de logs retornados desde 27/10, considerando somente POST com HTTP 200:

| Revisão | Amostras | Mínimo | Mediana | Máximo |
| --- | --- | --- | --- | --- |
| `00004-xuf` | 18 | 1,888 s | 2,645 s | 3,815 s |
| `00005-doh` | 15 | 7,220 s | 9,100 s | 10,271 s |

A mediana observada aumentou aproximadamente 3,4 vezes depois da atualização. Isso é uma associação entre revisão e latência, não um benchmark controlado: volumes de dados e condições dos acessos podem variar. A revisão anterior também tinha um protocolo incompatível com o app atual; retornar a ela restauraria esse problema.

Evidência: [comparação de revisões](diagnostico-financeiro-2026-11-04/comparacao-revisoes.json).

## Ordem recomendada para a correção

1. Controlar as consultas no controller: uma consulta em andamento por contexto de usuário/filtro, agrupando invalidações e tratando os snapshots iniciais para evitar duplicações. Alterações reais durante a consulta precisam continuar provocando atualização posterior.
2. Consolidar a leitura financeira no backend: carregar fatos e projeções uma vez, reutilizando-os no resumo e no planejamento dentro de uma visão consistente. Preservar as verificações de comissão, conciliação e privacidade.
3. Reduzir as consultas por contrato e as esperas sequenciais, agrupando leituras ou usando paralelismo limitado quando forem independentes. Instrumentar duração e quantidade de consultas por etapa, sem registrar valores financeiros ou dados pessoais.
4. Unificar o prazo da consulta entre controller e datasource com base na latência medida. Ajustá-lo pode evitar o falso fracasso no primeiro acesso, mas não elimina o trabalho repetido.
5. Depois de medir o backend otimizado, avaliar proximidade entre processamento e banco e eventual instância mínima. São mudanças de infraestrutura com implicações próprias; nenhuma foi executada nesta investigação.

A validação da correção deve cobrir uma única consulta inicial, atualização por mudança real sem sobreposição, respostas fora de ordem, troca de sessão/filtro, primeiro acesso com inicialização e manutenção dos totais corretos em comissão/repasse/caixa. Dados indisponíveis devem continuar distintos de saldo zero.

## Limites da investigação

Foram lidos logs, configuração do serviço, localização do Firestore e os arquivos relevantes do pacote de deploy. Nenhuma requisição foi executada em nome do fornecedor, e os documentos financeiros não foram acessados diretamente. Não foi capturado um perfil de rede da aba nem adicionada instrumentação no ambiente. Por isso, os tempos do serviço são comprovados, mas a divisão interna de latência e o tempo exato no navegador permanecem sem medição.

Não foram executados testes de aplicação porque não houve alteração de código executável.
