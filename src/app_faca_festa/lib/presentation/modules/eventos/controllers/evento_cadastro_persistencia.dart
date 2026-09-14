part of 'evento_cadastro_controller.dart';

extension EventoCadastroPersistencia on EventoCadastroController {
  void carregarEvento(Evento evento) {
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
    horaFesta.text = evento.hora ?? '';
    padrinhos.assignAll(evento.padrinhos ?? []);

    // ✅ Preenche a estimativa de convidados por tipo.
    //
    // Para eventos antigos, onde só existia total_convidados,
    // mantemos compatibilidade jogando o total em adultos quando
    // ainda não houver distribuição por adultos/crianças/bebês.
    final adultosSalvos = evento.totalAdultos ?? 0;
    final criancasSalvas = evento.totalCriancas ?? 0;
    final bebesSalvos = evento.totalBebes ?? 0;
    final totalPorTipoSalvo = adultosSalvos + criancasSalvas + bebesSalvos;
    final totalSalvo = evento.totalConvidados ?? totalPorTipoSalvo;

    final adultosParaTela = totalPorTipoSalvo > 0 ? adultosSalvos : totalSalvo;
    final criancasParaTela = totalPorTipoSalvo > 0 ? criancasSalvas : 0;
    final bebesParaTela = totalPorTipoSalvo > 0 ? bebesSalvos : 0;

    totalAdultos.text = adultosParaTela > 0 ? adultosParaTela.toString() : '';
    totalCriancas.text =
        criancasParaTela > 0 ? criancasParaTela.toString() : '';
    totalBebes.text = bebesParaTela > 0 ? bebesParaTela.toString() : '';
    totalConvidados.text = totalSalvo > 0 ? totalSalvo.toString() : '';

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

  Future<void> salvarEvento() async {
    _log('===== INÍCIO salvarEvento $_versaoDiagnostico =====');
    _log('route=${Get.currentRoute} | args=${AuthFluxoArgs.of(Get.arguments)}');

    final user = app.usuarioLogado.value;
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

    if (horaStr.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Informe a hora do evento.',
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
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

    // ✅ VALIDAÇÃO DO CUSTO ESTIMADO
    double valor = 0.0;
    if (custoEstimado.text.isNotEmpty) {
      valor = Biblioteca.toDouble(custoEstimado.text);
    }

    if (valor <= 1.0) {
      Get.snackbar(
        'Atenção',
        'O custo estimado deve ser superior a R\$ 1,00.',
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // ✅ Monta data/hora completa
      final dataSelecionada = DateFormat('dd/MM/yyyy', 'pt_BR').parse(dataStr);
      final partesHora = horaStr.split(':');
      final dataCompleta = DateTime(
        dataSelecionada.year,
        dataSelecionada.month,
        dataSelecionada.day,
        int.tryParse(partesHora[0]) ?? 0,
        int.tryParse(partesHora[1]) ?? 0,
      );

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

      // ✅ Quantidade de convidados por tipo
      //
      // O total geral é sempre derivado dos campos adultos/crianças/bebês
      // para evitar inconsistência entre o total e a distribuição.
      final totalAdultosValor = _parseIntController(totalAdultos);
      final totalCriancasValor = _parseIntController(totalCriancas);
      final totalBebesValor = _parseIntController(totalBebes);
      final totalConvidadosValor =
          totalAdultosValor + totalCriancasValor + totalBebesValor;

      totalConvidados.text =
          totalConvidadosValor > 0 ? totalConvidadosValor.toString() : '';

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

      // ✅ Criação da entidade do evento
      final evento = Evento(
        idEvento: idEvento.value.isEmpty ? uuid.v4() : idEvento.value,
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
        hora: horaStr,
        ativo: true,
        status: StatusEvento.planejamento,
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

      // ✅ Persistência delegada ao repository por meio do controller
      _log('Gravando evento ${evento.idEvento} no Firestore...');
      await _repository.salvar(evento);
      _log('Evento ${evento.idEvento} gravado com sucesso.');

      final criandoNovo = idEvento.value.isEmpty;
      await app.ativarEventoOrganizador(evento);
      carregando.value = false;

      if (criandoNovo) {
        app.abrirHomeOrganizador();
      } else {
        Get.back();
      }
    } catch (e, st) {
      carregando.value = false;
      _log('ERRO salvarEvento: $e');
      debugPrintStack(label: '$_logTag stack salvarEvento', stackTrace: st);
      Get.snackbar(
        'Erro',
        'Falha ao salvar evento: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // ===============================
  // 🔹 LIMPAR CAMPOS
  // ===============================
  void limpar({bool manterEndereco = false}) {
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
