# Calculadora Festa - Interface de IA

## O que foi feito

1. Criado `ICalculadoraFestaAIService` como contrato oficial da IA.
2. `CalculadoraFestaAIService` passou a implementar esse contrato.
3. Corrigido o erro de cast em `diferencaOrcamento`.
4. O método `analisarEstimativa` agora retorna `Future<AnaliseCalculadoraIAModel>`.
5. O controller foi ajustado para depender da interface e usar `await`.
6. Criada uma implementação remota opcional: `CalculadoraFestaRemoteAIService`.

## Por que isso é importante

Agora o controller não depende mais diretamente da IA local. Ele depende de uma abstração.
Isso permite trocar a IA local por uma IA remota no futuro sem reescrever a calculadora.

## Arquitetura

```text
ICalculadoraFestaAIService
        ↑
        ├── CalculadoraFestaAIService          // IA local baseada em regras
        └── CalculadoraFestaRemoteAIService    // IA generativa via backend futuramente
```

## Ajuste obrigatório no controller

Onde antes era:

```dart
final CalculadoraFestaAIService _aiService;
```

Agora fica:

```dart
final ICalculadoraFestaAIService _aiService;
```

E a chamada passa a ser:

```dart
final analise = await _aiService.analisarEstimativa(
  estimativa: estimativa,
  itensCalculados: itensCalculados.toList(),
  tipoEvento: tipoEventoAtual.value,
  orcamentoDisponivel: orcamentoDisponivel.value,
);
```

## Próximo passo

Depois dessa etapa, podemos criar o backend de IA generativa para receber o payload e retornar
`AnaliseCalculadoraIAModel` em JSON estruturado.
