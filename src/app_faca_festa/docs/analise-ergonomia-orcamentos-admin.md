# Orçamentos administrativos — análise de ergonomia e intuitividade

23/10/2026. Avaliação da captura fornecida e do código local da gestão de
orçamentos. Este documento registra o diagnóstico original. A revisão aplicada
posteriormente está descrita em [implementação local](orcamentos-admin-implementacao.md).

## Diagnóstico

A tela apresenta dados em sequência, mas oferece pouca orientação para o trabalho
do administrador. A largura extensa afasta título, valores e status; a tipografia
é pequena; cartões semelhantes dificultam comparação; falta resumo por evento
e ação explícita de consulta. Há também problemas de identificação e significado
dos indicadores que precisam ser resolvidos antes do acabamento visual.

## Prioridade 1: identificação e confiabilidade

### Nome e agrupamento do evento

O datasource de orçamentos lê `evento.nome` e `evento.cidade`. O modelo atual do
evento grava `nome_evento` e `nome_cidade`, com compatibilidade de leitura para
formatos anteriores. Essa diferença explica a possibilidade de identificação
incompleta mesmo com cadastro preenchido.

A tela agrupa por `eventoNome` e usa esse mesmo texto para controlar a expansão.
Eventos com o mesmo nome, ou com a identificação ausente, podem ser reunidos.
Nesse caso, a data, a cidade e o orçamento planejado do primeiro item são usados
para representar todo o grupo. A captura não permite concluir quais registros
foram agrupados indevidamente; o risco é confirmado pela estrutura do código.

Proposta: transportar o ID do evento até a entidade administrativa, agrupar e
controlar expansão por esse ID, e adotar a leitura compatível do cadastro atual.
Dados realmente indisponíveis recebem aviso específico, sem reunir eventos
distintos em um grupo genérico ou inventar informações.

### Significado dos pagamentos

O valor “Pago” desta consulta vem dos registros de gastos do orçamento. Ele não
é uma consulta ao livro de recebimentos confirmados e repasses da plataforma.
O saldo exibido é a diferença entre custo estimado e pagamentos desses gastos.

Proposta: usar “Pagamentos registrados nos gastos” e “Saldo previsto dos itens”,
com ajuda sobre a origem. Se o objetivo for mostrar dinheiro efetivamente recebido
pela plataforma, buscar o fluxo financeiro correspondente, preservando as duas
origens. Uma oportunidade ainda não confirmada não deve parecer dívida contratual.

### Estouro do orçamento

O indicador atual limita o percentual a 100% e usa verde quando atinge esse limite.
Isso pode ocultar um total acima do planejamento.

Proposta: calcular e exibir a razão real, apresentar o valor excedente e diferenciar
“Dentro do planejado”, “Limite atingido” e “Acima do planejado”. A barra pode ter
comprimento limitado; o percentual e o valor excedente não podem ser ocultados.
Sem orçamento planejado positivo, apresentar “Planejamento não definido”.

## Prioridade 2: hierarquia e navegação

### Cabeçalho da página

Título “Orçamentos”, descrição curta e atualização explícita por botão. Busca por
evento, descrição, categoria e cidade; filtros claros de negociação e situação
dos pagamentos. Diferenciar lista vazia, busca sem resultado e falha de consulta.

Resumo identifica a abrangência dos números: quantidade de eventos, estimativas
dos itens, pagamentos registrados e saldo previsto, sempre no conjunto consultado.
Não somar o orçamento planejado uma vez por item: ele pertence ao evento.

### Resumo de cada evento

Nome, data, cidade e quantidade de itens identificados juntos. Ao lado, em desktop,
planejamento do evento e estimativa dos itens com diferença em reais. Em telas
menores, empilhar mantendo essa ordem. Detalhes ficam recolhidos inicialmente,
com ação textual “Ver itens” e estado de expansão acessível por teclado.

### Itens do orçamento

Em desktop, tabela com descrição, categoria quando disponível, valor estimado,
pagamentos registrados, saldo previsto, situação da negociação e ação “Ver orçamento”.
Em celular ou com texto ampliado, cartões com a mesma hierarquia.

Não tratar anotação livre como categoria de serviço. Descrições como “Entrada do
contrato” e “Pagamento corrente” precisam manter seu significado; exibir serviço,
fornecedor e vínculo contratual apenas quando disponíveis e conferidos.

A situação comercial e a financeira têm rótulos distintos. Um item pode estar
“Pendente na negociação” e “Sem saldo previsto” simultaneamente. Pagamento não
confirma contrato, entrega nem elegibilidade de repasse.

Evitar uma barra por item como principal leitura: valores e situação precisam
ficar explícitos. Se houver indicador de pagamento, ele é secundário e tem legenda.

## Prioridade 3: acabamento e ajuda

- Área de conteúdo centralizada, com largura máxima adequada para comparação de valores.
- Conteúdo principal entre 14 e 16 pixels lógicos; metadados secundários legíveis.
- Valores alinhados à direita nas tabelas e sem truncamento de quantias relevantes.
- Moeda brasileira consistente: `R$ 13.386,40`, com centavos e separadores corretos.
- Espaçamentos e estados visuais alinhados às telas financeiras já revisadas.
- Ações identificadas por texto; estados compreensíveis sem depender apenas de cor.
- Calendário e filtros acessíveis por teclado, toque e mouse.

Ajuda recolhível “Como interpretar os valores”:

| Informação | Explicação proposta |
| --- | --- |
| Planejamento do evento | Limite de gastos definido para o evento. É diferente da soma dos itens já cadastrados. |
| Estimativa dos itens | Soma dos valores previstos nos itens apresentados. Pode incluir serviços ainda em negociação. |
| Pagamentos registrados nos gastos | Valores registrados nos detalhes dos gastos. Consulte o financeiro para conferir recebimentos e repasses da plataforma. |
| Saldo previsto dos itens | Diferença entre as estimativas e os pagamentos desses gastos. Não representa automaticamente cobrança contratual ou repasse liberado. |
| Negociação pendente | Situação comercial do item; pode coexistir com pagamentos já registrados. |
| Acima do planejado | A estimativa dos itens ultrapassa o planejamento do evento. Mostra o valor excedente. |

## Sequência de implementação

1. Corrigir identidade do evento, agrupamento por ID e origem/semântica dos valores.
2. Criar resumo por evento e indicadores de planejamento sem mascarar excesso.
3. Reorganizar lista/tabela, filtros e navegação de detalhe.
4. Aplicar ajuda contextual e validar desktop, celular, teclado e texto ampliado.

Validar eventos homônimos, identificação ausente, formatos atuais/legados de
cadastro, zero de planejamento, estouro, pagamento parcial, item sem saldo,
oportunidade, cancelamento, nomes longos, falha e resultado vazio.

## Referências do código

- `lib/presentation/modules/admin/pages/orcamentos_admin_list_screen.dart`
- `lib/presentation/modules/admin/controllers/orcamentos_admin_controller.dart`
- `lib/data/datasources/remote/orcamentos_admin_remote_datasource.dart`
- `lib/domain/entities/orcamento_admin.dart`
- `lib/data/models/evento/evento_model.dart`
