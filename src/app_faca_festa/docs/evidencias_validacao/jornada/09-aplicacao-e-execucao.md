# 09 — Aplicação agrupada, estoque e execução idempotente

Data: 20/10/2026. Escopo: aplicação revisada entre cardápios, operação privada, estoque, lista proposta e tarefas. Nenhum deploy, commit, push, migração destrutiva ou acesso intencional à produção.

## Diagnóstico e decisão de negócio

O fluxo existente já construía IDs estáveis de tarefas, utilizava callable com transação única, comparava documentos e consultas completos (inclusive coleções inicialmente vazias) e preservava quantidade final, despesas, contratos e tarefas editadas no domínio. Os testes focados iniciais passaram em 24 casos. A entrega preserva esses mecanismos.

As lacunas encontradas foram: criação de recibo versão 1 permitida ao cliente; ausência de recuperação durável do ID enviado; verificação de callback apenas pelo evento; validação de saldo no servidor sem validar a chave e o destino de cada reserva alterada; tarefa podendo receber ID alternativo; e atualização de tarefa sem demanda recusada quando o patch não repetia a origem já persistida.

Aplicar confirma sugestões, destina saldo disponível e organiza tarefas. Não confirma quantidade final, compra realizada, pagamento, contratação, conclusão de tarefa, envio de mensagem ou suficiência alimentar. Ingredientes só vêm de fichas explícitas; sem ficha compatível, não se inventa composição. A lista agrega por identidade nominal normalizada, unidade, estado e público compatíveis, sem conversões implícitas. IDs locais de ingredientes continuam vinculados à ficha de cada destino.

## Implementação e arquivos

- `lib/domain/services/plano_execucao_service.dart`: mantém a transação proposta e acrescenta `destinos_ids` às compras, com cardápio, item e ingrediente quando conhecido. O contexto informa quais recibos foram recuperados.
- `lib/data/datasources/remote/plano_execucao_remote_datasource.dart`: confere proprietário na fonte revisada antes de enviar; grava identidade local do pedido antes da chamada; consulta recibos pelo servidor ao reabrir; isola a conta em todas as chaves; preserva recuperação quando há erro de transporte; apresenta categorias das fontes conflitantes sem valores privados. Rejeição definitiva remove o marcador local; recibo confirmado só é removido localmente após carregar as fontes atuais.
- `lib/data/datasources/remote/agenda_servico_remote.dart`: reutiliza transporte callable autenticado HTTP também para execução, inclusive no desktop. Projeto demo exige endpoint HTTP de loopback explícito. Injeção de FirebaseFunctions permanece compatível.
- `lib/presentation/modules/calculadora/controllers/calculadora_festa_execucao.dart`: leitura e callback de aplicação vinculados à conta, evento, geração de preparação e cardápio, além da assinatura do planejamento. Resposta antiga não restaura regras ou operação de uma tela reaberta.
- `lib/presentation/modules/calculadora/widgets/calculadora_execucao_dialog.dart`: revisão presa à sessão original; mudança de escolhas gera novo pedido; repetição da mesma proposta mantém o pedido. Ao reabrir, informa recuperação confirmada pelo servidor. Cancelar não chama aplicação.
- `functions/src/services/calculadora/executarPlanoService.ts`: valida chave única, destino existente, regra correspondente, identidade/unidade/estado do lote e ingrediente conhecido para reservas alteradas. Preserva reservas manuais e de preparo iniciado/editado, bem como tarefas já trabalhadas. Valida UUID v5 derivado da chave da tarefa, responsabilidade e prazo. Não permite que uma regra salva seja reaproveitada para outro destino. Conflito retorna caminhos limitados para classificação no cliente, sem conteúdo dos documentos.
- `functions/src/functions/calculadora/aplicarPlanoCalculadora.ts`: devolve o recibo persistido tanto no primeiro sucesso quanto na repetição.
- `firestore.rules`: recibos são exclusivamente gravados pelo servidor. O cliente pode continuar salvando regras e o indicador de revisão em `execucao`, mas não pode forjar ou apagar os campos de aplicação agrupada.
- Testes: `test/features/calculadora/plano_execucao{,_remote,_widgets}_test.dart`, `test/firestore/calculadora.rules.test.js`, `functions/scripts/testPlanoExecucaoEmulator.js`, `integration_test/execucao_recuperacao_emulator_test.dart`, `functions/scripts/testExecucaoDesktop.js`. Harness: `functions/scripts/prepararExecucaoEmulador.js`, `firebase.execucao-test.json`.

## Persistência, atomicidade e compatibilidade

O documento privado continua `calculadora_operacao/{evento}`, versão 1. A aplicação incrementa `revisao` e grava `execucao` versão 2, preservando regras omitidas. As reservas continuam no único mapa `lotes/{lote}/reservas` do documento operacional, com chave JSON `[cardapio,item]` ou `[cardapio,item,ingrediente]`. Toda reserva conta contra o total único do lote. Lotes não são criados ou excluídos pela aplicação.

O recibo imutável permanece em `calculadora_operacao/{evento}/aplicacoes/{pedido}`, versão 2, com pedido, proprietário, evento, SHA-256 do plano canônico, revisão, instante do servidor e contagem de ações. Não contém lista de convidados, receitas ou textos das tarefas. O mesmo pedido com assinatura diferente é recusado. Recibos legados versão 1 não são aceitos como comprovação do executor atual; devem levar à revisão com um novo pedido, sem migração ou exclusão automática.

Recuperação local reutiliza o armazenamento durável por arquivo já existente (armazenamento web equivalente), com prefixo `execucao_v1_`, identidades de usuário/evento/pedido em base64url e conteúdo somente `{pedido}`. Não guarda plano, token ou receita. Só um recibo remoto confirma aplicação. Pedido sem recibo permanece sem confirmação; não há reexecução automática. O caminho para retomar é “Atualizar pelas fontes atuais”.

Todas as mutações e o recibo são escritos na mesma transação. Limites existentes (240 fontes, 100 patches, 60 regras e tamanho do comando) são mantidos. Excesso é recusado integralmente; não existe etapa parcial anunciada como sucesso. Duas propostas de revisões concorrentes disputam o mesmo documento operacional; a perdedora precisa de nova revisão. Não foi criado executor paralelo ou fila de efeitos parciais.

Os novos campos são aditivos. Clientes antigos que tentarem gravar recibos ou substituir o relatório de aplicação diretamente serão recusados pelas regras novas. O caminho atual para salvar regras individuais continua permitido. Históricos aprovados não são alterados.

## Validação reproduzível

Executar na raiz, com as dependências locais já instaladas:

```powershell
flutter test
npm --prefix functions run check:calculadora
npm --prefix functions run build
node functions/scripts/prepararExecucaoEmulador.js
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
firebase emulators:exec --project demo-calculadora-execucao --config firebase.execucao-test.json --only 'firestore,auth,functions' "node functions/scripts/testPlanoExecucaoEmulator.js"
firebase emulators:exec --project demo-calculadora-execucao --config firebase.execucao-test.json --only 'firestore,auth,functions' "node functions/scripts/testExecucaoDesktop.js"
firebase emulators:exec --project demo-faca-festa-contexto --config firebase.calculadora-test.json --only firestore "node test/firestore/calculadora.rules.test.js"
```

O teste remoto Dart gera fixtures em `.dart_tool` a partir do motor de produção; por isso `flutter test` precede o harness Node. A preparação expõe somente as callables de execução/revisão em `.dart_tool/execucao-functions`, carregando as fontes TypeScript reais. Os scripts recusam hosts não locais e usam projetos `demo-*`. Rodar os dois harnesses em sessões novas dos emuladores. Não executar Flutter unitário e integração Windows simultaneamente, por compartilharem artefatos do compilador.

Resultados efetivamente obtidos nesta entrega:

| Verificação | Resultado |
| --- | --- |
| `flutter test` | **658 testes passaram**, duração reportada 3min; domínio, widgets e regressão geral. Log local `.dart_tool/p09-full.log`. |
| Análise Dart dos arquivos de produção e testes modificados | **No issues found**. Log `.dart_tool/p09-analyze-final.log`. |
| Formatação Dart | 9 arquivos verificados, nenhuma alteração pendente; TypeScript formatado com o printer do compilador instalado; scripts Node com sintaxe verificada. |
| `npm --prefix functions run check:calculadora` e build TypeScript | Passaram, incluindo as validações já existentes de planejamento/IA e planejador. Logs `.dart_tool/p09-backend-formatted.log` e `.dart_tool/p09-build-final.log`. |
| Transações reais em Firestore + Auth emuladores e protocolo callable HTTP autenticado | **78 verificações passaram**. Mesma assinatura retorna exatamente o mesmo recibo; duas chamadas iguais não duplicam efeitos; dois pedidos concorrentes disputam a revisão e apenas um confirma; reservas com alias, destino externo ou ingrediente inventado são recusadas; reservas manuais e de preparo iniciado são preservadas. Inserção/remoção/alteração nas fontes recusa a aplicação integralmente. Log `.dart_tool/p09-emulator-final.log`. |
| Regras reais Firestore | **Calculadora Firestore rules: OK**. Proprietário não forja recibo nem relatório; salvar regras individuais permanece permitido; outras contas não leem o recibo privado. Log `.dart_tool/p09-rules.log` (executado no emulador local já ativo, em namespace demo separado). |
| Integração Windows com Firebase Auth/Firestore reais e callable emuladora | **1 teste integrado passou**. O servidor confirma, o cliente perde a resposta de propósito, o marcador é durável em arquivo, uma nova instância do adaptador recupera o recibo; repetir a proposta não duplica tarefas nem altera a quantidade final 7. Outra conta é recusada antes de enviar e pelas regras na leitura do recibo. Log `.dart_tool/p09-desktop-final.log`. |
| Isolamento de callback | Teste força resposta de leitura e de aplicação após reabrir o mesmo evento e verifica ausência de restauração de regras/operação antigas. Incluído nos 658 testes. |

Os logs de rejeição das regras contêm `PERMISSION_DENIED` esperados pelos testes negativos. Nenhum substituto foi usado para comprovar as transações, permissões ou recibos das linhas de integração acima. Os testes unitários da fronteira usam substitutos apenas para controle de falhas/callbacks e são identificados separadamente.

## Limitações e ativação posterior

O host usa Node 24; o projeto declara Node 22. A execução emuladora não homologa Node 22 de produção. O linker Windows emite avisos LNK4099 por PDBs ausentes nas bibliotecas do Firebase, sem mudar as verificações funcionais. Não foi realizada homologação em dispositivo Android/iOS ou em produção.

A primeira execução nativa cumpriu as asserções funcionais e falhou na limpeza por tentar excluir o app Firebase padrão, operação não suportada pelo SDK. O harness foi corrigido para encerrar a sessão e deixar a instância padrão terminar junto com o processo; não foi removida nenhuma asserção funcional.

Para ativar posteriormente: revisar o diff integrado às alterações anteriores; conferir build com Node 22; publicar as funções e as regras compatíveis antes de distribuir o cliente atualizado; executar verificação de ambiente separada sob autorização. Nada foi publicado nesta entrega. Estes resultados cobrem o Prompt 09, não encerram a jornada inteira.
