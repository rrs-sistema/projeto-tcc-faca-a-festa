import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:app_faca_festa/domain/entities/endereco_usuario.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/tipo_evento.dart';
import 'package:app_faca_festa/domain/entities/uf_cidade.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/repositories/evento_repository.dart';
import 'package:app_faca_festa/domain/services/buscar_cep_service.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/tema_festa_view_model.dart';
import 'package:app_faca_festa/presentation/modules/usuario/components/endereco/endereco_section_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/uf_cidade_controller.dart';

part 'evento_cadastro_tipos.dart';
part 'evento_cadastro_endereco.dart';
part 'evento_cadastro_persistencia.dart';

const String _logTag = '[EventoCadastroController]';
const String _versaoDiagnostico = 'v2026-06-16-cep-convidado-logs';

class EventoCadastroController extends GetxController {
  EventoCadastroController({
    required EventoRepository repository,
    required BuscarCepService buscarCepService,
    required UFCidadeController ufCidadeController,
    AppController? appController,
    AppController? Function()? appControllerResolver,
  })  : _repository = repository,
        _buscarCepService = buscarCepService,
        _ufCidadeController = ufCidadeController,
        _appController = appController,
        _appControllerResolver = appControllerResolver;

  final EventoRepository _repository;
  final BuscarCepService _buscarCepService;
  final UFCidadeController _ufCidadeController;
  final AppController? _appController;
  final AppController? Function()? _appControllerResolver;
  final uuid = const Uuid();
  AppController get app {
    final controller = _appController ?? _appControllerResolver?.call();
    if (controller == null) {
      throw StateError('AppController não configurado.');
    }
    return controller;
  }

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

  /// Preserva a capa personalizada ao editar o evento (não é editada neste form).
  String? _imagemCapaUrl;

  /// Preserva o rótulo personalizado do banner ao editar o evento.
  String? _rotuloBanner;

  final dataFesta = TextEditingController();
  final horaFesta = TextEditingController();
  final cidade = TextEditingController();
  final uf = TextEditingController(text: 'PR');
  final email = TextEditingController();
  final celular = TextEditingController();

  Rx<EnderecoSectionController>? _enderecoController;
  Rx<EnderecoSectionController> get enderecoController =>
      _enderecoController ??= EnderecoSectionController(
        cepService: _buscarCepService,
        ufCidadeController: _ufCidadeController,
      ).obs;
  final padrinhos = <String>[].obs;

  final formKey = GlobalKey<FormState>();
  final nomeEventoPreview = ''.obs;
  final carregando = false.obs;

  bool get isEditando => idEvento.value.isNotEmpty;

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
    final porArgumentos =
        AuthFluxoArgs.maybeOf(Get.arguments)?.ehConvidado == true;
    final porRota = _normalizeTexto(Get.currentRoute).contains('convidado');

    final resultado = manual || porUsuario || porArgumentos || porRota;

    _log(
      'cadastroComoConvidado => $resultado | '
      'manual=$manual | porUsuario=$porUsuario | porArgumentos=$porArgumentos | '
      'porRota=$porRota | route=${Get.currentRoute} | args=${AuthFluxoArgs.of(Get.arguments)}',
    );

    return resultado;
  }

  bool get enderecoObrigatorio => !cadastroComoConvidado;

  @override
  void onInit() {
    super.onInit();
    _log(
        'onInit $_versaoDiagnostico | route=${Get.currentRoute} | args=${AuthFluxoArgs.of(Get.arguments)}');
  }

  void configurarCadastroComoConvidado(bool value) {
    cadastroConvidadoManual.value = value;
    _log('configurarCadastroComoConvidado($value)');
  }

  bool _usuarioEhConvidado(Usuario? usuario) {
    if (usuario == null) {
      _log('_usuarioEhConvidado=false porque usuário é null.');
      return false;
    }

    final resultado = (usuario.tipo ?? '').trim().toUpperCase() == 'C';
    _log('_usuarioEhConvidado=$resultado | tipo=${usuario.tipo}');
    return resultado;
  }

  void _logUsuario(Usuario? usuario) {
    if (usuario == null) {
      _log('Usuário logado: null');
      return;
    }

    _log('Usuário logado runtimeType=${usuario.runtimeType}');
    _log(
      'Usuário id=${usuario.idUsuario} | nome=${usuario.nome} | tipo=${usuario.tipo}',
    );
  }

  void _log(String mensagem) {
    debugPrint('$_logTag $mensagem');
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
