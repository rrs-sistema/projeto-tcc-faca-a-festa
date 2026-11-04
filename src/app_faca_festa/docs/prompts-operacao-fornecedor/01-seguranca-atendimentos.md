# Prompt 01 — Privacidade e integridade dos atendimentos

Implemente a proteção dos atendimentos do fornecedor no Faça a Festa. Trabalhe no repositório `D:\repository\unicesumar\tcc\app\src\app_faca_festa`, Windows/PowerShell, Flutter/Dart/GetX e Firebase/Cloud Functions TypeScript. Este prompt é autocontido e solicita implementação, não somente análise.

Antes de editar, leia AGENTS.md aplicáveis, examine o Git e reconfirme os achados. Preserve alterações preexistentes e reutilize a arquitetura atual. Não faça deploy, commit, push, migração em produção nem envie mensagens externas. Use dados sintéticos e emuladores para testes de integração.

## Problema observado

Em `firestore.rules`, a regra recursiva de `mensagens` permite leitura a qualquer usuário autenticado. Em `cotacao/{cotacaoId}/fornecedores/{fornecedorId}`, uma regra genérica de subcoleções concede update/delete aos participantes e pode também alcançar mensagens. Regras Firestore coincidentes são permissivas por união; uma regra específica restritiva não anula outra concessão.

## Implementação

1. Mapeie todos os caminhos de chat, collectionGroup, listeners, mensagens de sistema e marcação de leitura. Inspecione `lib/data/datasources/remote/cotacao_remote_datasource.dart`, `lib/presentation/modules/fornecedor/pages/chat/` e as Functions de cotação.
2. Restrinja leituras aos participantes reais da conversa e aos papéis de suporte explicitamente autorizados pelo modelo existente. Estar no mesmo evento, ser fornecedor ou conhecer o ID não concede acesso. Não crie acesso administrativo irrestrito por conveniência.
3. Remova concessões sobrepostas que permitam editar texto/autoria ou apagar histórico. Permita apenas a alteração mínima de leitura ao destinatário autorizado, sem modificar o restante da mensagem. Mensagens de sistema são gravadas por backend autorizado.
4. Valide remetente pela sessão, vínculo com a cotação, tamanho e campos permitidos. Descubra a política de conversa após contratação: mantenha a comunicação operacional autorizada; não reabra conversa cancelada contrariando regra vigente.
5. Adapte consultas e índices ao acesso restrito. Não resolva permission-denied ampliando leitura geral. Ao trocar de sessão, cancele listeners e descarte resultados antigos. Caso haja anexos, proteja também o acesso aos arquivos e seus metadados.

## Aceite e validação

Com dois clientes, dois fornecedores e um usuário sem vínculo, teste leitura direta e consultas, envio, falsificação de remetente, edição, exclusão e leitura de mensagens de sistema. O cliente A e fornecedor A conversam normalmente; cliente B e fornecedor B não acessam a conversa A. Um participante não altera mensagens antigas do outro. Marcar como lida preserva texto, autor e datas originais.

Adicione testes de regras executados no emulador, cobrindo explicitamente regras sobrepostas e collectionGroup. Execute os testes pertinentes e análise estática do código alterado. Registre comandos, resultados, índices e limitações em `docs/evidencias_validacao/operacao-fornecedor/01-seguranca-atendimentos.md`. Entregue arquivos alterados, comportamento final e resultados reais, distinguindo testes executados de verificações pendentes.
