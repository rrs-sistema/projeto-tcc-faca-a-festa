# Prompt 05 — Percentual e comissões da plataforma

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

Implemente configuração e controle da comissão por contratação elegível, consolidada por evento: política, simulação, geração da obrigação, liquidação manual e ajustes, sem cobrança externa.

## Política proposta e decisões comerciais pendentes

Calcule preferencialmente sobre serviços efetivamente contratados pela plataforma, não sobre o limite global do cliente. Contratação confirmada, evento realizado e comissão recebida são estados distintos.

Pagador, componentes elegíveis, exigibilidade, vencimento, retenções e cancelamentos ainda não foram aprovados. Modele essas escolhas expressamente. Novas políticas ficam inativas por padrão; simulações usam dados sintéticos. Não gere dívida retroativa ou cobrança real a partir de decisões presumidas. Preserve políticas válidas já existentes.

## Investigue

Módulos administrativos, orçamento/cotação e confirmação de contratação, entidades de fornecedor/evento, Functions, regras, auditoria e infraestrutura financeira existente.

## Requisitos

1. Configure percentual, vigência, base elegível, pagador, gatilho de geração, condição de vencimento e ajustes. Valide de 0% a 100%, precisão e arredondamento; zero válido difere de configuração ausente.
2. Grave versão imutável da política aplicada ao contrato, base, percentual, valor, autor e data. Mudança global não recalcula contratos anteriores silenciosamente.
3. Base líquida elegível considera descontos e exclusões definidos. Não inclua custos privados ou contratações externas sem autorização comercial.
4. Política ativa válida gera obrigação uma única vez no gatilho definido. Diferencie previsão, gerada, a vencer, vencida, recebida e estornada, sem inferir reconhecimento contábil formal.
5. Aditivos, descontos posteriores, cancelamento parcial e reembolso produzem ajustes vinculados e históricos. Atualização do contrato não recria a cobrança original.
6. Liquidação manual/estorno exigem autorização e identificação como registro manual, sem afirmar confirmação bancária. Diferencie permissão de configurar política e liquidar quando o modelo suportar.
7. Extrato administrativo e visão do próprio pagador sem acesso cruzado. Audite mudanças sensíveis.

## Critérios de aceite

- Política sintética ativa 5%, base R$ 10.000: R$ 500 gerados uma única vez.
- Alterar taxa futura para 6% preserva os R$ 500 anteriores.
- Liquidação R$ 200 deixa saldo R$ 300.
- Quando a política prevê reversão proporcional, redução elegível R$ 2.000 gera ajuste R$ 100 e eventual crédito/reembolso explícito.
- Política ausente/inativa/incompleta não gera dívida; simulação não altera financeiro.
- Alteração não autorizada de taxa é rejeitada no backend.

Evidência: `docs/evidencias_validacao/financeiro/05-comissoes-plataforma.md`.
