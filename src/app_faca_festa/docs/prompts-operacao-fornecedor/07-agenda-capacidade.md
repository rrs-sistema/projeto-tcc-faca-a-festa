# Prompt 07 — Agenda e capacidade operacional do fornecedor

Implemente agenda e identificação de conflitos operacionais do fornecedor no Faça a Festa, repositório `D:\repository\unicesumar\tcc\app\src\app_faca_festa`. Stack Flutter/GetX e Firebase/Functions TypeScript, Windows/PowerShell. Entregue implementação integrada e testes.

Leia AGENTS.md e Git; preserve alterações existentes. Não faça deploy, commit/push ou mudanças em produção. Descubra e reutilize agenda, capacidade, reservas de estoque e execução já existentes, inclusive na calculadora e contratação. Não faça um calendário isolado nem crie compromisso duplicado.

## Objetivo

O fornecedor deve saber o que precisa executar, quando preparar/montar/retirar e se tem capacidade para aceitar outra contratação. Reutilize a identidade real do contrato e o estado operacional vigente. Se a jornada ainda estiver incompleta, implemente apenas a menor base necessária para compromissos reais.

## Implementação

1. Liste compromissos contratados em visão de agenda e próximos eventos, com data, intervalo, fuso, local compartilhável, serviço e pendências. Diferencie evento de janela de montagem, execução e retirada. Registros sem horário ficam pendentes de definição, sem horário inventado.
2. Diferencie consulta comercial, bloqueio provisório e reserva confirmada. Cotação aberta não deve consumir automaticamente toda a capacidade. Se houver bloqueio provisório, use validade e expiração explícitas.
3. Permita configurar capacidade simples adequada ao modelo atual: equipe/recurso ou simultaneidade. Não assuma que todo fornecedor atende apenas um evento por dia. Identifique conflitos de intervalos e insuficiência de recursos/reservas quando disponíveis.
4. Revalide capacidade na confirmação/reagendamento em transação ou mecanismo equivalente. Defina quais conflitos bloqueiam e quais exigem decisão fundamentada; alerta visual sozinho não protege concorrência.
5. Cancelamento libera reservas corretamente; reagendamento mantém histórico e reavalia conflitos. Retorno de itens reutilizáveis não é consumo definitivo. Reutilize o estoque privado sem converter produto do catálogo em material interno automaticamente.
6. Controle acesso por fornecedor e mantenha agenda interna privada. Cliente vê somente disponibilidade/compromisso permitido, não detalhes de terceiros. Datas exibidas devem seguir o fuso do compromisso e o padrão do aplicativo.

## Aceite e validação

Capacidade 1 e compromissos sobrepostos geram conflito; capacidade 2 permite dois e detecta o terceiro. Serviços em horários compatíveis não são bloqueados apenas por serem no mesmo dia. Duas confirmações concorrentes não ultrapassam a capacidade. Reagendamento e cancelamento atualizam reservas sem apagar histórico. Uma consulta comercial não cria reserva definitiva.

Teste limites de intervalo, virada de dia, fuso, horário ausente, concorrência, cancelamento e autorização. Execute testes de domínio/backend/regras e widgets pertinentes. Registre decisões e evidências em `docs/evidencias_validacao/operacao-fornecedor/07-agenda-capacidade.md`, explicitando recursos suportados e limitações.
