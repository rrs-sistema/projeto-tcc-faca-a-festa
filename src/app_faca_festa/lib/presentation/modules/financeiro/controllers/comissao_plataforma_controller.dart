import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/comissao_plataforma_remote_datasource.dart';
import 'package:app_faca_festa/domain/entities/financeiro/comissao_plataforma.dart';
import 'package:app_faca_festa/domain/services/comissao_plataforma_service.dart';

class ComissaoPlataformaController extends GetxController {
  ComissaoPlataformaController({
    required this.remote,
    String? Function()? usuarioAtual,
    bool Function()? ehAdmin,
  })  : _ehAdmin = ehAdmin,
        _usuarioAtual = usuarioAtual;

  final ComissaoPlataformaRemoteDatasource remote;
  final bool Function()? _ehAdmin;
  final String? Function()? _usuarioAtual;

  final carregando = false.obs;
  final enviando = false.obs;
  final erro = ''.obs;
  final politicas = <Map<String, dynamic>>[].obs;
  final obrigacoes = <Map<String, dynamic>>[].obs;
  final simulacaoTexto = ''.obs;
  final simulacaoValorCentavos = 0.obs;
  final simulacaoBaseCentavos = 0.obs;
  final simulacaoBps = 0.obs;
  final filtroEvento = ''.obs;

  int _geracao = 0;

  bool get isAdmin => _ehAdmin?.call() == true;

  /// Totais de apresentação a partir das cobranças carregadas (não recalcula domínio).
  int get totalGeradoCentavos {
    var t = 0;
    for (final o in obrigacoes) {
      t += _valorOriginalCentavos(o);
    }
    return t;
  }

  int get totalRecebidoCentavos {
    var t = 0;
    for (final o in obrigacoes) {
      t += _valorLiquidadoCentavos(o);
    }
    return t;
  }

  int get totalAReceberCentavos {
    var t = 0;
    for (final o in obrigacoes) {
      t += _saldoCentavos(o);
    }
    return t;
  }

  /// Só conta status `vencida` explícito (não inventa atraso).
  int get qtdVencidas {
    var n = 0;
    for (final o in obrigacoes) {
      if ((o['status'] ?? '').toString().toLowerCase() == 'vencida') n++;
    }
    return n;
  }

  /// Percentual da política aplicada à obrigação (snapshot), em bps.
  static int? percentualBpsAplicadoDe(Map<String, dynamic> o) {
    final snap = o['politica_aplicada'] ?? o['politicaAplicada'];
    if (snap is Map) {
      final bps = snap['percentual_bps'] ?? snap['percentualBps'];
      if (bps is num) return bps.toInt();
    }
    final direto = o['percentual_bps'] ?? o['percentualBps'];
    if (direto is num) return direto.toInt();
    return null;
  }

  static int? baseElegivelCentavosDe(Map<String, dynamic> o) {
    final v = o['base_elegivel'] ??
        o['baseElegivel'] ??
        o['base_elegivel_centavos'] ??
        o['baseElegivelCentavos'];
    if (v == null) return null;
    return _lerCentavos(v);
  }

  static int valorOriginalDe(Map<String, dynamic> o) =>
      _valorOriginalCentavos(o);
  static int valorLiquidadoDe(Map<String, dynamic> o) =>
      _valorLiquidadoCentavos(o);
  static int saldoDe(Map<String, dynamic> o) => _saldoCentavos(o);

  static int _valorOriginalCentavos(Map<String, dynamic> o) {
    final v = o['valor_original_centavos'] ??
        o['valorOriginalCentavos'] ??
        o['valor_original'];
    return _lerCentavos(v);
  }

  static int _valorLiquidadoCentavos(Map<String, dynamic> o) {
    final v = o['valor_liquidado_centavos'] ??
        o['valorLiquidadoCentavos'] ??
        o['valor_liquidado'];
    return _lerCentavos(v);
  }

  static int _saldoCentavos(Map<String, dynamic> o) {
    final explicito = o['saldo_centavos'] ?? o['saldoCentavos'];
    if (explicito != null) return _lerCentavos(explicito);
    final ajustes =
        _lerCentavos(o['valor_ajustes_centavos'] ?? o['valorAjustesCentavos']);
    return _valorOriginalCentavos(o) + ajustes - _valorLiquidadoCentavos(o);
  }

  static int _lerCentavos(dynamic v) {
    if (v is Map && v['centavos'] is num) return (v['centavos'] as num).toInt();
    if (v is num && v.isFinite) return v.round();
    return 0;
  }

  @override
  void onClose() {
    _geracao++;
    super.onClose();
  }

  void aoTrocarSessao() => _geracao++;

  Future<void> carregar() async {
    final geracao = ++_geracao;
    final uid = _usuarioAtual?.call();
    erro.value = '';
    carregando.value = true;
    try {
      final res = await remote.consultarExtrato(
        idEvento: filtroEvento.value.isEmpty ? null : filtroEvento.value,
        idPagador: isAdmin ? null : uid,
        ehAdmin: isAdmin,
      );
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
      final obr = res['obrigacoes'];
      final pol = res['politicas'];
      obrigacoes.assignAll(
        obr is List
            ? obr.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [],
      );
      politicas.assignAll(
        pol is List
            ? pol.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [],
      );
      if (res['origem'] == 'fallback_local') {
        erro.value = '';
      }
    } catch (e) {
      if (geracao != _geracao) return;
      erro.value = e.toString();
    } finally {
      if (geracao == _geracao) carregando.value = false;
    }
  }

  /// Simulação local (não altera financeiro) + eco remoto se admin.
  void simularLocal({required int percentualBps, required int baseCentavos}) {
    final politica = PoliticaComissaoPlataforma(
      id: 'sim',
      versao: 0,
      percentualBps: percentualBps,
      baseElegivel: BaseElegivelComissao.servicosContratadosPlataforma,
      pagador: PagadorComissao.fornecedor,
      gatilho: GatilhoGeracaoComissao.contratacaoConfirmada,
      reversao: ReversaoComissao.proporcional,
      ativa: true,
    );
    final r = ComissaoPlataformaService.simular(
      politica: politica,
      baseBrutaCentavos: baseCentavos,
    );
    simulacaoValorCentavos.value = r.valorCentavos;
    simulacaoBaseCentavos.value = r.baseLiquidaCentavos;
    simulacaoBps.value = percentualBps;
    simulacaoTexto.value =
        'Hipótese: R\$ ${(r.valorCentavos / 100).toStringAsFixed(2)} '
        'sobre base R\$ ${(r.baseLiquidaCentavos / 100).toStringAsFixed(2)} '
        '(${(percentualBps / 100).toStringAsFixed(2)}%).';
  }

  Future<bool> salvarPoliticaInativa({required int percentualBps}) async {
    if (!isAdmin) {
      erro.value = 'Somente administrador configura política.';
      return false;
    }
    if (enviando.value) return false;
    enviando.value = true;
    erro.value = '';
    try {
      await remote.salvarPolitica(percentualBps: percentualBps, ativa: false);
      // carregar() incrementa _geracao — não amarrar enviando a essa geração.
      await carregar();
      return erro.value.isEmpty;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      enviando.value = false;
    }
  }

  Future<bool> ativar(String id) async {
    if (!isAdmin) {
      erro.value = 'Somente administrador ativa política.';
      return false;
    }
    final idLimpo = id.trim();
    if (idLimpo.isEmpty) {
      erro.value = 'Política sem identificador — atualize o extrato e tente de novo.';
      return false;
    }
    if (enviando.value) return false;
    enviando.value = true;
    erro.value = '';
    try {
      await remote.ativarPolitica(idLimpo);
      await carregar();
      return erro.value.isEmpty;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      enviando.value = false;
    }
  }

  Future<Map<String, dynamic>?> liquidar({
    required String idObrigacao,
    required int valorCentavos,
  }) async {
    if (!isAdmin) {
      erro.value = 'Somente administrador liquida (registro manual).';
      return null;
    }
    if (enviando.value) return null;
    enviando.value = true;
    erro.value = '';
    try {
      final res = await remote.liquidarManual(
        idObrigacao: idObrigacao,
        valorCentavos: valorCentavos,
        motivo: 'Liquidação manual — sem confirmação bancária',
      );
      await carregar();
      if (erro.value.isNotEmpty) return null;
      return res;
    } catch (e) {
      erro.value = e.toString();
      return null;
    } finally {
      enviando.value = false;
    }
  }
}
