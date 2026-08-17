class GiftContribution {
  final String id;
  final String nome;
  final String? uid;
  final double valor;
  final String? mensagem;
  final DateTime data;

  const GiftContribution({
    required this.id,
    required this.nome,
    this.uid,
    required this.valor,
    this.mensagem,
    required this.data,
  });
}
