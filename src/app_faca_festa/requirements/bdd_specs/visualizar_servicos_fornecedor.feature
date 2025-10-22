Feature: Exibição dos serviços de um fornecedor
  Como organizador do evento
  Quero visualizar todos os serviços oferecidos por um fornecedor
  Para poder escolher e contratar os que atendem meu evento

  Background:
    Dado que estou logado no aplicativo "Faça a Festa"
    E acesso a área "Fornecedores"

  Scenario: Exibir serviços cadastrados de um fornecedor
    Dado que o fornecedor "Stephanie Schor - Designer de Eventos" possui serviços cadastrados
    Quando eu abrir o perfil deste fornecedor
    Então o aplicativo deve chamar o método "escutarServicosFornecedor"
    E a lista de serviços deve ser carregada da coleção "fornecedor_servico"
    E o catálogo detalhado de serviços deve ser buscado na coleção "servico_produto"
    E as imagens correspondentes devem ser carregadas da coleção "fornecedor_fotos"
    Então devo ver na tela uma lista com:
      | Nome do serviço     | Preço | Descrição resumida | Imagem |
      | Decoração Completa  | R$5000 | Inclui flores e mobiliário | 🖼 |
      | Bolo Cenográfico    | R$600  | Três andares personalizado | 🖼 |

  Scenario: Atualização em tempo real
    Dado que o fornecedor adiciona um novo serviço no painel administrativo
    Quando a alteração for salva no Firestore
    Então o aplicativo deve atualizar automaticamente a lista de serviços exibidos
    Sem necessidade de recarregar a tela

  Scenario: Nenhum serviço cadastrado
    Dado que o fornecedor ainda não possui serviços cadastrados
    Quando eu acessar o perfil do fornecedor
    Então o aplicativo deve exibir a mensagem "Este fornecedor ainda não cadastrou serviços."
