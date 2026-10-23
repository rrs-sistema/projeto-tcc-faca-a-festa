# 02 — Cadastro, rascunho durável e vínculo recuperável

Data: 19/10/2026. Alterações locais; sem deploy, migração destrutiva, commit ou push.

## Diagnóstico

O working tree já continha alterações extensas, incluindo os pontos de entrada. Elas foram preservadas. A busca por AGENTS.md na árvore e nos ancestrais não encontrou instruções adicionais.

A implementação anterior já mantinha ID estável de evento durante tentativas no mesmo controller e uma chave GetStorage por usuário/evento para vínculo pendente. Entretanto, não havia persistência completa do formulário antes da primeira tentativa de salvar. A estimativa retornava no dispose da calculadora. Fechar o processo antes da tentativa podia perder o cadastro e suas escolhas. O vínculo usava o salvamento geral da simulação: repetir a chamada podia sobrescrever um histórico com a mesma identidade.

A inspeção de get_storage 2.1.1 mostrou que write()/save() retornam após agendar uma microtask de flush, sem aguardar o Future da fila de IO. Assim, somente acrescentar await à API antiga não satisfaria o checkpoint durável.

## Decisões e comportamento novo

- A store existente ganhou capacidade de guardar o cadastro completo por usuário e ID de rascunho, antes de existir evento. A implementação de produção é injetada pelo bootstrap já existente.
- Em Windows/Android/IO, cada cadastro tem arquivo próprio no diretório privado de suporte do aplicativo, em rascunhos_eventos/. A gravação escreve arquivo temporário com flush:true e aguarda rename. Operações concorrentes da mesma identidade são serializadas. Não há regravação de arquivos de outros usuários. No navegador, o adaptador condicional usa localStorage, sujeito à quota e limpeza do navegador.
- O formulário registra alterações por debounce de 300 ms e aguarda checkpoints ao avançar, abrir a calculadora, sair e iniciar a criação remota. A calculadora registra escolhas enquanto permanece aberta, além de guardar ao pausar e aguardar a gravação ao voltar. dispose apenas encerra observadores.
- Falha de armazenamento tem mensagem visível e bloqueia os pontos críticos; não é apresentada como salvamento remoto. Encerramento abrupto recupera o último checkpoint concluído; há janela de até 300 ms para a edição ainda em debounce. Não se promete sincronização entre aparelhos, nem resistência a remoção dos dados do aplicativo ou falha física do armazenamento.
- A entrada oferece retomar, descartar um rascunho específico e iniciar novo sem apagar os demais. Os registros ilegíveis são indicados e preservados. Cancelar fecha após guardar localmente e não altera o evento ativo.
- O ID de evento é incluído no arquivo antes da primeira chamada de rede, inclusive sem estimativa. Recuperar uma tentativa com ID já atribuído consulta o evento para reconhecer criação cuja resposta se perdeu e preservar seus metadados. Repetir usa o mesmo documento.
- Evento confirmado e vínculo pendente são estados diferentes. A falha do vínculo mantém os registros locais e informa que o evento está salvo. O botão passa a “Concluir vínculo”. A conclusão só remove o registro correspondente.
- Público, tipo e limite atuais do formulário prevalecem. Reconciliação mantém identidade, data original, duração, perfil e ajustes manuais. Alterar tipo invalida o catálogo anterior e informa sua atualização, preservando ajustes privados. Limite zero permanece zero; campo vazio permanece ausente.
- O vínculo de produção usa transação de criação única no repositório existente. Se a identidade já existe com mesmo usuário/evento/rascunho, retorna sem substituir valores ou itens. Divergência de identidade é erro. Não cria cardápio, orçamento, tarefa, cotação, compra ou pagamento.
- Após concluir, a interface abre a simulação vinculada diretamente na calculadora, com sua identidade estável; não exige procurar no histórico. O snapshot salvo continua isolado e a transição para dados correntes permanece explícita.
- Consultas tardias de CEP são invalidadas ao limpar/reabrir o cadastro. Restaurar o endereço não dispara busca automática que possa sobrescrever campos recuperados.

## Formato e migração

CadastroEventoRascunho, versão 2:

```json
{
  "versao": 2,
  "usuario": "identidade-local-do-organizador",
  "id": "uuid-do-rascunho",
  "evento": "",
  "evento_confirmado": false,
  "atualizado_em": "data-ISO-UTC",
  "formulario": {"campos": {}, "tipo": "id-tipo", "padrinhos": []},
  "estimativa": null
}
```

A chave codifica separadamente usuário e rascunho em base64url. O formulário inclui textos necessários à retomada, endereço, tipo, tema, datas, público e limite; a estimativa inclui regras e escolhas privadas. O parser verifica versão, identidade e estrutura. Corrupção individual não vira ausência e não apaga o original.

RascunhoCalculadora serializa versao:1; mapas anteriores sem versão continuam aceitos como versão 1. A recuperação de vínculo legado por edição do evento grava o novo cadastro e conserva a chave rascunho_calculadora_v1_* até sucesso do vínculo. Não há recuperação retroativa de dados que nunca chegaram a ser persistidos.

Não foram acrescentados campos privados ao documento compartilhado evento. O snapshot permanece em calculadora_festa/{idCalculo}/itens, com dono e id_rascunho_origem existentes. calculadora_operacao não teve seu schema alterado.

A regra nova permite ao dono do evento consultar a ausência de calc_{idEvento}_{timestamp}, necessária à transação. Não autoriza outro organizador ou usuário anônimo, nem libera leitura de um snapshot existente pertencente a outro contexto. Há testes negativos para esses casos.

## Arquivos da entrega

- lib/domain/entities/cadastro_evento_rascunho.dart
- lib/domain/entities/rascunho_calculadora.dart
- lib/domain/services/rascunho_calculadora_store.dart
- lib/domain/repositories/vinculo_rascunho_repository.dart
- lib/data/local/rascunho_calculadora_store.dart
- lib/data/local/cadastro_armazenamento.dart
- lib/data/local/cadastro_armazenamento_contrato.dart
- lib/data/local/cadastro_armazenamento_io.dart
- lib/data/local/cadastro_armazenamento_web.dart
- lib/data/datasources/remote/calculadora_festa_remote_datasource.dart
- lib/data/repositories_impl/calculadora_festa_repository_impl.dart
- lib/presentation/modules/eventos/controllers/evento_cadastro_controller.dart
- lib/presentation/modules/eventos/controllers/evento_cadastro_persistencia.dart
- lib/presentation/modules/eventos/controllers/evento_cadastro_rascunho.dart
- lib/presentation/modules/usuario/pages/cadastro_evento_bottom_sheet.dart
- lib/presentation/modules/usuario/components/endereco/endereco_section_controller.dart
- lib/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart
- lib/presentation/modules/calculadora/pages/calculadora_festa_screen.dart
- firestore.rules
- test/firestore/calculadora.rules.test.js
- test/features/eventos/cadastro_rascunho_duravel_test.dart
- test/features/eventos/evento_cadastro_controller_test.dart
- integration_test/cadastro_rascunho_vinculo_emulator_test.dart
- functions/scripts/testCadastroRascunhoDesktop.js

Os diffs contra HEAD também incluem trabalho anterior nestes arquivos.

## Validação e limites

Resultados efetivos:

- dart format: arquivos Dart alterados formatados.
- dart analyze: arquivos alterados, partes de controllers, testes novos e teste ajustado, **sem problemas** na execução final.
- flutter test test/features/eventos test/features/calculadora test/features/cardapios --reporter expanded: **355 testes aprovados**, saída 0.
- Cinco testes novos de durabilidade aprovados: arquivo real/novas instâncias/isolamento/corrupção; confirmação perdida e retomada; falha de disco e troca de usuário; debounce e pausa antes de dispose; migração/reconciliação e zero versus ausência.
- npm --prefix functions run check:calculadora: aprovado (tsc --noEmit, planejamento/IA, limite compartilhado, renovação, autorização e fallback).
- Regras com Firestore emulado: **Calculadora Firestore rules: OK**, saída 0; inclui transação repetida sem sobrescrever histórico e consulta de ausência negada a outro usuário/anônimo. As negativas PERMISSION_DENIED são esperadas.
- Harness Windows de SDK real: **1 teste aprovado**, “Cadastro/vínculo SDK real: OK”, saída 0. Conferiu uma única identidade de evento, público 40 e limite 2500 no snapshot, repetição preservando alteração posterior do histórico, uma única simulação, privacidade contra outro usuário e ausência de cardápios/orçamentos/tarefas automáticos.
- node --check nos dois scripts JS alterados: aprovado.
- git diff --check nos arquivos envolvidos: sem erros de whitespace.

O caso antigo que esperava converter limite confirmado zero em ausência foi ajustado para testar explicitamente zero e campo vazio, mantendo validação de entradas inválidas e de valor fracionado. Os controles de abrir estimativa e salvar/cancelar têm altura mínima de 48 e podem crescer com texto ampliado.

 Testes locais com arquivos reais conferem leitura por novas instâncias antes de dispose, isolamento por usuário, corrupção preservada, perda de confirmação, repetição, falha de disco, vínculo pendente, reconciliação e migração. O teste de widget cobre debounce e pausa com a calculadora aberta. Repositórios controlados nesses testes não comprovam rede real.

O teste de integração usa SDKs reais de Auth/Firestore, repositórios de produção e regras no projeto fixo demo-cadastro-vinculo. As implementações substitutas de IA/base não são chamadas nesse teste; o caminho sob teste é persistência autenticada, cálculo determinístico e vínculo transacional. O harness recusa hosts fora do emulador local e não usa credenciais de produção. A dependência de upload do repositório de eventos é um sentinela de teste que falha se for chamado; não há requisição a Storage nem comprovação de upload.

O teste de integração foi executado no Windows com os SDKs reais; a inicialização usa o app Firebase padrão com opções demo explícitas, conforme exigência do plugin desktop. O processo termina sem tentar excluir esse app padrão, operação não suportada pelo plugin.

Não há aparelho/emulador móvel conectado. Testes de arquivo não simulam desligamento físico entre instruções, e o cenário completo de forçar encerramento/reabrir no telefone continua como validação manual pendente. Android apresenta licenças não aceitas no flutter doctor. A compilação Windows produziu avisos de PDB ausente e de assembly de impressoras de plugins existentes; não se confundem com a aprovação funcional.

## Reproduzir e ativar sem publicar

```powershell
flutter test test/features/eventos test/features/calculadora test/features/cardapios
npm --prefix functions run check:calculadora
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
firebase emulators:exec --project demo-cadastro-vinculo --config firebase.calculadora-test.json --only 'firestore,auth' "node functions/scripts/testCadastroRascunhoDesktop.js"
firebase emulators:exec --project demo-faca-festa-contexto --config firebase.calculadora-test.json --only firestore "node test/firestore/calculadora.rules.test.js"
```

Antes de disponibilizar o cliente, revisar e disponibilizar a regra de leitura do destino inexistente pelo processo normal de publicação do projeto; sem ela, o novo vínculo será recusado e a pendência local será preservada. Nenhum comando de deploy foi executado nesta entrega.

Roteiro móvel: abrir novo cadastro com outro evento ativo; preencher e estimar; esperar a janela de debounce de 300 ms e encerrar o processo; reabrir e retomar; alterar público/tipo/limite e conferir a reconciliação; interromper rede após criação e repetir; restaurar rede e concluir vínculo; verificar uma única simulação e abertura direta; cancelar e descartar um rascunho próprio sem afetar os demais usuários/eventos. Conferir teclado aberto, fonte ampliada, tela pequena e falha de armazenamento. Não marcar a jornada inteira homologada com base neste escopo.
