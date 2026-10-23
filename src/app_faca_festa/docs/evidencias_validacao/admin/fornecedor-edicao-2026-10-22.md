# Edição administrativa de fornecedor

Data: 22/10/2026.

**Atualização:** o formulário simplificado descrito neste registro foi substituído pelo fluxo compartilhado de criação e edição. Consulte `fornecedor-fluxo-compartilhado-2026-10-22.md` para a implementação e validação atuais.

## Entrega

Foi adicionada a ação **Editar dados** no início das ações de cada fornecedor, na Gestão de Fornecedores. A ação só aparece para administrador ativo. O controller também valida a permissão antes de gravar.

O modal responsivo abre preenchido e permite editar razão social, CNPJ, e-mail comercial, telefone e descrição. O e-mail comercial não altera Firebase Auth nem o cadastro de acesso em `usuarios`. Campos de contato e CNPJ são opcionais, mas validados quando preenchidos. A razão social é obrigatória.

O desktop utiliza diálogo central; o celular utiliza painel com corpo rolável. Salvar, cancelar e fechar ficam separados da rolagem. O envio bloqueia novas ações até a resposta. Cancelar não grava; uma falha mantém os campos preenchidos e mostra uma mensagem no formulário.

## Persistência

O novo contrato `FornecedorDadosCadastrais` restringe a atualização a `razao_social`, `cnpj`, `email`, `telefone` e `descricao`. A chamada atravessa controller, use case, repository e datasource e usa `update` no documento existente em `fornecedor/{idFornecedor}`.

O fluxo não serializa o fornecedor inteiro, preservando proprietário, aprovação, status, categorias, serviços, banner, token, data e indicadores. Campos opcionais podem ser limpos explicitamente. Após a confirmação, a lista recebe os novos campos sobre a versão local mais recente e reaplica a ordenação; filtros continuam usando os dados atualizados. A auditoria existente recebe o evento `FORNECEDOR_EDITADO`.

As regras atuais de `fornecedor/{fornecedorId}` já autorizam atualização por `isAdmin()`; não foi necessário alterá-las. Não houve acesso a produção nem deploy de regras. A proteção do servidor foi inspecionada no código, não exercitada em emulador nesta execução.

## Validação

```powershell
flutter test --no-pub test/features/fornecedor/fornecedor_edicao_admin_test.dart test/features/fornecedor/fornecedor_repository_test.dart
```

Resultado: **16 testes aprovados**, sendo nove novos e sete existentes. Casos novos:

- Atualização limitada aos cinco campos e preservação dos demais dados, inclusive status alterado durante a gravação.
- Bloqueio de envio duplicado enquanto a confirmação está pendente.
- Falha sem alteração antecipada da lista e nova tentativa posterior.
- Bloqueio para fornecedor, outros perfis e administrador inativo.
- Validação de entrada na chamada direta ao controller.
- Troca de sessão durante a gravação sem repopular a nova lista.
- Botão real do cartão abre o formulário; salvar atualiza o cartão e a chamada ao datasource; ação some ao sair do perfil administrador.
- Campos preenchidos no desktop e cancelamento sem escrita.
- Campo inválido recebe erro e envio aguarda confirmação.
- Celular 360×800, fonte em 160% e teclado de 280 px mantêm as ações visíveis e o erro acessível por rolagem.

Análise estática dos nove arquivos novos/alterados, incluindo o teste: **sem ocorrências**.

Os testes exercitam as camadas reais do aplicativo com dublês apenas para sessão/serviços não usados e a fronteira do SDK Firestore. Não comprovam integração com Firebase real. Não foi executado teste no aparelho nem gerado novo instalador.
