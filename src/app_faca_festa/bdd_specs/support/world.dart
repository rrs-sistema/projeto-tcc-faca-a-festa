class AppWorld {
  String? idUsuario;
  String? idFornecedor;
  String? idServico;
  String? idEvento;

  bool botaoAvaliarServicoVisivel = false;
  bool botaoAvaliarFornecedorVisivel = false;

  bool mediaServicoAtualizada = false;
  bool mediaFornecedorAtualizada = false;
  bool rankingAtualizado = false;
  bool selosFornecedorAtualizados = false;
  bool pushEnviado = false;

  bool totalPagoIgualEstimado = false;

  // -----------------------
  // AÇÕES DE AMBIENTE
  // -----------------------

  Future<void> loginAsOrganizador() async {
    idUsuario = "user-organizador";
  }

  Future<void> criarFornecedorFake() async {
    idFornecedor = "forn-001";
  }

  Future<void> criarServicoFake() async {
    idServico = "serv-001";
  }

  Future<void> criarEventoFake() async {
    idEvento = "evento-001";
  }

  Future<void> abrirTelaFornecedor() async {
    botaoAvaliarServicoVisivel = true;
  }

  Future<void> solicitarCotacaoServico() async {
    // simulação
  }

  Future<void> selecionarNota(int nota) async {}

  Future<void> digitarComentario(String comentario) async {}

  Future<void> enviarAvaliacaoServico() async {
    mediaServicoAtualizada = true;
    mediaFornecedorAtualizada = true;
    selosFornecedorAtualizados = true;
    rankingAtualizado = true;
    pushEnviado = true;
  }

  Future<bool> documentoExiste(String caminho) async {
    return true;
  }

  Future<void> criarOrcamentoFechado() async {
    botaoAvaliarFornecedorVisivel = true;
  }

  Future<void> pagarOrcamentoInteiro() async {
    totalPagoIgualEstimado = true;
  }

  Future<void> abrirTelaOrcamento() async {}

  Future<void> enviarAvaliacaoFornecedor() async {}
}

final AppWorld world = AppWorld();
