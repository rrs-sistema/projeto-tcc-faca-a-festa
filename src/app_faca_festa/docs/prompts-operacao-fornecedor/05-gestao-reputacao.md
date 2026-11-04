# Prompt 05 — Gestão da reputação pelo fornecedor

Implemente a gestão operacional das avaliações do fornecedor no Faça a Festa, em `D:\repository\unicesumar\tcc\app\src\app_faca_festa`. Flutter/Dart/GetX, Firestore e Functions TypeScript; Windows/PowerShell. Este é um pedido de implementação autocontido.

Leia AGENTS.md e Git, preserve alterações em andamento e reutilize os padrões atuais. Não faça deploy, commit, push, modificação em produção nem envie notificações externas reais. Execute validações com dados sintéticos.

## Contexto

`lib/presentation/modules/fornecedor/sections/avaliacoes_section.dart` apresenta média e insights, mas não oferece uma gestão completa de comentários, respostas e denúncias. Inspecione também controllers, entidades e datasources de avaliações.

A base precisa garantir avaliações verificadas, autoria e unicidade. Reutilize essa base caso exista. Se faltar, implemente o mínimo seguro necessário: não exponha respostas ou moderação sobre permissões amplas e não exija que o usuário execute outro prompt para obter uma entrega funcional.

## Implementação

1. Mostre comentários reais com nota, data, serviço e contexto compartilhável da contratação. Use paginação e filtros por nota, período e situação de resposta. Identificação de cliente/evento deve respeitar visibilidade pública e privada existentes.
2. Permita resposta pública do fornecedor autenticado, em campo/registro separado da avaliação. Defina política explícita de edição com autoria, data e histórico. Resposta não altera a nota nem sua elegibilidade.
3. Permita denúncia com motivo e descrição; anexos somente se houver armazenamento protegido. Denunciar não remove automaticamente a crítica. Evite denúncias duplicadas por operação e exponha ao fornecedor apenas o andamento compartilhável.
4. Reutilize uma fila de moderação existente; se não houver, implemente a menor fila restrita necessária para analisar e encerrar a denúncia com decisão fundamentada. Notas internas não ficam públicas. Toda ação relevante mantém histórico.
5. Exiba distribuição de estrelas e evolução por período com base e tamanho da amostra. Ausência de dados não significa ausência de problemas. Insights de IA não substituem os comentários e não podem inventar elogios ou falhas.
6. Inclua loading, vazio, falha com retry e envio pendente, além de acessibilidade e responsividade. A troca de sessão deve invalidar listas e comandos antigos.

## Aceite e validação

O fornecedor localiza uma crítica, lê seu contexto, responde, vê a resposta persistir após reabrir e pode denunciar sem editar/remover a avaliação. Outro fornecedor não responde em seu nome. A decisão de moderação fica rastreável e respeita a política de agregados. Um conjunto de notas conhecido produz distribuição e médias corretas.

Teste permissões, paginação, repetição de envio, concorrência de resposta/edição, filtros e visibilidade da moderação. Execute testes de regras/backend e widgets pertinentes. Registre resultados e evidências visuais em `docs/evidencias_validacao/operacao-fornecedor/05-gestao-reputacao.md`. Entregue o fluxo funcional, não apenas botões ou telas sem persistência.
