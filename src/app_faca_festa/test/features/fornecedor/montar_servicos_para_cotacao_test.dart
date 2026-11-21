import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_servico_detalhado.dart';
import 'package:app_faca_festa/domain/entities/servico_foto.dart';
import 'package:app_faca_festa/domain/entities/servico_produto.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/cotacao/montar_servicos_para_cotacao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fornecedor = Fornecedor(
    idFornecedor: 'forn-1',
    idUsuario: 'user-1',
    razaoSocial: 'Decoração Ana',
    telefone: '44999999999',
    email: 'ana@email.com',
    dataCadastro: DateTime(2026, 1, 1),
  );

  FornecedorProdutoServico vinculo({
    required String id,
    required String produto,
    String? subcategoria,
    double preco = 100,
  }) {
    return FornecedorProdutoServico(
      id: id,
      idProdutoServico: produto,
      idFornecedor: fornecedor.idFornecedor,
      idSubcategoria: subcategoria,
      preco: preco,
    );
  }

  const decoracao = ServicoProduto(
    id: 'prod-decoracao',
    nome: 'Decoração temática completa',
    descricao: 'Projeto de ambientação',
    idSubcategoria: 'sub-decoracao',
    tipoMedida: 'evento',
    ativo: true,
  );

  const bolo = ServicoProduto(
    id: 'prod-bolo',
    nome: 'Bolo',
    idSubcategoria: 'sub-bolo',
    ativo: true,
  );

  test('monta a lista pelo catálogo quando a localização não tem o serviço',
      () {
    final lista = montarServicosParaCotacao(
      fornecedor: fornecedor,
      nomeCategoria: 'Decoração',
      servicosLocalizados: const [],
      vinculos: [
        vinculo(id: 'v1', produto: decoracao.id, preco: 250),
        vinculo(id: 'v2', produto: bolo.id, preco: 80),
        FornecedorProdutoServico(
          id: 'outro',
          idProdutoServico: 'x',
          idFornecedor: 'outro-fornecedor',
          preco: 10,
        ),
      ],
      catalogo: const [decoracao, bolo],
      fotos: [
        ServicoFoto(
          id: 'foto-1',
          idProdutoServico: decoracao.id,
          idFornecedor: fornecedor.idFornecedor,
          url: 'https://exemplo/decoracao.jpg',
        ),
      ],
      idProdutoServicoDestaque: decoracao.id,
    );

    expect(lista.map((s) => s.idProdutoServico), [
      decoracao.id,
      bolo.id,
    ]);
    expect(lista.first.nomeServico, 'Decoração temática completa');
    expect(lista.first.preco, 250);
    expect(lista.first.imagemUrl, 'https://exemplo/decoracao.jpg');
    expect(lista.first.idSubcategoria, 'sub-decoracao');
    expect(lista.first.nomeCategoria, 'Decoração');
  });

  test(
      'serviço clicado entra na frente mesmo se a subcategoria localizada não bate',
      () {
    final localizado = FornecedorServicoDetalhado(
      id: 'loc-bolo',
      idFornecedor: fornecedor.idFornecedor,
      idProdutoServico: bolo.id,
      idSubcategoria: 'sub-diferente',
      nomeServico: 'Bolo',
      preco: 80,
      quantidade: 1,
      ativo: true,
    );

    final lista = montarServicosParaCotacao(
      fornecedor: fornecedor,
      nomeCategoria: 'Decoração',
      servicosLocalizados: [localizado],
      vinculos: [
        vinculo(
          id: 'v1',
          produto: decoracao.id,
          subcategoria: null,
          preco: 250,
        ),
      ],
      catalogo: const [decoracao, bolo],
      fotos: const [],
      idProdutoServicoDestaque: decoracao.id,
    );

    expect(lista.map((s) => s.idProdutoServico), [decoracao.id, bolo.id]);
    expect(lista.first.idSubcategoria, 'sub-decoracao');
    expect(lista.first.nomeServico, 'Decoração temática completa');
  });

  test('sem destaque mantém os serviços ativos já localizados', () {
    final inativo = FornecedorServicoDetalhado(
      id: 'off',
      idFornecedor: fornecedor.idFornecedor,
      idProdutoServico: 'prod-off',
      preco: 1,
      quantidade: 1,
      ativo: false,
    );
    final ativo = FornecedorServicoDetalhado(
      id: 'on',
      idFornecedor: fornecedor.idFornecedor,
      idProdutoServico: bolo.id,
      nomeServico: 'Bolo',
      preco: 80,
      quantidade: 1,
      ativo: true,
    );

    final lista = montarServicosParaCotacao(
      fornecedor: fornecedor,
      nomeCategoria: 'Decoração',
      servicosLocalizados: [inativo, ativo],
      vinculos: [vinculo(id: 'v1', produto: decoracao.id)],
      catalogo: const [decoracao, bolo],
      fotos: const [],
    );

    expect(lista.map((s) => s.id), ['on']);
  });
}
