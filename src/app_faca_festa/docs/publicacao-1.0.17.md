# Ergonomia administrativa — 1.0.17+19

Publicação de 23/10/2026. Web, Windows e APK disponíveis e verificados na versão
**1.0.17+19**, projeto `faca-a-festa`.

- [Web](https://faca-a-festa.web.app/)
- [Instalador Windows](https://faca-a-festa.web.app/desktop/)
- [APK Android](https://faca-a-festa.web.app/android/)

## Entrega

- Ajuda contextual recolhível nas telas de financeiro, comissões, contratações, detalhe/mediação e recebimentos/repasses.
- Resumo financeiro antes dos filtros, busca de fornecedor por nome e seleção de datas por calendário.
- Tabelas com separação entre colunas e rótulos explícitos para situação do evento, pagamentos registrados e saldo do contrato.
- Oportunidades apresentadas como estimativas, sem dívida confirmada ou acesso direto ao repasse.
- Contratos e oportunidades com filtros explícitos e ações identificadas por finalidade.
- Detalhe organizado em Resumo, Financeiro e Mediação e histórico, com orientação do próximo passo e condições de repasse retornadas pelo servidor.
- Registro de recebimento de comissão separado da consulta, com formulário curto e revisão explícita antes da gravação.
- Gestão de políticas como área secundária na tela de comissões.

Descrição e critérios em [implementação de ergonomia](ergonomia-admin-implementacao.md).

As regras financeiras, as Functions e as permissões não foram alteradas nesta
entrega. Nenhuma transferência ou decisão em caso real foi executada para validar
a interface. O aplicativo em uso não foi fechado nem instalado automaticamente.

## Validação

- 138 testes Flutter de administração/financeiro aprovados, incluindo 13 cenários novos de ergonomia.
- Após os últimos rótulos, os 18 testes diretamente relacionados a dashboard/ergonomia passaram novamente.
- Análise Dart dos sete arquivos de implementação sem problemas.
- Lista em 360, 768, 1366 e 1920 pixels, em escala de texto normal e 200%; seleção de fornecedor em desktop e celular com texto ampliado.
- Revisão, cancelamento e falha de recebimento; valor em centavos; distinção de oportunidade/contrato; ajuda explícita; resolução de mediação preservada.
- Capturas de widgets reais com dados fictícios inspecionadas.
- Windows, Web, APK e AAB compilados em release.
- APK com assinatura, pacote e versão conferidos pelo publicador; AAB aprovado por `jarsigner -verify`.
- `node tool/verificar_publicacao.cjs 1.0.17 19` concluído com código zero: versão Web, manifests, páginas, appcast, downloads completos, tamanhos, hashes e assinatura Ed25519 Windows.
- Cinco operações sensíveis de repasse/mediação retornaram HTTP 401 sem autenticação.

| Artefato | Bytes | SHA-256 |
| --- | ---: | --- |
| Windows | 52689842 | `2d923004ce72cae27575cf5c112af61eb6a26268d618e9aaebf668a7cab68b98` |
| APK | 113610910 | `734d11b8045c9230a9130d490376c0d660c59dc53aa5e37a8818ef0af1c324f9` |
| AAB | 60949237 | `12738a6043f344a6973cfa6a5b8b70d3e8cd01cb09e6e3db388200313dd18b75` |

Evidências locais em `.dart_tool/publication-1.0.17-19/verified.json`,
`ui-verified.json` e `auth-verified.json`.
Capturas em `.dart_tool/capturas-ergonomia` e `.dart_tool/capturas-comissoes`.
App Bundle local em `release/play-store/FacaFesta_1.0.17+19.aab`, sem envio ao Play Console.
