# Mensagens de consulta — fornecedor

27/10/2026. Ajuste de conteúdo e apresentação, sem deploy ou alteração de regras/dados.

- Primeira consulta falhou: **Não foi possível carregar o painel** / **Tente novamente em instantes para consultar suas pendências.**
- Atualização falhou com snapshot existente: **Não foi possível atualizar o painel** / **Os dados exibidos são da última consulta. Tente atualizar novamente.**
- Não se usa mais “se disponíveis”, nem se afirma que há dados anteriores quando a consulta inicial falhou.
- Aviso de consulta com superfície neutra, ícone, título e ação. A indicação de desatualização não é repetida junto ao mesmo aviso; data da consulta continua acessível.
- Padrão revisto também em agenda, planejamento financeiro e reputação. Mensagens de permissão, sessão e validação continuam específicas. A mensagem genérica não atribui a falha à conexão sem evidência.
- Mensagens de comandos/gravações pendentes não foram indiscriminadamente trocadas por incentivo a repetir operações.

Validação: 82 testes Flutter aprovados (painel, operação, agenda, planejamento, reputação e cotações), inclusive ausência de snapshot versus última consulta. Análise Dart sem problemas. Referências visuais anteriores preservadas.

```powershell
flutter test test/features/painel test/features/operacao test/features/avaliacoes/gestao_reputacao_test.dart --update-goldens --reporter expanded
flutter test test/features/painel test/features/operacao test/features/agenda test/features/planejamento test/features/avaliacoes/gestao_reputacao_test.dart test/features/cotacoes --reporter expanded
```

[Prévia do painel](../mensagens-painel-falha.png) · [Testes](widgets.txt) · [Análise](analyze.txt).

Imagens geradas em testes com dados sintéticos; não representam correção da disponibilidade de uma API hospedada. A rodada muda mensagens e estados de apresentação, não a causa da falha no backend.
