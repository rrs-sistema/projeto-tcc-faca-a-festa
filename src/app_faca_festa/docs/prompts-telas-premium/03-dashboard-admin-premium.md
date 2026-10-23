# Prompt 03 — Dashboard financeiro administrativo premium

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

Tela “Financeiro administrativo”, para administrador da plataforma. Referência opcional: `docs/prompts-telas-premium/referencias/03-financeiro-admin.png`.

A captura mostra grande faixa de filtros verticais, fornecedor por ID e botão Aplicar com largura extrema, sem uma estrutura executiva que permaneça legível com dados. Não deduza ausência de funcionalidades da falha de consulta mostrada: examine o código e projete os estados preenchidos a partir dos contratos reais.

Investigue `lib/presentation/modules/financeiro/pages/dashboard_financeiro_admin_page.dart`, controller correspondente, módulos do dashboard administrativo e `admin_kit.dart`. Preserve consulta e exportação existentes.

## Composição desejada

1. Cabeçalho “Visão financeira”, contexto e atualização. Ações secundárias Atualizar e exportação com texto que descreva o comportamento real. Se o código copia CSV, exiba “Copiar CSV”, não “Baixar relatório”.
2. Barra compacta de filtros: eixo temporal com rótulo compreensível, fornecedor por nome quando houver fonte autorizada e situação. Se houver período suportado, exponha-o. Filtros adicionais em painel. “Aplicar filtros” e “Limpar” com tamanho natural e escopo dos dados visível.
3. Primeira linha executiva com até quatro métricas principais suportadas: volume contratado, comissão gerada, comissão recebida, saldo de comissões. Volume é rotulado “Movimentado em contratos” ou equivalente, nunca receita própria.
4. Indicadores operacionais menores em área separada: eventos, contratos, serviços e fornecedores distintos conforme resposta atual. Não aumente número de cards só para preencher largura.
5. Resultado da plataforma só quando os dados justificarem; incompletude fica explícita. Tendência/histórico apenas com série real. Se não houver série, use síntese e lista útil, sem gráfico ornamental ou percentuais fictícios.
6. Lista “Eventos” no desktop como tabela com colunas priorizadas e números alinhados à direita. Mobile usa cards com campos essenciais e expansão. Detalhes disponíveis por ação explícita; não faça a linha inteira parecer clicável sem destino real.
7. Prioridades, como cobranças vencidas, só com dados confiáveis. Estados de consulta não deslocam o conteúdo inteiro com grandes espaços reservados sem função.
8. A área inicial deve orientar a decisão, mesmo no vazio: explicar ausência de registros no recorte e oferecer limpar filtros quando pertinente. Falha de consulta não é “nenhum evento”.

## Aceite específico

- R$ 100.000 em contratos e R$ 5.000 de comissão aparecem como métricas diferentes, sem impressão de receita própria de R$ 100.000.
- Selecionar eixo informa o significado do período; não renomeie eixos distintos como um genérico “Mês”.
- Filtros e exportação mantêm o mesmo conjunto e autorização. Não exporte os valores de um recorte anterior enquanto a tela mostra filtros novos não aplicados sem indicação.
- Desktop não é um formulário de 1900 px; mobile mantém identificação, valores e ações sem esmagar a tabela.
- Campos não suportados não são simulados como filtros funcionais.

Evidência: `docs/evidencias_validacao/premium/03-dashboard-admin.md`.
