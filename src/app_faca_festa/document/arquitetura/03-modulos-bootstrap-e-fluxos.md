# Módulos, bootstrap e fluxos

## Mapa módulo de UI → domínio → dados

| Módulo `presentation/modules` | Arquivos Dart | Contratos principais | Bootstrap |
| --- | ---: | --- | --- |
| `fornecedor` | 41 | `FornecedorRepository`, localização, AI, recomendações | `FornecedorBootstrap`, `FornecedorRecomendacaoBootstrap` |
| `convidado` | 30 | `ConvidadoRepository`, `GrupoConvidadoRepository`, `CardapioRepository`, `TarefaRepository`, `PresenteReservationRepository` | `ConvidadoBootstrap` |
| `calculadora` | 18 | `CalculadoraFestaRepository`, itens base, sugestão base, migração | `CalculadoraBootstrap` |
| `admin` | 17 | `AdminDashboardRepository`, `EventosAdminRepository`, `OrcamentosAdminRepository`, `AdminTerritorioRepository` | `AdminDashboardBootstrap`, `EventosAdminBootstrap`, `OrcamentosAdminBootstrap`, `AdminTerritorioBootstrap` |
| `catalogo` | 17 | `CatalogoServicoRepository`, `ServicoProdutoRepository`, `ServicoFotoRepository` | `CatalogoServicoBootstrap`, `ServicoProdutoBootstrap`, `ServicoFotoBootstrap` |
| `auth` | 16 | `AutenticacaoRepository`, `PerfilUsuarioRepository` | `AutenticacaoBootstrap` |
| `inspiracao` | 15 | `InspiracaoRepository` | `InspiracaoBootstrap` |
| `eventos` | 13 | `EventoRepository` | `EventoBootstrap` |
| `usuario` | 10 | `PerfilUsuarioRepository`, `UfCidadeRepository`, `FotoPerfilRepository` | `PerfilUsuarioBootstrap`, `UfCidadeBootstrap` |
| `orcamento` | 9 | `OrcamentoRepository`, `OrcamentoGastoRepository` | `OrcamentoBootstrap`, `OrcamentoGastoBootstrap` |
| `app` | 8 | sessão, convite, carrinho de cotação | `AppControllerBootstrap` |
| `auditoria` | 5 | `AuditoriaRepository` | `AuditoriaBootstrap` |
| `tema` | 4 | `TemaFestaRepository` | `TemaFestaBootstrap` |
| `checklist` | 3 | `TarefaRepository` | (via `ConvidadoBootstrap`) |
| `gifts` | 3 | `GiftRepository` | `GiftBootstrap` / `GiftOfflineBootstrap` + `GiftBinding` |
| `avaliacao` | 2 | `AvaliacaoServicoRepository` | `AvaliacaoServicoBootstrap` |
| `cotacao` | 2 | `CotacaoRepository`, `SolicitacoesRepository` | `CotacaoBootstrap`, `SolicitacoesBootstrap` |
| `comunidade` | 1 | `ComunidadeRepository` | `ComunidadeBootstrap` |
| `ranking` | 1 | `RankingRepository` | `RankingBootstrap` |

`presentation/widgets` (17 arquivos) e `presentation/coordinators` (1) não são módulos de feature.

## Contratos de repositório (38)

`admin_dashboard`, `admin_territorio`, `auditoria`, `autenticacao`, `avaliacao_servico`, `calculadora_festa`, `calculadora_itens_base`, `cardapio`, `catalogo_servico`, `comunidade`, `convidado`, `convite_convidado`, `cotacao`, `documento`, `evento`, `eventos_admin`, `foto_perfil`, `fornecedor`, `fornecedor_localizacao`, `fornecedor_migracao`, `fornecedor_recomendacao`, `gift`, `grupo_convidado`, `inspiracao`, `orcamento`, `orcamento_gasto`, `orcamentos_admin`, `perfil_usuario`, `presente_reservation`, `push_token`, `ranking`, `servico_foto`, `servico_produto`, `solicitacoes`, `sugestao_base_festa`, `tarefa`, `tema_festa`, `uf_cidade`.

## Serviços de domínio (contratos) e adapters

| Contrato `domain/services` | Adapter típico em `data/` |
| --- | --- |
| `BuscarCepService` | `BuscarCepGoogleService` (ViaCEP existe, não é o caminho do perfil) |
| `AbrirConvitePorToken` | `AbrirConvitePorTokenService` (Functions) |
| `ConviteEmailService` | serviço de convite + callable de e-mail |
| `CalculadoraFestaService` / `CalculadoraFestaAiService` | remoto + Functions de IA |
| `FornecedorAiRegrasService` / generativo | `FornecedorAiService`, `FornecedorAiGenerativaService` |
| `AuditoriaRegistrar` | `AuditoriaRegistrarApp` |
| `EventoAtivoStore` | GetStorage (`GetStorageEventoAtivoStore`) |

## Subpastas de models (`data/models`)

`admin`, `auditoria`, `avaliacao`, `calculadora`, `cardapio`, `comunidade`, `convidado`, `cotacao`, `DTO`, `endereco`, `evento`, `fornecedor`, `fornecedor_intelligence`, `gift`, `orcamento`, `pagamento`, `servico_produto`, `tarefa`, `usuario`.

## Arranque do processo

```text
WidgetsFlutterBinding
  → FirebaseServicesBootstrap (Auth, Firestore, Functions, Storage, Messaging)
  → AppCheck (debug secret no console em desenvolvimento)
  → GetStorage
  → GiftOfflineBootstrap (Drift; timeout 5 s — falha não impede o app)
  → initializeDateFormatting pt_BR
  → PushNotificationsBootstrap
  → AppBootstrap.registerControllers
  → runApp(FacaFestaApp)  // GetMaterialApp
```

Rotas iniciais e papéis: `AppCicloSessao.processar` lê o perfil, aplica endereço principal, exige TOTP se necessário e navega:

| `usuario.tipo` | Destino típico |
| --- | --- |
| `F` | fluxo do fornecedor (`AppSessaoFornecedor`) |
| `C` | área do convidado / convite |
| `A` | `/admin` |
| demais (organizador) | `/HomeEventScreen` se houver evento ativo; senão `/welcome` |

## Exemplo: cadastro / edição de endereço no perfil

1. UI (`edit_usuario_screen` + `EnderecoSection`) fala com `UsuarioController` / `EnderecoUsuarioController`.
2. CEP: contrato `BuscarCepService` → Google via Functions + cache Maps.
3. UF/cidade: `UFCidadeController` ← `GerenciarUfsCidades` ← Firestore.
4. Persistência: `PerfilUsuarioRepository.salvarEndereco` → `EnderecoUsuarioModel` → subcoleção `usuarios/{id}/enderecos`.
5. Sessão: `AppCicloSessao.aplicarPerfil` escolhe o endereço principal **sem** `firstWhere`/`orElse` (lista runtime é `List<EnderecoUsuarioModel>`).

## Exemplo: evento ativo

1. `EventoController` usa `EventoRepository` e `EventoAtivoStore`.
2. Ao selecionar um evento, `EventoSessionCoordinator` dispara tema, orçamento, convidados, cardápio, grupos, tarefas, inspiração e fornecedores do evento.
3. Controllers colaboradores são resolvidos por closures `Get.isRegistered` — registrados em bootstraps posteriores não quebram o `Get.put` do evento.

## Cloud Functions tocadas pelo app

Grupos em `functions/src/functions`:

- **auth** — TOTP, e-mail MFA, redefinição de senha
- **auditoria** — trilha, integridade, falha de login
- **cotacao** — criar, responder, fechar
- **convite** — e-mail e token
- **calculadora** — análise IA
- **fornecedores** — avaliação, recomendação, migração de tipos de evento
- **tema** — capa
- **whatsapp** — integração pontual

Mais `functions/src/address/buscarCepGoogle.ts` e `mapsCache.ts` (TTL; o app não chama Google Maps “cru”).

## Como evoluir um módulo sem furar a camada

1. Entidade e contrato em `domain/`.
2. Model + datasource + `RepositoryImpl` em `data/`.
3. Bootstrap em `lib/app/bootstrap` (região de Functions: `southamerica-east1`).
4. Controller GetX em `presentation/modules/<feature>/controllers` com dependências no construtor.
5. Page em `pages/` sem `Get.find` novo se a rota já injeta no `AppRoutes`.
6. Teste do repositório/use case em `test/features/`.
