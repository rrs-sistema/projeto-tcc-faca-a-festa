# Ergonomia da administração — implementação

Implementação de 23/10/2026, a partir da
[análise de ergonomia e intuitividade](analise-ergonomia-admin-financeiro.md).

## Visão financeira

- Receita e indicadores antes dos filtros; filtros recolhíveis com período aplicado e aviso de alterações pendentes.
- Seleção de fornecedor por nome, usando o cadastro existente e mantendo o ID apenas no pedido ao servidor.
- Seleção de datas por calendário.
- Separação entre colunas e adaptação para cartões quando o espaço ou a ampliação de texto não comportam tabela.
- Rótulos explícitos: situação do evento, pagamentos registrados e saldo do contrato.
- Ajuda acessível por clique/toque/teclado sobre comissão, recebimento, saldo e condições de repasse.

## Comissões

- Indicadores identificam comissão gerada, recebida e a receber.
- “Regras de comissão” como ação secundária; criação de política na área de políticas.
- Guia recolhível explica receita, pagador e registro de recebimento.
- Consulta da cobrança separada do formulário de recebimento.
- Formulário curto mantém evento, pagador, saldo e valor juntos.
- “Revisar recebimento” abre confirmação explícita com pagador e valor. Voltar preserva a entrada; falha mantém o formulário; sucesso atualiza o extrato.
- Cobrança sem saldo positivo não oferece novo registro pelo detalhe.

## Contratações, financeiro e mediação

- Filtros rápidos distinguem todos, contratos e oportunidades.
- Oportunidade mostra valor estimado e aguarda contratação, sem rótulo “Cliente a pagar”, comissão indefinida tratada como erro ou acesso direto ao repasse.
- Contador de contratos a receber exclui oportunidades e identifica o escopo da página.
- Botões usam “Ver contratação”, “Ver oportunidade” e “Recebimentos e repasses”.
- Valores organizados em blocos adaptáveis; metadados e valores têm hierarquia visual distinta.
- Detalhe organizado em Resumo, Financeiro e Mediação e histórico. Em desktop, os dados de serviço e partes aproveitam duas colunas.
- Oportunidades também não apresentam uma dívida no detalhe financeiro.
- Contratos mostram orientação de próximo passo, preservando o motivo de bloqueio retornado pelo servidor. A interface não declara um saldo como liberado por inferência.
- Guia de recebimentos e repasses explica conferência, vínculo do dinheiro ao contrato e confirmação após transferência manual.

As regras financeiras e as Functions não foram alteradas nesta etapa.
Preparação e confirmação de repasse continuam validadas no servidor.

## Verificação

- 138 testes Flutter de financeiro e administração aprovados, incluindo 13 novos cenários de ergonomia.
- Nova rodada dos 18 testes diretamente relacionados a dashboard/ergonomia aprovada após a revisão final de rótulos.
- Análise Dart dos sete arquivos de implementação sem problemas.
- Lista validada em 360, 768, 1366 e 1920 pixels, em escala de texto normal e 200%.
- Seleção de fornecedor exercitada em desktop e em 360 pixels com texto ampliado, verificando que o nome exibido corresponde ao ID enviado.
- Ajuda aberta por ação explícita, filtro de contratos, oportunidade sem dívida, revisão/cancelamento/erro de recebimento e resolução de mediação exercitados em widgets reais.
- Capturas locais inspecionadas em `.dart_tool/capturas-ergonomia` e `.dart_tool/capturas-comissoes`.
- As capturas usam dados fictícios e não modificam registros de produção.

Esta validação de interface não substitui uma sessão de usabilidade com os
administradores. Os critérios de contraste e leitura assistiva do plano continuam
como critérios de avaliação específica, sem declaração de certificação de acessibilidade.

## Correções locais posteriores à publicação — 23/10/2026

- Estado comercial normalizado para tratar `Contratado`, `contratado` e espaços externos de forma consistente no detalhe, financeiro e lista.
- Registros vazios não são enviados ao servidor. Decisão e conclusão respeitam os limites de 10 a 2000 caracteres.
- Validação e erros conhecidos de envio aparecem junto ao campo, com foco para correção e preservação do texto.
- Seção de mediação atualiza mensagens e estado de envio de forma reativa.
- 147 testes de financeiro/administração aprovados e análise Dart sem problemas.
- Ajustes somente no código local; sem deploy, nova versão ou alteração de dados de produção.
