import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_servico_detalhado.dart';
import 'package:app_faca_festa/domain/entities/servico_foto.dart';
import 'package:app_faca_festa/domain/entities/servico_produto.dart';

/// Lista usada na tela de cotação.
///
/// Prefere os serviços já localizados do fornecedor. Quando essa fonte não
/// tem itens ativos, monta a mesma lista a partir do catálogo (vínculo +
/// produto + foto) — a fonte que desenha o card "Serviço principal".
///
/// [idProdutoServicoDestaque] coloca o serviço clicado na frente. Se ele não
/// estiver na lista localizada, entra pelo catálogo. A lista completa permanece.
List<FornecedorServicoDetalhado> montarServicosParaCotacao({
  required Fornecedor fornecedor,
  required String nomeCategoria,
  required Iterable<FornecedorServicoDetalhado> servicosLocalizados,
  required Iterable<FornecedorProdutoServico> vinculos,
  required Iterable<ServicoProduto> catalogo,
  required Iterable<ServicoFoto> fotos,
  String? idProdutoServicoDestaque,
}) {
  final ativos = servicosLocalizados
      .where((s) => s.idFornecedor == fornecedor.idFornecedor && s.ativo)
      .toList();

  final lista = ativos.isNotEmpty
      ? List<FornecedorServicoDetalhado>.of(ativos)
      : _doCatalogo(
          fornecedor: fornecedor,
          nomeCategoria: nomeCategoria,
          vinculos: vinculos,
          catalogo: catalogo,
          fotos: fotos,
        );

  final destaque = idProdutoServicoDestaque?.trim() ?? '';
  if (destaque.isEmpty) return lista;

  if (!lista.any((s) => s.idProdutoServico == destaque)) {
    final extra = _doCatalogo(
      fornecedor: fornecedor,
      nomeCategoria: nomeCategoria,
      vinculos: vinculos,
      catalogo: catalogo,
      fotos: fotos,
      somenteProdutoId: destaque,
    );
    if (extra.isNotEmpty) {
      return [...extra, ...lista];
    }
  }

  final primeiro = <FornecedorServicoDetalhado>[];
  final resto = <FornecedorServicoDetalhado>[];
  for (final servico in lista) {
    if (servico.idProdutoServico == destaque) {
      primeiro.add(servico);
    } else {
      resto.add(servico);
    }
  }
  return [...primeiro, ...resto];
}

List<FornecedorServicoDetalhado> _doCatalogo({
  required Fornecedor fornecedor,
  required String nomeCategoria,
  required Iterable<FornecedorProdutoServico> vinculos,
  required Iterable<ServicoProduto> catalogo,
  required Iterable<ServicoFoto> fotos,
  String? somenteProdutoId,
}) {
  final montados = <FornecedorServicoDetalhado>[];
  for (final vinculo in vinculos) {
    if (vinculo.idFornecedor != fornecedor.idFornecedor) continue;
    if (somenteProdutoId != null &&
        vinculo.idProdutoServico != somenteProdutoId) {
      continue;
    }

    final produto = _produto(catalogo, vinculo.idProdutoServico);
    final foto = _foto(
      fotos,
      idFornecedor: fornecedor.idFornecedor,
      idProdutoServico: vinculo.idProdutoServico,
    );

    montados.add(
      FornecedorServicoDetalhado(
        id: vinculo.id,
        idFornecedor: fornecedor.idFornecedor,
        idProdutoServico: vinculo.idProdutoServico,
        idSubcategoria: vinculo.idSubcategoria ?? produto?.idSubcategoria,
        nomeServico: produto?.nome,
        nomeFornecedor: fornecedor.razaoSocial,
        descricaoServico: produto?.descricao,
        preco: vinculo.preco,
        quantidade: 1,
        precoPromocao: vinculo.precoPromocao,
        nomeCategoria: nomeCategoria,
        imagemUrl: foto?.url,
        tipoMedida: produto?.tipoMedida,
        ativo: vinculo.ativo,
      ),
    );
  }
  return montados;
}

ServicoProduto? _produto(Iterable<ServicoProduto> catalogo, String id) {
  for (final item in catalogo) {
    if (item.id == id) return item;
  }
  return null;
}

ServicoFoto? _foto(
  Iterable<ServicoFoto> fotos, {
  required String idFornecedor,
  required String idProdutoServico,
}) {
  for (final foto in fotos) {
    if (foto.idFornecedor == idFornecedor &&
        foto.idProdutoServico == idProdutoServico) {
      return foto;
    }
  }
  return null;
}
