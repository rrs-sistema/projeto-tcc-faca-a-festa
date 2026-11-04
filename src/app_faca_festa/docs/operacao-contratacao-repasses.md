# Contratação, comissão e repasse

## Regra de liberação

O pagamento ao fornecedor exige contratação confirmada, comissão consistente,
recebimento conferido e alocado e política de liberação ativa. Além disso, exige
o evento no estado `finalizado` OU autorização explícita do organizador proprietário.
A data do evento ter passado, o fornecedor informar entrega e o cliente aceitar
entrega não substituem essa autorização.

Mediações em aberto, retenções efetivas, execução contestada e cancelamentos
bloqueiam a autorização e a confirmação do pagamento. O administrador pode
cancelar uma reserva pendente para revisar condições; pagamentos confirmados
permanecem no histórico.

## Comissão e valores

A divisão usa a obrigação de comissão e sua política aplicada ao contrato.
Taxa, valor contratado e fornecedor enviados pela interface não definem os direitos
do repasse. Comissão ausente, duplicada, estornada ou inconsistente exige conferência.
Contratos legados não recebem automaticamente a taxa padrão de 5%.

Exemplo de comissão descontada do fornecedor: R$ 3.150,00 contratados com 5%
resultam em R$ 157,50 para a plataforma e R$ 2.992,50 para o fornecedor.
Quando a comissão é cobrada do organizador, soma-se ao preço do cliente; não se
desconta do fornecedor. A política que a plataforma absorve não reduz o direito
do fornecedor.

O dinheiro destinado à comissão fica reservado antes de calcular o saldo
liberado. Em pagamentos parciais, a comissão é reservada integralmente, e sua
retenção é registrada uma única vez na primeira confirmação de repasse.
O extrato de comissões passa a reconhecer esse recebimento, com vínculo ao repasse.
Comissões recebidas separadamente são conciliadas com a obrigação: apenas a
parcela ainda não recebida fica reservada no contrato. Isso evita descontar do
fornecedor uma comissão já paga. O dossiê distingue comissão, direito de repasse
e saldo do fornecedor; comissão cobrada do organizador compõe o total a receber dele.

## Autorização antecipada

No acompanhamento do organizador há ações para autorizar ou revogar o pagamento
antecipado, com motivo obrigatório. A autorização registra o autor e as condições
do contrato. Mudanças de valor, beneficiário ou comissão invalidam a autorização.
Administradores e fornecedores não podem autorizar em nome do organizador.
A revogação impede confirmar reservas pendentes antes do evento; não desfaz
pagamentos já confirmados. Após o evento finalizado, aplica-se a regra normal.

## Operação administrativa

1. Confirmar contratação e conferir comissão na central de contratações.
2. Registrar recebimento conferido na intermediação. Declarações do cliente não financiam repasses.
3. Alocar o recebimento ao contrato correspondente.
4. Conferir o líquido e o motivo de liberação ou bloqueio.
5. Autorizar o repasse disponível.
6. Realizar a transferência pelo meio bancário adotado pela administração.
7. Confirmar o pagamento com referência ou comprovante obrigatório.

A confirmação revalida as condições no servidor. Reservas concorrentes do mesmo
contrato são serializadas, e repetições idempotentes não duplicam saídas ou comissões.
A confirmação continua sendo uma conferência manual; não existe transferência
bancária automática nesta implementação.

## Regularização após mediação

Registre uma decisão fundamentada antes de encerrar o caso. Se a execução
continuar contestada, o administrador pode regularizá-la pelo dossiê, escolhendo
retomar a execução, reconhecer sua regularização ou cancelar a execução, conforme
a última decisão registrada. A retirada de uma retenção exige confirmação explícita.
Outra mediação aberta ou uma transferência em processamento impede a regularização.

A resolução cancela reservas pendentes e revoga autorizações antecipadas anteriores.
Antes de pagar, confira novamente o contrato e prepare um novo repasse. Se o evento
ainda não estiver finalizado, o organizador deve autorizar novamente. Pagamentos já
confirmados permanecem registrados. Encerrar ou regularizar uma mediação não executa
transferência ou reembolso. Casos encerrados podem originar uma nova mediação,
com justificativa, sem alterar a decisão histórica.

## Validação e publicação

`npm run test:repasse:operacional` compila o backend e executa os cenários reais
de persistência, concorrência e regras em um projeto `demo` no Firestore Emulator.
Exige Java 21+; nesta máquina ele está no JBR do Android Studio.

Para disponibilizar a alteração, publicar as Functions e as regras do Firestore
em conjunto e distribuir uma nova compilação do aplicativo. Repasses autorizados
antigos sem assinatura das condições devem ser cancelados e preparados novamente.
Não há migração nem pagamento automático de registros anteriores.
