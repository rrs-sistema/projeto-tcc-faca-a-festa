# Calculadora — personalização, revisão e fechamento das pendências técnicas

Implementação local de 17/10/2026. Este relatório complementa as entregas 0, 1 e 2. Nenhum dado do evento real foi escrito. Pesquisa externa de preços e publicação permanecem fora desta execução.

## O que mudou para o organizador

| Caminho | Comportamento |
| --- | --- |
| Sugestões → Próximas ações → Planejar por texto | Prepara público, fonte de convidados, duração e perfil em conjunto. Mostra o efeito antes de usar. Não executa compras ou pagamentos. |
| Outras opções → Minhas preferências | Guarda explicitamente uma receita revisada e permite esquecer as receitas guardadas. A leitura é privada à conta. |
| Reutilização | Propõe a receita guardada quando composição, tipo de evento, título da refeição, escopo, tipo de serviço, duração, unidade e público-alvo são compatíveis. Uma receita atual explícita mantém prioridade. |
| Regra de consumo → Ingredientes → Colar receita com medidas | Transforma rendimento e ingredientes explicitamente escritos em ficha editável. Converte apenas g/kg e ml/L. Não infere rendimento térmico, ingredientes ausentes ou preços. |
| Revisão depois da festa | Primeiro pergunta se foi suficiente, sobrou, faltou, não foi servido ou não é possível avaliar. Pesagens são opcionais e ficam em fluxo próprio. |
| Salvar para depois / Concluir revisão | Persiste o estado por refeição e mantém possibilidade de correção. Conclusão exige avaliação de todos os itens atuais, admitindo “Não sei avaliar”. |

Exemplo aceito no texto: `Planeje para 30 adultos e 8 crianças; duração de 6 horas; perfil padrão`. Também é possível selecionar a fonte com `usar convidados não recusados`. Um trecho não reconhecido ou duas definições conflitantes impedem o conjunto inteiro. A revisão é invalidada quando o contexto muda. Este interpretador local cobre essas intenções; não é uma conversa de domínio aberto com um modelo remoto.

As preferências só são guardadas por escolha explícita e não incluem preços ou vínculos do evento anterior. Receitas com divisão de grupo ou público alimentar específico exigem conferência no contexto atual e não entram na reutilização automática. A gravação usa comparação transacional para impedir a perda silenciosa de uma preferência alterada em outro acesso.

## Consumo e encerramento

Uma resposta “sobrou” não é convertida em quilos, rendimento ou porção observada. A revisão qualitativa fica em `calculadora_operacao/{evento}/revisao_pos_evento/{cardapio}`. Os registros quantitativos continuam separados e passam pelos validadores de consumo observado existentes.

O botão de medição salva primeiro o progresso qualitativo. Falhas mantêm respostas e permitem nova tentativa. O servidor confere organizador, data do evento, refeição, revisão e conjunto atual de itens na transação. Um evento futuro não recebe fechamento de resultados. A revisão não encerra pagamentos, altera contratos, dá baixa física no estoque ou muda o status cadastral do evento.

## Concorrência e executor

A aplicação conjunta deixou de escrever por uma transação documental no cliente. Agora usa `aplicarPlanoCalculadora`, com transação no servidor. Dentro dela são consultados convidados, cardápios, itens, orçamentos, lançamentos financeiros e tarefas, inclusive coleções vazias. O conjunto e o conteúdo são comparados com a proposta revisada. Inserções, remoções e alterações após a captura impedem aplicar aquela proposta.

Organizador, destinos, campos permitidos, quantidade, revisão, saldo de lotes e preservação das configurações são validados no servidor. Identidades de tarefas, fatos financeiros e quantidades finais são preservados. O recibo usa SHA-256 do plano canônico e é criado junto com as alterações. Duas aplicações simultâneas do mesmo pedido produzem uma gravação e uma resposta de repetição, sem tarefas duplicadas.

Referência da garantia transacional: [isolamento serializável do Firestore](https://firebase.google.com/docs/firestore/transaction-data-contention). Os testes usam o SDK real de autenticação e o Admin SDK contra emuladores locais, com projeto `demo-calculadora-execucao`; não usam a conta ou os dados do evento real.

## Avaliação da autonomia

O avaliador `tool/avaliar_autonomia_calculadora.dart` compara sessões observadas pareadas, sem descartar falhas. Exige participante pseudonimizado, tarefa, cenário, contexto comparável, versão do app, intervenções, tempo ativo, correções, erros, custo e latência de IA e verificações de qualidade.

O protocolo e o formato estão em `docs/calculadora-protocolo-autonomia.md`. Cobertura incompleta, piora de qualidade ou aumento agregado de correções impedem declarar a meta no piloto. A contagem instrumentada na interface continua identificada como parcial; não é transformada automaticamente em uma medição integral de trabalho humano.

## O que ainda depende de evidência externa

- Realizar as sessões pareadas com usuários para medir a redução efetiva de trabalho. A ferramenta pronta não demonstra uma redução de 70%–80%.
- Registrar preparado, sobra, desperdício e falta após o evento de 23/10/2026. O primeiro evento ainda não fornece histórico para comprovar a calibração.
- Receitas próprias que ainda não foram fornecidas precisam de suas medidas reais. A importação reduz o cadastro, mas não torna uma ficha desconhecida em receita validada. A base inicial e as referências anteriores continuam limitadas aos cenários documentados na entrega 1.

Leitura de documentos continua sendo uma entrega posterior ao fluxo de texto, conforme o plano original. Pesquisa externa de preços permanece adiada por decisão do usuário.

## Validação

- Suíte Flutter completa: **553 testes aprovados** em `.dart_tool/pendencias-suite-final.log`.
- Após os ajustes finais de comparação transacional e remoção de metadados de calibração nas preferências, **24 testes de aceite passaram novamente** em `.dart_tool/pendencias-aceite-final.log`. Incluem domínio, persistência, texto, memória, importação e interfaces.
- **42 verificações autenticadas** aprovadas com Auth e Firestore emulados em `.dart_tool/pendencias-emuladores-final.log`. Incluem SDK cliente real, token validado, conta sem acesso, fontes inseridas/removidas/alteradas, repetição concorrente, estoque, ingredientes, preservação de quantidades finais e fechamento qualitativo.
- Regras da calculadora e das tarefas aprovadas no mesmo comando de emuladores. Mensagens `PERMISSION_DENIED` do arquivo são as negativas esperadas dos testes de acesso.
- Análise estática do módulo e serviços afetados sem problemas: `.dart_tool/pendencias-analysis-calculadora.log`. Persistência/memória/testes finais também sem problemas em `.dart_tool/pendencias-analysis-aceite.log`. A análise global apontou uma informação de import desnecessário fora da calculadora, em `lib/core/legal/dossie_titular_documento.dart`, preservada.
- TypeScript e verificações existentes de planejamento/IA aprovados: `.dart_tool/pendencias-functions-final.log`. Os novos serviços TypeScript também foram compilados e executados no teste autenticado.
- Interfaces de texto e revisão testadas em 320 × 640 com texto ampliado, falha de gravação e retomada. A importação prepara uma ficha editável e recusa texto sem medidas.
- `git diff --check` sem erros de whitespace. Nenhuma publicação, commit ou push nesta entrega.

Para repetir o teste autenticado, gerar antes as fixtures com `flutter test test/features/calculadora/plano_execucao_remote_test.dart`, compilar `npm --prefix functions run build` e executar:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
firebase emulators:exec --config firebase.calculadora-test.json --only "firestore,auth" --project demo-calculadora-execucao "node functions/scripts/testPlanoExecucaoEmulator.js"
```

O script se recusa a rodar sem os dois emuladores. O projeto é fixado com prefixo `demo-` e só usa dados sintéticos de teste. As 42 verificações não equivalem a validar a aplicação instalada nem a medir o resultado do evento real.
