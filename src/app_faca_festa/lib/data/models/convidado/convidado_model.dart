import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:app_faca_festa/domain/entities/convidado.dart';
export 'package:app_faca_festa/domain/entities/convidado.dart';

extension StatusConvidadoFirestore on StatusConvidado {
  String get firestoreValue => name;
}

extension TipoConvidadoFirestore on TipoConvidado {
  String get firestoreValue => name;
}

class ConvidadoModel extends Convidado {
  const ConvidadoModel({
    required super.idConvidado,
    required super.idEvento,
    required super.nome,
    required super.contato,
    super.email,
    super.status,
    super.tipoConvidado,
    super.idGrupo,
    super.nomeGrupo,
    super.idMesa,
    super.numeroMesa,
    super.ocupaAssento,
    super.cuidadoEspecial,
    super.dataEnvio,
    super.dataResposta,
    required super.dataCadastro,
    required super.dataAtualizacao,
    super.conviteToken,
    super.idUsuario,
    super.conviteStatus,
    super.emailUsuario,
    super.emailNormalizado,
  });

  factory ConvidadoModel.fromEntity(Convidado convidado) {
    return ConvidadoModel(
      idConvidado: convidado.idConvidado,
      idEvento: convidado.idEvento,
      nome: convidado.nome,
      contato: convidado.contato,
      email: convidado.email,
      status: convidado.status,
      tipoConvidado: convidado.tipoConvidado,
      idGrupo: convidado.idGrupo,
      nomeGrupo: convidado.nomeGrupo,
      idMesa: convidado.idMesa,
      numeroMesa: convidado.numeroMesa,
      ocupaAssento: convidado.ocupaAssento,
      cuidadoEspecial: convidado.cuidadoEspecial,
      dataEnvio: convidado.dataEnvio,
      dataResposta: convidado.dataResposta,
      dataCadastro: convidado.dataCadastro,
      dataAtualizacao: convidado.dataAtualizacao,
      conviteToken: convidado.conviteToken,
      idUsuario: convidado.idUsuario,
      conviteStatus: convidado.conviteStatus,
      emailUsuario: convidado.emailUsuario,
      emailNormalizado: convidado.emailNormalizado,
    );
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        'id_convidado': idConvidado,
        'id_evento': idEvento,
        'nome': nome,
        'contato': contato,
        'email': email,
        'status': status.firestoreValue,
        'tipo_convidado': tipoConvidado.firestoreValue,
        'adulto': tipoConvidado == TipoConvidado.adulto,
        'id_grupo': idGrupo,
        'nome_grupo': nomeGrupo,
        'id_mesa': idMesa,
        'numero_mesa': numeroMesa,
        'ocupa_assento': ocupaAssento,
        'cuidado_especial': cuidadoEspecial,
        'data_envio': dataEnvio != null ? Timestamp.fromDate(dataEnvio!) : null,
        'data_resposta':
            dataResposta != null ? Timestamp.fromDate(dataResposta!) : null,
        'data_cadastro': Timestamp.fromDate(dataCadastro),
        'data_atualizacao': Timestamp.fromDate(dataAtualizacao),
        'convite_token': tokenParaLink,
        'convite_status': contaVinculada ? 'vinculado' : 'link_gerado',
        if (idUsuario != null && idUsuario!.trim().isNotEmpty)
          'id_usuario': idUsuario!.trim(),
        if ((emailUsuario ?? '').trim().isNotEmpty)
          'email_usuario': emailUsuario!.trim(),
        if ((emailNormalizado ?? emailDaConta).trim().isNotEmpty)
          'email_normalizado':
              (emailNormalizado ?? emailDaConta).trim().toLowerCase(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao listar os grupos toMap: ${e.toString()}');
      }
      return {};
    }
  }

  factory ConvidadoModel.fromMap(Map<String, dynamic> map) {
    try {
      return ConvidadoModel.fromEntity(Convidado.fromMap(map));
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao listar os grupos fromMap: ${e.toString()}');
      }
      final now = DateTime.now();
      return ConvidadoModel(
        idConvidado: '',
        idEvento: '',
        nome: '',
        contato: '',
        dataCadastro: now,
        dataAtualizacao: now,
      );
    }
  }

  @override
  ConvidadoModel copyWith({
    String? idConvidado,
    String? idEvento,
    String? nome,
    String? contato,
    String? email,
    StatusConvidado? status,
    TipoConvidado? tipoConvidado,
    String? idGrupo,
    String? nomeGrupo,
    String? idMesa,
    int? numeroMesa,
    bool? ocupaAssento,
    bool? cuidadoEspecial,
    DateTime? dataEnvio,
    DateTime? dataResposta,
    DateTime? dataCadastro,
    DateTime? dataAtualizacao,
    String? conviteToken,
    String? idUsuario,
    String? conviteStatus,
    String? emailUsuario,
    String? emailNormalizado,
  }) {
    return ConvidadoModel(
      idConvidado: idConvidado ?? this.idConvidado,
      idEvento: idEvento ?? this.idEvento,
      nome: nome ?? this.nome,
      contato: contato ?? this.contato,
      email: email ?? this.email,
      status: status ?? this.status,
      tipoConvidado: tipoConvidado ?? this.tipoConvidado,
      idGrupo: idGrupo ?? this.idGrupo,
      nomeGrupo: nomeGrupo ?? this.nomeGrupo,
      idMesa: idMesa ?? this.idMesa,
      numeroMesa: numeroMesa ?? this.numeroMesa,
      ocupaAssento: ocupaAssento ?? this.ocupaAssento,
      cuidadoEspecial: cuidadoEspecial ?? this.cuidadoEspecial,
      dataEnvio: dataEnvio ?? this.dataEnvio,
      dataResposta: dataResposta ?? this.dataResposta,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      dataAtualizacao: dataAtualizacao ?? DateTime.now(),
      conviteToken: conviteToken ?? this.conviteToken,
      idUsuario: idUsuario ?? this.idUsuario,
      conviteStatus: conviteStatus ?? this.conviteStatus,
      emailUsuario: emailUsuario ?? this.emailUsuario,
      emailNormalizado: emailNormalizado ?? this.emailNormalizado,
    );
  }
}
