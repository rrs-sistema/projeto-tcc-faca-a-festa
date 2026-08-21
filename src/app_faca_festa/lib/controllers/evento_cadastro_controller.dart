import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

import '../core/utils/biblioteca.dart';
import './../presentation/pages/endereco/endereco_section_controller.dart';
import './../controllers/app_controller.dart';
import './../data/models/endereco/endereco_usuario.dart';
import '../domain/entities/evento.dart';
import '../domain/entities/tipo_evento.dart';
import '../domain/repositories/evento_repository.dart';
import '../data/models/evento/tema_festa_model.dart';

class EventoCadastroController extends GetxController {
  EventoCadastroController({required EventoRepository repository})
      : _repository = repository;

  final EventoRepository _repository;
  final uuid = const Uuid();
  AppController get app => Get.find<AppController>();

  /// ===============================
  /// 🔹 LISTA E MODELO DE TIPO DE EVENTO
  /// ===============================
  final tiposEvento = <TipoEvento>[].obs;
  final Rx<TipoEvento?> tipoEventoSelecionado = Rx<TipoEvento?>(null);

  /// ===============================
  /// 🔹 CAMPOS CONTROLADOS PELO CONTROLLER
  /// ===============================
  final idEvento = ''.obs;
  final nomeEvento = TextEditingController();
  final nomePessoalPrincipal = TextEditingController();
  final localEvento = TextEditingController();
  final nomeNoiva = TextEditingController();
  final parceiro = TextEditingController();
  final idade = TextEditingController();
  final bebe = TextEditingController();
  final tema = TextEditingController();
  final descricao = TextEditingController();
  final custoEstimado = TextEditingController();

  /// Quantidade estimada de convidados por tipo.
  ///
  /// O campo totalConvidados continua existindo para manter compatibilidade
  /// com as telas antigas e relatórios que usam apenas o total geral.
  /// A calculadora inteligente usa adultos/crianças/bebês para aplicar
  /// pesos de consumo diferentes.
  final totalAdultos = TextEditingController();
  final totalCriancas = TextEditingController();
  final totalBebes = TextEditingController();
  final totalConvidados = TextEditingController();

  final tipoCerimonia = ''.obs;
  final estiloCasamento = ''.obs;
  final idTema = ''.obs;
  final temaLivre = false.obs;
  final dressCode = ''.obs;

  final dataFesta = TextEditingController();
  final horaFesta = TextEditingController();
  final cidade = TextEditingController();
  final uf = TextEditingController(text: 'PR');
  final email = TextEditingController();
  final celular = TextEditingController();

  Rx<EnderecoSectionController>? _enderecoController;
  Rx<EnderecoSectionController> get enderecoController =>
      _enderecoController ??= EnderecoSectionController().obs;
  final padrinhos = <String>[].obs;

  final formKey = GlobalKey<FormState>();
  final nomeEventoPreview = ''.obs;
  final carregando = false.obs;

  bool get isEditando => idEvento.value.isNotEmpty;

  static const String _logTag = '[EventoCadastroController]';
  static const String _versaoDiagnostico = 'v2026-06-16-cep-convidado-logs';

  /// Permite que a tela force o fluxo como convidado quando o cadastro vier
  /// da área/convite do convidado e o UsuarioModel ainda não tiver perfil salvo.
  ///
  /// Exemplo na tela:
  /// controller.configurarCadastroComoConvidado(true);
  final cadastroConvidadoManual = false.obs;

  /// Quando o usuário logado for convidado, o endereço deixa de ser obrigatório.
  ///
  /// A detecção considera:
  /// 1) flag manual configurada pela tela;
  /// 2) campos/perfil do usuário logado;
  /// 3) argumentos da rota;
  /// 4) nome da rota atual contendo "convidado".
  ///
  /// Use este getter também na tela para deixar os validators dos campos
  /// de endereço opcionais quando o cadastro estiver sendo feito por convidado.
  bool get cadastroComoConvidado {
    final manual = cadastroConvidadoManual.value;
    final porUsuario = _usuarioEhConvidado(app.usuarioLogado.value);
    final porArgumentos = _argumentsIndicamConvidado(Get.arguments);
    final porRota = _normalizeTexto(Get.currentRoute).contains('convidado');

    final resultado = manual || porUsuario || porArgumentos || porRota;

    _log(
      'cadastroComoConvidado => $resultado | '
      'manual=$manual | porUsuario=$porUsuario | porArgumentos=$porArgumentos | '
      'porRota=$porRota | route=${Get.currentRoute} | args=${Get.arguments}',
    );

    return resultado;
  }

  bool get enderecoObrigatorio => !cadastroComoConvidado;

  @override
  void onInit() {
    super.onInit();
    _log(
        'onInit $_versaoDiagnostico | route=${Get.currentRoute} | args=${Get.arguments}');
  }

  void configurarCadastroComoConvidado(bool value) {
    cadastroConvidadoManual.value = value;
    _log('configurarCadastroComoConvidado($value)');
  }

  // ===============================
  // 🔹 CARREGAR TIPOS DE EVENTO DO FIRESTORE
  // ===============================
  Future<void> carregarTiposEvento() async {
    try {
      tiposEvento.assignAll(await _repository.listarTiposAtivos());
    } catch (e) {
      debugPrint('❌ Erro ao carregar tipos de evento: $e');
    }
  }

  String get tokenTipoEvento =>
      TemaFestaModel.normalizarTipo(tipoEventoSelecionado.value?.nome ?? '');

  bool get exibeSeletorTemaFesta {
    final token = tokenTipoEvento;
    return token.contains('aniversario') ||
        token.contains('infantil') ||
        token.contains('formatura') ||
        token.contains('cha') ||
        token.contains('casamento') ||
        token.contains('corporativo');
  }

  bool get temaFestaObrigatorio {
    final token = tokenTipoEvento;
    return token.contains('aniversario') || token.contains('infantil');
  }

  void selecionarTemaFesta(TemaFestaModel? tema, {bool outro = false}) {
    if (outro || tema?.slug == TemaFestaModel.slugOutro) {
      idTema.value = TemaFestaModel.slugOutro;
      temaLivre.value = true;
      dressCode.value = '';
      return;
    }

    temaLivre.value = false;
    if (tema == null) {
      idTema.value = '';
      dressCode.value = '';
      return;
    }

    idTema.value = tema.idTema;
    this.tema.text = tema.nome;
    final dress = (tema.dressCodeSugerido ?? '').trim();
    if (dress.isNotEmpty) {
      dressCode.value = dress;
    }
  }

// ===============================
// 🔹 ATUALIZAR PRÉ-VISUALIZAÇÃO DO EVENTO
// ===============================
  void atualizarPreview() {
    if (tipoEventoSelecionado.value == null) return;
    final nomeTipoEvento =
        _normalizeTipoEvento(tipoEventoSelecionado.value!.nome.toLowerCase());

    switch (nomeTipoEvento) {
      case 'casamento':
        nomeEventoPreview.value = '💍 Casamento\n ${nomeEvento.text}';
        break;
      case 'festa infantil':
        nomeEventoPreview.value = '🎈 Festa Infantil\n ${nomeEvento.text}';
        break;
      case 'chá de bebê':
      case 'ch de beb':
        nomeEventoPreview.value = '🍼 Chá de Bebê\n ${nomeEvento.text}';
        break;
      case 'aniversário':
      case 'aniversrio':
        nomeEventoPreview.value = '🎂 Aniversário\n ${nomeEvento.text}';
        break;
      case 'evento corporativo':
      case 'corporativo':
        nomeEventoPreview.value = '💼 Evento Corporativo\n ${nomeEvento.text}';
        break;
      case 'formatura':
        nomeEventoPreview.value = '🎓 Formatura \n ${nomeEvento.text}';
        break;
      default:
        nomeEventoPreview.value =
            '🎉 ${_capitalizar(tipoEventoSelecionado.value!.nome)}';
    }
  }

  // ===============================
  // 🔹 PADRINHOS
  // ===============================
  void addPadrinho(String nome) {
    if (nome.trim().isNotEmpty && !padrinhos.contains(nome.trim())) {
      padrinhos.add(nome.trim());
    }
  }

  void removePadrinho(String nome) => padrinhos.remove(nome);

// ===============================
// 🔹 CARREGAR EVENTO EXISTENTE (EDIÇÃO)
// ===============================
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
    temaLivre.value = (evento.idTema == null ||
            evento.idTema!.trim().isEmpty ||
            evento.idTema == TemaFestaModel.slugOutro) &&
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
        end.ufCidadeController.estadoSelecionado.value = {
          'nome': evento.uf,
          'uf': evento.uf,
        };
      }

      if (evento.idCidade != null || evento.nomeCidade != null) {
        end.ufCidadeController.cidadeSelecionada.value = {
          'id_cidade': evento.idCidade,
          'nome': evento.nomeCidade ?? '',
          'uf': evento.uf ?? '',
        };
      }
    }

    atualizarPreview();
  }

  Future<void> salvarEvento() async {
    _log('===== INÍCIO salvarEvento $_versaoDiagnostico =====');
    _log('route=${Get.currentRoute} | args=${Get.arguments}');

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
          idTema.value != TemaFestaModel.slugOutro;
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
        dressCode: dressCode.value.trim().isEmpty ? null : dressCode.value.trim(),
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

  bool _enderecoTemAlgumCampoPreenchido(EnderecoUsuarioModel endereco) {
    // Não considera a UF sozinha, porque o controller inicia com "PR" por padrão.
    return endereco.cep.trim().isNotEmpty ||
        endereco.logradouro.trim().isNotEmpty ||
        endereco.numero.trim().isNotEmpty ||
        (endereco.complemento?.trim().isNotEmpty ?? false) ||
        (endereco.bairro?.trim().isNotEmpty ?? false) ||
        (endereco.nomeCidade?.trim().isNotEmpty ?? false);
  }

  bool _validarCamposEndereco(EnderecoUsuarioModel endereco) {
    _logEndereco(endereco, origem: '_validarCamposEndereco');

    // ------------------------------
    // 🔹 Endereço
    // ------------------------------
    if (endereco.cep.trim().isEmpty) {
      _log('FALHA endereço: CEP vazio.');
      _showError('Informe o CEP');
      return false;
    }
    if (endereco.logradouro.trim().isEmpty) {
      _log('FALHA endereço: logradouro vazio.');
      _showError('Informe o endereço completo');
      return false;
    }
    if (endereco.numero.trim().isEmpty) {
      _log('FALHA endereço: número vazio.');
      _showError('Informe o número do endereço');
      return false;
    }
    if (endereco.bairro == null || endereco.bairro!.trim().isEmpty) {
      _log('FALHA endereço: bairro vazio.');
      _showError('Informe o bairro');
      return false;
    }
    if (endereco.uf == null || endereco.uf!.trim().isEmpty) {
      _log('FALHA endereço: UF vazia.');
      _showError('Informe o estado (UF)');
      return false;
    }
    if (endereco.nomeCidade == null || endereco.nomeCidade!.trim().isEmpty) {
      _log('FALHA endereço: cidade vazia.');
      _showError('Informe a cidade');
      return false;
    }

    _log('Endereço validado com sucesso.');
    return true;
  }

  bool _usuarioEhConvidado(dynamic usuario) {
    if (usuario == null) {
      _log('_usuarioEhConvidado=false porque usuário é null.');
      return false;
    }

    final valoresPossiveis = <dynamic>[
      _safeRead(() => usuario.isConvidado),
      _safeRead(() => usuario.ehConvidado),
      _safeRead(() => usuario.convidado),
      _safeRead(() => usuario.tipoUsuario),
      _safeRead(() => usuario.tipo),
      _safeRead(() => usuario.perfil),
      _safeRead(() => usuario.role),
      _safeRead(() => usuario.nivelAcesso),
      _safeRead(() => usuario.grupoUsuario),
      _safeRead(() => usuario.tipoCadastro),
      _safeRead(() => usuario.origemCadastro),
    ];

    final usuarioMap = _safeRead(() => usuario.toMap());
    if (usuarioMap is Map) {
      for (final key in const [
        'isConvidado',
        'ehConvidado',
        'convidado',
        'tipoUsuario',
        'tipo',
        'perfil',
        'role',
        'nivelAcesso',
        'grupoUsuario',
        'tipoCadastro',
        'origemCadastro',
      ]) {
        valoresPossiveis.add(usuarioMap[key]);
      }
    }

    final filtrados = valoresPossiveis.where((v) => v != null).toList();
    final resultado = filtrados.any(_valorRepresentaConvidado);
    _log('_usuarioEhConvidado=$resultado | valores=$filtrados');
    return resultado;
  }

  bool _argumentsIndicamConvidado(dynamic args) {
    if (args == null) return false;

    if (args is Map) {
      final valores = <dynamic>[
        args['isConvidado'],
        args['ehConvidado'],
        args['convidado'],
        args['cadastroConvidado'],
        args['cadastroComoConvidado'],
        args['tipoCadastro'],
        args['origemCadastro'],
        args['perfil'],
        args['tipoUsuario'],
      ];
      return valores.any(_valorRepresentaConvidado);
    }

    return _valorRepresentaConvidado(args);
  }

  bool _valorRepresentaConvidado(dynamic valor) {
    if (valor == null) return false;
    if (valor is bool) return valor;

    final texto = _normalizeTexto(valor.toString());
    return texto == 'convidado' ||
        texto == 'guest' ||
        texto == 'area convidado' ||
        texto.contains('convidado') ||
        texto.contains('guest');
  }

  void _logUsuario(dynamic usuario) {
    if (usuario == null) {
      _log('Usuário logado: null');
      return;
    }

    final usuarioMap = _safeRead(() => usuario.toMap());
    _log('Usuário logado runtimeType=${usuario.runtimeType}');
    _log(
        'Usuário id=${_safeRead(() => usuario.idUsuario)} | nome=${_safeRead(() => usuario.nome)}');
    if (usuarioMap is Map) {
      _log('Usuário toMap=$usuarioMap');
    } else {
      _log('Usuário sem toMap disponível.');
    }
  }

  void _logEndereco(EnderecoUsuarioModel endereco, {required String origem}) {
    _log(
      'Endereço [$origem]: '
      'cep="${endereco.cep}" | '
      'logradouro="${endereco.logradouro}" | '
      'numero="${endereco.numero}" | '
      'bairro="${endereco.bairro}" | '
      'cidade="${endereco.nomeCidade}" | '
      'uf="${endereco.uf}" | '
      'complemento="${endereco.complemento}"',
    );
  }

  void _log(String mensagem) {
    debugPrint('$_logTag $mensagem');
  }

  dynamic _safeRead(dynamic Function() read) {
    try {
      return read();
    } catch (_) {
      return null;
    }
  }

  /// 🔹 Exibe mensagens elegantes de erro
  void _showError(String mensagem) {
    Get.snackbar(
      'Verificação necessária',
      mensagem,
      backgroundColor: Colors.red.shade600.withValues(alpha: 0.95),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  // ===============================
  // 🔹 UTILITÁRIOS INTERNOS
  // ===============================
  String _normalizeTipoEvento(String tipo) => _normalizeTexto(tipo);

  String _normalizeTexto(String texto) {
    return texto.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
  }

  String _capitalizar(String nome) {
    if (nome.isEmpty) return '';
    return nome
        .split(' ')
        .map((p) => p.isEmpty
            ? ''
            : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
  }
}
