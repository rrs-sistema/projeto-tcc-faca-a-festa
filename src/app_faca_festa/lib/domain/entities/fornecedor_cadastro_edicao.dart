import 'endereco_usuario.dart';
import 'fornecedor.dart';
import 'fornecedor_categoria.dart';
import 'fornecedor_dados_cadastrais.dart';
import 'fornecedor_produto_servico.dart';
import 'servico_produto.dart';
import 'usuario.dart';

class FornecedorCadastroEdicao {
  const FornecedorCadastroEdicao(
      {required this.fornecedor,
      required this.usuario,
      required this.endereco,
      required this.categorias,
      required this.vinculos,
      this.revisao = 0});
  final Fornecedor fornecedor;
  final Usuario usuario;
  final EnderecoUsuario? endereco;
  final List<FornecedorCategoria> categorias;
  final List<FornecedorProdutoServico> vinculos;
  final int revisao;
}

class FornecedorCadastroAlteracao {
  const FornecedorCadastroAlteracao(
      {required this.origem,
      required this.dados,
      required this.nomeResponsavel,
      required this.endereco,
      required this.categorias,
      required this.servicos,
      required this.tipoEventoIds,
      required this.tipoEventoSlugs,
      required this.tipoEventoNomes,
      this.novoBannerUrl});
  final FornecedorCadastroEdicao origem;
  final FornecedorDadosCadastrais dados;
  final String nomeResponsavel;
  final EnderecoUsuario endereco;
  final List<FornecedorCategoria> categorias;
  final List<ServicoProduto> servicos;
  final List<String> tipoEventoIds;
  final List<String> tipoEventoSlugs;
  final List<String> tipoEventoNomes;

  /// Nulo preserva o banner atual, inclusive se atualizado em outro acesso.
  final String? novoBannerUrl;
}
