🎉 Faça a Festa — Documentação Arquitetural
Módulo: Presentes (Gifts) | Stack: Flutter, Clean Architecture, GetX, Offline-first, Firestore

1. Introdução
O módulo Gifts é responsável por gerenciar a lista de presentes de eventos dentro da aplicação Faça a Festa. Ele permite que organizadores registrem itens desejados e que convidados possam reservar ou contribuir financeiramente para esses presentes.

Este módulo foi projetado utilizando os princípios da Clean Architecture, garantindo uma estrutura de código organizada, escalável e de fácil manutenção. A arquitetura separa claramente as responsabilidades em camadas independentes, promovendo baixo acoplamento entre a interface do usuário (UI), as regras de negócio e o acesso a dados.

2. Objetivos da Arquitetura
A adoção da Clean Architecture, combinada com GetX e uma abordagem Offline-first, visa:

Promover a separação de responsabilidades: Cada camada tem um papel único e bem definido.

Permitir independência de frameworks: O núcleo da aplicação (regras de negócio) não depende de pacotes externos ou do Flutter.

Facilitar testes automatizados: O isolamento das camadas permite testar casos de uso e lógicas de forma unitária.

Garantir resiliência (Offline-first): O usuário pode visualizar e interagir com os dados mesmo sem conexão, sincronizando com o servidor posteriormente.

Evitar acoplamento com o banco de dados: Alterações no Firestore não impactam a UI ou as regras de negócio.

3. Estrutura de Diretórios
A organização segue rigorosamente a divisão das três camadas principais (Presentation, Domain e Data):

Plaintext
lib/
 ├─ data/
 │   ├─ models/
 │   │   └─ gift/
 │   │       ├─ gift_model.dart
 │   │       └─ gift_contribution_model.dart
 │   └─ repositories_impl/
 │       └─ gift_repository_impl.dart
 │
 ├─ domain/
 │   ├─ entities/
 │   │   └─ gift/
 │   │       ├─ gift.dart
 │   │       └─ gift_contribution.dart
 │   ├─ repositories/
 │   │   └─ gift_repository.dart
 │   └─ usecases/
 │       ├─ get_gifts_usecase.dart
 │       ├─ create_gift_usecase.dart
 │       ├─ reservar_gift_usecase.dart
 │       └─ contribuir_pix_usecase.dart
 │
 └─ presentation/
     └─ modules/
         └─ gifts/
             ├─ controllers/  # Controladores do GetX
             ├─ pages/        # Telas da aplicação
             └─ widgets/      # Componentes visuais reutilizáveis
4. Camadas da Arquitetura
4.1 Camada Presentation (Interface do Usuário)
Responsável por tudo o que o usuário vê e interage.

Responsabilidades: Renderizar telas, capturar interações e apresentar informações processadas.

Componentes: Pages, Widgets e Controllers (GetX).

Regra de Ouro: Esta camada não acessa o banco de dados diretamente. Ela se comunica exclusivamente com os Controllers, que por sua vez acionam os UseCases. O GetX é utilizado para reatividade de estado e injeção de dependência.

4.2 Camada Domain (Núcleo da Aplicação)
É o coração do sistema. Contém as regras de negócio puras e é totalmente independente de qualquer framework (incluindo Flutter e Firebase).

Entities: Objetos centrais do domínio (Gift, GiftContribution). Representam os conceitos reais de negócio.

Repository Interfaces: Contratos que definem o que o sistema precisa fazer, sem se importar em como isso será feito.

UseCases: Encapsulam ações específicas e únicas do sistema (ex: ReservarGiftUseCase).

4.3 Camada Data (Infraestrutura)
Responsável por conversar com o mundo externo (APIs, Firebase, Bancos Locais).

Models: Responsáveis pela serialização/desserialização. Convertem dados do formato do banco para Entities do domínio, e vice-versa (fromFirestore, toMap).

Repository Implementations: Implementam as interfaces definidas no domínio. É aqui que as queries no Firestore são executadas, as transações são aplicadas e a lógica Offline-first é tratada.

5. Diagramas Arquiteturais e Fluxo de Dados
O fluxo de comunicação segue a Regra de Dependência da Clean Architecture: as dependências apontam sempre de fora para dentro (A UI conhece o Domínio, mas o Domínio não conhece a UI).

5.1 Visão Geral da Arquitetura
Snippet de código

graph TD
    subgraph Presentation Layer
        UI[Pages / Widgets]
        Ctrl[GetX Controllers]
    end
    
    subgraph Domain Layer
        UC[UseCases]
        RepoInt[Repository Interfaces]
        Ent[Entities]
    end
    
    subgraph Data Layer
        RepoImpl[Repository Implementations]
        Mod[Models]
    end
    
    DB[(Firestore / Local Cache)]

    UI -->|Ação do Usuário| Ctrl
    Ctrl -->|Chama| UC
    UC -->|Usa Contrato| RepoInt
    RepoInt -.->|Implementado por| RepoImpl
    RepoImpl <-->|CRUD / Transações| DB
    RepoImpl -->|Mapeia Dados| Mod
    Mod -.->|Converte para| Ent
    Ent -.->|Retorna para| UC

5.2 Fluxo de Leitura: Listar Presentes (Offline-first)
Neste fluxo, o repositório é responsável por decidir se busca os dados do cache local (para uma resposta imediata) ou do Firestore.

Snippet de código
sequenceDiagram
    participant UI as Page (UI)
    participant Ctrl as GetX Controller
    participant UC as GetGiftsUseCase
    participant Repo as GiftRepositoryImpl
    participant DB as Firestore/Cache

    UI->>Ctrl: Solicita lista de presentes
    Ctrl->>UC: call()
    UC->>Repo: getGifts()
    Repo->>DB: Busca dados (Cache local / Firestore)
    DB-->>Repo: Retorna JSON / Documentos
    Repo->>Repo: Converte Models em Entities
    Repo-->>UC: Retorna List<Gift>
    UC-->>Ctrl: Retorna List<Gift>
    Ctrl-->>UI: Atualiza Estado (Rebuild)
5.3 Fluxo de Escrita: Reservar Presente / Contribuição PIX
Para garantir que duas pessoas não reservem o mesmo presente ao mesmo tempo, a camada Data utiliza transações.

Snippet de código
sequenceDiagram
    participant UI as Page (UI)
    participant Ctrl as GetX Controller
    participant UC as Reservar/Contribuir UseCase
    participant Repo as GiftRepositoryImpl
    participant DB as Firestore

    UI->>Ctrl: Ação do Usuário (Reservar/Pagar)
    Ctrl->>UC: call(parametros)
    UC->>Repo: executarTransacao()
    Repo->>DB: Inicia Firestore Transaction
    Note over Repo,DB: Lock no documento para evitar concorrência
    DB-->>Repo: Confirmação da Transação
    Repo-->>UC: Resultado (Sucesso/Erro)
    UC-->>Ctrl: Resultado
    Ctrl-->>UI: Feedback Visual (Snackbar/Toast)
6. Benefícios e Evoluções Futuras
Benefícios Técnicos Alcançados
Baixo Acoplamento: A interface e as regras de negócio estão blindadas contra mudanças na infraestrutura.

Alta Testabilidade: A criação de mocks para os repositórios permite testar UseCases e Controllers de forma isolada e sem depender de conexão com a internet ou banco de dados.

Experiência Fluida: A abordagem offline-first combinada com a reatividade do GetX garante que o aplicativo responda instantaneamente, mesmo em cenários de conectividade ruim.

Roadmap e Possíveis Evoluções
O módulo foi arquitetado para suportar expansões de forma orgânica. Futuras implementações planejadas incluem:

Edição de presentes registrados e cancelamento de reservas.

Painel com histórico e ranking de contribuições.

Notificações push em tempo real para novas contribuições.

Integração direta com gateways de pagamento PIX e relatórios de arrecadação para o organizador.