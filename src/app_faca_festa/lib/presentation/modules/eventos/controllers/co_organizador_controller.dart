import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/services/co_organizador/co_organizador_service.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';

class CoOrganizadorController extends GetxController {
  CoOrganizadorController({
    required this.idEvento,
    CoOrganizadorService? service,
  }) : _service = service ?? CoOrganizadorService();

  final String idEvento;
  final CoOrganizadorService _service;

  final carregando = true.obs;
  final enviando = false.obs;
  /// E-mail do convite em andamento (bloqueia duplo toque e destaca o item).
  final emailEmEnvio = ''.obs;
  final erro = RxnString();
  final resumo = Rxn<ResumoCoOrganizadores>();
  final buscaConvidado = ''.obs;
  final mostrarFormularioEmail = false.obs;

  final emailCtrl = TextEditingController();
  final nomeCtrl = TextEditingController();
  final buscaCtrl = TextEditingController();

  ConvidadoController? get _convidados {
    if (!Get.isRegistered<ConvidadoController>()) return null;
    return Get.find<ConvidadoController>();
  }

  bool get carregandoConvidados => _convidados?.carregando.value ?? false;

  /// E-mails já na equipe ou com convite pendente.
  Set<String> get _emailsBloqueados {
    final bloqueados = <String>{};
    final atual = resumo.value;
    if (atual == null) return bloqueados;
    for (final m in atual.membros) {
      final email = m.email.trim().toLowerCase();
      if (email.isNotEmpty) bloqueados.add(email);
    }
    for (final c in atual.convitesPendentes) {
      final email = c.email.trim().toLowerCase();
      if (email.isNotEmpty) bloqueados.add(email);
    }
    return bloqueados;
  }

  /// Adultos do evento com e-mail, ainda disponíveis para co-organizar.
  List<Convidado> get convidadosDisponiveis {
    final lista = _convidados?.convidados.toList() ?? const <Convidado>[];
    final bloqueados = _emailsBloqueados;
    final termo = buscaConvidado.value.trim().toLowerCase();

    final filtrados = lista.where((c) {
      if (!c.adulto) return false;
      final email = c.emailNormalizadoEfetivo;
      if (email.isEmpty) return false;
      if (bloqueados.contains(email)) return false;
      if (termo.isEmpty) return true;
      return c.nome.toLowerCase().contains(termo) || email.contains(termo);
    }).toList();

    filtrados.sort(
      (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
    );
    return filtrados;
  }

  /// Adultos sem e-mail (aparecem na busca só para orientar o dono).
  List<Convidado> get convidadosSemEmail {
    final lista = _convidados?.convidados.toList() ?? const <Convidado>[];
    final termo = buscaConvidado.value.trim().toLowerCase();
    return lista.where((c) {
      if (!c.adulto) return false;
      if (c.emailNormalizadoEfetivo.isNotEmpty) return false;
      if (termo.isEmpty) return true;
      return c.nome.toLowerCase().contains(termo);
    }).toList();
  }

  int get totalConvidadosComEmail {
    final lista = _convidados?.convidados.toList() ?? const <Convidado>[];
    return lista
        .where((c) => c.adulto && c.emailNormalizadoEfetivo.isNotEmpty)
        .length;
  }

  @override
  void onInit() {
    super.onInit();
    buscaCtrl.addListener(() {
      buscaConvidado.value = buscaCtrl.text;
    });
    carregar();
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    nomeCtrl.dispose();
    buscaCtrl.dispose();
    super.onClose();
  }

  Future<void> carregar() async {
    carregando.value = true;
    erro.value = null;
    try {
      await Future.wait([
        _service.listar(idEvento).then((value) => resumo.value = value),
        _garantirListaConvidados(),
      ]);
    } on FinanceiroCallableException catch (e) {
      erro.value = e.message ?? e.code;
    } catch (e) {
      erro.value = 'Não foi possível carregar a equipe.';
    } finally {
      carregando.value = false;
    }
  }

  Future<void> _garantirListaConvidados() async {
    final controller = _convidados;
    if (controller == null) return;
    await controller.escutarConvidados(idEvento);
  }

  Future<bool> convidarDaLista(Convidado convidado) async {
    if (enviando.value) return false;
    final email = convidado.emailNormalizadoEfetivo;
    if (email.isEmpty) {
      Get.snackbar(
        'E-mail necessário',
        'Cadastre um e-mail para ${convidado.nome} na lista de convidados.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    emailCtrl.text = email;
    nomeCtrl.text = convidado.nome.trim();
    return convidar();
  }

  Future<bool> convidar() async {
    if (enviando.value) return false;
    final email = emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar(
        'E-mail',
        'Informe um e-mail válido para convidar.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    enviando.value = true;
    emailEmEnvio.value = email.toLowerCase();
    EasyLoading.show(status: 'Enviando convite...');
    try {
      await _service.convidar(
        idEvento: idEvento,
        email: email,
        nome: nomeCtrl.text.trim(),
      );
      emailCtrl.clear();
      nomeCtrl.clear();
      buscaCtrl.clear();
      buscaConvidado.value = '';
      mostrarFormularioEmail.value = false;
      await carregar();
      EasyLoading.dismiss();
      Get.snackbar(
        'Convite enviado',
        'A pessoa receberá um e-mail para aceitar.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on FinanceiroCallableException catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Não foi possível convidar',
        e.message ?? e.code,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (_) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Não foi possível convidar',
        'Tente novamente em instantes.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      enviando.value = false;
      emailEmEnvio.value = '';
      if (EasyLoading.isShow) EasyLoading.dismiss();
    }
  }

  Future<void> remover(MembroOrganizacao membro) async {
    if (enviando.value) return;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remover co-organizador?'),
        content: Text(
          '${membro.nome} deixará de gerir este evento. '
          'Contratações e autorizações já feitas permanecem no histórico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (enviando.value) return;

    enviando.value = true;
    EasyLoading.show(status: 'Removendo...');
    try {
      await _service.remover(idEvento: idEvento, uid: membro.uid);
      await carregar();
      if (Get.isRegistered<EventoController>()) {
        // Stream do evento atualiza a lista local.
      }
      EasyLoading.dismiss();
      Get.snackbar(
        'Removido',
        '${membro.nome} não é mais co-organizador.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FinanceiroCallableException catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Não foi possível remover',
        e.message ?? e.code,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      enviando.value = false;
      if (EasyLoading.isShow) EasyLoading.dismiss();
    }
  }
}
