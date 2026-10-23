# Prompt 04 — Persistência uniforme das escolhas da calculadora

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

Faça as escolhas confirmadas da calculadora sobreviverem à saída da tela e à reabertura do app, independentemente de terem vindo de controles manuais, texto ou IA. Planejamento corrente não deve depender de abrir uma simulação histórica.

## Situação a investigar

Regras manuais já têm gravação aguardada no fluxo integrado. Configurações aplicadas por entrada inteligente possuem restauração. Base, duração, perfil, margem e verba alterados apenas na sessão podem não ter o mesmo caminho durável. Já foi reproduzida duração local de 6 horas e verba de R$ 1.450 voltando para 4 horas e verba ausente após nova preparação sem configuração salva.

## Pontos de entrada

- `lib/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart`
- `calculadora_festa_entrada.dart`, `calculadora_festa_operacao.dart`, `calculadora_festa_personalizacao.dart` e `calculadora_festa_historico.dart`
- `widgets/calculadora_capacidade_dialog.dart` e `pages/calculadora_regra_manual_dialog.dart`
- Repositório/datasource da calculadora, `firestore.rules` e `functions/src/services/calculadora/entradaAssistenteService.ts`.

## Requisitos de implementação

1. Defina um comando tipado de confirmação de configuração, reutilizando a operação privada e a configuração de planejamento existentes quando compatíveis. Controles manuais, texto e IA precisam das mesmas validações e persistência.
2. Inclua base/fonte do público, valores manuais, duração assumida, perfil, margem e verba alimentar. O limite total continua canônico no evento pelo caminho próprio.
3. Distinga editar, aplicar, confirmado no servidor, pendente, falhou e conflito. Cancelar não grava. Simular capacidade não aplica verba; “Usar esta verba” confirma a escolha sem afirmar capacidade indisponível.
4. Preserve as gravações atuais das regras por evento/cardápio/item e todas as premissas de receita, quantidade, estado, serviços, rendimento, embalagem e preço.
5. Trate revisão esperada, edição concorrente, retorno tardio e repetição idempotente. Não perca alterações locais por callback antigo.
6. Atualize schema, validações, permissões e leitores necessários. Dados privados não devem migrar para o documento compartilhado do evento.
7. Restaure o planejamento corrente antes de apresentar o resultado como atual. Históricos permanecem snapshots e não substituem silenciosamente as escolhas correntes.

## Critérios de aceite próprios

- Confirmar 6 horas e verba de R$ 1.450, sair e reabrir recupera os valores.
- Cancelar alterações mantém o estado anterior, inclusive após reabrir.
- Aplicar os mesmos valores por UI, texto ou IA produz o mesmo estado persistido.
- Falha de gravação mantém editor e valores; não mostra sucesso nem fecha como se tivesse salvo.
- Usuário sem propriedade não grava configuração privada de outro evento.
- Reconciliar o teste antigo de capacidade que esperava aplicação imediata após simular; preservar confirmação explícita, não restaurar gravação por mera simulação.

## Execução, validação e entrega

Comece reproduzindo os cenários desta entrega e identificando o comportamento atual. Implemente verticalmente as camadas necessárias: domínio, persistência, permissões/backend e interface. Preserve o comportamento correto já existente e teste falhas, repetição e retomada, além do caminho feliz.

Execute formatação e análise estática nos arquivos modificados e os testes pertinentes. Verifique os scripts atuais antes de usar comandos: a base contém `flutter test`, `npm --prefix functions run check:calculadora`, `npm run test:rules:calculadora` e testes em `integration_test/`. Não rode deploy por esses comandos. Não afirme que testes com substitutos comprovam a integração com Firestore ou com dispositivo.

Se faltar aparelho, emulador, credencial de teste ou outro recurso externo, continue todo o trabalho independente, entregue teste e roteiro reproduzíveis e registre exatamente o que não foi executado. Não marque como homologado o que não foi comprovado. Não desative testes ou enfraqueça regras apenas para obter aprovação.

Registre a evidência da entrega em `docs/evidencias_validacao/jornada/04-persistencia-das-configuracoes.md`: diagnóstico, decisão de negócio, arquivos alterados, formato persistido, compatibilidade/migração, testes e resultados reais, limitações externas e instruções de ativação sem publicação. Não inclua segredos ou dados pessoais reais.

Ao finalizar, explique o comportamento anterior e o novo, o que foi efetivamente implementado e validado, e qualquer requisito pendente. Não declare a jornada inteira concluída apenas por encerrar este escopo.
