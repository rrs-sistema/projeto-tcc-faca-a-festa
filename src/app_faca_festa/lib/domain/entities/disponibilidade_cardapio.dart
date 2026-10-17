/// Quantidades informadas pelo organizador. Não deriva de confirmação ou pagamento.
class DisponibilidadeCardapio {
  const DisponibilidadeCardapio(
      {required this.comprado,
      required this.estoque,
      required this.unidade,
      required this.estado,
      required this.nome,
      required this.publico});
  final double comprado, estoque;
  final String unidade, estado, nome, publico;

  bool get valida =>
      comprado.isFinite &&
      estoque.isFinite &&
      comprado >= 0 &&
      estoque >= 0 &&
      (comprado + estoque).isFinite &&
      unidade.isNotEmpty &&
      nome.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'comprado': comprado,
        'estoque': estoque,
        'unidade': unidade,
        'estado': estado,
        'nome': nome,
        'publico': publico
      };

  static DisponibilidadeCardapio? fromMap(dynamic data) {
    if (data is! Map || data['comprado'] is! num || data['estoque'] is! num) {
      return null;
    }
    final value = DisponibilidadeCardapio(
        comprado: (data['comprado'] as num).toDouble(),
        estoque: (data['estoque'] as num).toDouble(),
        unidade: data['unidade']?.toString() ?? '',
        estado: data['estado']?.toString() ?? '',
        nome: data['nome']?.toString() ?? '',
        publico: data['publico']?.toString() ?? '');
    return value.valida ? value : null;
  }
}
