# Administração financeira: ergonomia e intuitividade

Análise em 23/10/2026, com base nas seis capturas da versão 1.0.16+18 e na
estrutura Flutter das telas correspondentes. É uma avaliação heurística:
não houve observação de usuários, medição de contraste ou teste de usabilidade.
As propostas abaixo definem a próxima evolução da interface.

## Diagnóstico

A identidade visual já tem consistência: paleta, cartões, títulos, ícones e
formatação monetária. O principal obstáculo à percepção de produto premium é
a dificuldade para identificar situação atual, significado dos valores e próxima
ação. Mais decoração não resolve esses problemas.

Cada tela deve responder, nesta ordem:

1. O que estou administrando?
2. Qual é a situação e o que exige atenção?
3. Qual valor representa receita da plataforma, dinheiro recebido ou saldo do fornecedor?
4. O que posso fazer agora e qual será o efeito?

## Prioridade imediata: significado e prevenção de erro

### Oportunidade não é contratação confirmada

Nas capturas, oportunidades sem fornecedor aparecem com “Cliente a pagar”,
“A receber do cliente” e “Valor contratado / orçado”. Isso pode sugerir uma dívida
confirmada a partir de uma estimativa. A observação é sobre a apresentação;
não comprova existência de cobrança efetiva no backend.

Para oportunidades, usar “Valor estimado”, “Aguardando contratação” e
“Comissão definida após a contratação”. Não representar ausência de obrigação
por um saldo financeiro zero ou por “A conferir”. Reservar “A conferir” para
uma inconsistência que realmente exige intervenção.

Em contratos confirmados, usar “Valor contratado” e mostrar o financeiro real.
A lista precisa distinguir oportunidades e contratos por filtro/visão explícita.
Contadores devem dizer a que conjunto se referem.

### Saldo do fornecedor não é valor liberado

Usar rótulos distintos para valor previsto ao fornecedor, já pago, saldo pendente
e valor disponível para repasse. O saldo pendente pode estar bloqueado.
“Repasse liberado” deve vir da validação autoritativa, nunca da cor de um cartão
ou de uma inferência feita apenas pela interface.

### Recebimento exige contexto visível

No modal de comissão, o botão fixo está visível enquanto o campo “Valor recebido”
fica depois de composição, taxa e códigos técnicos. O código confirma que o valor
é previamente preenchido com o saldo. Assim, é possível acionar o registro antes
de perceber o campo.

Separar “Ver cobrança” de “Registrar recebimento”. A segunda ação abre um
formulário curto com evento, pagador, saldo e valor a registrar visíveis juntos,
seguido de revisão explícita. Mostrar o efeito no saldo e manter o valor em caso
de erro. Não anunciar pagamento bancário ou transferência automática.

## Recomendações por tela

| Tela | Problema observado | Direção proposta |
| --- | --- | --- |
| Visão financeira | Filtro ocupa o início; termos como “recorte”, “Olhar por”, “Pago” e “Saldo” exigem interpretação | Resumo e atenção no início; filtro compacto; “Filtrar pela data de”; identificar origem/destino de cada valor |
| Tabelas financeiras | Cabeçalhos “Valor” e “Situação” encostam na captura; leitura depende de texto pequeno | Larguras mínimas, separação entre colunas, valores alinhados à direita, ações identificadas e adaptação para cartões |
| Painel lateral | Identidade e status aparecem, mas falta explicar situação financeira e próximo passo | Resumo da contratação, valores essenciais e ação contextual; detalhes técnicos recolhidos |
| Comissões | Gerado/Recebido/A receber sem definição próxima; configuração tem destaque de operação diária | Destacar cobranças e pendências; configuração em ação secundária; explicar saldo e pagador |
| Detalhe da cobrança | Leitura longa e campo de operação longe do botão | Detalhe para consulta e fluxo curto para registrar recebimento, com revisão |
| Contratações e mediação | Cartões altos; oportunidades dominam a lista; duas ações com nomes abstratos | Lista mais compacta, filtros por situação, próximo passo visível, “Ver contratação” e “Recebimentos e repasses” |
| Dossiê | Coluna longa e estreita; status repetidos; financeiro e conflito disputam atenção | Cabeçalho com situação/próxima ação; seções “Resumo”, “Financeiro”, “Mediação” e “Histórico” |

## Arquitetura das telas

### Visão financeira

Topo: título, período aplicado e atualização. Resumo: comissões recebidas,
comissões a receber e valor contratado, com definições próximas. Em seguida,
pendências acionáveis e visão por evento/contratação. Filtros avançados recolhidos.

Substituir entrada de ID do fornecedor por seleção pesquisável por nome,
reaproveitando a identidade disponível no aplicativo. O ID pode permanecer em
detalhes de suporte. Datas devem ter seletor, período visível e opções rápidas.
Indicar claramente filtros alterados e ainda não aplicados.

### Comissões

Explicar no resumo: “As comissões são a remuneração da plataforma pelos contratos”.
Nas cobranças, priorizar evento, pagador, saldo, vencimento quando disponível e
ação. Identificar o papel do pagador, mesmo quando o nome repete o fornecedor.
“Nova política” deve ficar na área de regras/configuração.

### Contratações

Separar visualmente negociação, execução, financeiro e mediação. Não usar uma
sequência de chips indistintos para representar quatro dimensões diferentes.
Cada item deve mostrar evento, serviço, fornecedor, valor apropriado ao estágio,
pendência principal e uma ação primária. Exibir detalhe financeiro completo sob demanda.

Exemplos de próximo passo:

- Oportunidade: “Aguardando contratação”.
- Sem recebimento confirmado: “Conferir recebimento”.
- Mediação aberta: “Analisar mediação — repasse bloqueado”.
- Evento não finalizado e sem autorização: “Aguardar finalização ou autorização do organizador”.
- Condições confirmadas no servidor: “Conferir e preparar repasse”.

Não apresentar esses estados como progresso linear obrigatório: há pagamentos
parciais, autorizações antecipadas, cancelamentos e contestações.

### Dossiê e mediação

Trocar “Dinheiro em jogo” por “Resumo financeiro”. O cabeçalho deve mostrar o
estágio comercial correto. Oportunidades não devem receber aparência de contrato
formalizado. Em desktop, usar uma área de conteúdo mais larga e uma coluna de
situação/ações; em telas menores, empilhar preservando a ordem de importância.

Na mediação, apresentar situação, responsável, última decisão e próximo passo.
A ação de encerrar explica o que resolve e se permanece algum bloqueio.
A regularização mostra que cancela reservas pendentes e exige nova autorização
antecipada quando aplicável. Notas e histórico ficam separados do formulário da ação.

## Padrão de ajuda contextual

Ajuda em três níveis, com o mesmo comportamento em todas as telas:

1. Frase curta junto ao valor/campo quando essencial para interpretar a informação.
2. Ícone de ajuda acessível por clique, toque e teclado, com explicação e exemplo.
3. “Como funciona esta tela”, recolhível, com passos operacionais e glossário.

Tooltip de mouse pode complementar; não deve ser a única forma de acesso.
Alertas persistentes ficam reservados a impedimentos e decisões relevantes.

Textos sugeridos:

| Termo/ação | Ajuda |
| --- | --- |
| Valor contratado | Total dos serviços com contratação confirmada no período selecionado. |
| Comissão gerada | Remuneração prevista da plataforma nos contratos. Parte dela pode ainda não ter sido recebida. |
| Comissão recebida | Parcela da comissão com recebimento registrado, inclusive por retenção em repasse. |
| A receber de comissão | Parcela da comissão que ainda falta receber. |
| Recebido do cliente | Valor confirmado e vinculado a esta contratação. Uma declaração de pagamento ainda não conferida não libera repasse. |
| Saldo do fornecedor | Valor ainda não pago ao fornecedor. Pode haver bloqueio para liberação. |
| Disponível para repasse | Valor que atende às condições de saldo e liberação verificadas pelo sistema. |
| Repasse bloqueado por mediação | Há uma pendência nesta contratação. Consulte a mediação para verificar o motivo e a próxima ação. |
| Registrar recebimento de comissão | Use após conferir o recebimento da comissão. O registro atualiza o extrato e não realiza transferência bancária. |
| Alocar recebimento | Vincule o dinheiro já recebido aos contratos correspondentes. Essa etapa não faz uma transferência. |

## Padrão visual proposto

- Preservar a identidade verde; reservar a cor de destaque para ações principais.
- Superfícies claras, bordas discretas, espaçamento consistente e menos caixas aninhadas.
- Escala sugerida: título de página 24–28, seção 18–20 e conteúdo 14–16 pixels lógicos.
- Metadados menores apenas quando secundários; valores financeiros essenciais não devem ser truncados.
- Espaçamento baseado em 8/16/24, com densidade ajustada para listas extensas.
- Áreas de interação de pelo menos 48 × 48 pixels lógicos como alvo de projeto.
- Estados com texto e ícone, além da cor; erro com orientação de recuperação.
- Cabeçalhos e ações consistentes entre painel lateral, modal e página de detalhe.
- Aproveitar a largura desktop sem esticar linhas de texto indefinidamente; manter leitura adequada no celular e com ampliação de texto.

## Ordem de execução e critérios de aceite

1. Corrigir significado dos estados, separar oportunidade/contrato e melhorar o fluxo de recebimento.
2. Padronizar resumo, filtros, lista, tabela e painel lateral.
3. Reorganizar dossiê/mediação e implementar ajuda contextual compartilhada.
4. Validar os fluxos e a apresentação em desktop e celular antes de nova publicação.

Verificar em 360, 768, 1280, 1366 e 1920 de largura, com ampliação de texto até
200% e teclado virtual. Essas larguras são alvos de validação, não breakpoints obrigatórios.
Validar navegação por teclado, foco, leitura assistiva, contraste medido, conteúdo
longo e ausência de colisão/truncamento de valores.

Cobrir estados de carregamento, vazio, erro, filtros pendentes, oportunidade,
contrato confirmado, pagamento parcial, comissão paga separadamente, mediação
aberta/encerrada, evento finalizado e autorização antecipada válida/revogada.
Preservar os testes e as regras de liberação financeira já existentes.

Em uma sessão de usabilidade, pedir que o administrador localize a receita da
plataforma, diferencie estimativa e contrato, explique um bloqueio, registre um
recebimento e encontre a próxima ação de mediação. Registrar erros, dúvidas e
necessidade de ajuda; percepção de “premium” precisa ser confirmada com usuários.

## Referências no código

- `lib/presentation/modules/financeiro/pages/dashboard_financeiro_admin_page.dart`
- `lib/presentation/modules/financeiro/pages/comissao_plataforma_page.dart`
- `lib/presentation/modules/financeiro/widgets/comissao_detalhe.dart`
- `lib/presentation/modules/financeiro/widgets/comissao_modal.dart`
- `lib/presentation/modules/financeiro/pages/central_mediacao_page.dart`
- `lib/presentation/modules/financeiro/pages/central_mediacao_detalhe_page.dart`

Este documento registra a avaliação e os critérios da proposta. A aplicação das
melhorias e sua validação estão registradas em
[implementação de ergonomia](ergonomia-admin-implementacao.md).
