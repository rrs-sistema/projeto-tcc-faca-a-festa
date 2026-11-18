import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/domain/entities/evento_admin.dart';
import '../../models/admin/evento_com_tipo_model.dart';

class EventosAdminRemoteDatasource {
  EventosAdminRemoteDatasource({
    required FirebaseFirestore firestore,
    CallableSessaoGateway? gateway,
  })  : _db = firestore,
        _gateway = gateway ?? FirebaseCallableSessaoGateway();

  final FirebaseFirestore _db;
  final CallableSessaoGateway _gateway;

  Future<List<EventoComTipoModel>> listarEventosComTipo() async {
    final resultados = await Future.wait([
      _db.collection('evento').get(),
      _contarCotacoesPorEvento(),
    ]);

    final eventosSnap = resultados[0] as QuerySnapshot<Map<String, dynamic>>;
    final cotacoesPorEvento = resultados[1] as Map<String, int>;

    final tiposCache = <String, String>{};
    final contagemPorUsuario = <String, int>{};

    for (final doc in eventosSnap.docs) {
      final data = doc.data();
      final idUsuario =
          (data['idUsuario'] ?? data['id_usuario'] ?? data['usuarioId'] ?? '')
              .toString()
              .trim();
      if (idUsuario.isEmpty) continue;
      contagemPorUsuario[idUsuario] = (contagemPorUsuario[idUsuario] ?? 0) + 1;
    }

    final listaEventos = <EventoComTipoModel>[];

    for (final doc in eventosSnap.docs) {
      final data = doc.data();
      final idTipoEvento =
          (data['id_tipo_evento'] ?? data['idTipoEvento'] ?? '').toString();
      final idUsuario =
          (data['idUsuario'] ?? data['id_usuario'] ?? data['usuarioId'] ?? '')
              .toString()
              .trim();

      final nomeTipo = await _buscarNomeTipoEvento(idTipoEvento, tiposCache);
      listaEventos.add(
        EventoComTipoModel.fromMap(
          data,
          doc.id,
          nomeTipo,
          totalCotacoes: cotacoesPorEvento[doc.id] ?? 0,
          eventosDoOrganizador:
              idUsuario.isEmpty ? 1 : (contagemPorUsuario[idUsuario] ?? 1),
        ),
      );
    }

    return listaEventos;
  }

  Future<Map<String, int>> _contarCotacoesPorEvento() async {
    final snap = await _db.collection('cotacao').get();
    final contagem = <String, int>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final idEvento =
          (data['id_evento'] ?? data['idEvento'] ?? '').toString().trim();
      if (idEvento.isEmpty) continue;
      contagem[idEvento] = (contagem[idEvento] ?? 0) + 1;
    }
    return contagem;
  }

  Future<void> aprovarEvento(String id) {
    return _db.collection('evento').doc(id).update({'aprovado': true});
  }

  Future<void> excluirEvento(String id) {
    return _db.collection('evento').doc(id).delete();
  }

  Future<List<FornecedorSugestaoAdmin>> sugerirFornecedores({
    required String idEvento,
    int limite = 5,
  }) async {
    final raw = await _gateway.chamar('gerenciarOportunidadeEventoAdmin', {
      'acao': 'sugerir_fornecedores',
      'idEvento': idEvento,
      'limite': limite,
    });
    final lista = raw['recomendacoes'];
    if (lista is! List) return const [];
    return lista
        .whereType<Map>()
        .map((e) =>
            FornecedorSugestaoAdmin.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<FollowUpComercial> marcarFollowUp({
    required String idEvento,
    String nota = '',
    DateTime? proximoContato,
  }) async {
    final raw = await _gateway.chamar('gerenciarOportunidadeEventoAdmin', {
      'acao': 'marcar_follow_up',
      'idEvento': idEvento,
      'nota': nota,
      if (proximoContato != null)
        'proximoContato': proximoContato.toUtc().toIso8601String(),
    });
    final follow = raw['followUp'];
    if (follow is Map) {
      return FollowUpComercial.fromMap(Map<String, dynamic>.from(follow))
          .copyWithMarcado();
    }
    return FollowUpComercial(
      marcado: true,
      nota: nota.isEmpty ? null : nota,
      proximoContato: proximoContato,
      em: DateTime.now(),
    );
  }

  Future<void> limparFollowUp(String idEvento) async {
    await _gateway.chamar('gerenciarOportunidadeEventoAdmin', {
      'acao': 'limpar_follow_up',
      'idEvento': idEvento,
    });
  }

  Future<({NudgeCotacao nudge, List<FornecedorSugestaoAdmin> recomendacoes})>
      enviarNudgeOrganizador({
    required String idEvento,
    String? mensagem,
    bool gerarRecomendacoes = true,
  }) async {
    final raw = await _gateway.chamar('gerenciarOportunidadeEventoAdmin', {
      'acao': 'nudge_organizador',
      'idEvento': idEvento,
      if (mensagem != null && mensagem.trim().isNotEmpty) 'mensagem': mensagem,
      'gerarRecomendacoes': gerarRecomendacoes,
    });
    final lista = raw['recomendacoes'];
    final recomendacoes = lista is List
        ? lista
            .whereType<Map>()
            .map((e) =>
                FornecedorSugestaoAdmin.fromMap(Map<String, dynamic>.from(e)))
            .toList()
        : <FornecedorSugestaoAdmin>[];
    return (
      nudge: NudgeCotacao(
        em: DateTime.now(),
        mensagem: mensagem ?? '',
        qtdFornecedores: recomendacoes.length,
      ),
      recomendacoes: recomendacoes,
    );
  }

  Future<String> _buscarNomeTipoEvento(
    String idTipoEvento,
    Map<String, String> cache,
  ) async {
    const nomePadrao = 'Tipo não informado';
    if (idTipoEvento.isEmpty) return nomePadrao;
    final cached = cache[idTipoEvento];
    if (cached != null) return cached;

    final tipoDoc = await _db.collection('tipo_evento').doc(idTipoEvento).get();
    if (tipoDoc.exists) {
      final nome = (tipoDoc.data()?['nome'] ?? nomePadrao).toString();
      cache[idTipoEvento] = nome;
      return nome;
    }

    final tipoSnap = await _db
        .collection('tipo_evento')
        .where('id_tipo_evento', isEqualTo: idTipoEvento)
        .limit(1)
        .get();
    if (tipoSnap.docs.isEmpty) {
      cache[idTipoEvento] = nomePadrao;
      return nomePadrao;
    }

    final nome = (tipoSnap.docs.first.data()['nome'] ?? nomePadrao).toString();
    cache[idTipoEvento] = nome;
    return nome;
  }
}

extension on FollowUpComercial {
  FollowUpComercial copyWithMarcado() => FollowUpComercial(
        marcado: true,
        em: em ?? DateTime.now(),
        por: por,
        nota: nota,
        proximoContato: proximoContato,
      );
}
