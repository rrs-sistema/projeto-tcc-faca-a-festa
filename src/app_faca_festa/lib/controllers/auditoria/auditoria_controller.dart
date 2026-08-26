import 'package:get/get.dart';

import '../../data/models/auditoria/auditoria_catalogo.dart';
import '../../domain/entities/auditoria_evento.dart';
import '../../domain/usecases/gerenciar_auditoria.dart';

class AuditoriaController extends GetxController {
  AuditoriaController({
    required GerenciarAuditoria gerenciarAuditoria,
    required this.escopoAdmin,
    this.idFornecedor,
  }) : _gerenciarAuditoria = gerenciarAuditoria;

  final GerenciarAuditoria _gerenciarAuditoria;
  final bool escopoAdmin;
  final String? idFornecedor;

  final eventos = <AuditoriaEvento>[].obs;
  final busca = ''.obs;
  final areaFiltro = ''.obs;
  final acaoFiltro = ''.obs;
  final limite = 150.obs;
  final carregando = false.obs;
  final erro = ''.obs;

  List<AuditoriaEvento> get visiveis {
    final termo = busca.value.trim().toLowerCase();
    final area = areaFiltro.value;
    final acao = acaoFiltro.value;

    return eventos.where((evento) {
      if (area.isNotEmpty && evento.area != area) return false;
      if (acao.isNotEmpty && evento.acao != acao) return false;
      if (termo.isEmpty) return true;
      final info = infoAcaoAuditoria(evento.acao);
      final blob = [
        info.titulo,
        evento.resumo,
        evento.entidadeNome ?? '',
        evento.atorNome ?? '',
        evento.atorEmail ?? '',
        evento.acao,
        evento.area,
      ].join(' ').toLowerCase();
      return blob.contains(termo);
    }).toList();
  }

  int get totalEventos => eventos.length;
  int get totalVisiveis => visiveis.length;
  int get totalHoje => eventos.where((e) => e.ocorreuHoje).length;

  List<MapEntry<String, String>> get areasDisponiveis {
    final usadas = eventos.map((e) => e.area).toSet();
    final entradas = <MapEntry<String, String>>[];
    for (final area in usadas) {
      entradas.add(MapEntry(area, areasAuditoriaLabels[area] ?? area));
    }
    entradas.sort((a, b) => a.value.compareTo(b.value));
    return entradas;
  }

  List<MapEntry<String, String>> get acoesDisponiveis {
    final usadas = eventos.map((e) => e.acao).toSet();
    final entradas = <MapEntry<String, String>>[];
    for (final acao in usadas) {
      entradas.add(MapEntry(acao, infoAcaoAuditoria(acao).titulo));
    }
    entradas.sort((a, b) => a.value.compareTo(b.value));
    return entradas;
  }

  Future<void> carregar() async {
    try {
      carregando.value = true;
      erro.value = '';
      eventos.value = await _gerenciarAuditoria.listar(
        AuditoriaConsulta(
          escopoAdmin: escopoAdmin,
          idFornecedor: idFornecedor,
          limite: limite.value,
        ),
      );
    } catch (e) {
      erro.value = 'Não foi possível carregar o histórico de auditoria.';
    } finally {
      carregando.value = false;
    }
  }

  void limparFiltros() {
    busca.value = '';
    areaFiltro.value = '';
    acaoFiltro.value = '';
  }

  Future<void> alterarLimite(int novoLimite) async {
    if (limite.value == novoLimite) return;
    limite.value = novoLimite;
    await carregar();
  }
}
