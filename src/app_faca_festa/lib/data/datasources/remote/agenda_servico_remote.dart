import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

/// Protocolo callable autenticado por HTTP, também disponível no desktop.
/// Emuladores só aceitam projeto demo e loopback explícitos.
class AgendaServicoRemote {
  AgendaServicoRemote(this.auth, {this.emulador});
  final FirebaseAuth auth;
  final Uri? emulador;
  Future<Map<String, dynamic>> confirmar(
      String evento, Map<String, dynamic> acao) async {
    return CallableCalculadoraRemote(auth, emulador: emulador)
        .chamar('confirmarAgendaCalculadora', {'evento': evento, 'acao': acao});
  }
}

class CallableCalculadoraRemote {
  CallableCalculadoraRemote(this.auth, {this.emulador});
  final FirebaseAuth auth;
  final Uri? emulador;
  Future<Map<String, dynamic>> chamar(
      String funcao, Map<String, dynamic> dados) async {
    if (![
      'confirmarAgendaCalculadora',
      'editarCatalogoCalculadora',
      'sugerirCandidatosCalculadora',
      'confirmarPlanejadorCalculadora',
      'interpretarEntradaCalculadora',
      'aplicarEntradaCalculadora',
      'aplicarPlanoCalculadora'
    ].contains(funcao)) {
      throw StateError('Função não permitida.');
    }
    final usuario = auth.currentUser;
    if (usuario == null) throw StateError('Entre na conta do organizador.');
    final projeto = auth.app.options.projectId;
    if (emulador != null &&
        (!projeto.startsWith('demo-') ||
            !['127.0.0.1', 'localhost', '::1'].contains(emulador!.host) ||
            emulador!.scheme != 'http')) {
      throw StateError('Emulador de agenda inválido.');
    }
    if (projeto.startsWith('demo-') && emulador == null) {
      throw StateError('Configure o emulador local da agenda.');
    }
    final url = emulador ??
        Uri.https('southamerica-east1-$projeto.cloudfunctions.net', funcao);
    final token = await usuario.getIdToken();
    if (token == null) throw StateError('Sua sessão precisa ser renovada.');
    final response = await http
        .post(url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token'
            },
            body: jsonEncode({'data': dados}))
        .timeout(const Duration(seconds: 120));
    if (auth.currentUser?.uid != usuario.uid) {
      throw StateError('Sua sessão mudou. Reabra o evento.');
    }
    final body = jsonDecode(response.body);
    if (body is! Map) throw StateError('O servidor não confirmou a agenda.');
    if (response.statusCode != 200 || body['error'] != null) {
      final erro = body['error'];
      if (funcao == 'aplicarPlanoCalculadora' && erro is Map) {
        throw FirebaseFunctionsException(
            code: (erro['status'] ?? 'unknown')
                .toString()
                .toLowerCase()
                .replaceAll('_', '-'),
            message: erro['message']?.toString() ??
                'O servidor não confirmou a aplicação.',
            details: erro['details']);
      }
      throw StateError(erro is Map && erro['message'] is String
          ? erro['message']
          : 'Não foi possível guardar a agenda. Seus valores foram mantidos.');
    }
    final result = body['result'] ?? body['data'];
    if (result is! Map) {
      throw StateError('A confirmação da agenda está incompleta.');
    }
    return Map<String, dynamic>.from(result);
  }
}
