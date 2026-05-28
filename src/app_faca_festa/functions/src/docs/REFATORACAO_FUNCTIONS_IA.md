# Refatoração das Cloud Functions — Faça a Festa

## Objetivo

Separar responsabilidades das Cloud Functions mantendo o fluxo existente da calculadora inteligente e evoluindo a análise com a coleção `ia_sugestoes_base`.

## Estrutura final

```text
functions/src/
├── index.ts
├── functions/
│   ├── analisarCalculadoraFestaIA.ts
│   ├── novaAvaliacaoProcessar.ts
│   └── testarNotificacaoFornecedor.ts
├── services/
│   └── sugestoesBaseIAService.ts
├── shared/
│   └── firebaseAdmin.ts
├── seeds/
│   └── seedIaSugestoesBase.ts
├── openaiClient.ts
├── prompt.ts
├── fallback.ts
├── firestore.ts
├── schema.ts
├── types.ts
└── validators.ts
```

## Responsabilidades

### `index.ts`

Somente exporta as funções públicas que o Firebase deve registrar.

### `functions/analisarCalculadoraFestaIA.ts`

Apenas orquestra o fluxo:

1. valida autenticação;
2. normaliza payload;
3. busca sugestões base;
4. chama `runOpenAIAnalysis`;
5. salva a análise;
6. aciona fallback em caso de falha.

Não contém prompt, não instancia OpenAI e não contém regra de fallback.

### `openaiClient.ts`

Centraliza a chamada para OpenAI usando `defineSecret("OPENAI_API_KEY")`.

### `prompt.ts`

Centraliza as instruções da IA e o input enviado ao modelo.

### `services/sugestoesBaseIAService.ts`

Busca sugestões ativas na coleção `ia_sugestoes_base`, filtra por tipo de evento/perfil e ordena por prioridade/ordem.

### `fallback.ts`

Gera resposta local compatível com `AnaliseCalculadoraIAResponse` e aproveita sugestões base quando disponíveis.

## Observação sobre Firestore

A consulta de sugestões base foi feita de forma segura: busca por `modulo == calculadora` e aplica filtros complementares em memória. Isso evita acoplamento imediato a índices compostos complexos com arrays, ordenação e múltiplos filtros.

## Deploy

```bash
cd functions
npm run build
firebase deploy --only functions
```

## Seed

```bash
cd functions
npm run build
node lib/seeds/seedIaSugestoesBase.js
```

Ou configure um script próprio no `package.json`.
