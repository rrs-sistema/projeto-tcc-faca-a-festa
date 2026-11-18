import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/evento_admin.dart';

class EventoComTipoModel extends EventoAdmin {
  EventoComTipoModel({
    required super.id,
    required super.nome,
    required super.tipoNome,
    required super.organizador,
    super.cidade,
    super.uf,
    super.data,
    super.dataCadastro,
    super.aprovado = false,
    super.ativo = true,
    super.status = '',
    super.totalConvidados = 0,
    super.custoEstimado,
    super.totalCotacoes = 0,
    super.idUsuario = '',
    super.idTipoEvento = '',
    super.eventosDoOrganizador = 1,
    super.followUp = const FollowUpComercial(marcado: false),
    super.nudge = const NudgeCotacao(),
  });

  factory EventoComTipoModel.fromMap(
    Map<String, dynamic> map,
    String id,
    String tipoNome, {
    int totalCotacoes = 0,
    int eventosDoOrganizador = 1,
  }) {
    final followRaw = map['follow_up_comercial'] ?? map['followUpComercial'];
    final nudgeRaw = map['nudge_cotacao'] ?? map['nudgeCotacao'];

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
      uf: _textoOpcional(map, ['uf', 'estado', 'estadoEvento', 'estado_evento']),
      aprovado: map['aprovado'] == true,
      ativo: map['ativo'] != false,
      status: _texto(map, ['status']),
      totalConvidados: _int(map, ['totalConvidados', 'total_convidados']),
      data: _data(map, ['data', 'data_evento', 'dataEvento']),
      dataCadastro: _data(map, ['dataCadastro', 'data_cadastro', 'criadoEm']),
      custoEstimado: _double(map, ['custoEstimado', 'custo_estimado']),
      totalCotacoes: totalCotacoes,
      idUsuario: _texto(map, ['idUsuario', 'id_usuario', 'usuarioId']),
      idTipoEvento: _texto(map, ['idTipoEvento', 'id_tipo_evento']),
      eventosDoOrganizador: eventosDoOrganizador,
      followUp: FollowUpComercial.fromMap(
        followRaw is Map ? Map<String, dynamic>.from(followRaw) : null,
      ),
      nudge: NudgeCotacao.fromMap(
        nudgeRaw is Map ? Map<String, dynamic>.from(nudgeRaw) : null,
      ),
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

  static double? _double(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value.replaceAll(',', '.'));
      }
    }
    return null;
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
