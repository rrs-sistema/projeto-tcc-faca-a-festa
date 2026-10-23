# Entrega 05 — Agenda e serviços por ocorrência

Data: 19/10/2026. Escopo: Prompt 05. Alterações anteriores do workspace preservadas; sem deploy, migração, commit ou push.

## Diagnóstico e reprodução

O período do evento e os títulos dos cardápios não distinguiam duas execuções do mesmo menu. Público/grupos e quantidades finais eram vinculados ao ID do cardápio, a análise de composição interpretava o título e a duração global podia alcançar todas as regras. O primeiro teste do comando de agenda falhou com `Operação desconhecida` (registro local `.dart_tool/agenda-repro.log`).

## Decisão e comportamento implementado

Uma ocorrência possui ID estável próprio, também usado como ID de seu cardápio de execução. `id_modelo` referencia o cardápio reutilizável. Reutilizar o mesmo modelo cria cópias independentes de composição e regras privadas, com quantidades finais/sugeridas zeradas, não confirmadas e sem disponibilidade, compras ou reservas copiadas. Alterar ou excluir o modelo depois não modifica essas cópias nem impede editar a agenda existente. Não há sincronização automática de alterações de composição do modelo para as cópias.

A calculadora oferece **Agenda de refeições e intervalos**, com criação/edição, revisão explícita e confirmação remota. Salvar evento ou cardápio não agenda refeições. Data, hora, fuso e duração podem permanecer desconhecidos. Data civil, hora, fuso IANA, duração de 1 a 1.440 minutos e período são validados no cliente e servidor, incluindo horário inexistente na transição de verão. Quando início e duração são conhecidos, o término não pode ultrapassar o último dia do evento. O período usa os dias cadastrados, sem inventar horários de abertura/fechamento. Sobreposição entre serviços é permitida: grupos simultâneos são possíveis.

O tipo de serviço (refeição/intervalo) é declarado, separado do título e do formato de atendimento. Renomear não reclassifica ocorrências. O comportamento de interpretação do título permanece apenas para cardápios legados sem ocorrência. Público herdado/próprio e equipe/extra pertencem à ocorrência; extra não altera a previsão do evento. Grupos e destinos usam os mecanismos privados existentes e não são copiados automaticamente de outro serviço.

Cada cópia representa um serviço: a confirmação informa essa decisão e as regras copiadas iniciam `numero_servicos: 1`, preservando a referência anterior em `numero_servicos_modelo`. Uma edição deliberada posterior de repetições do item continua possível. Regras de ocorrência ignoram a duração global; apenas uma duração local conhecida pode participar da heurística técnica já existente quando a regra habilita ajuste por duração. Duração desconhecida aplica fator 1. Não se apresenta essa heurística como rendimento medido ou certificação nutricional.

Compras consolidadas, plano do evento, executor e reservas distinguem os IDs das ocorrências. As reservas continuam no único conjunto `lotes` do evento, por destino/item, impedindo disponibilizar o mesmo saldo duas vezes. O snapshot de planejamento já inclui a operação completa; agora leva também a agenda e os públicos locais. Históricos carregam seu snapshot, e edição de agenda fica bloqueada nesse contexto.

## Persistência e confirmação

Schema adicional opcional em `calculadora_operacao/{evento}`:

```text
agenda: [{id, id_evento, id_modelo, id_cardapio, titulo,
          data_local: "AAAA-MM-DD" | null, hora_local: "HH:mm" | null,
          fuso: IANA | null, duracao_minutos: inteiro | null, formato}]
refeicoes[id_cardapio]: {publico: contagem | null,
                        publico_extra: {adultos, criancas, bebes},
                        servico: "refeicao" | "lanche" | null,
                        ...grupos/destinos já existentes}
```

`agenda_confirmacoes/{pedido}` guarda recibo privado com assinatura e instante da confirmação. A callable de produção `confirmarAgendaCalculadora`, em `southamerica-east1`, verifica autenticação, propriedade do evento, revisão esperada, vínculo estável, período e projeção atual dos itens do modelo. Lê fonte e grava cópias, regras privadas, configuração, agenda e recibo na mesma transação. Retry do mesmo pedido/dados não duplica a revisão; reutilizar pedido com dados diferentes falha. Mudança concorrente exige nova revisão, e o editor preserva os campos após falha. O controller verifica usuário/evento/geração antes de consumir a resposta e confere se o estado retornado ainda corresponde à confirmação.

O transporte de produção usa o protocolo HTTP callable com token Firebase Auth, inclusive no Windows, sem uma interface desconectada ou backend simulado. A agenda é imutável pelo SDK cliente nas regras: somente a callable Admin pode introduzi-la/alterá-la. Atualizações normais da operação precisam preservá-la. Clientes não podem mudar `id_evento`, `id_modelo` ou `somente_modelo` de cardápio existente. Outros organizadores, fornecedores e anônimos não leem a operação/recibos privados.

Limites explícitos: até 20 cardápios no conjunto do evento, incluindo modelos; agenda até 20 ocorrências; modelo até 60 itens; conjunto de regras privadas até 60. A criação recusa ultrapassar esses limites antes de qualquer gravação, respeitando o executor atual. A conferência de público nominal herdado na callable limita a consulta a 120 convidados e recusa excedentes em vez de truncar silenciosamente.

## Compatibilidade

Ausência de `agenda`, `id_modelo` e `somente_modelo` preserva o comportamento antigo; não há migração nem datas/frequências inferidas. O original pode continuar como serviço sem agenda. A escolha explícita de usá-lo somente como modelo o retira da soma; isso é recusado se já contém finalização, compra, estoque ou reserva, para preservar fatos. Sua composição não é excluída. Não se convertem históricos aprovados em planejamento corrente.

## Arquivos desta entrega

- Domínio: `ocorrencia_servico.dart`, `agenda_servico_service.dart`, `cardapio.dart`, `estimativa_financeira.dart`, `analise_refeicao_service.dart`, `operacao_calculadora_service.dart`, `calculadora_festa_service.dart`, `plano_evento_service.dart`.
- Persistência: `cardapio_model.dart`, `agenda_servico_remote.dart`, `calculadora_festa_remote_datasource.dart`; dependência direta `timezone` em `pubspec.yaml`/lock.
- Interface: controller/parte `calculadora_festa_agenda.dart`, `calculadora_agenda_dialog.dart`, tela/layout da calculadora, `calculadora_operacao_dialog.dart`, texto do cadastro de cardápio.
- Backend/regras: `agendaServicoService.ts`, `confirmarAgendaCalculadora.ts`, export em `index.ts`, `executarPlanoService.ts`, `firestore.rules`.
- Testes: `agenda_ocorrencias_test.dart`, `agenda_ocorrencias_emulator_test.dart`, `calculadora.rules.test.js`, `testCalculadoraPlanejamento.js`, `testAgendaDesktop.js`, `prepararAgendaEmulador.js`, `firebase.agenda-test.json`.

## Validação

- `flutter test`: **620 testes aprovados**, saída 0 (`.dart_tool/agenda-fulltests.log`). Os seis testes de agenda incluem a regressão inicialmente ausente e as verificações de domínio/widget desta entrega.
- `npm --prefix functions run check:calculadora`: **aprovado**, saída 0; `tsc --noEmit`, planejamento/IA, política/configuração privada, agenda civil/fuso/identidade, autorização e limites (`.dart_tool/agenda-functions-final.log`).
- Firestore Emulator: **Calculadora Firestore rules: OK**, saída 0 (`.dart_tool/agenda-rules.log`). Negativas `PERMISSION_DENIED` são esperadas. Inclui bloqueio de introdução/edição/remoção direta da agenda e acesso aos recibos por terceiros.
- `node --check` nos dois scripts novos e no teste de regras: aprovado. Formatação Dart aplicada; `git diff --check` sem erros de whitespace nos arquivos envolvidos.
- `dart analyze` final do projeto: saída 0, **sem erros ou warnings**; seis mensagens informativas, repetindo três vezes dois pontos preexistentes fora desta entrega (`dossie_titular_documento.dart:2` e `ajustes_manuais_persistencia_test.dart:180`). Os avisos de estilo/import dos arquivos novos encontrados na primeira análise foram corrigidos, sem alterar esses arquivos anteriores.
- Integração Windows final: **1 teste aprovado**, `Agenda SDK/Callable reais: OK`, saída 0 (`.dart_tool/agenda-sdk-final.log`). A callable real validou token Auth no emulador. Todos os cenários descritos abaixo foram executados, inclusive edição após excluir o modelo, regras copiadas com um serviço, projeção desatualizada, período inválido, revisão concorrente e saldo único. Emuladores encerraram normalmente. Build Windows emitiu avisos de PDB/assembly de dependências nativas, sem impedir compilação ou teste. A CLI também detectou ADC, mas este teste usou somente os serviços emulados e não chamou serviços externos.

Os testes unitários/widgets distinguem substitutos controlados de integração. Cobrem quatro ocorrências/públicos em dois dias, três intervalos com compras agregadas, duração local/global, grupo isolado, lote único, horário desconhecido, limites e fuso, renomeação, cancelar sem gravação, falha com dados preservados e nova tentativa. Widget em 320 × 740, fonte 1,3 e teclado aberto.

O teste Windows usa SDKs reais Auth/Firestore, datasource/repositório de produção e a própria callable de produção carregada no Functions Emulator. Cobertura: quatro ocorrências/cópias, regras copiadas, repetição idempotente, público próprio/extra, finalização isolada, grupos isolados, reservas 6 + 5 recusadas e 6 + 4 aceitas sobre lote 10, falha por fonte desatualizada sem gravação parcial, período inválido, edição após exclusão do modelo, revisão concorrente recusada, retomada em novo controller e outro organizador sem acesso. IA/catálogo são substitutos locais nesse teste: isso não comprova um modelo externo.

Projeto fixo `demo-agenda-servicos`, inicialização Firebase explícita, emuladores conectados antes da autenticação. Harness recusa hosts não locais; transporte recusa override em projeto real ou URL não loopback; callable em emulação recusa projeto não demo/Firestore não local. Todos os usuários e eventos são sintéticos.

## Reprodução e ativação posterior

```powershell
flutter test
flutter analyze
npm --prefix functions run check:calculadora
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
firebase emulators:exec --project demo-faca-festa-contexto --config firebase.calculadora-test.json --only firestore "node test/firestore/calculadora.rules.test.js"
node functions/scripts/prepararAgendaEmulador.js
firebase emulators:exec --project demo-agenda-servicos --config firebase.agenda-test.json --only 'firestore,auth,functions' "node functions/scripts/testAgendaDesktop.js"
```

Executar Flutter unit/widget e integração Windows sequencialmente: ambos podem tocar arquivos gerados dos plugins. A preparação grava apenas a pasta ignorada `.dart_tool/agenda-functions`; não compila/publica o conjunto de Functions do projeto. Java padrão antigo foi recusado pela CLI; usar o JBR 21+ indicado. A máquina executa Node 24, embora Functions declare Node 22; registrar essa diferença na homologação do runtime de produção.

Ativação futura: revisar/publicar o backend com a nova callable e o executor atualizado, publicar as regras compatíveis e somente depois distribuir o cliente, pelo processo normal do projeto. Nenhuma publicação foi realizada. Não é necessário regravar cardápios/eventos legados.

Não há homologação em aparelho Android/iOS nesta entrega, nem testes de upload/modelo externo. Roteiro móvel: criar quatro serviços, deixar horário em aberto, declarar equipe e grupos, confirmar, encerrar/reabrir, editar com rede interrompida, repetir após retorno, alternar usuário/evento com resposta pendente, conferir fonte ampliada/teclado e compras de lote compartilhado. Datas civis/fuso são dados de planejamento; não há agendamento de notificações nem escolha de offset para horários duplicados de transição de verão. Esses testes não declaram a jornada inteira concluída.

## Revalidação após reenvio do Prompt 05 — 19/10/2026

O novo anexo foi comparado ao anterior por SHA-256: conteúdo idêntico. A implementação existente foi preservada e revalidada após as mudanças do catálogo contextual do Prompt 06, incluindo a extração do transporte HTTP autenticado compartilhado. Não foi necessário duplicar ou alterar a implementação da agenda.

- Agenda e executor: **24 testes aprovados**, saída 0, executando `agenda_ocorrencias_test.dart` e `plano_execucao_test.dart` (`.dart_tool/agenda-revalidacao.log`).
- `npm --prefix functions run check:calculadora`: **aprovado**, saída 0 (`.dart_tool/agenda-revalidacao-functions.log`).
- Análise estática dos arquivos específicos de ocorrência, serviço, controller, interface, transporte e integração: **No issues found**, saída 0 (`.dart_tool/agenda-revalidacao-analyze.log`).
- Reexecução Windows com SDKs reais Auth/Firestore e callable de produção emulada: **1 teste aprovado**, `Agenda SDK/Callable reais: OK`, saída 0 (`.dart_tool/agenda-revalidacao-sdk.log`). Conferiu quatro ocorrências independentes, repetição, públicos, grupos, saldo único, rejeições e retomada. Emuladores encerrados normalmente; apenas projeto demo e serviços locais foram usados.

Essa revalidação não substitui a homologação móvel nem ativa a funcionalidade em produção. Sem deploy, commit ou push.
