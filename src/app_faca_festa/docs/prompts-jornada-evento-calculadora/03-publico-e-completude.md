# Prompt 03 — Público, origem e completude da lista de convidados

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

Corrija a definição do público planejado desde o cadastro até a calculadora. O primeiro convidado cadastrado não pode reduzir automaticamente uma previsão de dezenas de pessoas.

## Situação a investigar

Na base “Não recusados”, o cálculo usa previstos enquanto a lista está vazia e pode passar a contar somente a lista assim que surge um registro. A reprodução diagnóstica foi: 40 adultos previstos → um convidado cadastrado → cálculo para uma pessoa. Existem bases manual, previstos, todos cadastrados, confirmados e não recusados que precisam continuar distintas.

## Pontos de entrada

- `lib/domain/entities/evento.dart`, `convidado.dart` e `calculadora_festa.dart`
- `lib/presentation/modules/convidado/controllers/convidado_controller.dart`
- `aplicarTotaisDosConvidados`, `sincronizarConvidados` e `_registrarTotaisDoEvento` em `calculadora_festa_controller.dart`
- `calculadora_festa_screen.dart` e `sections/calculadora_festa_totais.dart` no módulo calculadora.

## Requisitos de implementação

1. Separe previsão de público, lista nominal, presença confirmada, base escolhida e contagem efetiva do cálculo. Não some previsão à lista nem trate confirmação de presença como previsão total.
2. Modele completude da lista como declaração explícita, com estado desconhecido/em preenchimento/concluída ou equivalente. Não infira completude pelo número de registros. Persistência deve ficar no local privado apropriado e funcionar sem uma tarefa anterior.
3. Para planejamento novo sem escolha confirmada, sugira previstos enquanto a lista estiver em preenchimento. Uma troca material de fonte requer escolha e explicação; não sobrescreva uma base explicitamente selecionada.
4. Mostre um resumo como “40 previstos · lista em preenchimento: 1 cadastrado · cálculo usando previstos”, adaptado à situação real.
5. Preserve o público manual durante atualizações remotas. Bases que dependem da lista devem reagir às mudanças de presença sem misturar eventos.
6. Público zero confirmado é diferente de ausente. Para legado com total sem distribuição etária, mantenha a contagem conhecida e exponha a hipótese ou solicite a distribuição; não apresente adultos inferidos como informação conhecida.
7. Reutilize a política na Home, na entrada da calculadora e no público herdado dos serviços. Públicos próprios de refeições não devem ser sobrescritos por uma alteração global.

## Critérios de aceite próprios

- Previsto 40 e primeiro convidado: nenhuma redução silenciosa para 1.
- Escolha explícita de confirmados com zero confirmações mantém zero, sem fallback a 40.
- Todos cadastrados, não recusados e confirmados retornam conjuntos corretos.
- Alterar a lista não modifica o público manual nem públicos próprios de refeições.
- Mudar a base exige confirmação quando houver impacto e a escolha é recuperada ao reabrir.
- Legado com total conhecido e idades desconhecidas apresenta a limitação corretamente.

## Execução, validação e entrega

Comece reproduzindo os cenários desta entrega e identificando o comportamento atual. Implemente verticalmente as camadas necessárias: domínio, persistência, permissões/backend e interface. Preserve o comportamento correto já existente e teste falhas, repetição e retomada, além do caminho feliz.

Execute formatação e análise estática nos arquivos modificados e os testes pertinentes. Verifique os scripts atuais antes de usar comandos: a base contém `flutter test`, `npm --prefix functions run check:calculadora`, `npm run test:rules:calculadora` e testes em `integration_test/`. Não rode deploy por esses comandos. Não afirme que testes com substitutos comprovam a integração com Firestore ou com dispositivo.

Se faltar aparelho, emulador, credencial de teste ou outro recurso externo, continue todo o trabalho independente, entregue teste e roteiro reproduzíveis e registre exatamente o que não foi executado. Não marque como homologado o que não foi comprovado. Não desative testes ou enfraqueça regras apenas para obter aprovação.

Registre a evidência da entrega em `docs/evidencias_validacao/jornada/03-publico-e-completude.md`: diagnóstico, decisão de negócio, arquivos alterados, formato persistido, compatibilidade/migração, testes e resultados reais, limitações externas e instruções de ativação sem publicação. Não inclua segredos ou dados pessoais reais.

Ao finalizar, explique o comportamento anterior e o novo, o que foi efetivamente implementado e validado, e qualquer requisito pendente. Não declare a jornada inteira concluída apenas por encerrar este escopo.
