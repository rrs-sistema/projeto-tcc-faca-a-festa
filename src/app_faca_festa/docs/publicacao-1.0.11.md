# Publicação 1.0.11+13

Verificação pública concluída em 15/10/2026. Web, Windows e APK disponibilizados no projeto Firebase `faca-a-festa`, com downloads no bucket próprio `faca-a-festa.firebasestorage.app`.

- [Aplicação web](https://faca-a-festa.web.app/)
- [Instalador Windows](https://faca-a-festa.web.app/desktop/)
- [APK Android](https://faca-a-festa.web.app/android/)

## Verificação

`node tool/verificar_publicacao.cjs 1.0.11 13` terminou com código 0. Confirmou versão web e manifests, disponibilidade das páginas e appcast, download completo dos pacotes, tamanho e SHA-256 e assinatura Ed25519 do Windows. Evidência local em `.dart_tool/publication-1.0.11-13/verified.json`.

| Artefato | Bytes | SHA-256 |
| --- | ---: | --- |
| Windows | 51857853 | `d1659f79210be41cc2cbbf6926ce816a4f6feb7a5b76c327674023b6052664ed` |
| APK | 103401020 | `a3568457d36a384c7f50c6fc8c3771d58c99bbae7e3e34a0b0cd5c97e7e95bf2` |
| AAB | 56523038 | `cc4a221ea2d87a74b17d648364fe204b91cc89743e1680791c1f11a21d585bcc` |

O publicador Android validou assinatura, pacote `com.rrs.system.technology.facafesta` e versão do APK. O AAB local `release/play-store/FacaFesta_1.0.11+13.aab` passou pela verificação de assinatura JAR; não foi submetido ao Play Console.

A Function `analisarCalculadoraFestaIA` foi publicada em `southamerica-east1`, com prompt 1.3.0 e timeout do provedor de 45 segundos. A chamada pública sem autenticação retornou 401, como esperado. Não houve teste de geração autenticada contra o provedor em produção.

## Implementação e testes

As entregas e premissas estão em [implementacao-calculadora-completa.md](implementacao-calculadora-completa.md). Foram aprovados 44 testes Flutter, análise estática dos arquivos alterados, compilação TypeScript e testes do callable e seus helpers. Web, Windows, APK e AAB compilaram com a versão final.

O catálogo inicial foi criado com cinco referências de consumo e três orientações editoriais. O publicador preserva documentos existentes; a repetição em modo de simulação confirmou os 13 documentos preservados. Dados particulares de cardápios não foram migrados.

A jornada móvel exercita a tela Flutter real com repositórios de teste e dimensões de celular, incluindo teclado e texto ampliado. Não havia aparelho Android físico ou emulador disponível; instalação e uso em dispositivo real permanecem sem validação nesta sessão.
