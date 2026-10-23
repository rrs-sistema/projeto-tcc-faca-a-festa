# Entrega 2 — compras, ingredientes, estoque e tarefas

Atualização: a entrega 3 substituiu a transação do cliente por consultas e gravações na mesma transação do servidor, e acrescentou validação autenticada em emuladores. Veja [o relatório atualizado](calculadora-fase3-personalizacao-2026-10-17.md). Os resultados abaixo registram a validação original da entrega 2.

17/10/2026. Implementação local; aplicativo e regras não publicados. Nenhum dado do evento real foi alterado.

## Caminho operacional

No passo de sugestões, “Organizar compras e tarefas” abre a revisão do evento salvo. A consulta reúne cardápios, itens, estoque, serviços, tarefas e participantes conhecidos. O público é refeito segundo a fonte escolhida: previstos, confirmados, não recusados, todos ou manual. Refeições com público próprio continuam usando sua configuração. O total legado do evento mantém a compatibilidade anterior quando não há separação por idade.

A revisão propõe quantidades sugeridas, reservas de lotes compatíveis e uma lista consolidada de compra. Quantidades finais já informadas têm prioridade na demanda de compra/preparo; a referência continua sendo apenas a sugestão. Ao mudar o público, aparecem as diferenças em relação à aplicação anterior. Serviços contratados e integralmente vinculados ao item suspendem a compra/reserva adicional e deixam a conferência de entrega visível. Valores financeiros não são alterados.

A ausência de disponibilidade não significa compra zero. Uma declaração agrupada permite informar que, para os itens ainda sem registro, nada foi comprado. Somente nesses itens é gravada disponibilidade zerada. Compras existentes, estoque local antigo e registros com medida incompatível não são sobrescritos. O estoque local antigo continua exigindo conferência para impedir desconto duplicado.

A lista pode ser copiada antes da aplicação. “Aplicar conjunto” efetiva exclusivamente as ações mostradas; não compra, paga, contrata, confirma disponibilidade física ou conclui tarefas.

## Ingredientes e fichas

No ajuste da regra, “Informar ingredientes da receita” registra uma ficha estruturada: nome do prato, rendimento na medida de compra explicitada e até 20 ingredientes, cada um com nome, quantidade, unidade e estado. É um cadastro opcional e reaproveitável pela persistência das regras/receitas. O rendimento pertence à receita informada; não é uma referência culinária fabricada.

O motor escala os ingredientes pela demanda de saída da receita, descontando o prato já comprado ou reservado antes do desdobramento. Não soma simultaneamente o prato inteiro e seus ingredientes. Materiais são consolidados somente por nome normalizado, unidade, estado e público compatíveis. Não há conversão automática entre litros e kg, entre cru e pronto, nem identificação aproximada de ingredientes pelo nome. Ficha incompatível fica pendente. Sem ficha, o material permanece como item inteiro a comprar.

A lista de compras anterior reconhece a ficha e encaminha à lista de ingredientes; não volta a apresentar a compra integral do mesmo prato. Registrar ingredientes comprados como lote central é distinto de declarar o prato já comprado. O aplicativo ainda depende dessa distinção declarada para não contar duas vezes o mesmo alimento físico.

## Estoque

A distribuição é determinística por destino e lote. Reservas manuais são preservadas. Reservas identificadas como originadas pelo executor podem ser redistribuídas após aprovação, incluindo liberação de excesso quando a demanda diminui. O saldo de destinos pendentes não é liberado silenciosamente. Reservas de preparos iniciados, concluídos ou com tarefa editada são preservadas mesmo quando o público diminui: uma reserva anterior pode já ter sido utilizada fisicamente. O saldo físico precisa ser conferido antes de liberá-la. A conclusão da tarefa não fabrica um movimento de consumo ou um lote de prato pronto. Os limites dos lotes são verificados antes de aplicar.

Ingredientes usam um vínculo próprio com refeição, item e ingrediente. Isso evita descontar a reserva do ingrediente novamente como reserva do prato. A liberação manual no estoque reconhece esse vínculo. Necessidades alimentares específicas impedem destinação automática de lote genérico; não se presume adequação de ingredientes, preparo ou contato cruzado.

O algoritmo privilegia a ordem estável dos destinos; não é um otimizador global de preferências, custos ou validade dos lotes. Embalagens são arredondadas após consolidação compatível. Não há preço inventado para declarar economia.

## Tarefas

São propostas tarefas de compra por material consolidado e de preparo por receita/destino. As identidades são estáveis. Novas tarefas ficam com o organizador, seguindo a exigência atual do módulo de tarefas por responsável válido; podem ser delegadas depois. Não são atribuídos prazos fictícios.

Tarefas automáticas ainda pendentes e sem edição do texto podem ser atualizadas, mantendo responsável, prazo e cadastro. Tarefas iniciadas, concluídas, manuais ou com texto editado são preservadas e sinalizadas. Uma tarefa automática pendente cuja demanda desaparece passa a pedir revisão, sem ser marcada como concluída. Um planejamento incompleto não declara demandas antigas encerradas.

## Executor e concorrência

O comando e o registro de aplicação usam versão 1. A aplicação grava sugestões, disponibilidades explicitamente declaradas, operação do estoque, regras aprovadas, lista, tarefas e recibo na mesma transação. Não há uma sequência de escritas parcialmente concluídas para o usuário recuperar. O mesmo identificador de pedido e a mesma assinatura retornam o resultado anterior; reutilizá-lo para outra revisão é rejeitado. Uma nova revisão mantém as identidades das tarefas e preserva os fatos já registrados.

A transação confere organizador, revisão operacional e conteúdo dos documentos capturados. Mudanças conhecidas em item, lote, participante, serviço ou tarefa impedem aplicar a revisão antiga. A interface também verifica seu contexto local. Uma troca de evento, parâmetros ou revisão mais nova durante a gravação não deve restaurar dados antigos sobre o editor atual.

Limitação identificada na entrega 2 e corrigida na entrega 3: a transação anterior no cliente só conferia documentos capturados. A implementação atual consulta os conjuntos no servidor dentro da própria transação, detectando inserções, remoções e alterações antes de gravar a revisão. Os cadastros do evento continuam operacionais; não há bloqueio global da interface.

A consulta usa o servidor e falha de forma explícita se estiver incompleta/offline. Limites atuais: 20 cardápios consultados, 60 itens por cardápio, 120 convidados, 40 orçamentos, 40 registros financeiros por orçamento, 100 tarefas e 240 documentos capturados no total; aplicação limitada a 100 alterações e 60 regras. O excesso bloqueia a revisão conjunta, sem truncar dados silenciosamente.

## Infraestrutura e alcance

As regras locais aceitam o snapshot operacional de execução, recibos privados de criação imutável e leitura de tarefa automática ainda inexistente para a transação. Tarefas existentes mantêm as permissões atuais. Os recibos não ficam disponíveis aos convidados ou a outro organizador.

Essas regras precisam acompanhar a futura disponibilização do aplicativo. Não houve deploy, push, commit adicional, uso da conta real ou gravação no evento real nesta entrega.

Não há alegação de 70%–80% de redução de trabalho comprovada. Fichas ausentes, medidas incompatíveis, compras não registradas e necessidades alimentares continuam exigindo informação real. Personalização, entrada por linguagem natural, encerramento e a medição da meta continuam nas entregas posteriores.


## Validação

- Suíte Flutter completa: **535 testes aprovados**, em `.dart_tool/fase2-suite-final.log`.
- Vinte e quatro testes novos de domínio, executor e interface. Após o ajuste final de rótulos para nomes dos cardápios/lotes, esses 24 testes passaram novamente em `.dart_tool/fase2-aceite-final.log`.
- Análise estática dos serviços, persistência e módulo da calculadora: sem problemas, em `.dart_tool/fase2-analysis-final.log`.
- Regras da calculadora e tarefas aprovadas no emulador Firestore com Java 21, em `.dart_tool/fase2-rules.log`. A validação inclui recibo imutável, criação conjunta e bloqueio de acessos indevidos.
- Testes de transação executam o callback real do datasource com substituto de armazenamento: falha antes do commit, nova tentativa, conflito, preservação dos fatos e troca de organizador. Não equivalem a uma sessão autenticada de produção.
- Revisão em 320 × 568 com texto ampliado e ficha com teclado aberto, sem overflow. Captura inspecionada em `.dart_tool/qa-calculadora/plano-execucao.png`.
- `git diff --check` sem erros. Não houve publicação nem teste com dados reais de produção.
