part of 'auditoria_controller.dart';

extension AuditoriaFiltros on AuditoriaController {
  List<AuditoriaEvento> get visiveis {
    final termo = busca.value.trim().toLowerCase();
    final ator = atorFiltro.value.trim().toLowerCase();
    final entidade = entidadeFiltro.value.trim().toLowerCase();
    final vinculo = vinculoFiltro.value.trim().toLowerCase();
    final area = areaFiltro.value;
    final acao = acaoFiltro.value;
    final origem = origemFiltro.value;
    final nivel = nivelFiltro.value;
    final intervalo = _intervaloPeriodo(periodoFiltro.value);

    return eventos.where((evento) {
      if (area.isNotEmpty && evento.area != area) return false;
      if (acao.isNotEmpty && evento.acao != acao) return false;
      if (origem.isNotEmpty && _origemEvento(evento) != origem) return false;
      if (nivel.isNotEmpty && evento.nivel != nivel) return false;
      if (apenasCriticos.value && !_ehCritico(evento)) return false;
      if (!_ocorreuNoIntervalo(evento, intervalo)) return false;
      if (ator.isNotEmpty && !_contemAtor(evento, ator)) return false;
      if (entidade.isNotEmpty && !_contemEntidade(evento, entidade)) {
        return false;
      }
      if (vinculo.isNotEmpty && !_contemVinculo(evento, vinculo)) {
        return false;
      }
      if (termo.isEmpty) return true;
      final info = infoAcaoAuditoria(evento.acao);
      final blob = [
        info.titulo,
        evento.resumo,
        evento.entidadeNome ?? '',
        evento.entidadeTipo ?? '',
        evento.entidadeId ?? '',
        evento.idFornecedor ?? '',
        evento.idEvento ?? '',
        evento.idServico ?? '',
        evento.idCotacao ?? '',
        evento.idOrcamento ?? '',
        evento.atorUid ?? '',
        evento.atorNome ?? '',
        evento.atorEmail ?? '',
        evento.atorTipo ?? '',
        evento.atorAuthType ?? '',
        evento.acao,
        evento.area,
        evento.nivel,
        evento.origem ?? '',
        evento.operacao ?? '',
        evento.documentPath ?? '',
        evento.sourceEventId ?? '',
        evento.algoritmoHash ?? '',
        evento.hashIntegridade ?? '',
        evento.rota ?? '',
        evento.plataforma ?? '',
        _labelOrigem(evento),
      ].join(' ').toLowerCase();
      return blob.contains(termo);
    }).toList();
  }

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

  List<MapEntry<String, String>> get origensDisponiveis {
    final usadas = eventos.map(_origemEvento).toSet();
    final entradas = <MapEntry<String, String>>[];
    for (final origem in usadas) {
      entradas.add(MapEntry(origem, _labelOrigemCodigo(origem)));
    }
    entradas.sort((a, b) => a.value.compareTo(b.value));
    return entradas;
  }

  List<MapEntry<String, String>> get niveisDisponiveis {
    final usadas =
        eventos.map((e) => e.nivel).where((e) => e.isNotEmpty).toSet();
    final entradas = <MapEntry<String, String>>[];
    for (final nivel in usadas) {
      entradas.add(MapEntry(nivel, _labelNivel(nivel)));
    }
    entradas.sort((a, b) => a.value.compareTo(b.value));
    return entradas;
  }

  List<MapEntry<String, String>> get periodosDisponiveis {
    return const [
      MapEntry('24h', 'Últimas 24h'),
      MapEntry('7d', 'Últimos 7 dias'),
      MapEntry('30d', 'Últimos 30 dias'),
      MapEntry('90d', 'Últimos 90 dias'),
      MapEntry('', 'Todo o histórico'),
    ];
  }

  String get resumoFiltrosAplicados {
    final filtros = <String>[];
    if (busca.value.trim().isNotEmpty) {
      filtros.add('busca: ${busca.value.trim()}');
    }
    if (atorFiltro.value.trim().isNotEmpty) {
      filtros.add('ator: ${atorFiltro.value.trim()}');
    }
    if (entidadeFiltro.value.trim().isNotEmpty) {
      filtros.add('entidade: ${entidadeFiltro.value.trim()}');
    }
    if (vinculoFiltro.value.trim().isNotEmpty) {
      filtros.add('vínculo: ${vinculoFiltro.value.trim()}');
    }
    if (areaFiltro.value.isNotEmpty) {
      filtros.add('área: ${_labelArea(areaFiltro.value)}');
    }
    if (acaoFiltro.value.isNotEmpty) {
      filtros.add('ação: ${infoAcaoAuditoria(acaoFiltro.value).titulo}');
    }
    if (origemFiltro.value.isNotEmpty) {
      filtros.add('origem: ${_labelOrigemCodigo(origemFiltro.value)}');
    }
    if (nivelFiltro.value.isNotEmpty) {
      filtros.add('severidade: ${_labelNivel(nivelFiltro.value)}');
    }
    if (periodoFiltro.value.isNotEmpty) {
      filtros.add('período: ${_labelPeriodo(periodoFiltro.value)}');
    }
    if (apenasCriticos.value) {
      filtros.add('apenas críticos');
    }
    return filtros.isEmpty ? 'Sem filtros aplicados' : filtros.join(' | ');
  }
}
