// ================================
// 🔹 Controller reativo GetX
// ================================
import 'package:get/get.dart';

class FornecedoreController extends GetxController {
  final fornecedores = <FornecedorData>[].obs;

  int get contratadosCount => fornecedores.where((f) => f.status == 'Contratado').length;

  @override
  void onInit() {
    super.onInit();
    fornecedores.assignAll([
      FornecedorData(
        image: 'assets/images/fornecedor_recepcao.jpeg',
        title: 'Recepção',
        subtitle: 'Do Jeito Certo',
        status: 'Contratado',
      ),
      FornecedorData(
        image: 'assets/images/fornecedor_buffet.jpeg',
        title: 'Buffet e Gastronomia',
        subtitle: 'Buffet Ideal',
        status: 'Em negociação',
      ),
      FornecedorData(
        image: 'assets/images/fornecedor_fotografia.jpeg',
        title: 'Fotografia e Filmagem',
        subtitle: 'Franciesca Fotografias',
        status: 'Contratado',
      ),
      FornecedorData(
        image: 'assets/images/fornecedor_decoracao.jpg',
        title: 'Decoração e Flores',
        subtitle: 'Lírio Branco Decorações',
        status: 'Aguardando orçamento',
      ),
    ]);
  }

  void reservarFornecedor(int index) {
    fornecedores[index] = fornecedores[index].copyWith(status: 'Contratado');
  }

  void solicitarOrcamento(int index) {
    fornecedores[index] = fornecedores[index].copyWith(status: 'Em negociação');
  }

  void avaliarFornecedor(int index) {
    Get.snackbar('Avaliação', '⭐ Avaliação registrada com sucesso!',
        snackPosition: SnackPosition.BOTTOM);
  }

  void adicionarFornecedorSimulado() {
    fornecedores.add(
      FornecedorData(
        title: 'Novo Serviço',
        subtitle: 'Fornecedor Simulado',
        status: 'Aguardando orçamento',
      ),
    );
  }
}

// ================================
// 🔹 Modelo de dados
// ================================
class FornecedorData {
  final String? image;
  final String title;
  final String subtitle;
  final String status;

  FornecedorData({
    this.image,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  FornecedorData copyWith({
    String? image,
    String? title,
    String? subtitle,
    String? status,
  }) {
    return FornecedorData(
      image: image ?? this.image,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      status: status ?? this.status,
    );
  }
}
