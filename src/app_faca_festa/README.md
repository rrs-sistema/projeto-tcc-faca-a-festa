# Faça a Festa — estrutura do projeto

Aplicativo multiplataforma (Android, Web e Desktop) em **Flutter**, organizado em **Clean Architecture** com GetX na composição/UI e Firestore + Cloud Functions no backend.

## Documentação técnica

A descrição das camadas, regras de dependência e organogramas está em:

- [`document/arquitetura/README.md`](document/arquitetura/README.md) — índice
- [`document/arquitetura/01-camadas-e-regras.md`](document/arquitetura/01-camadas-e-regras.md)
- [`document/arquitetura/02-organogramas.md`](document/arquitetura/02-organogramas.md) — diagramas Mermaid
- [`document/arquitetura/03-modulos-bootstrap-e-fluxos.md`](document/arquitetura/03-modulos-bootstrap-e-fluxos.md)

## Pastas em `lib/`

```text
lib/
├── main.dart              # Firebase, Drift (gifts), AppBootstrap, runApp
├── app/                   # Composition root: bootstrap, rotas, tema, middleware
├── domain/                # Entidades, contratos, casos de uso (sem Firebase/GetX)
├── data/                  # Datasources, models, repositories_impl, adapters
├── presentation/          # Módulos GetX (pages, controllers, sections)
└── core/                  # Drift, plataforma, validadores, helpers
```

Dependências apontam para dentro: `presentation` e `data` usam `domain`; `domain` não conhece UI nem Firebase. GetX de DI fica em `app/bootstrap`.

## Backend

Cloud Functions v2 em `functions/src`, região **`southamerica-east1`** (auth/MFA, auditoria, cotação, convite, calculadora IA, recomendação de fornecedores, CEP Google com cache).

## Stack

Flutter 3.x · GetX · Firebase (Auth, Firestore, Storage, Functions, Messaging, App Check) · Drift/SQLite no módulo de presentes
