# Prompt 05 — Agenda e serviços alimentares por ocorrência

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

Permita planejar corretamente eventos de um ou vários dias, com refeições e intervalos distintos. Data de início/fim e título do cardápio não podem ser usados como substitutos de uma agenda de serviços.

## Situação a investigar

O evento contém período, e os cardápios possuem escopo/público. Falta uma identidade temporal completa para diferenciar, por exemplo, almoço do dia 1 e almoço do dia 2. A duração global padrão não deve multiplicar indiscriminadamente todas as receitas.

## Pontos de entrada

- `lib/domain/entities/evento.dart`, `cardapio.dart` e `cardapio_item.dart`
- `lib/domain/services/plano_evento_service.dart` e `operacao_calculadora_service.dart`
- `lib/presentation/modules/convidado/components/cadastro_cardapio_bottom_sheet.dart`
- `lib/presentation/modules/calculadora/pages/calculadora_operacao_dialog.dart`
- Regras/datasource da operação, criação inicial, histórico, estoque e executor do plano.

## Requisitos de implementação

1. Reutilize ou crie ocorrência de serviço com ID estável, vínculo ao evento/cardápio, data/hora/fuso quando conhecidos, duração, formato de atendimento, público herdado/próprio e destinos de grupos.
2. Diferencie evento, cardápio/receita reutilizável e ocorrência. Dias do evento não são número de porções nem número de serviços de cada item.
3. Ofereça criação e edição progressivas das ocorrências. Não crie refeições automaticamente só por salvar o evento; apresente uma proposta revisável quando houver intenção de planejar alimentação.
4. Horário desconhecido permanece desconhecido. Valide intervalos e período sem bloquear um rascunho permitido apenas por ausência de horário definitivo.
5. Inclua equipe ou público extra explicitamente por ocorrência; não adultere a previsão principal. Preserve grupos e necessidades por destino sem afirmar adequação pelo nome do prato.
6. Atualize cálculo, compras consolidadas, estoque/reservas e snapshots para distinguir ocorrências. Não disponibilize o mesmo lote duas vezes.
7. Mantenha compatibilidade dos cardápios antigos, sem atribuir datas ou frequência inventadas. Ofereça completar a agenda sem destruir seus dados.

## Critérios de aceite próprios

- Retiro de dois dias com dois almoços e dois jantares mantém quatro identidades e públicos independentes.
- Congresso com três intervalos calcula por ocorrência e agrega compras sem multiplicação adicional por duração global.
- O mesmo cardápio pode ser reutilizado em ocorrências distintas sem compartilhar indevidamente quantidades finais e registros de execução.
- Um grupo de uma refeição não altera automaticamente as demais.
- Renomear “Almoço” não muda o serviço por interpretação do título.
- Reservas e compras em duas ocorrências mantêm saldo único de estoque.

## Execução, validação e entrega

Comece reproduzindo os cenários desta entrega e identificando o comportamento atual. Implemente verticalmente as camadas necessárias: domínio, persistência, permissões/backend e interface. Preserve o comportamento correto já existente e teste falhas, repetição e retomada, além do caminho feliz.

Execute formatação e análise estática nos arquivos modificados e os testes pertinentes. Verifique os scripts atuais antes de usar comandos: a base contém `flutter test`, `npm --prefix functions run check:calculadora`, `npm run test:rules:calculadora` e testes em `integration_test/`. Não rode deploy por esses comandos. Não afirme que testes com substitutos comprovam a integração com Firestore ou com dispositivo.

Se faltar aparelho, emulador, credencial de teste ou outro recurso externo, continue todo o trabalho independente, entregue teste e roteiro reproduzíveis e registre exatamente o que não foi executado. Não marque como homologado o que não foi comprovado. Não desative testes ou enfraqueça regras apenas para obter aprovação.

Registre a evidência da entrega em `docs/evidencias_validacao/jornada/05-agenda-e-ocorrencias.md`: diagnóstico, decisão de negócio, arquivos alterados, formato persistido, compatibilidade/migração, testes e resultados reais, limitações externas e instruções de ativação sem publicação. Não inclua segredos ou dados pessoais reais.

Ao finalizar, explique o comportamento anterior e o novo, o que foi efetivamente implementado e validado, e qualquer requisito pendente. Não declare a jornada inteira concluída apenas por encerrar este escopo.
