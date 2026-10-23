# 12 — Homologação pelo cadastro e retomada real

Execução: 21/10/2026, Windows, fuso `America/Sao_Paulo`. Base Git
`7419d28c34081ae0d15a2da5c85a5704bf39410b`, com alterações locais anteriores
dos prompts 01–11 preservadas. Não houve commit, push, deploy ou escrita em
projeto Firebase real.

## Situação da entrega

A matriz coberta por esta entrega foi executada em emuladores demo e na interface
Windows do roteiro principal. O aparelho Android já autenticado comprovou a
consulta real de CEP e a navegação do cadastro, sem gravar evento remoto.
Provedor real de IA (OpenAI via Secret Manager), login e-mail/senha pela
`LoginScreen` com Auth emulador, o grupo 6 de receitas/referências, Google
Sign-In pela `LoginScreen` (remote injetável + Auth emulador) e MFA TOTP
(UI real + callables no emulador) foram fechados nesta continuação. Isso
ainda não homologa iOS, o seletor OAuth Google real no dispositivo, MFA por
e-mail (SMTP) nem a jornada em todas as plataformas. Os critérios ainda
abertos permanecem na seção de pendências; não foram marcados como aprovados.

## Diagnóstico e correções

O roteiro anterior `jornada_calculadora_aparelho_test.dart` inicia o evento pelo
repositório e recria controllers. Continua útil como suplemento, mas seu nome e
comentários agora explicitam esse alcance. Não comprova cadastro pela interface
nem encerramento do processo.

O roteiro novo usa a composição de produção (`FacaFestaApp`, rotas, controllers,
repositórios, SDKs e arquivos). Encontrou defeitos ausentes nesse roteiro antigo:

1. Selecionar Corporativo e abrir o formulário limpava novamente o tipo escolhido.
   Os campos específicos desapareciam. A inicialização preserva tipo e endereço;
   retomar rascunho e editar evento continuam usando seus próprios dados.
2. Uma negativa no commit da transação do FlutterFire desktop chegava pelo stream
   nativo sem concluir o Future aguardado pelo cadastro. O adaptador
   `executarTransacaoFirestore` entrega também essa falha ao chamador, sem repetir
   gravação ou anunciá-la como sucesso. O cadastro mantém o evento confirmado e
   a estimativa pendente. Há regressão para esse canal assíncrono e negativa real
   no emulador.
3. O retorno da seleção de tipos substituía pela Home a calculadora aberta ao
   concluir o cadastro. Agora só redireciona se ainda está na rota de origem.
   Voltar da calculadora concluída retorna à Home, conferindo usuário, evento e
   rota antes da navegação.
4. A URI explícita do planejador no emulador não era encaminhada ao executor.
   O datasource encaminha a mesma configuração local ao protocolo de execução;
   a proteção de projeto demo/loopback permanece ativa.
5. A entrada assistida chamava um canal nativo de Functions indisponível no
   Windows (`CloudFunctionsHostApi.call`). O caminho padrão agora reutiliza o
   protocolo callable HTTPS autenticado já usado pelo planejador. A análise
   automática no bootstrap Windows usa `CallableHttpsClient`, também existente.
   O leitor continua exigindo revisão e confirmação; o servidor continua
   verificando proprietário, assinatura e repetição.

A expectativa de verba já estava corrigida no código encontrado: simular não
grava; `Usar esta verba` confirma. A validação desta entrega precisa executar
novamente esse contrato; não se atribui essa correção ao prompt 12.

O editor de regra já descartava `Cancelar` e `Fechar` sem chamar a gravação, e
só persistia em `Salvar porção e preço`. O suplemento de ergonomia confirmava o
preço, mas não comparava o documento depois de editar e desistir. Não houve
defeito de produção nesse caminho. A prova que faltava usa o diálogo e
`salvarItemManual` reais, com Auth, regras e Firestore do emulador
`demo-regras12`. O catálogo base e o extrator continuam sendo os substitutos
já existentes; a mensagem de log “Itens carregados do Firestore” é texto fixo
do controller e não significa que esses cinco itens tenham vindo do banco. O
cardápio `Arroz` consultado na transação foi semeado no emulador.

## Arquivos desta entrega

Produção: `lib/presentation/modules/usuario/pages/cadastro_evento_bottom_sheet.dart`,
`lib/presentation/modules/eventos/pages/welcome_event_screen.dart`,
`lib/data/services/transacao_firestore.dart`,
`lib/data/datasources/remote/calculadora_festa_remote_datasource.dart`,
`lib/data/datasources/remote/agenda_servico_remote.dart` e
`lib/app/bootstrap/calculadora_bootstrap.dart`.

Homologação: novo `integration_test/homologacao_cadastro_retomada_test.dart`,
`firebase.homologacao12-test.json`, scripts `prepararHomologacao12.js`,
`testHomologacao12Desktop.js`, `testHomologacao12Complementos.js`,
`testHomologacao12FalhaIntermediaria.js`, `testEditorRegrasDesktop.js` e
`testLoginDesktop.js` em `functions/scripts/`; regressões
`transacao_firestore_test.dart`, `homologacao_matriz12_test.dart`,
`homologacao_receitas12_test.dart` e o caso de cancelar/fechar em
`calculadora_regra_manual_dialog_test.dart`; confirmação de alcance/visibilidade
e nova captura em `ergonomia_jornada_test.dart`. O suplemento de persistência
do editor é `integration_test/editor_regras_persistencia_emulator_test.dart`.
O login pela interface é `integration_test/login_interface_emulator_test.dart`
(Auth emulador `demo-login12`). Google é
`integration_test/login_google_interface_emulator_test.dart` (`demo-google12`).
MFA TOTP UI/sessão:
`test/features/auth/mfa_totp_interface_test.dart` e
`app_totp_sessao_test.dart`; backend:
`functions/scripts/testTotpMfaEmulator.js` com
`firebase.mfa12-test.json` / `prepararMfa12.js`. O provedor real de IA
reutiliza `functions/scripts/testEntradaModelo.js --sintetico`. O roteiro
antigo e seu script recebem somente identificação de alcance e proteção
adicional de loopback. `LoginController` aceita `SessaoLoginPort` injetável.

Nenhuma regra de produção ou implementação TypeScript de negócio foi alterada
neste prompt. O backend usado é o que já existe no workspace, identificado por
hash e novamente compilado/testado.

## Roteiro principal e fronteiras

`integration_test/homologacao_cadastro_retomada_test.dart`, orquestrado por
`functions/scripts/testHomologacao12Desktop.js`:

1. Home → Mais → Trocar festa → Novo evento → Corporativo. Preenche o formulário,
   abre a estimativa sem orçamento, verifica que a outra festa de 999 pessoas
   não foi usada, volta, edita público/limite e guarda o cadastro.
2. Em outro processo, retoma o formulário e salva o evento. Uma regra
   **mais restritiva**, somente no emulador, impede criar o vínculo. Confere um
   evento e nenhum histórico, preservando a mesma identidade e o arquivo local.
3. Restaura as regras originais, abre outro processo e conclui o vínculo pela
   interface. Confere um histórico inicial. Uma repetição suplementar pelo SDK,
   com outra duração, verifica que esse histórico não é sobrescrito.
4. Em outro processo, entra pela Home sem abrir histórico. Cancela e confirma
   público manual, duração, perfil, margem e verba. Escolhe referência sintética,
   revisa e cria o cardápio, revisa a execução e aplica explicitamente o conjunto.
5. Em outro processo, abre pela Home, confere configurações, execução e histórico
   inicial preservados. Revisa texto e interpretação determinística antes de
   confirmar, comparando o estado persistido das escolhas.

Cada fase registra PID. O orquestrador verifica no SO que ele já não existe antes
de iniciar a seguinte. Não chama `Get.reset()` para simular encerramento. A
autenticação em cada novo processo usa SDK Auth com conta sintética do emulador;
login/MFA pela interface não são objetos desta prova.

O evento-alvo e seu cardápio **não são semeados**. As fixtures de apoio são conta
organizadora sintética, tipos, município fictício, outra festa ativa e duas
referências editoriais identificadas. No roteiro Windows, CEP é resposta HTTP
determinística local; a consulta real foi feita depois, no aparelho.
GPS físico é desligado. A interpretação substitui somente o extrator externo,
usando preparação, revisão e aplicação de produção em Functions/Firestore reais
emulados. Esse roteiro principal não homologa OpenAI, a consulta real de CEP,
envio de mensagens ou serviços externos; esses itens têm provas separadas
abaixo. Nenhuma chave pessoal é incluída nas fixtures.

Os complementos antigos de público e financeiro usam SDK Auth/Firestore reais
nos repositórios sob teste, mas mantêm `AiQA`, `BaseJornada` e um substituto de
Storage não exercitado. Seus resultados valem para público/financeiro; não são
evidência de IA, catálogo, upload ou composição integral. O roteiro principal
novo não usa esses substitutos. Na recuperação suplementar da execução, a
resposta é descartada **depois do commit real**, para reproduzir perda de resposta;
o recibo é então consultado no Firestore por outro adaptador com arquivos reais.

## Persistência e compatibilidade

Não há novo schema de negócio nem migração de produção nesta entrega.

- Cadastro local v2: arquivos duráveis, separados por organizador e identidade.
- Vínculo: `evento/{id}` e `calculadora_festa/{idEstavel}`, com origem do rascunho;
  criação transacional e repetição sem substituir o snapshot existente.
- Escolhas correntes: `calculadora_operacao/{idEvento}`, envelope v1, revisão e
  `configuracao_planejamento`. Limite total continua no evento.
- Execução: operação, sugestões dos itens, tarefas e recibo em
  `calculadora_operacao/{idEvento}/aplicacoes/{pedido}`. Aplicar planejamento não
  registra compra positiva, contratação ou pagamento. A declaração explícita
  de não ter comprado grava zero nos itens sem disponibilidade informada.
- Referências sintéticas: schema 1, leitor/motor mínimo 1, versão editorial 1,
  fonte `example.test`, aprovação identificada como fixture.

## Matriz obrigatória — alcance das evidências

| Grupo | Evidência executável | Classificação e limite |
|---|---|---|
| 1. Cadastro/rascunho/vínculo | Roteiro principal, arquivos, PIDs, consultas Firestore e repetição do vínculo | UI Windows + SDK/regras reais; resultados finais abaixo |
| 2. Público | `publico_planejamento_test.dart`, `publico_planejamento_emulator_test.dart`: 40 previstos/lista parcial, bases, zero, manual, legado e remoto | Domínio e suplemento SDK; não confundir lista nominal com previsão |
| 3. Fontes | Testes de jornada/contexto/composição: carregamento, vazio, erro, desatualizado, resposta tardia; `plano_evento_test.dart` impede menu em consulta incompleta | Testes determinísticos; interrupção real de vínculo no roteiro principal |
| 4. Escolhas | UI principal cancela e confirma verba, perfil, margem, base e duração, e retoma sem abrir histórico; texto e extrator determinístico; editor de regra no emulador `demo-regras12`; provedor real OpenAI em `testEntradaModelo.js --sintetico` | Widget de cancelar/fechar não prova Firestore. IA real cobre texto/PDF/PNG/TXT sintéticos; não é a UI do leitor no aparelho |
| 5. Contextos | `homologacao_matriz12_test.dart`: infantil, casamento, corporativo, retiro, churrasco e livre sem fallback; 3 intervalos e 4 ocorrências em dois dias com públicos distintos; `agenda_ocorrencias_test.dart` | Motor real determinístico; UI principal corporativo, sem reivindicar UI dos seis contextos |
| 6. Receitas/referências | `homologacao_receitas12_test.dart` (11 casos): receita própria, ingrediente/preço ausente, cru/pronto, embalagem/unidade, referência nova, restrição sem composição e catálogo indisponível | Domínio e cálculo reais; não é a UI completa de composição no Windows/Android |
| 7. Financeiro/estoque | Execução, compromissos, capacidade e financeiro; suplemento financeiro SDK | Estoque comum, buffet, preço pendente, grupos e valores cotado/contratado/comprado/pago são distintos |
| 8. Repetição/conflito/migração | Vínculo repetido, execução/revisão autenticadas, recuperação SDK, entrada e migração/governança em emuladores | Conferir resultados novos abaixo; não usar números de relatórios anteriores |
| 9. Ergonomia/retorno/indisponibilidade | UI principal e `ergonomia_jornada_test.dart`: teclado, fonte, paisagem, controles alcançáveis e falha recuperável | Geometrias móveis em widget tests; não comprova teclado/gestos de Android/iOS físico |

## Resultados desta execução

| Verificação | Resultado desta rodada |
|---|---|
| `flutter test`, fontes finais e captura habilitada | **682 passaram**, 0 falhas; execução de 21/10/2026, 07:43–07:44. Não inclui o suplemento do editor, acrescentado depois |
| Análise estática dos arquivos Dart do editor (`editor_regras_persistencia_emulator_test.dart` e `calculadora_regra_manual_dialog_test.dart`) | **Sem problemas**, 21/10/2026 |
| Widget do editor, incluindo cancelar e fechar sem chamar gravação | **5 passaram**. Não usa Firestore |
| `npm --prefix functions run check:calculadora` e build TypeScript | **Passaram** |
| Regras da calculadora | **Passaram**; negativas de acesso esperadas não são falhas |
| Entrada assistida em Firestore emulado | **67 verificações passaram**; extrator determinístico |
| Confirmação assistida de verba | **Passou**, com origem/data, repetição e nenhuma despesa/pagamento criado |
| UI Windows do cadastro à retomada (`p12-ui-final-cobertura.log`, 08:03) | **Passou**. Cadastro pela interface, interrupção do vínculo, confirmação das escolhas, aplicação e retomada sem abrir histórico |
| Público SDK (`p12-publico-sdk.log`, 08:04) | **Passou** |
| Financeiro, verba e capacidade SDK (`p12-financeiro-sdk.log`, 08:05) | **Passou** |
| Execução e revisão autenticadas (`p12-execucao-backend.log`, 08:06) | **78 verificações passaram** |
| Execução SDK Windows e recuperação (`p12-execucao-sdk.log`, 08:07) | **Passou** |
| Migração e governança (`p12-migracao-regras.log`, 08:07) | **Passou**: dry-run sem escrita, aplicação dupla, conflito, reversão, isolamento e catálogo |
| Falha intermediária da transação (`p12-execucao-falha-intermediaria.log`, 08:08) | **6 verificações passaram**: nada parcial no banco, nova tentativa e repetição com um recibo |
| Ergonomia dos editores (`p12-ergonomia-sdk.log`, 08:12) | **Passou** a confirmação de texto e de preço. Não cobre desistir da regra |
| Editor de regra com persistência real, projeto `demo-regras12`, 21/10/2026 | **Passou** no Windows com Auth e Firestore do emulador. Admin releu o mesmo estado |
| Provedor real de IA (`node functions/scripts/testEntradaModelo.js --sintetico`), 21/10/2026 | **Passou**. Texto distingue compra, preço, cotação e ausência de pagamento; PDF/PNG/TXT extraem cotação e ignoram instrução maliciosa sem criar pagamento |
| Login pela interface (`demo-login12` + `testLoginDesktop.js`), 21/10/2026 | **Passou** no Windows: validação local, senha errada com aviso e retomada do formulário, login correto, saída e novo login |
| Grupo 6 receitas/referências (`homologacao_receitas12_test.dart`), 21/10/2026 | **11 passaram**: receita própria, ingrediente/preço ausente, cru/pronto, embalagem/unidade, referência nova, restrição sem composição e catálogo indisponível |
| Google Sign-In pela interface (`demo-google12` + `testLoginGoogleDesktop.js`), 21/10/2026 | **Passou** no Windows: cancelar sem sessão, falha `clientConfigurationError` com aviso, sucesso com Auth emulador e marca de login Google |
| MFA sessão (`app_totp_sessao_test.dart`), 21/10/2026 | **3 passaram**: senha exige MFA; Google não exige; conta sem password não exige |
| MFA TOTP UI (`mfa_totp_interface_test.dart` + `testMfaTotpDesktop.js`), 21/10/2026 | **Passou**: setup (QR, código errado, confirmação) e desafio (errado e entrada) nas telas reais |
| MFA TOTP backend (`demo-mfa12` + `testTotpMfaEmulator.js`), 21/10/2026 | **10 verificações passaram**: iniciar/cifrar, código errado, confirmar, flags em `usuarios`, desafio e reuso |

Capturas novas foram geradas em 21/10/2026 e inspecionadas. O campo e o botão não
precisam ocupar simultaneamente a pequena área disponível: ambos são alcançáveis
por rolagem, com hit test e interação verificados. Exemplos:
[campo de preço em paisagem](12-capturas/preco-paisagem-teclado.png),
[ação de confirmação após rolagem](12-capturas/preco-acao-paisagem-teclado.png),
[revisão de texto](12-capturas/texto-revisao-teclado.png).

## Versões

- App `1.0.14+16`; motor de compatibilidade 6; proposta de refeição 1.
- Flutter `3.27.2`, revisão `68415ad1d9`; Dart `3.6.1` (comandos desta execução).
- Backend: TypeScript do workspace, `tsc --noEmit`/build locais; Node host 24,
  enquanto `functions/package.json` declara Node 22. A diferença fica registrada;
  a equivalência ao runtime hospedado Node 22 não é afirmada.
- Regras, locks, fontes alteradas e manifesto do backend:
  [versões e hashes SHA-256](12-versoes.json). SDKs do lock: Firestore 6.4.1,
  Auth 6.5.1, Core 4.9.0, Functions 6.3.1. Java 21.0.6; Firebase CLI 15.10.0.

## Reproduzir sem publicar

Executar os comandos Flutter **em sequência**, pois o registrador de plugins do
Windows é compartilhado pelo build. Uma tentativa simultânea de captura e build
nativo nesta rodada produziu `PathAccessException`; deve ser repetida em série,
sem tratar a tentativa abortada como resultado aprovado.

```powershell
$env:JAVA_HOME = 'C:/Program Files/Android/Android Studio/jbr'
$env:Path = "$env:JAVA_HOME/bin;$env:Path"
$env:FUNCTIONS_DISCOVERY_TIMEOUT = '120'
node functions/scripts/prepararHomologacao12.js
firebase emulators:exec --project demo-jornada12 --config firebase.homologacao12-test.json --only 'firestore,auth,functions' 'node functions/scripts/testHomologacao12Desktop.js'
flutter test
npm --prefix functions run check:calculadora
npm --prefix functions run build
```

Para executar a matriz autenticada completa, após preparar a composição QA12 e
gerar a fixture pelo `flutter test`, usar:

```powershell
node functions/scripts/testHomologacao12Complementos.js
```

Esse orquestrador inclui o roteiro UI e os suplementos, em série, reiniciando
emuladores com o projeto demo de cada caso. `QA12_COMPLEMENTOS` permite repetir
apenas um caso pelo nome registrado no resultado JSON; seleção desconhecida é
recusada e a execução filtrada é marcada como parcial. Os casos novos incluem
`editor-regras-sdk` e `login-interface`. No PowerShell, a vírgula de `--only`
precisa de aspas:

```powershell
firebase emulators:exec --project demo-regras12 --config firebase.homologacao12-test.json --only 'firestore,auth' "node functions/scripts/testEditorRegrasDesktop.js"
firebase emulators:exec --project demo-login12 --config firebase.homologacao12-test.json --only 'firestore,auth' "node functions/scripts/testLoginDesktop.js"
firebase emulators:exec --project demo-google12 --config firebase.homologacao12-test.json --only 'firestore,auth' "node functions/scripts/testLoginGoogleDesktop.js"
node functions/scripts/testMfaTotpDesktop.js
node functions/scripts/prepararMfa12.js
firebase emulators:exec --project demo-mfa12 --config firebase.mfa12-test.json --only 'firestore,auth,functions' "node functions/scripts/testTotpMfaEmulator.js"
node functions/scripts/testEntradaModelo.js --sintetico
flutter test test/features/calculadora/homologacao_receitas12_test.dart
```

Os scripts recusam destinos fora de loopback e o roteiro principal exige o
projeto exato `demo-jornada12`. As URI locais são injetadas em datasources reais,
sem alterar a configuração Firebase de produção. `QA12_RETOMAR=1` e `QA12_FASES`
servem ao diagnóstico: exigem importar o mesmo checkpoint dos emuladores e manter
os arquivos locais. Uma execução limpa final deve percorrer todas as fases.

As correções Flutter podem seguir o processo normal de revisão/build posterior.
As Functions temporárias estão em `.dart_tool`, somente para emulador; não devem
ser publicadas. Não é necessário migrar dados de produção para ativar as
correções desta entrega.
Antes de disponibilizar o app, conferir a disponibilidade das Functions de
negócio já existentes e a configuração dos provedores. Esta sessão não verificou
nem alterou essa disponibilidade em produção.

## O que o editor de regra comprovou

No projeto `demo-regras12`, com regras reais e cache local desligado:

- Carregar a operação não altera o documento.
- Editar preço e consumo e tocar `Cancelar` devolve o diálogo sem gravação.
  A regra continua 5,75 por kg e 0,05 por convidado, na memória e no banco.
- Editar de novo e tocar `Fechar` também não grava. Evento, configuração e
  histórico aprovado permanecem iguais.
- `Salvar porção e preço` grava uma única regra: preço 8,50 e consumo 0,08,
  revisão 2. Não cria aplicação, compra ou pagamento e não muda o limite do
  evento nem o histórico `calculadora_festa/hist-regras12`.
- Reabrir o controller, sem contexto de histórico, recupera esses valores.
- Confirmar outra vez mantém uma regra só, com o mesmo preço e consumo.
- Outro usuário autenticado recebe `permission-denied` ao ler e ao tentar
  atualizar. A releitura do organizador e a releitura pelo Admin SDK mostram
  o mesmo documento.

## Aparelho Android e CEP real

Em 21/10/2026, o Samsung SM-G990E já autenticado, pacote
`com.rrs.system.technology.facafesta`, rede móvel do aparelho. Não houve
instalação de build novo, deploy nem gravação remota de evento.

Pela interface: Mais → Trocar festa → Novo evento → Evento corporativo.
O formulário instalado mostrou só o título; o campo “Empresa ou setor”,
presente no código deste workspace, não apareceu. O aplicativo do aparelho
não é a build local desta entrega.

No passo “Quando e onde”, o CEP `81490398` foi digitado com o teclado aberto.
A consulta real preencheu logradouro, bairro Campo de Santana, cidade Curitiba
e UF PR. O número permaneceu vazio; a consulta não inventou número. Sem
número, Continuar ficou no mesmo passo e exibiu “Informe o número (ou S/N)”.
Sem data, o mesmo bloqueio exibiu “Informe a data do evento”. Com número `100`
e data `21/10/2026`, o passo de convidados abriu. “Salvar evento” não foi
acionado. A festa que já estava ativa permaneceu a mesma, com os mesmos
previstos e o mesmo limite.

Fechar o formulário guardou somente no aparelho o rascunho “Homologacao CEP”.
Ele reaparece em “Continuar um cadastro?” e pode ser descartado pela lixeira
desse diálogo. Não é um evento remoto.

## O que o login pela interface comprovou

No projeto `demo-login12`, com Auth e Firestore do emulador e viewport de
celular forçada no Windows:

- A `LoginScreen` real exibe e-mail, senha, Entrar, Google e recuperação.
- E-mail inválido não autentica e não marca sessão.
- Senha errada abre o aviso, fecha sem sessão e permite preencher de novo.
- Senha correta autentica no emulador, garante perfil organizador, marca login
  com senha e navega para `/splash`.
- Após `sair`, `Get.offAllNamed('/login')` retoma o formulário e autentica de
  novo.

## O que o Google Sign-In pela interface comprovou

No projeto `demo-google12`, com Auth emulador. O seletor OAuth real não roda
no Windows de teste; o remote QA injeta cancelar, falha e sucesso, mantendo a
`LoginScreen` e a sessão Auth reais:

- “Entrar com Google” é alcançável.
- Cancelar não autentica; marca login Google uma vez (mesmo padrão da senha).
- `clientConfigurationError` abre o aviso “Google indisponível” sem sessão.
- Sucesso autentica no emulador, garante perfil organizador, marca Google e
  navega para `/splash` sem marcar senha.

## O que o MFA TOTP comprovou

UI (`TotpSetupScreen` / `TotpVerifyScreen` + `TotpMfaController`):

- Setup: escolha do autenticador, QR/chave, código errado, confirmação e splash.
- Desafio: código errado e código certo com `marcarTotpVerificado` e splash.
- Sessão: login Google não exige MFA; login senha exige até verificar; conta
  sem provedor de senha não exige.

Backend (`iniciarTotpMfa` / `confirmarTotpMfa` / `verificarTotpMfa` no emulador
`demo-mfa12`, com `PASSWORD_RESET_SECRET` local):

- Sem secret pendente, confirmar falha com `failed-precondition`.
- Iniciar grava `mfa_totp/{uid}` cifrado, pendente e inativo.
- Código errado: `permission-denied`; código TOTP válido confirma, ativa o
  documento e define `mfa_totp_ativo` / `mfa_metodo: totp` em `usuarios`.
- Desafio com código válido passa; iniciar de novo após ativo permanece ok.
- Correção: `FieldValue` importado de `firebase-admin/firestore` (o namespace
  `admin.firestore.FieldValue` quebrava na composição transpile do emulador).
- Navegação MFA: sucesso marca verificado e vai ao splash antes do
  `EasyLoading.dismiss`, para falha de overlay não bloquear a entrada.

## O que o provedor real de IA comprovou

`testEntradaModelo.js --sintetico` usa o provedor OpenAI configurado no
ambiente (Secret Manager), sem fixtures de extrator:

- Texto: compra parcial de arroz cru, preço por kg e cotação de decoração sem
  contratação/pagamento.
- PDF, PNG e TXT: cotação identificada; instrução maliciosa de pagamento é
  ignorada; nenhum pagamento é autorizado.

## O que o grupo 6 comprovou

`homologacao_receitas12_test.dart` exerce serviços de domínio reais:

- Receita própria revisada não é substituída por referência editorial nova.
- Ficha sem ingredientes ou incompatível não inventa grão, água nem preço.
- Compra pronta não vira crua; crua exige rendimento medido.
- Embalagem arredonda a necessidade; unidade/embalagem da regra própria seguem
  no cálculo e na lista de compras.
- Referência nova publicada não reescreve regra confirmada; rendimento
  compatível converte compra crua sem nome fechado.
- Restrição sem composição conferida e catálogo indisponível permanecem
  pendentes, sem inventar adequação.

## Pendências

iOS não foi usado. O seletor OAuth Google real (conta Google no aparelho/web)
e o MFA por e-mail (SMTP) não foram exercitados; a prova Google usa remote
injetável com sessão Auth emulada, e a prova MFA cobre TOTP. A sessão Android
já estava autenticada quando o CEP foi conferido. A interface principal no
Windows exercitou o contexto corporativo; no aparelho, o campo específico
desse tipo não estava na build instalada. O grupo 6 fechou o domínio e o
cálculo, não a UI completa de composição no aparelho. Não se declara a
jornada inteira homologada em todas as plataformas.
