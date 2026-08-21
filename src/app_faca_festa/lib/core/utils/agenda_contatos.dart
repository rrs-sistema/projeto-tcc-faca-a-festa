import 'package:flutter/foundation.dart';

import 'agenda_contatos_nativo_stub.dart'
    if (dart.library.io) 'agenda_contatos_nativo.dart' as nativo;

class ContatoAgenda {
  const ContatoAgenda({
    required this.nome,
    required this.telefones,
    this.email,
  });

  final String nome;
  final List<String> telefones;
  final String? email;

  String get telefonePrincipal => telefones.isEmpty ? '' : telefones.first;
}

bool agendaDoCelularDisponivel() {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// Agenda do aparelho (a mesma origem que o WhatsApp usa).
/// O WhatsApp não expõe a lista da conta para outros aplicativos.
Future<List<ContatoAgenda>> carregarContatosDaAgenda() async {
  if (!agendaDoCelularDisponivel()) {
    throw const AgendaContatosIndisponivel();
  }
  return nativo.carregarContatosNativo();
}

class AgendaContatosIndisponivel implements Exception {
  const AgendaContatosIndisponivel();
}

class AgendaContatosSemPermissao implements Exception {
  const AgendaContatosSemPermissao();
}
