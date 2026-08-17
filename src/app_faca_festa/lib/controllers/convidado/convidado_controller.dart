import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../../core/services/whatsGw/whatsapp_service.dart';
import './../../presentation/whatsapp/whatsapp_templates.dart';
import './../../domain/entities/convidado.dart';
import './../../domain/entities/evento.dart';
import './../../domain/repositories/convidado_repository.dart';
import './../../domain/repositories/grupo_convidado_repository.dart';
import './../../domain/repositories/presente_reservation_repository.dart';
import './grupo_convidado_controller.dart';
import './../evento_controller.dart';

class ConvidadoController extends GetxController {
  ConvidadoController({
    required ConvidadoRepository repository,
    required PresenteReservationRepository presenteReservationRepository,
  })  : _repository = repository,
        _presenteReservationRepository = presenteReservationRepository;

  final ConvidadoRepository _repository;
  final PresenteReservationRepository _presenteReservationRepository;

  // 🔹 Lista completa de convidados do evento atual
  final RxList<Convidado> convidados = <Convidado>[].obs;

  GrupoConvidadoController? _grupoController;
  GrupoConvidadoController get grupoController {
    final existente = _grupoController;
    if (existente != null) return existente;

    final criado = Get.isRegistered<GrupoConvidadoController>()
        ? Get.find<GrupoConvidadoController>()
        : Get.put(
            GrupoConvidadoController(
              repository: Get.find<GrupoConvidadoRepository>(),
            ),
          );
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

// =============================================================
// 🔹 Lista temporária de novos convidados (somente em memória)
// =============================================================
  final RxList<Convidado> novosConvidados = <Convidado>[].obs;

  Future<void> enviarConviteAoAdicionar(
      Convidado convidado, Evento evento, String tipoEvento) async {
    final whats = Get.find<WhatsAppService>();
    final templates = Get.find<WhatsAppTemplates>();

    final msg = templates.conviteFormal(
      nomeConvidado: convidado.nome,
      tipoEvento: tipoEvento,
      nomeEvento: evento.nomeEvento,
      data: Biblioteca.formatarData(evento.data),
      hora: evento.hora ?? Biblioteca.formatarHora(evento.data),
      endereco: evento.localEvento,
      linkConfirmacao: 'https://www.facaafesta.com.br',
    );

    await whats.sendText(
      phone: convidado.contato,
      message: msg,
    );
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
    final whats = Get.find<WhatsAppService>();
    final templates = Get.find<WhatsAppTemplates>();

    final msg = templates.confirmacaoPresenca(
      nomeConvidado: convidado.nome,
      nomeEvento: tipoEvento,
      data: Biblioteca.formatarData(evento.data),
      hora: evento.hora ?? Biblioteca.formatarHora(evento.data),
      endereco: evento.localEvento,
    );

    await whats.sendText(
      phone: convidado.contato,
      message: msg,
    );
  }

  Future<void> enviarLembreteEvento(
      Convidado convidado, Evento evento, String tipoEvento) async {
    final whats = Get.find<WhatsAppService>();
    final templates = Get.find<WhatsAppTemplates>();

    final msg = templates.lembreteEvento(
      nomeConvidado: convidado.nome,
      nomeEvento: tipoEvento,
      data: Biblioteca.formatarData(evento.data),
      hora: evento.hora ?? Biblioteca.formatarHora(evento.data),
    );

    await whats.sendText(
      phone: convidado.contato,
      message: msg,
    );
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

    try {
      carregando.value = true;
      final eventoController = Get.find<EventoController>();
      final tipoEvento =
          eventoController.tipoEventoAtualEntidade?.nome ?? evento.nomeEvento;

      for (final c in novosConvidados) {
        await _repository.salvar(c);
        enviarConviteAoAdicionar(c, evento, tipoEvento);
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
      convidados.clear();
      idEventoAtual.value = '';
      return;
    }

    if (idEventoAtual.value == idEventoLimpo && _convidadosSub != null) {
      return;
    }

    await _convidadosSub?.cancel();

    idEventoAtual.value = idEventoLimpo;
    carregando.value = true;
    erro.value = '';

    _convidadosSub = _repository.observarPorEvento(idEventoLimpo).listen(
      (resultado) {
        final lista = resultado.toList();

        lista.sort(
          (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
        );

        convidados.assignAll(lista);
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
      carregando.value = true;
      erro.value = '';

      await _repository.salvar(model);
    } catch (e) {
      erro.value = 'Erro ao salvar convidado: $e';
      rethrow;
    } finally {
      carregando.value = false;
    }
  }

  Future<void> atualizarConvidado(Convidado model) async {
    try {
      carregando.value = true;
      erro.value = '';

      await _repository.salvar(model);
    } catch (e) {
      erro.value = 'Erro ao atualizar convidado: $e';
      rethrow;
    } finally {
      carregando.value = false;
    }
  }

  Future<void> excluirConvidado(String idConvidado) async {
    try {
      await _repository.excluir(idConvidado);
    } catch (e) {
      erro.value = 'Erro ao excluir convidado: $e';
      rethrow;
    }
  }

  Future<void> enviarConvitesSelecionados({
    required List<Convidado> convidadosSelecionados,
    required Evento evento,
    required String tipoEnvio,
  }) async {
    if (convidadosSelecionados.isEmpty) return;

    try {
      carregando.value = true;
      erro.value = '';

      final eventoController = Get.find<EventoController>();
      final tipoEvento =
          eventoController.tipoEventoAtualEntidade?.nome ?? evento.nomeEvento;

      for (final convidado in convidadosSelecionados) {
        await enviarConviteAoAdicionar(
          convidado,
          evento,
          tipoEvento,
        );
      }

      await _repository.marcarConvitesEnviados(
        convidadosSelecionados
            .map((convidado) => convidado.idConvidado)
            .toList(growable: false),
        tipoEnvio,
      );
    } catch (e) {
      erro.value = 'Erro ao enviar convites: $e';
      rethrow;
    } finally {
      carregando.value = false;
    }
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
    if (termo.isEmpty) return convidados;
    return convidados
        .where((c) =>
            c.nome.toLowerCase().contains(termo) ||
            (c.email?.toLowerCase().contains(termo) ?? false))
        .toList();
  }
}
