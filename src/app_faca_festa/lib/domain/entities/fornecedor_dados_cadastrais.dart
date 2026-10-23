import 'fornecedor.dart';

/// Somente os campos cadastrais; não transporta status, proprietário ou métricas.
class FornecedorDadosCadastrais {
  FornecedorDadosCadastrais({
    required String razaoSocial,
    required String email,
    required String telefone,
    required String cnpj,
    required String descricao,
  })  : razaoSocial = razaoSocial.trim(),
        email = email.trim(),
        telefone = telefone.trim(),
        cnpj = cnpj.trim(),
        descricao = descricao.trim();

  final String razaoSocial;
  final String email;
  final String telefone;
  final String cnpj;
  final String descricao;

  Fornecedor aplicarEm(Fornecedor atual) => atual.copyWith(
        razaoSocial: razaoSocial,
        email: email,
        telefone: telefone,
        cnpj: cnpj,
        descricao: descricao,
      );

  /// Lista explícita para impedir a serialização acidental do fornecedor inteiro.
  Map<String, dynamic> toMap() => {
        'razao_social': razaoSocial,
        'cnpj': cnpj,
        'email': email,
        'telefone': telefone,
        'descricao': descricao,
      };
}
