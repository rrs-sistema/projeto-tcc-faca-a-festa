# Auditoria - validação de produção

Este módulo depende de três garantias antes de ir para produção:

- os clientes não podem criar, alterar ou excluir documentos em `auditoria_eventos`;
- administradores ativos podem ler todo o histórico;
- fornecedores ativos só podem ler eventos próprios com `visivel_fornecedor == true`.

## Testes automatizados

Para validar regras puras das Cloud Functions, parsing, filtros, paginação,
exportação, painel e tela de detalhe, execute na raiz do app:

```bash
npm run test:audit
```

Execute na raiz do app:

```bash
npm run test:rules
```

O comando sobe o emulador Firestore e executa `test/firestore/auditoria.rules.test.js`.

Pré-requisito local/CI:

- Firebase CLI instalado;
- JDK 21 ou superior disponível no `PATH`.

## Cenários cobertos

- Admin ativo consegue fazer `get` e `list` em `auditoria_eventos`.
- Admin inativo não lê auditoria.
- Usuário anônimo não lê auditoria.
- Organizador não lê auditoria.
- Fornecedor lê apenas evento próprio e visível.
- Fornecedor não lista a coleção inteira sem filtros de segurança.
- Fornecedor não consulta eventos de outro fornecedor.
- Nenhum cliente, nem admin, consegue criar, alterar ou excluir auditoria.

## Validação manual recomendada

No emulador ou ambiente de homologação, executar fluxos reais e conferir se cada evento traz:

- `acao`, `area`, `nivel` e `resumo`;
- `ator_uid`, `ator_nome`, `ator_email`, `ator_tipo`;
- `entidade_tipo`, `entidade_id`, `entidade_nome`;
- vínculos como `id_fornecedor`, `id_evento`, `id_cotacao`, `id_orcamento`;
- `mudancas` com antes/depois quando for atualização;
- `origem`, `document_path`, `operacao`, `plataforma` e `rota`;
- `algoritmo_hash` e `hash_integridade`.

## Verificação de integridade

Depois do deploy das Functions, um administrador pode chamar a callable
`verificarIntegridadeAuditoria` para recalcular o hash dos registros mais
recentes de `auditoria_eventos`.

Payload sugerido:

```json
{
  "limite": 300
}
```

Resposta esperada em ambiente saudável:

```json
{
  "ok": true,
  "sem_hash": 0,
  "invalidos": 0
}
```

Se `sem_hash` ou `invalidos` vier maior que zero, investigar as amostras
retornadas antes de usar a exportação como evidência.
