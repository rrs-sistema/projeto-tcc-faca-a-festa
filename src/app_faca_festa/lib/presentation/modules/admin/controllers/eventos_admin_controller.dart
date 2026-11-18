import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/evento_admin.dart';
import 'package:app_faca_festa/domain/services/auditoria_registrar.dart';
import 'package:app_faca_festa/domain/services/kit_servicos_por_tipo.dart';
import 'package:app_faca_festa/domain/services/lead_evento_score_service.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_eventos_admin.dart';

class EventosAdminController extends GetxController {
  EventosAdminController({
    required GerenciarEventosAdmin eventosAdmin,
    LeadEventoScoreService? leadScore,
    KitServicosPorTipo? kitServicos,
    AuditoriaRegistrar? auditoria,
    AuditoriaRegistrar? Function()? auditoriaResolver,
  })  : _eventosAdmin = eventosAdmin,
        _leadScore = leadScore ?? const LeadEventoScoreService(),
        _kitServicos = kitServicos ?? const KitServicosPorTipo(),
        _auditoria = auditoria,
        _auditoriaResolver = auditoriaResolver;

  final GerenciarEventosAdmin _eventosAdmin;
  final LeadEventoScoreService _leadScore;
  final KitServicosPorTipo _kitServicos;
  final AuditoriaRegistrar? _auditoria;
  final AuditoriaRegistrar? Function()? _auditoriaResolver;
  AuditoriaRegistrar get _registradorAuditoria =>
      _auditoria ??
      _auditoriaResolver?.call() ??
      const AuditoriaRegistrarVazio();

  final eventos = <EventoAdmin>[].obs;
  final busca = ''.obs;
  final filtroComercial = FiltroComercialEvento.todos.obs;
  final carregando = false.obs;
  final acaoEmAndamento = false.obs;
  final erro = ''.obs;
  final mostrarHeatmap = true.obs;

  final sugestoesPorEvento = <String, List<FornecedorSugestaoAdmin>>{}.obs;
  final carregandoSugestoes = <String>{}.obs;

  LeadEventoScoreService get leadScore => _leadScore;
  KitServicosPorTipo get kitServicos => _kitServicos;

  List<EventoAdmin> get eventosFiltrados {
    final termo = busca.value.trim().toLowerCase();
    var lista = eventos.toList();

    switch (filtroComercial.value) {
      case FiltroComercialEvento.semCotacao:
        lista = lista.where((e) => e.semCotacao && e.emCurso).toList();
      case FiltroComercialEvento.proximos90Dias:
        lista = lista.where((e) => e.nosProximos90Dias).toList();
      case FiltroComercialEvento.prioridadeAlta:
        lista = lista.where((e) => scoreDe(e) >= 70).toList();
      case FiltroComercialEvento.organizadorRecorrente:
        lista = lista.where((e) => e.organizadorRecorrente).toList();
      case FiltroComercialEvento.followUp:
        lista = lista.where((e) => e.temFollowUp).toList();
      case FiltroComercialEvento.todos:
        break;
    }

    if (termo.isNotEmpty) {
      lista = lista.where((e) {
        return e.nome.toLowerCase().contains(termo) ||
            e.tipoNome.toLowerCase().contains(termo) ||
            (e.cidade ?? '').toLowerCase().contains(termo) ||
            e.organizador.toLowerCase().contains(termo);
      }).toList();
    }

    lista.sort((a, b) {
      final scoreCmp = scoreDe(b).compareTo(scoreDe(a));
      if (scoreCmp != 0) return scoreCmp;
      final da = a.diasAteEvento;
      final db = b.diasAteEvento;
      if (da == null && db == null) return a.nome.compareTo(b.nome);
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    return lista;
  }

  int get totalAtivos => eventos.where((e) => e.emCurso).length;

  int get totalSemCotacao =>
      eventos.where((e) => e.semCotacao && e.emCurso).length;

  int get totalProximos90Dias =>
      eventos.where((e) => e.nosProximos90Dias).length;

  int get totalPrioridadeAlta =>
      eventos.where((e) => scoreDe(e) >= 70).length;

  int get totalComCotacao =>
      eventos.where((e) => e.emCurso && !e.semCotacao).length;

  int get totalFollowUp => eventos.where((e) => e.temFollowUp).length;

  double get taxaConversaoCotacao {
    final base = totalAtivos;
    if (base == 0) return 0;
    return totalComCotacao / base;
  }

  String get taxaConversaoLabel {
    final pct = (taxaConversaoCotacao * 100).round();
    return '$pct%';
  }

  /// % de eventos em curso na janela [0, dias] que já têm cotação.
  double conversaoNaJanela(int dias) {
    final janela = eventos
        .where((e) => e.emCurso && e.nosProximosDias(dias))
        .toList();
    if (janela.isEmpty) return 0;
    final comCotacao = janela.where((e) => !e.semCotacao).length;
    return comCotacao / janela.length;
  }

  String labelConversaoJanela(int dias) {
    final janela =
        eventos.where((e) => e.emCurso && e.nosProximosDias(dias)).length;
    if (janela == 0) return '—';
    return '${(conversaoNaJanela(dias) * 100).round()}%';
  }

  int quantidadeNaJanela(int dias) =>
      eventos.where((e) => e.emCurso && e.nosProximosDias(dias)).length;

  List<HeatmapDemandaCelula> get heatmapCidadeTipo {
    final mapa = <String, HeatmapDemandaCelula>{};
    for (final e in eventos.where((e) => e.emCurso)) {
      final cidade = (e.cidade ?? '').trim().isEmpty
          ? 'Sem cidade'
          : e.cidade!.trim();
      final tipo =
          e.tipoNome.trim().isEmpty ? 'Sem tipo' : e.tipoNome.trim();
      final chave = '${cidade.toLowerCase()}|${tipo.toLowerCase()}';
      final atual = mapa[chave];
      if (atual == null) {
        mapa[chave] = HeatmapDemandaCelula(
          cidade: cidade,
          tipoNome: tipo,
          quantidade: 1,
          semCotacao: e.semCotacao ? 1 : 0,
        );
      } else {
        mapa[chave] = HeatmapDemandaCelula(
          cidade: atual.cidade,
          tipoNome: atual.tipoNome,
          quantidade: atual.quantidade + 1,
          semCotacao: atual.semCotacao + (e.semCotacao ? 1 : 0),
        );
      }
    }
    final lista = mapa.values.toList();
    lista.sort((a, b) {
      final s = b.semCotacao.compareTo(a.semCotacao);
      if (s != 0) return s;
      final q = b.quantidade.compareTo(a.quantidade);
      if (q != 0) return q;
      return a.cidade.compareTo(b.cidade);
    });
    return lista;
  }

  int scoreDe(EventoAdmin evento) => _leadScore.calcular(evento);

  String prioridadeDe(EventoAdmin evento) =>
      _leadScore.faixaPrioridade(scoreDe(evento));

  List<String> kitDe(EventoAdmin evento) =>
      _kitServicos.sugerir(evento.tipoNome);

  Future<void> carregarEventosComTipo() async {
    try {
      carregando.value = true;
      erro.value = '';

      eventos.value = await _eventosAdmin.listarEventosComTipo();
    } catch (e) {
      erro.value = 'Erro ao carregar eventos: $e';
    } finally {
      carregando.value = false;
    }
  }

  void definirFiltro(FiltroComercialEvento filtro) {
    filtroComercial.value =
        filtroComercial.value == filtro ? FiltroComercialEvento.todos : filtro;
  }

  void _atualizarEventoLocal(EventoAdmin atualizado) {
    final i = eventos.indexWhere((e) => e.id == atualizado.id);
    if (i >= 0) eventos[i] = atualizado;
  }

  Future<List<FornecedorSugestaoAdmin>> carregarSugestoes(
    EventoAdmin evento, {
    bool forcar = false,
  }) async {
    if (!forcar && sugestoesPorEvento.containsKey(evento.id)) {
      return sugestoesPorEvento[evento.id] ?? const [];
    }
    if (carregandoSugestoes.contains(evento.id)) {
      return sugestoesPorEvento[evento.id] ?? const [];
    }
    try {
      carregandoSugestoes.add(evento.id);
      carregandoSugestoes.refresh();
      final lista =
          await _eventosAdmin.sugerirFornecedores(idEvento: evento.id);
      sugestoesPorEvento[evento.id] = lista;
      sugestoesPorEvento.refresh();
      return lista;
    } catch (e) {
      _mostrarSnackbar(
        'Sugestões',
        'Não foi possível carregar fornecedores: $e',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return const [];
    } finally {
      carregandoSugestoes.remove(evento.id);
      carregandoSugestoes.refresh();
    }
  }

  Future<void> marcarFollowUp(
    EventoAdmin evento, {
    String nota = '',
    DateTime? proximoContato,
  }) async {
    try {
      acaoEmAndamento.value = true;
      final follow = await _eventosAdmin.marcarFollowUp(
        idEvento: evento.id,
        nota: nota,
        proximoContato: proximoContato,
      );
      _atualizarEventoLocal(evento.copyWith(followUp: follow));
      _registradorAuditoria.registrar(
        acao: 'EVENTO_FOLLOW_UP',
        resumo: 'Follow-up comercial marcado no evento.',
        entidadeTipo: 'evento',
        entidadeId: evento.id,
        entidadeNome: evento.nome,
        idEvento: evento.id,
      );
      _mostrarSnackbar(
        'Follow-up marcado',
        'Oportunidade "${evento.nome}" entrou na fila de acompanhamento.',
        backgroundColor: Colors.teal.shade700,
        colorText: Colors.white,
      );
    } catch (e) {
      _mostrarSnackbar(
        'Follow-up',
        'Falha ao marcar: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } finally {
      acaoEmAndamento.value = false;
    }
  }

  Future<void> limparFollowUp(EventoAdmin evento) async {
    try {
      acaoEmAndamento.value = true;
      await _eventosAdmin.limparFollowUp(evento.id);
      _atualizarEventoLocal(
        evento.copyWith(followUp: const FollowUpComercial(marcado: false)),
      );
      _mostrarSnackbar(
        'Follow-up removido',
        'Acompanhamento limpo para "${evento.nome}".',
        backgroundColor: Colors.blueGrey.shade700,
        colorText: Colors.white,
      );
    } catch (e) {
      _mostrarSnackbar(
        'Follow-up',
        'Falha ao limpar: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } finally {
      acaoEmAndamento.value = false;
    }
  }

  Future<void> enviarNudge(EventoAdmin evento, {String? mensagem}) async {
    try {
      acaoEmAndamento.value = true;
      final kit = kitDe(evento).take(3).join(', ');
      final msg = (mensagem ?? '').trim().isNotEmpty
          ? mensagem!.trim()
          : 'Há fornecedores para ${evento.tipoNome} em ${evento.cidade ?? "sua região"}'
              '${kit.isEmpty ? "" : " ($kit)"}. Abra cotações e avance o planejamento de "${evento.nome}".';

      final resultado = await _eventosAdmin.enviarNudgeOrganizador(
        idEvento: evento.id,
        mensagem: msg,
      );
      _atualizarEventoLocal(evento.copyWith(nudge: resultado.nudge));
      sugestoesPorEvento[evento.id] = resultado.recomendacoes;
      sugestoesPorEvento.refresh();
      _registradorAuditoria.registrar(
        acao: 'EVENTO_NUDGE_COTACAO',
        resumo: 'Nudge de cotação enviado ao organizador.',
        entidadeTipo: 'evento',
        entidadeId: evento.id,
        entidadeNome: evento.nome,
        idEvento: evento.id,
      );
      _mostrarSnackbar(
        'Nudge enviado',
        resultado.recomendacoes.isEmpty
            ? 'Aviso registrado para o organizador.'
            : '${resultado.recomendacoes.length} fornecedor(es) sugeridos e aviso enviado.',
        backgroundColor: Colors.indigo.shade700,
        colorText: Colors.white,
      );
    } catch (e) {
      _mostrarSnackbar(
        'Nudge',
        'Falha ao enviar: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } finally {
      acaoEmAndamento.value = false;
    }
  }

  Future<void> acaoEvento(String acao, EventoAdmin evento) async {
    switch (acao) {
      case 'oportunidade':
        break;
      case 'follow_up':
        await marcarFollowUp(evento);
        break;
      case 'nudge':
        await enviarNudge(evento);
        break;
      case 'aprovar':
        await _eventosAdmin.aprovarEvento(evento.id);
        _registradorAuditoria.registrar(
          acao: 'EVENTO_APROVADO',
          resumo: 'Evento aprovado pelo administrador.',
          entidadeTipo: 'evento',
          entidadeId: evento.id,
          entidadeNome: evento.nome,
          idEvento: evento.id,
        );
        _mostrarSnackbar(
          'Evento aprovado',
          '${evento.nome} foi aprovado com sucesso!',
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
        );
        break;

      case 'excluir':
        Get.defaultDialog(
          title: 'Excluir evento',
          content: Text('Deseja excluir "${evento.nome}"?'),
          textConfirm: 'Excluir',
          confirmTextColor: Colors.white,
          buttonColor: Colors.redAccent,
          textCancel: 'Cancelar',
          onConfirm: () async {
            await excluirEvento(evento.id);
            Get.back();
            _mostrarSnackbar(
              'Excluído',
              'Evento removido com sucesso.',
              backgroundColor: Colors.red.shade400,
              colorText: Colors.white,
            );
          },
        );
        break;

      default:
        break;
    }
  }

  Future<void> excluirEvento(String id) async {
    final evento = eventos.firstWhereOrNull((e) => e.id == id);
    await _eventosAdmin.excluirEvento(id);
    eventos.removeWhere((e) => e.id == id);
    _registradorAuditoria.registrar(
      acao: 'EVENTO_EXCLUIDO',
      resumo: 'Evento removido pelo administrador.',
      entidadeTipo: 'evento',
      entidadeId: id,
      entidadeNome: evento?.nome,
      idEvento: id,
    );
  }

  void _mostrarSnackbar(
    String titulo,
    String mensagem, {
    Color? backgroundColor,
    Color? colorText,
  }) {
    if (Get.testMode) return;
    if (Get.context == null && Get.overlayContext == null) return;

    Get.snackbar(
      titulo,
      mensagem,
      backgroundColor: backgroundColor,
      colorText: colorText,
    );
  }
}
