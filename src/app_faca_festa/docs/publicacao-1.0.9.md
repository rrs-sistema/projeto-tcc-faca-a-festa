# Publicação 1.0.9+11 — 14/10/2026

Projeto Firebase: `faca-a-festa`.

- Web: https://faca-a-festa.web.app/
- Windows: https://faca-a-festa.web.app/desktop/
- Android APK: https://faca-a-festa.web.app/android/
- AAB para envio à Play Store: `release/play-store/FacaFesta_1.0.9+11.aab`. O pacote foi gerado e assinado; não houve envio ao Play Console.

Foram publicadas as regras do Firestore, a Function `analisarCalculadoraFestaIA` e a dependência da tela inicial `obterEstatisticasPublicas`, ambas em `southamerica-east1`.

## Verificação

A versão pública em `/version.json` é 1.0.9, build 11. Os catálogos Windows/Android indicam a mesma versão e `published: true`. As páginas de download e o appcast Windows responderam corretamente. Ambos os pacotes foram baixados novamente do Storage e conferidos por tamanho e SHA-256.

| Pacote | Bytes | SHA-256 |
| --- | ---: | --- |
| Windows | 51386750 | c3aeb8e2c5f2e38ffffe805806300a5102227c060e3a5f96e6b031d3df335277 |
| APK | 102480925 | 2e206cd62ece3aabce3aa7870e7971e4b0bcb6d2beabe1d83b0cf2f41501fd6c |
| AAB | 55722228 | 410eb5a160a201df19af1dda517c5a7eecddce59846a2dfc0e5fd0c26ff4cbfb |

A assinatura Ed25519 do Windows foi verificada com a chave pública incorporada. As assinaturas APK/AAB também foram verificadas. A Function da calculadora devolveu 401/UNAUTHENTICATED sem login; as estatísticas públicas devolveram 200 com somente os campos agregados previstos.

A instalação real e o ciclo de atualização em um dispositivo ficam para validação no terminal/aparelho piloto.

## Próximas publicações

`python build_production.py --windows --web --apk --bundle --deploy` usa a mesma versão para os quatro builds e publica os pacotes imutáveis no Storage e seus catálogos no Hosting. AAB é preparado localmente para envio à loja. O publicador Android valida assinatura, pacote e versão antes de upload. Uma publicação sem APK preserva o catálogo Android atual.

Para retomar após upload e antes de Hosting, reutilize os mesmos arquivos de pacote e catálogos; não recompile um build já distribuído. As Functions e as regras do Firestore têm deploy separado.
