class WhatsAppTemplates {
  // =========================================================
  // 🔹 CONVITES – Formal / Divertido / Emocionante
  // =========================================================

  // Formal
  String conviteFormal({
    required String nomeConvidado,
    required String tipoEvento,
    required String nomeEvento,
    required String data,
    required String hora,
    required String endereco,
    String? linkConfirmacao,
  }) {
    return """
Olá $nomeConvidado.

Você está oficialmente convidado para o(a) *$tipoEvento*  
de *$nomeEvento*.

🗓 Data: $data  
⏰ Horário: $hora  
📍 Local: $endereco  

${linkConfirmacao != null ? "Confirme sua presença: $linkConfirmacao" : "Por favor, confirme sua presença pelo app FAÇA A FESTA."}
""";
  }

  // Divertido
  String conviteDivertido({
    required String nomeConvidado,
    required String tipoEvento,
    required String nomeEvento,
    required String data,
    required String hora,
    required String endereco,
    String? linkConfirmacao,
  }) {
    return """
Ei $nomeConvidado! 😄🎉

Tem festa chegando! Você está convidado para o(a) *$tipoEvento*  
de *$nomeEvento*! Vai ser incrível! 🔥✨

📅 $data  
⏰ $hora  
📍 $endereco  

${linkConfirmacao != null ? "Clique e confirma aí rapidinho 👉 $linkConfirmacao" : "Confirme sua presença pelo app FAÇA A FESTA 😉"}
""";
  }

  // Emocionante
  String conviteEmocionante({
    required String nomeConvidado,
    required String tipoEvento,
    required String nomeEvento,
    required String data,
    required String hora,
    required String endereco,
    String? linkConfirmacao,
  }) {
    return """
Olá $nomeConvidado! ❤️

É com muita alegria que convidamos você para o(a) *$tipoEvento*  
de *$nomeEvento*. Sua presença tornará esse momento ainda mais especial. ✨

📅 Data: $data  
⏰ Horário: $hora  
📍 Local: $endereco  

${linkConfirmacao != null ? "Confirme sua presença aqui: $linkConfirmacao" : "Confirme sua presença pelo app FAÇA A FESTA ❤️"}
""";
  }

  // Confirmado
  String confirmacaoPresenca({
    required String nomeConvidado,
    required String nomeEvento,
    required String data,
    required String hora,
    required String endereco,
    String? linkEvento,
  }) {
    return """
Olá $nomeConvidado! 😊

Sua presença no evento *$nomeEvento* foi confirmada! 🎉  
Estamos muito felizes por ter você conosco!

📅 $data  
⏰ $hora  
📍 $endereco  

${linkEvento != null ? "Acesse os detalhes do evento: $linkEvento" : ""}
""";
  }

  // Padrão
  String lembreteEvento({
    required String nomeConvidado,
    required String nomeEvento,
    required String data,
    required String hora,
    String? linkEvento,
  }) {
    return """
Olá $nomeConvidado! ⏰

Lembrete: está chegando o evento *$nomeEvento*! 🎉

📅 $data  
⏰ $hora  

${linkEvento != null ? "Veja os detalhes: $linkEvento" : ""}
Estamos ansiosos para te ver lá!
""";
  }

  // Divertido
  String lembreteDivertido({
    required String nomeConvidado,
    required String nomeEvento,
    required String data,
    required String hora,
  }) {
    return """
Atenção $nomeConvidado! 😄🔥

O grande dia do *$nomeEvento* está chegando!  
Preparado(a)? Porque nós estamos! 🎉✨

📅 $data  
⏰ $hora  
Vai ser top demais!
""";
  }

  // Emocionante
  String lembreteEmocionante({
    required String nomeConvidado,
    required String nomeEvento,
    required String data,
    required String hora,
  }) {
    return """
Olá $nomeConvidado! ❤️

Falta pouco para vivermos juntos o momento especial: *$nomeEvento*.  
Será um dia marcante e ficaremos honrados com sua presença.

📅 $data  
⏰ $hora  
""";
  }

  String atualizacaoOrcamento({
    required String nomeOrganizador,
    required String categoria,
    required String item,
    required double valor,
  }) {
    return """
🧾 Atualização no orçamento

O item *$item* da categoria *$categoria* foi atualizado.

💰 Novo valor: R\$ ${valor.toStringAsFixed(2)}  
👤 Responsável: $nomeOrganizador  

Acesse o app FAÇA A FESTA para acompanhar tudo.
""";
  }

  String atualizacaoCotacao({
    required String nomeFornecedor,
    required String categoria,
    required String status,
  }) {
    return """
Olá $nomeFornecedor! 📩

Sua cotação da categoria *$categoria* foi atualizada.

📌 Novo status: *$status*  

Acesse o painel do fornecedor no app FAÇA A FESTA.
""";
  }

  String boasVindasFornecedor({
    required String nomeFornecedor,
  }) {
    return """
Olá $nomeFornecedor! 👋

Bem-vindo ao *FAÇA A FESTA*! 🎉  
Agora você pode receber orçamentos, responder clientes e fechar negócios diretamente pelo app.

Estamos felizes em ter você conosco!  
Conte sempre com nosso suporte. 🤝
""";
  }
}
