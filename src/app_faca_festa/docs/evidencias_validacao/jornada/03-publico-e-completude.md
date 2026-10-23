# Entrega 03 — Público, origem e completude

Data: 19/10/2026. Escopo: Flutter/Firebase do Faça a Festa. Alterações pré-existentes do workspace preservadas. Sem deploy, migração destrutiva, commit ou push.

## Diagnóstico reproduzido

A calculadora usava o cadastro quando a lista estava vazia e trocava para os registros nominais no primeiro convidado. O teste de regressão reproduziu **esperado 40, obtido 1** antes da correção. A Home também escolhia a lista pelo critério `totalLista > 0`. `_registrarTotaisDoEvento` e a edição do cadastro convertiam um total legado em adultos conhecidos.

## Decisão e comportamento implementado

Previsão, registros nominais, confirmações, completude declarada e fonte efetiva permanecem separados. Sem escolha confirmada, o planejamento usa previstos independentemente da quantidade de convidados. Completar a lista não troca a fonte nem confirma presença. Todos cadastrados inclui todos; não recusados exclui recusados; confirmados inclui apenas confirmados, inclusive conjunto vazio conhecido com total zero. Erro/carregamento não disparam fallback.

A interface apresenta previsão, estado explícito da lista, quantidade cadastrada e fonte usada. Trocar fonte mostra impacto e requer confirmação; cancelar não grava. A confirmação usa a operação de domínio e aguarda persistência; falha mantém a fonte anterior. A declaração de completude também passa por confirmação e persistência privadas. Edições manuais são identificadas como prévia local até a confirmação remota, sem marcar a fonte como confirmada no evento. Permanecem durante snapshots remotos; conflito externo é mostrado para revisão. Reabrir recupera a escolha persistida. Históricos usam o snapshot aprovado e não recebem a declaração corrente silenciosamente.

A Home usa a mesma política e mantém confirmações separadas do total escolhido; informa consulta/erro da configuração privada. A entrada e os serviços da calculadora herdam os valores da fonte escolhida. Refeições com público próprio mantêm seu público.

Total legado sem idades mantém a contagem conhecida, deixa as idades sem preenchimento no cadastro e pede distribuição antes de calcular porções. Salvar metadados desse cadastro preserva total e ausência de idades. Zero explicitamente informado permanece zero; cadastro novo sem público não vira zero confirmado. Vínculo de estimativa com evento legado sem idades mantém a pendência e pede distribuição em vez de inferir adultos.

Callbacks de lista/operação verificam evento, geração e usuário. Cancelamentos de listeners anteriores não limpam o listener novo. Respostas de gravações e declarações antigas não se aplicam a outro contexto.

## Persistência e compatibilidade

Reutiliza `calculadora_operacao/{idEvento}.configuracao_planejamento`, sem nova coleção nem dados alimentares privados no evento compartilhado:

```json
{
  "configuracao_planejamento": {
    "base": "previstos",
    "base_confirmada": true,
    "lista_completude": "em_preenchimento",
    "revisao": 4,
    "campos_alterados": ["base", "base_confirmada", "lista_completude"]
  }
}
```

Bases: `manual`, `previstos`, `todos`, `nao_recusados`, `confirmados`. Completude: `desconhecida`, `em_preenchimento`, `concluida`. Público manual usa o mapa existente `publico: {adultos, criancas, bebes}`; inteiros entre 0 e 1.000.000. A confirmação manual exige esse mapa. Revisão e campos alterados seguem o mecanismo transacional existente; cada comando registra seus próprios campos.

Campos novos são opcionais. Documento antigo sem declaração significa completude desconhecida, nunca inferida pelo tamanho da lista. Configuração antiga com `base` válida continua sendo uma escolha recuperável; `base_confirmada: false` não a adota. Sem base persistida, usa a previsão. Não há migração em lote. Snapshots novos incluem `politica_publico` com total previsto, completude, presença de idades e confirmação da fonte. Snapshots anteriores mantêm a fonte e os números salvos.

Validação de domínio, regras Firestore e backend TypeScript conferem os mesmos tokens e limites; autorização continua restrita ao dono/administrador conforme as regras existentes. O executor de planos mantém a configuração de público imutável durante a execução. Entrada assistida só registra fonte/público depois da aprovação existente e grava `base_confirmada`.

## Arquivos desta entrega

- Política: `lib/domain/services/publico_planejamento_service.dart`; entidade `lib/domain/entities/evento.dart`; comando/validação em `lib/domain/services/operacao_calculadora_service.dart`.
- Calculadora: `calculadora_festa_controller.dart`, partes `calculadora_festa_publico.dart`, `calculadora_festa_operacao.dart`, `calculadora_festa_entrada.dart`, `calculadora_festa_historico.dart`, tela `calculadora_festa_screen.dart` e seção `calculadora_festa_totais.dart`, no módulo calculadora.
- Lista/Home/DI: `convidado_controller.dart`, `home_event_screen.dart`, `lib/app/bootstrap/convidado_bootstrap.dart`.
- Cadastro: `evento_cadastro_controller.dart`, `evento_cadastro_persistencia.dart` e `cadastro_evento_bottom_sheet.dart`.
- Permissões/backend: `firestore.rules`, `functions/src/services/calculadora/publicoPlanejamentoService.ts`, `entradaAssistenteService.ts`, `executarPlanoService.ts`.
- Testes: `publico_planejamento_test.dart`, testes de cadastro/controller e jornada, `test/firestore/calculadora.rules.test.js`, `functions/scripts/testCalculadoraPlanejamento.js`, `integration_test/publico_planejamento_emulator_test.dart`, `functions/scripts/testPublicoPlanejamentoDesktop.js`.
- Fixtures anteriores de composição, consumo, integridade, planejamento e prontidão agora declaram a fonte manual/lista que seus cenários pretendiam usar. Widgets de cadastro/jornada rolam até os campos após o resumo maior. Nenhum teste foi desativado.

## Validação real

- `dart format`: arquivos Dart desta entrega formatados, incluindo fixtures ajustadas.
- `dart analyze`: produção, partes de controllers, integração e testes alterados, **sem problemas**; análise separada das sete fixtures ajustadas também sem problemas.
- `flutter test test/features/calculadora test/features/eventos test/features/cardapios test/features/convidados --reporter expanded`: **404 testes aprovados**, saída 0. Após o último ajuste de apresentação do total no cadastro, subconjunto de **26 testes aprovado**, saída 0. Após os guardas finais de usuário em respostas assíncronas e a distinção de prévia local, **11 testes de público/prontidão aprovados**, saída 0, e análise estática dessas partes sem problemas.
- `node --check` nos scripts de backend/harness: aprovado. `git diff --check` nos arquivos envolvidos: sem erros de whitespace.
- Regressão 40 → primeiro convidado; conjuntos todos/não recusados/confirmados; zero confirmado e manual zero; ausência/erro; legado sem idades; falha de gravação; cancelamento; recuperação da escolha; público próprio de refeição; troca de evento e usuário.
- Widget a 320 × 740, fonte 1,3: confirmação e cancelamento sem gravação; seleção confirmados zero persistida. Testes anteriores de cadastro/estimativa também exercitam teclado e rolagem.
- `npm --prefix functions run check:calculadora`: **aprovado**, incluindo `tsc --noEmit`, validação da política, planejamento/IA, autorização, fallback e limites. O carregamento síncrono do novo validador foi movido antes de iniciar os testes assíncronos para não interferir no teste de intervalo entre chamadas.
- Regras em Firestore local: **Calculadora Firestore rules: OK**, saída 0. Inclui configurações válidas, enum/tipo/contagens inválidos, manual zero e isolamento contra outro usuário/anônimo. Logs de PERMISSION_DENIED correspondem às negativas esperadas.
- Windows com SDKs reais de Auth/Firestore e repositórios de produção: **1 teste aprovado**, `Público/completude SDK real: OK`, saída 0. Cria evento 40, grava primeiro convidado, mantém previsão 40, persiste declaração privada, confirma fonte com zero presenças, persiste manual 7, altera presença, mantém refeição própria 10, reabre com manual 7, declara lista concluída e verifica acesso privado negado a outro usuário e ausência de dados privados no evento compartilhado.

A repetição detectou recuperação de uma configuração de execução anterior no SDK Windows ao reutilizar a identidade fixa. O harness passou a gerar um evento sintético único por execução e exige essa identidade no teste, isolando o estado inicial sem apagar dados.

O harness exige hosts locais para Auth/Firestore e usa projeto fixo `demo-publico-planejamento`. O teste Flutter exige `CALCULADORA_QA=true`, inicializa opções Firebase demo explícitas e conecta os SDKs a localhost antes de autenticar. IA/base são substitutos controlados nesse teste; não comprovam IA externa nem catálogo remoto. Upload e presentes são sentinelas não usados; não há comprovação de Storage, envio de convites ou serviços externos.

## Reproduzir e ativar posteriormente

```powershell
flutter test test/features/calculadora test/features/eventos test/features/cardapios test/features/convidados --reporter expanded
npm --prefix functions run check:calculadora
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
firebase emulators:exec --project demo-publico-planejamento --config firebase.calculadora-test.json --only 'firestore,auth' "node functions/scripts/testPublicoPlanejamentoDesktop.js"
firebase emulators:exec --project demo-faca-festa-contexto --config firebase.calculadora-test.json --only firestore "node test/firestore/calculadora.rules.test.js"
```

Para disponibilização futura, revisar/publicar regras e backend pelo processo normal do projeto antes do cliente que grava os novos campos. Nenhuma publicação foi feita. Sem atualização das regras, a gravação pode ser recusada e a interface mantém a escolha anterior.

Não houve homologação em aparelho Android/iOS. Validar manualmente em telefone: cadastrar 40 previstos, registrar primeiro convidado, declarar lista em preenchimento, cancelar/confirmar troca de fonte, confirmar zero, reabrir, editar manual, alterar presenças e testar refeição própria; repetir offline e alternando usuário/evento, teclado aberto e fonte ampliada. A compilação Windows apresentou avisos existentes de PDB ausente e assembly de impressoras; o teste funcional terminou com saída 0. Uma tentativa concorrente de testes Flutter encontrou bloqueio do arquivo gerado de plugins no Windows; a verificação foi repetida sequencialmente. A integração Windows não homologa os plugins e o ciclo de vida móvel. Esta entrega encerra apenas o escopo 03, sem declarar a jornada completa homologada.
