# Correção do primeiro salvamento — 16/10/2026

## Defeito reproduzido

O botão Salvar grava diretamente no Firestore; não chama a função de análise da IA. `salvarSimulacao` consulta `calculadora_festa/{id}/itens` antes de criar o documento pai, para identificar itens antigos a remover. A regra publicada exigia acesso ao documento pai nessa leitura. Em uma primeira simulação, ele ainda não existe: mesmo o organizador correto recebia `permission-denied` antes de chegar ao batch de gravação.

A nova regressão reproduziu a negação usando as regras iguais às então publicadas. O teste anterior cobria criação conjunta de pai/itens, mas não a consulta anterior que o aplicativo realiza.

## Correção compatível com o app atual

Foi acrescentada uma autorização restrita para consulta de `itens` quando o pai ainda não existe e o identificador tem o formato já gerado pelo app: `calc_{evento}_{instante}`. A regra extrai o evento e verifica seu proprietário no Firestore. Não permite a consulta a outros organizadores, fornecedores ou usuários anônimos.

Se o documento pai já existe, sua autorização continua baseada no proprietário registrado, mesmo quando o nome do documento contém o código de outra festa. A exceção de primeiro salvamento não se aplica a subcoleções arbitrárias. A remoção de itens órfãos no mesmo primeiro batch segue a mesma verificação de propriedade.

O formato e o método de separação são verificados no emulador. A operação de strings está descrita na [referência oficial de Security Rules](https://firebase.google.com/docs/reference/rules/rules.String#split).

## Validação

- Falha anterior reproduzida na consulta prévia do primeiro salvamento.
- Consulta inicial seguida de criação do pai e item aprovada para o organizador.
- Outro organizador, fornecedor, usuário anônimo, evento inexistente e identificador sem formato válido bloqueados.
- Documento existente não muda de dono por seu prefixo.
- Itens órfãos do próprio evento podem ser conferidos e removidos no primeiro batch.
- Suítes Firestore de calculadora, tarefas e auditoria aprovadas.
- Verificações de backend/financeiro/autorização/fallback/limites aprovadas.

## Publicação

A correção de regras foi publicada no projeto `faca-a-festa`. A atualização pendente do prompt da IA (1.7.0) também foi publicada exclusivamente na função `analisarCalculadoraFestaIA`. Essa atualização não é a correção do botão Salvar.

Não houve publicação do aplicativo, alteração do evento real, criação de simulação de teste em produção, troca do proprietário do evento ou chamada paga de IA. A verificação autenticada do fluxo de salvamento foi feita no emulador; o organizador deve tentar novamente no aplicativo para confirmar sua sessão real.

Logs: `.dart_tool/calculadora-primeiro-save-antes.log`, `calculadora-primeiro-save-depois.log`, `calculadora-primeiro-save-deploy.log` e `calculadora-prompt-170-deploy.log`.

Confirmação pela API: ruleset `b04ab371-9061-40d2-8fc0-4fb9a316fe58`, publicado às 18:21:04 de São Paulo; conteúdo ativo igual ao arquivo local, SHA-256 `32b370ba3e3a75fefc858fe3977cbc894bd657cdef897d8381160a32cf6842d1`. Função `ACTIVE`, atualizada às 18:22:53. Verificação externa sem autenticação manteve rejeição de acesso (401 na função e 403 no documento operacional), sem escritas ou chamada ao provedor.
