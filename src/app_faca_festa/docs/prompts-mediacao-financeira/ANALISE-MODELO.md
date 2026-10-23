# Evolução do Faça a Festa para contratação e pagamento intermediados

## Direção de produto

O organizador monta a festa e contrata serviços; o pagamento é feito com a equipe/plataforma Faça a Festa. A administração precisa acompanhar a contratação e os movimentos até o fornecedor, além de mediar divergências de execução e pagamento.

Isso exige evolução de estrutura, além do acabamento premium. O painel atual apresenta eventos e valores, mas não entrega um dossiê operacional das partes, serviços, recebimentos e repasses. A proposta deste documento não implementa nem ativa cobrança ou transferência.

## O que a leitura do projeto indica

- Orcamento já prevê id/nome de fornecedor e solicitante, além do vínculo com evento e serviço.
- ContratoFinanceiro representa valor e situação comercial, mas a versão examinada não concentra as identidades completas de contratante, prestador, pagador e execução.
- A callable consultarDashboardFinanceiroAdmin constrói fatos comerciais com IDs de evento, orçamento, necessidade, fornecedor e serviço, agregando-os por evento. Essa resposta não garante nomes de cliente/fornecedor no detalhe.
- Na página administrativa examinada, o detalhe expande contagens, valor pago e ID, sem constituir um histórico de atendimento/mediação.
- LiquidacaoFinanceira tem perspectiva do evento e distingue declaração manual de confirmação externa. Isso não comprova por si só recebimento pela plataforma ou repasse ao fornecedor.
- A consulta administrativa observada usa limites e conciliação por amostra. Deve explicitar completude/paginação; “sincronizado” não significa automaticamente total completo.

Essas observações são leitura estática do estado local, não homologação do aplicativo. Confirme o código no momento de executar cada prompt.

## Modelo proposto

Organizador/contratante → evento/pedido → contratações por fornecedor → linhas de serviço.

Pagamento do cliente → recebimento pela plataforma → alocação por contrato → comissão/destinações → repasse ao beneficiário.

Execução/aceite e mediação acompanham a contratação em trilhas separadas. Pagar não comprova entrega; entrega informada não comprova aceite; autorizar repasse não comprova transferência.

| Estrutura | O que precisa responder |
|---|---|
| Evento/pedido | Qual festa, data, proprietário/organizador e conjunto de contratações |
| Contratação | Quem contrata, qual empresa fornece, escopo, valor e termos aceitos |
| Partes | Organizador, contratante, pagador, empresa prestadora, beneficiário e operador do APP, quando distintos |
| Serviço | O que foi contratado, quantidade/unidade, condições e execução |
| Recebimento | Quem pagou, para a plataforma, quanto, quando, por qual referência e confirmação |
| Alocação | A quais contratos se destina cada parte do recebimento |
| Comissão | Qual regra/versão é aplicável e como é liquidada, sem cobrança duplicada |
| Repasse | Quem recebe, contrato, origem do recurso, elegibilidade, autorização e confirmação |
| Mediação | Motivo, partes, responsável, evidências, manifestações, decisão e efeitos vinculados |

A plataforma como operadora financeira/comercial não se torna automaticamente prestadora de todos os serviços ou parte contratual universal. O papel jurídico/comercial precisa ser definido nas condições aprovadas; o software deve representar a decisão explicitamente.

## Identificação que o administrador precisa ver

A lista por contratação deve mostrar evento, cliente/contratante, fornecedor, serviço, valor, recebido pela plataforma, repassado, execução e pendência. O detalhe organiza Partes, Serviço/Contrato, Financeiro e Mediação/Histórico.

Exemplo fictício de identificação:

| Evento | Contratante | Fornecedor | Serviço | Estado |
|---|---|---|---|---|
| Aniversário da Sofia | Ana Souza | Decora Festas | Decoração do salão | Contratado; execução ainda não confirmada |
| Aniversário da Sofia | Ana Souza | Buffet Sabor | Buffet para convidados | Em negociação |

No mesmo evento há duas relações comerciais. Uma ainda pode ser oportunidade: não conte como serviço prestado. IDs devem continuar internos ou em detalhes técnicos. Na ausência de identidade confiável, registre pendência, sem inventar nome.

Snapshots no aceite preservam identificação e condições da época; perfis atuais podem mudar. Contatos e dados necessários ao atendimento ficam disponíveis conforme autorização, sem liberar dados bancários completos, custos internos ou margens do fornecedor.

## Separação dos valores

| Indicador | Significado operacional |
|---|---|
| Contratado | Valor vigente das contratações |
| A receber do cliente | Obrigações do cliente ainda não liquidadas conforme ajustes |
| Recebido pela plataforma | Entrada confirmada/conferida, com fonte e nível de confirmação |
| Sem alocação | Valor recebido ainda não atribuído a contratos |
| Previsto ao fornecedor | Direito previsto conforme contrato e descontos aplicáveis |
| Elegível para repasse | Parcela que atende à política definida e aos recursos disponíveis |
| Autorizado/em processamento | Operação preparada; ainda não necessariamente confirmada |
| Repassado | Saída confirmada/conferida para o fornecedor, com origem |
| Comissão | Remuneração aplicável da plataforma, separada do dinheiro de terceiros |

Esses valores são dimensões diferentes: não podem ser somados indiscriminadamente. A implementação deve definir invariantes e fórmulas operacionais e manter os registros que explicam cada total.

## Exemplo de verificação, sem política comercial presumida

Contrato de R$ 10.000, com comissão sintética de 5% descontada do fornecedor:

- Direito total previsto do fornecedor: R$ 9.500.
- Comissão prevista: R$ 500, conforme regra/versão; não constitui cobrança adicional duplicada.
- Cliente paga R$ 4.000 à plataforma: após conferência, restam R$ 6.000 a receber do cliente.
- O fornecedor ainda não recebeu R$ 4.000: recebeu zero até que haja repasse confirmado.
- Sob política sintética que permite repasse parcial de R$ 3.000, confirmação deixa R$ 3.000 repassados e R$ 6.500 previstos ainda não repassados. Parte desse saldo pode ainda não estar financiada/elegível.
- A diferença de R$ 1.000 na plataforma precisa de destinação demonstrável; não se converte automaticamente em receita própria.

Se a comissão for adicionada ao preço do cliente, em vez de descontada do fornecedor, a equação é diferente. O sistema precisa explicitar qual política foi acordada, não aplicar as duas simultaneamente.

## Mediação de execução e divergências

Caso vinculado à contratação identifica motivo, manifestações, operador, evidências, decisão e conclusão. Nota interna não é mensagem compartilhada. Registro de decisão não significa reembolso/repasse executado: os efeitos usam comandos financeiros próprios, autorizados e rastreáveis.

Uma divergência em decoração não bloqueia automaticamente o buffet do mesmo evento. Qualquer bloqueio operacional precisa de escopo, motivo, autorização e regra definida. Chargeback ou reembolso depois de repasse exige ajuste e tratamento de recuperação/cobertura; não se resolve apagando o repasse histórico.

## Decisões pendentes de produto

1. Como a plataforma receberá e comprovará pagamentos na operação real: processo manual aprovado e/ou prestador integrado.
2. Quem suporta comissão, taxas e ajustes, e qual base/versão é aplicada.
3. Quando cada parcela se torna elegível para repasse e quais evidências são necessárias.
4. Como tratar aceite, contestação, cancelamento, reembolso e recuperação após repasse.
5. Quem pode conferir recebimento, decidir mediação e autorizar repasse; eventual separação de funções.
6. Termos e papel contratual das partes, incluindo pagador diferente do contratante.

Essas escolhas não impedem estruturar identificação, histórico e rastreabilidade. Recursos dependentes delas devem permanecer inativos ou em simulação até configuração válida. Não foi escolhido prestador de pagamentos, modelo de custódia/escrow ou enquadramento jurídico/contábil.

## Sequência recomendada

1. Identificação/contratação com nomes e vínculos confiáveis.
2. Recebimentos, alocações, comissão e repasses separados.
3. Central administrativa operacional e mediação.
4. Acompanhamento das partes e validação integrada.

O primeiro incremento resolve a ausência de identificação. Os demais tornam a mediação efetiva e explicável, em vez de apenas acrescentar nomes a um painel financeiro.
