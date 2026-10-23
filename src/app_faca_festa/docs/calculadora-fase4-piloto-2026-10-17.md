# Entrega 4 — coleta observada e publicação do backend

17/10/2026. A infraestrutura necessária às entregas anteriores foi publicada antes de implementar esta etapa. O aplicativo não foi publicado e não houve gravação de dados no evento real.

## Deploy confirmado

Projeto `faca-a-festa`, região `southamerica-east1`:

| Recurso | Resultado |
| --- | --- |
| `aplicarPlanoCalculadora` | Criada; estado `ACTIVE` |
| `revisarRefeicaoCalculadora` | Criada; estado `ACTIVE` |
| `fecharCotacao` | Atualizada; estado `ACTIVE` |
| Regras do Firestore | Compiladas e publicadas |

O fechamento da cotação agora mantém o status de negócio fechado coerente com o orçamento criado; não cria pagamento. Os testes de autorização e consistência passaram antes do deploy.

Depois do deploy, os três endpoints retornaram HTTP 401 com `UNAUTHENTICATED` para chamadas sem credencial. Esse teste confirma disponibilidade e proteção da entrada; não equivale a executar uma aplicação autenticada em produção. Não foram feitas compras, pagamentos, revisões ou aplicações de plano no evento real.

Evidências locais: `.dart_tool/fase4-deploy.log`, `.dart_tool/fase4-funcoes-depois.json` e `.dart_tool/fase4-smoke-publicado.json`. Os arquivos de listagem completos ficam no diretório de ferramentas, sem serem incorporados ao relatório público.

## Coleta do piloto

O comando `tool/piloto_autonomia_calculadora.dart` permite ao observador trabalhar sem montar JSON à mão. Não integra o fluxo normal do organizador e não acessa o Firebase. O participante usa a versão da aplicação sob teste; o observador registra as ações separadamente.

- Roteiro com pseudônimos e versões anterior/nova, sem resultados pré-preenchidos.
- Dezesseis casos, com contexto e critério de aceite fixados antes da observação. O critério não muda depois que o caso recebe uma sessão.
- Ordem alternada: `p01` começa na versão anterior, `p02` na nova, e assim por diante, para cada par de tarefa/cenário.
- Contagem de intervenções, correções e erros; cronômetro com pausa e retomada explícitas. Uma correção já conta uma intervenção.
- Gravação a cada ação e saída com retomada. Arquivo com trava, revisão e substituição atômica evita sobrescrever outro acesso.
- Sessões finalizadas são preservadas, inclusive falhas. Uma retomada não pode diminuir contagens ou tempo já salvos.
- Custo/latência desconhecidos ficam pendentes, sem assumir zero. Zero é registrado quando o observador confirma que não houve chamada de IA.
- Se o processo encerrou durante a contagem, o intervalo sem checkpoint não é inventado. A observação retomada fica marcada com medição incompleta e não comprova a meta.
- Exportação mantém também sessões interrompidas. O painel de progresso mostra o que falta e só calcula o resultado final quando todas as sessões previstas estiverem finalizadas.

O avaliador também foi reforçado: cinco participantes com cobertura apenas agregada não bastam. Cada participante precisa ter os pares das 16 combinações; melhora percentual com falha de qualidade ou medição incompleta não aprova a meta. Essa é uma porta operacional conservadora do piloto, não um teste de significância estatística.

## Como usar

Identificar as versões realmente utilizadas. Executar os casos em ambiente de teste; o caso pós-evento usa dados previamente definidos para teste, sem preencher consumo fictício no evento de 23/10/2026. A revisão com medições reais daquele evento continua para depois da realização.

```powershell
dart run tool/piloto_autonomia_calculadora.dart criar observacoes.json baseline-identificada nova-identificada 5
dart run tool/piloto_autonomia_calculadora.dart caso observacoes.json completo propor caso-01
dart run tool/piloto_autonomia_calculadora.dart observar observacoes.json p01 completo propor antes
dart run tool/piloto_autonomia_calculadora.dart observar observacoes.json p01 completo propor depois
dart run tool/piloto_autonomia_calculadora.dart status observacoes.json
dart run tool/piloto_autonomia_calculadora.dart exportar observacoes.json > sessoes-observadas.json
dart run tool/avaliar_autonomia_calculadora.dart sessoes-observadas.json
```

O comando `caso` pede o critério de aceite. Usar os cenários e tarefas do [protocolo](calculadora-protocolo-autonomia.md). Durante a observação: `i` intervenção, `c` correção, `e` erro, `p` pausa, `r` retomada, `f` finalização e `q` salvar para continuar depois. Não registrar `i` adicional para a mesma correção já registrada com `c`.

Os dados ficam no arquivo escolhido pelo observador, sem nome, e-mail ou ID do evento. Não há transmissão automática. A contagem é observada por uma pessoa e continua dependendo da aplicação consistente do protocolo; o programa não certifica que uma entrada foi observada corretamente.

## Validação técnica e limite da entrega

- Backend: compilação e testes existentes de planejamento/IA/cotação aprovados antes do deploy.
- **238 testes da calculadora aprovados**: `.dart_tool/fase4-calculadora-tests.log`.
- Dez novos testes do piloto cobrem ausência de observações, ordem das versões, retomada, preservação das falhas, validação dos dados, cronômetro, persistência concorrente e portas de qualidade.
- Análise estática dos novos serviços, comandos e testes: sem problemas, em `.dart_tool/fase4-analysis.log`.
- Teste do comando completo: criação, critério, ordem inválida, pausa, correção, saída/retomada, finalização, exportação e leitura pelo avaliador. Registro em `.dart_tool/fase4-cli-smoke.json`. Usou dados sintéticos temporários e não é estudo com usuários.

**A preparação técnica da coleta está implementada. O piloto empírico ainda não foi realizado.** Não há comprovação de 70%–80%, nem dados reais de consumo do primeiro evento. O próximo passo operacional é observar os participantes nas versões e casos definidos, preservando falhas e resultados, e depois medir o consumo real quando o evento acontecer.
