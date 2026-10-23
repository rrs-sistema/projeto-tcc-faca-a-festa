# Plano de evolução: Calculadora Inteligente com 70%–80% menos intervenção

Data: 16/10/2026. Plano baseado na auditoria da jornada real e na análise da implementação atual. Esta entrega é um plano: não modifica funções, dados, regras ou publicação do aplicativo.

## 1. Objetivo e definição de sucesso

Transformar as informações iniciais do evento em uma proposta operacional completa, atualizável e rastreável, para que o organizador revise decisões e exceções em vez de configurar cada item.

70%–80% é uma meta de redução de trabalho humano necessário para chegar a um plano utilizável, e não uma porcentagem de inteligência ou uma garantia de exatidão. O resultado deve ser medido contra o fluxo atual em cenários equivalentes, mantendo visíveis os casos que o sistema não atende.

Métrica principal proposta: redução de intervenções obrigatórias = 1 − intervenções no novo fluxo / intervenções no fluxo de referência. A unidade será uma informação ou decisão humana necessária, incluindo confirmações e correções; toques, mudanças de tela, campos digitados e tempo ativo serão métricas auxiliares. Agrupar vários campos em um único botão não reduz artificialmente a contagem das informações exigidas.

Exemplo apenas de meta: uma tarefa que hoje exige 20 intervenções deveria exigir de 4 a 6. Esses números não representam uma medição já feita. A meta precisa ser acompanhada de conclusão da tarefa, erros de planejamento, correções, cobertura do catálogo e qualidade das referências. Não excluir os cenários difíceis do relatório para elevar o percentual.

## 2. Definições propostas para resolver a jornada

- Orçamento: explicitar quanto o usuário pretende gastar no evento inteiro; separar valor total, valores já comprometidos, pagamentos e verba restante. Não tratar todo o valor como alimentação.
- Planejamento antes do cadastro completo: manter um rascunho isolado do evento ativo. Data e endereço podem continuar sendo exigidos para formalizar o evento, sem impedir uma proposta preliminar.
- Público: fontes distintas para previsto no cadastro, não recusados, confirmados e manual. Mostrar a fonte em uso; manter overrides por refeição. Informar o que é estimado e o que é uma pessoa cadastrada.
- Cardápio: representar explicitamente refeição, categoria ou serviço transversal. Não renomear/migrar silenciosamente categorias antigas como “Bebidas” para refeições.
- Fornecedor: distinguir seleção do vencedor, negociação, contratação e pagamento. Alinhar textos da cotação e status do orçamento antes de automatizar cobertura.
- Ciclo de vida: separar estado do evento, estado do plano e revisão do pós-evento. Salvar edição não deve reiniciar o evento em planejamento. Concluir uma simulação não encerra o evento.

Essas são propostas de produto para o plano; ainda não são alterações aprovadas ou implementadas no modelo.

## 3. Experiência principal

Entrada: tipo + orçamento, com público e cardápio opcionais. Reaproveitar data, local, preferências e registros existentes quando houver.

Saída inicial: uma proposta preenchida, com público considerado, refeições, quantidades para servir, preparo, compras, distribuição de orçamento e pendências decisivas. Em evento com dados incompletos, apresentar quais partes da proposta já podem ser utilizadas e quais dependem de referência ou confirmação.

A interface deve concentrar a experiência em três blocos: Seu plano; Decisões que mudam o resultado; Compras e execução. Formulários avançados permanecem acessíveis por item. Conversa por texto é uma entrada opcional, não uma etapa obrigatória.

As decisões necessárias aparecem com alternativas e consequência. A meta de interface para os cenários comuns cobertos é resolver a proposta inicial com até três decisões adicionais e uma aprovação do conjunto, além das entradas iniciais. A medição não deve forçar esse limite quando existir uma ambiguidade material.

Não criar uma sequência de confirmações para cada campo. Depois que uma preferência for estabelecida, os recálculos de rascunho usam essa preferência e mostram o impacto. Alterações de compromisso já assumido recebem revisão específica.

## 4. Comportamento por combinação de entradas

| Entradas | Proposta esperada | Limite operacional |
| --- | --- | --- |
| Tipo + orçamento | Cenários de formato e público possível, com distribuição do valor | Capacidade depende de custos compatíveis; sem preços suficientes, a capacidade financeira fica pendente, sem ser inventada |
| Tipo + orçamento + pessoas | Cardápio e estrutura propostos para o público, com cenários de ajuste | Não reduzir porções indiscriminadamente para encaixar no valor |
| Tipo + orçamento + cardápio | Quantidades por pessoa e cenários de capacidade sustentados pelos custos disponíveis | Distinguir prato pronto de receita a preparar e não supor rendimento universal |
| Tipo + orçamento + pessoas + cardápio | Revisão conjunta, compras restantes e alternativas concretas | Preservar receitas, disponibilidade, contratações e decisões explícitas |
| Evento sem orçamento definido | Planejamento quantitativo quando houver público | Não apresentar cabimento financeiro; orientar orçamento apenas quando necessário |
| Público ausente | Capacidade sugerida como cenário, quando existir base de custo; caso contrário, faixa de público a escolher | Estimativa de público não cria convidados nem confirma presença |

A busca externa de preços continua fora do escopo inicial, conforme combinado. O planejador poderá aproveitar preços já informados, cotações e documentos do usuário, respeitando produto, unidade, estado, região e data quando disponíveis. Caso nenhum custo compatível exista, precisa manter a parte financeira pendente.

## 5. Capacidades da inteligência

### 5.1 Entender o evento e recuperar o que já existe

Montar um contexto único com o rascunho/evento, revisões, refeições, público, orçamento, serviços, estoque, receitas, preferências e observações reais. Distinguir origem e data de cada dado. Recuperar automaticamente escolhas compatíveis já feitas pelo organizador, sem transformar uma escolha de ocasião em preferência universal.

### 5.2 Reconhecer alimentos e recuperar referências

Ampliar a cobertura do catálogo a partir dos itens efetivamente usados no aplicativo. Identidades estáveis, sinônimos, receitas, papéis, estados e unidades devem preceder o cálculo. A IA pode classificar um nome e recuperar candidatos; números devem vir de referências ou receitas compatíveis verificadas pelo motor.

Prioridade da fonte: decisão explícita para a receita atual; receita privada confirmada; medição histórica que cumpra critérios; referência contextual curada; candidato a confirmar. As medições não devem substituir uma preferência explícita sem mostrar o motivo.

### 5.3 Raciocinar por refeição e pelo evento

Considerar conjunto de principais, acompanhamentos, alternativas, bebidas e serviços, com público por destino. A partilha de porções precisa representar como se pretende servir, não apenas contar quantos alimentos existem.

Incluir rendimentos de referência por receita, corte e preparo, classificados separadamente dos rendimentos medidos. Isso permite uma estimativa de compra no primeiro evento quando existir referência compatível. Nunca apresentar estimativa como medição própria.

### 5.4 Gerar e comparar planos

Preparar uma recomendação principal e, quando fizer sentido, uma alternativa com objetivo concreto: menos trabalho de preparo, melhor aproveitamento do que já existe, menor variedade ou menor custo conhecido. Comparar quantidades, compras, tarefas e custos disponíveis, preservando compromissos.

O cenário financeiro deve ser resolvido por cálculo sobre custos de origem conhecida. A IA não deve declarar economia a partir de preços ausentes, nem garantir suficiência ao reduzir a reserva.

### 5.5 Escolher perguntas por impacto

Antes de perguntar, simular consequências das respostas plausíveis. Priorizar mudanças em medida de compra, embalagens, cobertura de público, contratação, custo e execução. Consultar dados já cadastrados e respostas anteriores antes de perguntar novamente.

Exemplos de perguntas materiais: comprar pronto ou preparar; cachorro-quente tradicional ou mini; uma categoria de bebidas atende quais refeições; o orçamento inclui o espaço? Não pedir participação, grupo, rendimento e preço em um formulário inteiro quando uma escolha simples resolve a ambiguidade.

### 5.6 Preparar ações entre módulos

Propor reservas de estoque, criação/ajuste de cardápio, lista consolidada e tarefas com origem no plano. Desdobrar pratos em ingredientes a partir de uma ficha técnica, somando apenas ingredientes compatíveis e preservando seus destinos.

Aprovação agrupada deve aplicar um conjunto coerente. Repetir uma requisição não pode duplicar itens, tarefas ou reservas. Quantidade final, compra real, contratação e pagamento não são inferidos a partir de aceitar o plano.

### 5.7 Aprender com resultados e reduzir digitação

Aceitação/correção de sugestão informa preferência. Medições de preparado, sobra e falta informam consumo. Manter essa separação.

Pré-preencher a revisão com os registros reais existentes; pedir inicialmente o que faltou/sobrou e coletar quantidade quando ela existir. Não copiar o planejado como se fosse preparado.

Permitir texto e, em entrega posterior, leitura de documentos para sugerir registros de compra, quantidades e valores. Documentos precisam de revisão agrupada, diferenciação de cotação/compra/pagamento e detecção de duplicidade.

## 6. Divisão de autonomia

| Ação | Regime proposto |
| --- | --- |
| Ler dados permitidos, recuperar referências, identificar pendências | Automático |
| Calcular, simular, gerar rascunho, atualizar explicação | Automático |
| Preparar distribuição do estoque, ingredientes e tarefas | Automático como proposta |
| Aplicar o plano inicial ou mudanças materiais ao plano aprovado | Uma revisão do conjunto, com alterações claras |
| Preferências pessoais, público desejado e restrições não registradas | Informação/decisão do organizador quando material |
| Compra, pagamento, contratação e comunicação externa | Ação explícita autorizada; não executar implicitamente pelo cálculo |
| Ingredientes e preparo de receitas reais para grupos com restrições | Conferência do responsável; não inferir adequação pelo nome |

O usuário deve ter controle de correção simples e desfazer quando cabível. Não transformar esse controle em aprovação repetitiva para cada recálculo.

## 7. Arquitetura de execução

Aproveitar serviços existentes, com uma camada de planejamento e comandos estruturados:

1. Snapshot versionado do contexto, incluindo rascunho e ID de evento explícitos.
2. Recuperação de dados/referências compatíveis e identificação de lacunas.
3. IA propõe interpretação, perguntas e alternativas por IDs.
4. Motor atual calcula efeitos; validadores conferem medida, saldo, orçamento, grupos, compromissos e atualização da revisão.
5. Plano com mudanças e dependências, pronto para revisão.
6. Executor aplica operações autorizadas, deduplica requisições e registra execução parcial/falha quando necessário.
7. Observações e métricas alimentam a próxima proposta.

Uma ação precisa de tipo, destino por ID, valor proposto, origem, revisão consultada, dependências e chave de deduplicação. Nome de item e texto livre de recomendação não são autorização de gravação.

Usar transações quando as operações couberem na mesma unidade atômica. Fluxos entre coleções/módulos maiores precisam de estado de execução e recuperação explícita, sem anunciar sucesso completo após falha parcial. Histórico e mecanismo de desfazer devem respeitar registros financeiros e fatos efetivamente ocorridos.

Cache e disparos de IA devem considerar mudanças materiais do contexto. Aritmética, filtros, invariantes e recálculos não exigem uma chamada ao modelo. Manter o cálculo e a leitura do plano disponíveis quando o modelo remoto falhar.

## 8. Entregas e portas de qualidade

### Entrega 0 — Coerência da jornada e linha de base

- Isolar rascunho do evento ativo, levar orçamento digitado à estimativa e definir transferência ao salvar.
- Preservar status na edição; alinhar cotação, negociação e contratação.
- Definir fontes de público, atualização e categoria/refeição/serviço transversal.
- Instrumentar intervenções, tempo ativo, correções e resultados sem mudar a definição para favorecer a meta.

**Aceite:** regressões específicas dos caminhos identificados; novo evento nunca lê/grava no evento anterior; nenhum dado do rascunho some sem explicação; fluxo de referência medido.

### Entrega 1 — Proposta inicial realmente utilizável

- Catálogo e receitas para o conjunto inicial de cenários escolhidos a partir do uso real.
- Rendimentos estimados rastreáveis e composição das refeições.
- Plano do evento inteiro, com opções para as quatro combinações de entrada.
- Capacidade financeira apenas com custos suficientes; perguntas por impacto.

**Aceite:** entrega proposta antes do formulário técnico; preserva dados e receitas; informa limitações por parte do plano; evita perguntas respondidas; passa por todas as combinações da matriz.

### Entrega 2 — Menos trabalho na execução

- Aprovação agrupada, executor versionado e idempotente.
- Estoque distribuído como proposta; ingredientes consolidados; tarefas vinculadas.
- Atualização contínua ou explícita por fonte; mudanças no público mostram o que muda na compra e nos compromissos.

**Aceite:** uma aplicação cria/atualiza apenas o autorizado, sem duplicidades ou saldos excedidos; repetição e falha parcial recuperáveis; comprados/contratados/pagos permanecem fatos separados.

### Entrega 3 — Personalização e encerramento

- Memória privada com escopo; revisão pós-evento simplificada; comparabilidade de observações.
- Estado persistido da revisão e percurso de encerramento sem confundir pendências financeiras com realização do evento.
- Entrada por linguagem natural; documentos depois do fluxo de ações validado.

**Aceite:** preferência não vira dado de consumo; correção é simples; encerramento mantém pendências visíveis; linguagem natural só produz comandos verificáveis.

### Entrega 4 — Validação da meta

Avaliar as mesmas tarefas atuais e novas com usuários e cenários equivalentes. Meta de 70%–80% menos intervenções, com métricas de qualidade mantidas e cobertura publicada. Tempo ativo, correções, conclusão e custo/latência da IA também precisam ser apresentados.

Se o alvo falhar, identificar quais perguntas, informações indisponíveis ou desvios de fluxo mantêm trabalho manual. Corrigir esses pontos antes de acrescentar mais recursos ou declarar a meta atingida.

## 9. Cenários obrigatórios de aceite

- Novo evento com apenas tipo/orçamento; com/sem pessoas e com/sem cardápio.
- Outro evento ativo ao abrir cadastro novo; cancelamento e gravação posterior do rascunho.
- Orçamento ausente, custo parcial, fornecedor incluído e pagamento parcial.
- Público previsto, confirmados, não recusados e público específico por refeição.
- Cardápio como categoria, refeição, serviço transversal e evento de vários dias.
- Receita conhecida, nome ambíguo, item desconhecido e receita própria protegida.
- Cru/seco/pronto; rendimento de referência e medido; unidade incompatível.
- Estoque compartilhado entre refeições sem duplicar desconto.
- Cotação concluída com contratação pendente; cobertura explicitamente confirmada.
- Mudança concorrente, aplicação repetida, falha parcial, histórico antigo e indisponibilidade da IA.
- Primeiro evento sem medições; pós-evento qualitativo e medido.
- Celular com teclado, tela pequena, texto ampliado e correção de uma sugestão errada.

## 10. Fora do escopo inicial

Pesquisa externa de preços, compra/pagamento autônomo, envio automático a fornecedores e alegações de confiança estatística sem dados. A meta de autonomia não depende de ativar esses recursos.

Nenhum deploy está incluído neste plano. Publicação do aplicativo permanece fora da execução até instrução posterior do usuário.

## Referências da análise

- `docs/jornada-evento-codigo-inicio-fim-2026-10-16.md`: caminhos e lacunas reais da jornada; 77 testes existentes aprovados na análise precedente.
- `docs/calculadora-inteligencia-autonomia-2026-10-16.md`: capacidades atuais e oportunidades de autonomia.
- Microsoft Research, diretrizes de interação humano–IA: https://www.microsoft.com/en-us/research/?p=564561
- Google PAIR, feedback e controle: https://pair.withgoogle.com/guidebook-v2/chapter/feedback-controls/

As diretrizes externas orientam correção e supervisão; não demonstram o percentual de redução de trabalho deste produto.


## 11. Acompanhamento de implementação — 17/10/2026

| Entrega | Estado verificável |
| --- | --- |
| 0 — Coerência e linha de base técnica | Implementada; diagnóstico instrumentado não mede integralmente as intervenções humanas. |
| 1 — Proposta inicial | Implementada nos formatos e referências documentados. Receitas próprias podem ser importadas com rendimento e ingredientes explícitos; receitas desconhecidas não recebem ficha inventada. |
| 2 — Executor | Implementado; a transação no servidor também confere inserções nas fontes. Aplicação repetida, estoque, ingredientes e tarefas cobertos por testes autenticados em emuladores. |
| 3 — Personalização e encerramento | Memória privada com adesão explícita e escopo compatível; revisão qualitativa persistida; medições separadas; texto para público, fonte, duração e perfil com aprovação do conjunto. |
| 4 — Meta empírica | Avaliador e protocolo implementados. Sessões observadas com usuários e consumo real continuam pendentes; não há comprovação de 70%–80%. |

O interpretador local de planejamento continua disponível. A entrega complementar de 17/10 ampliou a entrada com IA para compras, quantidades, estoque, preços, cotações, despesas, pagamentos vinculados e receitas, incluindo TXT, PDF e imagens. A interpretação gera propostas delimitadas e validadas, com revisão do conjunto e prevenção de duplicidade; não executa ações financeiras arbitrárias. Busca externa de preços continua adiada pelo usuário. Ver [entrada inteligente](calculadora-entrada-inteligente-2026-10-17.md).

Detalhes e evidências atuais: [entrega 3](calculadora-fase3-personalizacao-2026-10-17.md) e [protocolo de avaliação](calculadora-protocolo-autonomia.md).


### Atualização da entrega 4 — 17/10/2026

Concluída a preparação da coleta assistida: roteiro, ordem alternada das versões, contagens observadas, pausas, retomada, persistência com revisão, preservação de falhas e exportação para o avaliador. As portas de cobertura e qualidade foram reforçadas. O aplicativo normal não recebeu um questionário adicional.

As funções `aplicarPlanoCalculadora`, `revisarRefeicaoCalculadora` e `fecharCotacao` e as regras do Firestore foram publicadas por autorização explícita do usuário nesta etapa. Aplicativo e hosting não foram publicados.

A execução empírica com participantes e as medições reais após o evento continuam pendentes de observação. Não são substituídas pelos testes técnicos. Ver [relatório da entrega 4](calculadora-fase4-piloto-2026-10-17.md).

### Revisão de integração — 17/10/2026

Corrigidos os lançamentos de pagamento para manter compatibilidade com o editor financeiro, os nomes/IDs das despesas da entrada inteligente e a conexão Firebase utilizada pelo executor. A propriedade dos eventos foi protegida contra alteração por outro organizador. Funções e regras atualizadas; aplicativo e hosting não publicados.

Suíte geral: 574 testes aprovados. Entrada/financeiro/autorização: 67 verificações; executor/pós-evento: 54. Após a reconexão do aparelho, o roteiro ampliado foi concluído e aprovado no SM G990E/Android 16: evento, proposta, criação do cardápio, duas refeições compartilhando estoque, entrada inteligente, edição financeira, concorrência e recuperação após novo login. A execução encontrou e permitiu corrigir a normalização das datas entre Flutter e SDK Admin; propostas inalteradas deixaram de ser recusadas indevidamente. As três funções envolvidas foram atualizadas e verificadas como `ACTIVE`, com recusa de chamadas sem autenticação. Ver [relatório de integração](calculadora-jornada-integrada-2026-10-17.md).
