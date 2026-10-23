# Prompt 10 — Ergonomia e intuitividade da jornada completa

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

Refine a experiência desde o cadastro até a Calculadora Inteligente, mantendo continuidade e tornando os efeitos das ações claros. Não entregue uma coleção de modais bonitos e desconectados.

## Pontos de entrada

- `lib/presentation/modules/usuario/pages/cadastro_evento_bottom_sheet.dart`
- Home e seletor de evento no módulo eventos.
- `lib/presentation/modules/calculadora/pages/calculadora_festa_screen.dart`, suas seções e widgets.
- Modais de consumo, capacidade, planejamento por texto, IA, operação e revisão.
- Widgets compartilhados de formulário, barra de passos e tema.

## Requisitos de implementação

1. Percorra os caminhos cadastro→estimativa→cadastro→evento salvo→Home→calculadora e evento existente→calculadora→editar→sair→retomar. Corrija quebras reais de navegação e perda de contexto no escopo.
2. Use cadastro progressivo sem questionário técnico obrigatório: identidade, quando/onde e previsão. Recuperar o já informado deve evitar redigitação. Tema visual não pode orientar consumo alimentar.
3. Apresente resumo de contexto com evento, público e origem, período, limite/verba e serviços. Diferencie ausência de dados de falha de consulta com ação de recuperação.
4. Ações principais devem corresponder ao efeito real: salvar rascunho, simular, aplicar ao planejamento, salvar histórico ou registrar fato real. Não mostre “salvo” para mera alteração de memória; conecte a persistência mínima necessária quando houver confirmação durável anunciada.
5. Preserve um próximo passo claro e revisão antes de alterações materiais. Encerrar/cancelar não grava. Resolver uma pendência volta ao mesmo ponto do planejamento.
6. Adote padrão consistente de cabeçalho/fechar, conteúdo rolável, foco/erros e ações acessíveis. Teclado não pode cobrir campo, valor ou botão; texto ampliado não pode cortar informações essenciais. Ícones acompanham o contraste do texto.
7. Use seções progressivas para detalhes técnicos, mantendo orientação de quantidade, unidade e preço. Não diminua fonte/áreas de toque para simular compactação.
8. Reutilize fontes e componentes existentes; não acrescente imagens de demonstração, métricas artificiais ou texto de IA como prova de sucesso.

## Critérios de aceite próprios

- Nenhum dado já confirmado precisa ser redigitado ao voltar entre cadastro e estimativa.
- Rascunho sem evento não herda o contexto de outra festa.
- Modal de texto permite digitar, revisar e aplicar com teclado aberto em tela estreita.
- Campo de preço fica inteiramente utilizável, com botão e fechamento acessíveis.
- Falha de rede e salvamento mantém valores e orienta nova tentativa.
- Inclua testes de fonte ampliada/orientação e verificação visual de capturas do app renderizado quando o ambiente permitir; não afirme revisão visual somente com análise estática.

## Execução, validação e entrega

Comece reproduzindo os cenários desta entrega e identificando o comportamento atual. Implemente verticalmente as camadas necessárias: domínio, persistência, permissões/backend e interface. Preserve o comportamento correto já existente e teste falhas, repetição e retomada, além do caminho feliz.

Execute formatação e análise estática nos arquivos modificados e os testes pertinentes. Verifique os scripts atuais antes de usar comandos: a base contém `flutter test`, `npm --prefix functions run check:calculadora`, `npm run test:rules:calculadora` e testes em `integration_test/`. Não rode deploy por esses comandos. Não afirme que testes com substitutos comprovam a integração com Firestore ou com dispositivo.

Se faltar aparelho, emulador, credencial de teste ou outro recurso externo, continue todo o trabalho independente, entregue teste e roteiro reproduzíveis e registre exatamente o que não foi executado. Não marque como homologado o que não foi comprovado. Não desative testes ou enfraqueça regras apenas para obter aprovação.

Registre a evidência da entrega em `docs/evidencias_validacao/jornada/10-experiencia-integral.md`: diagnóstico, decisão de negócio, arquivos alterados, formato persistido, compatibilidade/migração, testes e resultados reais, limitações externas e instruções de ativação sem publicação. Não inclua segredos ou dados pessoais reais.

Ao finalizar, explique o comportamento anterior e o novo, o que foi efetivamente implementado e validado, e qualquer requisito pendente. Não declare a jornada inteira concluída apenas por encerrar este escopo.
