# Prompt 09 — Aplicação agrupada, estoque e execução idempotente

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

Implemente ou complete a aplicação agrupada do plano entre cardápios, estoque, lista de compras e tarefas, preservando idempotência, autorização e recuperação. Aprovar um plano não é executar compras ou pagamentos.

## Pontos de entrada

- `lib/domain/services/criacao_cardapio_inicial_service.dart`
- Serviços e entidades de plano de execução, operação, lista de compras e composição por ficha técnica.
- `lib/data/datasources/remote/cardapio_remote_datasource.dart` e `plano_execucao_remote_datasource.dart`
- Controllers de cardápio/calculadora e modais de revisão/execução.
- `functions/src/services/calculadora/executarPlanoService.ts`, funções relacionadas e `firestore.rules`.

## Requisitos de implementação

1. Inspecione as transações, assinaturas, recibos e validações já existentes. Complete as lacunas; não substitua proteções por gravações diretas do cliente.
2. Proposta revisada descreve efeitos por ID: sugestões de cardápio, regras por destino, distribuição/reserva de estoque, ingredientes conhecidos e tarefas. Separe de quantidade final, compra, contratação e pagamento reais.
3. Vincule aplicação a proprietário, evento, revisões de fontes e ID de pedido estável. Mudança material exige revisar novamente; repetição com o mesmo pedido retorna o mesmo recibo.
4. Faça operações coerentes de forma atômica quando possível. Quando limites técnicos exigirem etapas, implemente estado persistido e reconciliação explícita; não anuncie sucesso de um conjunto parcialmente aplicado.
5. Use saldo único por lote e destino, sem reserva dupla ou utilização simultânea indevida. Agregue ingredientes somente com unidade, estado e identidade compatíveis.
6. Um cancelamento não executa o conjunto. Conflito de dois acessos não apaga alterações confirmadas; apresente diferenças e retomada.
7. Registre auditoria técnica sem conteúdo privado desnecessário. Envio a terceiros ou ações financeiras externas ficam fora da execução implícita do plano.

## Critérios de aceite próprios

- Aplicar e repetir a mesma proposta não duplica cardápio, ingrediente, tarefa ou reserva.
- Resposta perdida após sucesso recupera o recibo em nova tentativa.
- Revisão desatualizada é rejeitada sem aplicação parcial.
- Dois serviços disputando um lote não consomem o mesmo saldo duas vezes.
- Ficha técnica incompleta não produz ingredientes inventados.
- Outro organizador não lê nem aplica o plano privado.
- Teste com transações e regras reais em emuladores, além dos testes de domínio.

## Execução, validação e entrega

Comece reproduzindo os cenários desta entrega e identificando o comportamento atual. Implemente verticalmente as camadas necessárias: domínio, persistência, permissões/backend e interface. Preserve o comportamento correto já existente e teste falhas, repetição e retomada, além do caminho feliz.

Execute formatação e análise estática nos arquivos modificados e os testes pertinentes. Verifique os scripts atuais antes de usar comandos: a base contém `flutter test`, `npm --prefix functions run check:calculadora`, `npm run test:rules:calculadora` e testes em `integration_test/`. Não rode deploy por esses comandos. Não afirme que testes com substitutos comprovam a integração com Firestore ou com dispositivo.

Se faltar aparelho, emulador, credencial de teste ou outro recurso externo, continue todo o trabalho independente, entregue teste e roteiro reproduzíveis e registre exatamente o que não foi executado. Não marque como homologado o que não foi comprovado. Não desative testes ou enfraqueça regras apenas para obter aprovação.

Registre a evidência da entrega em `docs/evidencias_validacao/jornada/09-aplicacao-e-execucao.md`: diagnóstico, decisão de negócio, arquivos alterados, formato persistido, compatibilidade/migração, testes e resultados reais, limitações externas e instruções de ativação sem publicação. Não inclua segredos ou dados pessoais reais.

Ao finalizar, explique o comportamento anterior e o novo, o que foi efetivamente implementado e validado, e qualquer requisito pendente. Não declare a jornada inteira concluída apenas por encerrar este escopo.
