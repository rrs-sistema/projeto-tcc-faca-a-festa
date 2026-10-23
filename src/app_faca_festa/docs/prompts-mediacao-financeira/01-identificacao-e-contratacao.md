# Prompt 01 — Identificação das partes e contratação rastreável

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

Faça cada contratação responder: qual evento, quem está contratando, quem organiza, quem paga, qual empresa fornece, qual serviço foi vendido e se foi executado. Entregue a informação na consulta e no detalhe administrativos, não apenas novos campos sem leitores.

## Pontos de entrada a confirmar

`lib/domain/entities/orcamento.dart` já prevê id/nome de fornecedor e solicitante. Investigue Evento/Fornecedores/Usuários, cotação e aceite; `lib/domain/entities/financeiro/contrato_financeiro.dart`; `functions/src/functions/financeiro/consultarDashboardFinanceiroAdmin.ts`; `functions/src/services/financeiro/dashboardAdminService.ts`; datasource `dashboard_financeiro_admin_remote.dart` e página correspondente. A consulta observada retorna IDs e agregados, sem necessariamente carregar os nomes e vínculos necessários.

## Entrega

1. Mapeie fontes autoritativas e significado de cada identidade atual. Solicitante do orçamento não é automaticamente parte contratante; proprietário do evento não é necessariamente pagador. Mantenha esses papéis explicitamente identificados.
2. Formalize contratação com identificadores de evento, pedido se aplicável, necessidade, orçamento/proposta aceita, contratante, empresa fornecedora e serviços. Use uma empresa fornecedora por contrato ou documente desmembramento; itens do mesmo fornecedor podem compor o contrato.
3. Snapshot servidor da identidade comercial e condições no aceite, com data/versão/origem, preserva quem contratou e forneceu na época. Perfil atual fica separado; mudança de nome não reescreve histórico. Snapshot não concede autorização.
4. Registre linhas: serviço, descrição/escopo, quantidade/unidade, data/local pertinentes, inclusões/exclusões e valor combinado. Preserve preço, termos e aceite histórico. Identifique responsável do APP por acompanhamento quando atribuído.
5. Estados de execução como agendado/em execução/entrega informada/aceite/contestação só usam fatos registrados por atores autorizados. Separe declaração do fornecedor de aceite do cliente e da mediação administrativa. Contrato fechado não vira serviço concluído.
6. Enriquecer consulta com nomes do evento, contratante/organizador e fornecedores, sem N+1 irrestrito: leitura em lote/projeção segura, paginação e completude. Busca por nomes/referência com índices/projeções coerentes, sem fazer a pessoa digitar UID.
7. Detalhe do evento lista contratos por fornecedor; detalhe de contratação exibe partes, escopo, termos e execução. Não atribua fornecedor único ao evento que tem vários. IDs completos ficam em detalhes técnicos.
8. Legados sem identidade confiável recebem pendência de identificação, com revisão autorizada e auditada. Não preencher usando semelhança de nomes, primeiro fornecedor encontrado ou usuário logado.

## Aceite

- Um evento com dois fornecedores mostra o mesmo organizador e duas contratações identificadas, com respectivos serviços.
- Pagador diferente do contratante não troca titularidade ou permissão do evento.
- Alteração de nome do fornecedor preserva snapshot e evidencia perfil atual separado.
- Oito oportunidades sem contratação não aparecem como oito serviços efetivamente prestados.
- Dados legados incompletos continuam marcados; outro fornecedor não consulta contrato alheio.
- Contratado e executado/aceito aparecem em estados distintos.

Evidência: `docs/evidencias_validacao/mediacao/01-identificacao-e-contratacao.md`.
