# Retenção de instaladores

Gerar um build sem `--deploy` cria somente arquivos locais. O upload ao Cloud
Storage acontece com `--deploy` (ou `--publish` nos scripts de release).

Depois de um deploy do Hosting bem-sucedido, `build_production.py` executa a
retenção dos instaladores Windows e Android:

- Mantém o pacote apontado pelo catálogo público e dois builds anteriores.
- Preserva também pacotes criados há menos de sete dias, para permitir downloads
  iniciados antes da troca do catálogo. Builds superiores ao catálogo são
  preservados para não interferir em outra publicação em andamento.
- Considera somente os nomes exatos dos instaladores nos prefixos
  `desktop-faca-festa/releases/` e `android-faca-festa/releases/`, com a identidade
  esperada nos metadados. Não remove imagens, documentos ou dados de usuários.
- Confere o catálogo, o appcast Windows e os metadados do pacote atual. Catálogo
  indisponível/divergente ou pacote atual ausente cancela a limpeza.
- Antes de cada exclusão, relê o catálogo e exige a geração original do objeto.

Inspeção sem excluir:

```powershell
node tool/release_retention.cjs --dry-run
```

Limpeza explícita do acervo existente, com as mesmas verificações:

```powershell
node tool/release_retention.cjs --apply
```

É necessária uma credencial Google com acesso ao bucket do projeto. O relatório
lista objetos e bytes elegíveis, sem estimar valores de cobrança. Se a limpeza
falhar depois do deploy, a publicação já ocorreu: corrija o acesso/causa e repita
o comando de retenção, sem precisar reconstruir o aplicativo.

O Firebase Hosting ignora `desktop/packages/**` e `android/packages/**`: os
instaladores publicados são servidos pelo Storage, evitando cópias no Hosting.
O histórico de releases do Hosting é separado. Com `--apply`, o script também
limita o canal `live` a dois releases anteriores mais o atual (três no total),
usando a API do Firebase. Uma configuração existente mais restrita é preservada.
Sem `--apply`, informa a configuração encontrada e a mudança proposta. A remoção
do histórico excedente é gerenciada pelo Hosting; não altera o site publicado.

O bucket pode manter objetos excluídos durante o prazo de soft delete, informado
em `softDeleteRetentionSeconds` no relatório. Nesse caso a liberação de espaço
cobrado não é imediata. A política global de proteção do bucket não é alterada.

Referências: [histórico do Hosting](https://firebase.google.com/docs/hosting/manage-hosting-resources),
[soft delete do Storage](https://docs.cloud.google.com/storage/docs/soft-delete).
