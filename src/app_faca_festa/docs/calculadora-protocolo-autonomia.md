# Protocolo de avaliação da autonomia

Este protocolo mede trabalho e qualidade em tarefas comparáveis. Não mede suficiência alimentar por si só e não autoriza registrar estimativas como consumo real.

## Sessões

Usar participantes identificados por pseudônimos, como `p01`. Definir antecipadamente os dados e o resultado esperado de cada caso. Alternar a ordem das versões entre os participantes para reduzir o efeito de aprendizagem. Registrar falhas e desistências; elas não podem ser removidas para melhorar o percentual.

Comparar a jornada anterior e a nova nas tarefas `propor`, `ajustar`, `comprar` e `revisar`, em quatro cenários: `tipo_orcamento`, `tipo_orcamento_publico`, `tipo_orcamento_cardapio` e `completo`. “Comprar” significa preparar/revisar a lista, sem executar uma compra externa. A revisão usa um caso de pós-evento previamente medido; o evento futuro não deve receber dados de teste.

Contar como intervenção cada edição concluída de um campo e cada decisão explícita necessária para concluir a tarefa. Não contar cada tecla ou um recálculo automático como uma decisão. Usar a mesma definição nas duas versões e um observador ou gravação consentida. Campos distintos e ações instrumentadas pelo app são diagnósticos auxiliares, não substitutos dessa contagem.

Registrar tempo ativo, correções, erros, conclusão, custo de IA na mesma moeda e latência observada. Um custo desconhecido não é zero. Conferir as quantidades e invariantes contra o resultado esperado do caso, além de duplicidades e preservação de compras, contratos e pagamentos. Não confundir a conferência da aritmética com validação empírica das porções.

## Arquivo de entrada

Um JSON com lista de sessões. Cada par tem o mesmo `participante`, `cenario`, `tarefa` e `contexto_comparavel`, e uma entrada de cada `modo`: `antes` e `depois`.

Campos obrigatórios por sessão:

| Campo | Tipo / significado |
| --- | --- |
| origem | `sessao_observada` |
| participante | Pseudônimo sem nome ou e-mail |
| cenario / tarefa | Uma das opções acima |
| modo | `antes` ou `depois` |
| versao_app | Versão efetivamente usada naquela sessão |
| contexto_comparavel | Identificador do caso fixado previamente |
| intervencoes | Inteiro não negativo; contagem integral observada |
| segundos_ativos | Inteiro não negativo |
| correcoes / erros | Inteiros não negativos |
| latencia_ia_ms | Inteiro não negativo, medido; zero se IA não foi usada |
| custo_ia | Número não negativo na moeda definida para o estudo |
| concluida | Booleano; falhas continuam na amostra |
| validacao_quantidades | Booleano, conforme o resultado esperado do caso |
| sem_duplicidades | Booleano |
| sem_alterar_fatos | Booleano, conforme compras/contratos/pagamentos do caso |

Executar na raiz do aplicativo:

```powershell
dart run tool/avaliar_autonomia_calculadora.dart caminho/sessoes-observadas.json
```

O programa rejeita pares ausentes, duplicados ou com contextos diferentes. Calcula `100 × (1 − intervenções_depois / intervenções_antes)` e apresenta também tempo, correções, custo e latência.

O piloto só sinaliza a meta com ao menos cinco participantes e cobertura pareada das 16 combinações de cenário/tarefa por participante, sem perda das verificações de qualidade, tarefas inconclusas ou aumento agregado de correções. Esse mínimo é uma porta operacional do piloto, não uma demonstração de significância estatística. Guardar os registros, inclusive tentativas malsucedidas, e relatar a cobertura efetiva. Resultados de testes sintéticos não podem ser usados como dados desse estudo.


## Coleta assistida pelo observador

A coleta pode ser feita com `tool/piloto_autonomia_calculadora.dart`, sem editar o JSON manualmente. O comando registra ações, pausa/retomada e falhas, preserva sessões finalizadas e exporta o formato aceito pelo avaliador. O roteiro alterna a primeira versão entre participantes.

A cobertura completa prevista para cinco participantes contém 160 sessões (5 × 16 tarefas/cenários × 2 versões). É possível salvar o progresso entre sessões; registros pendentes permanecem visíveis e não são omitidos para calcular um resultado final. Se houver encerramento inesperado durante a contagem, o tempo sem checkpoint não é presumido, e a medição fica incompleta.

Instruções e evidências: [entrega 4](calculadora-fase4-piloto-2026-10-17.md). Essa coleta pertence ao estudo conduzido pelo observador; não adiciona formulários ou decisões ao fluxo normal do organizador.
