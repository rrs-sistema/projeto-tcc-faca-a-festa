part of 'register_controller.dart';

extension RegisterFornecedorSelecao on RegisterController {
  void adicionarCategoria(CategoriaServico cat) {
    categoriasSelecionadas.add(
      FornecedorCategoria(
        idFornecedor: '',
        idCategoria: cat.id,
        nomeCategoria: cat.nome,
      ),
    );
  }

  Future<void> _enviarBannerAposAutenticacao(String uid) async {
    final bytes = bannerBytes;
    if (bytes == null || bytes.isEmpty) return;

    try {
      EasyLoading.show(status: 'Enviando banner...');
      final uploadBanner = _uploadBanner;
      if (uploadBanner == null) {
        _log('Upload de banner não configurado para este fluxo.');
        return;
      }
      final nomeArquivo = (bannerArquivo?.name ?? '').trim();
      bannerUrl = await uploadBanner(
        bytes: bytes,
        nomeArquivo: nomeArquivo.isEmpty ? 'banner.jpg' : nomeArquivo,
        uid: uid,
      );
      _log('Banner enviado para o fornecedor $uid.');
    } catch (e, s) {
      _log('Banner não enviado após autenticação: $e');
      _log('StackTrace: $s');
      Get.snackbar(
        'Banner',
        'O cadastro segue sem a imagem. Você pode adicioná-la depois no perfil.',
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _salvarDadosFornecedorGoogle({
    required String uid,
    required String email,
  }) async {
    final novoFornecedor = Fornecedor(
      idFornecedor: uid,
      idUsuario: uid,
      razaoSocial: razaoSocial.value.trim(),
      telefone: telefone.value.trim(),
      email: email,
      aptoParaOperar: false,
      ativo: true,
      bannerUrl: bannerUrl,
      cnpj: cnpj.value.trim(),
      descricao: descricao.value.trim(),
      dataCadastro: DateTime.now(),
      tipoEventoIds: tipoEventoIds.toList(growable: false),
      tipoEventoSlugs: tipoEventoSlugs.toList(growable: false),
      tipoEventoNomes: tipoEventoNomes.toList(growable: false),
    );

    await _fornecedores.salvarFornecedor(novoFornecedor);

    for (final cat in categoriasSelecionadas) {
      final catUpdate = cat.copyWith(idFornecedor: uid);
      await _fornecedores.salvarCategoriaFornecedor(catUpdate);
    }

    for (final serv in servicosSelecionados) {
      final vinculo = FornecedorProdutoServico(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        idProdutoServico: serv.id,
        idFornecedor: uid,
        preco: 0.0,
        dataCadastro: DateTime.now(),
        ativo: true,
        idSubcategoria: serv.idSubcategoria,
        precoPromocao: 0.0,
      );
      await _servicosProduto.salvarVinculo(vinculo);
    }
  }

  void alternarSubcategoria(
      FornecedorCategoria catSel, SubcategoriaServico sub, bool selected) {
    final index = categoriasSelecionadas
        .indexWhere((c) => c.idCategoria == catSel.idCategoria);
    if (index == -1) return;

    final atual = categoriasSelecionadas[index];
    final subcats =
        List<FornecedorSubcategoriaResumo>.from(atual.subcategorias);

    if (selected) {
      subcats.add(
        FornecedorSubcategoriaResumo(
          idSubcategoria: sub.id,
          nomeSubcategoria: sub.nome,
        ),
      );
    } else {
      subcats.removeWhere((s) => s.idSubcategoria == sub.id);
    }

    categoriasSelecionadas[index] = atual.copyWith(subcategorias: subcats);
    categoriasSelecionadas.refresh();
  }

  /// 🔹 Alterna o estado de seleção de um serviço
  void alternarServico(ServicoProduto servico, bool selecionado) {
    if (selecionado) {
      servicosSelecionados.add(servico);
    } else {
      servicosSelecionados.remove(servico);
    }
    servicosSelecionados.refresh();
  }

  /// 🧠 Define todos os tipos de evento atendidos pelo fornecedor.
  /// Útil quando a tela trabalha com seleção múltipla e envia as listas completas.
  void definirTiposEventoAtendidos({
    required List<String> ids,
    required List<String> slugs,
    required List<String> nomes,
  }) {
    tipoEventoIds.assignAll(_normalizarLista(ids));
    tipoEventoSlugs.assignAll(_normalizarLista(slugs));
    tipoEventoNomes.assignAll(_normalizarLista(nomes));
  }

  /// 🧠 Alterna um tipo de evento atendido pelo fornecedor.
  /// Útil para ChoiceChip/FilterChip com seleção individual.
  void alternarTipoEventoAtendido({
    required String id,
    required String slug,
    required String nome,
    required bool selecionado,
  }) {
    final idLimpo = id.trim();
    final slugLimpo = slug.trim();
    final nomeLimpo = nome.trim();

    if (idLimpo.isEmpty) return;

    if (selecionado) {
      if (!tipoEventoIds.contains(idLimpo)) {
        tipoEventoIds.add(idLimpo);
      }

      if (slugLimpo.isNotEmpty && !tipoEventoSlugs.contains(slugLimpo)) {
        tipoEventoSlugs.add(slugLimpo);
      }

      if (nomeLimpo.isNotEmpty && !tipoEventoNomes.contains(nomeLimpo)) {
        tipoEventoNomes.add(nomeLimpo);
      }
    } else {
      tipoEventoIds.remove(idLimpo);
      tipoEventoSlugs.remove(slugLimpo);
      tipoEventoNomes.remove(nomeLimpo);
    }

    tipoEventoIds.refresh();
    tipoEventoSlugs.refresh();
    tipoEventoNomes.refresh();
  }

  bool isTipoEventoAtendidoSelecionado(String id) {
    return tipoEventoIds.contains(id.trim());
  }

  void limparTiposEventoAtendidos() {
    tipoEventoIds.clear();
    tipoEventoSlugs.clear();
    tipoEventoNomes.clear();
  }

  List<String> _normalizarLista(List<String> valores) {
    return valores
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  // 🔹 Carrega todas as subcategorias de uma categoria
  Future<void> carregarSubcategoriasPorCategoria(String idCategoria) async {
    try {
      carregando.value = true;
      final lista = await _catalogoServico.listarSubcategorias(
        idCategoria: idCategoria,
      );
      subcategoriasPorCategoria[idCategoria] = lista;
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar subcategorias: $e');
    } finally {
      carregando.value = false;
    }
  }

  /// 🆕 Limpa subcategorias de uma categoria específica
  void limparSubcategorias(String idCategoria) {
    subcategoriasPorCategoria.remove(idCategoria);
  }

  /// 🆕 Limpa todas as subcategorias
  void limparTudo() {
    subcategoriasPorCategoria.clear();
  }
}
