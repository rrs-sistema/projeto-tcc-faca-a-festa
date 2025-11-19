import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'dart:convert';

class WhatsAppService extends GetxService {
  static const String _baseUrl = "https://app.whatsgw.com.br/api/WhatsGw/Send";

  late String apiKey;

  WhatsAppService({
    required this.apiKey,
  });

  String formatarNumeroWhatsApp(String numero) {
    numero = numero.replaceAll(RegExp(r'[^0-9]'), '');
    if (!numero.startsWith("55")) {
      numero = "55$numero";
    }
    return numero;
  }

  Future<bool> sendText({
    required String phone,
    required String message,
  }) async {
    try {
      EasyLoading.show(status: "Enviando...");

      final numero = formatarNumeroWhatsApp(phone);

      final body = {
        "apikey": apiKey,
        "phone_number": numero,
        //"phone_number": "5541996938377",
        "contact_phone_number": "554197400322",
        "message_type": "text",
        "message_body": message,
        "check_status": "1",
        "message_custom_id": "app-faca-festa"
      };

      final headers = {
        "Content-Type": "application/json",
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      EasyLoading.dismiss();
      //"{"result":"fail","result_message":"phone_number does not exist [5541996938377] access tutorial at API-\u003eTutorial for check y…"
      /*[41996938377][4198714616][4185158486][4184608936]*/
      if (response.statusCode == 200) {
        Get.snackbar("WhatsApp", "Mensagem enviada!");
        return true;
      }

      Get.snackbar(
        "Erro",
        "Falha: ${response.body}",
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.2),
      );
      return false;
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar("Erro", e.toString());
      return false;
    }
  }
}
