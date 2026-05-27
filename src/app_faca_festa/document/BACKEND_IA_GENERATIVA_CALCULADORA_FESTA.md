# Backend / Cloud Function da IA Generativa — Faça a Festa

## 1. Objetivo

Este documento descreve como será a arquitetura da IA generativa da calculadora inteligente do aplicativo **Faça a Festa**.

A proposta é manter a calculadora atual como fonte confiável dos cálculos e usar a IA generativa como uma camada de **interpretação, análise e recomendação**. Ou seja, a IA não substitui as regras de cálculo do sistema. Ela recebe os dados já calculados, interpreta o cenário da festa e devolve orientações úteis para o organizador.

## 2. Visão geral da solução

O fluxo recomendado é:

```text
Flutter App
  ↓
Calculadora local calcula quantidades e custos
  ↓
Controller monta um payload estruturado
  ↓
Cloud Function recebe os dados da simulação
  ↓
Cloud Function chama o provedor de IA
  ↓
IA retorna uma resposta estruturada em JSON
  ↓
Cloud Function valida e normaliza a resposta
  ↓
Resultado é salvo no Firestore
  ↓
Flutter exibe a análise inteligente na tela
```

Essa arquitetura evita expor chaves de API dentro do aplicativo e mantém o controle da resposta da IA no backend.

## 3. Responsabilidade de cada camada

### 3.1 Flutter App

Responsável por:

- Capturar os dados do evento;
- Informar adultos, crianças e bebês;
- Executar a calculadora local;
- Salvar simulações;
- Exibir a análise da IA;
- Transformar simulações aprovadas em orçamento.

O Flutter não deve conter chave de API da IA.

### 3.2 Calculadora local

Responsável por:

- Calcular convidados equivalentes;
- Calcular quantidade por item;
- Calcular custo estimado;
- Aplicar perfil da festa;
- Aplicar margem de segurança;
- Gerar simulação;
- Gerar itens para orçamento.

Essa camada continua sendo a fonte de verdade para os cálculos.

### 3.3 Cloud Function

Responsável por:

- Receber os dados da simulação;
- Validar se o usuário tem permissão;
- Montar o prompt da IA;
- Chamar o provedor de IA;
- Exigir retorno em JSON;
- Validar o JSON recebido;
- Salvar a análise no Firestore;
- Retornar o resultado para o app.

### 3.4 IA Generativa

Responsável por:

- Interpretar o cenário;
- Explicar riscos;
- Gerar recomendações;
- Sugerir economia;
- Apontar pontos de atenção;
- Sugerir próximas ações.

A IA não deve alterar cálculos matemáticos feitos pelo sistema.

## 4. Por que usar Cloud Function

A Cloud Function será usada como intermediária entre o aplicativo Flutter e o provedor de IA.

Motivos:

- Protege a chave da API;
- Centraliza regras de segurança;
- Permite validar os dados antes de chamar a IA;
- Permite padronizar a resposta;
- Permite salvar histórico da análise;
- Facilita trocar o provedor de IA no futuro;
- Evita depender de lógica sensível no aplicativo.

## 5. Fluxo técnico detalhado

### 5.1 Usuário gera uma simulação

O usuário informa os dados da festa:

```text
Tipo de evento: Aniversário infantil
Perfil: Premium
Adultos: 30
Crianças: 20
Bebês: 5
Duração: 5 horas
Orçamento disponível: R$ 2.500,00
```

A calculadora local gera:

```text
Total informado: 55 convidados
Total equivalente: 43 convidados
Custo estimado: R$ 3.932,60
Itens calculados:
- Salgadinhos
- Docinhos
- Bolo
- Refrigerante
- Água
- Lembrancinhas
```

### 5.2 App envia para a Cloud Function

O Flutter envia um payload estruturado para a função:

```json
{
  "idEvento": "evt_123",
  "idCalculo": "calc_123",
  "nomeEvento": "Aniversário do Vitor",
  "tipoEvento": "Aniversário infantil",
  "perfilFesta": "Premium",
  "adultos": 30,
  "criancas": 20,
  "bebes": 5,
  "totalInformado": 55,
  "totalEquivalente": 43,
  "duracaoHoras": 5,
  "orcamentoDisponivel": 2500.0,
  "custoTotalEstimado": 3932.60,
  "itens": [
    {
      "nome": "Salgadinhos",
      "categoria": "Recepção",
      "quantidade": 650,
      "unidade": "un",
      "valorUnitarioMedio": 0.9,
      "custoEstimado": 585.0
    }
  ]
}
```

### 5.3 Cloud Function monta o prompt

A função monta uma instrução para a IA, deixando claro que ela deve apenas analisar e recomendar.

Exemplo de orientação:

```text
Você é um assistente especialista em planejamento de festas.
Analise os dados enviados e gere recomendações práticas para o organizador.
Não refaça cálculos.
Não invente valores.
Use apenas os dados recebidos.
Responda exclusivamente em JSON válido.
```

### 5.4 IA responde em JSON estruturado

Resposta esperada:

```json
{
  "titulo": "Análise inteligente da festa",
  "resumoExecutivo": "A festa está acima do orçamento disponível e possui maior concentração de custo nos itens de recepção.",
  "diagnosticoFinanceiro": "O custo estimado ultrapassa o orçamento informado em aproximadamente R$ 1.432,60.",
  "diagnosticoConsumo": "As quantidades estão adequadas para o número de convidados equivalentes e para a duração do evento.",
  "recomendacaoFinal": "Recomenda-se comparar esta simulação Premium com uma simulação Padrão antes de converter em orçamento.",
  "sugestoes": [
    {
      "titulo": "Reduzir itens opcionais",
      "descricao": "Os itens opcionais podem ser ajustados para reduzir o custo sem comprometer os itens essenciais.",
      "impacto": "alto",
      "prioridade": "alta",
      "itemRelacionado": "Lembrancinhas"
    }
  ],
  "pontosDeAtencao": [
    "Custo acima do orçamento informado",
    "Evento com muitas crianças exige atenção a bebidas e descartáveis"
  ],
  "proximasAcoes": [
    "Comparar com uma simulação Padrão",
    "Revisar itens opcionais",
    "Aprovar a melhor simulação",
    "Transformar a simulação aprovada em orçamento"
  ]
}
```

## 6. Modelo de entrada recomendado

Arquivo sugerido no Flutter:

```text
planejamento_festa_ia_request.dart
```

Campos principais:

```dart
class PlanejamentoFestaIARequest {
  final String? idEvento;
  final String? idCalculo;
  final String? nomeEvento;
  final String? tipoEvento;
  final String perfilFesta;

  final int adultos;
  final int criancas;
  final int bebes;
  final int totalInformado;
  final int totalEquivalente;

  final int duracaoHoras;
  final double? orcamentoDisponivel;
  final double custoTotalEstimado;

  final List<ItemPlanejamentoIARequest> itens;

  const PlanejamentoFestaIARequest({
    this.idEvento,
    this.idCalculo,
    this.nomeEvento,
    this.tipoEvento,
    required this.perfilFesta,
    required this.adultos,
    required this.criancas,
    required this.bebes,
    required this.totalInformado,
    required this.totalEquivalente,
    required this.duracaoHoras,
    this.orcamentoDisponivel,
    required this.custoTotalEstimado,
    required this.itens,
  });
}
```

## 7. Modelo de saída recomendado

Arquivo sugerido no Flutter:

```text
planejamento_festa_ia_response.dart
```

Campos principais:

```dart
class PlanejamentoFestaIAResponse {
  final String titulo;
  final String resumoExecutivo;
  final String diagnosticoFinanceiro;
  final String diagnosticoConsumo;
  final String recomendacaoFinal;

  final List<SugestaoPlanejamentoIA> sugestoes;
  final List<String> pontosDeAtencao;
  final List<String> proximasAcoes;

  const PlanejamentoFestaIAResponse({
    required this.titulo,
    required this.resumoExecutivo,
    required this.diagnosticoFinanceiro,
    required this.diagnosticoConsumo,
    required this.recomendacaoFinal,
    required this.sugestoes,
    required this.pontosDeAtencao,
    required this.proximasAcoes,
  });
}
```

## 8. Interface no Flutter

A calculadora deve depender de uma interface, não de uma classe concreta.

```dart
abstract class ICalculadoraFestaAIService {
  Future<AnaliseCalculadoraIAModel> analisarEstimativa({
    required EstimativaFinanceiraModel estimativa,
    required List<CalculadoraFestaItemModel> itensCalculados,
    required String tipoEvento,
    double? orcamentoDisponivel,
  });
}
```

Implementações:

```text
CalculadoraFestaAIService
  → IA local baseada em regras

CalculadoraFestaRemoteAIService
  → IA generativa via Cloud Function
```

## 9. Cloud Function recomendada

Nome sugerido:

```text
analisarPlanejamentoFesta
```

Tipo:

```text
Callable Function
```

Responsabilidade:

```text
Receber simulação
Validar usuário
Validar evento
Montar prompt
Chamar IA
Validar JSON
Salvar análise
Retornar resultado
```

## 10. Estrutura sugerida no Firebase Functions

```text
functions/
  src/
    index.ts
    ai/
      analisarPlanejamentoFesta.ts
      buildPromptPlanejamentoFesta.ts
      schemas/
        planejamentoFestaSchema.ts
      services/
        openAIService.ts
```

## 11. Exemplo de contrato da função

Entrada:

```typescript
type AnalisarPlanejamentoFestaInput = {
  idEvento?: string;
  idCalculo?: string;
  nomeEvento?: string;
  tipoEvento?: string;
  perfilFesta: string;
  adultos: number;
  criancas: number;
  bebes: number;
  totalInformado: number;
  totalEquivalente: number;
  duracaoHoras: number;
  orcamentoDisponivel?: number;
  custoTotalEstimado: number;
  itens: Array<{
    nome: string;
    categoria: string;
    quantidade: number;
    unidade: string;
    valorUnitarioMedio: number;
    custoEstimado: number;
  }>;
};
```

Saída:

```typescript
type AnalisarPlanejamentoFestaOutput = {
  titulo: string;
  resumoExecutivo: string;
  diagnosticoFinanceiro: string;
  diagnosticoConsumo: string;
  recomendacaoFinal: string;
  sugestoes: Array<{
    titulo: string;
    descricao: string;
    impacto: "baixo" | "medio" | "alto";
    prioridade: "baixa" | "media" | "alta";
    itemRelacionado?: string;
  }>;
  pontosDeAtencao: string[];
  proximasAcoes: string[];
};
```

## 12. Persistência no Firestore

A análise da IA pode ser salva em:

```text
calculadora_festa/{idCalculo}/analises_ia/{idAnalise}
```

Campos sugeridos:

```text
id_analise
id_calculo
id_evento
tipo_origem: "local" | "generativa"
titulo
resumo_executivo
diagnostico_financeiro
diagnostico_consumo
recomendacao_final
sugestoes
pontos_de_atencao
proximas_acoes
created_at
modelo_ia
status
```

## 13. Fallback local

Se a Cloud Function falhar, o app deve continuar funcionando com a IA local baseada em regras.

Fluxo de fallback:

```text
Flutter chama IA remota
↓
Falhou
↓
Flutter usa CalculadoraFestaAIService local
↓
Usuário continua recebendo recomendações
```

Isso evita que a calculadora fique dependente da internet ou da API externa.

## 14. Segurança

Regras recomendadas:

- Nunca colocar chave da IA no Flutter;
- Validar autenticação na Cloud Function;
- Validar se o usuário tem acesso ao evento;
- Limitar tamanho do payload;
- Usar JSON estruturado;
- Registrar logs de erro sem expor dados sensíveis;
- Salvar apenas o necessário no Firestore;
- Manter fallback local.

## 15. Estratégia de evolução

### Etapa 1 — Atual

```text
IA local baseada em regras
```

### Etapa 2 — Próxima

```text
Contrato/interface da IA
```

### Etapa 3

```text
Cloud Function com IA generativa
```

### Etapa 4

```text
Histórico de análises por simulação
```

### Etapa 5

```text
Comparação inteligente entre simulações
```

### Etapa 6

```text
Recomendações personalizadas com base no histórico do usuário
```

## 16. Benefício para o projeto

A IA generativa agrega valor ao aplicativo porque transforma a calculadora em um assistente de planejamento. O usuário não recebe apenas números, mas também diagnóstico, recomendações e próximas ações.

Isso fortalece o projeto em três pontos:

```text
1. Experiência do usuário
2. Apoio à tomada de decisão
3. Integração entre cálculo, orçamento e planejamento
```

## 17. Decisão arquitetural final

A decisão recomendada é usar uma arquitetura híbrida:

```text
Calculadora local confiável
+
IA local baseada em regras
+
IA generativa via Cloud Function
```

Assim, o app mantém precisão nos cálculos, segurança no uso da IA e flexibilidade para evoluir o módulo futuramente.
