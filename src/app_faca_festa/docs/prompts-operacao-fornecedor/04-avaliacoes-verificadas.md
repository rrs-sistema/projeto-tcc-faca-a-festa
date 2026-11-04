# Prompt 04 — Avaliações verificadas e protegidas

Implemente a integridade das avaliações que formam a reputação do fornecedor no Faça a Festa. Repositório: `D:\repository\unicesumar\tcc\app\src\app_faca_festa`; Flutter/GetX, Firebase Auth/Firestore e Functions TypeScript. Ambiente Windows/PowerShell. Faça a implementação completa pertinente ao escopo.

Leia AGENTS.md, confira Git e preserve alterações existentes. Não publique, não faça commit/push nem migre dados em produção. Use dados sintéticos em testes e emuladores. Os achados abaixo precisam ser reconfirmados.

## Problema

Há coleções de avaliações com escrita liberada a qualquer autenticado; avaliações aninhadas no fornecedor são alcançadas por regra genérica de escrita do próprio fornecedor. A criação usa subcoleções, enquanto parte das verificações de duplicidade consulta `avaliacao_fornecedor`. Uma verificação admite participação em cotação sem comprovar serviço entregue.

Inspecione `firestore.rules`, `lib/data/datasources/remote/avaliacao_servico_remote_datasource.dart`, os repositories/usecases de avaliação, controller de avaliações e todos os consumidores de média, quantidade, ranking e recomendações. Não assuma que um arquivo de serviço existente contém implementação utilizável.

## Implementação

1. Escolha o armazenamento canônico compatível com o projeto e identifique autor pela sessão, contratação, fornecedor e objeto avaliado. Não confie em IDs/nome de autor enviados pelo cliente.
2. Garanta uma avaliação por autor/contratação/objeto mediante identidade determinística e transação. Repetição é idempotente; novo payload segue política explícita de edição/histórico.
3. Avaliação do serviço entregue exige vínculo e conclusão/aceite compatíveis com a jornada real. Se houver avaliação de atendimento comercial, mantenha tipo e agregados separados. Cotação enviada ou contrato fechado não comprovam entrega.
4. Valide nota finita no intervalo permitido, comentário, campos, datas do servidor e elegibilidade no backend. Bloqueie autoavaliação e escrita de terceiros. Proteja também agregados no documento do fornecedor; não basta proteger comentários.
5. Cliente e fornecedor não podem alterar a nota/comentário do outro ou apagar críticas. Moderação usa autorização específica e histórico. Remova concessões genéricas sobrepostas e adapte consultas/índices.
6. Integre média/quantidade em todos os consumidores sem dupla contagem. Legado sem vínculo deve ter tratamento explícito, preservado sem receber selo de verificado indevidamente. Prepare migração revisável/dry-run se necessária, sem executá-la em produção.

## Aceite

Cliente de contratação concluída consegue avaliar uma vez; outro cliente, fornecedor avaliado e usuário sem vínculo não conseguem criar essa avaliação. Nota fora da faixa, autoria falsificada e corrida de duas criações são rejeitadas/tratadas corretamente. Novo comentário e agregados convergem. Leitura histórica permanece compatível sem fabricar verificação.

Execute testes de regras no emulador, autorização das Functions, concorrência, agregados e regressão dos consumidores. Registre formato, compatibilidade e resultados em `docs/evidencias_validacao/operacao-fornecedor/04-avaliacoes-verificadas.md`. Entregue código, verificações executadas e limitações restantes.
