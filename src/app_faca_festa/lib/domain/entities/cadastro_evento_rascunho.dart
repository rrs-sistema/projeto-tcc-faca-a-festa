import 'dart:convert';
import 'rascunho_calculadora.dart';

/// Registro privado local. Não é um documento compartilhado de evento.
class CadastroEventoRascunho {
  static const versaoAtual = 2;
  final String usuario, id, evento;
  final bool eventoConfirmado;
  final DateTime atualizadoEm;
  final Map<String, dynamic> formulario;
  final RascunhoCalculadora? estimativa;
  CadastroEventoRascunho(
      {required this.usuario,
      required this.id,
      required this.evento,
      required this.eventoConfirmado,
      required this.atualizadoEm,
      required Map<String, dynamic> formulario,
      this.estimativa})
      : formulario = Map.unmodifiable(
            jsonDecode(jsonEncode(formulario)) as Map<String, dynamic>);
  Map<String, dynamic> toMap() => {
        'versao': versaoAtual,
        'usuario': usuario,
        'id': id,
        'evento': evento,
        'evento_confirmado': eventoConfirmado,
        'atualizado_em': atualizadoEm.toUtc().toIso8601String(),
        'formulario': formulario,
        'estimativa': estimativa?.toMap()
      };
  factory CadastroEventoRascunho.fromMap(Map<String, dynamic> m) {
    if (m['versao'] != versaoAtual ||
        m['usuario'] is! String ||
        (m['usuario'] as String).isEmpty ||
        m['id'] is! String ||
        (m['id'] as String).isEmpty ||
        m['formulario'] is! Map ||
        m['evento_confirmado'] is! bool) {
      throw const FormatException(
          'Rascunho local inválido ou de versão incompatível.');
    }
    final formulario = Map<String, dynamic>.from(m['formulario'] as Map);
    final campos = formulario['campos'];
    if (campos is! Map ||
        campos.values.any((v) => v is! String) ||
        (formulario['padrinhos'] != null &&
            (formulario['padrinhos'] is! List ||
                (formulario['padrinhos'] as List).any((v) => v is! String)))) {
      throw const FormatException('Campos do cadastro inválidos.');
    }
    final estimativa = m['estimativa'] == null
        ? null
        : RascunhoCalculadora.fromMap(
            Map<String, dynamic>.from(m['estimativa'] as Map));
    if (estimativa != null && estimativa.id != m['id']) {
      throw const FormatException('Identidade da estimativa divergente.');
    }
    return CadastroEventoRascunho(
        usuario: m['usuario'] as String,
        id: m['id'] as String,
        evento: m['evento'] as String,
        eventoConfirmado: m['evento_confirmado'] as bool,
        atualizadoEm: DateTime.parse(m['atualizado_em'] as String),
        formulario: Map<String, dynamic>.from(m['formulario'] as Map),
        estimativa: estimativa);
  }
}

class LeituraCadastrosLocais {
  final List<CadastroEventoRascunho> cadastros;
  final List<String> corrompidos;
  const LeituraCadastrosLocais(this.cadastros, this.corrompidos);
}
