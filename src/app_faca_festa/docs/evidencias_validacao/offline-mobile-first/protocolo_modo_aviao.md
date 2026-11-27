# Protocolo manual: modo avião real

Complementa a prova automática (`README.md`) com o app de produção e o modo avião do aparelho. Use contas de teste. Não use dados reais de clientes.

## Preparação

1. Instale a versão em avaliação e entre com a conta de organizador de teste, **com internet**.
2. Abra uma vez: lista de eventos, um evento, checklist, convidados, orçamento, presentes e calculadora. Depois, com a conta de fornecedor, abra o painel, a agenda e os serviços. Com o link de convite de teste, abra a área do convidado.
3. Para cada passo abaixo, registre data e hora, aparelho e uma captura (`adb exec-out screencap -p > passo.png` ou captura do próprio aparelho). Guarde as capturas em `telas/manual/`.

## Roteiro

| # | Ação | Resultado esperado | OK |
|---|---|---|---|
| 1 | Ligar o modo avião com o app aberto | Faixa "Sem internet" aparece em poucos segundos | |
| 2 | Abrir o evento e criar uma tarefa | Tarefa aparece na hora, com o selo "Salvo no aparelho, aguardando sincronização" | |
| 3 | Adicionar um convidado e um gasto no orçamento | Ambos aparecem na hora; a faixa conta as alterações pendentes | |
| 4 | Cadastrar um presente e registrar uma contribuição Pix recebida | Presente aparece; valor arrecadado soma a contribuição | |
| 5 | Abrir a calculadora e simular | Itens e quantidades calculados sem erro | |
| 6 | Tentar uma ação online (ex.: sugestão por IA, pagamento Pix) | Mensagem clara de que precisa de internet, sem tela travada | |
| 7 | Fechar o app pelo gerenciador de tarefas e abrir de novo, ainda em modo avião | Sessão aberta, dados e selos de pendência continuam | |
| 8 | Fornecedor: abrir painel e agenda em modo avião | Última consulta salva, com aviso de que são dados do aparelho | |
| 9 | Fornecedor: tentar alterar um serviço | Mensagem de que a ação precisa de internet | |
| 10 | Convidado: reabrir o convite e reservar um presente | Convite abre do aparelho; reserva fica salva e o app avisa que confirma quando a internet voltar | |
| 11 | Desligar o modo avião | Faixa "Conexão restabelecida", depois some; selos somem quando o servidor confirma | |
| 12 | Em outro aparelho (online), conferir os itens criados | Tudo presente, contribuição Pix uma única vez | |
| 13 | Conflito: com o aparelho A em modo avião, reservar no aparelho B o mesmo presente; depois reservar no A e desligar o modo avião | Vale a reserva do B; o A mostra "O servidor recusou: reserva do presente ..." e passa a exibir o presente como reservado | |

## Registro

- Aparelho e versão do Android:
- Versão do app:
- Responsável e data:
- Observações e desvios:
