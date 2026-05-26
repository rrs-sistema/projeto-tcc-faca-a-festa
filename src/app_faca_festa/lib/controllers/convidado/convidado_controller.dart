import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../../core/services/whatsGw/whatsapp_service.dart';
import './../../presentation/whatsapp/whatsapp_templates.dart';
import './grupo_convidado_controller.dart';
import './../../data/models/model.dart';
import './../evento_controller.dart';

class ConvidadoController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Lista completa de convidados do evento atual
  final RxList<ConvidadoModel> convidados = <ConvidadoModel>[].obs;

  final grupoController = Get.put(GrupoConvidadoController());

  // 🔹 Estados de carregamento e erro
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  // 🔹 IDs e filtros auxiliares
  final RxString idEventoAtual = ''.obs;
  final RxString termoBusca = ''.obs;

  final Rx<ConvidadoModel?> convidadoAtual = Rx<ConvidadoModel?>(null);

  StreamSubscription? _convidadosSub;

// =============================================================
// 🔹 Lista temporária de novos convidados (somente em memória)
// =============================================================
  final RxList<ConvidadoModel> novosConvidados = <ConvidadoModel>[].obs;

  Future<void> enviarConviteAoAdicionar(
      ConvidadoModel convidado, EventoModel evento, String tipoEvento) async {
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

      final snapshot = await _db.collection('convidado').get();

      if (snapshot.docs.isEmpty) {
        Get.snackbar(
          'Migração',
          'Nenhum convidado encontrado para migrar.',
          backgroundColor: Colors.orangeAccent,
          colorText: Colors.white,
        );
        return;
      }

      WriteBatch batch = _db.batch();

      int contadorBatch = 0;
      int totalAtualizados = 0;
      int totalIgnorados = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final tipoAtual = data['tipo_convidado'];

        final jaTemTipo = tipoAtual != null && tipoAtual.toString().trim().isNotEmpty;

        if (jaTemTipo) {
          totalIgnorados++;
          continue;
        }

        final adultoValue = data['adulto'];

        String tipoConvidado;

        if (adultoValue == false) {
          tipoConvidado = 'crianca';
        } else {
          tipoConvidado = 'adulto';
        }

        batch.update(doc.reference, {
          'tipo_convidado': tipoConvidado,
          'data_atualizacao': FieldValue.serverTimestamp(),
        });

        contadorBatch++;
        totalAtualizados++;

        if (contadorBatch == 450) {
          await batch.commit();
          batch = _db.batch();
          contadorBatch = 0;
        }
      }

      if (contadorBatch > 0) {
        await batch.commit();
      }

      Get.snackbar(
        'Migração concluída',
        '$totalAtualizados convidados atualizados. $totalIgnorados já estavam corretos.',
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
      ConvidadoModel convidado, EventoModel evento, String tipoEvento) async {
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
      ConvidadoModel convidado, EventoModel evento, String tipoEvento) async {
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
  void adicionarNovoConvidadoLocal(ConvidadoModel convidado) {
    novosConvidados.add(convidado);
  }

  /// 🔹 Remove convidado da lista local
  void removerNovoConvidadoLocal(String idConvidado) {
    novosConvidados.removeWhere((c) => c.idConvidado == idConvidado);
  }

  /// =====================================================
  /// 🔹 Busca convidado pelo ID do usuário
  /// =====================================================
  Future<ConvidadoModel?> buscarPeloIdConvidado(String idUsuario) async {
    try {
      carregando.value = true;
      final snapshot = await _db
          .collection('convidado')
          .where('id_convidado', isEqualTo: idUsuario)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final model = ConvidadoModel.fromMap(snapshot.docs.first.data());
        convidadoAtual.value = model;
        return model;
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

  Future<ConvidadoModel?> buscarPeloIdEvento(String idEvento) async {
    try {
      carregando.value = true;

      final snapshot =
          await _db.collection('convidado').where('id_evento', isEqualTo: idEvento).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        carregando.value = false;
        return ConvidadoModel.fromMap(snapshot.docs.first.data());
      } else {
        carregando.value = false;
        return null;
      }
    } catch (e) {
      carregando.value = false;
      return null;
    }
  }

  /// 🔹 Persiste todos os convidados novos no Firestore
  Future<void> enviarNovosConvidados(EventoModel evento) async {
    if (novosConvidados.isEmpty) return;

    try {
      carregando.value = true;
      final eventoController = Get.find<EventoController>();
      final tipoEvento = eventoController.tipoEventoAtual.value?.nome ?? evento.nomeEvento;

      for (final c in novosConvidados) {
        await _db.collection('convidado').doc(c.idConvidado).set(c.toMap());
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
    _db
        .collection('convidado')
        .where('id_evento', isEqualTo: idEvento)
        .snapshots()
        .listen((snapshot) {
      convidados.assignAll(
        snapshot.docs.map((d) => ConvidadoModel.fromMap(d.data())).toList(),
      );
    });
  }

  /// =============================================================
  /// 🔹 Adiciona um novo convidado ao evento
  /// =============================================================
  Future<void> adicionarConvidado(ConvidadoModel model) async {
    try {
      carregando.value = true;
      await _db.collection('convidado').doc(model.idConvidado).set(model.toMap());
    } catch (e) {
      erro.value = 'Erro ao salvar convidado: $e';
    } finally {
      carregando.value = false;
    }
  }

  /// =============================================================
  /// 🔹 Atualiza os dados de um convidado existente
  /// =============================================================
  Future<void> atualizarConvidado(ConvidadoModel model) async {
    try {
      carregando.value = true;

      await _db.collection('convidado').doc(model.idConvidado).update(model.toMap());
    } catch (e) {
      erro.value = 'Erro ao atualizar convidado: $e';
    } finally {
      carregando.value = false;
    }
  }

  /// =====================================================
  /// 🔹 Cria ou atualiza convidado no Firestore
  /// =====================================================
  Future<void> salvarConvidado(ConvidadoModel convidado) async {
    await _db.collection('convidado').doc(convidado.idConvidado).set(
          convidado.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<ConvidadoModel?> buscarPorToken(String token) async {
    final convidadoDoc = await FirebaseFirestore.instance.collection('convidado').doc(token).get();

    if (!convidadoDoc.exists) return null;

    return ConvidadoModel.fromMap(convidadoDoc.data()!);
  }

  Future<void> reservarPresente(
      {required String idPresente,
      required String idConvidado,
      required String nomeConvidado,
      required Color backgroundColor}) async {
    final ref =
        _db.collection('evento').doc(idEventoAtual.value).collection('presentes').doc(idPresente);

    await ref.update({
      'reservado_por': nomeConvidado,
      'id_convidado': idConvidado,
      'data_reserva': Timestamp.now(),
    });

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
    ConvidadoModel convidado,
    StatusConvidado novoStatus,
  ) async {
    try {
      final atualizado = convidado.copyWith(
        status: novoStatus,
        dataResposta: DateTime.now(),
      );

      await _db
          .collection('convidado')
          .doc(convidado.idConvidado)
          .set(atualizado.toMap(), SetOptions(merge: true));

      convidadoAtual.value = atualizado;

      String msg = switch (novoStatus) {
        StatusConvidado.confirmado => '🎉 Presença confirmada! Obrigado por confirmar.',
        StatusConvidado.recusado => '🙁 Sentiremos sua falta, confirmação registrada.',
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
  Future<void> atualizarStatus(String idConvidado, StatusConvidado status) async {
    try {
      await _db.collection('convidado').doc(idConvidado).update({
        'status': status.firestoreValue,
        'data_resposta': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      erro.value = 'Erro ao atualizar status: $e';
    }
  }

  /// =============================================================
  /// 🔹 Exclui um convidado
  /// =============================================================
  Future<void> excluirConvidado(String idConvidado) async {
    try {
      await _db.collection('convidado').doc(idConvidado).delete();
    } catch (e) {
      erro.value = 'Erro ao excluir convidado: $e';
    }
  }

  /// 🔹 Agrupa convidados por mesa/grupo
  Map<String, List<ConvidadoModel>> get convidadosPorMesa {
    final Map<String, List<ConvidadoModel>> grupos = {};
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
          .where((c) => c.nomeGrupo == nomeMesa && c.status == StatusConvidado.confirmado)
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
    final totalOcupados = convidados.where((c) => c.status == StatusConvidado.confirmado).length;
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

  int get totalPendentes => convidados.where((c) => c.status == StatusConvidado.pendente).length;

  int get totalRecusados => convidados.where((c) => c.status == StatusConvidado.recusado).length;

  int get totalAdultos => convidados.where((c) => c.adulto == true).length;

  int get totalCriancas => convidados.where((c) => c.adulto == false).length;

  /// =============================================================
  /// 🔹 Filtro de busca por nome ou e-mail
  /// =============================================================
  List<ConvidadoModel> get listaFiltrada {
    final termo = termoBusca.value.toLowerCase();
    if (termo.isEmpty) return convidados;
    return convidados
        .where((c) =>
            c.nome.toLowerCase().contains(termo) ||
            (c.email?.toLowerCase().contains(termo) ?? false))
        .toList();
  }

  /// =============================================================
  /// 🔹 Resetar tudo (ex: ao trocar de evento)
  /// =============================================================
  void limpar() {
    convidados.clear();
    idEventoAtual.value = '';
    termoBusca.value = '';
    erro.value = '';
  }

  @override
  void onClose() {
    _convidadosSub?.cancel();
    super.onClose();
  }
}
