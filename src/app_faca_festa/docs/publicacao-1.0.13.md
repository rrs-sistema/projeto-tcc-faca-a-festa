# Publicação 1.0.13+15 — 15/10/2026

Web, instalador Windows e APK publicados no projeto Firebase `faca-a-festa`, com downloads no bucket próprio `faca-a-festa.firebasestorage.app`.

- [Web](https://faca-a-festa.web.app/)
- [APK Android](https://faca-a-festa.web.app/android/)
- [Windows](https://faca-a-festa.web.app/desktop/)

## Escopo

Entrega descrita em [calibração contextual](calculadora-calibracao-contextual.md): referências por papel e estado, faixa de compra com reserva, rendimento medido, pesos de público ajustáveis, registro privado após a festa e proposta de porção a partir de eventos comparáveis.

O motor registra versão 4. A Function `analisarCalculadoraFestaIA` foi publicada com prompt 1.4.0. O índice privado de consumo foi criado individualmente e confirmado `READY`, sem remoção de outros índices. O teste das regras existentes confirmou acesso pelo dono e rejeição de acesso por outra conta ou sem autenticação. As permissões não foram ampliadas.

Não foram inventados participantes, coeficientes para contextos sem referência nem medições reais de festas. A base proposta para preparo preserva o desperdício observado e desconta a sobra não servida. A mediana depende dos registros disponíveis e de adoção explícita; não é garantia de suficiência.

## Conferência

- 62 testes Flutter aprovados; TypeScript e testes do callable aprovados.
- Análise estática dos arquivos alterados sem problemas.
- Testes de regras do Firestore aprovados no emulador com Java 21.
- Builds release Windows, Web, APK e AAB concluídos.
- Publicador Android confirmou assinatura, pacote e versão do APK; assinatura JAR do AAB conferida.
- `node tool/verificar_publicacao.cjs 1.0.13 15` concluiu com código 0: versão web e manifests, páginas e appcast disponíveis, downloads completos, SHA-256/tamanho e assinatura Ed25519 do Windows válidos.
- Function sem autenticação retornou 401. Não houve geração autenticada com o provedor em produção nesta sessão.

Evidência local: `.dart_tool/publication-1.0.13-15/verified.json`. O estado do índice foi registrado em `.dart_tool/calculadora-consumo-index.json`.

| Artefato | Bytes | SHA-256 |
| --- | ---: | --- |
| Windows | 51891194 | `fa228099745d1519ebc77a009791ff9515c387fc0f7d8905243b83b0223bcc35` |
| APK | 103761676 | `0e77c61b5be92734a187f14054673ff1b03751e2e7449cd3f03e61e3b6f987b7` |
| AAB | 56648328 | `b8469670576cac58bd21b5e2a05f6e0b15ef210ddf7f41d91e2f0d5064c12224` |

O AAB local está em `release/play-store/FacaFesta_1.0.13+15.aab`; não foi submetido ao Play Console. Os testes móveis usam Flutter com repositórios de teste. Não houve instalação em aparelho físico ou ensaio real de consumo nesta sessão.
