# Prompts — Intermediação de contratação, pagamento e repasse

Este pacote evolui o modelo de produto: cliente paga à plataforma, que acompanha destinação e repasses aos fornecedores. Não é apenas redesign.

[Leia a análise do modelo](ANALISE-MODELO.md).

## Prompts independentes para chats novos

| Arquivo | Entrega |
|---|---|
| [01-identificacao-e-contratacao.md](01-identificacao-e-contratacao.md) | Identificação das partes e contratação rastreável |
| [02-recebimentos-alocacoes-repasses.md](02-recebimentos-alocacoes-repasses.md) | Recebimentos da plataforma, alocações e repasses |
| [03-central-administrativa-mediacao.md](03-central-administrativa-mediacao.md) | Central administrativa de contratações e mediação |
| [04-acompanhamento-cliente-fornecedor.md](04-acompanhamento-cliente-fornecedor.md) | Acompanhamento das partes e validação da intermediação |

Copie integralmente um arquivo em um chat novo, ou anexe e peça sua execução no repositório. Todos repetem contexto, restrições, regras e validação. Não dependem de outro prompt executado; se faltar fundação necessária, pedem apenas a base mínima para seu objetivo.

Ordem recomendada: 01 → 02 → 03 → 04. Execute sequencialmente no mesmo checkout; chats separados podem editar modelos e funções compartilhados. A independência é de contexto, não ausência de conflitos de implementação.

## Relação com os pacotes anteriores

Os prompts de telas premium continuam úteis para acabamento, mas sua proibição de mudar domínio não se aplica à execução deste novo pacote estrutural. Este pacote não manda executar os anteriores e não modifica seus arquivos. Em caso de execução conjunta, este modelo de cliente → plataforma → fornecedor orienta a evolução financeira, preservando dados e fluxos legados compatíveis.

Pagamentos legados não são convertidos automaticamente em recebimento do APP/repasse. Comissão descontada no repasse não pode virar também dívida adicional da mesma comissão.

## Limites e decisões pendentes

As implementações futuras não fazem deploy/produção, transferência bancária real, cobrança real, commit/push ou envio externo de mensagens. Comissão, liberação de repasse, cancelamento e confirmação exigem políticas explícitas; simulação não ativa operação financeira.

A captura em `referencias/01-visao-financeira-admin.png` é referência do problema original. O modelo e os prompts contêm contexto suficiente sem a imagem.

Evidências serão geradas nas execuções em `docs/evidencias_validacao/mediacao/`. Criar este pacote não valida nem implementa os fluxos.
