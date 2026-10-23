import 'package:flutter_test/flutter_test.dart';

/// Replica a regra corrigida: categoria NÃO dispensa leitura do detalhe pago.
_CategoriaDetalhes conciliar({
  required String? idCategoria,
  required String nomeCategoria,
  required double custoEstimadoOrcamento,
  required _CategoriaDetalhes? detalheGastos,
}) {
  var categoriaNome = 'Outros';
  var custoEstimado = custoEstimadoOrcamento;
  if (idCategoria != null && idCategoria.isNotEmpty) {
    categoriaNome = nomeCategoria;
  }
  final valorPago = detalheGastos?.valorPago ?? 0.0;
  if (idCategoria == null || idCategoria.isEmpty) {
    if (detalheGastos != null) {
      categoriaNome = detalheGastos.nome;
      if (detalheGastos.custoEstimado > 0) {
        custoEstimado = detalheGastos.custoEstimado;
      }
    }
  }
  return _CategoriaDetalhes(
    nome: categoriaNome,
    custoEstimado: custoEstimado,
    valorPago: valorPago,
  );
}

class _CategoriaDetalhes {
  const _CategoriaDetalhes({
    required this.nome,
    required this.custoEstimado,
    required this.valorPago,
  });
  final String nome;
  final double custoEstimado;
  final double valorPago;
}

void main() {
  test('com categoria e pagamento detalhado, admin concilia o pago', () {
    final resultado = conciliar(
      idCategoria: 'cat-buffet',
      nomeCategoria: 'Buffet',
      custoEstimadoOrcamento: 10000,
      detalheGastos: const _CategoriaDetalhes(
        nome: 'Entrada, Prato',
        custoEstimado: 10000,
        valorPago: 3000,
      ),
    );
    expect(resultado.nome, 'Buffet');
    expect(resultado.custoEstimado, 10000);
    expect(resultado.valorPago, 3000);
  });

  test('sem categoria ainda usa nomes e totais do detalhe', () {
    final resultado = conciliar(
      idCategoria: null,
      nomeCategoria: 'Outros',
      custoEstimadoOrcamento: 0,
      detalheGastos: const _CategoriaDetalhes(
        nome: 'Som, Luz',
        custoEstimado: 2500,
        valorPago: 800,
      ),
    );
    expect(resultado.nome, 'Som, Luz');
    expect(resultado.valorPago, 800);
  });
}
