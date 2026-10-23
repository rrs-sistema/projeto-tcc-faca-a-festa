# Prompt 03 — Central administrativa de contratações e mediação

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

Evolua a visão administrativa de agregados para central operacional capaz de identificar partes, acompanhar contratação/serviço e mediar divergências. Aparência premium deve apoiar a operação, não substituir sua base.

## Investigue

`lib/presentation/modules/financeiro/pages/dashboard_financeiro_admin_page.dart`, controller/datasource, callable `consultarDashboardFinanceiroAdmin.ts`, `dashboardAdminService.ts`, contratos, snapshots, financeiro e auditoria. Na versão examinada, “Detalhes” expande contagens e ID, sem necessariamente resolver cliente, fornecedor, escopo e ações de mediação.

## Entrega

1. Preserve visão financeira executiva, mas acrescente acesso a “Contratações e mediação”. Lista principal por contratação, com agrupamento opcional por evento, evita esconder fornecedores em uma única linha agregada.
2. Colunas essenciais: evento/data, cliente contratante, fornecedor/empresa, serviço/escopo curto, valor, recebido do cliente, repassado, saldo pertinente, execução e pendência. Organizador/pagador diferentes ficam identificados no detalhe; não crie “saldo” ambíguo somando dinheiro do cliente com dívida do fornecedor.
3. Busca por evento, cliente, fornecedor, serviço e referência; filtros por estado comercial, financeiro, execução, caso aberto, responsável e período com eixo explícito. Fonte autorizada, paginação e completeness. Contadores/gráficos não tratam amostra de 500 registros como total global.
4. Detalhe em áreas Partes, Contratação/Serviço, Financeiro e Histórico/Mediação, com resumo visível. Mostrar contatos autorizados e referência de contratação, não exigir UIDs para trabalhar.
5. Caso de mediação contém contrato/evento, partes, motivo/categoria, descrição, operador responsável, prioridade, estado, registros cronológicos, anexos autorizados e conclusão. Distinguir nota interna da equipe de informação compartilhável às partes.
6. Permita atribuir responsável, registrar análise, solicitar informações dentro do fluxo disponível e registrar decisão. Não envie email/WhatsApp ou mensagem externa. Comunicação com partes só por canal existente e ação explícita do usuário operador, sem disparo automático nesta entrega.
7. “Pedido de reembolso”, “solicitação de cancelamento” e decisão administrativa são diferentes do efeito financeiro. Decisão referencia comandos autorizados/validados; não altera saldo apenas mudando status do caso.
8. Bloqueio operacional para revisão, quando suportado, atua apenas sobre valor/contrato afetado, exige motivo/permissão e não afeta todos os fornecedores do evento. Se política não definida, registre recomendação de revisão sem criar retenção automática.
9. Histórico identifica quem alegou entrega, quem aceitou/contestou, decisões, recebimentos, alocações e repasses. Não afirme entrega só porque pagamento ocorreu.
10. Preserve permissões por capacidade: consulta comercial, notas internas, decisão de mediação e autorização financeira, respeitando modelo vigente; se inexistentes, implemente mínimo explícito, sem confiança em flag local.

## Aceite

- Operador identifica cliente, fornecedor e serviço sem copiar IDs ou abrir cadastro manualmente.
- Evento com dois fornecedores permite caso sobre um contrato sem bloquear o outro automaticamente.
- Cliente vê apenas histórico compartilhável do próprio caso; fornecedor só seus contratos; nota interna não vaza em exportação/anexo.
- Fechar caso não executa reembolso/repasse silencioso.
- Vários estados separados e pendências de identificação/financeiro ficam visíveis.
- Uso desktop/mobile, teclado e detalhe preservam filtros/posição na volta.

Evidência: `docs/evidencias_validacao/mediacao/03-central-administrativa-mediacao.md`.
