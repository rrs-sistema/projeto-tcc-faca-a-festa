# Calculadora Inteligente - Transformar Simulação em Orçamento

## O que foi entregue

Esta etapa fecha o ciclo da calculadora:

Cadastro do evento -> Calculadora Inteligente -> Simulação salva -> Simulação aprovada -> Orçamento gerado.

## Arquivos principais

- `calculadora_festa_controller.dart`
- `calculadora_festa_repository.dart`
- `calculadora_festa_model.dart`
- `calculadora_festa_item_model.dart`
- `minhas_simulacoes_calculadora_bottom_sheet.dart`
- `calculadora_festa_screen.dart`

## Regra implementada

A simulação só pode virar orçamento quando estiver com status `aprovada`.

O método central é:

```dart
Future<void> transformarSimulacaoEmOrcamento(CalculadoraFestaModel simulacao)
```

Ele:

1. Busca os itens da simulação.
2. Ignora itens que já foram enviados para orçamento.
3. Cria documentos na coleção `orcamento`.
4. Marca cada item da calculadora como `adicionado_ao_orcamento`.
5. Marca a simulação como `convertida_orcamento`.

## Coleção usada

O controller usa:

```dart
static const String _collectionOrcamentos = 'orcamento';
```

Se o seu projeto usa outro nome, como `orcamentos`, altere apenas essa constante.

## Campos criados no orçamento

Cada item gerado possui:

- `id_orcamento`
- `id_evento`
- `categoria`
- `item`
- `nome`
- `quantidade`
- `unidade`
- `custo_estimado`
- `custo_real`
- `status_pagamento`
- `status_orcamento`
- `origem`
- `id_calculo_origem`
- `id_item_calculadora`

## Observação importante

Eu não rodei `flutter analyze` aqui porque este ambiente não possui SDK Dart/Flutter. Após aplicar os arquivos no projeto, rode:

```bash
flutter analyze
```
