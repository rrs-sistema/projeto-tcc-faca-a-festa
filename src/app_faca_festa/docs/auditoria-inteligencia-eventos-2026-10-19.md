# Auditoria de dados e inteligência de eventos

Data: 19/10/2026. Análise do código local, sem consulta ao Firestore de produção, sem confirmar quais funções estão publicadas e sem alterar regras de negócio nesta auditoria. A busca percorreu apresentação, serviços de domínio e serviços de backend; a leitura aprofundada concentrou-se na calculadora e nos fluxos relacionados. Não equivale a certificar todas as telas ou validar tecnicamente as fontes alimentares citadas no código.

## Conclusão

O aplicativo combina dados persistidos, cálculos determinísticos, referências editoriais locais, preferências do organizador, consumo observado e chamadas de IA remota. Não é correto dizer que toda a inteligência é estática, nem que o planejamento atual serve automaticamente para qualquer evento.

`PlanoEventoService` é principalmente uma prévia de alimentação por cardápio. Não representa um plano completo de evento com cronograma, equipe, fornecedores, infraestrutura, acessibilidade e execução. O cálculo de itens existentes é reutilizável entre eventos; a seleção automática inicial é limitada.

## Achados prioritários

| Prioridade | Evidência no código | Consequência |
|---|---|---|
| Alta | `plano_evento_service.dart:73`: nome contendo “churrasco” seleciona churrasco; todos os outros tipos caem em lanche. | Sem cardápio e com consulta completa, casamento, reunião empresarial ou retiro recebem a mesma sugestão inicial de cachorro-quente e frutas, salvo formato informado explicitamente. Isso não demonstra adequação ao evento. |
| Alta | `plano_evento_service.dart:77`: quatro modelos com alimentos definidos no código. | A sugestão inicial não escolhe menu por horário, duração de cada serviço, orçamento alimentar, preferências ou restrições. Há avisos de revisão e ausência de bebidas; o modelo não é uma recomendação completa. |
| Alta | `proposta_refeicao_service.dart:34`: reconhecimento por lista fechada de nomes e aliases. | Receitas e nomes fora da lista dependem de regra existente ou entram como pendência. Não há reconhecimento semântico geral nesse serviço. |
| Alta | `proposta_refeicao_service.dart:200–306`: porções, faixas e pesos etários definidos localmente. | São parâmetros de referência e hipóteses do produto, não consumo medido do evento. Links de fonte não significam consulta ou atualização automática. |
| Alta | `painel_cotacao_page.dart:126` e `fornecedor_localizacao_screen.dart:218`: `modoDemo: true`. No backend, `fornecedorRecomendacaoService.ts`, `buscarFornecedoresCandidatos`, esse modo ignora a verificação de aptidão para operar. | Não inventa fornecedores: busca registros reais e ativos. Porém pode recomendar registros que seriam excluídos pelo filtro normal de aptidão. |
| Alta | `home_event_screen.dart:1669/1748` usa `totalCustoEstimado` sob o rótulo “Gasto”; `orcamento_controller.dart:125` soma `custoEstimado`. | Dado real, mas com significado apresentado incorretamente. Estimado, contratado e efetivamente pago precisam ser separados. |
| Média | `proposta_refeicao_service.dart:487`: data `2026-10-16` gravada como verificação de referência. | Data editorial estática, não verificação recente a cada execução. Deve acompanhar a versão da fonte utilizada. |
| Média | `capacidade_alimentos_service.dart:96`: públicos específicos impedem extrapolação de um cenário único de adultos. | Restrição explícita do algoritmo. Pode-se aplicar a verba, mas não afirmar capacidade desse público misto. Não resolver removendo a proteção. |
| Média | `consumo_observado_service.dart`: mínimo de três eventos, janela de 365 dias e contexto estrito. | Existe calibração com histórico, mas pouca amostra e correspondência rigorosa podem limitar o uso. Esses limiares são políticas locais; três eventos não comprovam confiabilidade universal. |
| Média | `perfil_festa.dart`: multiplicadores e reservas fixos; regras propostas desativam ajuste por perfil e duração. | Duração do evento e perfil não implicam ajuste uniforme de todas as receitas. A interface deve explicar o que realmente mudou. |
| Baixa | `fornecedor_localizacao_controller.dart`: raio inicial de 10 km e atribuição de 25 km na inicialização; scores usam corte 75 em vários pontos. | Políticas espalhadas dificultam manutenção e consistência. Não são métricas falsas, mas merecem centralização. |

## Os dois serviços atendem qualquer tipo de evento?

### PlanoEventoService

O tipo do evento influencia a seleção inicial somente pelo teste textual de churrasco. O orçamento é transportado e aparecem pendências, mas ele não otimiza a escolha dos alimentos. Cardápios cadastrados são filtrados por evento e seus públicos e destinos são respeitados.

Casamento com jantar, aniversário infantil com lanche, congresso com vários intervalos e retiro com várias refeições podem usar a infraestrutura de cardápios, desde que sejam configurados. Não recebem automaticamente um planejamento especializado apenas por selecionar o tipo de evento.

### PropostaRefeicaoService

A entrada não recebe tipo de evento, horário ou duração do serviço como contexto estruturado. Recebe itens, regras, respostas, opção de composição e destinos de público. O serviço pode perguntar sobre situações específicas, como salgados em festa ou serviço empresarial, mas isso não constitui adaptação geral ao evento.

Há decisões de composição explícitas: dividir variedades, compartilhar arroz e massa quando há carne, escolher tamanho e papel do cachorro-quente e distinguir servir de comprar/preparar. São heurísticas reproduzíveis, com cobertura limitada. A divisão não é consumo comprovado.

Pontos positivos que devem ser preservados: regras revisadas e receitas próprias são protegidas; preços só são reaproveitados sob condições de unidade/estado compatíveis; ausência de preço gera pendência; compra crua não é confundida automaticamente com peso pronto; decisões ficam identificadas por evento, cardápio e item.

## O que é inteligência hoje

1. **Cálculo e validação:** fórmulas locais, conversões, composição e controles de consistência. Devem continuar determinísticos e testáveis.
2. **Referências e sugestões:** tabelas locais de alimentos, porções, rendimentos, aliases e modelos. Precisam de governança e contexto.
3. **Linguagem restrita:** `ComandoTextoCalculadoraService` usa expressões regulares para um conjunto finito de comandos. É útil, mas não interpretação livre.
4. **IA remota:** bootstrap registra `CalculadoraFestaRemoteAIService`; backend de análise chama modelo generativo e identifica fallback local quando ocorre falha. A existência desse caminho no código não comprova disponibilidade em produção nem transforma o motor de propostas em IA generativa.
5. **Memória:** receitas/preferências explicitamente guardadas são recuperadas por contexto. Preferência não significa medição de consumo.
6. **Calibração:** `ConsumoObservadoService` compara registros, calcula mediana e verifica amostras, faltas e valores atípicos. A adoção passa por ação do usuário. Existe aprendizado assistido por dados, não treinamento autônomo universal.

## Inteligência de negócio proposta

### 1. Entender o serviço antes de sugerir alimentos

Tipo do evento é um ponto de partida. O briefing deve registrar objetivo, horários, quantidade de dias, refeições/intervalos, formato de atendimento, público por serviço, preferências, restrições, infraestrutura, equipe, verba alimentar e itens já contratados/comprados. Perguntar somente o que falta e o que pode mudar a decisão.

Exemplos de contextos diferentes: congresso com dois intervalos por dia; retiro com almoço e jantar para públicos distintos; aniversário com lanche e bolo; casamento com recepção e jantar. Não presumir equivalência entre eles pelo número de convidados.

### 2. Catálogo de políticas e referências versionadas

Proposta de estrutura, ainda não existente: `politicas_planejamento`, `formatos_servico`, `referencias_consumo`, `receitas_referencia` e `avaliacoes_planejamento`.

Cada referência precisa de identificador, versão, origem, revisão editorial, vigência, unidade, estado de compra/serviço, contexto de aplicação, limites conhecidos, faixa de consumo, condições de incompatibilidade e responsável pela aprovação. Publicação exige validação de esquema e compatibilidade com o motor, com versão local conhecida para contingência.

Mover números para o Firestore, sozinho, não cria inteligência. O motor precisa selecionar a referência compatível, justificar a escolha e recusar aplicação fora das condições. Constantes técnicas, fórmulas e invariantes não precisam virar configurações arbitrárias.

### 3. Motor híbrido com precedência explícita

Priorizar regra revisada do item/evento; oferecer consumo observado comparável com qualidade suficiente; recuperar receita privada compatível; consultar referência aprovada e contextual; quando não houver cobertura, perguntar ou apresentar pendência.

IA pode interpretar o briefing, identificar candidatos no catálogo e explicar alternativas. O motor deve validar unidades, rendimentos, públicos, orçamento e efeitos antes de calcular ou persistir. IA não deve inventar preço, rendimento medido, disponibilidade de fornecedor ou adequação alimentar.

Cada recomendação deve informar origem, premissas, faixa estimada, dados ausentes e quais escolhas a modificam. Evitar porcentagem de confiança sem calibração real.

### 4. Planejamento como conjunto de decisões

Separar plano alimentar, financeiro, cronograma, fornecedores, equipe e infraestrutura. Consolidar relações entre eles: um serviço interfere em horários, contratação, preparo e verba. O organizador revisa alternativas e confirma ações externas.

Capacidade para públicos mistos exige modelo próprio de composição, preservando restrições, grupos e serviços. Não somar equivalentes e chamar o resultado de capacidade física ou suficiência do cardápio.

### 5. Fechar o ciclo após o evento

Registrar público efetivo por serviço, quantidade preparada, servida, reaproveitável, descartada, sobra e falta, com unidade/estado e origem. Distinguir quantidade comprada de consumo. Comparar previsto e observado apenas entre contextos compatíveis; medir erro, cobertura e frequência de falta antes de propor adoção de outra referência.

Manter histórico privado e exigir avaliação de privacidade e autorização antes de qualquer agregação entre organizadores.

## Ordem de execução recomendada

1. Corrigir modo de demonstração nos fluxos normais e o significado de “Gasto”.
2. Retirar a decisão automática “todos os demais eventos = lanche”; solicitar formato quando não houver contexto suficiente.
3. Introduzir contrato de contexto por serviço e catálogo versionado, migrando uma família de referências de cada vez, preservando receitas já salvas.
4. Integrar escolha contextual e explicação da origem; testar casos sem cobertura e eventos com múltiplos públicos/refeições.
5. Expandir a calibração observada e medir se as recomendações melhoram, antes de ampliar autonomia.

Critérios mínimos: alterar referência aprovada sem novo APK; não sugerir formato incompatível silenciosamente; não substituir receita revisada; impedir preço estimado tratado como pago; restaurar decisões por evento; não executar gravação externa a partir de saída não validada de IA; demonstrar comportamento em aniversário infantil, casamento, congresso, retiro, churrasco e serviço personalizado sem referência.

## Limites desta conclusão

Nenhuma tabela alimentar foi endossada como recomendação profissional. Não houve validação das fontes externas nem coleta de consumo real. Não foram verificados dados de produção, versão instalada, configuração de segredos ou publicação das funções. Testes automatizados avaliam o comportamento implementado, não comprovam que as premissas são adequadas para qualquer evento.
