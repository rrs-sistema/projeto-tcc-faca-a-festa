import 'package:flutter_contacts/flutter_contacts.dart';

import 'agenda_contatos.dart';

Future<List<ContatoAgenda>> carregarContatosNativo() async {
  final permitido = await FlutterContacts.requestPermission(readonly: true);
  if (!permitido) {
    throw const AgendaContatosSemPermissao();
  }

  final contatos = await FlutterContacts.getContacts(withProperties: true);
  final resultado = <ContatoAgenda>[];

  for (final contato in contatos) {
    final telefones = <String>[];
    final ordenados = [...contato.phones]
      ..sort((a, b) => (b.isPrimary ? 1 : 0) - (a.isPrimary ? 1 : 0));

    for (final telefone in ordenados) {
      final numero = _normalizarTelefone(
        telefone.normalizedNumber.isNotEmpty
            ? telefone.normalizedNumber
            : telefone.number,
      );
      if (numero.isEmpty || telefones.contains(numero)) continue;
      telefones.add(numero);
    }
    if (telefones.isEmpty) continue;

    String? email;
    for (final item in contato.emails) {
      final valor = item.address.trim();
      if (valor.contains('@')) {
        email = valor;
        break;
      }
    }

    final nome = contato.displayName.trim();
    resultado.add(ContatoAgenda(
      nome: nome.isEmpty ? telefones.first : nome,
      telefones: telefones,
      email: email,
    ));
  }

  resultado.sort(
    (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
  );
  return resultado;
}

String _normalizarTelefone(String bruto) {
  final soDigitos = bruto.replaceAll(RegExp(r'\D'), '');
  if (soDigitos.length < 8) return '';
  if (soDigitos.startsWith('55') && soDigitos.length >= 12) {
    return '+$soDigitos';
  }
  return soDigitos;
}
