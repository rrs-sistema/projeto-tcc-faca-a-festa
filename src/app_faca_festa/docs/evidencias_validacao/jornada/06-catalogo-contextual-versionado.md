# Entrega 06 — Catálogo contextual versionado

Data: 19/10/2026. Escopo: Prompt 06. Alterações anteriores preservadas. Sem deploy, alteração em produção, migração destrutiva, commit ou push.

## Diagnóstico

O catálogo existente usa `calculadora_itens_base` para identidades e `calculadora_evento_itens` para regras por tipo/perfil de evento. Já há CRUD administrativo e repositório. Entretanto, `PlanoEventoService` selecionava churrasco pela palavra no tipo e lanche para qualquer outro tipo. `PropostaRefeicaoService` continha reconhecimento fechado de nomes e escolhas locais de porção/rendimento. As fontes no código não constituíam atualização remota nem aprovação universal de contexto.

A reprodução por inspeção confirmou esse caminho. Na primeira regressão após a mudança, testes antigos que dependiam de uma sugestão automática ou de perguntas locais deixaram de funcionar. Os cenários de criação foram atualizados para escolher um modelo explicitamente, mantendo as verificações de revisão, conflito, falha, repetição, quantidades finais e histórico. Não foram desativados testes nem relaxadas regras de publicação. A regressão também expôs um indicador de carregamento que permanecia ativo após resposta tardia; a resposta já era descartada e o encerramento do carregamento foi corrigido.

## Decisão e fluxo implementado

O novo catálogo **estende a coleção existente**, sem coleção concorrente de referências. Um documento base pode ter uma publicação contextual e um rascunho. As versões ficam em subcoleção imutável. O repositório de produção implementa a extensão `CatalogoContextualRepository`; não usa as antigas regras por tipo de evento como novas porções automaticamente. Receitas e regras privadas confirmadas continuam disponíveis.

O organizador escolhe um modelo aprovado opcional ou mantém seu cardápio livre. Casamento, corporativo, retiro e churrasco não escolhem formato pelo nome. Um modelo novo contém composição declarada em dados, consumida pelo cliente compatível sem recompilar o APK. Antes da criação inicial, a interface permite responder às referências/obtenção de cada item e revisar a proposta. Sem cobertura, não cria quantidades artificiais nem aprova a criação de um conjunto incompleto.

Para porções, a seleção exige alias exato normalizado, serviço, formato, público e forma de obtenção compatíveis. Limites editoriais de horário civil, duração e período também restringem candidatos; horário desconhecido não satisfaz referência que exija faixa horária. Serviço/formato ausentes geram perguntas. Não se usa aproximação por palavras de alimento desconhecido. A seleção explícita identifica papel, unidade, estado, faixa e limitações da referência.

Porções são o ponto de partida editorial publicado dentro da faixa, por público declarado; não são consumo medido ou certificação de adequação. Não há preço no schema. Peso servido não se torna compra crua por fator presumido. A preparação com estados diferentes exige escolher rendimento publicado compatível, com snapshot/fonte próprios, ou informar medição na ficha da receita. Rendimento estimado permanece distinto de medido. O validador técnico de compra também reconhece o snapshot de rendimento configurável, sem depender de uma lista fechada de nomes.

O editor manual consulta o catálogo configurável nos fluxos de produção. Definir regra própria continua possível sem uma referência publicada. Alterações manuais que modificam a base referenciada conservam a referência como origem e deixam de declará-la como valor editorial aplicado.

A publicação não altera regras correntes aprovadas nem históricos. As regras usam snapshots completos de referência, rendimento e modelo, com ID/versão. Consultar novas versões atualiza as opções para revisão; não reescreve essas regras. O executor confere snapshots referenciados contra suas versões imutáveis no Firestore, aceitando uma versão anterior ainda existente em vez de exigir a publicação mais recente.

## Schema, permissões e administração

```text
calculadora_itens_base/{id}
  ...campos base compatíveis com o catálogo existente
  referencia_contextual: publicação atual | ausente
  referencia_rascunho: proposta editorial | null
  versoes_contextuais/{versao}: publicação imutável
  edicoes_contextuais/{pedido}: assinatura e resultado da confirmação
```

Schema contextual 1 / motor mínimo 1: `id`, `versao`, `tipo` (porção/modelo/rendimento), nome, aliases, alimento/receita, serviços, formatos, períodos, públicos, obtenções, papel, unidade, estados de consumo/compra, contexto, limitações, fonte, data de verificação opcional, parecer editorial, aprovador e instante da aprovação. Porção/rendimento acrescentam mínimo/máximo/padrão. Modelo contém itens tipados e declara um serviço/formato. Faixas opcionais: hora inicial/final e duração mínima/máxima. Hora usa HH:mm e faixa dentro do mesmo dia; serviços noturnos que cruzem meia-noite precisam de referências separadas. Fonte aceita HTTPS ou origem identificada no código (`codigo:`).

`editarCatalogoCalculadora`, em `southamerica-east1`, valida o schema, limites e versão esperada. Só administrador com `tipo: A` e `ativo: true` pode salvar/publicar. O servidor determina UID e instante de aprovação; a data de verificação da fonte não é inventada. Publicar cria versão, ponteiro atual e recibo em transação. Mesmo pedido/dados não cria outra versão; pedido adulterado ou publicação sobre versão desatualizada falha. Rascunho não é utilizado nas propostas.

Regras do Firestore impedem introduzir/alterar os campos editoriais diretamente pelo SDK, inclusive como administrador, e impedem editar versões. Usuário autenticado pode consultar referências/versões, mantendo a política de leitura do catálogo existente. Administração cotidiana usa **Itens da Calculadora → Referências e modelos versionados**, com formulário, revisão, salvar rascunho e publicar. Não exige edição manual de documentos. Desativação continua disponível no CRUD administrativo existente; versões históricas permanecem.

Limites: leitura do catálogo até 500 documentos base, recusando excedente em vez de truncar; até 30 aliases/contextos por campo, 30 itens por modelo e payload editorial até 100 KB. Formatos/unidades/serviços desconhecidos exigem evolução explícita de schema/motor; referências para motor incompatível são ignoradas com aviso. Não se promete que qualquer nova fórmula rode em cliente antigo.

## Compatibilidade, migração e contingência

`CatalogoContextualLegado.propostas()` transforma referências locais, rendimentos e modelos existentes em propostas rastreáveis para revisão administrativa, preservando IDs e números/fontes do código. Não publica automaticamente. Os modelos antigos eram hipóteses do produto; sua fonte é a origem no código, sem fabricar fonte externa. O enquadramento de serviço/formato/público/obtenção é explicitamente apresentado como proposta editorial a revisar. As faixas de duração conhecidas dos salgados preservam 180–240 minutos e 30–40 minutos.

Datas de conferência já declaradas no código são conservadas como informação legada, com essa origem identificada. Nenhuma fonte externa foi consultada novamente nesta entrega, e não se afirmou nova verificação. Valores definidos pelo organizador não viram referências globais sem aprovação administrativa.

Os documentos básicos antigos e regras por tipo permanecem para clientes/adaptadores anteriores. A API legada de propostas continua como contingência local conhecida v1, identificada nos motivos e metadados; suas fórmulas/perguntas continuam cobertas pelos testes anteriores. O repositório de produção deste cliente sempre usa o catálogo contextual publicado; erro remoto não aciona essa tabela local. Sem consulta anterior válida, fica indisponível e sem novos números. Com consulta válida na mesma sessão, uma falha mantém apenas aquelas versões conhecidas com aviso explícito de contingência. Não há cache persistente novo nem fallback de preços.

O retorno de consulta é condicionado a usuário, evento, geração e identidade da consulta. Troca de contexto descarta respostas tardias. O snapshot do histórico inclui catálogo e regras utilizadas; a tela histórica não consulta/publica versões automaticamente.

## Arquivos envolvidos

- Domínio: `referencia_contextual.dart`, `catalogo_contextual_repository.dart`, `proposta_catalogo_service.dart`, `proposta_refeicao_service.dart`, `plano_evento_service.dart`, `plano_execucao_service.dart`, `rendimento_referencia_service.dart`.
- Dados/bootstrap: datasource e implementação do repositório de itens base, transporte autenticado compartilhado em `agenda_servico_remote.dart`, `catalogo_contextual_legado.dart`, `calculadora_bootstrap.dart`.
- Interface: parte `calculadora_festa_catalogo.dart`, controller/partes de proposta e execução, plano do evento, capacidade, proposta, editor manual e suas seções, `catalogo_contextual_admin_page.dart` e acesso na página administrativa existente.
- Backend: `catalogoContextualService.ts`, `editarCatalogoCalculadora.ts`, export em `index.ts`, validação de snapshots no executor e `firestore.rules`.
- Testes/harness: `catalogo_contextual_test.dart`, ajustes de criação/jornada/matriz para seleção explícita, `testCalculadoraPlanejamento.js`, `calculadora.rules.test.js`, `catalogo_contextual_emulator_test.dart`, `prepararCatalogoEmulador.js`, `testCatalogoDesktop.js`, `firebase.catalogo-test.json`.

## Validação executada

- `flutter test`: **631 testes aprovados**, saída 0 (`.dart_tool/catalogo-fulltests-final.log`). Uma primeira execução capturou a regressão de carregamento tardio; após a correção, a suíte inteira passou.
- `npm --prefix functions run check:calculadora`: **aprovado**, saída 0 (`.dart_tool/catalogo-functions-final3.log`), incluindo `tsc --noEmit` e validações novas de schema, identidade tipada, fonte, faixa, horário e duração editoriais.
- Regras Firestore em emulador: **Calculadora Firestore rules: OK**, saída 0 (`.dart_tool/catalogo-rules.log`). `PERMISSION_DENIED` nas tentativas negativas é esperado.
- `dart analyze` nos arquivos de domínio/dados/bootstrap e módulo calculadora, teste e integração: **No issues found**, saída 0 (`.dart_tool/catalogo-analyze-clean.log`). Análise complementar do editor manual realizada após o refinamento da invalidação de origem.
- `dart format` aplicado. `node --check` nos scripts novos e `git diff --check` nos arquivos envolvidos: aprovados.
- Windows com SDKs reais e callable de produção emulada: **1 teste aprovado**, `Catálogo SDK/Callable reais: OK`, saída 0 (`.dart_tool/catalogo-sdk.log`). Executou publicação v1/repetição, rascunho, negação a organizador, pedido adulterado, modelo novo, consumo pela calculadora, regra privada/histórico gravados, publicação v2, versão concorrente recusada e retomada preservando regra/histórico v1. Emuladores encerrados normalmente. CLI executou Node 24 em vez do Node 22 declarado e detectou ADC; as operações do teste usaram somente Auth/Firestore/Functions emulados no projeto demo.
- Depois do refinamento final do editor manual: **18 testes complementares aprovados**, saída 0 (`.dart_tool/catalogo-manual-final.log`). Incluem preservar um rendimento publicado ao salvar, invalidar a origem aplicada ao trocar a receita e manter a referência própria do organizador. São parcialmente os mesmos casos já presentes na suíte completa; não se somam como 18 casos exclusivos. Análise complementar: **No issues found** (`.dart_tool/catalogo-manual-analyze-final.log`).

Logs locais em `.dart_tool/catalogo-*` não são enviados para produção.

Os testes unitários/widgets cobrem escolha explícita, alimento desconhecido, incompatibilidade de serviço/horário/duração/público/obtenção, peso pronto versus compra crua, rendimento publicado escolhido, preservação após nova versão, propostas de migração sem aprovação, criação de composição configurada, contingência identificada, primeira falha indisponível e resposta tardia. O formulário administrativo é exercitado a 320 × 740 e fonte 1,3, com cancelamento sem gravação e erro/retry preservando campos e pedido. Substitutos desses testes não comprovam Firebase real.

O teste Windows executado usa SDKs reais Firebase Auth/Firestore, datasource/repositório de produção e a própria callable emulada. Verifica papel autorizado, rascunho fora das propostas, publicação/repetição, identidade adulterada, modelo novo, consumo no controller, gravação privada/histórico, publicação v2, retomada preservando regra e histórico v1 e bloqueio de gravação editorial direta. IA é substituto controlado; não se chama modelo externo.

## Reprodução e ativação futura

```powershell
flutter test
npm --prefix functions run check:calculadora
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
firebase emulators:exec --project demo-faca-festa-contexto --config firebase.calculadora-test.json --only firestore "node test/firestore/calculadora.rules.test.js"
node functions/scripts/prepararCatalogoEmulador.js
firebase emulators:exec --project demo-catalogo-contextual --config firebase.catalogo-test.json --only 'firestore,auth,functions' "node functions/scripts/testCatalogoDesktop.js"
```

Executar Flutter unit/widget e integração Windows sequencialmente para evitar conflito nos arquivos de plugins gerados. Harness fixa projeto demo, exige hosts Auth/Firestore locais e usa dados sintéticos; o aplicativo de teste inicializa Firebase demo e conecta os emuladores antes da autenticação. Override de callable é recusado em projeto real e em URL fora de loopback. A callable em modo emulado recusa projeto não demo/Firestore não local. Preparação grava somente artefatos ignorados em `.dart_tool/catalogo-functions`.

Ativação posterior, pelo processo normal: publicar backend e regras compatíveis antes do cliente; na administração, revisar as propostas legadas, conferir fontes/contextos e publicar as versões aprovadas. Confirmar o runtime Node 22 declarado: a máquina de teste tem Node 24, diferença que a CLI pode sinalizar. Não alterar documentos históricos ou regras confirmadas para adotar uma publicação nova. Nenhuma publicação em produção foi executada.

Não há homologação Android/iOS nem teste com modelo externo nesta entrega. Roteiro móvel pendente: consultar catálogo, criar/editar proposta com teclado/fonte ampliada, publicar por administrador, trocar de organizador, perder rede durante confirmação, repetir, consultar v2 e conferir receita/histórico v1. Esta entrega não declara a jornada inteira concluída.
