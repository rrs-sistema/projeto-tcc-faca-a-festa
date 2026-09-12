import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/evento_admin.dart';
import 'package:app_faca_festa/domain/services/auditoria_registrar.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_eventos_admin.dart';

class EventosAdminController extends GetxController {
  EventosAdminController({
    required GerenciarEventosAdmin eventosAdmin,
    AuditoriaRegistrar? auditoria,
    AuditoriaRegistrar? Function()? auditoriaResolver,
  })  : _eventosAdmin = eventosAdmin,
        _auditoria = auditoria,
        _auditoriaResolver = auditoriaResolver;

  final GerenciarEventosAdmin _eventosAdmin;
  final AuditoriaRegistrar? _auditoria;
  final AuditoriaRegistrar? Function()? _auditoriaResolver;
  AuditoriaRegistrar get _registradorAuditoria =>
      _auditoria ??
      _auditoriaResolver?.call() ??
      const AuditoriaRegistrarVazio();

  final eventos = <EventoAdmin>[].obs;
  final busca = ''.obs;
  final carregando = false.obs;
  final erro = ''.obs;

  List<EventoAdmin> get eventosFiltrados {
    final termo = busca.value.trim().toLowerCase();
    if (termo.isEmpty) return eventos.toList();
    return eventos.where((e) {
      return e.nome.toLowerCase().contains(termo) ||
          e.tipoNome.toLowerCase().contains(termo) ||
          (e.cidade ?? '').toLowerCase().contains(termo) ||
          e.organizador.toLowerCase().contains(termo);
    }).toList();
  }

  int get totalAtivos => eventos.where((e) => e.emCurso).length;

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

  Future<void> acaoEvento(String acao, EventoAdmin evento) async {
    switch (acao) {
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
