import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/admin/evento_com_tipo_model.dart';

class EventosAdminController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
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

      // 🔹 Passo 1: buscar eventos
      final eventosSnap = await _db.collection('evento').get();

      final List<EventoComTipoModel> listaEventos = [];

      // 🔹 Passo 2: buscar tipo de evento para cada registro
      for (var doc in eventosSnap.docs) {
        final data = doc.data();
        final idTipoEvento =
            (data['id_tipo_evento'] ?? data['idTipoEvento'] ?? '').toString();

        String nomeTipo = 'Tipo não informado';
        if (idTipoEvento.isNotEmpty) {
          final tipoDoc = await _db.collection('tipo_evento').doc(idTipoEvento).get();
          if (tipoDoc.exists) {
            nomeTipo = (tipoDoc.data()?['nome'] ?? nomeTipo).toString();
          } else {
            final tipoSnap = await _db
                .collection('tipo_evento')
                .where('id_tipo_evento', isEqualTo: idTipoEvento)
                .limit(1)
                .get();
            if (tipoSnap.docs.isNotEmpty) {
              nomeTipo = tipoSnap.docs.first.data()['nome'] ?? nomeTipo;
            }
          }
        }

        // Monta o modelo unificado
        final evento = EventoComTipoModel.fromMap(data, doc.id, nomeTipo);
        listaEventos.add(evento);
      }

      eventos.value = listaEventos;
    } catch (e) {
      erro.value = 'Erro ao carregar eventos: $e';
    } finally {
      carregando.value = false;
    }
  }

  void acaoEvento(String acao, EventoComTipoModel evento) {
    switch (acao) {
      case 'aprovar':
        _db.collection('evento').doc(evento.id).update({'aprovado': true});
        Get.snackbar(
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
            Get.snackbar(
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
    await _db.collection('evento').doc(id).delete();
    eventos.removeWhere((e) => e.id == id);
  }
}
