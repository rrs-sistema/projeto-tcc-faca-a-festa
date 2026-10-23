# Comissões — revisão de ergonomia e intuitividade

Data: 22/10/2026.

## Diagnóstico

A tabela não preenchia a área do extrato e o detalhe usava painel inferior também no desktop. Valores e situação eram apresentados como texto corrido, com pouca hierarquia. Os testes anteriores de composição desenhavam exemplos de interface, sem abrir a página real.

## Alterações implementadas

- Pagador: saldo em destaque, comissões geradas e pagamentos registrados separados; quantidade de cobranças e status com texto e ícone. Não há dedução de vencimento sem status explícito.
- Tabela usa a largura disponível. Em telas menores ou com fonte ampliada, o extrato usa cards. Referência amigável é usada quando já consta nos dados; não foi criada consulta adicional nem nome fictício para evento.
- Detalhe: diálogo central com largura máxima de 720 px no desktop; painel no celular. Cabeçalho e fechamento fora da rolagem, corpo rolável e espaço para teclado.
- Valores separados por comissão, pagamentos, ajustes e saldo, preservando créditos negativos. Taxa aplicada e base usam o registro da cobrança. IDs completos ficam em seção expansível com texto selecionável.
- Simulador usa a mesma estrutura responsiva e valida campos vazios, taxa fora de 0–100% e valores inválidos. A simulação continua local e separada do extrato.
- Administração: recebimento continua pelo controller existente; erro aparece no campo e preserva o modal, com ação protegida durante envio. A área de cabeçalho e abas agora pode rolar, corrigindo overflow quando o teclado e um erro reduzem o espaço disponível.
- Falha inicial de consulta não apresenta os cards de saldo zero nem a mensagem de nenhuma cobrança. Atualização preserva os dados já carregados.

## Arquivos

- `lib/presentation/modules/financeiro/pages/comissao_plataforma_page.dart`
- `lib/presentation/modules/financeiro/widgets/comissao_modal.dart`
- `lib/presentation/modules/financeiro/widgets/comissao_detalhe.dart`
- `test/features/financeiro/comissoes_responsivas_test.dart`
- `test/features/financeiro/comissao_pagador_premium_test.dart`: assinatura do gateway de teste atualizada para incluir o timeout opcional já existente no contrato.

## Validação executada

Análise estática dos cinco arquivos: sem ocorrências.

```powershell
flutter test --no-pub --dart-define=CAPTURAS_COMISSOES=true test/features/financeiro/comissoes_responsivas_test.dart test/features/financeiro/comissao_plataforma_test.dart test/features/financeiro/comissao_plataforma_premium_test.dart test/features/financeiro/comissao_pagador_premium_test.dart
```

Resultado: **25 testes aprovados**, incluindo nove novos testes da página real e seus modais. Cobertura nova: desktop 1440×1000, celular 360×800 com fonte 100% e 200%, admin 390×844 com teclado de 300 px, paisagem 844×390, simulação sem escrita, erro de consulta, falha no recebimento, recebimento parcial e crédito sem taxa informada.

As imagens abaixo foram inspecionadas visualmente e são capturas dos widgets de produção com dados de teste e fontes locais. Não representam consulta à conta real do usuário.

- [Extrato desktop](comissoes-2026-10-22/desktop-extrato.png)
- [Detalhe desktop](comissoes-2026-10-22/desktop-detalhe.png)
- [Detalhe celular](comissoes-2026-10-22/celular-detalhe.png)

## Limites da verificação

Testes de interface usam gateway controlado. Não foi feita homologação com Firebase real, navegador ou aparelho físico nesta execução. A validação confirma apresentação, interação e chamadas ao controller, não transferência bancária ou integração remota. Nenhum deploy foi realizado.
