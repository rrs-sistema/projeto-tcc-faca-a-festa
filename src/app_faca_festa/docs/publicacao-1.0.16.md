# Conclusão operacional 1.0.16+18 — 23/10/2026

Web, instalador Windows e APK publicados e verificados na versão **1.0.16+18**.
Esta entrega conclui as pendências identificadas no escopo de contratação,
financeiro e mediação, complementando a [publicação anterior](publicacao-1.0.15.md).

- [Aplicativo Web](https://faca-a-festa.web.app/)
- [Instalador Windows](https://faca-a-festa.web.app/desktop/)
- [APK Android](https://faca-a-festa.web.app/android/)

## Ajustes concluídos

- Comissão recebida separadamente, parcial ou integral, conciliada sem novo desconto da mesma parcela no repasse.
- Dossiê e central distinguem comissão, direito de repasse do fornecedor e saldo pendente. Comissão de responsabilidade do organizador integra o total a receber dele.
- Abertura de mediação transacional, protegida contra casos concorrentes duplicados e vínculos incorretos.
- Decisão obrigatória antes do encerramento; decisão de caso encerrado preservada, com possibilidade de abrir outro caso justificado.
- Regularização administrativa da execução contestada após mediação encerrada, com motivo, confirmação e compatibilidade com a decisão registrada.
- Retirada de retenção exige confirmação explícita. Outra mediação aberta ou transferência em processamento impede a regularização.
- Resolução revoga a autorização antecipada anterior e cancela reservas pendentes. Novo repasse exige nova conferência e, antes da finalização do evento, nova autorização do organizador.
- Acesso do dossiê à intermediação com os identificadores da contratação preenchidos.
- Consultas de recebimentos, alocações e repasses sem os antigos cortes por contrato/evento que poderiam truncar os saldos. A central mantém sua paginação e identificação da amostra consultada.

Permanece a regra: pagar o fornecedor somente após evento finalizado ou autorização
explícita do organizador, com contratação ativa, comissão consistente, dinheiro
conferido/alocado e ausência de bloqueios. A resolução de mediação não executa
pagamento nem reembolso. A transferência bancária continua manual e sua confirmação
exige referência ou comprovante. Nenhum caso, recebimento ou pagamento real foi
alterado para testar esta publicação.

## Backend

11 Functions publicadas no projeto `faca-a-festa`, região `southamerica-east1`,
confirmadas como `ACTIVE`:

`resolverExecucaoMediacao`, `abrirCasoMediacao`, `abrirCasoMediacaoParte`,
`registrarDecisaoCaso`, `fecharCasoMediacao`, `prepararRepasseFornecedor`,
`confirmarRepasseManual`, `consultarExtratoIntermediacao`,
`autorizarRepasseOrganizador`, `consultarCentralContratacoes` e
`consultarDetalheContratacao`.

Chamadas anônimas a `resolverExecucaoMediacao`, `prepararRepasseFornecedor`,
`confirmarRepasseManual`, `autorizarRepasseOrganizador` e
`cancelarRepassePendente` retornaram HTTP 401. As regras publicadas na entrega
anterior continuam aplicáveis; esta etapa não introduz escrita financeira pelo cliente.

## Validação

- TypeScript compilado e análise Dart dos cinco arquivos de interface/controle alterados sem problemas.
- 124 testes Flutter existentes aprovados, mais o novo teste de tela da resolução de mediação.
- Integração no Firestore Emulator aprovada: comissão externa parcial/integral, comissão paga pelo organizador, saldos do dossiê, abertura concorrente de mediação, decisão/encerramento, permissões, bloqueios, cancelamento de reservas, revogação e renovação da autorização, idempotência e regras.
- Dois testes do processo de build aprovados.
- Builds release Windows, Web, APK e AAB concluídos.
- Publicador Android verificou assinatura, pacote e versão do APK. AAB aprovado pelo `jarsigner -verify`.
- `node tool/verificar_publicacao.cjs 1.0.16 18` terminou com código zero: versão Web, manifests, páginas, appcast, downloads completos, tamanhos, SHA-256 e assinatura Ed25519 Windows conferidos.

| Artefato | Bytes | SHA-256 |
| --- | ---: | --- |
| Windows | 52684256 | `5957db155daf7a0671877eb13ce054402870a3e31b55b6f119369e4232ff07cd` |
| APK | 113578142 | `513a3a67e121b4f10840967b1c8b359392c46670a5f3532292ad001672a76aa3` |
| AAB | 60899270 | `c5a4a721a5c827c766db0778db6bed2278de726d51b513c32f39a86750895015` |

Evidências em `.dart_tool/publication-1.0.16-18/backend-verified.json` e
`.dart_tool/publication-1.0.16-18/verified.json`. O AAB está em
`release/play-store/FacaFesta_1.0.16+18.aab`, sem envio ao Play Console.
O aplicativo em uso não foi fechado nem atualizado automaticamente.

Orientações em [operação de contratação e repasses](operacao-contratacao-repasses.md).
