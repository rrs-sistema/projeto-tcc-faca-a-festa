Feature: Gestão de Categorias, Subcategorias e Serviços no aplicativo Faça a Festa

  Como administrador da plataforma
  Quero gerenciar as categorias e serviços disponíveis
  Para que todos os fornecedores utilizem uma base padronizada

  Background:
    Dado que o usuário está autenticado no aplicativo Faça a Festa

  # ======================================
  # 🧑‍💼 ADMINISTRADOR
  # ======================================

  Scenario: Administrador cadastra uma nova categoria
    Dado que o usuário possui papel "admin"
    Quando ele acessa a tela de "Categorias de Serviços"
    E clica no botão "Adicionar"
    E informa o nome "Decoração" e descrição "Serviços de ambientação de eventos"
    Então a categoria "Decoração" deve ser salva e exibida na lista

  Scenario: Administrador cadastra uma nova subcategoria
    Dado que o usuário possui papel "admin"
    E existe uma categoria chamada "Decoração"
    Quando ele acessa a tela de "Subcategorias"
    E seleciona a categoria "Decoração"
    E adiciona a subcategoria "Flores"
    Então a subcategoria "Flores" deve aparecer associada à categoria "Decoração"

  Scenario: Administrador cadastra um novo serviço/produto
    Dado que o usuário possui papel "admin"
    E existe uma subcategoria chamada "Flores"
    Quando ele acessa a tela de "Serviços / Produtos"
    E adiciona o serviço "Arranjo de Mesa" com tipo de medida "Unidade"
    Então o serviço "Arranjo de Mesa" deve estar disponível para vínculo por fornecedores

  Scenario: Administrador edita ou desativa uma categoria existente
    Dado que o usuário possui papel "admin"
    Quando ele acessa a categoria "Decoração"
    E altera o campo "ativo" para falso
    Então a categoria "Decoração" não deve mais aparecer para seleção por fornecedores

  # ======================================
  # 🧑‍🔧 FORNECEDOR
  # ======================================

  Scenario: Fornecedor vincula um serviço existente ao seu perfil
    Dado que o usuário possui papel "fornecedor"
    E existe um serviço chamado "Arranjo de Mesa"
    Quando ele acessa a tela "Meus Serviços"
    E seleciona "Arranjo de Mesa"
    E informa o preço "200.00" e o preço promocional "150.00"
    Então o vínculo entre o fornecedor e o serviço deve ser criado com sucesso

  Scenario: Fornecedor tenta criar uma nova categoria
    Dado que o usuário possui papel "fornecedor"
    Quando ele tenta acessar a tela "Categorias de Serviços"
    Então o sistema deve exibir uma mensagem de acesso negado
    E o botão "Adicionar" não deve estar visível

  Scenario: Fornecedor edita o preço de um serviço vinculado
    Dado que o usuário possui papel "fornecedor"
    E já possui vínculo com o serviço "Arranjo de Mesa"
    Quando ele atualiza o preço para "250.00"
    Então o novo preço deve ser salvo e refletido em sua lista de serviços

  # ======================================
  # 🎉 ORGANIZADOR (USUÁRIO FINAL)
  # ======================================

  Scenario: Organizador visualiza categorias e serviços disponíveis
    Dado que o usuário possui papel "organizador"
    Quando ele acessa a aba "Fornecedores"
    Então deve visualizar a lista de categorias e serviços ativos
    E deve poder filtrar fornecedores por categoria ou serviço

  Scenario: Organizador não pode cadastrar categorias ou serviços
    Dado que o usuário possui papel "organizador"
    Quando ele tenta abrir o menu de administração
    Então o sistema deve ocultar as opções de "Gerenciar Categorias" e "Gerenciar Serviços"

  # ======================================
  # 🔒 REGRAS GERAIS DE ACESSO
  # ======================================

  Rule: Somente administradores podem criar, editar ou excluir categorias, subcategorias e serviços
  Rule: Fornecedores podem apenas vincular serviços existentes e definir preços
  Rule: Organizadores apenas consomem as informações para montar eventos
  Rule: Categorias ou serviços inativos não devem aparecer para fornecedores nem organizadores
  Rule: Todas as ações devem respeitar o tema visual ativo do evento (gradiente e cor primária)
