import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../../data/models/model.dart';
import '../../data/services/auditoria/auditoria_app.dart';
import '../../domain/entities/auditoria_evento.dart';
import '../../domain/usecases/gerenciar_servicos_produto.dart';

class ServicoProdutoController extends GetxController {
  ServicoProdutoController({required GerenciarServicosProduto servicos})
      : _servicos = servicos;

  final GerenciarServicosProduto _servicos;

  final RxList<ServicoProdutoModel> servicos = <ServicoProdutoModel>[].obs;
  final RxList<FornecedorServicoDetalhadoDto> servicosFornecedor =
      <FornecedorServicoDetalhadoDto>[].obs;
  final RxString erro = ''.obs;

  StreamSubscription<void>? _servicosSubscription;
  StreamSubscription<void>? _servicosAdminSubscription;

  /// 🔄 Alterna automaticamente o listener por fornecedor
  Timer? _fornecedorTimeoutTimer;

  final RxBool listenerAtivoAdmin = false.obs;
  final RxBool listenerAtivoFornecedor = false.obs;

  final RxBool carregando = false.obs;

  final RxMap<String, List<ServicoProdutoModel>> servicosPorSubcategoria =
      <String, List<ServicoProdutoModel>>{}.obs;

  @override
  void onClose() {
    _servicosAdminSubscription?.cancel();
    _servicosSubscription?.cancel();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    carregarServicos();
  }

  Future<void> escutarServicosFornecedor(String idFornecedor) async {
    debugPrint('📡 Listener FORNECEDOR iniciado → $idFornecedor');

    await _servicosSubscription?.cancel();

    _servicosSubscription =
        _servicos.observarVinculosFornecedor(idFornecedor).listen((_) async {
      debugPrint('♻️ Detectada mudança REAL-TIME → recarregando...');
      await carregarServicosComDetalhesOtimizado(idFornecedor: idFornecedor);
    });
  }

  /// 🔹 Carrega serviços com detalhes completos (modo ADMIN ou FORNECEDOR)
  Future<void> carregarServicosComDetalhesOtimizado(
      {String? idFornecedor}) async {
    try {
      carregando.value = true;
      servicosFornecedor.clear();
      erro.value = '';

      final lista = await _servicos.listarServicosComDetalhes(
        idFornecedor: idFornecedor,
      );
      servicosFornecedor.assignAll(lista);
      debugPrint('🟢 [SERVIÇOS] Lista carregada: ${lista.length} itens.');
    } catch (e, s) {
      erro.value = e.toString();
      servicosFornecedor.clear();
      debugPrint('❌ Erro ao carregar serviços: $e\n$s');
    } finally {
      carregando.value = false;
    }
  }

  Future<List<ServicoProdutoModel>> carregarServicosPorSubcategoria(
      String idSubcategoria) async {
    try {
      carregando.value = true;
      debugPrint(
          '🔹 [SERVIÇOS] Buscando serviços para subcategoria: $idSubcategoria');

      final lista =
          await _servicos.listarServicosAtivosPorSubcategoria(idSubcategoria);

      servicosPorSubcategoria[idSubcategoria] = lista;
      servicos.assignAll(lista);

      debugPrint(
          '✅ [SERVIÇOS] ${lista.length} serviços encontrados para subcategoria $idSubcategoria');
      debugPrint(
          '📊 [SERVIÇOS MAP] Chaves atuais: ${servicosPorSubcategoria.keys.toList()}');
      return lista;
    } catch (e) {
      debugPrint(
          '⚠️ [SERVIÇOS] Erro ao carregar serviços da subcategoria $idSubcategoria: $e');
      return [];
    } finally {
      carregando.value = false;
    }
  }

  void limparServicos() {
    servicosPorSubcategoria.clear();
    servicos.clear();
    debugPrint('🧹 [SERVIÇOS] Lista e mapa de serviços limpos.');
    servicosPorSubcategoria.refresh();
  }

  void removerServicosPorSubcategoria(String idSubcategoria) {
    servicosPorSubcategoria.remove(idSubcategoria);
  }

  Future<void> carregarServicos() async {
    try {
      carregando.value = true;
      servicos.assignAll(await _servicos.listarServicos());
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao carregar serviços: $e');
    } finally {
      carregando.value = false;
    }
  }

  Future<void> buscarServicosDoFornecedorPeloAdmin(String idFornecedor) async {
    toggleListenerFornecedor(idFornecedor: idFornecedor);
  }

  void pararListenerServicosAdmin() {
    _servicosAdminSubscription?.cancel();
    _servicosAdminSubscription = null;
    debugPrint('🛑 Listener de serviços ADMIN encerrado.');
  }

  ServicoProdutoModel? buscarPorId(String id) {
    return servicos.firstWhereOrNull((s) => s.id == id);
  }

  Future<void> excluirServico(String id) async {
    final atual = buscarPorId(id);
    await _servicos.excluirServico(id);
    AuditoriaApp.registrar(
      acao: 'SERVICO_CATALOGO_EXCLUIDO',
      resumo: 'Serviço removido do catálogo da plataforma.',
      entidadeTipo: 'servico_produto',
      entidadeId: id,
      entidadeNome: atual?.nome,
    );
    await carregarServicos();
  }

  Future<void> salvarServico(ServicoProdutoModel model) async {
    await _servicos.salvarServico(model);
    AuditoriaApp.registrar(
      acao: 'SERVICO_CATALOGO_SALVO',
      resumo: 'Serviço do catálogo salvo.',
      entidadeTipo: 'servico_produto',
      entidadeId: model.id,
      entidadeNome: model.nome,
      mudancas: [
        AuditoriaMudanca(
          campo: 'Ativo',
          para: model.ativo ? 'sim' : 'não',
        ),
      ],
    );
    await carregarServicos();
  }

  /// Grava (merge) o catálogo padrão de serviços/produtos no Firestore.
  /// Preserva IDs já usados por fornecedores, fotos e cotações.
  Future<int> popularCatalogoInicial() async {
    final total = await _servicos.popularCatalogoInicial();
    await carregarServicos();
    await carregarServicosComDetalhesOtimizado();
    return total;
  }

  /// 🔄 Alterna automaticamente entre iniciar e parar o listener Admin
  Future<void> toggleListenerAdmin() async {
    if (listenerAtivoAdmin.value) {
      // Listener está ativo → parar
      debugPrint('🛑 Parando listener de serviços (Admin)...');
      await _servicosAdminSubscription?.cancel();
      _servicosAdminSubscription = null;
      listenerAtivoAdmin.value = false;
      debugPrint('✅ Listener (Admin) parado.');
    } else {
      // Listener está inativo → iniciar
      debugPrint('▶️ Iniciando listener de serviços (Admin)...');
      carregarServicosComDetalhesOtimizado();
      listenerAtivoAdmin.value = true;
    }
  }

  Future<void> toggleListenerFornecedor({
    required String idFornecedor,
    Duration timeout = const Duration(minutes: 2),
  }) async {
    if (listenerAtivoFornecedor.value) {
      // PARAR LISTENER
      debugPrint('🛑 Parando listener do fornecedor $idFornecedor...');
      await _servicosSubscription?.cancel();
      _servicosSubscription = null;
      listenerAtivoFornecedor.value = false;

      _fornecedorTimeoutTimer?.cancel();
      _fornecedorTimeoutTimer = null;

      return;
    }

    // INICIAR LISTENER
    debugPrint('▶️ Iniciando listener do fornecedor $idFornecedor...');

    // Carrega imediatamente antes de abrir o listener realtime
    await carregarServicosComDetalhesOtimizado(idFornecedor: idFornecedor);

    // Agora sim: cria o listener real-time
    await escutarServicosFornecedor(idFornecedor);

    listenerAtivoFornecedor.value = true;

    // Timeout opcional
    _fornecedorTimeoutTimer?.cancel();
    _fornecedorTimeoutTimer = Timer(timeout, () async {
      if (listenerAtivoFornecedor.value) {
        debugPrint('⏰ Timeout: encerrando listener fornecedor.');
        await _servicosSubscription?.cancel();
        _servicosSubscription = null;
        listenerAtivoFornecedor.value = false;
      }
    });

    debugPrint('⏱️ Listener ativo por ${timeout.inMinutes} min.');
  }

  /// 🔍 Valida se o fornecedor realmente possui a subcategoria
  Future<bool> validarSubcategoriaFornecedor(
      String idFornecedor, String idSubcat) async {
    return _servicos.validarSubcategoriaFornecedor(idFornecedor, idSubcat);
  }

  /// ============================================================
  /// 🔗 Vincular serviço ao fornecedor — VERSÃO CORRIGIDA
  /// ============================================================
  Future<void> vincularServico(FornecedorProdutoServicoModel model) async {
    try {
      carregando.value = true;

      debugPrint('💾 [VÍNCULO] Salvando vínculo do serviço...');

      /// 1) VALIDAR SUBCATEGORIA
      final ok = await validarSubcategoriaFornecedor(
        model.idFornecedor,
        model.idSubcategoria ?? '',
      );

      // 2) Se não possuir → cadastrar automaticamente
      if (!ok) {
        debugPrint('⚠ Subcategoria não encontrada. Adicionando...');
        await adicionarSubcategoriaAoFornecedor(
          model.idFornecedor,
          model.idSubcategoria!,
        );
      }

      /// 2) SALVAR VÍNCULO
      await _servicos.salvarVinculo(model);

      debugPrint('🟢 Vínculo salvo com sucesso');
      AuditoriaApp.registrar(
        acao: 'SERVICO_FORNECEDOR_SALVO',
        resumo: 'Serviço do fornecedor publicado ou atualizado.',
        entidadeTipo: 'fornecedor_servico',
        entidadeId: model.id,
        entidadeNome: model.idProdutoServico,
        idFornecedor: model.idFornecedor,
        idServico: model.idProdutoServico,
        mudancas: [
          AuditoriaMudanca(
            campo: 'Preço',
            para: model.preco.toStringAsFixed(2),
          ),
          AuditoriaMudanca(
            campo: 'Ativo',
            para: model.ativo ? 'sim' : 'não',
          ),
        ],
      );

      /// 3) RECARREGAR SERVIÇOS (SEMPRE)
      await carregarServicosComDetalhesOtimizado(
        idFornecedor: model.idFornecedor,
      );

      _mostrarSnackbar(
        'Sucesso',
        'Serviço vinculado ao fornecedor!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
    } catch (e, s) {
      debugPrint('❌ Erro ao vincular serviço: $e\n$s');
      erro.value = e.toString();
      _mostrarSnackbar(
        'Erro',
        erro.value,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      carregando.value = false;
    }
  }

  Future<void> adicionarSubcategoriaAoFornecedor(
    String idFornecedor,
    String idSubcat,
  ) async {
    await _servicos.adicionarSubcategoriaAoFornecedor(idFornecedor, idSubcat);
    debugPrint("🟢 Subcategoria adicionada automaticamente ao fornecedor.");
  }

  Future<void> excluirVinculo(String id, String idFornecedor) async {
    await _servicos.excluirVinculo(id);
    AuditoriaApp.registrar(
      acao: 'SERVICO_FORNECEDOR_EXCLUIDO',
      resumo: 'Serviço removido do catálogo do fornecedor.',
      entidadeTipo: 'fornecedor_servico',
      entidadeId: id,
      idFornecedor: idFornecedor,
    );
    await carregarServicosComDetalhesOtimizado(
      idFornecedor: idFornecedor,
    );
  }

  void _mostrarSnackbar(
    String titulo,
    String mensagem, {
    required Color backgroundColor,
    required Color colorText,
  }) {
    if (Get.context == null) return;

    Get.snackbar(
      titulo,
      mensagem,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: colorText,
    );
  }
}
