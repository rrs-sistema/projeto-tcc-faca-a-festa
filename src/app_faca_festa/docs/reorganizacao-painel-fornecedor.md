# Reorganização do painel do fornecedor

## Ponto de restauração

Tag local: `checkpoint/painel-fornecedor-2026-11-19`.

A tag preserva o estado dos arquivos rastreados imediatamente antes desta alteração, incluindo as mudanças locais que já existiam. Sua criação não mudou a branch nem limpou o diretório de trabalho. Arquivos não rastreados preexistentes não foram incluídos nem alterados.

Para voltar à apresentação anterior, execute na pasta `src/app_faca_festa`:

```powershell
.\scripts\restaurar-painel-fornecedor.ps1
```

Para apenas conferir a operação:

```powershell
.\scripts\restaurar-painel-fornecedor.ps1 -WhatIf
```

O script copia os arquivos que substituirá para `output/painel-backups/<data-hora>`, restaura somente os doze arquivos listados nele e remove o novo componente `pedido_resumo_card.dart`, também incluído na cópia. Não executa reset global, não troca de branch e não altera o staging. Alterações posteriores nesses mesmos arquivos também serão substituídas, mas estarão na cópia. A documentação e as novas imagens de validação permanecem disponíveis. A tag é local: não foi enviada ao servidor Git.

## Comportamento aplicado

- Navegação por áreas: Visão geral, Pedidos, Catálogo, Acessos rápidos e Avaliações. A opção Acessos rápidos leva diretamente ao bloco de ferramentas da visão geral. Cada área mantém seu estado durante a navegação; a página volta ao início ao mudar de área.
- Visão geral: atenção imediata, quatro indicadores, até cinco pedidos novos por ordem de espera, agenda, ferramentas, oportunidades regionais e preparação resumida do catálogo.
- Pedidos: linhas adaptadas à largura disponível, identificação do cliente, situação comercial, tempo de espera, valor e ação contextual. Descrição e assistência de IA ficam nos detalhes.
- Gestão completa: busca por cliente, ID, descrição e serviço; filtros de situação, categoria e recebimento; ordenação por data ou maior valor; vinte resultados por página.
- Catálogo: área própria com qualidade, critérios, ofertas e acesso a Gerenciar ofertas. As imagens existentes são exibidas com fallback em caso de falha.
- Avaliações: área própria; filtros recolhidos quando a consulta padrão está vazia. As alterações de avaliações que já existiam foram preservadas.
- Títulos podem quebrar linha, botões dos pedidos têm altura mínima de 48 pixels e a atualização dos indicadores tem apresentação compacta com diagnóstico expansível.

- Cabeçalho: identificação e situação da empresa agrupadas, ações Área de atendimento e Comunicados com rótulos e menu Minha conta para privacidade, notificações, auditoria, atualizações e saída.

## Limite de escalabilidade

A paginação é de apresentação: somente cinco pedidos são montados no resumo e vinte na página da gestão completa. O datasource mantém sua assinatura em tempo real e ainda consulta todos os pedidos autorizados. Esta alteração não reduz as leituras do Firestore. Paginação por cursor no servidor, contadores agregados e busca remota precisam de uma evolução específica da camada de dados; limitar a consulta atual sem esse trabalho esconderia pedidos dos filtros e dos contadores.

## Validação

- Análise estática dos arquivos alterados.
- Testes de ordenação e limite do resumo, navegação por páginas, busca combinada com filtros, acesso a propostas e detalhes com IA.
- Imagens de referência próprias em `docs/evidencias_validacao/operacao-fornecedor/reorganizacao/`; as referências antigas de restauração foram mantidas.
- Layout verificado em 360 e 1280 pixels e com escala de texto de 200%.

As imagens usam fontes e dados de teste. A alteração não publica nem gera um novo instalador do aplicativo.
