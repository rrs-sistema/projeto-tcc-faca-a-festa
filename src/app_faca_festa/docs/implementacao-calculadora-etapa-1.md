# Calculadora inteligente — primeira etapa da auditoria

Implementação local em 14/10/2026. Referência: auditoria-calculadora-inteligente-2026-10-14.md.

## Entregue

- Diagnóstico determinístico independente de resultado e de IA generativa, no início da etapa de sugestões.
- Mostra pessoas, cobertura de consumo do cardápio, itens sem regra, preços pendentes e regras inválidas.
- Ações para informar pessoas, usar o cardápio e configurar o primeiro item pendente. Não gera porções fictícias.
- Detecta possíveis acompanhamentos pelo nome e alerta para revisão conjunta. É uma indicação baseada em palavras, não um ajuste automático de consumo.
- Nomes com emojis e pontuação passam a corresponder; a regra aplicada preserva o nome do cardápio.
- Regras do público específico têm prioridade sobre regras para todos. Duplicatas do mesmo público permanecem ambíguas e não são escolhidas automaticamente.
- Regras inválidas são rejeitadas individualmente e identificadas; cálculo com catálogo parcialmente inválido é marcado parcial.
- Ausência de catálogo não exibe retry técnico; erro de carregamento continua permitindo retry.
- Descartáveis usam contagem física do público, sem multiplicadores de perfil ou duração. A margem explícita ou padrão ainda é aplicada como reserva.
- Orçamentos cancelados são excluídos do contexto. Gastos sem nome/unidade identificáveis mantêm seu valor e tornam a cobertura financeira parcial.
- Percentuais de risco, conforto e economia retirados da interface; campos mantidos no contrato por compatibilidade.

## Verificação

34 testes Flutter de calculadora/cardápio passaram, compilação TypeScript e testes do callable passaram. Análise estática dos arquivos de produção alterados sem problemas. Novo teste de widget usa largura de 360 pixels e texto ampliado em 1,5. Testes incluem diagnóstico sem catálogo, correspondência com emojis, preferência por público, rejeição parcial, descartáveis e cancelamento financeiro.

## Ainda pendente

Abastecimento e governança do catálogo de produção; regras contextualizadas de composição da refeição; aliases/IDs canônicos e conversões de embalagem/rendimento; reconciliação por serviço contratado e pagamentos; fonte única do limite financeiro; histórico com contexto completo; recomendações executáveis e avaliação da IA generativa em cenários reais.

Nenhum catálogo foi preenchido automaticamente: não há fonte aprovada para novos coeficientes de consumo/preços. Não houve publicação nem mudança de dados reais nesta etapa. O diagnóstico local funciona sem esse catálogo, mas o cálculo continua dependendo de regras cadastradas ou porções definidas pelo organizador.
