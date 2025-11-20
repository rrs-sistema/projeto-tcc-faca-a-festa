Feature: Avaliação e Ranking de Fornecedores
  Como organizador de um evento
  Quero avaliar serviços e fornecedores contratados
  Para melhorar a qualidade do marketplace e ajudar outros usuários

  Background:
    Given que estou autenticado como um organizador
    And existe um fornecedor cadastrado
    And existe um serviço vinculado a esse fornecedor
    And existe um evento criado pelo organizador

  Scenario: Organizador avalia um serviço do fornecedor
    Given que o organizador acessou a tela de detalhes do fornecedor
    And o serviço foi solicitado em uma cotação
    And o botão "Avaliar este serviço" está disponível
    When o organizador seleciona entre 1 e 5 estrelas
    And preenche um comentário válido
    And confirma o envio da avaliação
    Then a avaliação deve ser salva na subcoleção "fornecedor_servico/{id}/avaliacoes"
    And a Cloud Function deve recalcular a média do serviço
    And a Cloud Function deve atualizar a média geral do fornecedor
    And a Cloud Function deve validar e atribuir novos selos ao fornecedor
    And a Cloud Function deve atualizar o ranking da categoria
    And o fornecedor deve receber uma notificação push informando a nova avaliação

  Scenario: Organizador tenta avaliar um serviço sem permissão
    Given que o organizador acessou a tela de detalhes do fornecedor
    And o serviço nunca foi solicitado em nenhuma cotação
    When a tela é carregada
    Then o botão "Avaliar este serviço" não deve ser exibido

  Scenario: Organizador avalia um fornecedor após o serviço estar totalmente pago
    Given que o organizador tem um orçamento fechado com o fornecedor
    And todos os gastos desse orçamento estão pagos
    And a soma do valor pago é igual ao custo estimado
    When o organizador abre a tela de orçamento
    Then o botão "Avaliar Fornecedor" deve estar visível

    When o organizador seleciona entre 1 e 5 estrelas
    And preenche um comentário
    And envia a avaliação
    Then a avaliação deve ser salva na coleção "avaliacoes"
    And a Cloud Function deve recalcular a média geral do fornecedor
    And a Cloud Function deve atualizar os selos do fornecedor
    And a Cloud Function deve atualizar o ranking da categoria
    And o fornecedor deve receber uma notificação push

  Scenario: Organizador tenta avaliar um fornecedor antes de pagar tudo
    Given que o organizador tem um orçamento fechado com o fornecedor
    But existem valores ainda não pagos na categoria
    When o organizador abre a tela de orçamento
    Then o botão "Avaliar Fornecedor" não deve aparecer

  Scenario: Consultar ranking de fornecedores em uma categoria
    Given que existe uma categoria com vários fornecedores avaliados
    And cada fornecedor possui notas e quantidade mínima de avaliações
    When o organizador pressiona o botão "Ranking da Categoria"
    Then o sistema deve exibir a lista ordenada do melhor para o pior fornecedor
    And cada fornecedor deve exibir seu selo correspondente:
      | posição | selo      |
      | 1º      | 🥇 Ouro   |
      | 2º      | 🥈 Prata  |
      | 3º      | 🥈 Prata  |
      | 4º      | 🥉 Bronze |
      | 5º      | 🥉 Bronze |
