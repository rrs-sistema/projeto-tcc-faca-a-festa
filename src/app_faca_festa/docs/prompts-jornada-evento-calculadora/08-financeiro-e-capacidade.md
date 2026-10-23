# Prompt 08 — Financeiro real, verba alimentar e capacidade

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

Torne coerentes a Home, o orçamento e a calculadora: separar estimado, cotado, contratado e pago; conciliar alimentação com serviços já cobertos; apresentar capacidade e verba com semântica correta.

## Situação a investigar

O rótulo “Gasto” da Home usa soma de custos estimados. A calculadora já possui compromissos, pagamentos e detecção de sobreposição. O algoritmo de capacidade limita extrapolação de públicos/grupos específicos e deve manter essa proteção. Simular e confirmar verba são ações distintas.

## Pontos de entrada

- `lib/presentation/modules/eventos/pages/home_event_screen.dart` e `home_organizador_copy.dart`
- `lib/presentation/modules/orcamento/controllers/orcamento_controller.dart`
- `lib/domain/services/resumo_compras_service.dart`, `capacidade_alimentos_service.dart` e serviços de lista de compras/financeiro existentes.
- `lib/presentation/modules/calculadora/widgets/calculadora_capacidade_dialog.dart`
- Repositório da calculadora, despesas/cotações e `functions/src/services/calculadora/financeiroCalculadoraService.ts`.

## Requisitos de implementação

1. Defina e use nomes correspondentes aos dados: estimado, cotado, contratado, pago e compra adicional projetada. Não renomeie um valor como pago sem buscar os registros adequados.
2. Limite total é do evento; verba alimentar é uma escolha de planejamento. Preserve fonte, data e confirmação de valores. Persistência da verba confirmada deve estar integrada ao planejamento corrente.
3. Concilie compromissos e cobertura por identidade. Buffet ou serviço contratado que já cobre alimentos não entra outra vez como compra adicional.
4. Preço deve corresponder à unidade e ao estado de compra. Ausência, zero e incompatibilidade não viram economia. Não considere cotação como pagamento nem estime pago subtraindo custos arbitrariamente.
5. Simulação de capacidade deve apresentar exatamente o cenário suportado. Públicos mistos/específicos sem modelo aplicável recebem limitação e próxima ação, não um número falso. Ainda é possível confirmar verba sem estimar capacidade.
6. Aprovar proposta ou simular não registra compra/contratação/pagamento. Operações financeiras reais exigem ações explicitamente escolhidas e validadas.
7. Atualize listeners e revisão de projeções quando o limite ou compromissos mudarem, preservando históricos e decisões de outro evento.

## Critérios de aceite próprios

- Orçamento estimado de R$ 6.500 com pagamento real de R$ 500 é mostrado como informações distintas.
- Buffet com itens cobertos não duplica alimentação na projeção.
- Pagamento parcial respeita saldo e vínculo da despesa; cotação continua distinta.
- Preço ausente/por unidade incompatível deixa custo pendente.
- Simular capacidade não altera a verba; confirmar aplica e persiste; cancelar preserva o valor anterior.
- Atualização remota de limite revalida a projeção sem alterar compras já registradas.

## Execução, validação e entrega

Comece reproduzindo os cenários desta entrega e identificando o comportamento atual. Implemente verticalmente as camadas necessárias: domínio, persistência, permissões/backend e interface. Preserve o comportamento correto já existente e teste falhas, repetição e retomada, além do caminho feliz.

Execute formatação e análise estática nos arquivos modificados e os testes pertinentes. Verifique os scripts atuais antes de usar comandos: a base contém `flutter test`, `npm --prefix functions run check:calculadora`, `npm run test:rules:calculadora` e testes em `integration_test/`. Não rode deploy por esses comandos. Não afirme que testes com substitutos comprovam a integração com Firestore ou com dispositivo.

Se faltar aparelho, emulador, credencial de teste ou outro recurso externo, continue todo o trabalho independente, entregue teste e roteiro reproduzíveis e registre exatamente o que não foi executado. Não marque como homologado o que não foi comprovado. Não desative testes ou enfraqueça regras apenas para obter aprovação.

Registre a evidência da entrega em `docs/evidencias_validacao/jornada/08-financeiro-e-capacidade.md`: diagnóstico, decisão de negócio, arquivos alterados, formato persistido, compatibilidade/migração, testes e resultados reais, limitações externas e instruções de ativação sem publicação. Não inclua segredos ou dados pessoais reais.

Ao finalizar, explique o comportamento anterior e o novo, o que foi efetivamente implementado e validado, e qualquer requisito pendente. Não declare a jornada inteira concluída apenas por encerrar este escopo.
