# Falha ao carregar a jornada

27/10/2026. Causa do ambiente confirmada em consulta somente de leitura: consultarJornadaAtendimentoFn, movimentarComercialJornadaFn e executarJornadaAtendimentoFn não estão publicadas no projeto faca-a-festa. As três existem e estão exportadas no código local, região southamerica-east1.

O SDK pode apresentar o erro de endpoint como internal. Havia também um defeito no gateway: retornar a Future HTTPS sem await dentro do try permitia que CallableHttpsException escapasse da conversão para FinanceiroCallableException. Isso impedia o controller de receber o código padronizado de serviço ausente.

## Correções locais

- await nos dois caminhos HTTPS do gateway, preservando conversão de erros inclusive no Windows.
- Em internal opaco da consulta consultarJornadaAtendimentoFn, a leitura pode consultar o mesmo endpoint HTTP para recuperar o diagnóstico. A regra não inclui comandos; teste confirma que fecharCotacao não é reenviada automaticamente em internal.
- Controller guarda código da falha de consulta, traduz internal e diferencia serviço ausente/permissão/sessão. Estado de execução ou aceite não é fabricado na falha.
- Página usa a moldura operacional com contraste correto, carregamento e estado de erro apropriados. Detalhes de suporte ficam recolhidos. Fluxos de proposta, execução, confirmação e reconciliação pendente são preservados.

## Verificação

```powershell
firebase functions:list --project faca-a-festa --json
flutter test test/data/services/jornada_gateway_test.dart test/features/cotacoes test/presentation/widgets/operacao test/features/financeiro/financeiro_contratos_unificado_test.dart test/features/agenda test/features/planejamento --reporter expanded
npm --prefix functions run build
firebase emulators:exec --config firebase.operacao-test.json --project demo-jornada-atendimentos --only firestore "node functions/scripts/testJornadaAtendimentosEmulator.js"
```

**55 testes aprovados**; build TypeScript e jornada real no Firestore Emulator aprovados (versões, contratação única, preparação, entrega, aceite/contestação, histórico, conversa autorizada, reputação/painel e regras). Análise Dart sem problemas. git diff --check aprovado. [Testes](flutter.txt), [emulador](emulador.txt), [análise](analyze.txt), [publicação consultada](publicacao.json).

A primeira execução do novo teste de transporte reproduziu a exceção HTTPS não convertida; após o await, o teste passou com o código not-found esperado. Sem enfraquecer a validação ou ocultar ausência do serviço.

Não houve deploy, commit, push, escrita em produção ou chamada em nome de usuário. O ambiente hospedado continua sem as Functions. A correção operacional exige publicação coordenada dos serviços compatíveis de jornada/proposta/contratação; publicar apenas a interface ou modificar o texto de erro não disponibiliza as operações. Uma publicação parcial deve considerar as versões das Functions existentes de responder/fechar cotação e acompanhamento financeiro.

## Correção da navegação da lista — 27/10/2026

Regressão confirmada no código: o link “Ver atendimento” da lista passou a encaminhar todas as solicitações à rota `/jornada-atendimento`. A conversa existente utiliza `ChatMensagensPage` e as consultas Firestore já presentes, independentemente da callable da jornada.

Correção: cartão clicável e link “Ver atendimento” abrem `ChatMensagensPage` com a cotação selecionada, fornecedor autenticado e data original. A abertura verifica a correspondência da sessão com o fornecedor atual. Responder e Gerar IA conservam suas ações; a jornada permanece separada, como “Jornada e execução”, para contratação ganha. Nenhuma regra de acesso ou estado comercial foi ampliado.

Arquivos desta correção:
- `lib/presentation/modules/fornecedor/sections/solicitacoes_section.dart`
- `lib/presentation/modules/fornecedor/components/acesso_atendimento.dart`
- `test/features/cotacoes/acesso_atendimento_test.dart`

Validação executada:

```powershell
flutter test test/features/cotacoes/acesso_atendimento_test.dart test/features/cotacoes/solicitacoes_controller_test.dart test/features/cotacoes/cotacao_repository_test.dart test/features/cotacoes/jornada_atendimento_test.dart
dart analyze lib/presentation/modules/fornecedor/components/acesso_atendimento.dart lib/presentation/modules/fornecedor/sections/solicitacoes_section.dart test/features/cotacoes/acesso_atendimento_test.dart
git diff --check -- lib/presentation/modules/fornecedor/sections/solicitacoes_section.dart
```

Resultado: 23 testes aprovados; análise sem problemas; diff sem erros de whitespace. Os três testes novos verificam navegação/retorno do componente clicável com destino sintético, independência dos botões de resposta/IA e ativação por teclado. A primeira execução encontrou ausência de AppBar no destino sintético do teste de retorno; a fixture foi corrigida e a suite repetida integralmente.

Limites: não foi executado teste autenticado no aplicativo conectado ao Firebase neste ajuste. Os testes novos não comprovam leitura real do chat nem publicação da jornada. A jornada continua sujeita à disponibilidade das Functions descrita acima; nenhum deploy foi realizado. A correção elimina essa dependência do acesso principal ao atendimento, sem simular carregamento da jornada.
