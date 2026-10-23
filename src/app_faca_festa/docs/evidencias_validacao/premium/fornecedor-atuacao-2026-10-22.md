# Cadastro do fornecedor — etapa de atuação

Data: 22/10/2026.

## Diagnóstico

As listas horizontais ocultavam categorias, especialidades e serviços. O texto cortado dificultava identificar opções, e a seleção de uma especialidade marcava seus serviços automaticamente.

## Alterações

- Opções com texto completo, quebra de linha e indicação explícita de seleção.
- Grade responsiva no computador e uma coluna no celular com fonte ampliada.
- Especialidades e serviços agrupados por categoria, com painéis recolhíveis.
- Busca por serviço e contagem de escolhas, preservando seleções durante a filtragem.
- A escolha da especialidade apresenta seus serviços para seleção individual.
- Carregamento, erro e nova tentativa apresentados no próprio formulário.
- Tipos de evento com o mesmo padrão de seleção.
- Mais espaço para a etapa de atuação na edição administrativa; informações da conta em seção recolhível.
- Componentes compartilhados entre criação e edição.

## Validação

Análise estática dos seis arquivos Dart alterados: sem problemas.

24 testes aprovados nos arquivos `fornecedor_cadastro_fluxo_test.dart`, `fornecedor_cadastro_transacao_test.dart`, `fornecedor_edicao_admin_test.dart` e `fornecedor_repository_test.dart`. Cobertura inclui textos longos, ausência de listas horizontais de opções, fonte em 160% no celular, busca sem perda de seleção, recuperação de falha do catálogo e regressões de edição/persistência.

Capturas dos componentes reais, renderizados com dados de teste:

- [Computador](fornecedor-atuacao-2026-10-22/desktop.png)
- [Celular com fonte ampliada](fornecedor-atuacao-2026-10-22/celular.png)

As capturas foram inspecionadas visualmente. Não houve execução em dispositivo físico nem gravação no Firebase de produção nesta validação.
