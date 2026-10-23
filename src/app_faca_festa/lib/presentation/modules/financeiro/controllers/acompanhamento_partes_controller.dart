import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/acompanhamento_partes_remote.dart';
import 'package:app_faca_festa/domain/services/acompanhamento_partes_service.dart';

class AcompanhamentoPartesController extends GetxController {
  AcompanhamentoPartesController({
    required this.remote,
    AcompanhamentoPartesService? dominio,
  }) : dominio = dominio ?? const AcompanhamentoPartesService();

  final AcompanhamentoPartesRemote remote;
  final AcompanhamentoPartesService dominio;

  final carregando = false.obs;
  final enviando = false.obs;
  final erro = ''.obs;
  final aviso = ''.obs;
  final linhasOrg = <VisaoOrganizadorContrato>[].obs;
  final linhasForn = <VisaoFornecedorContrato>[].obs;
  final acoesBloqueadas = <String>[].obs;
  final idEvento = ''.obs;
  final idFornecedor = ''.obs;

  int _geracao = 0;

  Future<void> carregarOrganizador(String eventoId) async {
    final g = ++_geracao;
    idEvento.value = eventoId;
    carregando.value = true;
    erro.value = '';
    try {
      final r = await remote.consultarOrganizador(idEvento: eventoId);
      if (g != _geracao) return;
      final raw = r['linhas'];
      final lista = <VisaoOrganizadorContrato>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            lista.add(VisaoOrganizadorContrato.fromMap(
              Map<String, dynamic>.from(item),
            ));
          }
        }
      }
      linhasOrg.assignAll(lista);
      _lerAcoes(r);
      aviso.value = (r['aviso_integracao'] ?? r['aviso'] ?? '').toString();
    } catch (e) {
      if (g != _geracao) return;
      erro.value = e.toString();
      linhasOrg.clear();
    } finally {
      if (g == _geracao) carregando.value = false;
    }
  }

  Future<void> carregarFornecedor(String fornId) async {
    final g = ++_geracao;
    idFornecedor.value = fornId;
    carregando.value = true;
    erro.value = '';
    try {
      final r = await remote.consultarFornecedor(idFornecedor: fornId);
      if (g != _geracao) return;
      final raw = r['linhas'];
      final lista = <VisaoFornecedorContrato>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            lista.add(VisaoFornecedorContrato.fromMap(
              Map<String, dynamic>.from(item),
            ));
          }
        }
      }
      linhasForn.assignAll(lista);
      _lerAcoes(r);
      aviso.value = [
        (r['aviso'] ?? '').toString(),
        (r['aviso_integracao'] ?? '').toString(),
      ].where((s) => s.isNotEmpty).join(' ');
    } catch (e) {
      if (g != _geracao) return;
      erro.value = e.toString();
      linhasForn.clear();
    } finally {
      if (g == _geracao) carregando.value = false;
    }
  }

  void _lerAcoes(Map<String, dynamic> r) {
    final b = r['acoes_bloqueadas'];
    if (b is List) {
      acoesBloqueadas.assignAll(b.map((e) => e.toString()));
    } else {
      acoesBloqueadas.assignAll(AcompanhamentoPartesService.ctasIntegracaoAusente);
    }
  }

  Future<bool> declararPagamento({
    required String idOrcamento,
    required int valorCentavos,
    String? comprovante,
  }) async {
    if (enviando.value || idEvento.value.isEmpty) return false;
    enviando.value = true;
    try {
      final r = await remote.declararPagamento(
        idEvento: idEvento.value,
        idOrcamento: idOrcamento,
        valorCentavos: valorCentavos,
        chaveIdempotencia:
            'decl-$idOrcamento-${DateTime.now().millisecondsSinceEpoch}',
        referenciaComprovante: comprovante,
      );
      aviso.value = (r['aviso'] ?? '').toString();
      await carregarOrganizador(idEvento.value);
      return true;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      enviando.value = false;
    }
  }

  Future<bool> informarEntrega(String idOrcamento) async {
    if (enviando.value) return false;
    enviando.value = true;
    try {
      final r = await remote.informarEntrega(
        idOrcamento: idOrcamento,
        chaveIdempotencia:
            'ent-$idOrcamento-${DateTime.now().millisecondsSinceEpoch}',
      );
      aviso.value = (r['aviso'] ?? '').toString();
      if (idFornecedor.value.isNotEmpty) {
        await carregarFornecedor(idFornecedor.value);
      }
      return true;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      enviando.value = false;
    }
  }

  Future<bool> aceitarOuContestar(
    String idOrcamento, {
    required bool contestar,
    String? motivo,
  }) async {
    if (enviando.value) return false;
    enviando.value = true;
    try {
      final r = await remote.registrarAceite(
        idOrcamento: idOrcamento,
        chaveIdempotencia:
            'ace-$idOrcamento-${DateTime.now().millisecondsSinceEpoch}',
        contestar: contestar,
        motivo: motivo,
      );
      aviso.value = (r['aviso'] ?? '').toString();
      if (idEvento.value.isNotEmpty) {
        await carregarOrganizador(idEvento.value);
      }
      return true;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      enviando.value = false;
    }
  }

  Future<bool> abrirCaso(
    String idOrcamento,
    String motivo, {
    String? descricao,
  }) async {
    if (enviando.value) return false;
    final motivoLimpo = motivo.trim();
    if (motivoLimpo.isEmpty) {
      erro.value = 'Informe o motivo da mediação.';
      return false;
    }
    enviando.value = true;
    erro.value = '';
    try {
      await remote.abrirCasoParte(
        idOrcamento: idOrcamento,
        motivo: motivoLimpo,
        descricao: descricao?.trim().isEmpty == true ? null : descricao?.trim(),
        chaveIdempotencia:
            'caso-p-$idOrcamento-${DateTime.now().millisecondsSinceEpoch}',
      );
      aviso.value =
          'Caso de mediação aberto. A equipe analisa em seguida. '
          'Notas internas permanecem privadas.';
      if (idEvento.value.isNotEmpty) {
        await carregarOrganizador(idEvento.value);
      } else if (idFornecedor.value.isNotEmpty) {
        await carregarFornecedor(idFornecedor.value);
      }
      return true;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('failed-precondition') ||
          msg.toLowerCase().contains('já existe') ||
          msg.toLowerCase().contains('ja existe') ||
          msg.toLowerCase().contains('caso aberto')) {
        erro.value =
            'Já existe um caso de mediação aberto para este contrato.';
      } else {
        erro.value = 'Não foi possível abrir a mediação. Tente de novo.';
      }
      return false;
    } finally {
      enviando.value = false;
    }
  }

  void aoTrocarSessao() {
    _geracao++;
    linhasOrg.clear();
    linhasForn.clear();
    erro.value = '';
    aviso.value = '';
    idEvento.value = '';
    idFornecedor.value = '';
  }
}
