# Entrega operacional 1.0.15+17 — 23/10/2026

Backend publicado no projeto `faca-a-festa`, região `southamerica-east1`.
Web, instalador Windows e APK publicados e verificados na versão **1.0.15+17**.

- [Aplicativo Web](https://faca-a-festa.web.app/)
- [Instalador Windows](https://faca-a-festa.web.app/desktop/)
- [APK Android](https://faca-a-festa.web.app/android/)

## Contratação e repasses

- Fechamento de cotação protegido contra contratações duplicadas concorrentes.
- Comissão calculada a partir da obrigação e da política aplicada ao contrato.
- Autorização antecipada exclusiva do organizador proprietário, com motivo e possibilidade de revogação.
- Repasse condicionado a evento finalizado ou autorização explícita, saldo conferido/alocado e política ativa.
- Mediação, contestação e execução cancelada bloqueiam autorização e confirmação.
- Confirmação manual exige referência da transferência; retenção da comissão registrada uma única vez.

Foram publicadas 14 Functions do fluxo, incluindo as novas
`autorizarRepasseOrganizador` e `cancelarRepassePendente`, e as regras do Firestore.
Todas foram confirmadas como `ACTIVE`. Chamadas anônimas às quatro operações
críticas de repasse retornaram HTTP 401.

Não havia política de repasse cadastrada. Foi criada
`integral-evento-ou-autorizacao-v1`, ativa, sem repasses parciais, com registro
de auditoria da publicação. A comissão existente de 5%, paga pelo fornecedor,
foi preservada. A configuração não executa transferências.

Uma consulta somente de leitura encontrou uma contratação com comissão
consistente, fornecedor vinculado, sem recebimento confirmado e bloqueada
por mediação. Nenhum pagamento, recebimento, contratação ou caso real foi
alterado para testar a publicação.

## Validação

- Cenários no Firestore Emulator: fechamento e reserva concorrentes, comissão de 8% no fechamento real, taxa enviada pelo cliente ignorada, autorização/revogação, cancelamento de execução, mediação, retenção, pagamentos parciais, idempotência e regras de acesso.
- 124 testes Flutter de financeiro/administração aprovados na implementação.
- Suítes financeiras do backend e quatro suítes existentes de regras aprovadas.
- Análise Dart sem problemas e TypeScript compilado.
- Dois testes do processo de build aprovados.

O build Android exigiu preservar fontes de ícones dinâmicos. O processo de
produção passou a usar `--no-tree-shake-icons` para APK e AAB, como já fazia
no build Web.

- Builds release Windows, Web, APK e AAB concluídos.
- APK validado pelo publicador: assinatura, pacote e versão; AAB com assinatura JAR verificada.
- `node tool/verificar_publicacao.cjs 1.0.15 17` concluiu com código zero: versão Web, manifests, páginas, appcast, downloads completos, tamanhos, SHA-256 e assinatura Ed25519 Windows conferidos.

| Artefato | Bytes | SHA-256 |
| --- | ---: | --- |
| Windows | 52674940 | `1c0905cbff4adaee032c6867dbced100d4e2b3708ce9e3659874bc34ade73f9a` |
| APK | 113561758 | `a96f48f30e962de7379ce6d4854165ee20bb72fad57b2ba0df2e710c9cf3ac41` |
| AAB | 60878889 | `373d1cc8c327b455ab29192f83ed7324386f75558a54bcd602d8d202af58d3ff` |

Evidências em `.dart_tool/publication-1.0.15-17/backend-verified.json` e
`.dart_tool/publication-1.0.15-17/verified.json`. O AAB local está em
`release/play-store/FacaFesta_1.0.15+17.aab` e não foi enviado ao Play Console.
O fluxo operacional está descrito em [operação de contratação e repasses](operacao-contratacao-repasses.md).

Não houve instalação nem reinicialização automática do aplicativo aberto,
submissão ao Google Play ou transferência bancária.
