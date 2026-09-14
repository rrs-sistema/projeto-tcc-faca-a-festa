# Camadas e regras

O cliente Flutter segue Clean Architecture em quatro diretórios de produto (`domain`, `data`, `presentation`, `app`) mais um pacote transversal (`core`). O backend (`functions/`) **não** faz parte dessas camadas: é outro processo, chamado via HTTPS callable na região `southamerica-east1`.

## Inventário atual (`lib/`)

Contagem de arquivos `.dart` (incluindo gerados do Drift):

| Área | Arquivos | Papel |
| --- | ---: | --- |
| `domain/` | 152 | Núcleo: entidades, contratos, casos de uso, serviços de domínio |
| `data/` | 176 | Firestore, Functions, models, seeds, implementações |
| `presentation/` | 233 | Telas GetX, controllers, coordinator de sessão do evento |
| `app/` | 40 | Composição: bootstrap, rotas, tema, middleware de papel |
| `core/` | 23 | Drift (gifts), plataforma, validadores, helpers |

Recortes do domínio:

| Recorte | Quantidade |
| --- | ---: |
| Entidades | 71 |
| Contratos de repositório | 38 |
| Casos de uso | 34 |
| Serviços de domínio | 8 |
| Datasources | 39 (38 remotos + 1 local Drift) |
| Models | 73 |
| Implementações de repositório | 38 |
| Módulos de UI | 19 |

## Árvore de pastas

```text
lib/
├── main.dart                 # Firebase, Drift, GetStorage, AppBootstrap, runApp
├── firebase_options.dart
├── app/                      # Composition root (GetX)
│   ├── bootstrap/            # 33 arquivos: um bootstrap por feature (+ Firebase)
│   ├── routes/               # AppRoutes + argumentos tipados
│   ├── middleware/           # PapelMiddleware (A / F / C)
│   ├── theme/
│   ├── bindings/             # Apenas GiftBinding (rota com DI local)
│   └── faca_festa_app.dart   # GetMaterialApp
├── domain/                   # Sem Flutter UI, GetX, Firebase, fromMap
│   ├── entities/
│   ├── repositories/         # abstract interface class
│   ├── usecases/
│   ├── services/             # Contratos (CEP, convite, IA, auditoria, …)
│   └── exceptions/
├── data/                     # Sem GetX
│   ├── datasources/remote|local
│   ├── models/               # fromMap / toMap; vários estendem a entidade
│   ├── repositories_impl/
│   ├── services/             # Adapters (CEP Google, Functions, AI, …)
│   └── seeds/
├── presentation/
│   ├── modules/<feature>/    # pages, controllers, sections, widgets, dialogs
│   ├── coordinators/         # EventoSessionCoordinator
│   └── widgets/              # Widgets compartilhados entre módulos
└── core/                     # Infra transversal (não é “camada de negócio”)
    ├── database/             # Drift — cache local de gifts
    ├── platform/
    ├── utils/
    ├── services/
    ├── errors/
    └── constants/
```

## Regra de dependência

As setas de import apontam **para dentro**. O domínio não conhece UI nem Firebase.

```text
presentation  ──►  domain  ◄──  data
     ▲                           │
     │                           │ implementa os contratos
     └──────── app (Get.put) ────┘
```

| Camada | Pode importar | Não pode importar |
| --- | --- | --- |
| **domain** | Dart puro e outras peças de `domain` | `package:flutter` de UI, GetX, Firebase, `fromMap`/`Map` de persistência |
| **data** | `domain`, Firebase, HTTP, Drift, `core` | GetX, widgets Flutter |
| **presentation** | `domain`, widgets Flutter, GetX | datasources, models, `FirebaseFirestore.instance` direto em código novo |
| **app** | Todas as camadas (é a raiz de composição) | — |
| **core** | Flutter/plataforma pontuais (Drift, mascaras) | regras de negócio de festa |

Checagem feita no código: `lib/domain` não importa GetX, Firestore nem Firebase; `lib/data` não importa GetX.

## O que cada camada faz

### Domain

Coração do produto. Entidades (`Evento`, `Usuario`, `Fornecedor`, `Orcamento`, `Gift`, …) e contratos (`EventoRepository`, `PerfilUsuarioRepository`, …).

Há dois estilos de caso de uso:

1. **Fachada `GerenciarX`** — a maioria (`GerenciarOrcamentos`, `GerenciarFornecedores`, `GerenciarCatalogoServico`). Encaminha para o repositório; o controller GetX ainda orquestra a tela.
2. **Casos de uso unitários** — módulo de presentes (`CreateGiftUseCase`, `ReservarGiftUseCase`, `ContribuirPixUseCase`, …).

Serviços de domínio são **interfaces** (`BuscarCepService`, `CalculadoraFestaAiService`, `AuditoriaRegistrar`). A implementação fica em `data/services`.

### Data

Única camada autorizada a falar com Firestore, Auth, Storage, Cloud Functions e Drift.

Padrão típico:

`RemoteDatasource` → `Model.fromMap` → `RepositoryImpl` → devolve **entidade** para o domínio.

Vários models **estendem** a entidade (`EnderecoUsuarioModel extends EnderecoUsuario`, `UsuarioModel extends Usuario`). Isso simplifica o mapeamento, mas a lista em runtime é `List<Model>`. Não usar `List.firstWhere(..., orElse:)` nessas listas: o `orElse` que devolve a entidade quebra por covariância do `List` (ver `enderecoPrincipalOuPrimeiro`).

Offline-first completo (Drift + sync) está no **módulo gifts**. Os demais fluxos leem/escrevem Firestore (e Functions) direto via datasource remoto.

### Presentation

Módulos por feature. Convenção:

| Pasta no módulo | Conteúdo |
| --- | --- |
| `pages/` | Telas |
| `controllers/` | GetX: estado e orquestração |
| `sections/` | Blocos de UI extraídos da tela |
| `widgets/` / `dialogs/` / `components/` | Peças visuais |

Controllers recebem repositórios, casos de uso e serviços **pelo construtor**. Quem faz `Get.put` / `Get.lazyPut` é o bootstrap em `lib/app`.

`EventoSessionCoordinator` (`presentation/coordinators`) sincroniza tema, orçamento, convidados, checklist etc. quando o evento ativo muda. Não é domínio: é cola entre controllers GetX.

### App (composition root)

- `main.dart` inicializa Firebase, App Check, GetStorage, Drift (gifts), push e chama `AppBootstrap.registerControllers()`.
- Cada `*_bootstrap.dart` registra datasource → repositório → use case → controller.
- `AppRoutes` monta as páginas injetando controllers já registrados; argumentos de rota são tipos (`AuthFluxoArgs`, `TotpMfaArgs`, …).
- `PapelMiddleware` restringe rotas por `usuario.tipo`: `A` administrador, `F` fornecedor, `C` convidado.

GetX de DI e navegação vive aqui e em `presentation`. Não volta para `data` nem `domain`.

### Core

Não é uma camada Clean Architecture clássica. Agrupa Drift (`AppDatabase` + tabelas de gift), detecção de plataforma, máscaras/validadores e helpers de convite. `data` e `presentation` podem usar; `domain` não deve depender de Flutter/`core`.

## Backend (fora do `lib/`)

`functions/src` — Cloud Functions v2, região **`southamerica-east1`**. Grupos atuais: `auth`, `auditoria`, `cotacao`, `convite`, `calculadora`, `fornecedores` (recomendação/IA), `tema`, `whatsapp`, mais `address/buscarCepGoogle` e cache Maps.

O app chama essas functions por `FirebaseFunctions.instanceFor(region: 'southamerica-east1')` (mobile/web) ou cliente HTTPS equivalente, encapsulado em `data/services`.

## O que esta arquitetura não promete

- **Não** é hexagonal “pura”: a UI ainda conhece GetX e muitos controllers são grandes.
- **Não** há um use case por ação em todos os módulos — só gifts chegou perto disso.
- **Não** todo dado é offline-first — só a lista de presentes usa Drift de ponta a ponta.
- **Não** o domínio serializa Firestore: `fromMap` fica nos models.

Esses limites são intencionais no estado atual do produto; a migração de camadas está fechada.
