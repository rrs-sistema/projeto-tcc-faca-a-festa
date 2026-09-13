class ServicoCatalogoAlerta {
  const ServicoCatalogoAlerta({
    required this.idServico,
    required this.nomeServico,
    this.alertas = const [],
  });

  final String idServico;
  final String nomeServico;
  final List<String> alertas;
}
