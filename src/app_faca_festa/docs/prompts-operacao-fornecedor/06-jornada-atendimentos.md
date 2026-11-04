# Prompt 06 — Jornada do atendimento até a entrega

Implemente a continuidade operacional do fornecedor no Faça a Festa. Repositório `D:\repository\unicesumar\tcc\app\src\app_faca_festa`, Windows/PowerShell; Flutter/GetX e Firebase/Functions TypeScript. Este prompt é autocontido e exige código e validação.

Leia AGENTS.md, inspecione Git e preserve alterações existentes, principalmente mediação, execução e repasses. Não faça deploy, commit/push, operações em produção ou mensagens externas. Não crie outro sistema de contratos, chat ou mediação.

## Problema e referências

O painel organiza pedidos em aguardando, respondidas e finalizadas. O filtro de finalizadas agrega concluídas, canceladas, recusadas e perdidas. Negociação encerrada não representa serviço executado. Inspecione `lib/presentation/modules/fornecedor/sections/solicitacoes_section.dart`, controllers de solicitações/cotações, chat, Functions de cotação e acompanhamento/mediação financeira.

## Implementação

1. Separe estado comercial de estado de execução sem substituir indiscriminadamente os estados existentes. Comercial: nova solicitação, proposta enviada, negociação e resultado ganho/perdido/recusado/cancelado. Execução: compromisso contratado, preparação/agendamento, execução, entrega informada e aceite/contestação conforme regras vigentes. Documente o mapeamento de legado.
2. Faça a contratação gerar ou vincular o compromisso operacional existente com identidade estável. Uma cotação ganha continua acessível para prestação, conversa e pendências; não some proposta e contrato como duas vendas.
3. No detalhe, conecte cliente autorizado, evento/data/local, escopo, condições, proposta, conversa e acompanhamento financeiro do próprio contrato. Não exponha orçamento global do cliente, dados de outros fornecedores ou custos privados.
4. Versione proposta, preço, descontos, validade e condições. Aceite deve apontar para a versão correta. Revisão após aceite não pode alterar silenciosamente o contrato; use o mecanismo de alteração existente ou o mínimo fluxo explícito e auditável.
5. Ofereça próxima ação, responsável, prazo de retorno e motivo estruturado de perda/cancelamento. Valide transições e autoria no backend, incluindo concorrência. Marcar mensagem como lida não aceita proposta, entrega ou repasse.
6. Preserve assistência por IA com revisão humana. Não envie proposta/mensagem automaticamente. Reutilize políticas existentes para retomada de conversa e notificações.

## Aceite

Solicitação recebida → resposta → negociação → contratação → preparação → entrega informada → aceite/contestação é navegável com histórico e mesma identidade. Pedido perdido não aparece como contratado nem serviço concluído. Cliente só aceita a versão vigente permitida; fornecedor não registra aceite em nome dele. A conversa continua disponível nas etapas operacionais autorizadas.

Teste transições válidas/inválidas, dupla confirmação, revisão concorrente, expiração e cancelamento. Corrija a incompatibilidade conhecida no fake de `test/features/cotacoes/cotacao_repository_test.dart` se ainda existir, preservando o contrato real do método e suas verificações. Execute testes de domínio, backend, regras e interface pertinentes. Registre decisões, compatibilidade e resultados em `docs/evidencias_validacao/operacao-fornecedor/06-jornada-atendimentos.md`.
