part of 'auditoria_controller.dart';

extension AuditoriaIndicadores on AuditoriaController {
  int get totalEventos => eventos.length;
  int get totalVisiveis => visiveis.length;
  int get totalHoje => eventos.where((e) => e.ocorreuHoje).length;
  int get totalUltimas24h => eventos.where((e) {
        final data = e.criadoEm;
        if (data == null) return false;
        return data.isAfter(DateTime.now().subtract(const Duration(hours: 24)));
      }).length;
  int get totalUltimos7d => eventos.where((e) {
        final data = e.criadoEm;
        if (data == null) return false;
        return data.isAfter(DateTime.now().subtract(const Duration(days: 7)));
      }).length;
  int get totalUltimos15d => eventos.where((e) {
        final data = e.criadoEm;
        if (data == null) return false;
        return data.isAfter(DateTime.now().subtract(const Duration(days: 15)));
      }).length;
  int get totalUltimos30d => eventos.where((e) {
        final data = e.criadoEm;
        if (data == null) return false;
        return data.isAfter(DateTime.now().subtract(const Duration(days: 30)));
      }).length;
  int get totalAuditados =>
      eventos.where((e) => _origemEvento(e) == 'audit').length;
  int get totalSnapshots =>
      eventos.where((e) => _origemEvento(e) == 'snapshot').length;
  int get totalCriticos => eventos.where(_ehCritico).length;
  int get totalAlertas => eventos.where((e) => e.nivel == 'WARN').length;
  int get totalFalhasAcesso =>
      eventos.where((e) => e.acao == 'LOGIN_FALHOU').length;
  int get totalAlteracoesAdministrativas =>
      eventos.where(_ehAlteracaoAdministrativa).length;
  int get totalFornecedoresAprovados =>
      eventos.where((e) => e.acao == 'FORNECEDOR_APROVADO').length;
  int get totalFornecedoresComAtencao =>
      eventos.where(_ehMovimentoFornecedorComAtencao).length;
  int get totalFluxoComercial =>
      eventos.where((e) => e.area == 'COTACAO' || e.area == 'ORCAMENTO').length;
  int get totalEventosComDiff =>
      eventos.where((e) => e.mudancas.isNotEmpty).length;
  int get totalAuditadosSemHash => eventos.where((e) {
        if (_origemEvento(e) == 'snapshot') return false;
        return (e.hashIntegridade ?? '').trim().isEmpty;
      }).length;
  double get coberturaAuditoria {
    if (eventos.isEmpty) return 0;
    return totalAuditados / eventos.length;
  }

  List<MapEntry<String, int>> get distribuicaoPorArea {
    final contagem = <String, int>{};
    for (final evento in eventos) {
      final label = areasAuditoriaLabels[evento.area] ?? evento.area;
      contagem[label] = (contagem[label] ?? 0) + 1;
    }
    final entradas = contagem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entradas;
  }

  List<MapEntry<String, int>> get distribuicaoPorNivel {
    final contagem = <String, int>{};
    for (final evento in eventos) {
      final label = _labelNivel(evento.nivel);
      contagem[label] = (contagem[label] ?? 0) + 1;
    }
    final entradas = contagem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entradas;
  }

  List<MapEntry<String, int>> get distribuicaoPorOrigem {
    final contagem = <String, int>{};
    for (final evento in eventos) {
      final label = _labelOrigem(evento);
      contagem[label] = (contagem[label] ?? 0) + 1;
    }
    final entradas = contagem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entradas;
  }

  List<MapEntry<String, int>> get principaisAcoes {
    final contagem = <String, int>{};
    for (final evento in eventos) {
      final label = infoAcaoAuditoria(evento.acao).titulo;
      contagem[label] = (contagem[label] ?? 0) + 1;
    }
    final entradas = contagem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entradas.take(8).toList();
  }

  List<MapEntry<String, int>> get principaisAtores {
    final contagem = <String, int>{};
    for (final evento in eventos) {
      final ator = _labelAtorPainel(evento);
      if (ator.isEmpty) continue;
      contagem[ator] = (contagem[ator] ?? 0) + 1;
    }
    final entradas = contagem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entradas.take(5).toList();
  }

  List<MapEntry<String, int>> get atividadeUltimos7Dias {
    return _atividadeUltimosDias(7);
  }

  List<MapEntry<String, int>> get atividadeUltimos15Dias {
    return _atividadeUltimosDias(15);
  }

  List<MapEntry<String, int>> _atividadeUltimosDias(int totalDias) {
    final hoje = DateTime.now();
    final dias = <String, int>{};
    for (var offset = totalDias - 1; offset >= 0; offset--) {
      final dia = DateTime(hoje.year, hoje.month, hoje.day)
          .subtract(Duration(days: offset));
      dias[_chaveDia(dia)] = 0;
    }

    for (final evento in eventos) {
      final data = evento.criadoEm;
      if (data == null) continue;
      final chave = _chaveDia(data);
      if (!dias.containsKey(chave)) continue;
      dias[chave] = (dias[chave] ?? 0) + 1;
    }

    return dias.entries.toList();
  }
}
