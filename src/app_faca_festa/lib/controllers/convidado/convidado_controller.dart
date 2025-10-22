import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import './../../data/models/model.dart';

class ConvidadoController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Lista completa de convidados do evento atual
  final RxList<ConvidadoModel> convidados = <ConvidadoModel>[].obs;

  // 🔹 Estados de carregamento e erro
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  // 🔹 IDs e filtros auxiliares
  final RxString idEventoAtual = ''.obs;
  final RxString termoBusca = ''.obs;

// =============================================================
// 🔹 Lista temporária de novos convidados (somente em memória)
// =============================================================
  final RxList<ConvidadoModel> novosConvidados = <ConvidadoModel>[].obs;

  /// 🔹 Adiciona novo convidado temporário
  void adicionarNovoConvidadoLocal(ConvidadoModel convidado) {
    novosConvidados.add(convidado);
  }

  /// 🔹 Remove convidado da lista local
  void removerNovoConvidadoLocal(String idConvidado) {
    novosConvidados.removeWhere((c) => c.idConvidado == idConvidado);
  }

  /// 🔹 Persiste todos os convidados novos no Firestore
  Future<void> enviarNovosConvidados() async {
    if (novosConvidados.isEmpty) return;

    try {
      carregando.value = true;
      for (final c in novosConvidados) {
        await _db.collection('convidado').doc(c.idConvidado).set(c.toMap());
      }
      novosConvidados.clear();
    } catch (e) {
      erro.value = 'Erro ao salvar convidados: $e';
    } finally {
      carregando.value = false;
    }
  }

  /// =============================================================
  /// 🔹 Escuta em tempo real todos os convidados de um evento
  /// =============================================================
  Future<void> escutarConvidados(String idEvento) async {
    if (idEvento.isEmpty) return;
    idEventoAtual.value = idEvento;

    _db.collection('convidado').where('id_evento', isEqualTo: idEvento).snapshots().listen(
        (snapshot) {
      final lista = snapshot.docs.map((d) {
        final data = d.data();
        return ConvidadoModel.fromMap(data);
      }).toList();

      convidados.assignAll(lista);
    }, onError: (e) {
      erro.value = 'Erro ao carregar convidados: $e';
    });
  }

  /// =============================================================
  /// 🔹 Adiciona um novo convidado ao evento
  /// =============================================================
  Future<void> adicionarConvidado(ConvidadoModel model) async {
    try {
      carregando.value = true;
      await _db.collection('convidado').doc(model.idConvidado).set(model.toMap());
    } catch (e) {
      erro.value = 'Erro ao salvar convidado: $e';
    } finally {
      carregando.value = false;
    }
  }

  /// =============================================================
  /// 🔹 Atualiza o status do convidado (Pendente, Confirmado, Recusado)
  /// =============================================================
  Future<void> atualizarStatus(String idConvidado, StatusConvidado status) async {
    try {
      await _db.collection('convidado').doc(idConvidado).update({
        'status': status.firestoreValue,
        'data_resposta': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      erro.value = 'Erro ao atualizar status: $e';
    }
  }

  /// =============================================================
  /// 🔹 Exclui um convidado
  /// =============================================================
  Future<void> excluirConvidado(String idConvidado) async {
    try {
      await _db.collection('convidado').doc(idConvidado).delete();
    } catch (e) {
      erro.value = 'Erro ao excluir convidado: $e';
    }
  }

  /// 🔹 Agrupa convidados por mesa/grupo
  Map<String, List<ConvidadoModel>> get convidadosPorMesa {
    final Map<String, List<ConvidadoModel>> grupos = {};
    for (var c in convidados) {
      final grupo = c.grupoMesa ?? 'Sem mesa';
      grupos.putIfAbsent(grupo, () => []);
      grupos[grupo]!.add(c);
    }
    return grupos;
  }

  /// 🔹 Calcula estatísticas gerais de mesas
  Map<String, dynamic> get estatisticasMesas {
    final grupos = convidadosPorMesa;
    final totalMesas = grupos.length;
    final totalAssentos = grupos.values.fold<int>(0, (a, b) => a + b.length);
    final totalOcupados = convidados.where((c) => c.status == StatusConvidado.confirmado).length;
    final totalLivres = totalAssentos - totalOcupados;

    return {
      'totalMesas': totalMesas,
      'assentos': totalAssentos,
      'ocupados': totalOcupados,
      'livres': totalLivres,
    };
  }

  /// =============================================================
  /// 🔹 Estatísticas rápidas para o organizador
  /// =============================================================
  int get totalConvidados => convidados.length;

  int get totalConfirmados =>
      convidados.where((c) => c.status == StatusConvidado.confirmado).length;

  int get totalPendentes => convidados.where((c) => c.status == StatusConvidado.pendente).length;

  int get totalRecusados => convidados.where((c) => c.status == StatusConvidado.recusado).length;

  int get totalAdultos => convidados.where((c) => c.adulto == true).length;

  int get totalCriancas => convidados.where((c) => c.adulto == false).length;

  /// =============================================================
  /// 🔹 Filtro de busca por nome ou e-mail
  /// =============================================================
  List<ConvidadoModel> get listaFiltrada {
    final termo = termoBusca.value.toLowerCase();
    if (termo.isEmpty) return convidados;
    return convidados
        .where((c) =>
            c.nome.toLowerCase().contains(termo) ||
            (c.email?.toLowerCase().contains(termo) ?? false))
        .toList();
  }

  /// =============================================================
  /// 🔹 Resetar tudo (ex: ao trocar de evento)
  /// =============================================================
  void limpar() {
    convidados.clear();
    idEventoAtual.value = '';
    termoBusca.value = '';
    erro.value = '';
  }
}
