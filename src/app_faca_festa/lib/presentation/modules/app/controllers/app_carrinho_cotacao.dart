import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/servico_cotado.dart';

class AppCarrinhoCotacao {
  final RxList<ServicoCotado> servicos = <ServicoCotado>[].obs;

  void adicionar(ServicoCotado servico) {
    if (!servicos.any((s) => s.idProduto == servico.idProduto)) {
      servicos.add(servico);
    }
  }

  void remover(String idProduto) {
    servicos.removeWhere((s) => s.idProduto == idProduto);
  }

  void limpar() {
    servicos.clear();
  }

  bool contem(String idProduto) {
    return servicos.any((s) => s.idProduto == idProduto);
  }
}
