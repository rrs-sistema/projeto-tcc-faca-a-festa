import 'package:app_faca_festa/domain/entities/endereco_cep_resultado.dart';


class EnderecoCepResultadoModel extends EnderecoCepResultado {
  const EnderecoCepResultadoModel({
    required super.cep,
    required super.logradouro,
    required super.numero,
    required super.bairro,
    required super.cidade,
    required super.uf,
    required super.latitude,
    required super.longitude,
    required super.formatado,
    required super.origemCalculo,
    required super.possuiCoordenadas,
  });

  factory EnderecoCepResultadoModel.fromMap(Map<String, dynamic> map) {
    final cidade = _texto(map['cidade']).isNotEmpty
        ? _texto(map['cidade'])
        : _texto(map['localidade']);
    final uf = _texto(map['uf']).toUpperCase();
    final logradouro = _texto(map['logradouro']);
    final bairro = _texto(map['bairro']);
    final formatado = _texto(map['formatado']).isNotEmpty
        ? _texto(map['formatado'])
        : [
            logradouro,
            bairro,
            cidade,
            uf,
          ].where((parte) => parte.isNotEmpty).join(', ');

    return EnderecoCepResultadoModel(
      cep: _texto(map['cep']),
      logradouro: logradouro,
      numero: _texto(map['numero']),
      bairro: bairro,
      cidade: cidade,
      uf: uf,
      latitude: _numero(map['latitude']),
      longitude: _numero(map['longitude']),
      formatado: formatado,
      origemCalculo: _texto(map['origemCalculo']),
      possuiCoordenadas: map['possuiCoordenadas'] == true,
    );
  }

  factory EnderecoCepResultadoModel.fromViaCep(Map<String, dynamic> map) {
    return EnderecoCepResultadoModel.fromMap({
      ...map,
      'origemCalculo': 'viacep',
      'possuiCoordenadas': false,
    });
  }

  static String _texto(dynamic value) => (value ?? '').toString().trim();

  static double? _numero(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
