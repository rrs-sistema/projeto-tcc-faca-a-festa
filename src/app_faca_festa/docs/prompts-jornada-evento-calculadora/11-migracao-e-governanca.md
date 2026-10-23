# Prompt 11 — Compatibilidade, migração e governança do catálogo

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

Prepare e implemente a compatibilidade necessária para evoluir o planejamento sem corromper eventos antigos, históricos, receitas ou operações financeiras. Entregue ferramentas e testes de migração; não execute migração em produção.

## Pontos de entrada

- Modelos de evento, rascunho, cardápio, operação, regras e simulação.
- Repositórios/datasources e validação de `operacao_calculadora_service.dart`.
- Catálogo de referências, administração, Firestore rules e funções da calculadora.
- Snapshots/histórico e integração do executor/entrada inteligente.

## Requisitos de implementação

1. Faça inventário dos schemas e leitores realmente existentes, incluindo campos opcionais e versões do motor. Defina migração por versão, sem supor que todas as entregas de planejamento já tenham sido executadas.
2. Implemente adaptadores e validação necessários para dados antigos: evento sem término, total sem distribuição etária, cardápio sem ocorrência, regra sem metadados novos e histórico de motor anterior. Preserve origem/hipóteses em vez de inventar valores definitivos.
3. Ferramenta de migração deve operar primeiro em modo de inspeção/dry-run, ter seleção explícita de ambiente/eventos, autorização, identificadores estáveis, relatório e repetição idempotente. Não criar dados reais nesta tarefa.
4. Preserve compras, pagamentos, contratos, receitas próprias e snapshots aprovados. Corrigir schema não é recalcular silenciosamente fatos ou históricos.
5. Trate compatibilidade entre leitores antigos/novos e schema de publicação. Defina ordem segura de ativação de backend/regras, dados e clientes; identifique versões que não podem escrever no mesmo formato sem adaptação.
6. Modele governança de referências: rascunho, validada/aprovada, publicada e substituída, com papel responsável, origem e versão. Autor não privilegiado não publica política global.
7. Prepare reversão que desative a seleção da versão nova sem apagar fatos registrados, mais cópia/registro de inspeção antes de alterações de dados.
8. Proponha instrumentação de migração, restauração, conflitos e referência sem cobertura sem incluir dados pessoais, receitas ou documentos privados em logs.

## Critérios de aceite próprios

- Executar migração duas vezes em fixtures/emuladores não duplica nem altera novamente os dados.
- Dry-run não escreve.
- Eventos legados continuam legíveis e hipóteses ficam identificadas.
- Históricos e pagamentos permanecem iguais antes/depois da migração.
- Usuário sem permissão não migra dados de outro organizador nem publica catálogo global.
- Reversão é exercitada em ambiente demo e documentada; publicação real permanece pendente.

## Execução, validação e entrega

Comece reproduzindo os cenários desta entrega e identificando o comportamento atual. Implemente verticalmente as camadas necessárias: domínio, persistência, permissões/backend e interface. Preserve o comportamento correto já existente e teste falhas, repetição e retomada, além do caminho feliz.

Execute formatação e análise estática nos arquivos modificados e os testes pertinentes. Verifique os scripts atuais antes de usar comandos: a base contém `flutter test`, `npm --prefix functions run check:calculadora`, `npm run test:rules:calculadora` e testes em `integration_test/`. Não rode deploy por esses comandos. Não afirme que testes com substitutos comprovam a integração com Firestore ou com dispositivo.

Se faltar aparelho, emulador, credencial de teste ou outro recurso externo, continue todo o trabalho independente, entregue teste e roteiro reproduzíveis e registre exatamente o que não foi executado. Não marque como homologado o que não foi comprovado. Não desative testes ou enfraqueça regras apenas para obter aprovação.

Registre a evidência da entrega em `docs/evidencias_validacao/jornada/11-migracao-e-governanca.md`: diagnóstico, decisão de negócio, arquivos alterados, formato persistido, compatibilidade/migração, testes e resultados reais, limitações externas e instruções de ativação sem publicação. Não inclua segredos ou dados pessoais reais.

Ao finalizar, explique o comportamento anterior e o novo, o que foi efetivamente implementado e validado, e qualquer requisito pendente. Não declare a jornada inteira concluída apenas por encerrar este escopo.
