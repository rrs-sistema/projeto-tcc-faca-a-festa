import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/central_mediacao_remote.dart';
import 'package:app_faca_festa/domain/entities/financeiro/mediacao_operacional.dart';
import 'package:app_faca_festa/domain/services/mediacao_operacional_service.dart';

class CentralMediacaoController extends GetxController {
  CentralMediacaoController({
    required this.remote,
    MediacaoOperacionalService? dominio,
  }) : dominio = dominio ?? const MediacaoOperacionalService();

  final CentralMediacaoRemote remote;
  final MediacaoOperacionalService dominio;

  final carregando = false.obs;
  final enviando = false.obs;
  final erro = ''.obs;
  final aviso = ''.obs;
  final linhas = <LinhaCentralContratacao>[].obs;
  final detalhe = Rxn<Map<String, dynamic>>();
  final casoDetalhe = Rxn<Map<String, dynamic>>();
  final registrosCaso = <RegistroMediacaoView>[].obs;

  /// Filtros preservados ao voltar do detalhe.
  final busca = ''.obs;
  final estadoComercial = ''.obs;
  final estadoExecucao = ''.obs;
  final casoAberto = Rxn<bool>();
  final eixoTemporal = 'data_evento'.obs;
  final periodoInicio = ''.obs;
  final periodoFim = ''.obs;
  final agruparPorEvento = false.obs;
  final offset = 0.obs;
  final limite = 50.obs;
  final paginacaoAviso = ''.obs;
  final truncado = false.obs;
  final totalFiltradoAmostra = 0.obs;
  final idOrcamentoSelecionado = ''.obs;
  final scrollOffsetLista = 0.0.obs;

  int _geracao = 0;

  bool get temPaginaAnterior => offset.value > 0;

  bool get temProximaPagina {
    final total = totalFiltradoAmostra.value;
    if (total <= 0) return false;
    return offset.value + linhas.length < total;
  }

  String get rotuloPaginacao {
    final total = totalFiltradoAmostra.value;
    if (total <= 0 || linhas.isEmpty) {
      return 'Nenhum item neste recorte';
    }
    final ini = offset.value + 1;
    final fim = offset.value + linhas.length;
    return 'Mostrando $ini–$fim de $total';
  }

  Future<void> paginaAnterior() async {
    if (!temPaginaAnterior || carregando.value) return;
    offset.value = (offset.value - limite.value).clamp(0, 1 << 30);
    await carregarLista();
  }

  Future<void> paginaProxima() async {
    if (!temProximaPagina || carregando.value) return;
    offset.value += limite.value;
    await carregarLista();
  }

  Future<void> carregarLista() async {
    final g = ++_geracao;
    carregando.value = true;
    erro.value = '';
    aviso.value = '';
    try {
      final r = await remote.consultarCentral(
        busca: busca.value,
        estadoComercial: estadoComercial.value,
        estadoExecucao: estadoExecucao.value,
        casoAberto: casoAberto.value,
        eixoTemporal: eixoTemporal.value,
        periodoInicio: periodoInicio.value,
        periodoFim: periodoFim.value,
        agruparPorEvento: agruparPorEvento.value,
        offset: offset.value,
        limite: limite.value,
      );
      if (g != _geracao) return;
      final raw = r['linhas'];
      final lista = <LinhaCentralContratacao>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            lista.add(LinhaCentralContratacao.fromMap(
              Map<String, dynamic>.from(item),
            ));
          }
        }
      }
      final pag = r['paginacao'];
      var total = lista.length;
      if (pag is Map) {
        truncado.value = pag['truncado'] == true;
        paginacaoAviso.value = (pag['aviso'] ?? '').toString();
        if (pag['total_filtrado_amostra'] is num) {
          total = (pag['total_filtrado_amostra'] as num).toInt();
        }
      }
      totalFiltradoAmostra.value = total;

      // Offset além do total (ex.: Próxima com só 8 itens) → volta à última página.
      if (lista.isEmpty && total > 0 && offset.value > 0) {
        final ultimo =
            ((total - 1) ~/ limite.value) * limite.value;
        offset.value = ultimo;
        carregando.value = false;
        await carregarLista();
        return;
      }

      linhas.assignAll(lista);
      final avisos = <String>[
        if ((r['aviso'] ?? '').toString().trim().isNotEmpty)
          (r['aviso'] as Object).toString().trim(),
        if (paginacaoAviso.value.isNotEmpty) paginacaoAviso.value,
      ];
      aviso.value = avisos.join(' ');
    } catch (e) {
      if (g != _geracao) return;
      erro.value = e.toString();
      linhas.clear();
    } finally {
      if (g == _geracao) carregando.value = false;
    }
  }

  Future<void> abrirDetalhe(String idOrcamento) async {
    idOrcamentoSelecionado.value = idOrcamento;
    carregando.value = true;
    erro.value = '';
    try {
      detalhe.value = await remote.consultarDetalhe(idOrcamento: idOrcamento);
      final av = (detalhe.value?['aviso'] ?? '').toString().trim();
      if (av.isNotEmpty) aviso.value = av;
      final hist = detalhe.value?['historico_mediacao'];
      if (hist is Map && hist['caso_aberto'] is Map) {
        final caso = Map<String, dynamic>.from(hist['caso_aberto'] as Map);
        final idCaso = (caso['id'] ?? '').toString();
        if (idCaso.isNotEmpty) {
          await carregarCaso(idCaso);
        } else {
          casoDetalhe.value = caso;
          registrosCaso.clear();
        }
      } else {
        casoDetalhe.value = null;
        registrosCaso.clear();
      }
    } catch (e) {
      erro.value = e.toString();
      detalhe.value = null;
    } finally {
      carregando.value = false;
    }
  }

  Future<void> carregarCaso(String idCaso) async {
    try {
      final r = await remote.consultarCaso(idCaso: idCaso);
      casoDetalhe.value =
          r['caso'] is Map ? Map<String, dynamic>.from(r['caso'] as Map) : null;
      final regs = r['registros'];
      final lista = <RegistroMediacaoView>[];
      if (regs is List) {
        for (final item in regs) {
          if (item is Map) {
            lista.add(RegistroMediacaoView.fromMap(
              Map<String, dynamic>.from(item),
            ));
          }
        }
      }
      registrosCaso.assignAll(lista);
    } catch (e) {
      erro.value = e.toString();
    }
  }

  Future<bool> abrirCaso({
    required String idEvento,
    required String idContrato,
    required String idOrcamento,
    required String motivo,
    String categoria = 'divergencia_servico',
    String? idFornecedor,
    String? idContratante,
  }) async {
    if (enviando.value) return false;
    enviando.value = true;
    erro.value = '';
    try {
      final chave =
          'caso-$idOrcamento-${DateTime.now().millisecondsSinceEpoch}';
      await remote.abrirCaso(
        idEvento: idEvento,
        idContrato: idContrato,
        idOrcamento: idOrcamento,
        motivo: motivo,
        chaveIdempotencia: chave,
        categoria: categoria,
        idFornecedor: idFornecedor,
        idContratante: idContratante,
      );
      await abrirDetalhe(idOrcamento);
      return true;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      enviando.value = false;
    }
  }

  Future<bool> registrarAnalise(String texto, {bool interna = true}) async {
    final idCaso = (casoDetalhe.value?['id'] ?? '').toString();
    if (idCaso.isEmpty || enviando.value) return false;
    enviando.value = true;
    try {
      await remote.registrarRegistro(
        idCaso: idCaso,
        texto: texto,
        tipo: interna ? 'nota_interna' : 'info_compartilhavel',
        visibilidade: interna ? 'interna' : 'compartilhavel',
        novoEstado: 'em_analise',
      );
      await carregarCaso(idCaso);
      return true;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      enviando.value = false;
    }
  }

  Future<bool> solicitarInfo(String texto) async {
    final idCaso = (casoDetalhe.value?['id'] ?? '').toString();
    if (idCaso.isEmpty || enviando.value) return false;
    enviando.value = true;
    try {
      final r = await remote.solicitarInformacao(idCaso: idCaso, texto: texto);
      aviso.value = (r['aviso'] ?? '').toString();
      await carregarCaso(idCaso);
      return true;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      enviando.value = false;
    }
  }

  Future<bool> registrarDecisao(String texto, {String tipo = 'manter'}) async {
    final idCaso = (casoDetalhe.value?['id'] ?? '').toString();
    if (idCaso.isEmpty || enviando.value) return false;
    enviando.value = true;
    try {
      final r = await remote.registrarDecisao(
        idCaso: idCaso,
        texto: texto,
        tipoDecisao: tipo,
      );
      aviso.value = (r['aviso'] ?? '').toString();
      await carregarCaso(idCaso);
      return true;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      enviando.value = false;
    }
  }

  Future<bool> fecharCaso(String conclusao) async {
    final idCaso = (casoDetalhe.value?['id'] ?? '').toString();
    if (idCaso.isEmpty || enviando.value) return false;
    enviando.value = true;
    try {
      final r = await remote.fecharCaso(idCaso: idCaso, conclusao: conclusao);
      aviso.value = (r['aviso'] ?? '').toString();
      // Domínio: fechar ≠ efeito financeiro.
      assert(dominio.efeitosFinanceirosAoFechar().isEmpty);
      if (idOrcamentoSelecionado.value.isNotEmpty) {
        await abrirDetalhe(idOrcamentoSelecionado.value);
      }
      return true;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      enviando.value = false;
    }
  }

  Future<bool> recomendarBloqueio(String motivo) async {
    final idCaso = (casoDetalhe.value?['id'] ?? '').toString();
    if (idCaso.isEmpty || enviando.value) return false;
    enviando.value = true;
    try {
      final r =
          await remote.recomendarBloqueio(idCaso: idCaso, motivo: motivo);
      aviso.value = (r['aviso'] ?? '').toString();
      await carregarCaso(idCaso);
      return true;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      enviando.value = false;
    }
  }

  void limparDetalheMantendoFiltros() {
    detalhe.value = null;
    casoDetalhe.value = null;
    registrosCaso.clear();
    idOrcamentoSelecionado.value = '';
  }
}
