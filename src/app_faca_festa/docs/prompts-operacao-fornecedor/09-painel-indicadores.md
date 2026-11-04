# Prompt 09 — Painel orientado à operação e indicadores rastreáveis

Reorganize o painel do fornecedor no Faça a Festa para apoiar decisões diárias. Repositório `D:\repository\unicesumar\tcc\app\src\app_faca_festa`; Flutter/GetX e Firebase/Functions TypeScript, Windows/PowerShell. Implemente o comportamento com integração real, não apenas uma proposta visual.

Leia AGENTS.md, confira Git e preserve alterações existentes. Não faça deploy, commit/push ou mudanças em produção. Reutilize identidade visual, componentes, fontes canônicas, navegação e políticas atuais. Não adicione dependências ou uma nova plataforma de site para redesenhar o aplicativo.

## Contexto

O painel tem onze cartões com peso semelhante. Alguns mostram rótulos de acesso, como Privado, Pagador e Quantidades. Há indicador de resposta média de 1,0h e cotação pendente há 64 horas; os números podem coexistir, mas faltam critério e período claros.

Inspecione `lib/presentation/modules/fornecedor/pages/fornecedor_home_screen.dart`, `sections/resumo_section.dart`, `controllers/fornecedor_painel_ao_vivo.dart`, entidades/estatísticas e serviços de insights.

## Implementação

1. Priorize fila de ações: atendimento vencido/aguardando retorno, próximos compromissos, repasse bloqueado, despesa vencendo e avaliação sem resposta. Cada item informa motivo, prazo quando conhecido e leva ao registro correto.
2. Separe indicadores do negócio dos atalhos para catálogo, estoque, perfil e configurações. Evite repetir totais e textos instrucionais em vários blocos. Disponibilize navegação clara para financeiro, atendimentos, agenda e reputação.
3. Calcule tempo de primeira resposta a partir de eventos persistidos, sem contar mensagens de sistema, respostas do próprio cliente ou reenvios. Defina período, amostra, fuso e uso de horas corridas/comerciais. Solicitações ainda sem resposta aparecem separadamente, sem tempo zero ou exclusão invisível do contexto.
4. Defina conversão e contratações por identidade e período, sem contar vários itens do catálogo como contratos. Separe ganho, perdido, cancelado e concluído. Métricas de avaliações seguem a mesma base canônica das telas de reputação.
5. Exiba fonte, período, atualização e estado parcial/desatualizado quando relevante. Sem amostra, use ausência de dados; não reutilize valor seed ou estimativa como métrica medida.
6. Prioridades essenciais devem funcionar sem IA. Insights e scores auxiliam a análise e nunca representam pagamento garantido ou probabilidade comprovada sem base. Não gere sugestões contraditórias com dados completos.
7. Preserve responsividade, navegação por teclado, leitor de tela, fonte ampliada e estados de erro/vazio. Não esconda conteúdo sob a navegação inferior. Restrinja consultas/agregados ao fornecedor autenticado.

## Aceite e testes

Um atendimento parado há 64 horas permanece na fila mesmo com média histórica de 1 hora. A média informa período e amostra. Clique no alerta abre a cotação correta. Contratação aparece uma única vez. Falha financeira não vira saldo zero; nenhum total é fabricado para preencher cartões.

Teste fórmulas com fixtures determinísticas, limites de período e navegação/estados com widgets. Verifique interface em larguras de celular e desktop. Registre decisões, resultados e evidências visuais em `docs/evidencias_validacao/operacao-fornecedor/09-painel-indicadores.md`.
