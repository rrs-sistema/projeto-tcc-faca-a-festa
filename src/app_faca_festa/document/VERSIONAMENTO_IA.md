# Versionamento e rastreabilidade da IA — Faça a Festa

## Objetivo

Garantir que cada análise gerada pela IA da calculadora inteligente possa ser auditada no futuro, informando exatamente qual versão do prompt, qual versão do schema, qual modelo de IA e quais sugestões base foram usadas como contexto.

## Por que versionar o prompt?

O prompt é parte da regra de negócio da IA. Quando o texto do prompt muda, a IA pode passar a priorizar outros critérios, usar outro tom ou interpretar o mesmo cálculo de forma diferente.

Por isso, cada análise salva deve registrar:

- `nome_prompt`
- `versao_prompt`

Assim, uma análise antiga continua explicável mesmo depois que o prompt evoluir.

## Por que versionar o schema?

O schema define o contrato da resposta da IA. Se novos campos forem adicionados ou se algum campo mudar de significado, análises antigas podem não ter a mesma estrutura das novas.

Por isso, cada análise salva deve registrar:

- `versao_schema`

Esse campo permite que o app Flutter mantenha compatibilidade com análises antigas e novas.

## Por que salvar os IDs das sugestões base utilizadas?

As sugestões da coleção `ia_sugestoes_base` funcionam como contexto curado do produto. Elas influenciam a recomendação da IA.

Se uma sugestão for alterada no futuro, ainda precisamos saber quais sugestões foram usadas na análise original.

Por isso, cada análise salva deve registrar:

- `ids_sugestoes_base_utilizadas`
- `versoes_sugestoes_base_utilizadas`
- `total_sugestoes_base_utilizadas`

## Campos adicionados em `ia_sugestoes_base`

Cada documento de sugestão base passa a ter campos editoriais:

```json
{
  "versao": 1,
  "origem": "seed_inicial",
  "revisado_por": "admin",
  "data_revisao": "2026-05-27T00:00:00.000Z",
  "data_publicacao": "2026-05-27T00:00:00.000Z",
  "status_revisao": "aprovada",
  "observacao_revisao": "Sugestão validada para cálculo de bebidas"
}
```

## Campos adicionados na análise IA

A análise salva em `calculadora_festa/{id}/analise_ia` deve conter:

```json
{
  "nome_prompt": "calculadora_festa_analise_ia",
  "versao_prompt": "1.1.0",
  "versao_schema": "1.2.0",
  "ids_sugestoes_base_utilizadas": ["abc", "def"],
  "versoes_sugestoes_base_utilizadas": {
    "abc": 1,
    "def": 2
  },
  "total_sugestoes_base_utilizadas": 2,
  "modelo_ia_utilizado": "gpt-4o-mini",
  "data_processamento": "2026-05-27T00:00:00.000Z"
}
```

## Como rastrear uma análise antiga

1. Abra o documento da simulação em `calculadora_festa`.
2. Leia o objeto `analise_ia`.
3. Verifique `versao_prompt` e `versao_schema`.
4. Verifique `ids_sugestoes_base_utilizadas`.
5. Para cada ID, consulte `ia_sugestoes_base/{id}`.
6. Compare a versão atual da sugestão com o valor salvo em `versoes_sugestoes_base_utilizadas`.

Se a versão atual da sugestão for diferente da versão usada na análise, a recomendação antiga não deve ser reavaliada com base no texto atual da sugestão.

## Como auditar uma recomendação da IA

Para auditar uma recomendação:

1. Identifique a simulação original.
2. Confirme os dados de entrada: convidados, orçamento, duração e itens calculados.
3. Confirme o `modelo_ia_utilizado`.
4. Confirme `nome_prompt` e `versao_prompt`.
5. Confirme `versao_schema`.
6. Confirme as sugestões base usadas e suas versões.
7. Compare a recomendação com os dados que estavam disponíveis no momento do processamento.

## Como evoluir o prompt sem quebrar histórico

Ao alterar o prompt:

1. Não altere análises antigas.
2. Incremente `PROMPT_CALCULADORA_IA_VERSION`.
3. Registre no histórico interno o motivo da mudança.
4. Garanta que a Cloud Function continue preenchendo os campos de rastreabilidade.
5. Mantenha o Flutter compatível com campos ausentes em análises antigas.

## Política recomendada de versionamento

Use versionamento semântico simples:

- `1.0.0`: primeira versão estável.
- `1.1.0`: mudança de orientação, tom, critérios ou melhorias sem quebrar contrato.
- `2.0.0`: mudança incompatível no contrato ou comportamento principal.

## Compatibilidade com documentos antigos

Documentos antigos de `ia_sugestoes_base` podem não ter os campos novos. O backend deve assumir:

- `versao = 1`
- `origem = "legado"`
- `status_revisao = "aprovada"`
- `excluido = false`

Análises antigas também podem não ter rastreabilidade. O Flutter deve usar fallbacks, por exemplo:

- `versaoPrompt = "1.0.0"`
- `versaoSchema = "1.0.0"`
- `modeloIAUtilizado = "desconhecido"`
- `idsSugestoesBaseUtilizadas = []`
