import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../../data/models/convidado/grupo_convidado_model.dart';
import './../../data/models/model.dart';

class GrupoConvidadoController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<GrupoConvidadoModel> grupos = <GrupoConvidadoModel>[].obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  /// Escuta em tempo real todos os grupos de um evento
  StreamSubscription? _subConvidados;
  StreamSubscription? _subGrupos;

  Future<void> escutarGrupos(String idEvento) async {
    carregando.value = true;

    // 🔥 Cancelar listeners antigos
    await _subConvidados?.cancel();
    await _subGrupos?.cancel();

    // 🔥 Listener de GRUPOS
    _subGrupos = _db
        .collection('grupos_convidado')
        .where('id_evento', isEqualTo: idEvento)
        .snapshots()
        .listen((_) async {
      await _reconstruirGrupos(idEvento);
    });

    // 🔥 Listener de CONVIDADOS
    _subConvidados = _db
        .collection('convidado')
        .where('id_evento', isEqualTo: idEvento)
        .snapshots()
        .listen((_) async {
      await _reconstruirGrupos(idEvento);
    });

    carregando.value = false;
  }

  Future<void> adicionarGrupo(GrupoConvidadoModel grupo) async {
    await _db.collection('grupos_convidado').doc(grupo.idGrupo).set(grupo.toMap());
  }

  Future<void> excluirGrupo(String idGrupo) async {
    await _db.collection('grupos_convidado').doc(idGrupo).delete();
  }

  Future<void> _reconstruirGrupos(String idEvento) async {
    try {
      final gruposSnapshot =
          await _db.collection('grupos_convidado').where('id_evento', isEqualTo: idEvento).get();

      final convidadosSnapshot =
          await _db.collection('convidado').where('id_evento', isEqualTo: idEvento).get();

      final todosConvidados =
          convidadosSnapshot.docs.map((d) => ConvidadoModel.fromMap(d.data())).toList();

      final lista = gruposSnapshot.docs.map((g) {
        final grupo = GrupoConvidadoModel.fromMap(g.data()).copyWith(
          idGrupo: g.id,
        );

        final convGrupo = todosConvidados.where((c) => c.grupoMesa == grupo.nome).toList();

        return grupo.copyWith(convidados: convGrupo);
      }).toList();

      grupos.assignAll(lista);
    } catch (e) {
      erro.value = 'Erro ao reconstruir grupos: $e';
    }
  }

  /// 🔹 Agrupa convidados pelo número da mesa do grupo
  Map<int?, List<ConvidadoModel>> get convidadosPorMesaNumero {
    final Map<int?, List<ConvidadoModel>> mesas = {};

    for (var g in grupos) {
      mesas.putIfAbsent(g.numeroMesa, () => []);
      mesas[g.numeroMesa]!.addAll(g.convidados);
    }

    return mesas;
  }

  Map<String, dynamic> get estatisticasMesas {
    final mesas = convidadosPorMesaNumero;

    final totalMesas = mesas.length;
    final totalConvidados = mesas.values.fold<int>(0, (a, b) => a + b.length);
    final totalOcupados =
        mesas.values.expand((c) => c).where((c) => c.status == StatusConvidado.confirmado).length;

    return {
      'totalMesas': totalMesas,
      'totalConvidados': totalConvidados,
      'confirmados': totalOcupados,
    };
  }

  int get totalGrupos => grupos.length;
  int get gruposComConvidados => grupos.where((g) => g.convidados.isNotEmpty).length;
  int get gruposVazios => grupos.where((g) => g.convidados.isEmpty).length;
  int get totalConvidados => grupos.fold(0, (soma, g) => soma + g.convidados.length);
}
