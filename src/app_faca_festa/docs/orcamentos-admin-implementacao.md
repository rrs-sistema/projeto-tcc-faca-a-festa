# Orçamentos administrativos — implementação local

23/10/2026. Revisão aplicada ao código, sem deploy ou alteração de versão.

- Formatação monetária única em reais, com separador de milhar e duas casas decimais, inclusive totais e detalhe.
- Resumo geral dos itens ativos; filtros de busca, negociação e saldo; eventos identificados em cartões próprios.
- Agrupamento e expansão por ID do evento. Itens sem vínculo não são reunidos pelo nome.
- Leitura de `nome_evento` e `nome_cidade`, com compatibilidade para `nome` e `cidade`; uso do ID do documento quando o orçamento legado não o contém.
- Consulta dos dados de cada evento compartilhada entre os itens da mesma atualização, sem manter um cache de eventos desatualizado entre consultas.
- Planejamento usa todos os itens ativos de cada evento e permanece consistente durante a busca.
- Percentual real, valor excedente, limite atingido e ausência de planejamento identificados explicitamente. Cancelados ficam fora dos resumos.
- Tabela no desktop e cartões em telas menores ou com texto ampliado. Detalhe consultivo por item, com referências recolhidas.
- Negociação e saldo são dimensões separadas; pagamentos desta tela são registros dos gastos, sem afirmar recebimento ou repasse da plataforma.
- Ajuda contextual explica as origens dos valores e a abrangência dos filtros.

Validação: 160 testes de administração/financeiro aprovados e análise Dart dos
arquivos alterados sem problemas. Testes cobrem cadastro atual/legado, eventos
homônimos, ausência de ID, excedente, cancelamento, saldos por item, filtro sem
mascarar planejamento e layouts em 360, 768 e 1440 pixels, com texto normal e 200%.

Capturas de widgets reais com dados fictícios inspecionadas em
`.dart_tool/capturas-orcamentos`. A imagem `inicio-1440-1.png` mostra a visão geral;
`itens-1440-1.png` mostra a tabela expandida.

Não houve escrita de dados de produção, execução de pagamentos ou publicação.
