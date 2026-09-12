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

  factory EnderecoCepResultado.fromMap(Map<String, dynamic> map) {
    return EnderecoCepResultado(
      cep: _texto(map['cep']),
      logradouro: _texto(map['logradouro']),
      numero: _texto(map['numero']),
      bairro: _texto(map['bairro']),
      cidade: _texto(map['cidade']),
      uf: _texto(map['uf']).toUpperCase(),
      latitude: _numero(map['latitude']),
      longitude: _numero(map['longitude']),
      formatado: _texto(map['formatado']),
      origemCalculo: _texto(map['origemCalculo']),
      possuiCoordenadas: map['possuiCoordenadas'] == true,
    );
  }

  static String _texto(dynamic value) => (value ?? '').toString().trim();

  static double? _numero(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
