import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:app_faca_festa/domain/entities/auditoria_catalogo.dart';
import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_auditoria.dart';

part 'auditoria_controller_helpers.dart';
part 'auditoria_controller_filtros.dart';
part 'auditoria_controller_indicadores.dart';
part 'auditoria_controller_export.dart';

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
  final atorFiltro = ''.obs;
  final entidadeFiltro = ''.obs;
  final vinculoFiltro = ''.obs;
  final areaFiltro = ''.obs;
  final acaoFiltro = ''.obs;
  final origemFiltro = ''.obs;
  final nivelFiltro = ''.obs;
  final periodoFiltro = ''.obs;
  final apenasCriticos = false.obs;
  final dashboardExpandido = false.obs;
  final limite = 150.obs;
  final carregando = false.obs;
  final carregandoMais = false.obs;
  final temMais = false.obs;
  final erro = ''.obs;
  DateTime? _proximoCursorCriadoEm;

  Future<void> carregar() async {
    try {
      carregando.value = true;
      temMais.value = false;
      _proximoCursorCriadoEm = null;
      erro.value = '';
      final pagina = await _gerenciarAuditoria.listarPagina(
        _consulta(incluirSnapshots: true),
      );
      eventos.value = pagina.eventos;
      temMais.value = pagina.temMais;
      _proximoCursorCriadoEm = pagina.proximoCursorCriadoEm;
    } catch (e) {
      erro.value = 'Não foi possível carregar o histórico de auditoria.';
    } finally {
      carregando.value = false;
    }
  }

  Future<void> carregarMais() async {
    if (carregando.value || carregandoMais.value || !temMais.value) return;
    final cursor = _proximoCursorCriadoEm;
    if (cursor == null) {
      temMais.value = false;
      return;
    }

    try {
      carregandoMais.value = true;
      erro.value = '';
      final pagina = await _gerenciarAuditoria.listarPagina(
        _consulta(cursor: cursor, incluirSnapshots: false),
      );
      final idsAtuais = eventos.map((e) => e.id).toSet();
      eventos.addAll(pagina.eventos.where((e) => !idsAtuais.contains(e.id)));
      temMais.value = pagina.temMais;
      _proximoCursorCriadoEm = pagina.proximoCursorCriadoEm;
    } catch (e) {
      erro.value = 'Não foi possível carregar mais eventos de auditoria.';
    } finally {
      carregandoMais.value = false;
    }
  }

  Future<void> limparFiltros() async {
    busca.value = '';
    atorFiltro.value = '';
    entidadeFiltro.value = '';
    vinculoFiltro.value = '';
    areaFiltro.value = '';
    acaoFiltro.value = '';
    origemFiltro.value = '';
    nivelFiltro.value = '';
    periodoFiltro.value = '';
    apenasCriticos.value = false;
    await carregar();
  }

  void alternarApenasCriticos(bool value) {
    apenasCriticos.value = value;
  }

  void alternarDashboard() {
    dashboardExpandido.value = !dashboardExpandido.value;
  }

  Future<void> alterarLimite(int novoLimite) async {
    if (limite.value == novoLimite) return;
    limite.value = novoLimite;
    await carregar();
  }

  Future<void> alterarPeriodo(String periodo) async {
    if (periodoFiltro.value == periodo) return;
    periodoFiltro.value = periodo;
    await carregar();
  }

  AuditoriaConsulta _consulta({
    DateTime? cursor,
    required bool incluirSnapshots,
  }) {
    final intervalo = _intervaloPeriodo(periodoFiltro.value);
    final filtrosServidor = _filtrosServidorAdministrativos();
    return AuditoriaConsulta(
      escopoAdmin: escopoAdmin,
      idFornecedor: idFornecedor,
      area: filtrosServidor.area,
      acao: filtrosServidor.acao,
      origem: filtrosServidor.origem,
      nivel: filtrosServidor.nivel,
      criadoDe: intervalo?.inicio,
      criadoAte: intervalo?.fim,
      cursorCriadoEm: cursor,
      incluirSnapshots: incluirSnapshots,
      limite: limite.value,
    );
  }

  _AuditoriaFiltrosServidor _filtrosServidorAdministrativos() {
    if (!escopoAdmin) return const _AuditoriaFiltrosServidor();

    final filtros = <String, String>{
      if (areaFiltro.value.isNotEmpty) 'area': areaFiltro.value,
      if (acaoFiltro.value.isNotEmpty) 'acao': acaoFiltro.value,
      if (origemFiltro.value.isNotEmpty) 'origem': origemFiltro.value,
      if (nivelFiltro.value.isNotEmpty) 'nivel': nivelFiltro.value,
    };

    if (filtros.length != 1) return const _AuditoriaFiltrosServidor();

    return _AuditoriaFiltrosServidor(
      area: filtros['area'],
      acao: filtros['acao'],
      origem: filtros['origem'],
      nivel: filtros['nivel'],
    );
  }
}
