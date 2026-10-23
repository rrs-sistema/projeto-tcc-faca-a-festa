# Prompts — Telas premium, ergonomia e intuitividade

Preparação em 21/10/2026. Este pacote é de análise e instruções para implementação futura. Nenhuma tela foi alterada nesta preparação.

## Uso em chat novo

Copie integralmente um dos seis arquivos numerados para um chat novo, ou anexe e diga: “Execute o redesign descrito neste prompt no repositório”. Cada prompt inclui contexto, diagnóstico, proposta de composição, limites de escopo, critérios de aceite e validação. Não depende do histórico ou de outro arquivo.

As capturas em `referencias/` são opcionais: mostram os problemas originais e foram incluídas para preservar o contexto sem depender de arquivos temporários. Não representam o design final. Os seis arquivos atendem às seis capturas, sendo duas variantes da mesma página de comissões.

## Prompts

| Arquivo | Perfil e objetivo |
|---|---|
| [01-financeiro-fornecedor-premium.md](01-financeiro-fornecedor-premium.md) | Financeiro premium da empresa fornecedora |
| [02-comissoes-admin-premium.md](02-comissoes-admin-premium.md) | Comissões premium para administração |
| [03-dashboard-admin-premium.md](03-dashboard-admin-premium.md) | Dashboard financeiro administrativo premium |
| [04-estoque-fornecedor-premium.md](04-estoque-fornecedor-premium.md) | Estoque premium da empresa fornecedora |
| [05-comissoes-pagador-premium.md](05-comissoes-pagador-premium.md) | Extrato premium de comissões do fornecedor |
| [06-financeiro-organizador-premium.md](06-financeiro-organizador-premium.md) | Financeiro premium do organizador: lista e detalhe dos eventos |

[Análise de ergonomia e intuitividade](ANALISE.md).

## Direção aprovada pelo escopo deste pacote

Premium é qualidade visual e de uso, sem novo plano pago. O trabalho futuro se concentra em hierarquia, leitura, ações, filtros, formulários sob demanda, responsividade e linguagem. Erros de Firebase/Functions/conexão mostrados nas imagens não serão investigados por estes prompts.

Regras financeiras, cálculos, estado das políticas, privacidade e permissões devem ser preservados. Refinar apresentação de erro não autoriza corrigir infraestrutura ou substituí-la por dados fictícios.

As decisões de layout são propostas de produto. O executor deve conferir dados e comandos existentes antes de mostrar controles ou métricas. Não serão adicionados filtros, gráficos, pagamentos ou consultas globais sem suporte real.

## Ordem e coordenação

Pode usar cada prompt sozinho. Para uma sequência sugerida: 01 → 04 → 02 → 05 → 03 → 06. Não é pré-requisito técnico.

Os prompts 02 e 05 alteram variantes da mesma página, `comissao_plataforma_page.dart`; execute-os sequencialmente no mesmo checkout e verifique ambos os perfis. Outros prompts também podem compartilhar componentes. Chats separados não significam edições simultâneas seguras.

Não aplique mudanças globais de tema/app bar sem necessidade; componentes reaproveitados devem preservar as telas fora do escopo. O pacote financeiro anterior não foi substituído: este pacote melhora a experiência das capacidades já disponíveis, sem reimplementar seu domínio.

## Evidências esperadas na execução futura

Cada prompt solicita capturas, testes reais e relatório próprio em `docs/evidencias_validacao/premium/`. Não há alegação de homologação de tela, teste com usuário ou correção de infraestrutura nesta preparação.
