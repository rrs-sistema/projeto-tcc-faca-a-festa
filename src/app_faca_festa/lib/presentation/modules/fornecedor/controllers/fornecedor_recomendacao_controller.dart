import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/models/fornecedor/fornecedor_recomendacao_model.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedor_recomendacoes.dart';

class FornecedorRecomendacaoController extends GetxController {
  FornecedorRecomendacaoController({
    required GerenciarFornecedorRecomendacoes recomendacoesFornecedor,
  }) : _recomendacoesFornecedor = recomendacoesFornecedor;

  final GerenciarFornecedorRecomendacoes _recomendacoesFornecedor;

  final RxBool carregando = false.obs;
  final RxBool gerando = false.obs;
  final RxString erro = ''.obs;
  final RxList<FornecedorRecomendacaoModel> recomendacoes =
      <FornecedorRecomendacaoModel>[].obs;

  String? _eventoCarregado;
  String? _usuarioCarregado;
  Future<void>? _carregamentoEmAndamento;
  final Set<String> _geracaoTentadaPorEvento = <String>{};

  bool get ocupado => carregando.value || gerando.value;

  /// Reutiliza o cache em memória. Só consulta Firestore/IA quando o contexto muda ou é forçado.
  Future<void> garantirRecomendacoes({
    required String idEvento,
    required String idUsuario,
    int limite = 10,
    bool forcar = false,
    bool gerarSeVazio = false,
    bool modoDemo = false,
  }) async {
    if (idEvento.trim().isEmpty || idUsuario.trim().isEmpty) {
      recomendacoes.clear();
      _eventoCarregado = null;
      _usuarioCarregado = null;
      return;
    }

    final mesmoContexto =
        _eventoCarregado == idEvento && _usuarioCarregado == idUsuario;

    if (!forcar && mesmoContexto && recomendacoes.isNotEmpty) {
      return;
    }

    if (!forcar &&
        mesmoContexto &&
        _geracaoTentadaPorEvento.contains(idEvento)) {
      return;
    }

    if (_carregamentoEmAndamento != null && mesmoContexto && !forcar) {
      await _carregamentoEmAndamento;
      return;
    }

    final execucao = () async {
      if (!forcar) {
        await carregarRecomendacoesSalvas(
          idEvento: idEvento,
          idUsuario: idUsuario,
          limite: limite,
        );
      }

      _eventoCarregado = idEvento;
      _usuarioCarregado = idUsuario;

      final deveGerar = forcar || (gerarSeVazio && recomendacoes.isEmpty);
      if (!deveGerar) return;
      if (!forcar && _geracaoTentadaPorEvento.contains(idEvento)) return;

      _geracaoTentadaPorEvento.add(idEvento);
      await gerarRecomendacoes(
        idEvento: idEvento,
        limite: limite,
        modoDemo: modoDemo,
      );
    }();

    _carregamentoEmAndamento = execucao;
    try {
      await execucao;
    } finally {
      if (identical(_carregamentoEmAndamento, execucao)) {
        _carregamentoEmAndamento = null;
      }
    }
  }

  Future<void> carregarRecomendacoesSalvas({
    required String idEvento,
    required String idUsuario,
    int limite = 10,
  }) async {
    if (idEvento.trim().isEmpty || idUsuario.trim().isEmpty) {
      recomendacoes.clear();
      return;
    }

    try {
      carregando.value = true;
      erro.value = '';

      debugPrint(
        '🔎 [FornecedorRecomendacao] Buscando recomendações salvas | '
        'id_evento=$idEvento | id_usuario=$idUsuario',
      );

      final lista = await _recomendacoesFornecedor.carregarRecomendacoesSalvas(
        idEvento: idEvento,
        idUsuario: idUsuario,
        limite: limite,
      );

      debugPrint(
        '✅ [FornecedorRecomendacao] ${lista.length} recomendações salvas carregadas.',
      );

      recomendacoes.assignAll(lista);
    } catch (e, s) {
      erro.value = 'Erro ao carregar recomendações.';

      debugPrint(
        '❌ [FornecedorRecomendacao] carregarRecomendacoesSalvas: $e\n$s',
      );
    } finally {
      carregando.value = false;
    }
  }

  Future<void> gerarRecomendacoes({
    required String idEvento,
    int limite = 10,
    bool modoDemo = false,
  }) async {
    if (idEvento.trim().isEmpty) return;

    try {
      gerando.value = true;
      erro.value = '';

      debugPrint(
        '🧠 [FornecedorRecomendacao] Chamando IA | '
        'idEvento=$idEvento | limite=$limite | modoDemo=$modoDemo',
      );

      final lista = await _recomendacoesFornecedor.gerarRecomendacoes(
        idEvento: idEvento,
        limite: limite,
        modoDemo: modoDemo,
      );

      debugPrint(
        '✅ [FornecedorRecomendacao] IA retornou ${lista.length} recomendações.',
      );

      recomendacoes.assignAll(lista);
    } catch (e, s) {
      erro.value = 'Erro ao gerar recomendações.';
      debugPrint('❌ [FornecedorRecomendacao] gerarRecomendacoes: $e\n$s');
    } finally {
      gerando.value = false;
    }
  }

  Future<void> atualizarRecomendacoes({
    required String idEvento,
    required String idUsuario,
    int limite = 10,
    bool modoDemo = false,
  }) {
    return garantirRecomendacoes(
      idEvento: idEvento,
      idUsuario: idUsuario,
      limite: limite,
      forcar: true,
      gerarSeVazio: true,
      modoDemo: modoDemo,
    );
  }

  Future<void> registrarInteracao({
    required String idEvento,
    required String idFornecedor,
    required String acao,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) async {
    if (idEvento.trim().isEmpty ||
        idFornecedor.trim().isEmpty ||
        acao.trim().isEmpty) {
      return;
    }

    try {
      await _recomendacoesFornecedor.registrarInteracao(
        idEvento: idEvento,
        idFornecedor: idFornecedor,
        acao: acao,
        tipoEventoId: tipoEventoId,
        tipoEventoNome: tipoEventoNome,
        cidade: cidade,
      );
    } catch (e, s) {
      debugPrint('❌ [FornecedorInteracao] registrarInteracao: $e\n$s');
    }
  }

  Future<void> visualizarFornecedor({
    required String idEvento,
    required String idFornecedor,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) {
    return registrarInteracao(
      idEvento: idEvento,
      idFornecedor: idFornecedor,
      acao: 'visualizou',
      tipoEventoId: tipoEventoId,
      tipoEventoNome: tipoEventoNome,
      cidade: cidade,
    );
  }

  Future<void> favoritarFornecedor({
    required String idEvento,
    required String idFornecedor,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) {
    return registrarInteracao(
      idEvento: idEvento,
      idFornecedor: idFornecedor,
      acao: 'favoritou',
      tipoEventoId: tipoEventoId,
      tipoEventoNome: tipoEventoNome,
      cidade: cidade,
    );
  }

  Future<void> pedirOrcamentoFornecedor({
    required String idEvento,
    required String idFornecedor,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) {
    return registrarInteracao(
      idEvento: idEvento,
      idFornecedor: idFornecedor,
      acao: 'pediu_orcamento',
      tipoEventoId: tipoEventoId,
      tipoEventoNome: tipoEventoNome,
      cidade: cidade,
    );
  }

  Future<void> reservarFornecedor({
    required String idEvento,
    required String idFornecedor,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) {
    return registrarInteracao(
      idEvento: idEvento,
      idFornecedor: idFornecedor,
      acao: 'reservou',
      tipoEventoId: tipoEventoId,
      tipoEventoNome: tipoEventoNome,
      cidade: cidade,
    );
  }

  Future<void> dispensarFornecedor({
    required String idEvento,
    required String idFornecedor,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) async {
    await registrarInteracao(
      idEvento: idEvento,
      idFornecedor: idFornecedor,
      acao: 'dispensou',
      tipoEventoId: tipoEventoId,
      tipoEventoNome: tipoEventoNome,
      cidade: cidade,
    );

    recomendacoes.removeWhere((item) => item.idFornecedor == idFornecedor);
  }
}
