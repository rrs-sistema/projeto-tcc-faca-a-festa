class WhatsAppTemplates {
  // Confirmação de presença
  String confirmacaoPresenca({
    required String nomeConvidado,
    required String nomeEvento,
    required String data,
    required String hora,
    required String endereco,
  }) {
    return """
Olá $nomeConvidado! 😊

Sua presença no evento *$nomeEvento* está confirmada! 🎉

📅 Data: $data  
⏰ Horário: $hora  
📍 Local: $endereco  

Qualquer dúvida estou à disposição!
""";
  }

  // Convite para o evento
  String conviteEvento({
    required String nomeConvidado,
    required String nomeEvento,
    required String data,
    required String hora,
    required String endereco,
  }) {
    return """
Olá $nomeConvidado! 🎈

Você está convidado para o evento *$nomeEvento*!  
Será uma alegria te receber! 🥳

📅 Data: $data  
⏰ Horário: $hora  
📍 Endereço: $endereco  

Por favor, confirme sua presença pelo app.
""";
  }

  // Lembrete da data do evento
  String lembreteEvento({
    required String nomeConvidado,
    required String nomeEvento,
    required String data,
    required String hora,
  }) {
    return """
Olá $nomeConvidado! ⏰

Lembrete: falta pouco para o evento *$nomeEvento*! 🎉

📅 Data: $data  
⏰ Horário: $hora  

Estamos ansiosos para te ver lá!
""";
  }

  // Atualização de orçamento
  String atualizacaoOrcamento({
    required String nomeOrganizador,
    required String categoria,
    required String item,
    required double valor,
  }) {
    return """
Atualização no orçamento 🧾

$item da categoria *$categoria* foi atualizado.

💰 Valor: R\$ ${valor.toStringAsFixed(2)}  
👤 Atualizado por: $nomeOrganizador  

Acesse o app para ver mais detalhes.
""";
  }

  // Atualização de cotação
  String atualizacaoCotacao({
    required String nomeFornecedor,
    required String categoria,
    required String status,
  }) {
    return """
Olá $nomeFornecedor! 📩

Sua cotação da categoria *$categoria* foi atualizada:

📌 Status: *$status*

Acesse o app para mais detalhes.
""";
  }

  // Boas-vindas para fornecedor
  String boasVindasFornecedor({
    required String nomeFornecedor,
  }) {
    return """
Olá $nomeFornecedor! 👋

Bem-vindo ao *Faça a Festa*.  
Agora você pode receber solicitações de cotação diretamente no app, responder clientes e fechar negócios rapidamente. 🎉  

Qualquer dúvida, conte conosco!
""";
  }
}
