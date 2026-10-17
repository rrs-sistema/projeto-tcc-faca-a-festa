# Público e estoque: revisão de ergonomia

Alterações locais de 16/10/2026. Sem publicação do aplicativo, deploy ou alteração do evento real.

## Diagnóstico

As telas mostravam títulos longos, texto operacional sem hierarquia, cadastro de lote sobre outro modal e ações com aparência diferente. Isso exigia leitura desnecessária e dificultava saber se o usuário estava no estoque ou no cadastro. Os campos herdados tinham pouca legibilidade.

## Implementação

- Estrutura compartilhada `CalculadoraModal`: título e contexto separados, conteúdo rolável e rodapé fixo, botões de no mínimo 48 px, cores e fonte herdadas do tema da festa.
- Público: total visível, distinção entre herdar participantes e personalizar a refeição, contadores legíveis, instruções menores, ação principal curta “Salvar ajustes”. Destinação por item continua recolhida.
- Estoque vazio: explicação objetiva do próximo passo e botão principal “Cadastrar lote”.
- Cadastro, edição e reserva: substituem o conteúdo da mesma janela. A seta, Cancelar e o voltar do Android retornam ao estoque; não existe um segundo modal por cima dele.
- Lotes: saldo livre destacado; total, reservado, unidade e estado separados das ações. Não somamos unidades incompatíveis.
- Máscaras, restrições alimentares, assinaturas de conferência, revisão concorrente e validações de saldo permanecem no fluxo. Salvamento bloqueia saída e envio repetido; erros preservam o rascunho.
- Controladores dos formulários são descartados somente depois que os campos desmontam.

## Validação

23 testes aprovados no conjunto de operação, ergonomia e jornada móvel. Inclui tela de 320 × 568, texto a 140%, teclado aberto, salvamento de decimal com vírgula, cancelamento, voltar do Android, concorrência e bloqueio durante envio. A jornada também cadastra um lote, reserva para a refeição e verifica o desconto na lista de compras.

Análise estática sem ocorrências nos cinco arquivos Dart envolvidos.

Capturas geradas por testes e inspecionadas visualmente em `.dart_tool/qa-calculadora/`: `publico-refeicao-premium-mobile.png`, `publico-refeicao-teclado-320px.png`, `estoque-vazio-premium-mobile.png`, `estoque-novo-lote-premium-mobile.png`, `estoque-lote-teclado-mobile.png`, `estoque-central-mobile.png`.

O teclado nas capturas é representado pela área reservada do sistema; os testes não renderizam o teclado Android. Esta revisão visual foi feita com widgets, sem nova instalação em aparelho físico.
