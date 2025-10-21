Feature: Exibição de fornecedores na tela de localização
  Para que o usuário veja apenas fornecedores válidos e próximos,
  o sistema deve aplicar regras de carregamento, filtragem e exibição
  baseadas nas coleções Firestore e nos campos definidos.

  Background:
    Dado que as coleções "fornecedor", "fornecedor_categoria", "categoria_servico" e "territorio" existem no Firestore
    E que o app possui um usuário autenticado com localização atual

  # ==========================================================
  # 🚀 CENÁRIO 1 — Carregar fornecedores ativos
  # ==========================================================
  Scenario: Listar apenas fornecedores ativos
    Given que existem documentos em "fornecedor" com campo "ativo" igual a true
    When o método carregarDados() é executado
    Then apenas os fornecedores com ativo=true devem ser incluídos na lista inicial
    And os fornecedores inativos devem ser ignorados completamente

  # ==========================================================
  # 🧩 CENÁRIO 2 — Associação de categoria
  # ==========================================================
  Scenario: Exibir categorias corretas dos fornecedores
    Given que existe um documento em "fornecedor_categoria" com campos:
      | id_fornecedor | id_categoria |
    And o id_categoria corresponde a um documento válido em "categoria_servico"
    When o método carregarDados() monta a lista detalhada
    Then o fornecedor deve exibir o nome da categoria correspondente
    And se possuir múltiplas categorias, elas devem ser exibidas separadas por vírgula
    But se não possuir categoria válida, a categoria deve ser exibida como "Outros"

  # ==========================================================
  # 🗺️ CENÁRIO 3 — Associação de território e cálculo de distância
  # ==========================================================
  # ==========================================================
  # 🗺️ CENÁRIO 3 — Associação de território e cálculo de distância
  # ==========================================================
  Scenario: Calcular distância do usuário até o fornecedor
    Given que o fornecedor possui documento correspondente em "territorio"
      | id_fornecedor                     | latitude  | longitude  | raio_km |
      | X8R9CYgohqdM2dhnnN6GAvN3O8z1      | -25.494   | -49.291    | 25      |
      | 25e8212d-07f0-40c3-9bcb-5dfa6f7255bb | -24.945 | -48.850    | 150     |
    And o usuário está localizado em Curitiba (-25.428, -49.273)
    When o método carregarDados() é executado
    Then o sistema deve calcular a distância (distanciaKm) usando o método _calcularDistancia()
    And armazenar esse valor no modelo FornecedorDetalhadoModel
    And comparar com o raio_km definido para o território

    Examples:
      | Caso | Distância estimada | Raio definido | Resultado esperado |
      | Fornecedor A (25 km) | 12.3 km | 25 km | ✅ Aparece na listagem (dentro do raio) |
      | Fornecedor B (150 km) | 78.5 km | 150 km | ✅ Aparece na listagem (dentro do raio) |
      | Fornecedor C (10 km de raio, 40 km de distância) | 40.0 km | 10 km | 🚫 Não aparece (fora do raio) |

    But se o fornecedor não possuir coordenadas, o campo distanciaKm deve ser null
    And ele ainda pode aparecer se possuir categoria válida (tratado em _filtrarPorRaio)

  # ==========================================================
  # 🎯 CENÁRIO 4 — Filtro por raio e categorias
  # ==========================================================
  Scenario: Aplicar filtro de raio e categoria na tela
    Given que a lista de fornecedores foi carregada com sucesso
    And o raio padrão é 10 km (ou ajustado pelo usuário)
    When o método _filtrarPorRaio() é executado
    Then apenas os fornecedores dentro do raio devem ser exibidos
    And fornecedores fora do raio mas com categoria válida também devem aparecer

    When o usuário seleciona uma categoria na interface
    Then apenas os fornecedores cujas categorias incluem o nome selecionado devem ser mostrados
    And o filtro deve considerar múltiplas categorias separadas por vírgula, sem diferenciar maiúsculas/minúsculas

  # ==========================================================
  # 🚫 CENÁRIO 5 — Motivos para um fornecedor não aparecer
  # ==========================================================
  Scenario: Fornecedor ausente da listagem
    Given que um fornecedor possui ativo=false
    Or não existe em "fornecedor_categoria"
    Or está fora do raio e sem categoria associada
    Then ele não deve aparecer na listagem da tela

  # ==========================================================
  # 📊 CENÁRIO 6 — Resumo estrutural (visual)
  # ==========================================================
  Scenario: Relação entre coleções
    Given a estrutura de dados:
      """
            ┌───────────────────────────────┐
            │      categoria_servico        │
            │   (Decoração, Buffet, etc.)   │
            └──────────────┬────────────────┘
                           │
                           ▼
      ┌───────────────┐   ┌──────────────────────┐   ┌──────────────────────┐
      │  fornecedor   │──▶│ fornecedor_categoria │──▶│     territorio        │
      │ (ativo=true)  │   │ (idFornecedor/idCat) │   │ (latitude/longitude) │
      └───────────────┘   └──────────────────────┘   └──────────────────────┘
                           │
                           ▼
                      aparece na tela
      """
    Then o sistema deve respeitar essas dependências de dados para exibição
