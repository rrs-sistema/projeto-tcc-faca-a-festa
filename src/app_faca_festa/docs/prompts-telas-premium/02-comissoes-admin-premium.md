# Prompt 02 — Comissões premium para administração

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

Visão administrativa de “Comissões da plataforma”. Referência opcional: `docs/prompts-telas-premium/referencias/02-comissoes-admin.png`. A página atual começa com avisos técnicos e um simulador, seguido de formulário de política permanentemente aberto e listas pouco estruturadas. Falta uma ordem clara entre acompanhar cobranças, configurar regras e experimentar valores.

Investigue `lib/presentation/modules/financeiro/pages/comissao_plataforma_page.dart`, controller correspondente, entidade/serviço de comissão e componentes administrativos. A mesma página possui variante de pagador; preserve-a e não a substitua por uma tela administrativa. Se separar widgets por perfil, mantenha rota e autorização reais.

## Composição desejada

1. Cabeçalho “Comissões” com descrição curta e ação “Nova política”. Atualização secundária com rótulo/tooltip. Sem formulário permanente no primeiro bloco.
2. Síntese com valores gerados, recebidos e a receber, se disponíveis. Vencidos só com data/estado confiáveis; sem isso, não calcule atraso presumido. Inclua período/escopo dos totais.
3. Organização com áreas “Cobranças”, “Políticas” e “Simulador”, por tabs ou navegação equivalente acessível. Cobranças é a entrada principal; simulador fica como ferramenta auxiliar, sem domínio sobre a página.
4. Cobranças: tabela desktop/lista mobile com evento/contrato identificável, pagador, valor original, recebido, saldo, vencimento/situação quando existentes. Ação “Ver detalhes” mostra regra aplicada e movimentações. Sem ID técnico como título principal; se nome não estiver disponível, use referência curta honesta.
5. Políticas: lista de percentual, vigência/versão e estado disponíveis. Indique claramente ativa/inativa. Novo cadastro abre painel/página e apresenta resumo do que será salvo. Rótulo “Salvar política inativa” pode preservar a regra existente; não apresente campos configuráveis que o comando não aceita.
6. Ativação existente requer confirmação com regra/efeito compreensíveis e não ocorre automaticamente ao salvar. Não implemente nova política comercial ou ativação por conveniência visual.
7. Simulador: taxa e base lado a lado apenas com espaço suficiente, entradas pt-BR e resultado destacado como hipótese. “Esta simulação não gera cobrança” perto do resultado. Valores de demonstração claramente identificados, sem parecer saldo real.
8. Registro de recebimento manual abre formulário na cobrança selecionada, com saldo, valor e resumo. A interface informa “Registro manual” e não sugere confirmação bancária. Preserve comando `liquidar`, permissões e validações vigentes.

## Microcopy e aceite

“Obrigações” pode ser exibido como “Cobranças” sem alterar o domínio. “Política” recebe explicação curta “Regra de comissão”. Avisos de inatividade/manual aparecem no ponto de decisão, sem texto técnico em todo o topo.

- Entender saldo, encontrar cobrança e abrir regra são possíveis pela navegação principal.
- Nova política e simulador não se confundem, nem criam obrigação ao abrir/interagir.
- Criar/ativar/registrar recebimento continuam restritos ao administrador e usam comandos existentes.
- Nenhuma mudança visual altera fórmula, versão aplicada ou estado das políticas.
- Teste também a variante do pagador no mesmo arquivo para evitar regressão.

Evidência: `docs/evidencias_validacao/premium/02-comissoes-admin.md`.
