# Prompt 02 — Cadastro, rascunho durável e vínculo recuperável

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

Garanta continuidade desde o formulário de criação do evento até a estimativa vinculada: fechar o app, perder uma resposta de rede ou repetir uma tentativa não pode perder a estimativa nem criar outro evento.

## Situação a investigar

O cadastro abre uma estimativa sem evento e recebe um `RascunhoCalculadora`. Já existem identidade estável do evento e recuperação local de vínculo pendente. Entretanto, antes de uma tentativa de salvar, parte do rascunho pode permanecer somente em memória. Não refaça a proteção já existente; complete a recuperação.

## Pontos de entrada

- `lib/presentation/modules/eventos/controllers/evento_cadastro_controller.dart`
- `lib/presentation/modules/eventos/controllers/evento_cadastro_persistencia.dart`
- `lib/presentation/modules/usuario/pages/cadastro_evento_bottom_sheet.dart`
- `lib/domain/entities/rascunho_calculadora.dart`
- `lib/domain/services/rascunho_calculadora_store.dart` e `lib/data/local/rascunho_calculadora_store.dart`
- `capturarRascunho`, `restaurarRascunho` e `vincularRascunho` no controller da calculadora.

## Requisitos de implementação

1. Persista rascunho local por organizador e ID de rascunho antes de existir ID de evento. Inclua os campos de cadastro necessários para retomar e as escolhas da calculadora, com versão e tratamento de corrupção.
2. Grave por pontos de confirmação e/ou debounce controlado; aguarde os pontos críticos de gravação. Não dependa somente de `dispose` para salvar após encerramento forçado.
3. Apresente retomar, descartar e iniciar novo cadastro, preservando rascunhos de outros usuários/eventos. Não prometa recuperação entre dispositivos usando apenas armazenamento local.
4. Mantenha IDs estáveis e vínculo idempotente. Distinga erro de criar evento de erro de vincular estimativa após o evento já existir.
5. Se o usuário mudar público, tipo ou limite no formulário depois da estimativa, reconcilie explicitamente as premissas e invalide somente o necessário. Dados novos confirmados do formulário prevalecem sobre valores antigos.
6. Ao concluir o vínculo, permita continuar a estimativa vinculada sem exigir que o usuário descubra o histórico. Não crie cardápio, compra, cotação, tarefa, contratação ou pagamento só por salvar o evento.
7. Evite escrever conteúdo privado da simulação no documento compartilhado do evento. Migre os rascunhos locais antigos sem apagá-los antes do sucesso.

## Critérios de aceite próprios

- Com outro evento ativo, a estimativa do cadastro novo não herda seus limites, convidados ou cardápios.
- Fechar e reabrir o processo antes de salvar o evento recupera o cadastro e a estimativa no mesmo aparelho.
- Perder a confirmação de criação e repetir a ação produz um único evento.
- Falhar o vínculo mantém evento salvo e pendência recuperável; repetir não duplica simulação.
- O público e o limite alterados após a prévia chegam corretamente ao evento e ao snapshot vinculado.
- Cancelar ou descartar não remove rascunhos alheios nem altera o evento anteriormente ativo.

## Execução, validação e entrega

Comece reproduzindo os cenários desta entrega e identificando o comportamento atual. Implemente verticalmente as camadas necessárias: domínio, persistência, permissões/backend e interface. Preserve o comportamento correto já existente e teste falhas, repetição e retomada, além do caminho feliz.

Execute formatação e análise estática nos arquivos modificados e os testes pertinentes. Verifique os scripts atuais antes de usar comandos: a base contém `flutter test`, `npm --prefix functions run check:calculadora`, `npm run test:rules:calculadora` e testes em `integration_test/`. Não rode deploy por esses comandos. Não afirme que testes com substitutos comprovam a integração com Firestore ou com dispositivo.

Se faltar aparelho, emulador, credencial de teste ou outro recurso externo, continue todo o trabalho independente, entregue teste e roteiro reproduzíveis e registre exatamente o que não foi executado. Não marque como homologado o que não foi comprovado. Não desative testes ou enfraqueça regras apenas para obter aprovação.

Registre a evidência da entrega em `docs/evidencias_validacao/jornada/02-cadastro-e-rascunho-duravel.md`: diagnóstico, decisão de negócio, arquivos alterados, formato persistido, compatibilidade/migração, testes e resultados reais, limitações externas e instruções de ativação sem publicação. Não inclua segredos ou dados pessoais reais.

Ao finalizar, explique o comportamento anterior e o novo, o que foi efetivamente implementado e validado, e qualquer requisito pendente. Não declare a jornada inteira concluída apenas por encerrar este escopo.
