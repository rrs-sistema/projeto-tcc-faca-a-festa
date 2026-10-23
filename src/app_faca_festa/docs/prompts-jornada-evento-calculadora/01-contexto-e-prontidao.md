# Prompt 01 — Contexto único, prontidão e atualização das fontes

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

Implemente um contexto consistente para a Calculadora Inteligente, recuperado a partir do evento ou rascunho explícito. A tela precisa conhecer a origem, a revisão e a disponibilidade de cada fonte antes de permitir conclusões ou gravações.

## Situação a investigar

Convidados, cardápios, itens, operação e orçamento carregam separadamente. A inicialização de listeners não significa que todas as fontes estejam disponíveis. O evento recebe atualizações em tempo real, mas a calculadora pode continuar usando premissas capturadas na entrada. Um resultado de rede ou de IA antigo não pode ser aplicado depois de uma troca de evento.

## Pontos de entrada

- `lib/presentation/modules/eventos/controllers/evento_controller.dart`
- `lib/presentation/coordinators/evento_session_coordinator.dart`
- `lib/presentation/modules/calculadora/pages/calculadora_festa_screen.dart`
- `lib/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart`
- `calculadora_festa_operacao.dart`, `calculadora_festa_analise_ia.dart` e `calculadora_festa_entrada.dart`, na mesma pasta de controllers.

## Requisitos de implementação

1. Reutilize ou crie um contrato tipado equivalente a `ContextoPlanejamentoEvento`, com IDs de usuário/evento/rascunho, modo, revisões das fontes, estado de cada consulta e pendências. Não adicione outra cópia mutável da fonte da verdade.
2. Modele por fonte: não consultada, carregando, disponível com dados, disponível vazia, erro, desatualizada e escrita pendente. Não converta falha de consulta em evento sem dados.
3. Derive capacidades separadas: estimar quantidades, estimar compras, projetar custos, comparar alternativas e aplicar proposta. Resultado parcial deve indicar a parte pendente e sua ação de resolução.
4. Integre mudanças remotas do evento e dos módulos. Uma alteração de público, período, regra ou financeiro invalida os resultados afetados; capa ou título visual não deve invalidar quantidades sem necessidade.
5. Use geração/revisão de contexto para rejeitar callbacks antigos. Retomar histórico mantém seu snapshot isolado; atualizar para dados atuais exige uma transição explícita.
6. Garanta que todas as entradas da calculadora usem o contrato, inclusive a estimativa aberta antes de salvar o evento. ID vazio explicitamente escolhido não pode herdar o evento ativo.

## Critérios de aceite próprios

- Com consulta negada de cardápios, não surge um cardápio de exemplo nem afirmação de consulta completa.
- Alterar o orçamento em outro acesso atualiza ou invalida a projeção financeira visivelmente.
- Alternar rapidamente entre eventos A e B descarta respostas tardias de A.
- Público manual não é substituído por uma atualização da lista.
- Consultar histórico não modifica seus valores por listeners da operação corrente.
- Sem IA disponível, o cálculo determinístico com fontes válidas continua utilizável.
- Teste a coordenação com respostas fora de ordem e erros independentes; não teste apenas um booleano isolado.

## Execução, validação e entrega

Comece reproduzindo os cenários desta entrega e identificando o comportamento atual. Implemente verticalmente as camadas necessárias: domínio, persistência, permissões/backend e interface. Preserve o comportamento correto já existente e teste falhas, repetição e retomada, além do caminho feliz.

Execute formatação e análise estática nos arquivos modificados e os testes pertinentes. Verifique os scripts atuais antes de usar comandos: a base contém `flutter test`, `npm --prefix functions run check:calculadora`, `npm run test:rules:calculadora` e testes em `integration_test/`. Não rode deploy por esses comandos. Não afirme que testes com substitutos comprovam a integração com Firestore ou com dispositivo.

Se faltar aparelho, emulador, credencial de teste ou outro recurso externo, continue todo o trabalho independente, entregue teste e roteiro reproduzíveis e registre exatamente o que não foi executado. Não marque como homologado o que não foi comprovado. Não desative testes ou enfraqueça regras apenas para obter aprovação.

Registre a evidência da entrega em `docs/evidencias_validacao/jornada/01-contexto-e-prontidao.md`: diagnóstico, decisão de negócio, arquivos alterados, formato persistido, compatibilidade/migração, testes e resultados reais, limitações externas e instruções de ativação sem publicação. Não inclua segredos ou dados pessoais reais.

Ao finalizar, explique o comportamento anterior e o novo, o que foi efetivamente implementado e validado, e qualquer requisito pendente. Não declare a jornada inteira concluída apenas por encerrar este escopo.
