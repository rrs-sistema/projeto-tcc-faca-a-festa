import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import './../../data/models/convidado/grupo_convidado_model.dart';
import './../../data/models/model.dart';

class GrupoConvidadoController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<GrupoConvidadoModel> grupos = <GrupoConvidadoModel>[].obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  /// Escuta em tempo real todos os grupos de um evento
  Future<void> escutarGrupos(String idEvento) async {
    carregando.value = true;
    _db.collection('grupos_convidado').where('id_evento', isEqualTo: idEvento).snapshots().listen(
        (snapshot) async {
      final lista = await Future.wait(snapshot.docs.map((doc) async {
        final grupo = GrupoConvidadoModel.fromMap(doc.data());
        final convidadosSnapshot = await _db
            .collection('convidado')
            .where('id_evento', isEqualTo: idEvento)
            .where('grupo_mesa', isEqualTo: grupo.nome)
            .get();

        final convidados =
            convidadosSnapshot.docs.map((c) => ConvidadoModel.fromMap(c.data())).toList();

        return grupo.copyWith(convidados: convidados);
      }));

      grupos.assignAll(lista);
      carregando.value = false;
    }, onError: (e) {
      erro.value = 'Erro ao carregar grupos: $e';
      carregando.value = false;
    });
  }

  Future<void> adicionarGrupo(GrupoConvidadoModel grupo) async {
    await _db.collection('grupos_convidado').doc(grupo.idGrupo).set(grupo.toMap());
  }

  Future<void> excluirGrupo(String idGrupo) async {
    await _db.collection('grupos_convidado').doc(idGrupo).delete();
  }

  int get totalGrupos => grupos.length;
  int get gruposComConvidados => grupos.where((g) => g.convidados.isNotEmpty).length;
  int get gruposVazios => grupos.where((g) => g.convidados.isEmpty).length;
  int get totalConvidados => grupos.fold(0, (soma, g) => soma + g.convidados.length);
}
