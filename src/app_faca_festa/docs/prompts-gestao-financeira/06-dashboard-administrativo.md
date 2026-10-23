# Prompt 06 — Dashboard financeiro da administração

## Contexto e execução independente

Atue como desenvolvedor sênior Flutter/Firebase e analista financeiro de eventos. Implemente a atividade deste prompt no Faça a Festa com comportamento integrado e verificável. Este arquivo contém todo o contexto necessário: não exige histórico de outro chat, leitura de outro prompt ou etapa anterior executada pelo usuário.

Repositório: `D:\repository\unicesumar\tcc\app\src\app_faca_festa`. Ambiente Windows/PowerShell. Stack observada: Flutter/Dart, GetX, Firebase Auth, Firestore e Cloud Functions TypeScript em `functions/`.

Antes de editar, leia os AGENTS.md aplicáveis, examine o Git e confirme os comportamentos atuais. Preserve alterações preexistentes. Os caminhos citados são pistas que precisam ser confirmadas. Reutilize entidades, autorização, serviços e interface adequados, sem criar um financeiro paralelo. Se faltar uma dependência necessária ao objetivo, implemente somente a menor base real e reutilizável para entregá-lo. Não exija a execução de outro prompt nem entregue telas desconectadas, mocks de produção ou apenas documentação.

## Contrato financeiro e técnico obrigatório

- Estimativa, cotação, contratação, custo realizado, obrigação e pagamento são fatos distintos. Planejamento aprovado não significa compra, contratação ou pagamento. Cotação não aceita não é dívida ou receita garantida.
- Separe evento, empresa fornecedora e plataforma. Volume contratado não é receita da plataforma. Custos e margens internos são privados do fornecedor. Seu acesso não inclui orçamento global do cliente.
- Gerente significa responsável autorizado pelo evento. Descubra o modelo de autorização; se necessário, estabeleça vínculo explícito por evento. Rótulo de interface não concede permissão. Administrador não recebe automaticamente acesso a custos privados.
- Valores monetários novos usam centavos inteiros em BRL, limites e arredondamento explícitos. Adapte campos legados em double com compatibilidade e sem migração silenciosa em produção.
- Cada fato tem identidade, origem, titular/perspectiva, evento e vínculos pertinentes. Não duplique valores entre orçamento legado, contrato, compra e estoque. Propostas alternativas para uma necessidade não são somadas como compromisso.
- Pagamento e recebimento têm perspectivas definidas. Uma liquidação compartilhada pode alimentar duas visões, mas não duas movimentações na mesma visão. Diferencie registro manual declarado de confirmação externa. Não copie automaticamente registros privados do cliente como recebimento comprovado do fornecedor.
- Preserve descontos, adiantamentos, multas, estornos, reembolsos e créditos explicitamente. Não esconda pagamentos excedentes com clamp. Retificações preservam histórico, autor, data, motivo e origem.
- Ausente, zero confirmado, consulta incompleta, erro, cache e sincronização pendente não são equivalentes. Informação incompleta não sustenta afirmação de economia, lucro ou quitação.
- Valide cálculos e comandos críticos no backend. Functions com Admin SDK verificam autorização própria. Use idempotência, transações e controle de concorrência onde necessário. Troca de sessão/evento deve cancelar listeners e invalidar callbacks antigos.
- Proteja leituras, subcoleções, comandos, anexos, agregados, logs e exportações. Interface em português, responsiva para celular/web/desktop e fonte ampliada, com origem, filtros e atualização dos números. Reutilize padrões visuais existentes.
- Não faça deploy, alterações em produção, migração destrutiva, commit ou push. Não execute cobrança real nem envie mensagens externas. Testes autenticados usam dados sintéticos e projeto demo/emuladores, recusando produção.

## Validação e entrega

Implemente as camadas pertinentes: domínio, persistência, backend/permissões e interface. Confira os scripts atuais antes de usá-los. Existem referências a `flutter test`, `npm --prefix functions run build`, `npm --prefix functions run check:calculadora`, `npm run test:rules` e `npm run test:rules:calculadora`; selecione os adequados e adicione testes específicos necessários. O lint das Functions pode apenas informar que foi ignorado; isso não comprova análise estática.

Execute formatação, análise estática e testes pertinentes, inclusive regras e Functions separadamente, acesso negado, repetição e concorrência quando aplicáveis. Não corrija problemas alheios ao escopo. Falta de aparelho/credencial não impede trabalho independente: entregue roteiro reproduzível e explicite o que não foi executado. Mocks não comprovam integração Firebase.

Registre evidência no caminho indicado ao final: diagnóstico, regras, arquitetura, arquivos, formato persistido, compatibilidade, índices, testes/resultados reais, limitações e ativação posterior sem publicação. Ao concluir, explique comportamento entregue, pendências e alterações preexistentes relevantes.

## Objetivo

Implemente dashboard financeiro/comercial administrativo com oportunidades, contratações, execução e receitas próprias da plataforma, integrado aos painéis existentes e a consultas adequadas à escala.

## Investigue

`lib/presentation/modules/admin/pages/admin_dashboard_screen.dart`, seções admin_dashboard, controller, listas administrativas de eventos/orçamentos, `lib/data/datasources/remote/orcamentos_admin_remote_datasource.dart`, OrcamentoAdmin, Functions financeiras, autorização e auditoria.

## Requisitos

1. Adicione Financeiro sem substituir métricas operacionais por valores de outro significado. Mostre oportunidades abertas/negociação, contratos confirmados, eventos em execução/realizados, serviços e fornecedores distintos.
2. Conte entidades por identidade: evento com três fornecedores continua sendo um evento; cinco linhas não são cinco contratos; categoria não substitui serviço.
3. Separe valor de oportunidades, volume contratado, pagamentos dos eventos e receita própria da plataforma. Alternativas da mesma necessidade não inflacionam previsão.
4. Comissões: previstas, geradas, a receber, vencidas, recebidas e ajustadas. Sem política/dados válidos, mostre não configurado. Implemente apenas a base mínima necessária à consulta, sem inventar percentual ou ativar cobrança presumida.
5. Resultado gerencial exige despesas próprias e fórmula/abrangência explícitas. Sem despesas completas, apresente receitas/movimentos sem rotular como lucro líquido.
6. Tabela por evento: data, status, quantidade de serviços, contratado, pago conhecido, saldo, previsão disponível e comissão. Abra detalhes autorizados. Total do evento repetido em várias linhas não é somado novamente.
7. Filtros por período, data do evento/contratação, vencimento/liquidação, fornecedor e estado. Cada card/gráfico informa eixo temporal. Conversão exige denominador, janela/coorte e deduplicação definidos.
8. Evite carregar todos os gastos a cada abertura. Agregados seguros no backend, se necessários, suportam reprocessamento e gatilhos repetidos/fora de ordem. Documente índices, consistência e reconstrução sem backfill de produção.
9. Estados de consulta e atualização ficam visíveis. Exportação, se implementada, usa os mesmos filtros e permissões.

## Critérios de aceite

- Dois eventos com três contratos cada: dois eventos e seis contratos.
- R$ 100.000 movimentados e R$ 5.000 de comissão não aparecem como R$ 100.000 de receita própria.
- Reabrir painel/repetir gatilho não altera totais.
- Totais conciliam com origens autorizadas, inclusive orçamento com categoria e pagamento parcial.
- Custos/margens privados não vazam pelo dashboard, agregado ou exportação.

Evidência: `docs/evidencias_validacao/financeiro/06-dashboard-administrativo.md`.
