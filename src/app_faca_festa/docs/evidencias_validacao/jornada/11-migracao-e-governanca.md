# 11 — Compatibilidade, migração e governança

Data: 20/10/2026. Escopo implementado no estado local das entregas anteriores. Git já continha alterações e arquivos não rastreados; foram preservados. Nenhum AGENTS.md aplicável foi encontrado. Sem deploy, escrita em produção, migração destrutiva, commit ou push.

## Diagnóstico e decisão

O leitor de eventos retornava zero quando a previsão estava ausente e descartava um zero explícito quando existiam contagens etárias divergentes. A serialização também convertia idades ausentes em zero. O leitor de históricos atribuía o total legado a adultos sem marcar a hipótese. Operações futuras podiam ser regravadas como versão 1 em alguns comandos. O catálogo já tinha publicação imutável e autenticação administrativa, mas aprovação e publicação eram uma única ação sem registro intermediário; não existia seleção de versão anterior auditada nem ferramenta de inspeção de migração.

A entrega mantém os documentos originais. A migração v1 é **aditiva e de interpretação**: cria uma projeção privada de compatibilidade e seu registro de inspeção, sem inventar datas, idades, ocorrências ou metadados editoriais e sem recalcular fatos. Os adaptadores de leitura continuam funcionando mesmo sem operação, agenda ou catálogo publicados. A projeção é um inventário auditável; não substitui as fontes do cálculo. A seleção editorial efetiva continua em `calculadora_itens_base/{id}.referencia_contextual`, consumida pelos leitores Flutter e pelo planejador do backend.

## Inventário dos contratos efetivamente encontrados

| Contrato e leitores | Versões/campos opcionais | Tratamento nesta entrega |
| --- | --- | --- |
| `evento/{id}` — `EventoModel`, `Evento`, `PrevisaoPublico` | Sem schema global; `data_fim`, total e idades opcionais | Ausência continua null; zero explícito é preservado. Sem término não cria data final. Total sem idades não confirma adultos. Avisos no contexto da calculadora. |
| Cadastro local — `CadastroEventoRascunho`, `RascunhoCalculadoraStore` | Cadastro v2; estimativa `RascunhoCalculadora` v1 | Mantidos isolamento por usuário/identidade e rejeição de versões desconhecidas. Nenhuma conversão especulativa de cadastro v1 cujo contrato não está definido no código atual. Arquivo incompatível não é apagado por esta migração. |
| `cardapios/{id}` — `CardapioModel` | Escopo ausente → `naoDefinido`; modelo/ocorrência opcionais | Menu sem vínculo na agenda é contado como pendência, sem criar serviço/data. |
| `calculadora_operacao/{evento}` — datasource, `OperacaoCalculadoraService`, serviços TS | Envelope v1, revisão transacional; configuração, agenda, planejador, lotes e execução opcionais | Ausência é aceita como legado. Versão explícita diferente de 1 bloqueia gravação no domínio, comandos backend e regras; não há downgrade silencioso. |
| Regras — `ItemEstimativaFinanceira.fromPlanejamento` | `premissas` opcionais, regras anteriores sem fonte/ocorrência | Leitura mantém o mapa original; editor apresenta pendências progressivas. Nenhuma fonte é inventada. |
| `calculadora_festa/{id}` e itens — `CalculadoraFestaModel` no fluxo atual | Motor em `contexto_planejamento.versao_motor`; motor atual 6, ausência representa legado | Documento histórico não é migrado/recalculado. Hipótese etária do leitor antigo fica identificada e pode ser transportada como `publico_hipotetico:true` em uma serialização explicitamente solicitada. Motor diferente exige nova simulação para análise; custo/status/snapshot permanecem preservados. |
| Catálogo — `ReferenciaContextual`, datasource e `catalogoContextualService` | Payload schema 1 / `motor_minimo:1` do leitor editorial, independente do motor de cálculo 6 | Payload publicado permanece compatível. Governança schema 1 é metadado separado; versões publicadas são imutáveis. Legado aprovado sem governança continua legível. |
| Receitas, contratos, orçamento/gastos, pagamentos, compras e reservas | Contratos privados existentes | Não são destinos de escrita da migração. Fixtures verificam igualdade de documentos e itens antes/depois. |

## Migração v1: inspeção, aplicação e reversão

Callable: `migrarPlanejamentoCalculadora`. Serviço: `migracaoPlanejamentoService.ts`. CLI: `functions/scripts/migrarPlanejamento.js`.

- Exige projeto `demo-*` explícito, Firestore em loopback e administrador ativo com `usuarios/{uid}.migracao_planejamento == true`. O CLI exige token Auth e host Functions local. A ferramenta entregue recusa produção; esta tarefa não habilita nem executa migração real.
- Evento é seleção explícita e limitada. O CLI permite até 20 identidades distintas por execução, com resultado por evento. Cada evento é uma transação; não se promete atomicidade entre eventos.
- `inspecionar` é a ação padrão e só lê. Reporta schema, assinatura determinística, códigos de hipóteses e contagens. Não publica referências, não cria operação vazia e não escreve nem recibo no Firestore.
- `aplicar` exige relatório anterior do mesmo projeto e assinatura exata das fontes. Mudança concorrente aborta sem escrever. Mais de 100 cardápios ou históricos exige revisão manual; não há truncamento silencioso.
- Destino estável: `planejamento_compatibilidade/{evento}`, schema 1, proprietário, assinatura, revisão, `selecao_ativa` e `leitura`. A versão desconhecida da projeção é recusada.
- Antes da ativação, a mesma transação cria `inspecoes/{assinatura}` com cópia privada dos documentos inspecionados e `transicoes/{revisao}` com ação/responsável. A cópia inclui evento, operação e documentos principais de cardápios/históricos lidos; não é um backup completo de todas as subcoleções. Estas permanecem intactas.
- Aplicar novamente a mesma assinatura ativa não altera revisão, timestamp ou cópias. Reverter novamente uma seleção desativada também não altera nada.
- `reverter` usa a assinatura da projeção selecionada e só desativa sua seleção. Funciona mesmo se a operação original passar a uma versão que o leitor não suporta. Não restaura nem sobrescreve fontes atuais com a cópia antiga.
- O CLI reserva o relatório local antes de mutações remotas e registra progresso por evento. Falha deixa relatório parcial, sem expor conteúdo privado. Não sobrescreve um relatório preexistente. Repetir um evento já aplicado é seguro.

Não há um registro genérico que force versão nova em qualquer documento: apenas a transição conhecida legado→projeção v1 é suportada. Uma futura v2 exige novo adaptador, validação e teste; nunca é tratada como v1 por padrão.

## Governança editorial e reversão da referência

O backend continua exigindo administrador ativo para editar, aprovar, publicar e selecionar política global. O cliente não pode forjar publicação, aprovação, estado ou recibos, nem conceder a si mesmo a autorização de migração. A criação pública de usuário administrativo também é recusada, assim como a autoativação de um administrador desativado.

1. **Rascunho:** `referencia_rascunho`; não entra em propostas. Alterar o rascunho invalida a aprovação anterior daquela revisão.
2. **Aprovada:** ação `aprovar`, com `validacoes_contextuais/{versao}` contendo assinatura do conteúdo, fonte, versão, papel administrativo, responsável e instante. Ainda não seleciona a revisão para consumo.
3. **Publicada:** ação `publicar` exige aprovação do mesmo conteúdo e revisão esperada. Cria `versoes_contextuais/{versao}` imutável e seleciona o payload compatível no documento principal. A origem e o aprovador real são preservados.
4. **Substituída:** publicação seguinte registra o estado da versão anterior em `estados_contextuais`; não altera seu payload nem snapshots que a usaram.
5. **Seleção/reversão:** administrador escolhe uma versão já publicada ou desativa a seleção. Pedido estável e recibo impedem repetir a mutação após resposta perdida. A numeração máxima publicada não diminui ao selecionar uma versão anterior. O editor carrega a última revisão para não reutilizar número de versão.

A administração permite aprovação separada, “Aprovar e publicar”, seleção anterior e desativação, com confirmação remota, falha recuperável e campos mantidos. Cancelar a seleção não escreve. A ação antiga do repositório `publicarReferencia` foi adaptada para aprovar remotamente e depois publicar, verificando troca de sessão entre as etapas. Um cliente antigo que chama diretamente a callable de publicação sem aprovação recebe erro orientando atualização.

Selecionar outra referência só afeta novas propostas. Regras já confirmadas, receitas próprias e históricos aprovados continuam com seus snapshots. Desativar seleção não apaga versões, fatos ou auditoria. A projeção de compatibilidade não participa dessa seleção editorial.

## Arquivos alterados neste escopo

- Domínio/leitores: `compatibilidade_planejamento_service.dart`, `operacao_calculadora_service.dart`, `evento_model.dart`, `calculadora_festa.dart`, `calculadora_festa_model.dart`, `estimativa_financeira.dart`.
- UI: `calculadora_contexto_card.dart`, `calculadora_regra_manual_dialog.dart`, `catalogo_contextual_admin_page.dart`, guarda de motor em `calculadora_festa_analise_ia.dart`.
- Catálogo: contrato `catalogo_contextual_repository.dart`, datasource `calculadora_itens_base_remote_datasource.dart`, implementação `calculadora_itens_base_repository_impl.dart`, serviço `catalogoContextualService.ts`.
- Backend: novos `migracaoPlanejamentoService.ts` e `migrarPlanejamentoCalculadora.ts`, export em `functions/src/index.ts`; guardas de versão em `entradaAssistenteService.ts`, `agendaServicoService.ts`, `executarPlanoService.ts`, `revisaoPosEventoService.ts`; `firestore.rules`.
- Ferramentas/testes: `migrarPlanejamento.js`, `prepararMigracaoEmulador.js`, `testMigracaoGovernancaEmulator.js`, `testMigracaoSuite.js`, `firebase.migracao-test.json`, `compatibilidade_migracao_test.dart`, ajuste de rótulo em `catalogo_contextual_test.dart`, atualização explícita do contrato de zero em `evento_model_characterization_test.dart`, novos casos em `test/firestore/calculadora.rules.test.js`.

Os caminhos Dart citados estão nas pastas existentes de domínio, dados e apresentação; não foram duplicados serviços de cálculo ou persistência.

## Validação executada

- Foco inicial: **22 testes Flutter aprovados** em `.dart_tool/p11-foco-novo.log`, incluindo seis novos casos de compatibilidade/seleção.
- Primeira integração real bem-sucedida: `.dart_tool/p11-emulator-final.log`, com Auth, Firestore, Functions e CLI. Verificou dry-run sem escrita, idempotência, conflitos, reversão, autorização, preservação dos originais e ciclo editorial.
- Backend final: `check:calculadora` **aprovado**, incluindo compilação TypeScript e verificações de planejamento/catálogo/execução. Registro: `.dart_tool/p11-backend-conclusao.log`.
- Regressão completa final: **672 testes Flutter aprovados**, em 2 min 08 s. Registro: `.dart_tool/p11-full-final.log`.
- Análise estática dos arquivos envolvidos e controller com seus parts: **sem problemas encontrados**. Registro: `.dart_tool/p11-analyze-final.log`. Formatação conferida em 16 arquivos, sem diferenças; `git diff --check` sem erros de espaço.
- Integração final com Auth, Firestore, Functions, CLI e regras: **aprovada**, incluindo reversão após a operação passar à versão 2, preservando essa versão e os demais dados. Registro: `.dart_tool/p11-integracao-regras.log`.
- Regras finais repetidas após reforçar o bloqueio de autoativação administrativa: **aprovadas**. Registro: `.dart_tool/p11-regras-final.log`. Os erros PERMISSION_DENIED esperados são as tentativas negadas nos testes; o processo terminou com código 0.

A primeira regressão completa apresentou 671 aprovações e uma expectativa de caracterização do comportamento antigo: substituir total explicitamente zero pela soma etária de 48. Essa expectativa foi atualizada para exigir total zero, soma etária 48 e distribuição divergente não confirmada. A regressão completa seguinte passou, sem retirar as verificações numéricas ou desativar testes.

O arquivo `SimulacaoCalculadoraFestaModel` também foi inventariado, mas não tem chamadores no código atual: a lista de simulações usa `CalculadoraFesta` carregada pelo leitor principal. Não foi apresentado como um caminho de integração ativo nem alterado um leitor sem uso.

A primeira inicialização das Functions excedeu a descoberta padrão de 10 segundos. A execução seguinte usou `FUNCTIONS_DISCOVERY_TIMEOUT=120`. O cache anterior de compilação de testes foi preservado em cópia e recompilado após não avançar no carregamento. Nenhum teste foi desativado ou teve sua exigência funcional removida.

Reprodução em PowerShell, a partir da raiz:

```powershell
flutter test
npm --prefix functions run check:calculadora
node functions/scripts/prepararMigracaoEmulador.js
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
$env:FUNCTIONS_DISCOVERY_TIMEOUT='120'
firebase emulators:exec --project demo-migracao11 --config firebase.migracao-test.json --only 'firestore,auth,functions' 'node functions/scripts/testMigracaoSuite.js'
```

CLI manual, **apenas com os emuladores e uma identidade demo autorizada**. `MIGRACAO_ID_TOKEN` recebe um ID token obtido no Auth demo; não gravá-lo em arquivo ou documentação:

```powershell
$env:FUNCTIONS_EMULATOR_HOST='127.0.0.1:5001'
node functions/scripts/migrarPlanejamento.js --projeto demo-migracao11 --eventos legado11 --relatorio .dart_tool/inspecao11.json
node functions/scripts/migrarPlanejamento.js --projeto demo-migracao11 --eventos legado11 --acao aplicar --inspecao .dart_tool/inspecao11.json --relatorio .dart_tool/aplicacao11.json
node functions/scripts/migrarPlanejamento.js --projeto demo-migracao11 --eventos legado11 --acao reverter --inspecao .dart_tool/inspecao11.json --relatorio .dart_tool/reversao11.json
```

O harness cria somente fixtures sintéticas no demo, compara evento/operação/menu/itens/histórico/itens históricos/contrato/orçamento/pagamento/receitas privadas e testa permissões por tokens reais. Os testes de regras usam contextos autenticados do rules-unit-testing; não são apresentados como teste de aparelho. Não foi repetida homologação visual ou nativa Windows nesta entrega; a UI foi exercitada por testes de widget.

## Instrumentação sem conteúdo privado

Relatório de migração contém identidade técnica selecionada, schema, assinatura, estado, códigos de hipóteses e contagens, sem nome, e-mail, endereço, ingrediente, preço individual ou corpo de documento. Cópias privadas são acessíveis somente à administração pelas regras; o dono pode ler a projeção de seu evento, não as cópias. Responsáveis ficam na auditoria privada, sem reprodução em logs operacionais.

Instrumentação recomendada para ativação: contadores agregados por schema/ação/resultado (`inspecionada`, `aplicada`, `sem_alteracao`, `revertida`, `conflito`, `negada`, `incompativel`) e, para referências, cobertura ausente por tipo de serviço/versão do leitor. Não usar identidade de usuário/evento como dimensão de métricas nem registrar payloads de callables. Restauração significa desativação/seleção explícita; nunca reaplicar cópia sobre fatos mais recentes. Logs padrão de verificação das callables registram validade da autenticação, sem payload no código desta entrega.

## Ordem segura de ativação e limites

1. Revisar o diff com as entregas anteriores e suspender temporariamente publicação editorial durante a troca de contratos.
2. Ativar backend compatível e regras correspondentes antes de liberar o novo editor. Backend continua lendo referências schema 1 já publicadas e passa a exigir aprovação para novas publicações. As regras protegem governança, migração e versões futuras. Nenhum schema de operação muda nesta entrega.
3. Distribuir clientes com adaptadores e confirmação editorial atualizada. Não liberar escrita de eventos legados por versões que serializam ausência como zero; sem esse adaptador, essas versões só podem ser usadas para consulta desses registros. Clientes editoriais sem etapa de aprovação não podem publicar pelo contrato novo.
4. Inspecionar uma seleção pequena no ambiente demo, guardar relatórios e exercer aplicação/reversão. Esta entrega não precisa regravar documentos originais em produção para que os novos leitores funcionem.
5. Qualquer futura liberação da ferramenta fora do demo exige revisão específica da trava de ambiente, autorização operacional e backup completo conforme o processo do projeto. Essa liberação e publicação real permanecem pendentes e não foram executadas.
6. Se uma referência causar regressão, selecionar a publicação anterior ou desativá-la pela administração; preservar versões, snapshots e fatos. Não fazer rollback destrutivo de dados nem permitir cliente antigo rebaixar operação de versão futura.

Ambiente executado: Windows, Flutter 3.27.2/Dart 3.6.1; Node do host 24, embora o projeto declare Node 22. Os resultados não homologam o runtime Node 22, dispositivos Android/iOS nem produção. Sem dados reais criados ou migrados. Este registro encerra somente o escopo do Prompt 11, não toda a jornada.
