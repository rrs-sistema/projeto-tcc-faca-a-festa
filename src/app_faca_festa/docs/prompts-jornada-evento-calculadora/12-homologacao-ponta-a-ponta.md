# Prompt 12 — Homologação integral pelo cadastro e retomada real

Atue como engenheiro sênior Flutter/Firebase e analista de negócio de eventos. Implemente esta entrega no aplicativo Faça a Festa; não se limite a sugerir um plano ou produzir documentação.

Repositório: `D:\repository\unicesumar\tcc\app\src\app_faca_festa`. Ambiente Windows/PowerShell; app Flutter/Dart com GetX, Firestore, Firebase Auth e Cloud Functions TypeScript em `functions/`.

Este prompt é autossuficiente. Não depende de outro chat ou da execução de outro prompt. Leia o código atual e as instruções AGENTS.md aplicáveis, verifique o estado do Git e preserve alterações existentes. Os arquivos indicados são pontos de investigação: confirme os caminhos antes de editar. O código pode ter evoluído desde a auditoria.

Se uma infraestrutura necessária ainda não existir, implemente a menor fundação de produção necessária dentro desta entrega, com testes e integração real. Se já existir, reutilize-a. Não exija que o usuário execute outra tarefa, não duplique serviços equivalentes e não entregue somente interfaces, telas desconectadas, stubs ou mocks de produção. Isso não autoriza expandir para funcionalidades sem relação com o objetivo.

## Contrato comum que esta entrega deve respeitar

- Preserve o isolamento entre organizadores, eventos, cardápios e itens, incluindo callbacks tardios e troca de sessão.
- Evento salvo, rascunho, planejamento corrente, proposta, histórico e fatos executados são estados distintos. Históricos aprovados não são sobrescritos silenciosamente.
- Ausente, zero confirmado, carregando, vazio, erro, desatualizado e sincronização pendente não são equivalentes.
- Previsão de público, lista nominal, presença e capacidade são informações diferentes. Uma lista parcial não substitui automaticamente a previsão.
- Limite total pertence ao evento. Configurações alimentares e receitas privadas pertencem ao planejamento privado. Reutilize `calculadora_operacao/{idEvento}` e seus mecanismos atuais quando forem adequados; não acrescente campos incompatíveis sem atualizar validação, regras e leitores.
- Confirmação deve gravar pelo caminho de domínio apropriado; cancelar não grava. Não apresentar mutação local como confirmação remota.
- IA interpreta e propõe; cálculos e comandos são validados. Não invente preços, presenças, ingredientes, rendimentos medidos ou adequação alimentar. Não trate aprovação de plano como compra, pagamento, contratação ou envio de mensagem.
- Regras técnicas e fórmulas podem permanecer no código. Referências editoriais e políticas configuráveis precisam de origem, contexto e versão. Não elimine validações para produzir um resultado aparente.
- Garanta usabilidade em celular, teclado aberto, fonte ampliada e telas pequenas; mantenha leitura, contraste e áreas de toque. Não exponha detalhes técnicos desnecessários ao organizador.
- Não execute deploy, alterações em produção, migração destrutiva, commit ou push. Prepare os artefatos necessários e descreva a ativação posterior. Testes autenticados devem usar projeto demo/emuladores e recusar conexões acidentais com produção.

## Objetivo específico

Implemente e execute uma homologação da jornada completa pela interface real: criar evento, estimar, vincular, entrar pela Home, configurar, aplicar, sair, encerrar o processo e recuperar. Não aceite como substituto um teste que começa criando o evento diretamente pelo repositório.

## Contexto específico

Há testes unitários/widgets e roteiros autenticados existentes. Documentos anteriores relatam integração no aparelho, mas um roteiro cadastra o evento pelo repositório. Também foi encontrada expectativa antiga de aplicação imediata da verba após simular; o contrato desejado é simular, revisar e confirmar explicitamente. Verifique tudo no código atual, sem reutilizar números de aprovação de relatórios antigos como resultado desta execução.

## Pontos de entrada

- `test/features/eventos/`, `test/features/calculadora/`, `test/features/cardapios/`
- `integration_test/jornada_calculadora_aparelho_test.dart` e `entrada_inteligente_aparelho_test.dart`
- `functions/scripts/testJornadaCalculadoraAparelho.js` e scripts de teste do backend.
- `test/firestore/calculadora.rules.test.js`, regras do Firestore e configurações de emuladores.
- Cadastro, Home, calculadora e fontes persistidas reais do aplicativo.

## Escopo de validação obrigatório

1. Cadastro novo sem orçamento/cardápio; estimativa isolada com outra festa ativa; edição de público/limite depois da prévia; interrupção antes/depois de criar evento; vínculo recuperável e idempotente.
2. Previsto 40 com lista parcial de uma pessoa; zero confirmados; bases cadastrados/não recusados/confirmados; manual preservado; legado sem composição etária e atualização remota.
3. Carregamento, vazio, erro, fontes desatualizadas e resposta tardia de evento anterior; não fabricar menu em falha de consulta.
4. Confirmação/cancelamento de regra, verba, perfil, margem, base e duração; recuperação após reabrir sem depender de abrir histórico; equivalência entre controles manuais, texto e IA.
5. Infantil, casamento, corporativo com intervalos, retiro de dois dias, churrasco e serviço livre sem referência. Conferir ocorrências, população por destino e ausência de fallback genérico silencioso.
6. Receita própria, ingrediente ausente, compra crua/pronto, unidade/embalagem, referência nova e restrição sem composição conferida. Não inventar adequação nem preço.
7. Estoque comum em duas refeições; buffet já cobrindo itens; preço pendente; capacidade com grupos; cotação, contratação, compra e pagamento parcial distintos.
8. Aplicação repetida, resposta perdida, conflito entre acessos, falha intermediária e usuário sem propriedade; histórico imutável; migração idempotente.
9. Teclado, fonte ampliada, orientação horizontal, navegação de retorno e ausência de rede/IA. Verificar campos e ações visíveis, não apenas ausência de overflow.

## Requisitos de execução

Use SDKs, autenticação, regras e persistência reais em projeto demo/emuladores. Fixtures são dados de teste identificados, não substitutos das camadas que a homologação diz validar. Recuse conexão com produção. Isole testes determinísticos de interpretação da verificação do provedor real e declare qual foi executada.

Se encontrar defeito funcional no escopo, reproduza, corrija e acrescente regressão. Se faltar uma capacidade arquitetural grande, não crie um mock para marcá-la aprovada: implemente o necessário quando viável e mantenha a homologação bloqueada nos critérios ainda não satisfeitos, com evidência e diagnóstico. Ausência de recurso externo não impede escrever o roteiro executável e completar testes independentes.

Verifique dados efetivamente persistidos e efeitos entre módulos. Registre versões de app, motor, catálogo, regras e backend. Não execute deploy nem use credenciais pessoais em fixtures. Meta de conclusão: nenhuma falha crítica, nenhuma duplicação, nenhum vazamento entre usuários/eventos e nenhuma confirmação persistente perdida no roteiro coberto. Relate aprovações, falhas e não executados separadamente; não declare a jornada pronta com uma parte da matriz omitida.

## Execução, validação e entrega

Comece reproduzindo os cenários desta entrega e identificando o comportamento atual. Implemente verticalmente as camadas necessárias: domínio, persistência, permissões/backend e interface. Preserve o comportamento correto já existente e teste falhas, repetição e retomada, além do caminho feliz.

Execute formatação e análise estática nos arquivos modificados e os testes pertinentes. Verifique os scripts atuais antes de usar comandos: a base contém `flutter test`, `npm --prefix functions run check:calculadora`, `npm run test:rules:calculadora` e testes em `integration_test/`. Não rode deploy por esses comandos. Não afirme que testes com substitutos comprovam a integração com Firestore ou com dispositivo.

Se faltar aparelho, emulador, credencial de teste ou outro recurso externo, continue todo o trabalho independente, entregue teste e roteiro reproduzíveis e registre exatamente o que não foi executado. Não marque como homologado o que não foi comprovado. Não desative testes ou enfraqueça regras apenas para obter aprovação.

Registre a evidência da entrega em `docs/evidencias_validacao/jornada/12-homologacao-ponta-a-ponta.md`: diagnóstico, decisão de negócio, arquivos alterados, formato persistido, compatibilidade/migração, testes e resultados reais, limitações externas e instruções de ativação sem publicação. Não inclua segredos ou dados pessoais reais.

Ao finalizar, explique o comportamento anterior e o novo, o que foi efetivamente implementado e validado, e qualquer requisito pendente. Não declare a jornada inteira concluída apenas por encerrar este escopo.
