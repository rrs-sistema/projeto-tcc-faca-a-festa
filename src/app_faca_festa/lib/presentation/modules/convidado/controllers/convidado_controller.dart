import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:app_faca_festa/core/utils/convite_link.dart';
import 'package:app_faca_festa/data/services/convite/enviar_convites_por_email_service.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/repositories/convidado_repository.dart';
import 'package:app_faca_festa/domain/repositories/presente_reservation_repository.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/grupo_convidado_controller.dart';

class ConvidadoController extends GetxController {
  ConvidadoController({
    required ConvidadoRepository repository,
    required PresenteReservationRepository presenteReservationRepository,
    EnviarConvitesPorEmailService? conviteEmailService,
  })  : _repository = repository,
        _presenteReservationRepository = presenteReservationRepository,
        _conviteEmailService = conviteEmailService;

  final ConvidadoRepository _repository;
  final PresenteReservationRepository _presenteReservationRepository;
  final EnviarConvitesPorEmailService? _conviteEmailService;

  EnviarConvitesPorEmailService get _emailService =>
      _conviteEmailService ?? Get.find<EnviarConvitesPorEmailService>();

  // 🔹 Lista completa de convidados do evento atual
  final RxList<Convidado> convidados = <Convidado>[].obs;

  GrupoConvidadoController? _grupoController;
  GrupoConvidadoController get grupoController {
    final existente = _grupoController;
    if (existente != null) return existente;

    final criado = Get.find<GrupoConvidadoController>();
    _grupoController = criado;
    return criado;
  }

  // 🔹 Estados de carregamento e erro
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  // 🔹 IDs e filtros auxiliares
  final RxString idEventoAtual = ''.obs;
  final RxString termoBusca = ''.obs;

  final Rx<Convidado?> convidadoAtual = Rx<Convidado?>(null);

  StreamSubscription? _convidadosSub;
  final Map<String, Convidado> _convidadosPendentes = {};

// =============================================================
// 🔹 Lista temporária de novos convidados (somente em memória)
// =============================================================
  final RxList<Convidado> novosConvidados = <Convidado>[].obs;

  Future<void> enviarConviteAoAdicionar(
      Convidado convidado, Evento evento, String tipoEvento) async {
    // Envio externo (WhatsApp/SMS/e-mail) foi desativado nesta fase.
  }

  Future<void> migrarTipoConvidadoLegado() async {
    try {
      carregando.value = true;
      final resultado = await _repository.migrarTiposLegados();

      if (resultado.totalEncontrados == 0) {
        Get.snackbar(
          'Migração',
          'Nenhum convidado encontrado para migrar.',
          backgroundColor: Colors.orangeAccent,
          colorText: Colors.white,
        );
        return;
      }

      Get.snackbar(
        'Migração concluída',
        '${resultado.totalAtualizados} convidados atualizados. '
            '${resultado.totalIgnorados} já estavam corretos.',
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro na migração',
        'Não foi possível migrar os convidados: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      carregando.value = false;
    }
  }

  Future<void> confirmarPresenca(
      Convidado convidado, Evento evento, String tipoEvento) async {
    // Envio externo foi desativado nesta fase.
  }

  Future<void> enviarLembreteEvento(
      Convidado convidado, Evento evento, String tipoEvento) async {
    // Envio externo foi desativado nesta fase.
  }

  /// 🔹 Adiciona novo convidado temporário
  void adicionarNovoConvidadoLocal(Convidado convidado) {
    novosConvidados.add(convidado);
  }

  /// 🔹 Remove convidado da lista local
  void removerNovoConvidadoLocal(String idConvidado) {
    novosConvidados.removeWhere((c) => c.idConvidado == idConvidado);
  }

  /// =====================================================
  /// 🔹 Busca convidado pelo ID do usuário
  /// =====================================================
  Future<Convidado?> buscarPeloIdConvidado(String idUsuario) async {
    try {
      carregando.value = true;
      final convidado = await _repository.buscarPorId(idUsuario);

      if (convidado != null) {
        convidadoAtual.value = convidado;
        return convidado;
      } else {
        return null;
      }
    } catch (e, s) {
      debugPrint('❌ [ConvidadoController] Erro ao buscar convidado: $e\n$s');
      return null;
    } finally {
      carregando.value = false;
    }
  }

  Future<Convidado?> buscarPeloIdEvento(String idEvento) async {
    try {
      carregando.value = true;
      final convidado = await _repository.buscarPrimeiroPorEvento(idEvento);
      return convidado;
    } catch (e) {
      return null;
    } finally {
      carregando.value = false;
    }
  }

  /// 🔹 Persiste todos os convidados novos
  Future<void> enviarNovosConvidados(Evento evento) async {
    if (novosConvidados.isEmpty) return;
    if (evento.idEvento.trim().isEmpty) return;

    try {
      carregando.value = true;
      for (final c in novosConvidados) {
        await _repository.salvar(c.comTokenConvite());
      }
      novosConvidados.clear();
    } catch (e) {
      erro.value = 'Erro ao salvar convidados: $e';
    } finally {
      carregando.value = false;
    }
  }

  /// =============================================================
  /// 🔹 Escuta em tempo real todos os convidados de um evento
  /// =============================================================
  /// =====================================================
  /// 🔹 Escuta convidados do evento em tempo real
  /// =====================================================
  Future<void> escutarConvidados(String idEvento) async {
    final idEventoLimpo = idEvento.trim();

    if (idEventoLimpo.isEmpty) {
      await _convidadosSub?.cancel();
      _convidadosSub = null;
      _convidadosPendentes.clear();
      convidados.clear();
      idEventoAtual.value = '';
      return;
    }

    if (idEventoAtual.value == idEventoLimpo && _convidadosSub != null) {
      return;
    }

    await _convidadosSub?.cancel();

    idEventoAtual.value = idEventoLimpo;
    _convidadosPendentes.clear();
    carregando.value = true;
    erro.value = '';

    _convidadosSub = _repository.observarPorEvento(idEventoLimpo).listen(
      (resultado) {
        _publicarConvidados(resultado.toList());
        carregando.value = false;
      },
      onError: (e) {
        erro.value = 'Erro ao carregar convidados: $e';
        carregando.value = false;
      },
    );
  }

  Future<void> adicionarConvidado(Convidado model) async {
    try {
      erro.value = '';
      final salvo = model.comTokenConvite();
      await _repository.salvar(salvo);
      _mesclarConvidadoLocal(salvo);
    } catch (e) {
      erro.value = 'Erro ao salvar convidado: $e';
      rethrow;
    }
  }

  Future<void> atualizarConvidado(Convidado model) async {
    try {
      erro.value = '';
      await _repository.salvar(model);
      _mesclarConvidadoLocal(model);
    } catch (e) {
      erro.value = 'Erro ao atualizar convidado: $e';
      rethrow;
    }
  }

  Future<void> excluirConvidado(String idConvidado) async {
    try {
      await _repository.excluir(idConvidado);
      _convidadosPendentes.remove(idConvidado);
      convidados.removeWhere((c) => c.idConvidado == idConvidado);
    } catch (e) {
      erro.value = 'Erro ao excluir convidado: $e';
      rethrow;
    }
  }

  void _mesclarConvidadoLocal(Convidado model) {
    final id = model.idConvidado.trim();
    if (id.isEmpty) return;
    _convidadosPendentes[id] = model;
    _publicarConvidados(convidados.toList());
  }

  void _publicarConvidados(List<Convidado> remoto) {
    final porId = <String, Convidado>{};
    for (final convidado in remoto) {
      final id = convidado.idConvidado.trim();
      if (id.isEmpty) continue;
      final pendente = _convidadosPendentes[id];
      if (pendente != null && _pendenteMaisRecente(pendente, convidado)) {
        porId[id] = pendente;
      } else {
        porId[id] = convidado;
        _convidadosPendentes.remove(id);
      }
    }
    for (final pendente in _convidadosPendentes.values) {
      porId.putIfAbsent(pendente.idConvidado, () => pendente);
    }
    final lista = porId.values.toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    convidados.assignAll(lista);
  }

  bool _pendenteMaisRecente(Convidado pendente, Convidado remoto) {
    return pendente.dataAtualizacao.isAfter(remoto.dataAtualizacao);
  }

  /// Persiste o token de cada convidado e devolve a lista pronta para copiar/compartilhar.
  Future<List<Convidado>> garantirLinksConvite(
    List<Convidado> convidadosSelecionados,
  ) async {
    if (convidadosSelecionados.isEmpty) return const [];

    try {
      erro.value = '';

      final comToken = convidadosSelecionados
          .map((convidado) => convidado.comTokenConvite())
          .toList(growable: false);

      final tokensPorId = <String, String>{};
      for (final convidado in comToken) {
        final id = convidado.idConvidado.trim();
        if (id.isEmpty) continue;
        tokensPorId[id] = convidado.tokenParaLink;
      }

      await _repository.garantirTokensConvite(tokensPorId);
      return comToken;
    } catch (e) {
      erro.value = 'Erro ao gerar links de convite: $e';
      rethrow;
    }
  }

  Future<ResultadoEnvioConviteEmail> enviarConvitesPorEmail(
    List<Convidado> selecionados,
  ) async {
    final idEvento = idEventoAtual.value.trim();
    if (idEvento.isEmpty) {
      throw const EnviarConvitesPorEmailException(
        'failed-precondition',
        'Nenhum evento selecionado.',
      );
    }

    final comEmail = selecionados
        .where((convidado) =>
            convidado.temEmail && convidado.idConvidado.trim().isNotEmpty)
        .toList(growable: false);
    final semEmail = selecionados
        .where((convidado) => !convidado.temEmail)
        .map((convidado) => convidado.idConvidado)
        .where((id) => id.trim().isNotEmpty)
        .toList(growable: false);

    if (comEmail.isEmpty) {
      return ResultadoEnvioConviteEmail(
        enviados: 0,
        semEmail: semEmail,
        falhas: const [],
      );
    }

    await garantirLinksConvite(comEmail);
    final resultado = await _emailService.enviar(
      idEvento: idEvento,
      idsConvidados: comEmail
          .map((convidado) => convidado.idConvidado.trim())
          .toList(growable: false),
    );
    return ResultadoEnvioConviteEmail(
      enviados: resultado.enviados,
      semEmail: {...semEmail, ...resultado.semEmail}.toList(),
      falhas: resultado.falhas,
    );
  }

  String origemPublicaConvite() {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty &&
          !origin.contains('localhost') &&
          !origin.contains('127.0.0.1')) {
        return origin;
      }
    }
    return ConviteLink.origemPublicaPadrao;
  }

  String urlConvite(Convidado convidado, {String? origem}) {
    return ConviteLink.url(
      convidado.tokenParaLink,
      origem: origem ?? origemPublicaConvite(),
    );
  }

  String textoCompartilhamento({
    required List<Convidado> convidados,
    required Evento evento,
    String? origem,
  }) {
    final origemLink = origem ?? origemPublicaConvite();
    final nomeEvento = evento.nomeEvento.trim().isEmpty
        ? 'o evento'
        : evento.nomeEvento.trim();
    final mensagem = evento.mensagemConvidado?.trim();

    if (convidados.length == 1) {
      final convidado = convidados.first;
      final buffer = StringBuffer()
        ..writeln('Olá, ${convidado.nome.trim()}!')
        ..writeln()
        ..writeln('Você foi convidado(a) para $nomeEvento.');
      if (mensagem != null && mensagem.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln(mensagem);
      }
      buffer
        ..writeln()
        ..writeln('Abra seu convite:')
        ..write(urlConvite(convidado, origem: origemLink));
      return buffer.toString();
    }

    final buffer = StringBuffer()
      ..writeln('Convites para $nomeEvento')
      ..writeln();
    if (mensagem != null && mensagem.isNotEmpty) {
      buffer
        ..writeln(mensagem)
        ..writeln();
    }
    for (final convidado in convidados) {
      buffer.writeln(
          '${convidado.nome.trim()}: ${urlConvite(convidado, origem: origemLink)}');
    }
    return buffer.toString().trim();
  }

  @override
  void onClose() {
    _convidadosSub?.cancel();
    super.onClose();
  }

  void limpar() {
    _convidadosSub?.cancel();
    _convidadosSub = null;

    convidados.clear();
    _convidadosPendentes.clear();
    novosConvidados.clear();
    idEventoAtual.value = '';
    termoBusca.value = '';
    erro.value = '';
    convidadoAtual.value = null;
  }

  /// =====================================================
  /// 🔹 Cria ou atualiza convidado
  /// =====================================================
  Future<void> salvarConvidado(Convidado convidado) async {
    await _repository.salvar(convidado);
  }

  Future<Convidado?> buscarPorToken(String token) async {
    final convidado = await _repository.buscarPorToken(token);
    return convidado;
  }

  Future<void> reservarPresente(
      {required String idPresente,
      required String idConvidado,
      required String nomeConvidado,
      required Color backgroundColor}) async {
    await _presenteReservationRepository.reservar(
      idEvento: idEventoAtual.value,
      idPresente: idPresente,
      idConvidado: idConvidado,
      nomeConvidado: nomeConvidado,
      dataReserva: DateTime.now(),
    );

    Get.snackbar(
      '🎁 Presente reservado!',
      'Você selecionou esse presente. Obrigado por participar!',
      backgroundColor: backgroundColor,
      colorText: Colors.white,
    );
  }

  /// =====================================================
  /// 🔹 Atualiza status de presença
  /// =====================================================
  Future<void> atualizarStatusPresenca(
    Convidado convidado,
    StatusConvidado novoStatus,
  ) async {
    try {
      final atualizado = convidado.copyWith(
        status: novoStatus,
        dataResposta: DateTime.now(),
      );

      await _repository.salvar(atualizado);

      convidadoAtual.value = atualizado;

      String msg = switch (novoStatus) {
        StatusConvidado.confirmado =>
          '🎉 Presença confirmada! Obrigado por confirmar.',
        StatusConvidado.recusado =>
          '🙁 Sentiremos sua falta, confirmação registrada.',
        _ => 'Status atualizado.'
      };

      Get.snackbar(
        'Atualizado',
        msg,
        backgroundColor: novoStatus == StatusConvidado.confirmado
            ? Colors.green.shade400
            : Colors.orange.shade400,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('❌ [ConvidadoController] Erro ao atualizar status: $e');
    }
  }

  /// =============================================================
  /// 🔹 Atualiza o status do convidado (Pendente, Confirmado, Recusado)
  /// =============================================================
  Future<void> atualizarStatus(
      String idConvidado, StatusConvidado status) async {
    try {
      await _repository.atualizarStatus(
        idConvidado,
        status,
        DateTime.now(),
      );
    } catch (e) {
      erro.value = 'Erro ao atualizar status: $e';
    }
  }

  /// 🔹 Agrupa convidados por mesa/grupo
  Map<String, List<Convidado>> get convidadosPorMesa {
    final Map<String, List<Convidado>> grupos = {};
    for (var c in convidados) {
      final grupo = c.nomeGrupo ?? 'Sem mesa';
      grupos.putIfAbsent(grupo, () => []);
      grupos[grupo]!.add(c);
    }
    return grupos;
  }

  /// 🔹 Calcula estatísticas gerais de mesas (AGORA CORRETO)
  Map<String, dynamic> get estatisticasMesas {
    final gruposMesa = grupoController.grupos;

    // Total de mesas cadastradas
    final totalMesas = gruposMesa.length;

    // Total de assentos cadastrados
    final totalAssentos = gruposMesa.fold<int>(
      0,
      (acc, g) => acc + (g.totalConvidados),
    );

    // Buscar convidados no controller (fonte real)
    final todosConvidados = convidados;

    // Confirmados agrupados por mesa real
    int totalOcupados = 0;

    for (var g in gruposMesa) {
      final nomeMesa = g.nome;

      totalOcupados += todosConvidados
          .where((c) =>
              c.nomeGrupo == nomeMesa && c.status == StatusConvidado.confirmado)
          .length;
    }

    // Assentos livres
    final totalLivres = totalAssentos - totalOcupados;

    return {
      'totalMesas': totalMesas,
      'assentos': totalAssentos,
      'ocupados': totalOcupados,
      'livres': totalLivres,
    };
  }

  Map<String, dynamic> get estatisticasMesas001 {
    final grupos = convidadosPorMesa;
    final totalMesas = grupos.length;
    final totalAssentos = grupos.values.fold<int>(0, (a, b) => a + b.length);
    final totalOcupados =
        convidados.where((c) => c.status == StatusConvidado.confirmado).length;
    final totalLivres = totalAssentos - totalOcupados;

    return {
      'totalMesas': totalMesas,
      'assentos': totalAssentos,
      'ocupados': totalOcupados,
      'livres': totalLivres,
    };
  }

  /// =============================================================
  /// 🔹 Estatísticas rápidas para o organizador
  /// =============================================================
  int get totalConvidados => convidados.length;

  int get totalConfirmados =>
      convidados.where((c) => c.status == StatusConvidado.confirmado).length;

  int get totalPendentes =>
      convidados.where((c) => c.status == StatusConvidado.pendente).length;

  int get totalRecusados =>
      convidados.where((c) => c.status == StatusConvidado.recusado).length;

  int get totalAdultos => convidados.where((c) => c.adulto == true).length;

  int get totalCriancas => convidados.where((c) => c.adulto == false).length;

  /// =============================================================
  /// 🔹 Filtro de busca por nome ou e-mail
  /// =============================================================
  List<Convidado> get listaFiltrada {
    final termo = termoBusca.value.toLowerCase();
    final lista = List<Convidado>.from(convidados);
    if (termo.isEmpty) return lista;
    return lista
        .where((c) =>
            c.nome.toLowerCase().contains(termo) ||
            (c.email?.toLowerCase().contains(termo) ?? false))
        .toList();
  }
}
