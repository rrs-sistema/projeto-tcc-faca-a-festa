class ServicoCatalogoAlerta {
  const ServicoCatalogoAlerta({
    required this.idServico,
    required this.nomeServico,
    this.alertas = const [],
  });

  final String idServico;
  final String nomeServico;
  final List<String> alertas;

  factory ServicoCatalogoAlerta.fromMap(Map<String, dynamic> map) {
    return ServicoCatalogoAlerta(
      idServico: (map['id_servico'] ?? map['idServico'] ?? '').toString().trim(),
      nomeServico:
          (map['nome_servico'] ?? map['nomeServico'] ?? '').toString().trim(),
      alertas: _stringList(map['alertas']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_servico': idServico,
      'nome_servico': nomeServico,
      'alertas': alertas,
    };
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
