import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';

Future<void> showResponderCotacaoBottomSheet({
  required BuildContext context,
  required String nomeSolicitante,
  required String idCotacao,
  required String categoriaNome,
  required String descricao,
  required String dataLimite,
  required double ofertaDesejada,
  required EventThemeController theme,
  required FornecedorController fornecedorController,
  required GerenciarCotacoes cotacoes,
}) async {
  final idFornecedor = fornecedorController.fornecedor.value?.idFornecedor;
  if (idFornecedor == null) return;
  await Get.toNamed('/jornada-atendimento',
      arguments: {'idCotacao': idCotacao, 'idFornecedor': idFornecedor});
}
