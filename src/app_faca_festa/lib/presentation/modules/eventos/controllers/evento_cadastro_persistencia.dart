part of 'evento_cadastro_controller.dart';

extension EventoCadastroPersistencia on EventoCadastroController {
  void carregarEvento(Evento evento) {
    pararObservacaoCadastro();
    _eventoConfirmado = true;
    _cadastroConcluido = false;
    _novoEventoPendente = false;
    _eventoOriginal = evento;
    rascunhoCalculadora = null;
    carregando.value = false;
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    idEvento.value = evento.idEvento;
    nomeEvento.text = evento.nomeEvento;
    nomePessoalPrincipal.text = evento.nomePessoalPrincipal ?? '';
    nomeNoiva.text = evento.nomeNoiva ?? evento.nomeAniversariante ?? '';
    parceiro.text = evento.nomeNoivo ?? '';
    tema.text = evento.tema ?? '';
    idade.text = evento.idade?.toString() ?? '';
    bebe.text = evento.nomeBebe ?? '';
    tipoCerimonia.value = evento.tipoCerimonia ?? '';
    estiloCasamento.value = evento.estiloCasamento ?? '';
    idTema.value = evento.idTema ?? '';
    dressCode.value = evento.dressCode ?? '';
    _imagemCapaUrl = evento.imagemCapaUrl;
    _rotuloBanner = evento.rotuloBanner;
    temaLivre.value = (evento.idTema == null ||
            evento.idTema!.trim().isEmpty ||
            evento.idTema == TemaFestaViewModel.slugOutro) &&
        (evento.tema ?? '').trim().isNotEmpty;
    dataFesta.text = DateFormat('dd/MM/yyyy', 'pt_BR').format(evento.data);
    eventoVariosDias.value = evento.duracaoDias > 1;
    dataFimFesta.text = eventoVariosDias.value
        ? DateFormat('dd/MM/yyyy', 'pt_BR').format(evento.dataFim!)
        : '';
    horaFesta.text = evento.hora ?? '';
    padrinhos.assignAll(evento.padrinhos ?? []);

    // Legado mantém o total conhecido sem inventar a distribuição etária.
    totalAdultos.text = evento.totalAdultos?.toString() ?? '';
    totalCriancas.text = evento.totalCriancas?.toString() ?? '';
    totalBebes.text = evento.totalBebes?.toString() ?? '';
    totalConvidados.text = evento.previsaoPublicoInformada
        ? evento.totalConvidadosCalculado.toString()
        : '';

    // ✅ Formata custo estimado no padrão BR
    if (evento.custoEstimado != null && evento.custoEstimado! > 0) {
      custoEstimado.text = currencyFormat.format(evento.custoEstimado);
    } else {
      custoEstimado.text = '';
    }

    // ✅ Seleciona tipo de evento, se existir
    tipoEventoSelecionado.value = tiposEvento.firstWhereOrNull(
      (t) => t.idTipoEvento == evento.idTipoEvento,
    );

    // ✅ Preenche endereço (se existir)
    if (evento.cep != null ||
        evento.logradouro != null ||
        evento.bairro != null ||
        evento.numero != null) {
      final end = enderecoController.value;

      end.cepController.text = evento.cep ?? '';
      end.logradouroController.text = evento.logradouro ?? '';
      end.numeroController.text = evento.numero ?? '';
      end.complementoController.text = evento.complemento ?? '';
      end.bairroController.text = evento.bairro ?? '';
      end.nomeCidadeController.text = evento.nomeCidade ?? '';
      end.ufController.text = evento.uf ?? 'PR';

      // 🔹 Atualiza seleção reativa da cidade/UF no UFCidadeController
      if (evento.uf != null) {
        end.ufCidadeController.estadoSelecionado.value = Estado(
          id: '',
          nome: evento.uf!,
          uf: evento.uf!,
        );
      }

      if (evento.idCidade != null || evento.nomeCidade != null) {
        end.ufCidadeController.cidadeSelecionada.value = Cidade(
          id: evento.idCidade ?? '',
          nome: evento.nomeCidade ?? '',
          uf: evento.uf ?? '',
          idCidade: int.tryParse(evento.idCidade ?? ''),
        );
      }
    }

    atualizarPreview();
  }

  Future<void> salvarEvento(
      {Future<void> Function(RascunhoCalculadora, Evento)? vincularRascunho,
      Future<void> Function(Evento, RascunhoCalculadora?)? aoConcluir}) async {
    if (carregando.value) return;
    _log('===== INÍCIO salvarEvento $_versaoDiagnostico =====');
    _log('route=${Get.currentRoute} | args=${AuthFluxoArgs.of(Get.arguments)}');

    final user = app.usuarioLogado.value;
    final identidadeCadastro = idRascunho;
    _logUsuario(user);

    if (user == null) {
      Get.snackbar(
        'Erro',
        'Usuário não autenticado.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final cadastroConvidado = cadastroComoConvidado;
    _log(
        'Fluxo detectado: cadastroConvidado=$cadastroConvidado | enderecoObrigatorio=${!cadastroConvidado}');

    // ✅ Para organizador, mantém a validação completa do formulário.
    // ✅ Para convidado, evita que validators da tela bloqueiem o salvamento
    // por causa dos campos de endereço.
    if (!cadastroConvidado) {
      final formValido = formKey.currentState?.validate() ?? false;
      _log('Validação FormKey organizador => $formValido');
      if (!formValido) {
        _log('BLOQUEADO: FormKey inválido antes das validações de negócio.');
        return;
      }
    }

    if (cadastroConvidado) {
      _log(
          'FormKey.validate ignorado para convidado. Executando apenas save().');
      formKey.currentState?.save();
    }

    final tipoAtual = tipoEventoSelecionado.value;
    final dataStr = dataFesta.text.trim();
    final horaStr = horaFesta.text.trim();

    // ✅ VALIDAÇÕES DE NEGÓCIO
    if (tipoAtual == null) {
      Get.snackbar(
        'Atenção',
        'Selecione o tipo de evento antes de salvar.',
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
      return;
    }

    if (dataStr.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Informe a data do evento.',
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
      return;
    }

    final erroHora = validarHora(horaStr);
    final erroTermino = validarTermino(dataFimFesta.text);
    final erroCusto = validarCusto(custoEstimado.text);
    final erroPlanejamento = erroHora ?? erroTermino ?? erroCusto;
    if (erroPlanejamento != null) {
      Get.snackbar('Atenção', erroPlanejamento,
          backgroundColor: Colors.orange.shade600, colorText: Colors.white);
      return;
    }

    if (temaFestaObrigatorio) {
      final temaInformado = tema.text.trim();
      final escolheuCatalogo = idTema.value.isNotEmpty &&
          idTema.value != TemaFestaViewModel.slugOutro;
      if (!escolheuCatalogo && temaInformado.length < 2) {
        Get.snackbar(
          'Atenção',
          'Selecione o tema da festa.',
          backgroundColor: Colors.orange.shade600,
          colorText: Colors.white,
        );
        return;
      }
    }

    final valor = custoEstimadoInformado;

    try {
      // ✅ Monta data/hora completa
      final dataSelecionada =
          DateFormat('dd/MM/yyyy', 'pt_BR').parseStrict(dataStr);
      final partesHora = horaStr.isEmpty ? ['0', '0'] : horaStr.split(':');
      final dataCompleta = DateTime(
        dataSelecionada.year,
        dataSelecionada.month,
        dataSelecionada.day,
        int.tryParse(partesHora[0]) ?? 0,
        int.tryParse(partesHora[1]) ?? 0,
      );

      final dataFim = !eventoVariosDias.value
          ? null
          : DateFormat('dd/MM/yyyy', 'pt_BR')
              .parseStrict(dataFimFesta.text.trim());
      final inicioDia = DateTime(
          dataSelecionada.year, dataSelecionada.month, dataSelecionada.day);
      if (dataFim != null && dataFim.isBefore(inicioDia)) {
        Get.snackbar(
            'Atenção', 'O término deve ser no mesmo dia ou depois do início.');
        return;
      }

      // ✅ Endereço
      final end = enderecoController.value;
      final endereco = end.toModel(user.idUsuario);
      _logEndereco(endereco, origem: 'end.toModel');

      final enderecoFoiInformado = _enderecoTemAlgumCampoPreenchido(endereco);
      final deveSalvarEndereco = !cadastroConvidado || enderecoFoiInformado;

      _log(
        'Decisão endereço: cadastroConvidado=$cadastroConvidado | '
        'enderecoFoiInformado=$enderecoFoiInformado | deveSalvarEndereco=$deveSalvarEndereco',
      );

      // Organizador precisa informar endereço.
      // Convidado só valida endereço se tiver preenchido algum campo real.
      if (deveSalvarEndereco && !_validarCamposEndereco(endereco)) {
        _log('BLOQUEADO: _validarCamposEndereco retornou false.');
        return;
      }

      if (!deveSalvarEndereco) {
        _log('Endereço ignorado: convidado sem endereço preenchido.');
      }

      final idadesInformadas = [totalAdultos, totalCriancas, totalBebes]
          .any((campo) => campo.text.trim().isNotEmpty);
      final int? totalAdultosValor =
          idadesInformadas ? _parseIntController(totalAdultos) : null;
      final int? totalCriancasValor =
          idadesInformadas ? _parseIntController(totalCriancas) : null;
      final int? totalBebesValor =
          idadesInformadas ? _parseIntController(totalBebes) : null;
      final int? totalConvidadosValor = idadesInformadas
          ? totalAdultosValor! + totalCriancasValor! + totalBebesValor!
          : _eventoOriginal?.totalConvidados;
      totalConvidados.text = totalConvidadosValor?.toString() ?? '';

      carregando.value = true;

      // ⚙️ Mapeamento da cidade e estado
      final idCidade = deveSalvarEndereco
          ? end.ufCidadeController.idCidadeSelecionada?.toString()
          : null;
      final nomeCidade =
          deveSalvarEndereco ? end.nomeCidadeController.text.trim() : '';
      final uf = deveSalvarEndereco && end.ufController.text.trim().isNotEmpty
          ? end.ufController.text.trim().toUpperCase()
          : null;

      final criandoNovo = idEvento.value.isEmpty || _novoEventoPendente;
      // Identidade estável antes da rede, inclusive se a confirmação da gravação falhar.
      idEvento.value = idEvento.value.isEmpty ? uuid.v4() : idEvento.value;
      _novoEventoPendente = criandoNovo;
      // ✅ Criação da entidade do evento
      final evento = Evento(
        idEvento: idEvento.value,
        idTipoEvento: tipoAtual.idTipoEvento,
        idUsuario: user.idUsuario,
        nomeEvento: nomeEvento.text.trim().isNotEmpty
            ? nomeEvento.text.trim()
            : nomeEventoPreview.value.trim(),
        nomePessoalPrincipal: nomePessoalPrincipal.text,
        totalConvidados: totalConvidadosValor,
        totalAdultos: totalAdultosValor,
        totalCriancas: totalCriancasValor,
        totalBebes: totalBebesValor,
        localEvento: localEvento.text.trim(),
        custoEstimado: valor,
        data: dataCompleta,
        dataFim: dataFim,
        hora: horaStr.isEmpty ? null : horaStr,
        ativo: _eventoOriginal?.ativo ?? true,
        status: _eventoOriginal?.status ?? StatusEvento.planejamento,
        dataCadastro: _eventoOriginal?.dataCadastro,
        mensagemConvidado: _eventoOriginal?.mensagemConvidado,
        hashtagEvento: _eventoOriginal?.hashtagEvento,
        siteEvento: _eventoOriginal?.siteEvento,
        nomeGestante: _eventoOriginal?.nomeGestante,
        tipoCha: _eventoOriginal?.tipoCha,
        dataPrevistaNascimento: _eventoOriginal?.dataPrevistaNascimento,
        descricao: descricao.text,
        tema: tema.text.trim().isEmpty ? null : tema.text.trim(),
        idTema: idTema.value.trim().isEmpty ? null : idTema.value.trim(),
        imagemCapaUrl: _imagemCapaUrl,
        rotuloBanner: _rotuloBanner,
        dressCode:
            dressCode.value.trim().isEmpty ? null : dressCode.value.trim(),
        tipoCerimonia: tipoCerimonia.value,
        estiloCasamento: estiloCasamento.value,
        padrinhos: padrinhos.toList(),
        nomeNoiva: nomeNoiva.text,
        nomeAniversariante: _eventoOriginal?.nomeAniversariante,
        idade: int.tryParse(idade.text.trim()),
        nomeBebe: bebe.text.trim().isEmpty
            ? _eventoOriginal?.nomeBebe
            : bebe.text.trim(),
        nomeNoivo: parceiro.text,
        nomeResponsavel: user.nome,
        idCidade: idCidade,
        nomeCidade: nomeCidade.isNotEmpty ? nomeCidade : null,
        uf: uf,
        cep: deveSalvarEndereco ? endereco.cep : '',
        logradouro: deveSalvarEndereco ? endereco.logradouro : '',
        numero: deveSalvarEndereco ? endereco.numero : '',
        complemento: deveSalvarEndereco ? endereco.complemento : '',
        bairro: deveSalvarEndereco ? endereco.bairro : null,
      );

      reconciliarEstimativa();
      await salvarCadastroLocal(); // Inclui identidade estável ANTES da rede.
      if (app.usuarioLogado.value?.idUsuario != user.idUsuario ||
          identidadeCadastro != idRascunho) {
        return;
      }
      // ✅ Persistência delegada ao repository por meio do controller
      _log('Gravando evento ${evento.idEvento} no Firestore...');
      final pendente = rascunhoCalculadora;
      if (pendente != null) {
        await _rascunhos?.salvar(user.idUsuario, evento.idEvento, pendente);
      }
      await _repository.salvar(evento);
      if (app.usuarioLogado.value?.idUsuario != user.idUsuario ||
          identidadeCadastro != idRascunho) {
        return;
      }
      _eventoConfirmado = true;
      await salvarCadastroLocal();
      idEvento.value = evento.idEvento;
      _eventoOriginal = evento;
      _novoEventoPendente = criandoNovo;
      _log('Evento ${evento.idEvento} gravado com sucesso.');

      final rascunho = rascunhoCalculadora;
      if (rascunho != null) {
        try {
          if (vincularRascunho == null) {
            throw StateError('Vínculo da estimativa não configurado.');
          }
          await vincularRascunho(rascunho, evento);
          if (app.usuarioLogado.value?.idUsuario != user.idUsuario ||
              identidadeCadastro != idRascunho) {
            return;
          }
          await _rascunhos?.remover(user.idUsuario, evento.idEvento);
          rascunhoCalculadora = null;
        } catch (_) {
          carregando.value = false;
          Get.snackbar('Evento salvo; estimativa pendente',
              'Sua estimativa foi mantida. Tente salvar novamente ou reabra a edição deste evento para retomar o vínculo.');
          return;
        }
      }
      await concluirCadastroLocal(user.idUsuario, identidadeCadastro);
      if (app.usuarioLogado.value?.idUsuario != user.idUsuario ||
          identidadeCadastro != idRascunho) {
        return;
      }
      await app.ativarEventoOrganizador(evento);
      _novoEventoPendente = false;
      carregando.value = false;

      if (aoConcluir != null) {
        await aoConcluir(evento, rascunho);
      } else if (criandoNovo) {
        app.abrirHomeOrganizador();
      } else {
        Get.back();
      }
    } catch (e, st) {
      if (app.usuarioLogado.value?.idUsuario != user.idUsuario ||
          identidadeCadastro != idRascunho) {
        return;
      }
      carregando.value = false;
      _log('ERRO salvarEvento: $e');
      debugPrintStack(label: '$_logTag stack salvarEvento', stackTrace: st);
      Get.snackbar(
        'Erro',
        _eventoConfirmado
            ? 'O evento está salvo. A conclusão ficou pendente; tente novamente.'
            : 'Não foi possível confirmar o salvamento. Tente novamente; a identidade do evento foi preservada.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // ===============================
  // 🔹 LIMPAR CAMPOS
  // ===============================
  void limpar({bool manterEndereco = false}) {
    carregando.value = false;
    pararObservacaoCadastro();
    _usuarioCadastro = null;
    _eventoConfirmado = false;
    _cadastroConcluido = false;
    tipoEventoSelecionado.value = null;
    erroRascunhoLocal.value = '';
    avisoReconciliacao.value = '';
    _eventoOriginal = null;
    _novoEventoPendente = false;
    rascunhoCalculadora = null;
    idRascunho = uuid.v4();
    idEvento.value = '';
    nomeEvento.clear();
    nomePessoalPrincipal.clear();
    localEvento.clear();
    nomeNoiva.clear();
    parceiro.clear();
    idade.clear();
    bebe.clear();
    tema.clear();
    tipoCerimonia.value = '';
    estiloCasamento.value = '';
    idTema.value = '';
    temaLivre.value = false;
    dressCode.value = '';
    _imagemCapaUrl = null;
    _rotuloBanner = null;
    dataFesta.clear();
    dataFimFesta.clear();
    eventoVariosDias.value = false;
    horaFesta.clear();
    cidade.clear();
    uf.text = 'PR';
    email.clear();
    celular.clear();
    padrinhos.clear();
    custoEstimado.clear();
    totalAdultos.clear();
    totalCriancas.clear();
    totalBebes.clear();
    totalConvidados.clear();
    nomeEventoPreview.value = '';

    // ✅ Só limpa o endereço se não for pedido para manter
    if (!manterEndereco) {
      enderecoController.value.limpar();
    }
  }

  int _parseIntController(TextEditingController controller) {
    final raw = controller.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (raw.isEmpty) return 0;
    return int.tryParse(raw) ?? 0;
  }
}
