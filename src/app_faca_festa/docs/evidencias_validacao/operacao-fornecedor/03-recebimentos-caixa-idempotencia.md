# Prompt 03 — Recebimentos e caixa sem duplicidade

Validação local em 26/10/2026, Windows/PowerShell. Dados sintéticos e projeto `demo-caixa-fornecedor`. Não houve deploy, commit, push, migração, operação bancária ou alteração em produção.

## Reconferência e escopo

Foram examinados Git, regras, comandos financeiros, projeções, controller e páginas. Não foram encontrados AGENTS.md aplicáveis no repositório ou ancestrais. A árvore já continha alterações extensas, inclusive dos prompts 01/02 e de comissão/repasse; foram preservadas. O diagnóstico de escritas separadas não descrevia integralmente o estado local: já existia agrupamento de gravações. Permaneciam lacunas de identidade persistente no cliente, assinatura completa da requisição, auditoria atômica, conciliação dos espelhos e alocação por contrato.

Foi reutilizada a identidade canônica de contratação e a projeção financeira existente. `contas_receber` permanece o fato privado, `movimentos_caixa` seu espelho e `financeiro_auditoria` a evidência da operação; não foi criado outro livro financeiro.

## Comportamento implementado

- Valores novos usam centavos inteiros, limites e validação de campos. Conversão da interface para centavos arredonda na fronteira; cálculos/alocações posteriores são inteiros.
- A chave da operação é persistida por fornecedor antes da chamada. A abstração local existente usa arquivo temporário, flush e substituição; a implementação web correspondente também é reutilizada. Reabertura/retry consulta primeiro a operação com o payload original. Resultado desconhecido permanece recuperável e impede uma nova intenção conflitante. Limpeza compara a chave esperada para uma resposta antiga não apagar intenção posterior.
- O backend autentica o dono, valida vínculo e contrato, normaliza o payload e calcula SHA-256 canônico. Mesma chave/payload retorna o resultado existente; chave com conteúdo diferente é rejeitada. A transação verifica integridade das três representações e grava fato, espelho e auditoria juntos. Contenção concorrente não cria fatos extras.
- Regras permitem leitura dessas coleções apenas ao fornecedor dono; escritas diretas de cliente são negadas, incluindo a auditoria na exclusão da regra genérica sobreposta. Cliente, outro fornecedor e administrador não recebem acesso aos dados privados.
- O caixa concilia por identidade/origem: fato e espelho entram uma vez. Repasse confirmado pela plataforma continua separado do recebimento próprio declarado. Pagamento declarado pelo cliente não é caixa do fornecedor.
- A distribuição usa identidade canônica de contrato. É possível distribuir entre contratos, com soma menor ou igual ao fato e resto explicitamente não alocado. Sem escolha, vínculo automático só ocorre quando existe exatamente um contrato elegível. Dois contratos no mesmo evento não recebem o total do evento repetidamente.
- Resumo, lista e acompanhamento privado exibem saldo contratual após recebimento próprio, com repasse pendente da plataforma em campo distinto. Esta evolução do prompt 03 complementa a visão do prompt 02: recebimento externo reduz o saldo privado total, sem transformá-lo em repasse bancário confirmado.
- Adiantamento é caixa declarado sem presumir entrega ou execução. Sinal de execução enviado pelo cliente não confirma receita realizada. Crédito excedente permanece explícito e saldo contratual negativo é preservado; dívida positiva e crédito são apresentados separadamente.
- Estorno cria saída, novo fato e auditoria vinculados ao original. Valor parcial exige distribuição explícita compatível com o original; valor total pode derivar o restante. A transação limita estorno total, por contrato e parcela livre, inclusive sob concorrência. Só a projeção acumulada de estorno no original é atualizada; valor, autoria e data originais são preservados. A interface permite estorno parcial/total sem executar transferência bancária.
- Listeners e refresh conciliam as mesmas fontes, sem incremento otimista paralelo. Troca de sessão descarta dados/listeners antigos e preserva apenas a intenção local isolada por UID. Falha de consulta ou espelhos inconsistentes produz indisponibilidade, não saldo zero.

## Arquivos desta implementação

Backend/regras: `functions/src/services/financeiro/recebimentoFornecedorService.ts` (novo), `resumoFornecedorService.ts`, `acompanhamentoPersistenciaService.ts`, `acompanhamentoPartesService.ts`, `functions/src/functions/financeiro/comandosFinanceiroFornecedor.ts`, `functions/src/index.ts`, `firestore.rules`.

Flutter: `lib/data/local/recebimento_pendente_store.dart` e `lib/domain/services/caixa_fornecedor_service.dart` (novos); datasource financeiro remoto; serviços de resumo e acompanhamento; controller financeiro do fornecedor; páginas de financeiro e acompanhamento do fornecedor.

Validação: `functions/scripts/testRecebimentosCaixaDominio.js`, `testRecebimentosCaixaEmulator.js`, `test/features/financeiro/recebimentos_caixa_idempotencia_test.dart` (novos); `financeiro_contratos_unificado_test.dart` e script npm em `package.json`.

## Comandos executados e resultados reais

Para os emuladores, foi usado JDK 21 local, sem mudar configuração de produção:

```powershell
$env:JAVA_HOME=Join-Path $env:TEMP 'codex-chat-jdk/jdk-21.0.12.1+1'
$env:PATH="$env:JAVA_HOME/bin;$env:PATH"
npm run test:financeiro:recebimentos
npm run test:financeiro:contratos
npm --prefix functions run check:financeiro
```

Todos terminaram com código 0. O primeiro executa build TypeScript, domínio, emulador Firestore e regras privadas. O segundo reexecuta a integração de contratos/comissões/repasses do prompt 02 e respectivas regras. O terceiro executa TypeScript sem emissão e regressões financeiras existentes. Logs locais: `$env:TEMP/recebimentos-emulador-final.log`, `recebimentos-regressao-contratos.log`, `recebimentos-regressao-functions.log`.

```powershell
flutter test test/features/financeiro/recebimentos_caixa_idempotencia_test.dart test/features/financeiro/financeiro_contratos_unificado_test.dart test/features/financeiro/financeiro_fornecedor_test.dart test/features/financeiro/acompanhamento_partes_test.dart test/features/financeiro/comissao_plataforma_test.dart test/features/financeiro/comissoes_responsivas_test.dart --reporter expanded
```

Resultado: **45 testes aprovados**, código 0. Log local: `$env:TEMP/recebimentos-flutter-final.log`. O teste de estorno parcial encontrou uso de controller descartado durante a animação de saída; a liberação agora aguarda `DialogRoute.completed`, e a suíte completa foi reexecutada com sucesso.

```powershell
dart analyze lib/data/local/recebimento_pendente_store.dart lib/data/datasources/remote/financeiro_fornecedor_remote_datasource.dart lib/domain/services/caixa_fornecedor_service.dart lib/domain/services/resumo_financeiro_fornecedor_service.dart lib/domain/services/acompanhamento_partes_service.dart lib/presentation/modules/financeiro/controllers/financeiro_fornecedor_controller.dart lib/presentation/modules/financeiro/pages/financeiro_fornecedor_page.dart lib/presentation/modules/financeiro/pages/acompanhamento_fornecedor_page.dart test/features/financeiro/recebimentos_caixa_idempotencia_test.dart test/features/financeiro/financeiro_contratos_unificado_test.dart
```

Resultado: **No issues found**, código 0. `git diff --check` do escopo financeiro passou; a execução global identificou uma linha vazia preexistente em `calculadora_festa_totais.dart:601`, fora deste escopo e preservada.

### Cobertura comprovada no emulador

1. Contratos de R$ 2.000,00/R$ 3.000,00 no mesmo evento; entrada R$ 500,00 no primeiro: saldos R$ 1.500,00/R$ 3.000,00 e caixa R$ 500,00. Acompanhamento privado coincide com resumo.
2. Oito requisições simultâneas idênticas: um fato, um espelho, uma auditoria. Requisições concorrentes divergentes: uma vence e outra recebe conflito.
3. Mesma chave alterando valor, contrato, tipo, execução ou motivo: rejeição. Resposta perdida após persistência: consulta e replay não alteram totais.
4. Falha injetada depois de enfileirar as escritas, antes do commit: nenhum documento parcial; no estorno também não altera o contador original.
5. Listener real seguido de refresh, alocação múltipla e rejeição de soma excedente; adiantamento sem entrega presumida.
6. Estornos parciais/concorrentes, limite de devolução, crédito excedente, legado sem vínculo com/sem espelho; original preservado.
7. Regras com SDK cliente autenticado sintético: dono lê, escritas diretas negadas, outro fornecedor/cliente/admin negados, incluindo auditoria e concessões genéricas.
8. Espelho adulterado: resumo, consulta e replay falham de forma explícita, sem sobrescrever o histórico.

Os testes Flutter cobrem domínio, arquivo local realmente persistido e reaberto, isolamento por UID, limpeza condicionada à chave, timeout antes/depois da persistência, retomada com controller reaberto, payload divergente, refresh durante envio, falha de listener, formulários de alocação/estorno e exibição do crédito. Doubles de interface são complementares à integração real Firestore acima.

## Compatibilidade, índices e limites

- Novas operações usam schema 2 e assinatura verificável. Chaves legadas sem assinatura não são sobrescritas/reexecutadas automaticamente. Fatos antigos continuam legíveis; vínculo ausente ou desconhecido aparece não alocado. Não houve migração automática.
- Legado identificado como repasse privado sem conciliação e espelho antigo de recebimento sem fato não viram entrada adicional: são apresentados como pendência/incompletude. Movimento manual legado independente continua sendo movimento próprio. Identidades duplicadas ou espelhos divergentes não são corrigidos por suposição.
- Consultas utilizam caminhos privados e filtro simples por referência do recebimento. Não foi necessário novo índice composto nem alteração de `firestore.indexes.json`; índices simples automáticos são suficientes para as consultas adicionadas. Nada foi publicado.
- O emulador usa Firestore real e SDK de regras; os callables são invocados via `onCall.run` com contexto sintético autenticado. Timeout é perda de resposta simulada após persistência real, e rollback usa falha controlada antes do commit. Não foi usado proxy de rede, Auth emulator ou ambiente bancário.
- Não se afirma validação em aplicativo instalado, navegador real ou banco. Testes de interface/controller usam Flutter test; persistência em disco foi executada localmente. Nenhuma declaração privada é confirmação bancária e nenhum estorno transfere dinheiro.
