class EnderecoUsuario {
  final String id;
  final String idUsuario;
  final int idCidade;
  final String cep;
  final String logradouro;
  final String numero;
  final String? complemento;
  final String? bairro;
  final String? nomeCidade;
  final String? uf;
  final bool principal;
  final DateTime? dataCadastro;

  const EnderecoUsuario({
    required this.id,
    required this.idUsuario,
    required this.idCidade,
    required this.cep,
    required this.logradouro,
    required this.numero,
    this.complemento,
    this.bairro,
    this.nomeCidade,
    this.uf,
    this.principal = true,
    this.dataCadastro,
  });

  EnderecoUsuario copyWith({
    String? id,
    String? idUsuario,
    int? idCidade,
    String? cep,
    String? logradouro,
    String? numero,
    String? complemento,
    String? bairro,
    String? nomeCidade,
    String? uf,
    bool? principal,
    DateTime? dataCadastro,
  }) =>
      EnderecoUsuario(
        id: id ?? this.id,
        idUsuario: idUsuario ?? this.idUsuario,
        idCidade: idCidade ?? this.idCidade,
        cep: cep ?? this.cep,
        logradouro: logradouro ?? this.logradouro,
        numero: numero ?? this.numero,
        complemento: complemento ?? this.complemento,
        bairro: bairro ?? this.bairro,
        nomeCidade: nomeCidade ?? this.nomeCidade,
        uf: uf ?? this.uf,
        principal: principal ?? this.principal,
        dataCadastro: dataCadastro ?? this.dataCadastro,
      );
}
