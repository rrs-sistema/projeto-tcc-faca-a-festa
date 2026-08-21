import 'package:get/get.dart';

import '../../data/models/admin/orcamento_admin_model.dart';
import '../../domain/usecases/carregar_orcamentos_admin.dart';

import 'package:flutter/foundation.dart';

class OrcamentosAdminController extends GetxController {
  OrcamentosAdminController({
    required CarregarOrcamentosAdmin carregarOrcamentos,
  }) : _carregarOrcamentos = carregarOrcamentos;

  final CarregarOrcamentosAdmin _carregarOrcamentos;

  final orcamentos = <OrcamentoAdminModel>[].obs;
  final detalhesVisiveis = <String, bool>{}.obs;
  final busca = ''.obs;
  final carregando = false.obs;
  final erro = ''.obs;

  List<OrcamentoAdminModel> get orcamentosFiltrados {
    final termo = busca.value.trim().toLowerCase();
    if (termo.isEmpty) return orcamentos.toList();
    return orcamentos.where((o) {
      return o.eventoNome.toLowerCase().contains(termo) ||
          o.categoria.toLowerCase().contains(termo) ||
          o.cidade.toLowerCase().contains(termo) ||
          o.status.toLowerCase().contains(termo);
    }).toList();
  }

  int get totalAbertos => orcamentos.where((o) {
        final s = o.status.toLowerCase();
        return s.contains('pendente') || s.contains('negocia');
      }).length;

  Future<void> carregarOrcamentosComEventoDetalhes() async {
    try {
      carregando.value = true;
      erro.value = '';

      orcamentos.value = await _carregarOrcamentos();
    } catch (e) {
      erro.value = 'Erro ao carregar orçamentos: $e';
      debugPrint("❌ Erro ao carregar orçamentos: $e");
    } finally {
      carregando.value = false;
    }
  }
}
