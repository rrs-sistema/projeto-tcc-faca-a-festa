# Filtros e apresentação da reputação — 27/10/2026

Mudanças na tela existente, preservando controller, gateway, regras e persistência:

- Bloco de filtros com atalhos Todos os comentários / Preciso responder / Já respondidos.
- Três seletores: nota, período e Avaliações sobre (Sua empresa / Seus serviços / Empresa e serviços). Os valores enviados ao backend foram preservados.
- Botão Restaurar filtros quando há seleção diferente do padrão; restaura nota, período, resposta, tipo e situação com uma única consulta.
- Atualização automática explicitada. Seletores, atalhos e restauração desabilitados durante consulta ou envio, evitando alteração visual que não corresponda à consulta em andamento.
- Campos amplos no celular/fonte ampliada e240px no desktop.
- Sem avaliações verificadas, não desenha distribuição zerada nem evolução vazia. Ausência de comentários orienta ajustar filtros. Comentários históricos sem verificação continuam disponíveis conforme a consulta; não são promovidos a verificados.

Validações executadas:

```powershell
flutter test test/features/avaliacoes/gestao_reputacao_test.dart --update-goldens
flutter test test/features/avaliacoes/gestao_reputacao_test.dart
 dart analyze lib/presentation/modules/avaliacao/widgets/gestao_reputacao_painel.dart test/features/avaliacoes/gestao_reputacao_test.dart
```

Resultado final:19 testes aprovados, incluindo comparação visual sem atualização de golden, teste novo de filtro sem resposta/restauração confrontado com payload do gateway, resposta/edição/histórico, denúncia/moderação, paginação e isolamento de sessão. Análise sem problemas. Testes responsivos em360 e1200 pixels, também com escala de fonte2. As assertivas do estado vazio foram atualizadas para verificar ausência de gráficos e orientação ao usuário. A primeira execução anterior foi interrompida; não conta como aprovação.

Arquivos alterados: `lib/presentation/modules/avaliacao/widgets/gestao_reputacao_painel.dart` e `test/features/avaliacoes/gestao_reputacao_test.dart`, além de imagens atuais dos widgets em `../mensagens/reputacao-*.png`. Capturas geradas com dados sintéticos e fontes locais, não com dados de produção. Conferência visual realizada no desktop; ausência de overflow conferida nos testes móveis e com fonte ampliada.

Não houve alteração em cálculo/agregados, regras, Functions, autorização ou comandos financeiros; nenhum deploy necessário. Não foi executado teste autenticado na sessão do usuário nem estudo com usuários reais.
