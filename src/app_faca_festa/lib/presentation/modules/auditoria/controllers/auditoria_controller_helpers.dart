part of 'auditoria_controller.dart';

String _csv(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}

String _atorCsv(AuditoriaEvento evento) {
  return [
    evento.atorNome,
    evento.atorEmail,
    evento.atorUid,
    evento.atorTipo,
  ].where((e) => (e ?? '').trim().isNotEmpty).join(' | ');
}

String _curto(String? value, [int max = 16]) {
  final texto = (value ?? '').trim();
  if (texto.isEmpty) return '-';
  if (texto.length <= max) return texto;
  return '${texto.substring(0, max)}...';
}

_AuditoriaIntervalo? _intervaloPeriodo(String periodo) {
  final agora = DateTime.now();
  switch (periodo) {
    case '24h':
      return _AuditoriaIntervalo(
          agora.subtract(const Duration(hours: 24)), agora);
    case '7d':
      return _AuditoriaIntervalo(
          agora.subtract(const Duration(days: 7)), agora);
    case '30d':
      return _AuditoriaIntervalo(
          agora.subtract(const Duration(days: 30)), agora);
    case '90d':
      return _AuditoriaIntervalo(
          agora.subtract(const Duration(days: 90)), agora);
    default:
      return null;
  }
}

bool _ocorreuNoIntervalo(
  AuditoriaEvento evento,
  _AuditoriaIntervalo? intervalo,
) {
  if (intervalo == null) return true;
  final data = evento.criadoEm;
  if (data == null) return false;
  return !data.isBefore(intervalo.inicio) && !data.isAfter(intervalo.fim);
}

String _origemEvento(AuditoriaEvento evento) {
  final origem = (evento.origem ?? '').trim();
  if (origem == 'snapshot') return 'snapshot';
  return 'audit';
}

String _labelOrigem(AuditoriaEvento evento) {
  return _labelOrigemCodigo(_origemEvento(evento));
}

String _labelOrigemCodigo(String origem) {
  switch (origem) {
    case 'snapshot':
      return 'Registro do sistema';
    default:
      return 'Evento auditado';
  }
}

String _labelNivel(String nivel) {
  switch (nivel) {
    case 'CRITICAL':
      return 'Crítico';
    case 'ERROR':
      return 'Erro';
    case 'WARN':
      return 'Atenção';
    case 'INFO':
      return 'Informativo';
    default:
      return nivel;
  }
}

String _labelArea(String area) {
  return areasAuditoriaLabels[area] ?? area;
}

String _labelPeriodo(String periodo) {
  switch (periodo) {
    case '24h':
      return 'Últimas 24h';
    case '7d':
      return 'Últimos 7 dias';
    case '30d':
      return 'Últimos 30 dias';
    case '90d':
      return 'Últimos 90 dias';
    default:
      return 'Todo o histórico';
  }
}

bool _ehCritico(AuditoriaEvento evento) {
  return evento.nivel == 'CRITICAL' || evento.nivel == 'ERROR';
}

bool _ehAlteracaoAdministrativa(AuditoriaEvento evento) {
  if (evento.atorTipo == 'A') return true;
  if (evento.area == 'USUARIO') return true;
  return const {
    'FORNECEDOR_APROVADO',
    'FORNECEDOR_REPROVADO',
    'FORNECEDOR_ATIVADO',
    'FORNECEDOR_DESATIVADO',
    'SERVICO_CATALOGO_CRIADO',
    'SERVICO_CATALOGO_ATUALIZADO',
    'SERVICO_CATALOGO_EXCLUIDO',
    'CATEGORIA_CRIADA',
    'CATEGORIA_ATUALIZADA',
    'CATEGORIA_EXCLUIDA',
    'SUBCATEGORIA_CRIADA',
    'SUBCATEGORIA_ATUALIZADA',
    'SUBCATEGORIA_EXCLUIDA',
  }.contains(evento.acao);
}

bool _ehMovimentoFornecedorComAtencao(AuditoriaEvento evento) {
  return const {
    'FORNECEDOR_REPROVADO',
    'FORNECEDOR_DESATIVADO',
    'FORNECEDOR_EXCLUIDO',
  }.contains(evento.acao);
}

String _labelAtorPainel(AuditoriaEvento evento) {
  final nome = (evento.atorNome ?? '').trim();
  if (nome.isNotEmpty) return nome;
  final email = (evento.atorEmail ?? '').trim();
  if (email.isNotEmpty) return email;
  final uid = (evento.atorUid ?? '').trim();
  if (uid.isNotEmpty) return uid;
  return evento.atorTipo == 'S' ? 'Sistema' : '';
}

String _chaveDia(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes';
}

bool _contemAtor(AuditoriaEvento evento, String termo) {
  return _blob([
    evento.atorUid,
    evento.atorNome,
    evento.atorEmail,
    evento.atorTipo,
    evento.atorAuthType,
  ]).contains(termo);
}

bool _contemEntidade(AuditoriaEvento evento, String termo) {
  return _blob([
    evento.entidadeTipo,
    evento.entidadeId,
    evento.entidadeNome,
    evento.documentPath,
    evento.sourceEventId,
    evento.operacao,
  ]).contains(termo);
}

bool _contemVinculo(AuditoriaEvento evento, String termo) {
  return _blob([
    evento.idFornecedor,
    evento.idEvento,
    evento.idServico,
    evento.idCotacao,
    evento.idOrcamento,
    evento.rota,
    evento.plataforma,
  ]).contains(termo);
}

String _blob(Iterable<String?> valores) {
  return valores
      .where((v) => (v ?? '').trim().isNotEmpty)
      .join(' ')
      .toLowerCase();
}

class _AuditoriaIntervalo {
  const _AuditoriaIntervalo(this.inicio, this.fim);

  final DateTime inicio;
  final DateTime fim;
}

class _AuditoriaFiltrosServidor {
  const _AuditoriaFiltrosServidor({
    this.area,
    this.acao,
    this.origem,
    this.nivel,
  });

  final String? area;
  final String? acao;
  final String? origem;
  final String? nivel;
}
