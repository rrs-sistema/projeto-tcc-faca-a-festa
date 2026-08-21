import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/admin/evento_com_tipo_model.dart';
import '../../domain/usecases/gerenciar_eventos_admin.dart';

class EventosAdminController extends GetxController {
  EventosAdminController({required GerenciarEventosAdmin eventosAdmin})
      : _eventosAdmin = eventosAdmin;

  final GerenciarEventosAdmin _eventosAdmin;

  final eventos = <EventoComTipoModel>[].obs;
  final busca = ''.obs;
  final carregando = false.obs;
  final erro = ''.obs;

  List<EventoComTipoModel> get eventosFiltrados {
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

  Future<void> acaoEvento(String acao, EventoComTipoModel evento) async {
    switch (acao) {
      case 'aprovar':
        await _eventosAdmin.aprovarEvento(evento.id);
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
    await _eventosAdmin.excluirEvento(id);
    eventos.removeWhere((e) => e.id == id);
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
