# Publicação 1.0.12+14 — 15/10/2026

Web, Windows e APK publicados e verificados no projeto Firebase `faca-a-festa`.

- [Web](https://faca-a-festa.web.app/)
- [APK Android](https://faca-a-festa.web.app/android/)
- [Windows](https://faca-a-festa.web.app/desktop/)

## Escopo

Correções descritas em [revisao-realismo-calculadora-2026-10-15.md](revisao-realismo-calculadora-2026-10-15.md): divisão e escala de duração somente com ativação explícita; número de serviços por item; estado e papel do alimento; conta detalhada; porções em g/ml visíveis; comparação sem custo zero fictício. O catálogo continua sendo uma referência inicial, sem validação empírica do consumo do evento concreto.

O motor registra versão 3 no contexto das novas simulações. A Function `analisarCalculadoraFestaIA` foi atualizada com prompt 1.3.1. Não houve migração dos documentos particulares dos eventos nem substituição dos coeficientes publicados por números arbitrários. Catálogos existentes sem os novos campos usam os padrões explícitos do cliente: um serviço, sem divisão e sem escala de duração. Simulações salvas conservam seus resultados até um recálculo.

## Verificação

- 48 testes Flutter aprovados e análise estática dos arquivos alterados sem problemas.
- TypeScript e testes de planejamento/callable aprovados.
- Compilações release Windows, Web, APK e AAB concluídas.
- Publicador Android verificou assinatura, pacote e versão do APK; assinatura JAR do AAB verificada.
- `node tool/verificar_publicacao.cjs 1.0.12 14` concluiu com código 0. Confirmou versão web/manifests, disponibilidade das páginas/appcast, downloads completos no bucket próprio, tamanho/SHA-256 e assinatura Ed25519 do Windows.
- Function pública sem autenticação retornou 401, conforme esperado. Não houve geração autenticada com o provedor em produção nesta sessão.

Evidência local: `.dart_tool/publication-1.0.12-14/verified.json`.

| Artefato | Bytes | SHA-256 |
| --- | ---: | --- |
| Windows | 51858969 | `d3f03272359d55100681869a3ddcfd8cccabb075aa13d46c75e2460686caf881` |
| APK | 103417468 | `a8e72da6b24965ee7113cb72c8c37e8a967b2dfa5be5589cfc9d799e6757a5ac` |
| AAB | 56537758 | `0d420eb258c3e8eb73227005100efb81c47c00a4a3a9fc0c73ba28e818e9188f` |

O AAB está em `release/play-store/FacaFesta_1.0.12+14.aab`; não foi submetido ao Play Console. A jornada móvel usa a tela Flutter com repositórios de teste; não houve instalação em aparelho físico nem ensaio real de consumo.
