# Entrada inteligente e fechamento das pendências técnicas

Esta entrega amplia o trabalho das fases anteriores. A publicação do aplicativo continua suspensa por solicitação do usuário. A busca externa de preços permanece fora do escopo combinado.

## Experiência

Na Calculadora, em Próximas ações, **Interpretar pedido ou documento** aceita um pedido em linguagem natural, texto colado, TXT, PDF ou imagem (PNG/JPEG/WebP). O diálogo de planejamento rápido também permite continuar em **Interpretar com IA**, reaproveitando o texto.

O organizador prepara uma leitura, recebe propostas preenchidas, confere os trechos que as sustentam e aplica o conjunto selecionado. Não há gravação financeira durante a leitura. As perguntas restantes tratam de lacunas materiais; ações prontas podem ser aplicadas sem preencher todos os detalhes da entrada.

Exemplos: “Comprei 5 kg de arroz cru para o almoço; o preço é R$ 6/kg”, “Tenho 3 kg em estoque”, “A cotação da decoração é R$ 500, ainda não contratei”, ou uma receita com rendimento e ingredientes explicitamente informados.

## Efeitos distintos

| Entrada | Efeito após revisão |
| --- | --- |
| Público, fonte dos convidados, duração, perfil | Configuração privada do planejamento, recuperável ao reabrir |
| Limite da festa | Orçamento total do evento |
| Quantidade necessária | Quantidade final planejada; não confirma compra |
| Comprei X | Acrescenta à quantidade efetivamente comprada |
| Já tenho X comprados no total | Substitui apenas o total comprado, de forma explícita |
| Estoque | Novo lote central, sem reserva automática |
| Preço por unidade | Regra do item e refeição correspondentes; não presume preço de mercado |
| Receita | Ficha técnica com rendimento, ingredientes, medidas e estados informados |
| Cotação | Orçamento em negociação, sem contratação ou pagamento |
| Nota/despesa | Custo registrado, com pagamento separado |
| Pagamento informado/comprovado | Lançamento vinculado a orçamento identificado, limitado ao saldo |

## Proteções

- Somente o organizador acessa ou aplica a revisão. A checagem ocorre antes do provedor externo.
- O modelo propõe dados estruturados; o servidor valida destinos, medidas, valores, regras e dependências. Documento é dado não confiável, nunca autorização para executar instruções nele escritas.
- Cotação classificada como cotação não produz compra, despesa ou pagamento, mesmo que o modelo proponha isso.
- Não há conversão presumida de cru para pronto ou de pacote para kg. Medida ambígua permanece pendente.
- Revisão vinculada ao contexto e válida por 30 minutos. Alteração concorrente nos dados exige nova leitura.
- Gravação do conjunto é transacional. Falha em pagamento, por exemplo, desfaz também as demais ações selecionadas daquela tentativa.
- Repetição da mesma aplicação não duplica os registros. Hash de arquivo/texto e identificação do documento ajudam a reconhecer ações já lançadas e permitem aplicar partes restantes.
- Documento sem identificação única exige conferência de duplicidade. Nomes, números ou extração divergentes entre digitalizações continuam exigindo atenção; não se promete identificação universal de toda duplicata.
- O original do arquivo não é persistido no planejamento. A revisão guarda propostas e trechos de evidência para conferência. O envio à IA ocorre somente no comando de preparar a leitura, com aviso na tela.
- Arquivos limitados a 4 MB; texto a 16 mil caracteres; até 30 ações por revisão. Contexto do evento é limitado para manter a operação verificável.

## Validação e limites

Os testes do provedor usam exclusivamente documentos sintéticos e são separados dos testes determinísticos de transação. O roteiro de aparelho utiliza outro pacote Android, conta fictícia e emuladores locais. Não lança dados de teste no evento real.

- Suíte completa: **572 testes aprovados** (`.dart_tool/entrada-suite-completa.log`). Depois dela, mais dois casos foram acrescentados e os **9 testes dirigidos** da entrada passaram: vínculo de referência por refeição, seleção parcial, repetição após erro, TXT, contexto alterado, texto ampliado com teclado e preservação de edições locais (`.dart_tool/entrada-flutter.log`).
- Servidor: **48 verificações** da entrada aprovadas, incluindo autorização, concorrência, idempotência, importação parcial, documento alterado, pagamento excedente, orçamento já pago, estoque e ficha técnica (`.dart_tool/entrada-emulator-final.log`). A repetição de um pedido já reconhecido consulta o recibo antes de recapturar o evento inteiro.
- Regressão: **45 verificações** do executor/pós-evento e regras da calculadora/tarefas aprovadas (`.dart_tool/entrada-regressoes-emulator.log`). Inclui preservação da configuração recebida por texto.
- Provedor real: texto, PDF, PNG e documento colado/TXT sintéticos verificados, incluindo instruções adversariais dentro do documento (`.dart_tool/entrada-modelo.log`). O modelo anterior falhou no caso de imagem e não foi adotado como padrão desta função. A leitura usa `gpt-5-mini`, configurável por `MODELO_IA_CALCULADORA_ENTRADA`; resultados destes casos não demonstram imunidade geral a instruções adversariais.
- Análise estática: nenhuma ocorrência nova; permanece uma informação preexistente de importação redundante em `dossie_titular_documento.dart` (`.dart_tool/entrada-analysis.log`). `git diff --check` aprovado.
- Publicados: `interpretarEntradaCalculadora`, `aplicarEntradaCalculadora`, atualização de `aplicarPlanoCalculadora` e regras do Firestore. Três funções `ACTIVE`, região `southamerica-east1`; três chamadas sem login retornaram `401 UNAUTHENTICATED`. Evidências: `.dart_tool/entrada-deploy.log`, `.dart_tool/entrada-deploy-aplicacao-final.log` e `.dart_tool/entrada-smoke-publicado.json`.
- **Android físico SM G990E / Android 16: teste aprovado** (`.dart_tool/entrada-aparelho.log`). SDK Firebase real com conta fictícia: autenticação, leitura pela interface, revisão antes de gravar, compra de 2 → 7 kg, preservação da quantidade final de 10 kg e da confirmação anterior, recusa de duplicidade e recusa da leitura depois de sair da conta. O extrator desse teste é determinístico; a leitura por IA real está coberta separadamente nos quatro formatos descritos acima. Isso valida a nova entrada no aparelho, não certifica todas as jornadas de produção do aplicativo.

Não houve publicação do aplicativo ou hosting, nem gravação de dados sintéticos no evento real. A validação autenticada no aparelho utiliza exclusivamente o pacote de QA e o projeto demo.

### Reprodução dos testes

```powershell
flutter test test
flutter test test/features/calculadora/entrada_inteligente_test.dart
npm --prefix functions run build
npm --prefix functions run check:calculadora

# Somente exemplos sintéticos; este comando usa o provedor real.
node functions/scripts/testEntradaModelo.js --sintetico

# Emuladores locais; não usar projeto de produção.
firebase emulators:exec --config firebase.calculadora-test.json --only "firestore,auth" --project demo-calculadora-entrada "node functions/scripts/testEntradaCalculadoraEmulator.js"
```

O roteiro `functions/scripts/testEntradaAparelho.js` prepara conta/evento fictícios, restaura os encaminhamentos `adb reverse` e executa `integration_test/entrada_inteligente_aparelho_test.dart` no dispositivo de QA. Seu extrator é determinístico para separar transporte/gravação dos testes do provedor. O wrapper callable, o SDK Firebase, a autenticação e a transação são reais. Ele não é exportado em `index.ts` nem publicado no servidor.

Referências de implementação: [entrada de arquivos na Responses API](https://developers.openai.com/api/docs/guides/file-inputs), [saída estruturada](https://developers.openai.com/api/docs/guides/structured-outputs) e [modelo](https://developers.openai.com/api/docs/models/gpt-5-mini).

## O que não pode ser comprovado por implementação

A infraestrutura do piloto e da revisão pós-evento está implementada, mas a redução de 70%–80% precisa de observação com participantes reais. A calibração de consumo precisa de pessoas presentes, preparado, sobra e falta observados depois do evento de 23/10/2026. Dados sintéticos validam software, não comprovam suficiência de porções nem resultados empíricos.
