# Jornada real do evento: do cadastro ao pós-evento

Data: 16/10/2026. Leitura da implementação local, tomando como entrada o rascunho do usuário: tipo de evento, orçamento, convidados opcionais e cardápio opcional. O objetivo desta análise é mapear primeiro o processo existente, antes de propor uma nova inteligência.

Escopo: jornada do organizador e os pontos de contato de convidados, fornecedores, inspiração e calculadora. Não é uma auditoria integral de autenticação, segurança, presentes ou administração. Sem consulta a produção, chamadas pagas de IA, envios de mensagens, alterações funcionais ou deploy.

## Conclusão do mapeamento

A aplicação tem um cadastro seguido de módulos paralelos, com algumas integrações explícitas. Ela não possui hoje uma única sequência que recebe tipo e orçamento e conduz automaticamente até a conclusão operacional do evento.

Convidado cadastrado, quantidade estimada de pessoas e presença confirmada são três informações distintas. Orçamento total, item previsto, cotação, contratação e pagamento também são estados distintos. Parte da dificuldade de integração está nessas diferenças, não apenas na fórmula da calculadora.

## 1. Escolha do tipo e abertura do cadastro

`WelcomeEventScreen` carrega os tipos e permite escolher um. O clique aplica o tema, prepara a sessão/endereço do usuário, seleciona o tipo no controller e abre `showCadastroEventoBottomSheet`.

O formulário tem três passos: A festa; Quando e onde; Convidados. Não cria um documento de rascunho a cada passo: a gravação acontece ao salvar.

Campos e exigências dependem do tipo. Aniversários/infantil exigem tema; outros dados pessoais variam por ocasião. Data é obrigatória; hora é opcional. Para evento de vários dias, o término deve ser posterior ao início. O organizador deve informar endereço: CEP, logradouro, número, bairro, cidade e UF. O cadastro no contexto de convidado possui outra política de endereço.

**Diferença do rascunho conceitual:** não basta selecionar tipo e informar orçamento para criar o evento. O cadastro já exige decisões de ocasião, data e localização.

## 2. Orçamento inicial e público estimado

O campo de entrada se chama “Custo estimado (R$) · opcional” e é salvo em `Evento.custoEstimado`. Campo vazio resulta em valor ausente. Posteriormente, o mesmo valor é usado como limite em telas financeiras e pela calculadora do evento salvo.

Adultos, crianças e bebês são estimativas opcionais. O total é derivado da soma dos três campos. Deixar em branco permite salvar o evento com total zero; não cria pessoas na lista de convidados.

O cadastro não contém criação obrigatória de cardápio.

## 3. Caminho alternativo: calcular antes de salvar

No último passo existe “Assistente de Quantidades” / “Calcular estimativa”. O botão abre a calculadora com tipo e contagens digitadas, permitindo estimativa sem evento.

Nesse modo, o controller usa base manual e busca itens de referência por tipo. Não permite salvar simulação no histórico nem aplicar em um cardápio sem evento salvo. O formulário original continua sendo um processo separado.

Dois pontos de integração merecem correção/validação específica:

- O botão não envia `controller.custoEstimadoInformado` para a tela da calculadora. O limite carregado na preparação vem de `eventoController.eventoAtualEntidade`, quando há evento ativo.
- O botão passa `idEvento: null` para cadastro novo. Na preparação, a tela resolve `widget.idEvento ?? evento?.idEvento ?? ''`. Se existe outro evento ativo, esse fallback pode vincular a estimativa nova ao evento anterior, apesar de `permitirEstimativaSemEvento: true`.

O segundo ponto é um caminho possível identificado estaticamente; ainda precisa de teste de navegação específico com evento ativo e novo cadastro aberto. A opção de permitir estimativa não força, sozinha, isolamento do evento ativo.

Não foi localizada uma etapa explícita que transfira a proposta temporária para o documento do novo evento após seu salvamento. Uma nova preparação da calculadora reinicializa cálculo e regras manuais.

## 4. Gravação e entrada na área do organizador

`salvarEvento()` valida os campos, monta um `Evento`, usa UUID se novo e chama o repository. A gravação remota usa `set(evento.toMap())` no documento `evento/{id}`.

O cadastro define `ativo: true` e `status: planejamento`. Depois ativa o evento e abre a home do organizador. Para edição, retorna à tela anterior.

`EventoController` observa o evento ativo e o coordenador inicializa orçamento, convidados, cardápios, grupos, tarefas, inspirações e serviços. Isso carrega os módulos existentes; não gera automaticamente cardápio, convidados ou um plano completo.

**Atenção na edição:** o mesmo salvamento reconstrói o evento com status planejamento, em vez de preservar o status carregado. Como a persistência é um `set` completo, esse caminho merece regressão para preservação do ciclo de vida e dos campos não editados. Não alteramos esse comportamento nesta análise.

## 5. Módulos que podem ser usados em qualquer ordem

### Convidados

O organizador cadastra pessoas e grupos, gera links, envia convites e acompanha pendente/confirmado/recusado. As ações de convite são explícitas. O convidado pode responder à presença.

A calculadora carrega sua própria consulta de convidados na preparação ou atualização. Sem lista, usa a estimativa do cadastro; com lista, aplica a base selecionada. Não foi localizada uma assinatura contínua da lista de convidados dentro do controller da calculadora, equivalente às assinaturas de estoque e orçamento: a ação Atualizar planejamento recarrega a lista.

A base “todos” soma os registros consultados; somente a base “confirmados” filtra status. A consulta remota não exclui recusados. Portanto “todos” não significa “não recusados”. Uma política de público como a escolhida para o evento real precisa de representação própria ou ajuste explícito.

### Cardápios

Criar cardápio e seus itens é opcional e separado do cadastro do evento. O usuário define título, ícone e cor; depois cadastra alimentos/bebidas/outros e público.

Há uma ambiguidade de conceito: a tela sugere “Comidas, Bebidas” como exemplos de cardápio/categoria, enquanto a calculadora passou a tratar um cardápio como refeição/destino, como Almoço ou Jantar. O modelo Cardapio não possui horário, data ou uma identidade estruturada de refeição. A operação da calculadora guarda configurações adicionais por ID.

Logo, não se pode pressupor que cada cardápio existente corresponda a uma refeição completa. Uma categoria “Bebidas” pode atravessar refeições; uma análise que exige principal/bebida precisa conhecer esse escopo.

### Orçamento e pagamentos

O usuário cria categorias/itens previstos e registra lançamentos/pagamentos. A criação manual de categoria verifica o limite total e a soma já prevista. Sem custo estimado no evento, esse caminho apresenta bloqueio por falta de orçamento definido.

Isso cria uma dependência posterior: o orçamento é opcional no cadastro, mas necessário para operações financeiras específicas. O fluxo deve conduzir o usuário a completar esse dado quando necessário.

Pagamento é registrado separadamente e tem validação de limites. A home apresenta indicadores; ela não transforma um item planejado em compra física nem quita um fornecedor automaticamente.

### Fornecedores e cotações

Existem solicitação direta de orçamento/reserva e cotação para fornecedores, com respostas e escolha do vencedor.

`confirmarFornecedorEscolhido` chama a function `fecharCotacao`. O backend conclui a cotação e marca o fornecedor vencedor, cria um orçamento e um gasto inicial com pago zero.

**Incoerência identificada no código:** a interface mostra “Negócio fechado”, mas a function grava o orçamento com `status: em_negociacao` e `orcamento_fechado: false`. O gasto recebe o texto “Serviço contratado”. O modelo considera fechado somente `StatusOrcamento.fechado`.

Não há evidência aqui para tratar esse orçamento automaticamente como contratação confirmada na calculadora. É necessário decidir a semântica de escolher vencedor versus efetivamente contratar e alinhar textos, estados e cobertura.

### Tarefas, inspirações e outros recursos

Tarefas possuem responsável, data e status; podem ser criadas e concluídas. Concluir todas não altera automaticamente o status do evento no caminho examinado.

Inspirações podem ser salvas e gerar checklist e propostas de orçamento por uma ação explícita. Essa integração já existe e deve ser preservada. Sua existência não significa que todas as tarefas da calculadora já são geradas automaticamente ou que todo orçamento de inspiração já esteja conciliado ao financeiro principal: escopos de persistência precisam ser conferidos em uma implementação integrada.

Presentes, mesas, referências e contagem regressiva são caminhos auxiliares disponíveis. Não são pré-requisitos para o cálculo e não foram auditados integralmente neste trabalho.

## 6. Caminhos da Calculadora Inteligente

A home permite abrir a calculadora do evento ativo. Ela prepara o contexto, carrega referências por tipo, convidados, simulações e orçamento, observa a operação de público/estoque e acompanha os cardápios.

A interface tem Pessoas; A festa; Sugestões. Pode operar com base manual, todos os convidados ou confirmados. O público de uma refeição pode substituir a base geral.

### Matriz de entradas

| Situação após criar evento | Comportamento atual |
| --- | --- |
| Sem lista, com estimativa de pessoas, sem cardápio | Usa contagens do cadastro e referências disponíveis por tipo; precisa de cardápio de destino para aplicar |
| Sem lista e sem estimativa de pessoas | O motor não produz itens enquanto o total for zero; não deduz capacidade pelo orçamento |
| Com lista, sem cardápio | Usa a base de convidados escolhida e regras por tipo; cardápio não é pré-requisito para estimar |
| Com cardápio e com pessoas | Pode revisar os itens, gerar proposta contextual, preservar regras e considerar estoques, serviços e gastos |
| Com cardápio, sem pessoas | Ter itens não resolve a falta de público; o cálculo continua sem resultado quantitativo |
| Com pessoas, sem orçamento | Quantidades podem ser calculadas; não há verificação de cabimento em limite ausente |
| Só tipo e orçamento | Não há mecanismo inverso atual que proponha público e evento viável a partir do valor |

A proposta contextual trabalha sobre itens existentes do cardápio selecionado. O modo do zero utiliza referências por tipo; isso não equivale a um planejador completo de cardápio orientado pelo orçamento.

## 7. As diferentes formas de concluir um cálculo

**Salvar:** grava simulação e snapshot no histórico, com itens e análise disponível. Exige evento salvo e resultado. Não confirma compra, pagamento nem encerramento do evento.

**Revisar e aplicar:** exige cardápio de destino, mostra revisão dos itens e aplica as sugestões selecionadas. A transação verifica o evento do cardápio e evita sobrescrever identidade incompatível. Atualiza a quantidade sugerida; itens novos continuam com quantidade final zero. Não significa que o usuário comprou ou confirmou a quantidade final.

**Aprovar e converter em orçamento:** exige uma simulação aprovada, cria/vincula itens do orçamento e marca conversão. É outro caminho, separado de aplicar ao cardápio; não é pagamento.

**Registrar disponibilidade e reservar estoque:** quantidades compradas e reservas são informadas explicitamente. A lista usa essas quantidades e a cobertura dos serviços para calcular o que falta. O orçamento não substitui uma quantidade física registrada.

**Lista de compras:** pode abranger a refeição ou o evento. Se faltam regras, disponibilidade, preços ou cobertura, o resumo permanece parcial. Copiar a lista não registra compra.

## 8. Realização e pós-evento

Há registro de consumo, preparo, sobra, desperdício e falta, vinculado ao evento e contexto. O controller salva a simulação e a observação; comparações futuras exigem critérios de compatibilidade.

A calculadora identifica “depois da festa” pelo status finalizado ou pelo dia de término já passado. O botão “Concluir revisão” fecha o diálogo; não grava uma revisão concluída global nem finaliza o evento.

O domínio enumera rascunho, planejamento, confirmado, em andamento, finalizado, adiado e cancelado. Na busca pelos fluxos de UI/controllers e backend, não foi localizada uma jornada explícita do organizador para percorrer esses estados e realizar um encerramento integrado. Ter o enum não comprova que o processo de encerramento foi implementado.

Também não foi localizada uma etapa única que confira tarefas, entregas, compras, pagamentos e medições e então registre o encerramento. As conclusões são individuais por módulo.

## Pontos a decidir antes de redesenhar a inteligência

1. Se custo é opcional na criação, qual é a orientação quando uma operação financeira o exigir?
2. Evento em ideia pode existir sem data/endereço definidos, ou só existe como cadastro já operacional?
3. Como uma estimativa temporária vira plano do evento salvo, sem perder escolhas nem herdar outro evento?
4. A base de público será prevista, todos cadastrados, não recusados, confirmados ou manual? Qual mantém atualização e qual permanece congelada?
5. Cardápio representa refeição, categoria ou ambos com escopo explícito?
6. Escolher fornecedor na cotação representa seleção para negociação ou contratação concluída?
7. O que significa finalizar planejamento, realizar o evento e concluir pós-evento? Quais registros caracterizam cada etapa?

Estas decisões vêm antes de acrescentar novas automações. Sem elas, o sistema pode automatizar movimentos tecnicamente válidos que representam decisões diferentes para o usuário.

## Verificação executada

77 testes existentes aprovados em dez arquivos: cadastro de evento, controller de evento, coordenador de sessão, cardápios, convidados, orçamento, gastos, cotação, integridade da calculadora e jornada móvel. Log: `.dart_tool/analise-fluxo-evento-20261016.log`.

A execução usa substitutos de dependências; não validou serviços publicados ou um evento real. Os riscos de fallback no cadastro novo, preservação do status na edição, cotação versus contratação e escopo categoria/refeição foram identificados pela leitura; não foram reproduzidos por novos testes específicos nesta análise. Testes aprovados não eliminam essas lacunas de cobertura.

## Arquivos de referência

- `lib/presentation/modules/eventos/pages/welcome_event_screen.dart`
- `lib/presentation/modules/usuario/pages/cadastro_evento_bottom_sheet.dart`
- `lib/presentation/modules/eventos/controllers/evento_cadastro_controller.dart`
- `lib/presentation/modules/eventos/controllers/evento_cadastro_tipos.dart`
- `lib/presentation/modules/eventos/controllers/evento_cadastro_persistencia.dart`
- `lib/presentation/modules/eventos/controllers/evento_cadastro_endereco.dart`
- `lib/data/datasources/remote/evento_remote_ds.dart`
- `lib/presentation/modules/eventos/controllers/evento_controller.dart`
- `lib/presentation/coordinators/evento_session_coordinator.dart`
- `lib/presentation/modules/eventos/pages/home_event_screen.dart`
- `lib/presentation/modules/convidado/controllers/convidado_controller.dart`
- `lib/presentation/modules/convidado/controllers/cardapio_controller.dart`
- `lib/presentation/modules/convidado/components/cadastro_cardapio_bottom_sheet.dart`
- `lib/presentation/modules/orcamento/controllers/orcamento_controller.dart`
- `lib/presentation/modules/orcamento/controllers/orcamento_gasto_controller.dart`
- `lib/presentation/modules/cotacao/controllers/cotacao_controller.dart`
- `functions/src/functions/cotacao/fecharCotacao.ts`
- `lib/presentation/modules/inspiracao/controllers/inspiracao_evento_planejamento.dart`
- `lib/presentation/modules/checklist/controllers/tarefa_controller.dart`
- `lib/presentation/modules/calculadora/pages/calculadora_festa_screen.dart`
- `lib/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart`
- `lib/presentation/modules/calculadora/controllers/calculadora_festa_historico.dart`
- `lib/presentation/modules/calculadora/controllers/calculadora_festa_proposta.dart`
- `lib/presentation/modules/calculadora/sections/calculadora_festa_compras.dart`
- `lib/presentation/modules/calculadora/sections/calculadora_festa_decisoes.dart`
- `lib/data/datasources/remote/calculadora_festa_remote_datasource.dart`
- `lib/domain/services/calculadora_festa_service.dart`
- `lib/domain/entities/evento.dart`
- `lib/domain/entities/cardapio.dart`
- `lib/domain/entities/orcamento.dart`
