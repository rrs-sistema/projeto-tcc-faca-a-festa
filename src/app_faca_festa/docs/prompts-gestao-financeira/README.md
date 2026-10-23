# Prompts independentes — Gestão financeira Faça a Festa

Preparados em 21/10/2026. Este pacote contém instruções para implementação futura. Sua criação não implementa nem ativa funcionalidades financeiras.

## Como usar em chats novos

Copie integralmente um arquivo numerado e envie no novo chat. Alternativamente, anexe o arquivo e peça: “Execute integralmente o prompt anexado neste repositório”. Não precisa enviar o README nem o histórico da análise. Cada arquivo inclui contexto, regras, investigação, escopo, validação e entrega.

Cada prompt pede implementação futura no chat onde for executado, sem deploy, alteração de produção, commit ou push. Revise o escopo antes de enviá-lo.

## Atividades

| Arquivo | Entrega |
|---|---|
| [01-fundacao-financeira.md](01-fundacao-financeira.md) | Fundação financeira e conciliação |
| [02-gestao-financeira-evento.md](02-gestao-financeira-evento.md) | Dashboard financeiro do gerente do evento |
| [03-financeiro-fornecedor.md](03-financeiro-fornecedor.md) | Custos, caixa e resultado do fornecedor |
| [04-estoque-fornecedor.md](04-estoque-fornecedor.md) | Estoque, reservas e custos por evento |
| [05-comissoes-plataforma.md](05-comissoes-plataforma.md) | Percentual e comissões da plataforma |
| [06-dashboard-administrativo.md](06-dashboard-administrativo.md) | Dashboard financeiro da administração |
| [07-previsoes-e-cotacoes.md](07-previsoes-e-cotacoes.md) | Previsão financeira e cotação conforme orçamento |
| [08-validacao-integrada.md](08-validacao-integrada.md) | Validação integrada e preparação da ativação |

## Independência e ordem recomendada

Cada prompt é independente de contexto e não exige execução dos anteriores. Se faltar dependência necessária, o executor implementará somente a base mínima reutilizável do seu objetivo. Isso não torna as atividades independentes em arquivos, persistência ou regras de acesso.

Ordem recomendada para reduzir retrabalho: 01 → 02 → 03 → 04 → 05 → 06 → 07 → 08.

O prompt 08 valida o que estiver disponível e registra módulos ausentes. Não implementa o sistema inteiro para preencher a matriz.

Chats novos não exigem execução simultânea. Evite dois chats editando o mesmo checkout ao mesmo tempo. Execução concorrente requer checkouts isolados e integração deliberada dos modelos e permissões; numeração não resolve conflitos.

## Premissas e decisões comerciais

- Gerente é responsável autorizado pelo evento. Se for gerente da empresa fornecedora, revise essa premissa nos prompts afetados antes de executar.
- Percentual administrativo é interpretado como comissão da plataforma, por contratação elegível e consolidada por evento.
- Pagador, base elegível, exigibilidade, vencimento e cancelamento ainda precisam de decisão comercial. O prompt 05 permite configuração e simulação, deixando novas políticas inativas por padrão. Não autoriza cobrança real.
- Custos/margens internos pertencem ao fornecedor; limite global pertence ao evento. Acesso administrativo segue os limites explícitos.
- Exemplos numéricos são critérios de teste, não taxas comerciais aprovadas ou previsões reais.
- A investigação anterior foi leitura estática. Arquivos encontrados, inclusive não versionados, não comprovam disponibilidade na versão em uso ou integração homologada.

## Evidências

Cada implementação deve produzir relatório em `docs/evidencias_validacao/financeiro/`, conforme seu prompt. Esses relatórios serão produzidos na execução; não são entregas já validadas por este pacote.

A preparação deste pacote criou apenas Markdown e ZIP, sem alterar código de aplicação ou configuração.
