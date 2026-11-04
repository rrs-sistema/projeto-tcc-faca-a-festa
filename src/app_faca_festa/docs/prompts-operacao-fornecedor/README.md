# Implementação da operação do fornecedor

Prompts separados, preparados a partir da análise das telas e do código local em 23/10/2026. Os achados precisam ser reconfirmados no início de cada execução: o repositório contém alterações em andamento.

Cada arquivo contém um pedido de implementação completo e pode ser enviado individualmente a um chat com acesso ao repositório. Independente significa autocontido; algumas entregas compartilham contratos de dados. A ordem abaixo reduz retrabalho. Se uma base necessária ainda não existir, o executor deve implementar a menor base reutilizável e registrar a decisão, sem criar módulos paralelos.

| Ordem | Prompt | Resultado esperado |
|---|---|---|
| 01 | [Privacidade e integridade dos atendimentos](01-seguranca-atendimentos.md) | Conversas privadas e histórico protegido |
| 02 | [Unificação financeira por contrato](02-financeiro-contratos-repasses.md) | Bruto, comissão, líquido e repasses conciliados |
| 03 | [Recebimentos e caixa sem duplicidade](03-recebimentos-caixa-idempotencia.md) | Cada recebimento contado uma única vez |
| 04 | [Avaliações verificadas](04-avaliacoes-verificadas.md) | Origem, autoria e unicidade protegidas |
| 05 | [Gestão da reputação](05-gestao-reputacao.md) | Comentários, respostas e denúncias operacionais |
| 06 | [Jornada do atendimento à entrega](06-jornada-atendimentos.md) | Negociação e execução conectadas |
| 07 | [Agenda e capacidade](07-agenda-capacidade.md) | Compromissos e conflitos visíveis |
| 08 | [Planejamento e relatórios financeiros](08-planejamento-relatorios-financeiros.md) | Vencimentos, projeção e resultado por evento |
| 09 | [Painel operacional e indicadores](09-painel-indicadores.md) | Ações prioritárias e métricas rastreáveis |
| 10 | [Validação integrada](10-validacao-integrada.md) | Evidência reproduzível da jornada completa |

Dependências principais: 05 usa as garantias de 04; 07 usa a jornada de 06; 08 usa as bases de 02 e 03; 09 consome as bases das áreas anteriores; 10 verifica o conjunto. Execute 02 e 03 em sequência porque compartilham cálculos. Evite executar prompts que editam os mesmos arquivos simultaneamente.

Os prompts autorizam implementação e validação local. Não autorizam publicação, operações em produção ou movimentações financeiras reais. A execução deve terminar com alterações concretas e resultados de validação, sem ficar somente no planejamento.
