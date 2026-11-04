# Jornada: ergonomia e intuitividade — 27/10/2026

A tela existente foi reorganizada sem alterar backend, autorização, regras de transição, aceite, valores, versão da proposta ou histórico.

- Próximo passo destacado no início, com responsável (Você/Cliente/Fornecedor) e prazo real. Ausência de prazo é explícita.
- Ações existentes próximas do próximo passo. Proposta, contratação e preparação recebem botão preenchido; encerramento fica secundário. Botões com altura mínima48 e desabilitados durante carregamento/envio ou intenção pendente.
- Comercial e execução permanecem independentes, apresentados como Etapa do atendimento com rótulos legíveis. Não se cria etapa concluída, contrato ou entrega para preencher um fluxo visual.
- Sobre o pedido organiza cliente, evento, local e escopo com ícones e títulos. Referência do contrato fica na identificação recolhida.
- Ajuda explicativa deslocada para o fim. Propostas versionadas e histórico mantidos.
- Indicadores de etapa permitem quebra de linha: a inspeção visual detectou um rótulo cortado em Chip com fonte ampliada; o componente foi substituído por apresentação flexível.

Arquivos: `lib/presentation/modules/cotacao/pages/jornada_atendimento_page.dart` e `test/features/cotacoes/jornada_atendimento_test.dart`.

Validação real:

```powershell
flutter test test/features/cotacoes/jornada_atendimento_test.dart --update-goldens
flutter test test/features/cotacoes/jornada_atendimento_test.dart test/features/cotacoes/acesso_atendimento_test.dart
dart analyze lib/presentation/modules/cotacao/pages/jornada_atendimento_page.dart test/features/cotacoes/jornada_atendimento_test.dart
```

Resultado final: **17 testes aprovados**, comparação visual sem update-goldens, análise sem problemas e diff-check sem erros. Preservados testes de proposta, revisão concorrente, expiração, contratação, preparação/entrega/aceite, mediação, acesso ao chat/financeiro e troca de sessão. Novos testes conferem próximo passo, responsabilidade, prazo não inventado, ação principal preenchida e responsividade em390x1000 com fonte1,3 e1280x1100 com fonte1,0. A primeira execução dos testes novos identificou que FilledButton.icon usa uma subclasse; o finder foi corrigido para conferir a classe real sem remover a assertiva.

Imagens geradas nesta rodada com dados sintéticos e Poppins/MaterialIcons locais, inspecionadas visualmente:
- [Desktop](../jornada-ergonomia-desktop.png)
- [Celular com fonte ampliada](../jornada-ergonomia-celular.png)

Não houve deploy nem necessidade de alterar serviços. Não houve teste autenticado no navegador do usuário, leitor de tela externo ou estudo de usabilidade com usuários reais. Não se afirma validação de produção com base nesses widgets.
