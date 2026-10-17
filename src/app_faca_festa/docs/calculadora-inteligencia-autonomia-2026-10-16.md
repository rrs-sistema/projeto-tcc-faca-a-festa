# Calculadora Inteligente: evolução de inteligência e autonomia

Análise de 16/10/2026, após a revisão dos modais de público e estoque. Base: implementação local atual, serviços de domínio, controllers, interface e função de análise de IA. Não foi uma nova auditoria de produção nem uma medição de uso em evento real. Nenhum código de aplicação, dado do evento ou deploy foi alterado nesta análise. Documentos históricos foram tratados como contexto; as conclusões abaixo foram confrontadas com o código atual.

## Parecer

A aplicação já possui um planejador assistido com cálculo explicável, propostas iniciais, composição de acompanhamentos, disponibilidade, reservas, conciliação financeira e histórico. A principal limitação de inteligência é a distância entre recomendar e resolver: o sistema frequentemente identifica uma pendência e abre um formulário para o organizador decidir como tratá-la.

O investimento prioritário deve produzir um plano operacional integrado e propostas de alteração executáveis. Ampliar textos da IA ou adicionar um chat isolado não resolve essa distância. O motor matemático deve continuar calculando e validando; a IA deve interpretar dados, recuperar referências e preparar ações que ele consiga verificar.

## Estado atual verificado

| Capacidade | Implementação atual | Limitação relevante |
| --- | --- | --- |
| Proposta antes dos ajustes | Gera prévia da refeição selecionada e preserva regras próprias | O reconhecedor contextual tem cinco famílias: arroz, massa, churrasco, frutas e cachorro-quente; outros itens dependem de uma regra existente ou intervenção |
| Raciocínio conjunto | Papéis de alimento, grupos de alternativas e compartilhamento entre arroz e massa | A hipótese automática de compartilhamento está restrita a dois amidos, presença de churrasco e mesmo público; não é um planejador geral de refeições |
| Perguntas | Escolhas contextualizadas de função, tamanho e forma de compra | As perguntas são declaradas no código; não há seleção por impacto simulado na compra, custo ou execução |
| IA generativa | Interpreta os números, resume e sugere ajustes | O prompt proíbe recalcular do zero; a resposta contém recomendações textuais, sem um contrato operacional de alterações a aplicar |
| Próxima ação | Escolhe uma pendência prioritária por uma sequência local de regras | Não prioriza por prazo, dependências, impacto financeiro e quantidade de decisões que uma resposta elimina |
| Estoque | Saldo central, reservas por refeição, compatibilidade de unidade e estado, proteção contra saldo excedido | Cadastro e distribuição continuam manuais; não há proposta integrada de alocação |
| Compras e financeiro | Lista de todas as refeições, compras restantes, serviços, orçamento, pagamentos e distinção entre estimativa parcial e completa | A consolidação financeira já existe; falta transformar divergências e informações dispersas em um plano de resolução com menos etapas |
| Receitas | Recupera referências privadas de simulações anteriores, preservando papel, porção e rendimento | Reutilização começa por ação manual e correspondência normalizada do nome; não há ficha técnica estruturada de ingredientes no contrato principal de regra |
| Cenários | Reserva menor, retirada de variedade e substituição declarada | A alternativa ainda exige escolha e dados do organizador; o sistema não busca e compara automaticamente alternativas compatíveis disponíveis |
| Aprendizado | Mediana de consumo, recência, eventos distintos, verificação de falta e valores atípicos | Depende de medições manuais e contexto idêntico, inclusive proporção etária; dados úteis podem não formar amostra comparável |
| Avaliação de valor | Contadores e tempo da sessão em memória | Ainda não mede redução sustentada de trabalho, repetição de perguntas, correções ou desperdício real entre eventos |
| Custo de IA | Debounce, proteção contra resposta antiga, cache local de cinco minutos e deduplicação de requisições iguais | Uma evolução proativa precisa invalidar por mudança material e reaproveitar resultados, em vez de consultar o modelo em cada edição |

## 1. Plano único de todas as refeições — prioridade imediata

Gerar uma proposta do evento inteiro, preservando o público de cada refeição, horários disponíveis, alimentos, serviços, estoque e valores existentes. O resumo financeiro já considera o evento; esta proposta integrada de decisões é uma capacidade adicional.

A tela deve apresentar o plano e suas exceções. Uma confirmação pode aprovar um conjunto coerente de alterações, em vez de abrir repetidamente a configuração de cada item. A confirmação não declara compra, pagamento ou serviço realizado.

O plano precisa distinguir porções para servir, preparação, compra, reserva de estoque e compromisso financeiro. Cada alteração deve apontar sua origem, o dado anterior, o proposto, a dependência e a possibilidade de desfazer. Alterações incompatíveis com uma compra ou contratação já existente devem ser preservadas e explicadas.

**Aceite:** gerar prévia para todas as refeições cadastradas; conferir totais por público e estado; aplicar apenas o conjunto aprovado sobre a revisão consultada; não duplicar ações em uma nova tentativa; invalidar a proposta quando o evento mudar.

## 2. Reconhecimento de alimentos e memória útil — prioridade imediata

Ampliar o catálogo com identidades, sinônimos, papéis usuais, unidade, estado, forma de preparo e referências versionadas. A IA pode sugerir a identidade de um nome diferente; a regra de cálculo deve vir de uma referência recuperada e validada, não de um número inventado pelo modelo.

Hierarquia proposta: escolha explícita para aquela receita; referência privada já confirmada; referência contextual curada; candidato identificado pela IA; pergunta curta se persistir ambiguidade. Medições históricas só entram como referência de consumo quando cumprem os critérios próprios de comparabilidade.

Memória deve ter escopo. Escolher uma porção para um evento não deve transformá-la silenciosamente em preferência para todos. Uma receita da família pode ser reutilizada como proposta, com identificação e correção simples. Aceitar uma sugestão é preferência, não comprovação de consumo adequado.

**Aceite:** item com sinônimo reconhecido recebe proposta rastreável; item ambíguo não ganha conversão silenciosa; preferência corrigida permanece no escopo certo; ajuste manual existente é preservado.

## 3. Rendimento de referência para o primeiro evento — prioridade imediata

Hoje a conversão de carnes e frutas para compra crua/inteira pode depender de rendimento medido pelo organizador. É uma proteção útil contra conversão arbitrária, mas exige uma informação que um organizador iniciante provavelmente não tem.

Criar referências específicas e revisadas por preparo, corte e apresentação. Separar explicitamente rendimento de referência, informado e medido. Uma referência deve permitir proposta estimada de compra, com fonte e faixa de variação quando disponível. Sem uma referência compatível, continuar com o peso para servir e uma pergunta objetiva.

Não utilizar um rendimento único para toda carne ou fruta. A apresentação deve dizer qual hipótese foi usada e permitir trocá-la. As faixas culinárias não devem ser apresentadas como probabilidade de falta ou confiança estatística.

**Aceite:** uma receita coberta pela base pode gerar estimativa de compra sem medição prévia; o sistema identifica que o rendimento é estimado; compra pronta não recebe perda de preparo; compra já registrada não é reescrita pelo novo padrão.

## 4. Perguntas selecionadas por consequência — prioridade imediata

Simular as respostas plausíveis antes de perguntar. Priorizar a resposta que elimina uma ambiguidade com efeito na compra, atendimento de público, custo ou execução. Diferenças que não mudam a ação operacional podem permanecer como premissa visível e editável.

Exemplo: o tamanho do cachorro-quente pode mudar o número de unidades; a escolha de comprar carne pronta ou crua muda a medida da compra. Já uma pequena diferença de porção que resulta na mesma embalagem pode não justificar interromper o fluxo.

O limite de materialidade precisa ser definido e avaliado com cenários do produto; não aplicar uma porcentagem arbitrária a todos os alimentos. Restrição alimentar declarada e incompatibilidade de unidade não devem ser descartadas por terem baixo impacto monetário.

**Aceite:** não repetir uma resposta válida; explicar a consequência da pergunta; oferecer um padrão apenas quando sustentado pelo contexto; não abrir o formulário técnico inteiro para resolver uma escolha simples.

## 5. Estoque e compras com distribuição proposta — prioridade seguinte

Reconhecer quais lotes podem atender cada destino e preparar uma distribuição que respeite saldo, estado, unidade e quantidade necessária. A ordem pode considerar o horário informado da refeição e, se futuramente cadastrados, validade e conservação. Hoje não há base para alegar que o sistema já considera perecibilidade.

Apresentar uma proposta única de reservas para revisão. Não transformar disponibilidade provável em quantidade existente, não descontar o mesmo lote em duas refeições e não confundir comprado com disponível para servir.

**Aceite:** uma proposta com vários destinos nunca supera o lote; reservas existentes são preservadas ou aparecem no comparativo; itens incompatíveis são excluídos; o saldo e a lista são recalculados sem duplicidade.

## 6. Receitas que se desdobram em ingredientes — alto valor operacional

Adicionar ficha técnica versionada com rendimento, ingredientes e unidades. Cachorro-quente deixaria de terminar em unidades montadas e poderia produzir uma proposta de pão, salsicha e complementos conforme a receita escolhida. A lista consolidaria ingredientes compatíveis usados por mais de uma receita.

A primeira ficha pode ser curada ou extraída de texto/foto e apresentada preenchida. O usuário revisa a receita, sem cadastrar campo por campo. Receitas com variantes precisam de identificação; o nome do prato não comprova ingredientes nem atendimento a restrições.

**Aceite:** escala de receita reproduzível; nenhuma soma entre cru e pronto; ingredientes compartilhados consolidados sem apagar suas destinações; ingrediente não cadastrado na ficha não aparece como certeza.

## 7. Entrada por linguagem natural e comprovantes — reduzir digitação

Permitir instruções como “vamos comprar o cachorro-quente pronto; já temos quatro pacotes de pão”, com interpretação de intenção e uma prévia das alterações. O tamanho do pacote ainda precisa ser recuperado de um produto conhecido ou confirmado quando não estiver disponível.

Ler comprovantes e orçamentos pode preencher nome, quantidade, embalagem, preço, fornecedor e data. A revisão deve agrupar os dados extraídos e destacar dúvidas. Distinguir orçamento, compra e pagamento, validar totais e detectar documento duplicado antes de gravar.

A pesquisa externa de preços permanece fora desta prioridade, conforme combinado. Extração de um preço de documento fornecido pelo usuário é uma capacidade diferente e não exige inventar uma base de preços.

**Aceite:** poucas correções em uma prévia, sem digitação repetida; nenhuma confirmação automática de compra a partir de uma cotação; duplicidade bloqueada; erro de extração não altera silenciosamente estoque ou financeiro.

## 8. Planejamento operacional conectado às tarefas

A aplicação já possui tarefas, mas o fluxo inspecionado da calculadora não transforma automaticamente suas pendências em tarefas estruturadas e vinculadas.

Preparar tarefas a partir do plano: conferir uma entrega, comprar um ingrediente pendente ou preparar uma receita. Usar datas do evento e dependências conhecidas; perguntar por equipamento, capacidade ou responsável somente quando necessário. Não criar prazos técnicos de conservação sem referência apropriada.

As tarefas devem ter origem no item do plano para atualizar ou encerrar a mesma tarefa, evitando duplicação a cada cálculo. Contatar fornecedores, enviar mensagens e efetuar compras continuam sendo ações separadas e autorizadas.

**Aceite:** tarefas rastreáveis e sem duplicidade; conclusão não implica pagamento ou compra; mudança no plano identifica tarefas afetadas; nenhum envio externo implícito.

## 9. Aprendizado com menos esforço, mantendo a validade dos dados

Pré-preencher o pós-evento com o que foi registrado como preparado e perguntar primeiro se faltou ou sobrou. Respostas qualitativas podem orientar a próxima revisão, mas não produzem porção medida. Quantidade planejada também não substitui quantidade preparada.

O contexto atual é tão específico que a exigência de igualdade pode limitar o reaproveitamento. Evoluir para níveis explícitos de comparabilidade: mesma receita e preparo; contextos semelhantes; referência genérica. Antes de automatizar uma adaptação, avaliar retrospectivamente o erro por contexto e a frequência de falta, mantendo separação temporal entre dados usados e evento avaliado.

**Aceite:** nenhum aprendizado quantitativo baseado apenas em aprovação da sugestão; contexto semelhante identificado como tal; medições incompatíveis não são agregadas; correção e exclusão de um registro atualizam sua influência.

## 10. Menos interação exige medição de produto

Medir tempo até uma lista utilizável, campos digitados, perguntas por plano, respostas repetidas, correções, sugestões aplicadas/desfeitas, falhas de extração e custo/latência da IA. Tempo da sessão isolado inclui pausas e não comprova eficiência.

Em eventos com medições, avaliar consumo, falta, sobra e custo real. Em planejamento sem preços, não declarar economia monetária. Comparar o fluxo atual com o novo em tarefas equivalentes, incluindo usuários iniciantes, celular, teclado e conexão instável.

Não definir agora metas como “80% menos interação” ou “95% de confiança”; não há linha de base que sustente esses números.

## Arquitetura proposta

1. Contexto único versionado do evento e suas refeições.
2. Recuperação de dados e referências compatíveis, incluindo memória privada.
3. IA interpreta intenção e propõe ações estruturadas; o motor calcula seus efeitos.
4. Validadores conferem saldo, medida, referências, grupos e compromissos existentes.
5. Prévia mostra mudanças e perguntas materiais; aplicação usa revisão e identificador de operação.
6. Registro das alterações, possibilidade de desfazer quando cabível e avaliação de resultados.

O contrato de ação deve incluir tipo, destinos por ID, valores, origem, dependências, revisão de referência e chave de deduplicação. Uma sugestão textual ou um nome de item não é um comando de gravação confiável.

Rascunhos e recálculos podem ser automáticos. Reservas, substituições e alterações no plano podem ser aprovadas em conjunto. Compra real, pagamento, contratação e comunicação externa não devem ser afirmados ou executados como consequência implícita de um cálculo.

## Sequência recomendada

- Primeira entrega: plano integrado, catálogo/receitas recuperáveis, rendimento de referência e perguntas por consequência. Maior redução do trabalho de configurar e calcular.
- Segunda entrega: ações estruturadas, reservas propostas e ficha técnica por ingredientes. Maior redução do trabalho de executar.
- Terceira entrega: linguagem natural, documentos, tarefas vinculadas e aprendizado progressivo. Maior redução de digitação e manutenção.
- Medição e validação acompanham todas as entregas.

## Evidências no código

- `lib/domain/services/proposta_refeicao_service.dart`: reconhecedor, hipótese de compartilhamento, escolhas e rendimento medido.
- `lib/presentation/modules/calculadora/controllers/calculadora_festa_proposta.dart`: prévia e adoção no cardápio selecionado.
- `lib/domain/services/analise_refeicao_service.dart` e `composicao_refeicao_service.dart`: verificações e divisão por grupos/públicos.
- `functions/src/ia/calculadora/prompt.ts` e `schema.ts`: IA interpretativa e resposta consultiva.
- `lib/presentation/modules/calculadora/sections/calculadora_festa_ia.dart`: recomendações abrem detalhes do item.
- `lib/presentation/modules/calculadora/sections/calculadora_festa_compras.dart`: sequência da próxima pendência.
- `lib/presentation/modules/calculadora/sections/calculadora_festa_planejamento.dart`: reutilização manual de receitas.
- `lib/domain/services/receitas_salvas_calculadora_service.dart`: receitas recuperadas de simulações, sem reaproveitar preço.
- `lib/domain/services/operacao_calculadora_service.dart`, `lista_compras_calculadora_service.dart` e `resumo_compras_service.dart`: base existente de validação e conciliação.
- `lib/domain/services/consumo_observado_service.dart`: contexto exato, proporção etária, mediana e critérios temporais.
- `lib/domain/services/medicao_uso_calculadora.dart`: medição em memória da sessão.
- `lib/data/services/calculadora/calculadora_festa_remote_ai_service.dart`: cache local e requisições pendentes.
- `lib/domain/entities/tarefa.dart`: módulo operacional disponível para integração futura.

## Referências externas de interação com IA

As oportunidades acima são inferências de produto a partir do código. O princípio de supervisão simples, correção eficiente e memória contextual é compatível com as diretrizes de interação humano–IA da Microsoft Research e do Google PAIR; essas referências não comprovam os resultados desta aplicação.

- Microsoft Research: https://www.microsoft.com/en-us/research/?p=564561
- Google PAIR, Feedback + Control: https://pair.withgoogle.com/guidebook-v2/chapter/feedback-controls/
