import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/convidado/convidado_model.dart';
import '../../models/convidado/grupo_convidado_model.dart';
import 'package:app_faca_festa/core/conectividade/escrita_local_primeiro.dart';
import 'package:app_faca_festa/domain/repositories/grupo_convidado_repository.dart';

class GrupoConvidadoRemoteDatasource {
  GrupoConvidadoRemoteDatasource(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _grupos =>
      firestore.collection('grupos_convidado');

  CollectionReference<Map<String, dynamic>> get _convidados =>
      firestore.collection('convidado');

  Stream<List<GrupoConvidadoModel>> observarGrupos(String idEvento) {
    return _grupos
        .where('id_evento', isEqualTo: idEvento)
        .snapshots()
        .map((snapshot) {
      final grupos = snapshot.docs.map((document) {
        final data = Map<String, dynamic>.from(document.data());
        // Sempre usa o ID do documento: evita excluir/atualizar o doc errado
        // quando o campo id_grupo divergir.
        data['id_grupo'] = document.id;
        if ((data['id_evento'] ?? '').toString().trim().isEmpty) {
          data['id_evento'] = idEvento;
        }
        return GrupoConvidadoModel.fromMap(data);
      }).toList();

      grupos.sort(
        (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
      );
      return grupos;
    });
  }

  Stream<List<ConvidadoModel>> observarConvidados(String idEvento) {
    return _convidados.where('id_evento', isEqualTo: idEvento).snapshots().map(
      (snapshot) {
        final lista = _normalizarConvidados(snapshot, idEvento).values.toList()
          ..sort(
              (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
        return lista;
      },
    );
  }

  Map<String, ConvidadoModel> _normalizarConvidados(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String idEvento,
  ) {
    final convidados = <String, ConvidadoModel>{};
    for (final document in snapshot.docs) {
      final data = Map<String, dynamic>.from(document.data());
      if ((data['id_convidado'] ?? '').toString().trim().isEmpty) {
        data['id_convidado'] = document.id;
      }
      if ((data['id_evento'] ?? '').toString().trim().isEmpty) {
        data['id_evento'] =
            (data['id_evento_evento'] ?? data['evento_id'] ?? idEvento)
                .toString();
      }

      final nomeGrupo =
          (data['nome_grupo'] ?? data['grupo_mesa'] ?? '').toString().trim();
      if (nomeGrupo.isNotEmpty) data['nome_grupo'] = nomeGrupo;

      if ((data['tipo_convidado'] ?? '').toString().trim().isEmpty) {
        data['tipo_convidado'] = data['adulto'] == false ? 'crianca' : 'adulto';
      }

      final convidado = ConvidadoModel.fromMap(data);
      final id = convidado.idConvidado.trim().isNotEmpty
          ? convidado.idConvidado
          : document.id;
      convidados[id] = convidado;
    }
    return convidados;
  }

  Future<void> salvarGrupo(GrupoConvidadoModel grupo) async {
    final data = Map<String, dynamic>.from(grupo.toMap())
      ..['id_grupo'] = grupo.idGrupo
      ..['id_evento'] = grupo.idEvento
      ..['data_atualizacao'] = FieldValue.serverTimestamp()
      ..removeWhere((key, value) => value == null);
    await escritaLocalPrimeiro(
      _grupos.doc(grupo.idGrupo).set(data, SetOptions(merge: true)),
      descricao: 'grupo "${grupo.nome}"',
      chave: grupo.idGrupo,
    );
  }

  Future<void> excluirGrupo(
    String idGrupo, {
    String? idEvento,
    required bool desvincularConvidados,
  }) async {
    final batch = firestore.batch();
    if (desvincularConvidados) {
      // Precisa filtrar por id_evento: senão o list do convidado cai em
      // PERMISSION_DENIED (regra exige eventoDono(id_evento) na query).
      final eventoId = (idEvento ?? '').trim();
      final query = eventoId.isEmpty
          ? _convidados.where('id_grupo', isEqualTo: idGrupo)
          : _convidados
              .where('id_evento', isEqualTo: eventoId)
              .where('id_grupo', isEqualTo: idGrupo);
      final snapshot = await LeituraLocalPrimeiro.consulta(query);
      for (final document in snapshot.docs) {
        batch.update(document.reference, {
          'id_grupo': null,
          'nome_grupo': null,
          'grupo_mesa': null,
          'data_atualizacao': FieldValue.serverTimestamp(),
        });
      }
    }
    batch.delete(_grupos.doc(idGrupo));
    await escritaLocalPrimeiro(
      batch.commit(),
      descricao: 'exclusão de um grupo',
      chave: idGrupo,
    );
  }

  Future<void> _atualizarConvidado(
    ConvidadoModel convidado,
    Map<String, dynamic> dados,
    String descricao,
  ) {
    return escritaLocalPrimeiro(
      _convidados.doc(convidado.idConvidado).set({
        ...dados,
        'data_atualizacao': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
      descricao: '$descricao de ${convidado.nome}',
      chave: convidado.idConvidado,
    );
  }

  Future<void> vincularConvidadoAoGrupo(
    ConvidadoModel convidado,
    GrupoConvidadoModel grupo,
  ) {
    return _atualizarConvidado(
        convidado,
        {
          'id_convidado': convidado.idConvidado,
          'id_evento': convidado.idEvento,
          'id_grupo': grupo.idGrupo,
          'nome_grupo': grupo.nome,
          'grupo_mesa': grupo.nome,
        },
        'grupo');
  }

  Future<void> removerConvidadoDoGrupo(ConvidadoModel convidado) {
    return _atualizarConvidado(
        convidado,
        {'id_grupo': null, 'nome_grupo': null, 'grupo_mesa': null},
        'grupo');
  }

  Future<void> vincularConvidadoNaMesa(
    ConvidadoModel convidado,
    String idMesa,
    int numeroMesa,
  ) {
    return _atualizarConvidado(
        convidado, {'id_mesa': idMesa, 'numero_mesa': numeroMesa}, 'mesa');
  }

  Future<void> removerConvidadoDaMesa(ConvidadoModel convidado) {
    return _atualizarConvidado(
        convidado, {'id_mesa': null, 'numero_mesa': null}, 'mesa');
  }

  Future<void> atualizarResumos(List<ResumoGrupoConvidado> resumos) async {
    if (resumos.isEmpty) return;
    final batch = firestore.batch();
    for (final resumo in resumos) {
      batch.set(
        _grupos.doc(resumo.idGrupo),
        {
          'total_convidados': resumo.total,
          'total_adultos': resumo.adultos,
          'total_criancas': resumo.criancas,
          'total_bebes': resumo.bebes,
          'total_confirmados': resumo.confirmados,
          'data_atualizacao': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await escritaLocalPrimeiro(batch.commit(), descricao: 'resumo dos grupos');
  }
}
