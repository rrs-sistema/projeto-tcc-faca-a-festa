# Prompt 01 — Fundação financeira e conciliação

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

Estabeleça a fonte confiável dos valores do evento, com consulta integrada de conciliação e comandos mínimos para fatos financeiros reais. Não implemente todos os dashboards, estoque empresarial ou comissão nesta atividade.

## Investigue

Entidades Orcamento, OrcamentoGasto e OrcamentoAdmin; serviços `lib/domain/services/resumo_financeiro_evento_service.dart` e `compromisso_planejamento_service.dart`; datasources `compromissos_evento_remote.dart`, `orcamento_gasto_remote_datasource.dart` e `orcamentos_admin_remote_datasource.dart`; controllers, Functions, `firestore.rules` e testes existentes.

## Requisitos

1. Mapeie significado e origem dos campos legados. Investigue o caminho administrativo que pode deixar de consultar pagamentos detalhados quando existe categoria; se confirmado, corrija e comprove conciliação com o detalhe.
2. Defina vínculo entre necessidade, alternativas de cotação, contratação e parcelas. Estado comercial, execução e liquidação são separados. Não use o maior valor entre estimado, gasto e realizado como substituto universal do contrato.
3. Modele contrato e alterações aprovadas se a estrutura vigente não representar esses fatos. Cancelamento preserva histórico, pagamentos, retenções e reembolsos.
4. Implemente obrigações e liquidações parciais pelos fluxos adequados. Excesso sobre saldo exige crédito/adiantamento explícito ou rejeição. Comandos repetidos não duplicam lançamentos.
5. Resumo por evento: limite confirmado, estimado, cotado, contratado, pago líquido, saldo devido e completude. Valores alternativos são comparáveis, não obrigações somadas.
6. Integre conferência à área de orçamento, permitindo abrir os registros que explicam os totais. Padronize os consumidores alterados nesta entrega.
7. Documente contrato reutilizável de domínio/persistência, índices e adaptação dos dados legados. Campos antigos não comprovam recebimento bancário ou custo privado.

## Critérios de aceite

- Contrato R$ 10.000, pagamento R$ 3.000: contratado R$ 10.000, pago R$ 3.000 e saldo R$ 7.000.
- Três propostas alternativas de R$ 4.000, R$ 4.500 e R$ 5.000 não geram dívida de R$ 13.500.
- Orçamento com categoria e pagamento detalhado concilia entre administração e detalhe autorizado.
- Repetição e duas liquidações concorrentes não excedem saldo sem regra explícita.
- Cancelamento com retenção/reembolso mantém histórico e saldo explicado.
- Acesso a evento alheio é rejeitado também pelas Functions.

Evidência: `docs/evidencias_validacao/financeiro/01-fundacao-financeira.md`.
