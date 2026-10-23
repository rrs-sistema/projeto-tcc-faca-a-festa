# Prompt 06 — Financeiro premium do organizador

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

Financeiro do organizador, responsável autorizado pelos próprios eventos. Referência opcional: `docs/prompts-telas-premium/referencias/06-financeiro-organizador.png`.

A captura mobile mostra busca, chip de eixo temporal e chips comerciais ocupando várias linhas, explicação técnica persistente e quatro contadores antes dos eventos. O conteúdo útil perde espaço; “Linhas” não explica o que é contado; o eixo alterna ao toque sem apresentar suas opções. Com falha de consulta, os contadores aparecem zerados e uma mensagem isolada ocupa o centro da área restante. Isso descreve apresentação, não pede correção do erro.

Investigue `lib/presentation/modules/financeiro/pages/financeiro_gerente_list_page.dart`, `financeiro_gerente_detalhe_page.dart`, controller correspondente e `lib/domain/services/previsao_financeira_gerente_service.dart`. Apesar dos nomes internos “gerente”, o público desta entrega é o organizador. Não crie um novo papel/permissão nem renomeie a arquitetura inteira.

## Identidade e composição da lista

1. Use a identidade visual do organizador e seu tema vigente, com contraste consistente; a preferência índigo do contrato comum se aplica ao fornecedor, não obriga esta tela. Preserve navegação e identidade com acabamentos discretos, título legível e área segura no celular.
2. Cabeçalho “Financeiro dos meus eventos” ou “Financeiro”, com contexto curto. Ações Atualizar e Filtros identificáveis. “Limpar filtros” aparece quando há filtro ativo e tem texto/tooltip claro, sem ser o único ícone principal do cabeçalho.
3. Busca por nome do evento compacta, mas com área de toque confortável. O texto digitado e o estado do controller ficam sincronizados ao limpar filtros e retornar do detalhe. Não busque eventos globais.
4. Substitua a troca oculta do eixo por seleção explícita com duas opções, por exemplo “Data do evento” e “Referência de pagamento”. Deixe a opção selecionada visível. Ajuda contextual explica a referência real usada, sem dar impressão de extrato mensal completo.
5. Abra filtros adicionais em painel/sheet rolável: situação comercial, período e outros já suportados. Distinga selecionar rascunho de “Aplicar”, ou aplique imediatamente de forma coerente; não mantenha controles com modelos diferentes sem indicação. Cancelar filtros em rascunho preserva o recorte anterior.
6. Os chips comerciais atuais filtram eventos que contêm linhas naquele estado, conforme o código observado. Não apresente isso como filtro de cada pagamento/contrato agregado. Confirme a implementação atual: o eixo de pagamento pode selecionar eventos pela última data de pagamento e manter totais completos do evento. Não chame esse resultado de “Total pago no mês” nem altere regra financeira para atender ao layout; sinalize a limitação e escolha rótulo honesto.
7. Conte eventos, contratos, serviços/itens contratados e fornecedores apenas com a definição real. Troque “Linhas” por expressão compreensível, preservando exatamente o que é contado. Contadores são secundários, não quatro grandes blocos fixos antes da lista. Evite mostrar zero enquanto a consulta não confirmou vazio.
8. Cards de evento no celular: nome, data, estado e até três valores prioritários, como contratado, pago e saldo a pagar. “Ver financeiro” abre o detalhe correto. Previsão parcial ou excesso tem aviso próximo, sem depender só de cor. Não classifique saldo a pagar como vencido sem data.
9. Desktop usa área centralizada e tabela ou grid adequado, não celular esticado. Se houver síntese monetária consolidada, use somente dados completos, mesma seleção e sem duplicar eventos; deixe o escopo claro. Se não houver base confiável, mantenha síntese por evento, sem inventar indicadores.
10. Conteúdo deve rolar de maneira coordenada; evite filtros/contadores presos em uma Column que consuma quase toda a altura com teclado ou fonte ampliada.

## Detalhe do evento: continuidade da experiência

Inclua o detalhe no mesmo redesign para não trocar uma lista refinada por uma página de números em pills.

- Cabeçalho com nome/data e retorno que preserva busca, filtro e posição da lista.
- Bloco principal com limite, previsão final e folga/excesso, respeitando completude e contingência. Sem limite ou projeção completa, não afirme que cabe no orçamento.
- Segundo grupo com contratado, pago, saldo contratado, falta contratar e despesas adicionais, hierarquizados. O pagamento já incluído no contrato não entra de novo no custo.
- Serviços/compromissos em lista/tabela com categoria, fornecedor, contratado, pago e saldo conforme dados existentes, abrindo detalhes apenas quando houver destino real.
- Alertas agrupados, linguagem clara e detalhes de cálculo sob demanda; códigos internos saem da leitura principal.
- “Simular orçamento” como ferramenta secundária, usando `simularCenariosEvento` existente e mostrando hipótese separada dos fatos. Não registra contrato, pagamento nem altera limite.

## Estados e critérios de aceite

- Diferencie: nenhum evento cadastrado, nenhum resultado do filtro, carregamento, dados parciais e falha. “Limpar filtros” ajuda no segundo; CTA de criar evento só usa fluxo existente no primeiro. Falha não indica zero confirmado ou ausência de dívida.
- Erro pode ter apresentação compacta e ação de tentar novamente, sem investigar sua causa. Fixtures de teste/previews permitem verificar estados preenchidos sem inserir dados fictícios em produção.
- Limite R$ 30.000, contratado R$ 18.000, pago R$ 7.000 e falta contratar R$ 8.000: detalhe mostra saldo R$ 11.000, previsão R$ 26.000 e folga R$ 4.000 antes da reserva, quando os dados são completos.
- Campo sem preço mantém projeção parcial, sem selo de “Dentro do orçamento”.
- Em 360/390 px e texto a 200%, filtros/teclado não tornam resultados ou ações inacessíveis.
- Limpar busca atualiza campo e lista; retorno do detalhe preserva contexto; seleção não abre detalhe de outro evento após atualização.
- Testes cobrem filtros, retorno, estados de consulta e simulação, preservando IDs, acesso privado e semântica das datas.
- Não altere permissões, serviços financeiros ou backend para corrigir os erros da captura.

Evidência: `docs/evidencias_validacao/premium/06-financeiro-organizador.md`.
