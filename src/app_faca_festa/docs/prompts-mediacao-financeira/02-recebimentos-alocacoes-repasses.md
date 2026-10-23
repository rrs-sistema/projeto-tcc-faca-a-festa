# Prompt 02 — Recebimentos da plataforma, alocações e repasses

## Contexto e missão independente

Atue como analista de sistemas sênior, especialista em operações financeiras de marketplace e desenvolvedor Flutter/Firebase. Implemente a entrega específica deste arquivo no Faça a Festa. O cliente/organizador contrata serviços para seu evento, mas efetua pagamento à equipe/plataforma Faça a Festa; o fornecedor recebe repasses acompanhados pela plataforma. O administrador precisa identificar quem contrata, quem fornece, o serviço, a execução e a situação do dinheiro para fazer mediação.

Repositório: `D:\repository\unicesumar\tcc\app\src\app_faca_festa`, Windows/PowerShell, Flutter/Dart/GetX, Auth/Firestore e Functions TypeScript em `functions/`. Este prompt é autossuficiente para chat novo. Confira AGENTS.md, Git, código e contratos vigentes; preserve alterações preexistentes. Reutilize a estrutura adequada, sem financeiro paralelo. Dependência ausente exige somente a base mínima necessária ao objetivo, não outro prompt executado previamente.

Esta entrega é evolução estrutural, diferente dos prompts anteriores restritos à aparência. Pode alterar domínio, persistência, backend e UI dentro do escopo específico. Não diagnostique erros genéricos de conexão das capturas nem substitua integração por dados fictícios.

## Regras compartilhadas

- Contratação é a unidade de acompanhamento de serviço/fornecedor, vinculada a pedido/evento. Um evento pode ter diversos contratos e fornecedores; um pedido pode reunir vários contratos com alocação explícita. Propostas alternativas não são contratações somadas.
- Separe proprietário/organizador do evento, contratante e pagador; não presuma serem sempre a mesma pessoa. Prestador contratado, usuário que opera sua conta, beneficiário e operador administrativo são papéis distintos. Identidades e permissões devem vir de vínculos confiáveis, nunca do texto enviado pelo cliente.
- Contrato formalizado não comprova serviço prestado. Preserve estados de negociação/contratação, execução/aceite, recebimento do cliente, repasse e mediação em dimensões separadas.
- “Pago pelo cliente”, “recebido pela plataforma”, “repassado ao fornecedor” e “comissão” são fatos distintos. Dinheiro de terceiros pendente de destinação não vira receita própria pelo simples recebimento. Métricas são operacionais; não afirme enquadramento contábil/jurídico/fiscal.
- A nova direção não define prestador de pagamentos, custódia/escrow, regras jurídicas, taxas, gatilho de liberação, política de disputa ou cancelamento. Não invente essas decisões. Entregue configurações inativas e simulação onde faltarem políticas; preserve regras ativas válidas existentes. Não bloqueie todo trabalho independente por falta dessas escolhas.
- Não implemente movimentação bancária real, integração financeira ao vivo, recebimento de dados de cartão ou coleta de credenciais. O controle manual autorizado precisa distinguir declaração, conferência e confirmação por fonte externa. Uma atualização da UI não comprova transferência.
- Use centavos inteiros BRL, validação no backend, limite/precisão e idempotência por operação. Atualizações concorrentes não podem gastar/alocar o mesmo valor duas vezes. Histórico imutável/ajustes vinculados explicam reversões, crédito, estorno, reembolso e taxas sem apagar os fatos.
- Dados antigos de “pago” não provam recebimento pela plataforma ou repasse. Preserve origem e conciliação pendente. Não execute migração em produção, crie vínculos por semelhança de nome ou transforme todos os eventos antigos em operações intermediadas.
- Administração pode acessar partes e valores necessários à operação e mediação autorizada, preservando custos internos/margens privadas do fornecedor. Contatos, documentos, anexos e notas internas têm acesso mínimo por finalidade. Acesso comercial não libera dados bancários completos.
- Functions com Admin SDK verificam autenticação/autorização; IDs e snapshots são validados no servidor. Controle consulta, comandos, agregados, exportações e anexos. Troca de sessão/evento não mantém callbacks ou detalhes alheios. Sem segredos/dados pessoais reais em logs/testes.
- UI premium em português, nomes e referências compreensíveis em vez de IDs como título, desktop/mobile/teclado/fonte ampliada. Informação incompleta/ausente não é zero; consulta parcial/paginada não pode parecer total completo.

## Validação e entrega

Implemente verticalmente as camadas pertinentes. Verifique scripts atuais; há testes Flutter, rules e build TypeScript. Rode formatação, análise estática e testes adequados, inclusive backend/regras, acesso cruzado, repetição e concorrência. Testes autenticados usam projeto demo/emuladores e recusam produção. Fixtures de preview são isoladas de produção.

Sem deploy, alteração de produção, migração destrutiva, commit/push, envio de mensagens externas ou ativação de cobrança/repasse reais. Ao faltar recurso externo, conclua o trabalho independente, entregue roteiro reproduzível e descreva o que não foi executado. Não afirme homologação sem evidência.

Registre no caminho indicado: diagnóstico, escolhas e decisões ainda pendentes, arquivos, contrato de dados/API, compatibilidade/migração dry-run, índices, permissões, testes reais, capturas pertinentes e ativação futura sem publicação. Ao concluir, informe entrega, riscos/limitações e alterações anteriores preservadas.

## Objetivo

Estruture controle operacional cliente → plataforma → fornecedor, sem movimentação bancária real. Preserve o dinheiro recebido do cliente, sua alocação por contrato, remuneração do APP e repasses como fatos diferentes, conciliáveis e auditáveis.

## Investigue

Entidades financeiro/contrato, obrigação, liquidação, comissão, serviços `functions/src/services/financeiro/liquidacaoFinanceiroService.ts`, `contratoFinanceiroService.ts`, `comissaoPlataformaService.ts`, comandos financeiros, consultas administrativas, gateway existente e rules. Aproveite contratos e centavos vigentes, sem tratar pagamento legado ao fornecedor como entrada do APP.

## Entrega

1. Obrigação do cliente/pedido indica pagador, favorecido operacional, parcelas e vencimento. Recebimento tem valor, origem, referência, data, confirmação e operador; vinculação ao pedido não basta para provar destino por fornecedor.
2. Alocação identifica quanto de cada recebimento foi atribuído a cada contrato. Suporte parcial e múltiplos recebimentos, sem alocar acima do confirmado/disponível. Valor não identificado ou sem alocação fica visível em conciliação pendente, sem comissão/repasse presumidos.
3. Se pagamento único cobre vários fornecedores, registre cada destinação. Defina critério manual explícito; não rateie silenciosamente por igual ou proporcionalmente sem regra escolhida. Idempotência e transação protegem alocação e reserva de repasse.
4. Calcule remuneração do APP pela política versionada elegível. Defina se comissão é descontada do fornecedor ou cobrada além do cliente somente quando configurado. No modelo de desconto, não crie cobrança adicional duplicada de comissão ao fornecedor.
5. Repasse tem contrato, fornecedor/beneficiário validado, valor, recebimentos de origem e estados separado: previsto, elegível conforme política, autorizado, em processamento, confirmado, falhou/cancelado, conforme operações disponíveis. Não anuncie banco integrado. Confirmação manual é identificada como conferência/registro manual, com evidência e auditoria.
6. Política de liberação ainda não definida não deve autorizar repasse automaticamente. Apresente elegibilidade pendente e permita simulação. Não hardcode pagamento integral, término do evento ou aceite como gatilho universal sem regra comercial válida.
7. Saldo recebido, valores alocados, compromissos reservados para repasse, repassado, remuneração separada e reembolsável devem conciliar sem somar saldos de dimensões sobrepostas. Defina invariantes por movimento/contrato e razão auxiliar rastreável, não um campo “saldo” editável.
8. Reembolso/chargeback depois de repasse não apaga saída anterior. Registre ajuste e necessidade de recuperação/cobertura, separando crédito de caixa disponível. Cancelamento não devolve automaticamente valor já repassado.
9. Entregue telas mínimas de recebimento, alocação e preparação/conferência de repasse nos contratos autorizados. Não cadastre conta bancária sensível em campo livre ou exporte dados completos.

## Aceite com política sintética explícita

- Contrato R$ 10.000, comissão descontada 5%: direito total previsto do fornecedor R$ 9.500, sem nova cobrança duplicada de R$ 500.
- Recebimento parcial R$ 4.000, sem política de liberação: saldo do cliente R$ 6.000; não marque fornecedor como tendo recebido R$ 4.000 nem libere repasse automático.
- Sob regra sintética que autoriza repasse parcial de R$ 3.000, confirme uma vez: repassado R$ 3.000; diferença de caixa R$ 1.000 antes de outros movimentos continua com destinação demonstrável, sem virar automaticamente receita do APP.
- Recebimento R$ 6.000 não pode ser alocado R$ 4.000 a A e R$ 3.000 a B; concorrência e retry preservam limite.
- Aprovar repasse não equivale a transferência confirmada; falha não baixa saldo como sucesso.

Evidência: `docs/evidencias_validacao/mediacao/02-recebimentos-alocacoes-repasses.md`.
