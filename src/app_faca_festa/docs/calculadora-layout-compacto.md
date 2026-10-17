# Calculadora: revisão visual local — 15/10/2026

## Alterações

- Diagnóstico resumido; premissas, ressalvas de validade e vínculo dos gastos ficam acessíveis na expansão.
- Sugestões com quantidade e preço em destaque, base por pessoa/serviço e estado de compra em linhas compactas.
- Modos de planejamento menores, mantendo descrição, contraste, seleção explícita e semântica de acessibilidade.
- Lista do cardápio mostra a porção configurada no lugar da instrução repetida de edição.
- Resumo financeiro com valores alinhados; em texto ampliado, rótulo e valor se empilham.
- Próximas ações alinhadas à esquerda, com alvos mínimos de 48 px.
- Seletor de calibração acompanha o conteúdo e limita sua altura, com rolagem para listas maiores, fechamento e área segura.
- Detalhes em modal com quantidade destacada, explicação expansível e ação de edição fixa no rodapé.
- Regra de consumo com superfície branca, campos e espaçamentos menores; confirmação fixa e comportamento do teclado preservados.
- Modais de edição/detalhes acompanham o tema do evento.
- A ação indisponível de editar a seleção fica oculta durante a revisão do cardápio; edição das porções continua em Planejamento e nos detalhes.

## Verificação

- `npm run test:calculadora`: 62 testes Flutter aprovados, checagem TypeScript e testes de planejamento/callable aprovados.
- Jornada móvel executada novamente após os ajustes finais; inclui detalhes expansíveis, edição, comparação e seletor de calibração.
- Testes existentes de formulário com teclado aberto e texto ampliado preservados.
- Revisão das capturas geradas pelo teste em `.dart_tool/qa-calculadora/`: jornada-mobile, planejamento-mobile, detalhe-mobile, regra-mobile e seletor-mobile.
- As capturas usam dados de teste e não comprovam o consumo real da festa. O ambiente de teste não renderiza todos os emojis.

Escopo exclusivamente visual. Motor de cálculo, regras e dados de consumo preservados. Sem alteração de versão, build de distribuição ou deploy.

## Complemento: perfis e modais de planejamento

- Perfis Econômico, Padrão e Premium na mesma linha, com larguras iguais e alvos mínimos de 48 px. Com fonte ampliada ou largura insuficiente, a linha permite rolagem horizontal sem truncar os nomes.
- Comparação e cobertura compartilham modal branco com cabeçalho, botão de fechar, conteúdo rolável e ações fixas no rodapé. Tema do evento preservado.
- Comparação com alerta de preços ausentes, quantidades propostas por item e regras do cenário expansíveis; sem alterar cálculo ou confirmação de adoção.
- Cobertura mostra serviço, orientações e contador de seleção, preservando associação integral e cancelamento sem gravação.
- Jornada verifica os três perfis visíveis em 360 px, seleção de perfil, fonte ampliada, botões acessíveis no modal e cancelamento da cobertura sem alteração do orçamento.
- 62 testes Flutter aprovados após o complemento; análise estática sem problemas. Capturas adicionais: perfis-mobile, comparacao-mobile e cobertura-mobile.
- Sem deploy ou alteração de versão.
