# Auditoria de subcolecoes Firestore

Este inventario registra as subcolecoes encontradas nas regras e no codigo do app, com a decisao de auditoria adotada.

## Auditadas

| Caminho | Trigger | Contexto associado |
| --- | --- | --- |
| `usuarios/{idUsuario}/enderecos/{id}` | `auditarEnderecosUsuario` | usuario |
| `estado/{idEstado}/cidades/{id}` | `auditarCidadesEstado` | catalogo |
| `evento/{idEvento}/presentes/{id}` | `auditarPresentesEvento` | evento |
| `evento/{idEvento}/presentes/{idPresente}/contributions/{id}` | `auditarContribuicoesPresente` | evento |
| `evento/{idEvento}/tarefas/{id}` | `auditarTarefasEvento` | evento |
| `evento/{idEvento}/orcamento/{id}` | `auditarOrcamentosEvento` | evento |
| `cardapios/{idCardapio}/itens/{id}` | `auditarItensCardapio` | evento do cardapio pai |
| `fornecedor/{idFornecedor}/avaliacoes/{id}` | `auditarAvaliacoesFornecedor` | fornecedor |
| `fornecedor_servico/{idServico}/avaliacoes/{id}` | `auditarAvaliacoesServicoFornecedor` | fornecedor e servico pai |
| `orcamento/{idOrcamento}/orcamento_gasto/{id}` | `auditarGastosOrcamento` | orcamento, evento e fornecedor do orcamento pai |
| `cotacao/{idCotacao}/fornecedores/{idFornecedor}` | `auditarRespostasCotacaoFornecedor` | cotacao e fornecedor |
| `cotacao/{idCotacao}/fornecedores/{idFornecedor}/servicos/{id}` | `auditarServicosCotacaoFornecedor` | cotacao, evento, fornecedor e servico |
| `calculadora_festa/{idCalculo}/itens/{id}` | `auditarItensCalculadoraFesta` | evento da calculadora pai ou do item |
| `calculadora_festa/{idCalculo}/analises_ia/{id}` | `auditarAnalisesCalculadoraFesta` | evento da calculadora pai ou da analise |
| `posts/{idPost}/comentarios/{id}` | `auditarComentariosComunidade` | post/comunidade |

## Nao auditadas de proposito

| Caminho | Motivo |
| --- | --- |
| `cotacao/{idCotacao}/fornecedores/{idFornecedor}/mensagens/{id}` | Conteudo conversacional, alto volume e risco de registrar dados sensiveis no detalhe da auditoria. |
| `fornecedor/{idFornecedor}/{subcolecao}/{id}` generico | Regra permissiva para subcolecoes futuras; auditar por curinga pode capturar dados nao classificados. |
| `evento/{idEvento}/{subcolecao}/{id}` generico | Regra permissiva para subcolecoes futuras; subcolecoes conhecidas foram mapeadas explicitamente. |
| `calculadora_festa/{idCalculo}/{subcolecao}/{id}` generico | Apenas `itens` e `analises_ia` foram encontrados no codigo atual. |
| `password_reset_codes`, `mfa_totp`, `mfa_email_codes` | Colecoes sensiveis bloqueadas para cliente e com auditoria propria por callable/servico. |
| `_maps_cache`, `_cep_lookup_limits`, `auditoria_rate_limits` | Colecoes tecnicas/cache/rate-limit, sem valor para auditoria funcional. |

## Regra para novas subcolecoes

Toda nova subcolecao funcional deve ganhar um trigger explicito em `functions/src/functions/auditoria/auditTrailTriggers.ts`, uma entrada em `functions/src/functions/auditoria/catalogoAuditoria.ts`, export em `functions/src/index.ts` e titulo correspondente em `lib/data/models/auditoria/auditoria_catalogo.dart`.
