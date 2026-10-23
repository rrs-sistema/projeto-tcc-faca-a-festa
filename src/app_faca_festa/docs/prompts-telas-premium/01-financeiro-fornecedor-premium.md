# Prompt 01 — Financeiro premium da empresa fornecedora

## Missão e contexto autossuficiente

Atue como designer sênior de produto, especialista em ergonomia/intuitividade e desenvolvedor Flutter. Implemente o redesign desta tela no Faça a Festa, com qualidade visual premium e fluxos reais preservados. Premium significa acabamento, legibilidade e facilidade de uso; não crie plano pago, paywall ou novo papel de acesso.

Repositório: `D:\repository\unicesumar\tcc\app\src\app_faca_festa`. Stack observada: Flutter/Dart, GetX, Firebase Auth/Firestore/Functions. Este prompt funciona em chat novo, sem histórico, sem outro prompt e sem imagens obrigatórias: o diagnóstico e a proposta estão descritos abaixo. A referência visual, quando disponível no pacote, retrata a versão anterior, não um layout a reproduzir.

Leia AGENTS.md aplicáveis, Git e implementação atual antes de editar. Preserve alterações preexistentes. Confirme caminhos e capacidades. Reutilize controllers, comandos, validação e autorização. Entregue UI integrada, não somente mockup ou plano. Não publique, faça deploy, commit/push ou alterações de produção.

## Escopo e limites

O usuário pediu melhoria de ergonomia e intuitividade e determinou que os erros técnicos das capturas não são o foco. Não investigue nem corrija Firebase, Functions, conexão, credenciais ou regras financeiras. A apresentação de estados pode ser refinada, sem mudar a causa ou ocultar falha como sucesso/vazio.

Não reescreva fórmulas, centavos, políticas, regras de negócio ou permissões. Controllers podem receber adaptações de apresentação estritamente necessárias, documentadas e testadas. Novos filtros, campos, gráficos e ações só aparecem funcionais se houver dados/comandos reais compatíveis. Não invente endpoints ou habilite dados globais para preencher seletor. Funções ausentes ficam registradas como lacuna; remova controles decorativos ou desabilite-os com motivo útil.

## Direção visual comum

- Inspecione `lib/presentation/modules/fornecedor/sections/fornecedor_premium_layout.dart`, `lib/presentation/widgets/admin/admin_kit.dart`, `lib/presentation/modules/tema/admin_theme.dart` e app bars atuais. Use vocabulário visual coerente e componentes existentes adequados. Não aplique um tema global que altere telas fora do escopo. Se necessário, crie componentes de apresentação pequenos e reutilizáveis, sem exigir outro prompt.
- Fornecedor: fundos claros, superfícies brancas, texto escuro e acento índigo discreto, alinhado ao painel premium existente. Administração: mesma família de componentes com acento verde-petróleo. Estado financeiro usa cor semântica com texto/ícone, não só cor. Evite gradiente dominante, excesso de badges, sombras fortes e cartões aninhados.
- Área principal centralizada com largura máxima aproximada de 1360–1440 px em desktop; formulários com largura confortável. Use grid adaptativo, preenchimento útil e respiro. Não estique campos ou botões a 1900 px. Margens ~16 px no celular e 24–32 px no desktop; ritmo baseado em 4/8 px.
- Título ~24–28 px no desktop, corpo ~14–16 px, números principais ~26–32 px como ponto de partida. Adapte ao espaço, sem encolher informações para caber. Valores alinhados e formatados em pt-BR: R$ 10.000,00; 5%; datas legíveis.
- Cabeçalho compacto com título, contexto e ações. Uma ação primária por contexto. Filtros próximos dos dados; mais opções sob expansão. Formulários de criação/edição abrem sob demanda em painel lateral no desktop e página/sheet rolável adequado ao celular.
- Defina a ordem: orientação → síntese → prioridades → detalhe. Topo responde à tarefa do perfil. Não imponha gráficos sem série/escala disponível, nem tendências ou comparações inventadas. Todo gráfico precisa de rótulos e alternativa textual.
- Remova identificadores técnicos da entrada principal. Quando houver fonte autorizada, seletores usam nome, data e contexto, guardando ID internamente. Se faltar fonte, reutilize seleção contextual existente ou explique a limitação; não disfarce um campo de ID como “buscar evento”.
- Linguagem do usuário: termos de negócio curtos. Fórmulas, campos com underscore e notas de implementação saem da leitura principal. Informações que afetam a decisão continuam próximas do valor; detalhes de cálculo podem ir em “Como é calculado”. Dados parciais nunca parecem completos.
- Estados inicial, preenchido, vazio, sem resultado de filtro, carregando, parcial, desatualizado e erro têm apresentação distinta quando suportados. Falha não vira R$ 0,00. Valor ausente aparece “—” com explicação; zero confirmado continua zero.
- Teclado: ordem de foco previsível, foco visível, Enter adequado, Escape fecha overlays sem salvar, foco retorna ao acionador. Ícones com tooltip/rótulo semântico. Alvos de toque de pelo menos 48 px, contraste legível e texto ampliado até 200% sem perder ações.
- Reduza rolagem desnecessária, mas mantenha acesso às tarefas. Sem banners fixos ou overlays cobrindo campos/teclado. Mudança de filtro não perde edição sem aviso pertinente. Confirmação adicional apenas para ações sensíveis existentes, sem tornar consultas burocráticas.

## Validação e entrega

Antes de editar, resuma o diagnóstico e a composição que será implementada; prossiga sem pedir aprovação adicional. Depois verifique telas em 360, 390, 768, 1280 e 1920 px, texto a 200% nos fluxos principais, navegação por teclado e formulários com teclado aberto conforme ambiente disponível. Não declare teste visual que não executou.

Erros do backend não bloqueiam QA visual: use fixtures sintéticas isoladas em testes/previews, nunca fallback fictício em produção. Cubra estados vazio, preenchido e parcial, e o erro apenas como apresentação. Verifique que comandos reais ainda recebem os mesmos identificadores/valores e que cancelar não grava. Execute formatação/análise dos arquivos alterados e testes de widget/interação relevantes; não teste somente decoração.

Registre evidência no caminho específico indicado: diagnóstico, antes/depois com capturas quando possível, composição desktop/mobile, componentes, fluxos preservados, testes realmente executados e limitações. A captura é evidência, não substitui integração. Entregue implementação e resumo concreto de ergonomia, intuitividade e acabamento, sem alegar corrigir os erros de infraestrutura.

## Tela, público e diagnóstico

Tela “Financeiro da empresa”, para proprietário/responsável autorizado da fornecedora. Referência opcional: `docs/prompts-telas-premium/referencias/01-financeiro-fornecedor.png`.

A captura mostra filtro por ID ocupando toda a largura, sete indicadores minúsculos em uma faixa colorida, blocos textuais extensos de resultado/caixa e alertas repetidos. A pessoa precisa localizar números em frases e entender observações técnicas. O código também coloca formulários de custo e recebimento na rolagem principal.

Investigue `lib/presentation/modules/financeiro/pages/financeiro_fornecedor_page.dart`, controller correspondente, modelos de resumo e o painel premium do fornecedor. Preserve os comandos existentes `registrarCustoManual`, `registrarRecebimento` e sua autorização.

## Composição desejada

1. Cabeçalho “Financeiro”, empresa/contexto autorizado e atualização discreta. Ações “Registrar recebimento” e “Lançar custo”, com destaque coerente à tarefa. Abrem formulários sob demanda, sem ocupar o dashboard em repouso.
2. Barra contextual: evento por nome quando houver fonte autorizada, busca/limpeza conforme capacidade. Período somente se a origem suportar filtro real; não mostre seletor inoperante.
3. Quatro métricas principais sugeridas: contratado, recebido, a receber e custo previsto. Detalhe custo realizado/restante em texto secundário ou expansão. “A receber” tem maior atenção quando é a tarefa relevante, sem sugerir atraso inexistente.
4. Segunda faixa com Resultado e Caixa em duas colunas no desktop e uma no celular. Resultado distingue previsto/realizado e qualidade dos dados. “Resultado parcial” perto do valor com link “Ver pendências”. Caixa diferencia entradas, saídas e movimento líquido; sem saldo inicial, use “Movimento do período”, sem afirmar saldo disponível.
5. Se houver lançamentos consultáveis, mostre seção com lista/tabela de data, evento, descrição, valor e situação. Não crie registros com base em totais agregados.
6. Alertas agrupados por causa e contexto, com contagem/expansão se necessário. A mesma causa não se repete visualmente seis vezes, mas eventos diferentes continuam identificáveis. CTA somente quando houver destino/ação real.
7. Detalhes de cálculo em ajuda contextual. Troque “componentes ausentes (explícito)” por “Faltam informações para concluir o resultado”, identificando quais. Não esconda que taxas/despesas ainda não foram informadas.

## Interações essenciais

Formulário de custo/recebimento mostra contexto do evento/contrato, rótulos persistentes, moeda, campos obrigatórios, validação próxima ao campo e estado de envio. Não pré-preencha valor monetário arbitrário. Cancelar não grava; enviar uma vez não dispara duas chamadas por toque repetido. Preserve foco e edição em falha.

## Aceite específico

- Contratado R$ 10.000, recebido R$ 4.000, a receber R$ 6.000 ficam identificáveis sem ler fórmulas.
- Resultado parcial e movimento de caixa não parecem lucro líquido/saldo bancário.
- No desktop, indicadores usam grid; no celular, sequência de leitura clara, sem overflow horizontal da página.
- Recebimento e custo continuam acionando os contratos existentes, sem mudar valores ou titular.
- Filtro não exige memorizar ID quando houver escolha autorizada por nome.

Evidência: `docs/evidencias_validacao/premium/01-financeiro-fornecedor.md`.
