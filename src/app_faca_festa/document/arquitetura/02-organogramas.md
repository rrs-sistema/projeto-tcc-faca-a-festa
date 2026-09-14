# Organogramas

Diagramas da estrutura **atual**. Renderizam em GitHub, VS Code (Mermaid) e editores com suporte a GFM.

## 1. Camadas (visão em cebola)

```mermaid
flowchart TB
  subgraph externos["Sistemas externos"]
    FS[(Cloud Firestore)]
    AUTH[Firebase Auth]
    ST[Cloud Storage]
    FN["Cloud Functions\nsouthamerica-east1"]
    DRIFT[(Drift SQLite — gifts)]
  end

  subgraph appLayer["app/ — composition root"]
    MAIN[main.dart]
    BOOT[AppBootstrap]
    ROUTES[AppRoutes + PapelMiddleware]
  end

  subgraph presentation["presentation/"]
    PAGES[Pages / sections / widgets]
    CTRL[GetX controllers]
    COORD[EventoSessionCoordinator]
  end

  subgraph domain["domain/ — núcleo"]
    UC[Use cases]
    REPO_I[Repository interfaces]
    ENT[Entities]
    SVC_I[Service interfaces]
  end

  subgraph dataLayer["data/"]
    REPO_X[Repository implementations]
    DS[Datasources]
    MOD[Models]
    SVC_X[Service adapters]
  end

  MAIN --> BOOT
  BOOT --> CTRL
  ROUTES --> PAGES
  PAGES --> CTRL
  CTRL --> UC
  CTRL --> REPO_I
  CTRL --> SVC_I
  COORD --> CTRL
  UC --> REPO_I
  UC --> ENT
  REPO_I -.implementado por.-> REPO_X
  SVC_I -.implementado por.-> SVC_X
  REPO_X --> DS
  REPO_X --> MOD
  MOD --> ENT
  DS --> FS
  DS --> AUTH
  DS --> ST
  SVC_X --> FN
  DS --> DRIFT
```

## 2. Organograma de pastas (`lib/`)

```mermaid
flowchart TB
  LIB[lib/]
  LIB --> MAIN[main.dart]
  LIB --> APP[app/]
  LIB --> DOM[domain/]
  LIB --> DATA[data/]
  LIB --> PRES[presentation/]
  LIB --> CORE[core/]

  APP --> APP_BOOT[bootstrap/]
  APP --> APP_ROUTES[routes/]
  APP --> APP_MW[middleware/]
  APP --> APP_THEME[theme/]
  APP --> APP_BIND[bindings/ GiftBinding]

  DOM --> ENT[entities/]
  DOM --> REP[repositories/]
  DOM --> UCS[usecases/]
  DOM --> DSVC[services/]
  DOM --> DEXC[exceptions/]

  DATA --> DS[datasources/]
  DATA --> MODELS[models/]
  DATA --> IMPL[repositories_impl/]
  DATA --> DSERV[services/]
  DATA --> SEEDS[seeds/]
  DS --> DSR[remote/]
  DS --> DSL[local/ gift]

  PRES --> MODS[modules/]
  PRES --> COOR[coordinators/]
  PRES --> WID[widgets/]

  CORE --> DB[database/ Drift]
  CORE --> PLAT[platform/]
  CORE --> UTIL[utils/]
```

## 3. Organograma de módulos de UI por papel

Papel vem de `Usuario.tipo` e é aplicado em `PapelMiddleware` + `AppCicloSessao`.

```mermaid
flowchart TB
  APP[AppController / ciclo de sessão]
  APP --> ORG["Organizador — tipo padrão"]
  APP --> FORN["Fornecedor — F"]
  APP --> CONV["Convidado — C"]
  APP --> ADM["Administrador — A"]

  ORG --> EV[eventos]
  ORG --> CALC[calculadora]
  ORG --> ORC[orcamento]
  ORG --> COT[cotacao]
  ORG --> CHK[checklist]
  ORG --> INS[inspiracao]
  ORG --> CAT_O[catalogo / fornecedor]
  ORG --> CONV_M[convidado — lista e convites]
  ORG --> GIFT[gifts]
  ORG --> TEMA[tema]

  FORN --> FORN_M[fornecedor — painel]
  FORN --> COT_F[cotacao]
  FORN --> ORC_F[orcamento]

  CONV --> AREA[convidado — área do convidado]
  CONV --> GIFT_C[gifts — reserva / PIX]
  CONV --> CHK_C[checklist — tarefas do convidado]

  ADM --> DASH[admin]
  ADM --> AUD[auditoria]
  ADM --> CAT_A[catalogo]
  ADM --> TERR[admin território]
  ADM --> USR[usuario]
  ADM --> RANK[ranking]
```

## 4. Organograma domínio ↔ dados (contratos)

Cada caixa da esquerda é um `abstract interface class` em `domain/repositories`. A da direita é a impl em `data/repositories_impl` + datasource.

```mermaid
flowchart LR
  subgraph dominio["domain/repositories"]
    R1[EventoRepository]
    R2[PerfilUsuarioRepository]
    R3[AutenticacaoRepository]
    R4[FornecedorRepository]
    R5[OrcamentoRepository]
    R6[CotacaoRepository]
    R7[ConvidadoRepository]
    R8[GiftRepository]
    R9[CalculadoraFestaRepository]
    R10[AuditoriaRepository]
    RN["… 28 outros contratos"]
  end

  subgraph dados["data/"]
    I1[EventoRepositoryImpl]
    I2[PerfilUsuarioRepositoryImpl]
    I3[AutenticacaoRepositoryImpl]
    I4[FornecedorRepositoryImpl]
    I5[OrcamentoRepositoryImpl]
    I6[CotacaoRepositoryImpl]
    I7[ConvidadoRepositoryImpl]
    I8[GiftRepositoryImpl]
    I9[CalculadoraFestaRepositoryImpl]
    I10[AuditoriaRepositoryImpl]
  end

  R1 --> I1
  R2 --> I2
  R3 --> I3
  R4 --> I4
  R5 --> I5
  R6 --> I6
  R7 --> I7
  R8 --> I8
  R9 --> I9
  R10 --> I10
```

Há **38** pares contrato/implementação. A lista completa está em [03 — Módulos](03-modulos-bootstrap-e-fluxos.md).

## 5. Organograma da raiz de composição

Ordem real de `AppBootstrap.registerControllers()` (dependências eager primeiro).

```mermaid
flowchart TB
  MAIN[main.dart]
  MAIN --> FB[FirebaseServicesBootstrap]
  MAIN --> AC[App Check]
  MAIN --> GS[GetStorage]
  MAIN --> DR[GiftOfflineBootstrap Drift]
  MAIN --> PUSH[PushNotificationsBootstrap]
  MAIN --> REG[AppBootstrap.registerControllers]

  REG --> S0[BuscarCepService]
  REG --> S1[AutenticacaoBootstrap]
  REG --> S2[DocumentoBootstrap]
  REG --> S3[UfCidadeBootstrap]
  REG --> S4[ConvidadoBootstrap]
  REG --> S5[PerfilUsuarioBootstrap]
  REG --> S6[Fornecedor + catálogo + ranking]
  REG --> S7[EventoBootstrap]
  REG --> S8[TemaFestaBootstrap]
  REG --> S9[Cotação / calculadora / orçamento]
  REG --> S10[Admin / auditoria / inspiração]
  REG --> S11[AppControllerBootstrap]

  S3 --> S5
  S3 --> S7
  S7 --> S8
  S11 --> APP[AppController — último]
```

`UFCidadeController` é registrado **antes** do perfil e do cadastro de evento porque esses controllers fazem `Get.put` imediato com `Get.find<UFCidadeController>()`.

## 6. Sistemas ao redor do app

```mermaid
flowchart LR
  APP[Cliente Flutter\nAndroid / Web / Desktop]
  APP --> AUTH[Firebase Auth + App Check]
  APP --> FS[Cloud Firestore]
  APP --> ST[Firebase Storage]
  APP --> FCM[FCM]
  APP --> FN["HTTPS callables\nsouthamerica-east1"]
  APP --> DRIFT[(Drift — só gifts)]

  FN --> MAPS[Google Maps / CEP — via cache]
  FN --> IA[OpenAI — calculadora]
  FN --> MAIL[E-mail — convite / MFA]
  FN --> FS
```

## 7. Fluxo de uma ação na UI

```mermaid
sequenceDiagram
  participant Page as Page / Section
  participant Ctrl as GetX Controller
  participant UC as Use case ou repositório de domínio
  participant Impl as RepositoryImpl
  participant DS as Datasource
  participant Ext as Firestore / Functions / Drift

  Page->>Ctrl: gesto do usuário
  Ctrl->>UC: método de negócio
  UC->>Impl: contrato
  Impl->>DS: leitura/escrita
  DS->>Ext: SDK / HTTP
  Ext-->>DS: mapa / documento
  DS-->>Impl: Model
  Impl-->>UC: Entity
  UC-->>Ctrl: Entity
  Ctrl-->>Page: Rx / Obx
```

## 8. Gifts (único fluxo offline-first completo)

```mermaid
sequenceDiagram
  participant UI as Área do convidado / organizador
  participant Ctrl as GiftController
  participant UC as GiftUseCases
  participant Repo as GiftRepositoryImpl
  participant Local as GiftLocalDatasource Drift
  participant Rem as GiftRemoteDatasource Firestore

  UI->>Ctrl: listar / reservar / PIX
  Ctrl->>UC: call
  UC->>Repo: contrato
  Repo->>Local: lê/grava na hora
  Local-->>UI: Stream local
  Repo->>Rem: sync quando houver rede
  Rem-->>Repo: remoto
  Repo->>Local: reconcilia
```
