# Fornecedor: fluxo compartilhado entre criação e edição

Data: 22/10/2026.

## Resultado

A ação **Editar dados** da gestão administrativa passou a abrir uma página que utiliza o próprio `RegisterFornecedorForm`, em modo de edição, preenchido com os registros existentes. O formulário simplificado anterior foi removido.

As etapas são Responsável, Empresa, Endereço e Atuação. Na criação, o primeiro título continua sendo Você. São os mesmos componentes, validações, seleção de imagem, endereço e seleção de categorias/subcategorias/serviços e tipos de evento do cadastro.

Na edição não são exibidos senha, Google ou aceite de política em nome de outra pessoa. Nome do responsável e e-mail comercial são editáveis; o e-mail de acesso é apresentado como informação. Não há criação de conta nem navegação para autenticação. A sessão administrativa é preservada.

## Leitura, edição e salvamento

- O cadastro completo é carregado pelos IDs do documento do fornecedor e do usuário vinculado. Inclui usuário, endereço principal, categorias e vínculos de serviço. Ausência de responsável ou falha de consulta é apresentada como erro recuperável, sem inventar registros.
- O formulário e os controladores do catálogo/endereço são instâncias locais. Cancelar não modifica a sessão de cadastro nem os dados persistidos.
- O banner existente é exibido; uma nova imagem utiliza o mesmo seletor do cadastro e só é enviada ao confirmar. O ID usado no upload é o do responsável pelo fornecedor. Uma falha após upload permite reutilizar a URL na tentativa seguinte; Storage e Firestore não participam de uma única transação, portanto pode sobrar arquivo sem vínculo se o salvamento for abandonado nessa situação.
- Fornecedor, nome/localização do responsável, endereço e vínculos são escritos em uma transação Firestore. Endereço e serviços existentes preservam seus IDs. Contato comercial não altera o e-mail de autenticação, senha, tipo de conta ou aceite legal.
- Preço, promoção, imagens e indicadores dos serviços existentes são preservados. Serviços desmarcados são inativados, sem exclusão do histórico. Novos vínculos utilizam o ID determinístico e a estrutura já empregada pelo cadastro. Duplicatas antigas não são reativadas em conjunto.
- Aprovação, situação operacional, avaliações e token do fornecedor não são sobrescritos. Revisão do cadastro e verificação do proprietário detectam outra edição completa ou mudança de vínculo; nesse caso é necessário reabrir os dados atuais.
- A lista e os filtros são atualizados após confirmação. Campos inválidos e falhas de salvamento mantêm o formulário aberto.

Também foram corrigidos problemas da seleção compartilhada: os serviços refletem a seleção real, podem ser desmarcados e selecionados novamente, não se duplicam na lista local e a subcategoria é associada à categoria correta.

## Validação

```powershell
flutter test --no-pub test/features/fornecedor/fornecedor_cadastro_fluxo_test.dart test/features/fornecedor/fornecedor_cadastro_transacao_test.dart test/features/fornecedor/fornecedor_edicao_admin_test.dart test/features/fornecedor/fornecedor_repository_test.dart
```

21 testes aprovados: seis do fluxo compartilhado, três da transação, cinco das proteções de edição cadastral e sete do repositório existente.

Os cenários percorrem as quatro etapas, alteram e salvam razão social, voltam entre etapas, cancelam, desmarcam/selecionam novamente serviço, simulam falha e nova tentativa, bloqueiam repetição enquanto aguardam confirmação e preservam a conta administrativa. O cadastro novo continua exibindo senha/Google. Foi exercitado celular de 360×800 com fonte em 160% e teclado de 280 px.

Os testes do datasource verificam escrita conjunta, falha de commit, revisão concorrente, troca de proprietário, preservação do e-mail de acesso e dos preços e endereços/vínculos existentes. O documento real prevalece sobre um identificador legado divergente armazenado nos campos.

Análise estática dos arquivos envolvidos: sem ocorrências. As regras atuais permitem ao administrador atualizar os documentos envolvidos e foram inspecionadas; não houve alteração de regras nem deploy.

## Limites

Os testes usam as camadas reais com dublês nas fronteiras de autenticação/persistência. Não substituem uma execução com Firebase real ou emuladores. Seleção/upload de imagem em aparelho e geração de novo instalador não foram executados nesta rodada. As capturas enviadas pelo usuário são referências do fluxo, não evidência de execução desta versão.
