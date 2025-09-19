# 🎉 Faça a Festa - Estrutura do Projeto

Aplicativo multiplataforma (Android, Web e Desktop) desenvolvido em **Flutter**,  
seguindo **Clean Architecture + GetX + Offline-first** para garantir organização,  
testabilidade e escalabilidade.

---

## 📂 Estrutura de Pastas

```plaintext
lib/
│
├── app/
│   ├── app.dart
│   ├── routes/
│   │   └── app_routes.dart
│   ├── bindings/
│   │   └── initial_binding.dart
│   └── theme/
│       ├── app_theme.dart
│       └── app_colors.dart
│
├── core/
│   ├── constants/
│   │   └── app_strings.dart
│   ├── errors/
│   │   └── exceptions.dart
│   ├── utils/
│   │   └── validators.dart
│   └── services/
│       ├── network_service.dart
│       ├── sync_service.dart
│       ├── notification_service.dart
│       └── push/
│           ├── fcm_service.dart
│           ├── local_notification.dart
│           └── notification_handler.dart
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   │   └── notification_repository.dart
│   └── usecases/
│       └── send_notification.dart
│
├── data/
│   ├── models/
│   │   └── notification_model.dart
│   ├── datasources/
│   │   └── remote/
│   │       └── notification_remote_ds.dart
│   └── repositories_impl/
│       └── notification_repository_impl.dart
│
├── presentation/
│   ├── modules/
│   │   └── notifications/
│   │       ├── notification_binding.dart
│   │       ├── notification_controller.dart
│   │       └── notification_page.dart
│   └── widgets/
│
└── main.dart



🏗️ Camadas da Arquitetura
🔹 app/

Configurações centrais da aplicação:

app.dart → Classe raiz (GetMaterialApp).

routes/ → Definição de rotas.

bindings/ → Injeta dependências com GetX.

theme/ → Tema e cores globais.

🔹 core/

Recursos reutilizáveis e de infraestrutura:

constants/ → Strings e chaves globais.

errors/ → Exceções customizadas.

utils/ → Validadores e helpers.

services/ → Serviços globais:

network_service.dart → Verifica conectividade.

sync_service.dart → Estratégia offline-first.

notification_service.dart → Fachada de notificações.

push/ → Integrações:

fcm_service.dart → Firebase Cloud Messaging.

local_notification.dart → Notificações locais.

notification_handler.dart → Roteamento de cliques.

🔹 domain/

Regras de negócio puras (independente de Flutter/Firebase):

entities/ → Modelos centrais (Evento, Convidado, Fornecedor...).

repositories/ → Contratos (interfaces).

usecases/ → Casos de uso (ex.: SendNotification, AgendarEvento).

🔹 data/

Implementações concretas:

models/ → DTOs para Firestore/SQLite.

datasources/ → Fontes de dados:

local/ → Drift/SQLite (offline).

remote/ → Firebase (Firestore, Auth, Storage).

repositories_impl/ → Implementações dos repositórios.

🔹 presentation/

Interface com o usuário (UI com GetX):

modules/ → Dividido por funcionalidades.
Exemplo: notifications/ contém:

notification_binding.dart → Injeta dependências.

notification_controller.dart → Estado e lógica.

notification_page.dart → Tela de histórico/configurações.

widgets/ → Componentes visuais reutilizáveis.

🔹 main.dart

Ponto de entrada:

Inicializa Firebase (firebase_options.dart).

Carrega AppWidget.

Aplica InitialBinding.

🚀 Benefícios

✅ Clean Architecture → Separação clara de responsabilidades.
✅ Testabilidade → Cada camada pode ser testada isoladamente.
✅ Escalabilidade → Fácil adicionar novos módulos.
✅ Offline-first → Suporte a Drift/SQLite + Firebase com sincronização.
✅ Reatividade (GetX) → Menos boilerplate, mais simplicidade.

🔧 Tecnologias

Flutter 3.x

GetX (estado, rotas, DI)

Firebase (Firestore, Auth, Functions, Storage, Messaging)

Drift/SQLite (offline-first)

flutter_local_notifications (notificações locais)
