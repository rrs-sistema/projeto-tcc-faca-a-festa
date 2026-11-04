# Formulário de proposta — 27/10/2026

Formulário existente reorganizado em valor, itens incluídos e validade, com espaçamento, bordas, resumo do total durante a edição e ação explícita Enviar proposta. Agenda opcional recolhida. Datas escolhidas por calendário e horário com entrada24h; dados continuam enviados no contrato ISO/UTC do backend. Fuso resolvido pela dependência timezone já presente no projeto, com regiões legíveis na seleção e preservação de fuso existente. Não há nova dependência nem mudança de backend.

Campos readOnly de data mantêm controlador de apresentação separado do valor ISO. Seleção cancelada não altera o dado. Datas opcionais podem ser removidas. A troca de sessão continua invalidando o diálogo, e retornos tardios do seletor verificam mounted. Validação do formulário impede desconto maior que preço, preço não positivo, validade passada e intervalo incompleto/invertido. Validação autoritativa existente no backend preservada.

Validações finais:

```powershell
flutter test test/features/cotacoes/jornada_atendimento_test.dart --update-goldens
flutter test test/features/cotacoes/jornada_atendimento_test.dart test/features/cotacoes/acesso_atendimento_test.dart
dart analyze lib/presentation/modules/cotacao/pages/jornada_atendimento_page.dart test/features/cotacoes/jornada_atendimento_test.dart
```

**19 testes aprovados**, inclusive comparação visual sem update-goldens e análise sem problemas. Testes novos em390x1000 com fonte1,2 e1280x1100: total1000−100=900, abertura do calendário/relógio, ausência de offset/IANA na leitura principal e bloqueio do envio com desconto1100 sobre preço1000. Teste de envio válido confirma centavos, versão e dataUTC. Regressão inclui jornada, acesso, concorrência/versionamento, expiração e troca de sessão.

Durante a implementação, uma correção automática concorrente com edição local gerou erro de sintaxe; o trecho foi reescrito e as verificações finais repetidas. A primeira simulação móvel dos seletores usava dimensões físicas divergentes das dimensões de layout; o teste foi corrigido para usar viewport real, e o relógio usa entrada numérica24h. As assertivas não foram removidas. Logs finais anexos correspondem à versão aprovada.

Arquivos alterados: `lib/presentation/modules/cotacao/pages/jornada_atendimento_page.dart` e `test/features/cotacoes/jornada_atendimento_test.dart`.

Imagens atuais de widgets com dados sintéticos e fontes locais, inspecionadas visualmente:
- [Desktop](../proposta-formulario-desktop.png)
- [Celular](../proposta-formulario-celular.png)

Não houve deploy, envio real de proposta, alteração de registros em produção ou teste autenticado no navegador do usuário. Não foi executado estudo com usuários reais ou leitor de tela externo. As validações do formulário complementam e não substituem as transações/autorização do backend.
