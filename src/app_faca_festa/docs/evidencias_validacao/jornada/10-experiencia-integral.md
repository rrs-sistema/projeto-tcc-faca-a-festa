# 10 — Ergonomia e intuitividade da jornada

Data: 20/10/2026. Trabalho sobre o estado local com as entregas anteriores, sem reset, deploy, commit, push ou migração destrutiva. Nenhuma instrução AGENTS.md foi encontrada nos diretórios aplicáveis.

## Diagnóstico reproduzido

A base já preservava formulário e estimativa em armazenamento local, vinculava o rascunho ao evento por transação e confirmava configurações/regras pelo repositório. Foram percorridos os pontos de entrada no cadastro, Home, calculadora e editores. Essas fundações foram reutilizadas.

Dois novos testes falharam antes da correção: o botão do cadastro não continha seu texto com fonte 2× em 320 px, e o modal transbordava em paisagem 640×360 com fonte 1,6× e inset de teclado de 150 px. Reprodução: `.dart_tool/p10-repro.log`. Também foram identificados aviso incorreto de estimativa “temporária”, erro de armazenamento local sem apresentação na tela, perda do pedido ao cancelar a transição texto→IA e ausência de resumo de contexto ao trocar etapas.

## Decisões e implementação

### Continuidade e efeitos das ações

- O cadastro continua progressivo: identidade, quando/onde e previsão. O tema visual de aniversário é opcional e não entra nas fontes de consumo. Formulário e rascunho existentes são reutilizados, sem acrescentar questionário alimentar obrigatório.
- A área do cadastro respeita o teclado, suas etapas voltam ao início da rolagem ao avançar/retornar e os botões crescem com o texto. “Guardar e sair” informa o efeito local existente; “Salvar evento”/“Atualizar evento” confirmam o cadastro remoto. Fechar o cadastro preserva o rascunho local; não confirma o evento.
- A calculadora apresenta contexto em todas as etapas: identidade do evento/rascunho/histórico, público e origem, período, duração, limite total, verba alimentar e serviços. Detalhes e fontes ficam em expansão progressiva. Dados de outro evento ativo não são usados no resumo de um rascunho ou evento diferente. Zero informado permanece diferente de ausência; fonte indisponível oferece recuperação.
- “Salvar histórico” identifica a ação que cria uma simulação salva; “Salvar porção e preço” identifica a confirmação de regra no evento. A aplicação de escolhas pelo texto explica quando grava no planejamento e quando apenas aplica à estimativa.
- O estado de armazenamento da estimativa só anuncia confirmação após concluir a gravação. Falha mantém valores, mostra erro acessível e oferece “Tentar guardar novamente”. Versão de tentativa e sessão impedem que um retorno antigo anuncie confirmação de uma edição mais recente.
- A leitura por IA abre sobre o pedido por texto. Cancelar/fechar a leitura devolve o mesmo editor e texto, sem aplicar. Campos editados invalidam a proposta; confirmação segue pelos serviços existentes. Seleção de arquivo, preparação e aplicação verificam a sessão original.
- Salvar preço captura a sessão e geração de preparação: resposta de um acesso anterior não substitui a edição feita ao reabrir o mesmo evento. O retorno da revisão também verifica esse contexto.

### Componentes e acessibilidade

`CalculadoraModal` é reutilizado no texto, leitura inteligente, preço e nos editores de operação que já o utilizavam. Mantém fechamento acessível, conteúdo rolável, cores do tema e alvos de pelo menos 48 px. Em pouca altura, o título integra a rolagem e, quando necessário, as ações também podem ser alcançadas pela rolagem. Não reduz a escala de texto para esconder overflow. O campo de preço preserva foco/revelação automática; erros de rede não descartam o valor.

`CadastroPassosAcoes` empilha as ações em largura reduzida ou fonte ampliada e usa altura mínima, sem altura máxima ou corte em uma linha. Contraste do botão principal é calculado para preto/branco e aplicado também ao ícone/indicador. Os campos de preço usam superfície do tema.

Arquivos de produção deste escopo:

- `lib/presentation/widgets/cadastro_passos_bar.dart`
- `lib/presentation/modules/usuario/pages/cadastro_evento_bottom_sheet.dart`
- `lib/presentation/modules/calculadora/pages/calculadora_festa_screen.dart`
- `lib/presentation/modules/calculadora/pages/calculadora_regra_manual_dialog.dart`
- `lib/presentation/modules/calculadora/widgets/calculadora_modal.dart`
- `lib/presentation/modules/calculadora/widgets/calculadora_contexto_card.dart` (novo)
- `lib/presentation/modules/calculadora/widgets/calculadora_comando_texto_dialog.dart`
- `lib/presentation/modules/calculadora/widgets/calculadora_entrada_inteligente_dialog.dart`
- `lib/presentation/modules/calculadora/controllers/calculadora_festa_operacao.dart`
- `lib/presentation/modules/calculadora/sections/calculadora_festa_layout.dart`
- `lib/presentation/modules/calculadora/sections/calculadora_festa_planejamento.dart`

Testes/harness: `test/features/calculadora/ergonomia_jornada_test.dart`, `ajustes_manuais_persistencia_test.dart`, ajustes de navegação em `calculadora_jornada_test.dart`/`calculadora_criacao_jornada_test.dart`, assentamento da rolagem em `calculadora_operacao_evento_test.dart`, seletores dos campos atuais em `configuracao_duravel_test.dart`, `integration_test/ergonomia_planejamento_emulator_test.dart` e `functions/scripts/testErgonomiaDesktop.js`. Os testes antigos passam a localizar a rolagem principal explicitamente e aguardar seu assentamento; nenhuma asserção funcional foi retirada.

## Persistência, compatibilidade e cancelamento

Sem novo schema, coleção, índice ou regra de acesso. O resumo lê as fontes do controller; não mantém um novo cadastro paralelo. Identidade/período do cadastro são parâmetros de apresentação da estimativa. Escolhas e preços continuam em `calculadora_operacao/{evento}` pelos comandos e transações existentes. Histórico e quantidade final não são sobrescritos pela confirmação de porção/preço. O rascunho local continua usando o armazenamento durável implementado anteriormente.

Cancelar editores de texto, IA e preço não confirma alterações. O cadastro já possui preservação local automática; a ação de saída foi rotulada para explicitar isso. Não há confirmação remota implícita ao sair. Nenhuma ação envia mensagem, contrata, paga ou marca compra como realizada sem revisão específica.

## Validação e revisão visual

- Integração nativa Windows: **1 teste aprovado**, com Firebase Auth e Firestore reais dos emuladores. O editor por texto exige revisão antes de gravar público/duração; o preço confirmado é recuperado após reabrir. Resultado: `.dart_tool/p10-native.log`.
- Validação do backend existente: `npm --prefix functions run check:calculadora` **aprovada**, sem alteração de backend nesta entrega. Resultado: `.dart_tool/p10-backend.log`.
- Regressão completa: **666 testes Flutter aprovados**, em 3 min 32 s, incluindo os sete novos cenários de ergonomia e a proteção contra resposta tardia de preço. Resultado: `.dart_tool/p10-full-final.log`.
- Análise estática dos arquivos de produção/teste envolvidos: **sem problemas encontrados**. Resultado: `.dart_tool/p10-analyze-final.log`. Formatação aplicada; `git diff --check` sem erros de espaço.

As quatro capturas abaixo foram abertas e inspecionadas visualmente. O campo de preço, inclusive rótulo e valor, permanece visível em paisagem com teclado; erro mantém o preço e apresenta nova tentativa. A revisão por texto preserva fechamento e ação; o resumo do rascunho quebra linhas com fonte ampliada. Conteúdo adicional continua acessível por rolagem.

- [Preço em paisagem e teclado](10-capturas/preco-paisagem-teclado.png)
- [Falha recuperável de preço](10-capturas/preco-falha-retomavel.png)
- [Revisão por texto com teclado](10-capturas/texto-revisao-teclado.png)
- [Contexto do rascunho com fonte ampliada](10-capturas/contexto-rascunho-fonte-ampliada.png)

Na retomada, foi necessário recompilar o cache de testes que não avançava. Os ajustes finais dos testes preservam as verificações funcionais: aguardar rolagem terminar, usar os rótulos atuais e retornar ao início antes de procurar a confirmação do rascunho em uma lista com montagem progressiva. Nenhum teste foi desativado.

Capturas são produzidas pelo Flutter a partir dos widgets de produção renderizados; os testes visuais usam fontes reais e substitutos identificados para repositórios, não imagens de demonstração. Teclado nesses testes é inset simulado: não representa homologação de IME de Android/iOS. A integração Windows usa Auth/Firestore reais dos emuladores para provar a ligação dos editores com persistência, não substitutos de transação.

Comandos reproduzíveis, a partir da raiz:

```powershell
$env:CALCULADORA_QA_CAPTURE='1'
flutter test test/features/calculadora/ergonomia_jornada_test.dart
flutter test
npm --prefix functions run check:calculadora
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
firebase emulators:exec --project demo-ergonomia10 --config firebase.calculadora-test.json --only 'firestore,auth' "node functions/scripts/testErgonomiaDesktop.js"
```

O harness recusa hosts que não sejam loopback e usa projeto fixo `demo-ergonomia10`. O catálogo e a IA dos testes nativos são fixtures de suporte: a IA não é chamada. O que se verifica com integração real são formulário de texto/preço, autorização, gravação transacional e retomada do documento operacional. Rodar integração Windows e suíte Flutter em sequência para não disputar os artefatos de compilação.

## Limitações e ativação posterior

Não foi feita homologação com teclado físico/IME de Android/iOS nem verificação de produção. O desktop pode emitir os avisos conhecidos LNK4099 de PDB ausente nas bibliotecas Firebase; não são prova de falha funcional. O host Node é 24; não declarar homologação do runtime Node 22 de produção com base nesses testes.

Ativação posterior: revisar o diff junto das entregas anteriores e gerar/distribuir o cliente atualizado conforme o processo do projeto. Este escopo não exige migração nem implantação de backend. Nenhuma publicação foi executada. A evidência se limita ao Prompt 10 e não declara toda a jornada encerrada.
