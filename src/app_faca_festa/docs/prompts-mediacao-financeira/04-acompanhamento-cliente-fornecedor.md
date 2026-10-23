# Prompt 04 — Acompanhamento das partes e validação da intermediação

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

Entregue transparência ao organizador e fornecedor sobre suas contratações e o fluxo com a plataforma, validando a ligação com a administração. Execute em chat novo; se faltar uma base indispensável, crie a menor estrutura necessária, sem simular produção ou exigir outro prompt.

## Investigue

Páginas `financeiro_gerente_list_page.dart`, `financeiro_gerente_detalhe_page.dart`, `financeiro_fornecedor_page.dart`, `comissao_plataforma_page.dart`, controllers, contratação/cotação, execução, recebimentos, alocações, repasses, mediação e autorização.

## Entrega

1. Organizador encontra evento → fornecedor → serviço/contrato, com escopo, valor combinado, parcelas e pagamento à plataforma. Diferencie declarado, conferido e confirmado. Explique status operacional de repasse apenas no nível permitido, sem expor dados bancários ou margens privadas.
2. Fornecedor vê quem o contratou, evento/data/escopo, valor contratado, comissão/regra aplicada, valor líquido previsto, repasse previsto/autorizado/confirmado e pendências do próprio contrato. Valores pagos pelo cliente ao APP não aparecem como entrada de caixa do fornecedor.
3. Separe recebimentos próprios de outras origens de repasses provenientes da plataforma, preservando identidade dos movimentos para não duplicar receita/entrada. Não transforme extrato de comissão em dívida duplicada quando ela é descontada do repasse.
4. Confirmação de execução é ação específica: fornecedor informa entrega e cliente registra aceite/contestação conforme regra vigente. Operador pode registrar decisão fundamentada, sem apagar as manifestações anteriores. Abrir detalhe ou ler mensagem não vale como aceite.
5. Se houver solicitação de mediação, permita abrir caso vinculado ao contrato por motivo/descrição com anexos seguros quando suportados. Cliente e fornecedor acessam somente histórico compartilhável; nota interna e contrato alheio permanecem privados.
6. Chamadas de ação refletem a infraestrutura real. Não exiba “Pagar agora”, “Sacar” ou “Pagamento garantido” se não existe integração/garantia configurada. Fluxo manual deve explicar instruções aprovadas e registro de comprovante, sem marcar transação confirmada pelo simples upload.
7. Interface traduz estados em próximos passos úteis, com responsável pelo próximo passo quando conhecido. Políticas ausentes são pendências de configuração, não promessas de prazo/reembolso. IDs ficam em referência técnica.
8. Execute cenário integrado com dois clientes, dois fornecedores e administrador usando emuladores, incluindo dados parciais, legado sem identificação, pagamento parcial, alocação, repasse e caso contestado.

## Aceite

- Ana contrata Decora Festas por R$ 10.000 e declara pagamento de R$ 4.000 ao APP. Antes da conferência, administração vê pendência e fornecedor não recebe entrada automática.
- Após confirmação autorizada, cliente mantém saldo R$ 6.000; fornecedor vê recebimento pela plataforma como estado comercial, não caixa próprio.
- Com política sintética de desconto de 5%, direito total previsto é R$ 9.500; repasse parcial confirmado R$ 3.000 deixa saldo previsto de repasse R$ 6.500, distinguindo parcela ainda não financiada/não elegível e sem prometer prazo.
- Outro fornecedor do mesmo evento não vê este contrato nem caso; outro cliente não acessa os dados.
- Repetição de confirmação/repasse não duplica movimentos. Caso contestado não provoca reembolso silencioso.
- Todos os totais disponíveis conciliam com os mesmos IDs/origens, sem considerar declaração como confirmação ou contrato como execução.

Evidência: `docs/evidencias_validacao/mediacao/04-acompanhamento-cliente-fornecedor.md`.
