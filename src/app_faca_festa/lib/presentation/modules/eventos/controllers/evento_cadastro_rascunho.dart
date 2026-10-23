part of 'evento_cadastro_controller.dart';

extension EventoCadastroRascunho on EventoCadastroController {
  CadastroEventoRascunhoStore? get _storeCadastro =>
      _rascunhos is CadastroEventoRascunhoStore
          ? _rascunhos as CadastroEventoRascunhoStore
          : null;
  Map<String, TextEditingController> get _camposRascunho => {
        'nome': nomeEvento,
        'principal': nomePessoalPrincipal,
        'local': localEvento,
        'noiva': nomeNoiva,
        'parceiro': parceiro,
        'idade': idade,
        'bebe': bebe,
        'tema': tema,
        'descricao': descricao,
        'limite': custoEstimado,
        'adultos': totalAdultos,
        'criancas': totalCriancas,
        'bebes': totalBebes,
        'total': totalConvidados,
        'data': dataFesta,
        'fim': dataFimFesta,
        'hora': horaFesta,
        'cidade': cidade,
        'uf': uf,
        'email': email,
        'celular': celular,
        'cep': enderecoController.value.cepController,
        'logradouro': enderecoController.value.logradouroController,
        'numero': enderecoController.value.numeroController,
        'complemento': enderecoController.value.complementoController,
        'bairro': enderecoController.value.bairroController,
        'cidade_endereco': enderecoController.value.nomeCidadeController,
        'uf_endereco': enderecoController.value.ufController,
      };
  String get assinaturaPremissas => jsonEncode([
        tipoEventoSelecionado.value?.idTipoEvento,
        totalAdultos.text,
        totalCriancas.text,
        totalBebes.text,
        custoEstimado.text
      ]);

  Future<LeituraCadastrosLocais> listarCadastrosLocais() async {
    final usuario = app.usuarioLogado.value?.idUsuario;
    if (usuario == null || _storeCadastro == null) {
      return const LeituraCadastrosLocais([], []);
    }
    return _storeCadastro!.listarCadastros(usuario);
  }

  void observarCadastroLocal() {
    pararObservacaoCadastro();
    _usuarioCadastro = app.usuarioLogado.value?.idUsuario;
    _observandoCadastro = _storeCadastro != null && _usuarioCadastro != null;
    if (!_observandoCadastro) return;
    for (final campo in _camposRascunho.values) {
      campo.addListener(_agendarCadastro);
    }
    _workersCadastro.add(everAll([
      tipoEventoSelecionado,
      tipoCerimonia,
      estiloCasamento,
      idTema,
      temaLivre,
      dressCode,
      eventoVariosDias,
      padrinhos
    ], (_) => _agendarCadastro()));
  }

  void _agendarCadastro() {
    if (!_observandoCadastro) return;
    _debounceLocal?.cancel();
    _debounceLocal = Timer(const Duration(milliseconds: 300), () {
      unawaited(salvarCadastroLocal().catchError((Object _) {}));
    });
  }

  void pararObservacaoCadastro() {
    _debounceLocal?.cancel();
    if (_observandoCadastro) {
      for (final campo in _camposRascunho.values) {
        campo.removeListener(_agendarCadastro);
      }
    }
    _observandoCadastro = false;
    for (final worker in _workersCadastro) {
      worker.dispose();
    }
    _workersCadastro.clear();
  }

  void reconciliarEstimativa() {
    final anterior = rascunhoCalculadora;
    if (anterior == null) return;
    final tipo = tipoEventoSelecionado.value?.nome ?? anterior.tipoEvento;
    final adultos = _parseIntController(totalAdultos),
        criancas = _parseIntController(totalCriancas),
        bebes = _parseIntController(totalBebes);
    if (anterior.tipoEvento == tipo &&
        anterior.adultos == adultos &&
        anterior.criancas == criancas &&
        anterior.bebes == bebes &&
        anterior.limite == custoEstimadoInformado) {
      return;
    }
    rascunhoCalculadora = anterior.reconciliar(
        tipoEvento: tipo,
        adultos: adultos,
        criancas: criancas,
        bebes: bebes,
        limite: custoEstimadoInformado);
    avisoReconciliacao.value = anterior.tipoEvento != tipo
        ? 'O tipo da festa mudou. O catálogo será atualizado; seus ajustes manuais foram preservados.'
        : 'A estimativa usará o público e o limite atuais do cadastro.';
  }

  Future<void> salvarCadastroLocal() {
    _debounceLocal?.cancel();
    if (_cadastroConcluido) return Future.value();
    final store = _storeCadastro;
    final usuario = _usuarioCadastro ?? app.usuarioLogado.value?.idUsuario;
    if (store == null ||
        usuario == null ||
        usuario != app.usuarioLogado.value?.idUsuario) {
      return Future.value();
    }
    reconciliarEstimativa();
    final c = CadastroEventoRascunho(
        usuario: usuario,
        id: idRascunho,
        evento: idEvento.value,
        eventoConfirmado: _eventoConfirmado,
        atualizadoEm: DateTime.now(),
        estimativa: rascunhoCalculadora,
        formulario: {
          'campos': {
            for (final e in _camposRascunho.entries) e.key: e.value.text
          },
          'tipo': tipoEventoSelecionado.value?.idTipoEvento,
          'cerimonia': tipoCerimonia.value,
          'estilo': estiloCasamento.value,
          'id_tema': idTema.value,
          'tema_livre': temaLivre.value,
          'dress_code': dressCode.value,
          'varios_dias': eventoVariosDias.value,
          'padrinhos': padrinhos.toList(),
          'cidade_id': _ufCidadeController.idCidadeSelecionada,
          'novo_pendente': _novoEventoPendente,
          'capa': _imagemCapaUrl,
          'rotulo': _rotuloBanner,
        });
    final gravacao = _filaLocal
        .catchError((Object _) {})
        .then((_) => store.salvarCadastro(c));
    _filaLocal = gravacao;
    return gravacao.then((_) {
      if (c.id == idRascunho &&
          c.usuario == app.usuarioLogado.value?.idUsuario) {
        erroRascunhoLocal.value = '';
      }
    }, onError: (Object e) {
      if (c.id == idRascunho &&
          c.usuario == app.usuarioLogado.value?.idUsuario) {
        erroRascunhoLocal.value =
            'Não foi possível guardar neste aparelho. Tente novamente antes de sair.';
      }
      throw e;
    });
  }

  Future<void> retomarCadastro(CadastroEventoRascunho c) async {
    if (c.usuario != app.usuarioLogado.value?.idUsuario) {
      throw StateError('O rascunho pertence a outro usuário.');
    }
    pararObservacaoCadastro();
    limpar();
    _usuarioCadastro = c.usuario;
    idRascunho = c.id;
    idEvento.value = c.evento;
    _eventoConfirmado = c.eventoConfirmado;
    _novoEventoPendente =
        c.formulario['novo_pendente'] == true || c.evento.isEmpty;
    final campos =
        Map<String, dynamic>.from(c.formulario['campos'] as Map? ?? {});
    enderecoController.value.suspenderConsulta = true;
    for (final e in _camposRascunho.entries) {
      e.value.text = campos[e.key]?.toString() ?? '';
    }
    enderecoController.value.suspenderConsulta = false;
    tipoEventoSelecionado.value = tiposEvento
        .firstWhereOrNull((t) => t.idTipoEvento == c.formulario['tipo']);
    tipoCerimonia.value = c.formulario['cerimonia']?.toString() ?? '';
    estiloCasamento.value = c.formulario['estilo']?.toString() ?? '';
    idTema.value = c.formulario['id_tema']?.toString() ?? '';
    temaLivre.value = c.formulario['tema_livre'] == true;
    dressCode.value = c.formulario['dress_code']?.toString() ?? '';
    eventoVariosDias.value = c.formulario['varios_dias'] == true;
    padrinhos
        .assignAll(List<String>.from(c.formulario['padrinhos'] as List? ?? []));
    _imagemCapaUrl = c.formulario['capa'] as String?;
    _rotuloBanner = c.formulario['rotulo'] as String?;
    final cidadeId = c.formulario['cidade_id'] as int?;
    if (cidadeId != null) {
      _ufCidadeController.cidadeSelecionada.value = Cidade(
          id: '$cidadeId',
          idCidade: cidadeId,
          nome: enderecoController.value.nomeCidadeController.text,
          uf: enderecoController.value.ufController.text);
    }
    rascunhoCalculadora = c.estimativa;
    atualizarPreview();
    if (c.evento.isNotEmpty) {
      final salvo = await _repository.buscarPorId(c.evento);
      if (app.usuarioLogado.value?.idUsuario != c.usuario ||
          idRascunho != c.id) {
        return;
      }
      if (salvo == null && c.eventoConfirmado) {
        throw StateError('Não foi possível conferir o evento salvo.');
      }
      if (salvo != null) {
        if (salvo.idUsuario != c.usuario) {
          throw StateError('O evento pertence a outro usuário.');
        }
        _eventoOriginal = salvo;
        _eventoConfirmado = true;
      }
    }
    observarCadastroLocal();
  }

  Future<void> descartarCadastroLocal(CadastroEventoRascunho c) async {
    if (c.usuario != app.usuarioLogado.value?.idUsuario) {
      throw StateError('O rascunho pertence a outro usuário.');
    }
    if (c.id == idRascunho) pararObservacaoCadastro();
    await _filaLocal.catchError((Object _) {});
    await _storeCadastro?.removerCadastro(c.usuario, c.id);
    if (c.evento.isNotEmpty) {
      final legado = _rascunhos?.ler(c.usuario, c.evento);
      if (legado?.id == c.id) await _rascunhos?.remover(c.usuario, c.evento);
    }
    if (c.id == idRascunho) limpar();
  }

  Future<void> concluirCadastroLocal(String usuario, String id) async {
    _cadastroConcluido = true;
    pararObservacaoCadastro();
    await _filaLocal.catchError((Object _) {});
    try {
      await _storeCadastro?.removerCadastro(usuario, id);
    } catch (_) {
      _cadastroConcluido = false;
      rethrow;
    }
  }
}
