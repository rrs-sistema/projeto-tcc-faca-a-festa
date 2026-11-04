typedef LerReferenciaComissao = Future<Map<String, dynamic>?> Function(
    String colecao, String id);

/// Enriquece somente a apresentação; não altera valores nem grava a cobrança.
class ComissaoIdentificacaoService {
  ComissaoIdentificacaoService(this.ler);
  final LerReferenciaComissao ler;

  static String texto(Map dados, List<String> campos) {
    for (final campo in campos) {
      final valor = dados[campo];
      if (valor is String && valor.trim().isNotEmpty) return valor.trim();
    }
    return '';
  }

  Future<Map<String, dynamic>> completar(Map<String, dynamic> extrato,
      {required bool ehAdmin}) async {
    final cache = <String, Future<Map<String, dynamic>?>>{};
    Future<Map<String, dynamic>?> buscar(String colecao, String id) async {
      if (id.isEmpty || id.contains('/')) return null;
      return cache.putIfAbsent('$colecao/$id', () => ler(colecao, id));
    }

    final itens = extrato['obrigacoes'];
    if (itens is! List) return extrato;
    final resultado = <Map<String, dynamic>>[];
    Future<Map<String, dynamic>> completarItem(dynamic item) async {
      final o = Map<String, dynamic>.from(item as Map);
      final evento = texto(o, ['id_evento', 'idEvento']);
      final fornecedor = texto(o, ['id_fornecedor', 'idFornecedor']);
      final pagador = texto(o, ['id_pagador', 'idPagador']);
      if (texto(o, ['nome_evento', 'nomeEvento']).isEmpty) {
        final doc = await buscar('evento', evento);
        if (doc != null) {
          o['nome_evento'] = texto(doc, ['nome_evento', 'nomeEvento', 'nome']);
        }
      }
      if (texto(o, ['nome_fornecedor', 'nomeFornecedor']).isEmpty) {
        final doc = await buscar('fornecedor', fornecedor);
        if (doc != null) {
          o['nome_fornecedor'] = texto(
              doc, ['razao_social', 'razaoSocial', 'nomeFornecedor', 'nome']);
        }
      }
      if (texto(o, ['nome_pagador', 'nomePagador']).isEmpty) {
        if (pagador.isNotEmpty && pagador == fornecedor) {
          o['nome_pagador'] = texto(o, ['nome_fornecedor', 'nomeFornecedor']);
        } else if (ehAdmin) {
          final empresa = await buscar('fornecedor', pagador);
          var nome = empresa == null
              ? ''
              : texto(empresa, ['razao_social', 'razaoSocial', 'nome']);
          if (nome.isEmpty) {
            final usuario = await buscar('usuarios', pagador);
            if (usuario != null) nome = texto(usuario, ['nome']);
          }
          o['nome_pagador'] = nome;
        }
      }
      return o;
    }

    for (var i = 0; i < itens.length; i += 10) {
      resultado
          .addAll(await Future.wait(itens.skip(i).take(10).map(completarItem)));
    }
    return {...extrato, 'obrigacoes': resultado};
  }
}
