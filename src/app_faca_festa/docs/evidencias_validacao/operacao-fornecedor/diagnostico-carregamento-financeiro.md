# Diagnóstico do carregamento financeiro

Investigação de 27/10/2026, somente leitura no ambiente hospedado; correções e testes no repositório local. Nenhum deploy, gravação financeira, migração ou envio de mensagem.

## Causa confirmada

O aplicativo e o backend publicado estão em versões incompatíveis.

- A Function consultarResumoFinanceiroFornecedor existe em southamerica-east1, está ACTIVE e foi atualizada pela última vez em **22/10/2026 12:07:27, São Paulo** (15:07:27 UTC).
- Os logs de 27/10 mostram autenticação VALID e requisições POST retornando **HTTP200 em aproximadamente2–3,5 segundos**. Os HTTP204 são requisições preflight; não representam o resumo vazio. Não há indicação de timeout nesses acessos.
- A fonte efetivamente publicada foi lida pelo objeto versionado do pacote de deploy. O retorno usa o cálculo anterior, sem origem=contratos_repasses. Não retorna a nova projeção contratual usada pelo aplicativo atual.
- O controller atual exige origem=contratos_repasses e os totais numéricos. Ele rejeita a resposta antiga, lança um erro local e apagava os valores sob um aviso genérico. Portanto, HTTP200/autenticação válida não eram suficientes para a tela carregar.
- consultarPlanejamentoFornecedorFn, consultarPainelFornecedorFn, consultarAgendaFornecedorFn e consultarGestaoReputacaoFn **não constam da listagem de Functions publicadas**. Isso também explica a indisponibilidade das novas consultas dessas áreas; a mera alteração dos textos não corrigiria essa integração.

[Evidência sanitizada de versões e requisições](diagnostico-financeiro/evidencia-versoes.json). O pacote completo de fontes, credenciais e variáveis de ambiente não foram incluídos nas evidências do repositório.

## Correção local

A resposta incompatível agora tem tipo e diagnóstico próprios. O usuário vê **O serviço financeiro precisa ser atualizado para esta versão do aplicativo**, com detalhes recolhidos da consulta. Não é mais classificada como indisponibilidade genérica. Permissão, sessão, inconsistência financeira, serviço ausente e timeout também são diferenciados. Uma consulta compatível posterior limpa o diagnóstico.

A validação da projeção contratual foi preservada. A atualização do serviço é necessária para usar a base correta de comissão, líquido e repasses; aceitar silenciosamente o resumo antigo restauraria a divergência que motivou a unificação.

Arquivos: diagnostico_consulta_financeira.dart; financeiro_fornecedor_controller.dart; financeiro_fornecedor_page.dart; financeiro_contratos_unificado_test.dart.

## Verificações executadas

Leitura do ambiente:

```powershell
firebase functions:log --only consultarResumoFinanceiroFornecedor --lines 35 --project faca-a-festa
firebase functions:list --project faca-a-festa --json
```

Complemento em leitura: Cloud Functions v2 getFunction (data/estado/fonte), Cloud Logging entries:list (status/latência) e GET da geração específica do source.zip no Cloud Storage. Nenhuma chamada autenticada foi feita em nome do fornecedor para obter dados financeiros, nem houve alteração de recurso.

Validação local:

```powershell
flutter test test/features/financeiro/financeiro_contratos_unificado_test.dart test/features/financeiro/financeiro_fornecedor_test.dart test/features/financeiro/recebimentos_caixa_idempotencia_test.dart --reporter expanded
npm --prefix functions run build
firebase emulators:exec --project demo-financeiro-contratos --config firebase.operacao-test.json --only firestore "node functions/scripts/testVisaoContratoEmulator.js"
dart analyze lib/data/services/functions/diagnostico_consulta_financeira.dart lib/presentation/modules/financeiro/controllers/financeiro_fornecedor_controller.dart lib/presentation/modules/financeiro/pages/financeiro_fornecedor_page.dart test/features/financeiro/financeiro_contratos_unificado_test.dart
```

- **27 testes Flutter aprovados**: inclui reprodução sintética do formato publicado antigo, diagnóstico específico, ausência de valores falsos e recuperação para o contrato3150/comissão157,50/líquido2992,50 com protocolo novo.
- **Build TypeScript e integração no Firestore Emulator aprovados**, cobrindo2992,50 previsto e1992,50 pendentes após repasse1000, retenções, pagamento separado, legado, cancelamento e privacidade.
- **Análise estática sem problemas**, git diff --check aprovado.

[Flutter](diagnostico-financeiro/flutter.txt) · [Emulador](diagnostico-financeiro/emulador.txt) · [Análise](diagnostico-financeiro/analyze.txt).

## Ação necessária no ambiente em uso

Alinhar a publicação das Functions financeiras e operacionais compatíveis com o aplicativo, como uma atualização coordenada. Depois, validar as pré-condições dos contratos existentes; uma obrigação de comissão ausente ou inconsistente deve continuar sendo identificada, sem gerar quitação ou saldo artificial. Não houve deploy nesta investigação, conforme a restrição anterior. O ambiente hospedado ainda não está corrigido por esta alteração local de diagnóstico.
