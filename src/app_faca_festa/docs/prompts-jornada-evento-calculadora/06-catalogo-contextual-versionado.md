# Prompt 06 — Referências e modelos contextuais configuráveis

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

Retire a decisão automática de formato e porções do conjunto fechado de nomes/valores embutidos, introduzindo referências aprovadas, configuráveis e versionadas. Preserve fórmulas, validações e receitas confirmadas.

## Situação a investigar

`PlanoEventoService` escolhe churrasco por palavra no tipo e lanche nos demais casos. `PropostaRefeicaoService` reconhece uma lista finita de alimentos e contém porções e faixas locais. Há referências com fontes no código, mas isso não equivale a atualização automática nem adequação universal.

## Pontos de entrada

- `lib/domain/services/plano_evento_service.dart`, `proposta_refeicao_service.dart`, `referencia_porcao_service.dart` e `rendimento_referencia_service.dart`
- Catálogo remoto existente em `calculadora_itens_base`/`calculadora_evento_itens`, seus repositórios e telas administrativas.
- Fluxos de regras manuais, memória privada, histórico, `firestore.rules` e backend da calculadora.

## Requisitos de implementação

1. Inspecione o catálogo atual e estenda/reutilize o que serve, evitando duplicar a mesma referência em coleções concorrentes.
2. Versione identidade, aliases, alimento/receita, serviço/formato, papel, unidade, estado de consumo/compra, público aplicável, contexto, faixa, limitações, fonte, revisão editorial e responsável pela aprovação.
3. Implemente repositório e seleção por compatibilidade explícita. Horário, serviço, público e forma de obtenção prevalecem sobre o simples nome do tipo do evento.
4. Remova o fallback silencioso “qualquer outro evento = lanche”. Sem contexto suficiente, peça formato; sem cobertura, mantenha cardápio livre e pendência sem inventar números.
5. Migre as referências existentes com IDs e versões rastreáveis. Não invente fonte, data de verificação ou valores novos. Se atualizar referências externamente, consulte fontes adequadas e registre a verificação realizada.
6. Garanta edição/publicação por papel autorizado, validação no backend/regras e compatibilidade do schema com o motor. Não dependa de editar documento manualmente para a administração cotidiana.
7. Preserve decisões manuais e históricas. Publicação de versão nova oferece revisão, não reescreve plano aprovado. Contingência usa versão conhecida identificada; referência indisponível gera pendência adequada.

## Critérios de aceite próprios

- Casamento, corporativo e retiro não recebem o mesmo lanche silenciosamente.
- Publicar referência compatível permite uso por clientes compatíveis sem recompilar o APK.
- Referência de peso pronto não é aplicada como compra crua.
- Alimento desconhecido não é aproximado arbitrariamente para um alimento reconhecido.
- Regra/receita confirmada e histórico mantêm seus valores após nova publicação.
- Catálogo fora do ar não é substituído por preços ou porções inventados.

## Execução, validação e entrega

Comece reproduzindo os cenários desta entrega e identificando o comportamento atual. Implemente verticalmente as camadas necessárias: domínio, persistência, permissões/backend e interface. Preserve o comportamento correto já existente e teste falhas, repetição e retomada, além do caminho feliz.

Execute formatação e análise estática nos arquivos modificados e os testes pertinentes. Verifique os scripts atuais antes de usar comandos: a base contém `flutter test`, `npm --prefix functions run check:calculadora`, `npm run test:rules:calculadora` e testes em `integration_test/`. Não rode deploy por esses comandos. Não afirme que testes com substitutos comprovam a integração com Firestore ou com dispositivo.

Se faltar aparelho, emulador, credencial de teste ou outro recurso externo, continue todo o trabalho independente, entregue teste e roteiro reproduzíveis e registre exatamente o que não foi executado. Não marque como homologado o que não foi comprovado. Não desative testes ou enfraqueça regras apenas para obter aprovação.

Registre a evidência da entrega em `docs/evidencias_validacao/jornada/06-catalogo-contextual-versionado.md`: diagnóstico, decisão de negócio, arquivos alterados, formato persistido, compatibilidade/migração, testes e resultados reais, limitações externas e instruções de ativação sem publicação. Não inclua segredos ou dados pessoais reais.

Ao finalizar, explique o comportamento anterior e o novo, o que foi efetivamente implementado e validado, e qualquer requisito pendente. Não declare a jornada inteira concluída apenas por encerrar este escopo.
