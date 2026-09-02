import 'package:cloud_firestore/cloud_firestore.dart';

class EventoComTipoModel {
  final String id;
  final String nome;
  final String tipoNome;
  final String organizador;
  final String? cidade;
  final bool aprovado;
  final bool ativo;
  final String status;
  final int totalConvidados;
  final DateTime? data;

  EventoComTipoModel({
    required this.id,
    required this.nome,
    required this.tipoNome,
    required this.organizador,
    this.cidade,
    this.data,
    this.aprovado = false,
    this.ativo = true,
    this.status = '',
    this.totalConvidados = 0,
  });

  bool get emCurso {
    const ativos = {
      'rascunho',
      'planejamento',
      'confirmado',
      'emAndamento',
      'em_andamento',
    };
    if (status.isNotEmpty) return ativos.contains(status);
    return ativo &&
        (data == null ||
            !data!.isBefore(DateTime.now().subtract(const Duration(days: 1))));
  }

  String get statusLabel {
    switch (status) {
      case 'rascunho':
        return 'Rascunho';
      case 'planejamento':
        return 'Em planejamento';
      case 'confirmado':
        return 'Confirmado';
      case 'emAndamento':
      case 'em_andamento':
        return 'Em andamento';
      case 'finalizado':
        return 'Finalizado';
      case 'adiado':
        return 'Adiado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return aprovado ? 'Aprovado' : 'Em análise';
    }
  }

  factory EventoComTipoModel.fromMap(
      Map<String, dynamic> map, String id, String tipoNome) {
    return EventoComTipoModel(
      id: id,
      nome: _texto(map, ['nomeEvento', 'nome_evento', 'nome'],
          fallback: 'Sem nome'),
      tipoNome: tipoNome,
      organizador: _texto(
        map,
        [
          'nomePessoalPrincipal',
          'nome_pessoal_principal',
          'organizador',
          'nomeResponsavel',
          'nome_responsavel'
        ],
        fallback: '-',
      ),
      cidade: _textoOpcional(map, ['nomeCidade', 'nome_cidade', 'cidade']),
      aprovado: map['aprovado'] == true,
      ativo: map['ativo'] != false,
      status: _texto(map, ['status']),
      totalConvidados: _int(map, ['totalConvidados', 'total_convidados']),
      data: _data(map, ['data', 'data_evento', 'dataEvento']),
    );
  }

  static String _texto(Map<String, dynamic> map, List<String> keys,
      {String fallback = ''}) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  static String? _textoOpcional(Map<String, dynamic> map, List<String> keys) {
    final value = _texto(map, keys);
    return value.isEmpty ? null : value;
  }

  static int _int(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static DateTime? _data(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
    }
    return null;
  }
}
