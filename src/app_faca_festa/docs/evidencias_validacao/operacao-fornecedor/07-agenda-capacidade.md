# 07 — Agenda e capacidade operacional do fornecedor

Implementação e validação local em 26/10/2026, Windows/PowerShell. Nenhum deploy, commit, push, migração ou operação de produção foi realizado. Fixtures sintéticas e projetos demo no Firestore Emulator.

## Inspeção e base reutilizada

Foram examinados Git (branch main, árvore extensamente alterada), os caminhos de agenda, calculadora, estoque, contratação, execução e mediação antes de editar. Não foram encontrados AGENTS.md aplicáveis no repositório e ancestrais. As alterações anteriores, especialmente execução, comissão e repasses, foram preservadas.

A agenda existente da calculadora (`agendaServicoService.ts`, `OcorrenciaServico`, diálogos de ocorrência) pertence ao planejamento de refeições/serviços do evento. Não era uma reserva da equipe do fornecedor. O estoque empresarial já possuía intervalos com buffers de montagem/transporte/desmontagem, natureza consumível/reutilizável/locada, reserva, retirada, cancelamento e devolução. A jornada já criava um orçamento canônico por contratação. Foram reutilizados esses contratos, regras de intervalos, funções de estoque e mecanismos de execução/cancelamento/mediação.

## Modelo e fluxo entregues

A rota `/fornecedor/agenda`, acessível nas solicitações e na jornada de cada contrato, apresenta agenda cronológica, próximos compromissos, pendentes e histórico. Exibe contrato/serviço, data do evento, local compartilhável, estado operacional, janelas de montagem, execução e retirada, fuso IANA, pendências e recursos privados selecionados. A data do evento é exibida somente como data; meia-noite de um campo sem horário não vira hora de serviço. Janelas inexistentes permanecem pendentes.

| Informação | Origem e regra |
| --- | --- |
| Identidade e estado | orçamento/contrato existente; a cotação não é outra venda |
| Intervalos compartilháveis | `orcamento/{id}/agenda_operacional`, gravados pelo backend |
| Unidades e materiais privados | `fornecedor/{uid}/agenda_compromissos/{idOrcamento}`, projeção com a mesma identidade do contrato |
| Capacidade e serialização | `fornecedor/{uid}/agenda_config/principal`, revisão transacional |
| Histórico de alterações | `fornecedor/{uid}/agenda_historico`, com autor, motivo, datas e intervalos anteriores/novos |
| Materiais | coleções existentes `estoque_itens`, `estoque_reservas`, `estoque_movimentos` |
| Referência da calculadora | somente ocorrência explicitamente vinculada por id_ocorrencia/id_cardapio, sem copiar planejamento global ou criar outro cardápio |

Capacidade simples configurável de 1 a 100 unidades simultâneas. Cada contrato usa uma ou mais unidades; isso não presume um evento por dia nem um cadastro de funcionários. Intervalos são semiabertos `[início, fim)`: um serviço pode começar no instante em que outro termina. A verificação usa varredura de extremos, não soma indiscriminadamente todos os eventos que ocorreram no mesmo dia. Configuração ausente é apresentada como indisponível para confirmação, não como zero/um. Janelas já encerradas permanecem no histórico e não impedem reduzir a capacidade futura.

Cotação aberta/proposta enviada não cria reserva. Não foi introduzido bloqueio provisório: não há promessa de retenção/expiração implícita. Uma proposta pode incluir intervalo explícito de execução e fuso; essa informação integra a versão/assinatura revisada pelo cliente. No aceite, a capacidade é conferida e a reserva vinculada ao contrato é criada na mesma transação da contratação. Aceites concorrentes disputam a mesma revisão do fornecedor. Sem intervalo, o contrato real permanece pendente de agenda; a interface avisa que não houve reserva de capacidade. Nenhuma duração ou horário é inferido da data do evento ou do prazo de entrega. Requisições de proposta sem agenda preservam a assinatura anterior de idempotência, para não invalidar retomadas do protocolo existente.

Após contratar, confirmar/reagendar exige revisão vigente, motivo de 10 a 1.000 caracteres, capacidade suficiente e materiais suficientes. A confirmação grava contrato, projeção privada, reservas existentes e auditoria atomicamente. O reagendamento registra planejamento operacional compartilhável; não reescreve o snapshot/escopo/preço aceitos nem constitui aceite contratual em nome do cliente. Repetição com a mesma chave/payload é idempotente; payload divergente é rejeitado. Outro contrato sem horário exige decisão fundamentada ao confirmar/reagendar a agenda, pois a ausência de intervalo não comprova disponibilidade. Conflito conhecido de simultaneidade, manutenção/vencimento ou insuficiência de material bloqueia; justificativa não ultrapassa esses limites. Alteração após início/entrega/contestação segue a jornada/mediação e não é um reagendamento unilateral pela agenda. Valores, escopo e aceite da proposta permanecem preservados.

A projeção não cria outro compromisso comercial. Espelhos legados de uma mesma identidade são deduplicados na consulta, preferindo o vínculo já agendado. Uma segunda confirmação por outro espelho é recusada. Registros antigos sem janela continuam visíveis para definição explícita, sem migração automática.

## Estoque, cancelamento e execução

O formulário seleciona somente materiais internos existentes, com quantidade explícita; produto do catálogo não vira material. São suportados até 15 recursos distintos e até três janelas, com horizonte máximo de 30 dias. O estoque reutiliza `reservar`, `intervaloEfetivo`, `cancelarReserva`, mapeamento e persistência existentes. Materiais ficam reservados do primeiro preparo à última retirada, acrescidos dos buffers configurados do item. Essa ocupação pode ser mais conservadora que a equipe por janela, pois o material permanece alocado entre etapas.

Reagendamento cancela as reservas anteriores e cria as substitutas no mesmo commit, preservando documentos e histórico. Material já retirado precisa de devolução antes de reagendar. A agenda oferece retirada/devolução por confirmação humana e usa as callables de estoque existentes, com chave estável.

Cancelamento contratual e decisão de cancelamento da execução por mediação liberam reservas ainda ativas na mesma transação existente. Não apagam fatos. Material retirado permanece como pendência física até a devolução; não é devolvido ou consumido ficticiamente pelo cancelamento. A devolução de reutilizável preserva quantidade total e baixa apenas a quantidade em uso. Reserva retirada continua indisponível para novas reservas enquanto não houver retorno, inclusive se a janela planejada já terminou.

O início da execução exige agenda confirmada e os recursos vinculados ainda reservados/retirados. A preparação legada com apenas uma data continua sendo preparação, sem fabricar reserva de intervalo. Marcar mensagem como lida, pagamento declarado ou recebimento não confirma agenda/entrega.

Reservas antigas somente por evento, sem vínculo contratual, são mantidas no estoque e não são atribuídas arbitrariamente a um contrato ou canceladas em conjunto com ele. Cancelar um evento não comprova resolução financeira dos contratos nem devolução de itens: a liberação contratual segue o cancelamento/resolução autorizado existente.

## Privacidade e sessão

Agenda interna, capacidade, unidades, recursos e histórico são privados do próprio fornecedor, sem acesso geral de administrador ou cliente. Callables obtêm o autor da sessão e validam o vínculo ao orçamento; ID enviado não concede acesso. O endpoint de compromisso permitido retorna apenas o próprio contrato, agenda compartilhável e estado, sem compromissos de terceiros, materiais, capacidade interna, orçamento global do evento ou custos privados.

As regras excluem as novas coleções das permissões genéricas sobrepostas. Estoque passa a aceitar escrita somente pelo backend, compatível com o datasource atual que já usa callables. As regras também impedem editar a agenda, cancelar por update de status ou excluir um orçamento agendado diretamente, contornando liberação/auditoria. Consultas de collectionGroup por terceiros não expõem as projeções.

O controller invalida listas, consultas, formulários e comandos ao trocar sessão. Timeout mantém a mesma chave e payload em persistência local até retomada explícita, inclusive após reabrir; não gera outro comando silenciosamente. Há loading, vazio, falha com retry, pendência e formulário responsivo.

## Arquivos da entrega

- Backend novo: `functions/src/services/agenda/agendaFornecedorService.ts` e `functions/src/services/financeiro/estoqueFornecedorMapper.ts` (extração do mapeamento existente).
- Integrações: `jornadaAtendimentoService.ts`, `contratoFinanceiroService.ts`, `acompanhamentoPersistenciaService.ts`, `resolucaoMediacaoService.ts`, `estoqueFornecedorService.ts`, `comandosEstoqueFornecedor.ts`, `functions/src/index.ts`, `firestore.rules`.
- Flutter: `agenda_fornecedor_controller.dart`, `pages/agenda/agenda_fornecedor_page.dart`, solicitações, jornada/versionamento de proposta e rotas existentes.
- Testes: `functions/scripts/testAgendaFornecedorEmulator.js`, `test/firestore/agenda_fornecedor.rules.test.js`, `test/features/agenda/agenda_fornecedor_test.dart`; fixture da jornada ajustada para confirmar agenda antes de iniciar execução; script `test:agenda:fornecedor` em package.json.

## Validações executadas

JDK 21 local (`$env:TEMP/codex-chat-jdk/jdk-21.0.12.1+1`) no JAVA_HOME/PATH somente do processo. Emuladores Firestore em projetos demo; nenhuma credencial/fixture real.

1. `npm --prefix functions run build`: compilação TypeScript estrita passou.
2. `npm --prefix functions run check:financeiro`: passou, incluindo domínio de estoque, comissão, execução, conciliação e autorização. Log: `$env:TEMP/agenda-financeiro.log`.
3. `flutter test test/features/agenda test/features/cotacoes test/features/financeiro/estoque_fornecedor_test.dart test/features/calculadora/agenda_ocorrencias_test.dart test/features/financeiro/resolucao_mediacao_widget_test.dart --reporter expanded`: **42 testes passaram**. Inclui fuso, horário ausente, formulário, revisão, conflito, sessão antiga, timeout/reabertura com a mesma chave, movimento físico, largura de 360 pixels, jornada, estoque, agenda da calculadora e mediação. Log: `$env:TEMP/agenda-flutter-final.log`.
4. Análise direcionada com `dart analyze` nos novos controller/página, solicitações, página da jornada, rotas e testes de agenda: **No issues found**. Log: `$env:TEMP/agenda-analyze-final.log`.
5. `firebase emulators:exec --project demo-agenda-fornecedor --only firestore "node functions/scripts/testAgendaFornecedorEmulator.js"`: passou com Firestore real emulado. Capacidade 1/2/terceiro bloqueado; extremos compatíveis; normalização de offset; virada de dia; horário/fuso inválido; ausência de configuração; confirmações concorrentes; revisão/idempotência; redução inválida; reagendamento com substituição de reservas; cancelamento ativo/retirado; devolução preservando reutilizáveis; início sem agenda negado; aceite de propostas concorrentes; identidade legada e privacidade. Log final: `$env:TEMP/agenda-emulador-final.log`.
6. `firebase emulators:exec --project demo-agenda-fornecedor --only firestore "node test/firestore/agenda_fornecedor.rules.test.js"`: **61 verificações passaram**, incluindo dono, outro fornecedor, cliente e administrador; leitura privada, escrita direta, alteração/exclusão de contrato agendado. Log: `$env:TEMP/agenda-rules-final.log`.
7. `test/firestore/estoque_fornecedor.rules.test.js` executado no emulador: passou, privacidade do estoque preservada.
8. Em sessão limpa separada, `firebase emulators:exec --project demo-jornada-atendimentos --only firestore "node functions/scripts/testJornadaAtendimentosEmulator.js"`: passou. A fixture prepara intervalo/capacidade antes do início; contratação, versões, expiração, entrega, aceite, contestação e chat continuam funcionais. Log: `$env:TEMP/agenda-jornada-regressao.log`.
9. Em outra sessão limpa, `firebase emulators:exec --project demo-repasse-operacional --only firestore "node functions/scripts/testRepasseOperacionalEmulator.js"`: passou, incluindo comissão, retenção, concorrência, regras e resolução por mediação. Log: `$env:TEMP/agenda-repasses-regressao.log`.

As integrações usam transações e persistência no emulador, clientes SDK de regras e as implementações reais de serviços/callables. Widgets usam doubles para controlar timeout, conflito e sessão; não são a única prova. A rodada final de `npm run test:agenda:fornecedor` terminou com código 0, incluindo integração, histórico sem ocupar capacidade futura e as 61 verificações de regras. `git diff --check` nos arquivos do escopo também passou. Negações PERMISSION_DENIED no log são esperadas nos testes negativos. O comando reproduzível `npm run test:agenda:fornecedor` reúne build, integração e regras próprias da agenda.

## Índices, compatibilidade e limites

Não foi necessário índice composto novo: consultas por fornecedor/contrato usam igualdade simples e subcoleções existentes. Nenhuma permissão foi ampliada para resolver permission-denied. Não foi feita migração automática de agendas ou reservas legadas.

A capacidade suportada é simultaneidade simples, não uma escala individual de funcionários. Não há bloqueio provisório, roteirização entre locais, cálculo automático de deslocamento da equipe nem conversão de catálogo em estoque. Buffers de material existentes são respeitados. Referências da calculadora só aparecem quando o contrato tem vínculo explícito, sem inferir relações por data ou nome. Sem dados de horário/material, o sistema não atesta disponibilidade completa.

Não foram executados teste manual no aplicativo Windows instalado, deploy, produção ou ciclo HTTPS com Firebase Auth hospedado. O escopo foi validado com backend/Firestore emulado, regras e Flutter; esses limites não equivalem a validação em produção.
