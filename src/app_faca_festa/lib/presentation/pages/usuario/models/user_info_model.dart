class UserInfoModel {
  final String nome;
  final String? nomeParceiro; // usado só em casamento
  final DateTime dataNascimento;
  final String email;
  final String celular;
  final String cidade;
  final String uf;

  UserInfoModel({
    required this.nome,
    this.nomeParceiro,
    required this.dataNascimento,
    required this.email,
    required this.celular,
    required this.cidade,
    required this.uf,
  });
}
