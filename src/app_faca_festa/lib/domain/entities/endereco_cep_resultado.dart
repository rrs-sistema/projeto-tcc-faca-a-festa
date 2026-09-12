class EnderecoCepResultado {
  final String cep;
  final String logradouro;
  final String numero;
  final String bairro;
  final String cidade;
  final String uf;
  final double? latitude;
  final double? longitude;
  final String formatado;
  final String origemCalculo;
  final bool possuiCoordenadas;

  const EnderecoCepResultado({
    required this.cep,
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.uf,
    required this.latitude,
    required this.longitude,
    required this.formatado,
    required this.origemCalculo,
    required this.possuiCoordenadas,
  });
}
