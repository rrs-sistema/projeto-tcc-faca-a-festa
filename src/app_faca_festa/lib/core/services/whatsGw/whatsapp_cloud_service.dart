import 'dart:convert';
import 'package:http/http.dart' as http;

class WhatsAppCloudService {
  final String accessToken; // Bearer token
  final String phoneNumberId; // O ID do número da Cloud API

  WhatsAppCloudService({
    required this.accessToken,
    required this.phoneNumberId,
  });

  Future<void> enviarHelloWorld(String numeroDestino) async {
    final url = Uri.parse("https://graph.facebook.com/v22.0/$phoneNumberId/messages");

    final headers = {
      "Authorization": "Bearer $accessToken",
      "Content-Type": "application/json",
    };

    final body = {
      "messaging_product": "whatsapp",
      "to": numeroDestino,
      "type": "template",
      "template": {
        "name": "hello_world",
        "language": {"code": "en_US"}
      }
    };

    await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }
}
