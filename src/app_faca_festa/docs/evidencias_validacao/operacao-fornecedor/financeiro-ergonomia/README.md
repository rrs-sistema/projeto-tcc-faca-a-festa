# Clareza financeira para fornecedores — 27/10/2026

## Decisões de ergonomia e linguagem

As telas existentes foram preservadas. O planejamento agora inicia pelos valores de entradas/saídas; filtros e explicações ficam recolhidos, disponíveis por toque/teclado. Valores têm maior destaque que rótulos. A página principal substitui termos como Fechado, Não alocado e Lançar por Total contratado, Recebido sem contrato definido e Registrar.

As contas mostram a ação, descrição, situação legível, evento, vencimento e valor pendente em destaque. Códigos internos de situação/origem não aparecem na leitura principal; identificadores e histórico ficam em uma expansão. Ausência de vencimento aparece como Data a definir e não como atraso. Não há alteração de cálculo, confirmação de pagamento, autorização, exportação ou persistência financeira.

A consulta de planejamento inclui nomeEvento usando o resolvedor de nomes existente e o documento de evento que já era lido na mesma transação autorizada. Não adiciona consulta pública nem expõe orçamento global. Sem nome disponível, a interface indica Evento sem nome e preserva o ID nos detalhes. Registros legados sem nome podem exigir identificação pelos detalhes; nenhum nome é inventado.

## Arquivos desta alteração

- lib/presentation/modules/financeiro/pages/financeiro_fornecedor_page.dart
- lib/presentation/modules/financeiro/pages/planejamento_financeiro_page.dart
- functions/src/services/financeiro/planejamentoFornecedorService.ts
- functions/scripts/testPlanejamentoFornecedorEmulator.js
- test/features/planejamento/planejamento_financeiro_test.dart
- test/features/financeiro/financeiro_contratos_unificado_test.dart

## Verificações reais

- `flutter test test/features/planejamento/planejamento_financeiro_test.dart test/features/financeiro/financeiro_contratos_unificado_test.dart`: **21 testes aprovados**, incluindo comparação das imagens sem update-goldens, filtros aplicados, CSV idêntico ao autorizado, troca de sessão, indisponibilidade, recebimento parcial e conciliação.
- Novos testes visuais: 390x844 com fonte1,3 e 1280x1200 com fonte1,0. Conferem contexto legível, ausência de códigos técnicos na leitura principal, expansão dos identificadores e ausência de overflow. Regressão existente também cobre financeiro em360 e1200 pixels.
- `dart analyze` das duas páginas e do teste de planejamento: **No issues found**.
- `npm --prefix functions run build`: aprovado.
- JDK21 local e `firebase emulators:exec --config firebase.operacao-test.json --project demo-planejamento-fornecedor --only firestore "node functions/scripts/testPlanejamentoFornecedorEmulator.js"`: **exit0**, assertiva nova do nome do evento, R$1.992,50 de resultado direto e R$600 de movimento, concorrência, estorno, estoque, filtros, autorização e CSV.
- `firebase deploy --project faca-a-festa --only functions:consultarPlanejamentoFornecedorFn --non-interactive`: **Successful update operation; Deploy complete**. Publicação restrita à consulta para disponibilizar o nome do evento; nenhuma migração ou comando financeiro real executado.

A primeira geração das imagens usou a fonte de teste padrão; foi substituída por Poppins e MaterialIcons locais e as imagens foram regeneradas/inspecionadas. Durante a reorganização, os testes foram atualizados para localizar os novos rótulos e rolar até filtros recolhidos; as verificações financeiras foram preservadas. Os logs finais anexos são das execuções aprovadas.

## Evidências visuais

Imagens atuais geradas por widget tests com dados sintéticos, não capturas de produção:

- [Desktop](../financeiro-ergonomia-desktop.png)
- [Celular com fonte ampliada](../financeiro-ergonomia-celular.png)
- [Conta no celular](../financeiro-ergonomia-contas-celular.png)
- [Conta no desktop](../financeiro-ergonomia-contas-desktop.png)

Não foi realizado estudo de usabilidade com fornecedores reais, leitor de tela externo ou teste autenticado no navegador do usuário. O Hosting não foi publicado; a interface deve ser atualizada no Flutter local. Os dados e regras de negócio preexistentes continuam preservados.
