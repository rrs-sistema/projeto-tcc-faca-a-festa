# Evidência — Prompt 08 Validação integrada e preparação da ativação

**Data:** 2026-10-21  
**Repositório:** `app_faca_festa` (branch `main`, working tree com alterações preexistentes preservadas)  
**Escopo:** auditoria ponta a ponta dos fluxos financeiros 01–07; matriz requisito→origem→comando→leitura→permissão→teste; fixtures; conciliação de perspectivas; roteiro de ativação sem publicação.  
**Não feito (conforme contrato):** deploy, commit, push, migração destrutiva, cobrança real, mensagens externas, publicação de índices/regras.

## 1. Diagnóstico

Capacidades financeiras presentes no código (confirmadas nesta passagem):

| Módulo | Domínio | Functions | UI | Rules |
|---|---|---|---|---|
| Fundação / conciliação evento | `resumo_financeiro_evento_service` | `contrato` / `liquidacao` | Orçamento + Conferir totais | `financeiro.rules.test.js` |
| Gestão gerente | `previsao_financeira_gerente_service` | resumo/previsão | `modules/financeiro` gerente | dono `evento.id_usuario` |
| Financeiro fornecedor (privado) | `resumo_financeiro_fornecedor_service` | callables privado | fornecedor | `uid == idFornecedor` |
| Estoque empresarial | `estoque_fornecedor_service` | estoque | estoque fornecedor | privado + outra empresa negada |
| Comissão plataforma | `comissao_plataforma_service` | política/obrigação | admin comissão | coleções `plataforma_comissao_*` |
| Dashboard admin | `dashboard_financeiro_admin_service` | agregado | dashboard admin | só admin |
| Simulação / precificação / teto | `simulacao_orcamento_evento_service` + precificação | `simularOrcamentoEvento` etc. | detalhe gerente | read-only |

**Defeitos de integração comprovados nesta passagem:** nenhum novo além dos já corrigidos nos prompts 01–07 (ex.: admin sem `orcamento_gasto`; `max(custo_real, estimado)` indevido). Controllers financeiros já invalidam `_geracao` em logout/troca de evento.

**Bloqueio de ativação (não é ausência de módulo):** JDK local 17.0.15 — emulador Firestore Rules exige JDK ≥ 21. Scripts `npm run test:rules:*` financeiros existem mas **não foram executados** nesta máquina.

## 2. Matriz requisito → origem → comando → leitura → permissão → teste → resultado

| # | Requisito | Origem persistida | Comando | Leitura | Permissão | Teste | Resultado |
|---|---|---|---|---|---|---|---|
| R1 | Contrato 10k / pago 3k / saldo 7k | `orcamento` + `contrato_financeiro` / obrigações | liquidação idempotente | resumo evento | dono evento / Functions | `testFinanceiroIntegrado` + Dart | **validado** |
| R2 | Limite 30k / 18k + 8k → previsão 26k | limite evento + compromissos + necessidades | — (cálculo) | previsão gerente | dono | integrado + `testPrevisaoGerente` | **validado** |
| R3 | Comissão 5% × 10k = R$500 uma vez; snapshot | `plataforma_comissao_obrigacoes` | gerar obrigação | admin | admin + política ativa | integrado + `testComissaoPlataforma` | **validado** |
| R4 | Estoque concorrente / cancelamento | `fornecedor/{uid}/estoque_*` | reservar / cancelar | privado | `uid==idFornecedor` | integrado + estoque | **validado** |
| R5 | Taxa futura preserva obrigações | snapshot em obrigação | gerar com `jaExistente` | — | admin | integrado | **validado** |
| R6 | Preço ausente ≠ economia | necessidades sem preço | — | previsão parcial `cabeNoLimite=null` | dono | integrado + Dart | **validado** |
| R7 | Pagamento evento ≠ recebimento fornecedor | fatos distintos | não copiar | duas perspectivas | cruzado negado | integrado conciliação | **validado** |
| R8 | Volume contratado ≠ receita plataforma | fatos comerciais + comissões | agregar dashboard | admin | só admin | integrado + dashboard | **validado** |
| R9 | Auth anônimo / evento alheio / outra empresa / elevação | — | Functions Admin SDK | rules | denial | integrado + `testAutorizacaoFinanceiro` | **validado** (lógica); rules emulator **não executado** (JDK) |
| R10 | Idempotência / concorrência / repetição | liquidação chave + estoque + simulação | callables | agregados | — | `testLiquidacaoConcorrencia` + integrado | **validado** (domínio/Functions unit) |
| R11 | Fuso America/Sao_Paulo | apresentação | — | UI/format | — | integrado Intl | **validado** (formatação) |
| R12 | Logout / troca evento | sessão GetX `_geracao` | cancelar subs | — | — | controllers + teste sessão fake | **validado** (código); E2E aparelho **não** |
| R13 | Anexos / exportações fiscais | — | — | — | — | — | **ausente** (módulo grande não construído) |
| R14 | Gateway de pagamento externo | — | — | — | — | — | **ausente** (fora do escopo) |
| R15 | Seed emulador Auth+Firestore com 6 personas | fixture JSON | Admin SDK seed | — | — | `prepararFinanceiroIntegradoEmulador.js` | **documentado**; seed Auth **não executado** (JDK/emulador) |
| R16 | Visual celular + desktop/web | UI financeiro | — | páginas | — | `fvm flutter run` ativo (Android) | **não executado** QA visual das superfícies financeiras nesta passagem |

Legenda: **validado** = teste atual passou; **ausente** = capacidade inexistente; **não executado** = bloqueio externo ou fora do instrumento.

## 3. Fixtures determinísticas

Arquivo: `docs/evidencias_validacao/financeiro/fixture-08-personas.json`  
Script: `npm --prefix functions run fixture:financeiro:integrado`

| Persona | uid | Papel |
|---|---|---|
| Organizador A | `org-1` | dono `evt-1` (= gerente autorizado) |
| Organizador B | `org-2` | dono `evt-2` (evento alheio) |
| Fornecedor A | `forn-1` | financeiro/estoque privados |
| Fornecedor B | `forn-2` | outra empresa |
| Administrador | `admin-1` | dashboard/comissões; **sem** custos privados de `forn-1` |

Contrato sintético de referência: R$ 10.000 / pago R$ 3.000 / saldo R$ 7.000.  
Política comissão exemplo: 500 bps **inativa** até decisão comercial.

## 4. Conciliação de perspectivas

| Perspectiva | Fato | Exemplo do teste | Não confundir com |
|---|---|---|---|
| Evento (pagador) | `pagoLiquido` | 4000 | Recebimento do fornecedor |
| Fornecedor | `recebido_confirmado` | 0 (não copiado) | Pagamento declarado pelo cliente |
| Plataforma | `receitaPlataformaCentavos` | 500_000 (comissões) | `pagamentosEventosCentavos` / volume |

Diferenças unilaterais são esperadas até conciliação explícita; o sistema **não** espelha dados privados do cliente como caixa confirmado do fornecedor.

## 5. Arquitetura (integração)

```
Orçamento / Gerente / Fornecedor / Admin / Estoque / Comissão
        ↓ domínio Dart (centavos + legado double)
Functions v2 southamerica-east1 (Admin SDK + auth própria)
        ↓
Firestore (empresa/evento/orcamento + subcoleções privadas + plataforma_comissao_*)
Rules: dono evento | uid fornecedor | admin plataforma
```

## 6. Arquivos desta passagem

- `functions/scripts/testFinanceiroIntegrado.js`
- `functions/scripts/prepararFinanceiroIntegradoEmulador.js`
- `functions/package.json` (`check:financeiro` inclui integrado; `check:financeiro:integrado`; `fixture:financeiro:integrado`)
- `test/features/financeiro/validacao_integrada_test.dart`
- `docs/evidencias_validacao/financeiro/fixture-08-personas.json`
- `docs/evidencias_validacao/financeiro/08-validacao-integrada.md`

## 7. Formato / compatibilidade / índices

- Novos fatos: centavos inteiros BRL; legado double lido com conversão explícita ×100 onde aplicável.
- Sem migração silenciosa em produção.
- Índices financeiros: alterações em `firestore.indexes.json` da árvore de trabalho (prompts anteriores); **não publicados**.
- Working tree ampla (calculadora, MFA, etc.) preservada — não revertida.

## 8. Testes e resultados reais

```
# Domínio / Functions
npm --prefix functions run check:financeiro             → ok (inclui integrado)
fvm flutter test test/features/financeiro …            → 58 passed

# Rules (JDK 21 via Android Studio JBR)
$env:JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"
npm run test:rules:financeiro:all → Script exited successfully (code 0)
  ✓ financeiro (dono/intruso/write)
  ✓ financeiro_fornecedor (custos privados)
  ✓ estoque_fornecedor
  ✓ comissao_plataforma
  ✓ dashboard_admin

# Fixture seed Auth+Firestore
npm run fixture:financeiro:integrado → seeded:true + authSeeded:true
  Firestore @ 127.0.0.1:8080 | Auth @ 127.0.0.1:9099
  Personas: org-1, org-2, forn-1, forn-2, admin-1 (senha sintética)

# Smoke rules integrado (6 contextos)
npm run test:rules:financeiro:integrado → ok
  org-1 lê; org-2/anônimo negados; admin sem custos privados; forn cruzado negado
```

| Cenário mínimo | Status |
|---|---|
| 10k / 3k / 7k | OK |
| 30k → previsão 26k | OK |
| Comissão R$500 + versão | OK |
| Estoque concorrente / cancel | OK |
| Taxa futura / preço ausente | OK |
| Conciliação perspectivas | OK |
| Auth cruzada / anônimo / elevação | OK (lógica + rules) |
| Idempotência simulação | OK |
| America/Sao_Paulo | OK (21/10/2026, 15:00 a partir de 18:00Z) |
| Rules Firestore financeiras | OK (JDK 21 JBR) |
| Seed Firestore + Auth 5 personas + contrato 10k/3k | OK |
| Smoke rules integrado (cruzamentos) | OK |

### Não executado

| Item | Motivo |
|---|---|
| E2E autenticado em produção/demo remota | contrato: recusa produção |
| Revalidação visual pós-hot-restart nas 6 telas | sessão Flutter do usuário (Chrome/Windows ativos) |
| Cobrança / mensagens externas | fora do escopo |
| Deploy de Functions/rules/índices | contrato: sem publicação |

Lint Functions: script `lint` apenas ecoa skip — **não** comprova análise estática; `tsc --noEmit` foi a verificação usada.

**JDK:** PATH padrão ainda aponta JDK 17; rules exigem JDK ≥ 21. Usar temporariamente  
`JAVA_HOME=C:\Program Files\Android\Android Studio\jbr` (OpenJDK 21.0.6).

## 9. Correções nesta passagem

### Harness inicial
Entrega = harness + fixture + evidência + scripts npm. Correções substantivas 01–07 preservadas.

### Correções visuais (evidências 01–06, ordem)

| # | Superfície | Defeito | Correção |
|---|---|---|---|
| 01 | Financeiro fornecedor | Callable falha + alertas triplicados | Gateway HTTPS; merge de alertas sem concatenar; listeners locais cobrem a tela |
| 02 | Comissões admin | `firebase_functions/internal` / pigeon | Gateway + fallback Firestore local do extrato |
| 03 | Dashboard admin | `firebase_functions/internal` | Gateway + agregado local sem custos privados |
| 04 | Estoque fornecedor | Lista OK; cadastro sem try/catch | Gateway HTTPS; erro de cadastro capturado |
| 05 | Comissões pagador | `CloudFunctionsHostApi.call` (Windows) | Mesmo gateway HTTPS + fallback local |
| 06 | Financeiro organizador | Lista vazia em cache → erro duro | Empty ≠ falha; limpa erro após carga pontual |

Arquivos: `financeiro_callable_gateway.dart`, remotes financeiros, `compromissos_evento_remote.dart`, controllers, `app_routes.dart`.

## 10. Roteiro de ativação posterior (sem publicar agora)

1. **Decisões comerciais**
   - Pagador da comissão (fornecedor / organizador / absorve).
   - Gatilho (contratação vs evento realizado).
   - Percentual bps e vigência; política nasce **inativa**.
   - Teto compartilhado com fornecedor: opt-in explícito por necessidade.

2. **Configurações**
   - Projeto/ambiente demo ou homolog — nunca produção nesta etapa.
   - Secrets (se houver gateway futuro) só via Secret Manager; não embutir no Flutter.
   - Feature flags / política `ativa: false` até go-live comercial.

3. **Regras e índices**
   - Instalar JDK ≥ 21; rodar `npm run test:rules:financeiro` e variantes.
   - Dry-run: `firebase deploy --only firestore:rules,firestore:indexes --project <demo>` **após** aprovação (não nesta passagem).

4. **Compatibilidade e migração**
   - Dry-run em emulador: ler orçamentos legados double; gravar centavos só em fatos novos.
   - Não reescrever `pago` bool legado como liquidação comprovada.
   - Reconstruir agregados admin a partir das origens; comparar com dashboard.

5. **Observabilidade**
   - Logs estruturados nas callables financeiras (sem PII de custos privados em canais admin).
   - Métricas: falhas `permission-denied`, idempotência hit, estoque `failed-precondition`.

6. **Desativação de novas escritas / fatos já gravados**
   - Desligar política de comissão (`ativa: false`) e callables de escrita via flag.
   - Fatos já gravados (obrigações, liquidações, reservas) permanecem; estorno/ajuste com histórico, autor, motivo.
   - Listeners cliente: logout/troca evento já incrementam `_geracao` — validar em homolog.

7. **Checklist go-live**
   - [ ] Rules + índices no ambiente alvo
   - [ ] Política comissão aprovada e ativada
   - [ ] Fixture personas reexecutada no emulador com JDK 21
   - [ ] Smoke autenticado: org-1, forn-1, admin-1, denials org-2/forn-2
   - [ ] Visual gerente + fornecedor + admin em mobile e web/desktop
   - [ ] Plano de rollback (desativar escritas; manter leitura)

## 11. Conclusão

| Classe | Itens |
|---|---|
| **Validado** | R1–R11; rules (5+integrado); seed Auth+Firestore; conciliação; sessão `_geracao` |
| **Corrigido (passagens anteriores)** | Conciliação admin↔detalhe; compromisso; privacidade; estoque; comissão; dashboard; simulação |
| **Corrigido (esta passagem)** | Gateway HTTPS; alertas; empty cache; fallback local |
| **Não executado** | Deploy; E2E produção; re-QA visual pós-hot-restart pelo usuário |
| **Ausente** | Gateway pagamento; fiscal; exportações de grande porte |

**Escopo Prompt 08 (ambiente local):** fechado para domínio, Functions, rules, fixture Auth/Firestore e correções de integração. Restam decisão comercial de comissão e confirmação visual após hot restart.

## 12. Pendências

1. ~~JDK ≥ 21 + rules~~ / ~~seed Firestore~~ / ~~seed Auth~~ / ~~smoke integrado~~.
2. Confirmar visualmente as 6 telas após hot restart (Chrome/Windows já em `flutter run`).
3. Decisões comerciais de comissão antes de ativar política (sem deploy).

Comando único local (JDK 21 no PATH/JAVA_HOME):
`npm run check:financeiro:completo`

### Roteiro visual rápido (pós hot restart)

1. Organizador → Financeiro: sem “Não foi possível atualizar…” com lista vazia.
2. Fornecedor → Financeiro da empresa: sem alertas triplicados.
3. Fornecedor → Estoque: lista/cadastro; Windows usa HTTPS.
4. Fornecedor → Comissões: sem `CloudFunctionsHostApi`.
5. Admin → Comissões / Financeiro administrativo: sem `internal` duro (fallback local se callable ausente).
