import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import './../../data/models/convidado/grupo_convidado_model.dart';
import './../../data/models/model.dart';

class GrupoConvidadoController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<GrupoConvidadoModel> grupos = <GrupoConvidadoModel>[].obs;

  // Lista normalizada de convidados do evento.
  //
  // O GrupoConvidadoModel não carrega mais uma lista interna de convidados.
  // As telas devem buscar os convidados pelo controller:
  // controller.convidadosDoGrupo(grupo.idGrupo)
  final RxList<ConvidadoModel> convidados = <ConvidadoModel>[].obs;

  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subGrupos;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subConvidados;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subConvidadosLegado;

  final Map<String, ConvidadoModel> _cacheConvidadosPrincipal = {};
  final Map<String, ConvidadoModel> _cacheConvidadosLegado = {};

  String? _idEventoAtual;

  CollectionReference<Map<String, dynamic>> get _gruposRef => _db.collection('grupos_convidado');

  CollectionReference<Map<String, dynamic>> get _convidadosRef => _db.collection('convidado');

  Future<void> escutarGrupos(String idEvento) async {
    final eventoId = idEvento.trim();

    if (eventoId.isEmpty) {
      await _cancelarEscutas();
      _idEventoAtual = null;
      grupos.clear();
      convidados.clear();
      carregando.value = false;
      return;
    }

    _idEventoAtual = eventoId;
    carregando.value = true;
    erro.value = '';

    await _cancelarEscutas();

    grupos.clear();
    convidados.clear();
    _cacheConvidadosPrincipal.clear();
    _cacheConvidadosLegado.clear();

    _subGrupos = _gruposRef.where('id_evento', isEqualTo: eventoId).snapshots().listen(
      (snapshot) {
        final lista = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());

          if ((data['id_grupo'] ?? '').toString().trim().isEmpty) {
            data['id_grupo'] = doc.id;
          }

          if ((data['id_evento'] ?? '').toString().trim().isEmpty) {
            data['id_evento'] = eventoId;
          }

          return GrupoConvidadoModel.fromMap(data);
        }).toList();

        lista.sort(
          (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
        );

        grupos.assignAll(lista);

        // Recalcula a tela quando os grupos chegam depois dos convidados.
        _publicarConvidadosNormalizados();

        carregando.value = false;
      },
      onError: (Object error, StackTrace stackTrace) {
        erro.value = 'Erro ao carregar grupos de convidados: $error';
        carregando.value = false;
      },
    );

    // Campo novo/padrão.
    _subConvidados = _convidadosRef.where('id_evento', isEqualTo: eventoId).snapshots().listen(
      (snapshot) {
        _cacheConvidadosPrincipal
          ..clear()
          ..addAll(_normalizarSnapshotConvidados(snapshot, eventoId));

        _publicarConvidadosNormalizados();
        carregando.value = false;
      },
      onError: (Object error, StackTrace stackTrace) {
        erro.value = 'Erro ao carregar convidados: $error';
        carregando.value = false;
      },
    );

    // Campo legado usado em alguns documentos antigos.
    _subConvidadosLegado =
        _convidadosRef.where('id_evento_evento', isEqualTo: eventoId).snapshots().listen(
      (snapshot) {
        _cacheConvidadosLegado
          ..clear()
          ..addAll(_normalizarSnapshotConvidados(snapshot, eventoId));

        _publicarConvidadosNormalizados();
        carregando.value = false;
      },
      onError: (Object error, StackTrace stackTrace) {
        // Não derruba a tela. Se o campo legado não existir nos dados atuais,
        // a consulta apenas retorna vazia.
        erro.value = 'Erro ao carregar convidados legados: $error';
        carregando.value = false;
      },
    );
  }

  Map<String, ConvidadoModel> _normalizarSnapshotConvidados(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String idEvento,
  ) {
    final mapa = <String, ConvidadoModel>{};

    for (final doc in snapshot.docs) {
      final data = _normalizarDadosConvidado(
        docId: doc.id,
        idEvento: idEvento,
        data: Map<String, dynamic>.from(doc.data()),
      );

      final convidado = ConvidadoModel.fromMap(data);
      final id = convidado.idConvidado.trim().isNotEmpty ? convidado.idConvidado : doc.id;

      mapa[id] = convidado;
    }

    return mapa;
  }

  Map<String, dynamic> _normalizarDadosConvidado({
    required String docId,
    required String idEvento,
    required Map<String, dynamic> data,
  }) {
    if ((data['id_convidado'] ?? '').toString().trim().isEmpty) {
      data['id_convidado'] = docId;
    }

    if ((data['id_evento'] ?? '').toString().trim().isEmpty) {
      data['id_evento'] = (data['id_evento_evento'] ?? data['evento_id'] ?? idEvento).toString();
    }

    // Compatibilidade com o campo antigo grupo_mesa.
    final nomeGrupo = (data['nome_grupo'] ?? data['grupo_mesa'] ?? '').toString().trim();

    if (nomeGrupo.isNotEmpty) {
      data['nome_grupo'] = nomeGrupo;
    }

    if ((data['id_grupo'] ?? '').toString().trim().isEmpty && nomeGrupo.isNotEmpty) {
      final grupo = _buscarGrupoPorNome(nomeGrupo);
      if (grupo != null) {
        data['id_grupo'] = grupo.idGrupo;
        data['nome_grupo'] = grupo.nome;
      }
    }

    // Compatibilidade com o campo antigo adulto.
    if ((data['tipo_convidado'] ?? '').toString().trim().isEmpty) {
      final adulto = data['adulto'];
      if (adulto == false) {
        data['tipo_convidado'] = 'crianca';
      } else {
        data['tipo_convidado'] = 'adulto';
      }
    }

    return data;
  }

  void _publicarConvidadosNormalizados() {
    final mapa = <String, ConvidadoModel>{
      ..._cacheConvidadosLegado,
      ..._cacheConvidadosPrincipal,
    };

    final lista = mapa.values.toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    convidados.assignAll(lista);

    _sincronizarResumoDosGrupos();
  }

  Future<void> adicionarGrupo(GrupoConvidadoModel grupo) async {
    erro.value = '';

    try {
      final data = Map<String, dynamic>.from(grupo.toMap());

      data['id_grupo'] = grupo.idGrupo;
      data['id_evento'] = grupo.idEvento;
      data['data_atualizacao'] = FieldValue.serverTimestamp();

      data.removeWhere((key, value) => value == null);

      await _gruposRef.doc(grupo.idGrupo).set(data, SetOptions(merge: true));
    } catch (e) {
      erro.value = 'Erro ao adicionar grupo: $e';
      rethrow;
    }
  }

  Future<void> atualizarGrupo(GrupoConvidadoModel grupo) async {
    erro.value = '';

    try {
      final data = Map<String, dynamic>.from(grupo.toMap());

      data['id_grupo'] = grupo.idGrupo;
      data['id_evento'] = grupo.idEvento;
      data['data_atualizacao'] = FieldValue.serverTimestamp();

      data.removeWhere((key, value) => value == null);

      await _gruposRef.doc(grupo.idGrupo).set(data, SetOptions(merge: true));
    } catch (e) {
      erro.value = 'Erro ao atualizar grupo: $e';
      rethrow;
    }
  }

  Future<void> excluirGrupo(
    String idGrupo, {
    bool desvincularConvidados = true,
  }) async {
    erro.value = '';

    try {
      final batch = _db.batch();

      if (desvincularConvidados) {
        final convidadosSnapshot = await _convidadosRef.where('id_grupo', isEqualTo: idGrupo).get();

        for (final doc in convidadosSnapshot.docs) {
          batch.update(doc.reference, {
            'id_grupo': null,
            'nome_grupo': null,
            'grupo_mesa': null,
            'data_atualizacao': FieldValue.serverTimestamp(),
          });
        }
      }

      batch.delete(_gruposRef.doc(idGrupo));

      await batch.commit();
    } catch (e) {
      erro.value = 'Erro ao excluir grupo: $e';
      rethrow;
    }
  }

  Future<void> vincularConvidadoAoGrupo({
    required ConvidadoModel convidado,
    required GrupoConvidadoModel grupo,
  }) async {
    erro.value = '';

    try {
      await _convidadosRef.doc(convidado.idConvidado).set(
        {
          'id_convidado': convidado.idConvidado,
          'id_evento': convidado.idEvento,
          'id_grupo': grupo.idGrupo,
          'nome_grupo': grupo.nome,
          'grupo_mesa': grupo.nome,
          'data_atualizacao': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      erro.value = 'Erro ao vincular convidado ao grupo: $e';
      rethrow;
    }
  }

  Future<void> removerConvidadoDoGrupo(ConvidadoModel convidado) async {
    erro.value = '';

    try {
      await _convidadosRef.doc(convidado.idConvidado).set(
        {
          'id_grupo': null,
          'nome_grupo': null,
          'grupo_mesa': null,
          'data_atualizacao': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      erro.value = 'Erro ao remover convidado do grupo: $e';
      rethrow;
    }
  }

  Future<void> vincularConvidadoNaMesa({
    required ConvidadoModel convidado,
    required String idMesa,
    required int numeroMesa,
  }) async {
    erro.value = '';

    try {
      await _convidadosRef.doc(convidado.idConvidado).set(
        {
          'id_mesa': idMesa,
          'numero_mesa': numeroMesa,
          'data_atualizacao': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      erro.value = 'Erro ao vincular convidado à mesa: $e';
      rethrow;
    }
  }

  Future<void> removerConvidadoDaMesa(ConvidadoModel convidado) async {
    erro.value = '';

    try {
      await _convidadosRef.doc(convidado.idConvidado).set(
        {
          'id_mesa': null,
          'numero_mesa': null,
          'data_atualizacao': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      erro.value = 'Erro ao remover convidado da mesa: $e';
      rethrow;
    }
  }

  List<ConvidadoModel> convidadosDoGrupo(String idGrupo) {
    final grupo = _buscarGrupoPorId(idGrupo);
    final nomeGrupo = _normalizarTexto(grupo?.nome ?? '');

    final lista = convidados.where((c) {
      if ((c.idGrupo ?? '').trim() == idGrupo) {
        return true;
      }

      if (nomeGrupo.isEmpty) {
        return false;
      }

      return _normalizarTexto(c.nomeGrupo ?? '') == nomeGrupo;
    }).toList();

    lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return lista;
  }

  List<ConvidadoModel> convidadosSemGrupo() {
    final lista = convidados.where((c) {
      final possuiIdGrupo = (c.idGrupo ?? '').trim().isNotEmpty;
      final possuiNomeGrupo = (c.nomeGrupo ?? '').trim().isNotEmpty;
      return !possuiIdGrupo && !possuiNomeGrupo;
    }).toList();

    lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return lista;
  }

  List<ConvidadoModel> convidadosDaMesa(String idMesa) {
    final lista = convidados.where((c) => c.idMesa == idMesa).toList();
    lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return lista;
  }

  List<ConvidadoModel> convidadosDaMesaNumero(int numeroMesa) {
    final lista = convidados.where((c) => c.numeroMesa == numeroMesa).toList();

    lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return lista;
  }

  Map<String, List<ConvidadoModel>> get convidadosPorGrupoId {
    final map = <String, List<ConvidadoModel>>{};

    for (final grupo in grupos) {
      map[grupo.idGrupo] = convidadosDoGrupo(grupo.idGrupo);
    }

    return map;
  }

  Map<int, List<ConvidadoModel>> get convidadosPorMesaNumero {
    final map = <int, List<ConvidadoModel>>{};

    for (final convidado in convidados) {
      final numeroMesa = convidado.numeroMesa;

      if (numeroMesa == null) {
        continue;
      }

      map.putIfAbsent(numeroMesa, () => <ConvidadoModel>[]);
      map[numeroMesa]!.add(convidado);
    }

    for (final lista in map.values) {
      lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    }

    return map;
  }

  Map<String, dynamic> get estatisticasGrupos {
    final total = convidados.length;

    final confirmados = convidados.where((c) => c.status == StatusConvidado.confirmado).length;

    final pendentes = convidados.where((c) => c.status == StatusConvidado.pendente).length;

    final recusados = convidados.where((c) => c.status == StatusConvidado.recusado).length;

    final adultos = convidados.where((c) => c.tipoConvidado == TipoConvidado.adulto).length;

    final criancas = convidados.where((c) => c.tipoConvidado == TipoConvidado.crianca).length;

    final bebes = convidados.where((c) => c.tipoConvidado == TipoConvidado.bebe).length;

    return {
      'totalGrupos': grupos.length,
      'gruposComConvidados': gruposComConvidados,
      'gruposVazios': gruposVazios,
      'totalConvidados': total,
      'confirmados': confirmados,
      'pendentes': pendentes,
      'recusados': recusados,
      'adultos': adultos,
      'criancas': criancas,
      'bebes': bebes,
      'semGrupo': convidadosSemGrupo().length,
    };
  }

  Map<String, dynamic> get estatisticasMesas {
    final mesas = convidadosPorMesaNumero;

    final totalMesas = mesas.length;
    final totalAssentosOcupados = convidados.where((c) => c.idMesa != null).length;

    final confirmadosEmMesa = convidados
        .where(
          (c) => c.idMesa != null && c.status == StatusConvidado.confirmado,
        )
        .length;

    return {
      'totalMesas': totalMesas,
      'totalAssentosOcupados': totalAssentosOcupados,
      'confirmadosEmMesa': confirmadosEmMesa,
    };
  }

  int get totalGrupos => grupos.length;

  int get gruposComConvidados {
    final porGrupo = convidadosPorGrupoId;
    return grupos.where((g) => (porGrupo[g.idGrupo] ?? const []).isNotEmpty).length;
  }

  int get gruposVazios {
    final porGrupo = convidadosPorGrupoId;
    return grupos.where((g) => (porGrupo[g.idGrupo] ?? const []).isEmpty).length;
  }

  int get totalConvidados => convidados.length;

  int get totalConfirmados {
    return convidados.where((c) => c.status == StatusConvidado.confirmado).length;
  }

  int get totalAdultos {
    return convidados.where((c) => c.tipoConvidado == TipoConvidado.adulto).length;
  }

  int get totalCriancas {
    return convidados.where((c) => c.tipoConvidado == TipoConvidado.crianca).length;
  }

  int get totalBebes {
    return convidados.where((c) => c.tipoConvidado == TipoConvidado.bebe).length;
  }

  Future<void> _sincronizarResumoDosGrupos() async {
    if (_idEventoAtual == null || grupos.isEmpty) return;

    try {
      final batch = _db.batch();
      var possuiAtualizacao = false;

      final porGrupo = convidadosPorGrupoId;

      for (final grupo in grupos) {
        final lista = porGrupo[grupo.idGrupo] ?? const <ConvidadoModel>[];

        final total = lista.length;
        final adultos = lista.where((c) => c.tipoConvidado == TipoConvidado.adulto).length;
        final criancas = lista.where((c) => c.tipoConvidado == TipoConvidado.crianca).length;
        final bebes = lista.where((c) => c.tipoConvidado == TipoConvidado.bebe).length;
        final confirmados = lista.where((c) => c.status == StatusConvidado.confirmado).length;

        final precisaAtualizar = grupo.totalConvidados != total ||
            grupo.totalAdultos != adultos ||
            grupo.totalCriancas != criancas ||
            grupo.totalBebes != bebes ||
            grupo.totalConfirmados != confirmados;

        if (!precisaAtualizar) {
          continue;
        }

        possuiAtualizacao = true;

        batch.set(
          _gruposRef.doc(grupo.idGrupo),
          {
            'total_convidados': total,
            'total_adultos': adultos,
            'total_criancas': criancas,
            'total_bebes': bebes,
            'total_confirmados': confirmados,
            'data_atualizacao': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      if (possuiAtualizacao) {
        await batch.commit();
      }
    } catch (e) {
      erro.value = 'Erro ao sincronizar resumo dos grupos: $e';
    }
  }

  GrupoConvidadoModel? _buscarGrupoPorId(String idGrupo) {
    for (final grupo in grupos) {
      if (grupo.idGrupo == idGrupo) {
        return grupo;
      }
    }

    return null;
  }

  GrupoConvidadoModel? _buscarGrupoPorNome(String nome) {
    final alvo = _normalizarTexto(nome);

    if (alvo.isEmpty) {
      return null;
    }

    for (final grupo in grupos) {
      if (_normalizarTexto(grupo.nome) == alvo) {
        return grupo;
      }
    }

    return null;
  }

  String _normalizarTexto(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> recarregar() async {
    final idEvento = _idEventoAtual;

    if (idEvento == null || idEvento.trim().isEmpty) {
      return;
    }

    await escutarGrupos(idEvento);
  }

  Future<void> _cancelarEscutas() async {
    await _subGrupos?.cancel();
    await _subConvidados?.cancel();
    await _subConvidadosLegado?.cancel();

    _subGrupos = null;
    _subConvidados = null;
    _subConvidadosLegado = null;
  }

  @override
  void onClose() {
    _cancelarEscutas();
    super.onClose();
  }
}
