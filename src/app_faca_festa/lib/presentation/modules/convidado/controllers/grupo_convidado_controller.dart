import 'dart:async';

import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/grupo_convidado.dart';
import 'package:app_faca_festa/domain/entities/resultados_operacao.dart';
import 'package:app_faca_festa/domain/repositories/grupo_convidado_repository.dart';

class GrupoConvidadoController extends GetxController {
  GrupoConvidadoController({required GrupoConvidadoRepository repository})
      : _repository = repository;

  final GrupoConvidadoRepository _repository;

  final RxList<GrupoConvidado> grupos = <GrupoConvidado>[].obs;
  final RxList<Convidado> convidados = <Convidado>[].obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  static const nomeGrupoPadrao = 'Geral';

  /// Grupos criados automaticamente em todo evento novo.
  static const gruposIniciais = <({
    String nome,
    String descricao,
    String icone,
    String corHex,
  })>[
    (
      nome: nomeGrupoPadrao,
      descricao: 'Grupo padrão dos convidados.',
      icone: 'group',
      corHex: '#0F766E',
    ),
    (
      nome: 'Família',
      descricao: 'Parentes e familiares.',
      icone: 'family',
      corHex: '#FF7BAC',
    ),
    (
      nome: 'Amigos',
      descricao: 'Amigos e convidados próximos.',
      icone: 'favorite',
      corHex: '#6EC3F4',
    ),
  ];

  StreamSubscription<List<GrupoConvidado>>? _subGrupos;
  StreamSubscription<List<Convidado>>? _subConvidados;
  List<Convidado> _convidadosRecebidos = const [];
  /// Snapshot bruto do Firestore (com possíveis duplicatas) para sanitização.
  List<GrupoConvidado> _ultimaListaBruta = const [];
  String? _idEventoAtual;
  Future<List<GrupoConvidado>>? _garantiaGruposIniciais;
  bool _gruposIniciaisSolicitados = false;

  Future<void> escutarGrupos(String idEvento) async {
    final eventoId = idEvento.trim();
    if (eventoId.isEmpty) {
      await _cancelarEscutas();
      _idEventoAtual = null;
      _convidadosRecebidos = const [];
      _ultimaListaBruta = const [];
      _gruposIniciaisSolicitados = false;
      grupos.clear();
      convidados.clear();
      carregando.value = false;
      return;
    }

    // Já escutando este evento: não reinicia seed (evita duplicar Grupos).
    if (_idEventoAtual == eventoId && _subGrupos != null) {
      return;
    }

    _idEventoAtual = eventoId;
    _gruposIniciaisSolicitados = false;
    carregando.value = true;
    erro.value = '';
    await _cancelarEscutas();
    grupos.clear();
    convidados.clear();
    _convidadosRecebidos = const [];
    _ultimaListaBruta = const [];

    _subGrupos = _repository.observarGrupos(eventoId).listen(
      (lista) {
        _ultimaListaBruta = List<GrupoConvidado>.from(lista);
        final tinhaDuplicatas = _temDuplicatasGruposIniciais(lista);
        // UI limpa na hora; limpeza no Firestore usa a lista bruta.
        grupos.assignAll(
          _unicosPorIdGrupo(_colapsarGruposIniciaisParaExibicao(lista)),
        );
        _publicarConvidadosNormalizados();
        carregando.value = false;

        final precisaSanitizar = !_gruposIniciaisSolicitados ||
            tinhaDuplicatas ||
            _faltamGruposIniciais(grupos);
        if (precisaSanitizar) {
          _gruposIniciaisSolicitados = true;
          unawaited(garantirGruposIniciais(idEvento: eventoId));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        erro.value = 'Erro ao carregar grupos de convidados: $error';
        carregando.value = false;
      },
    );

    _subConvidados = _repository.observarConvidados(eventoId).listen(
      (lista) {
        _convidadosRecebidos = lista;
        _publicarConvidadosNormalizados();
        carregando.value = false;
      },
      onError: (Object error, StackTrace stackTrace) {
        erro.value = 'Erro ao carregar convidados: $error';
        carregando.value = false;
      },
    );
  }

  /// ID estável dos grupos seed (idempotente no Firestore).
  static String idGrupoInicial(String idEvento, String nome) {
    final slug = nome
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'ç'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'grupo_${idEvento.trim()}_$slug';
  }

  void _publicarConvidadosNormalizados() {
    final lista = _convidadosRecebidos.map((convidado) {
      final nomeGrupo = convidado.nomeGrupo?.trim() ?? '';
      if ((convidado.idGrupo ?? '').trim().isNotEmpty || nomeGrupo.isEmpty) {
        return convidado;
      }
      final grupo = _buscarGrupoPorNome(nomeGrupo);
      return grupo == null
          ? convidado
          : convidado.copyWith(idGrupo: grupo.idGrupo, nomeGrupo: grupo.nome);
    }).toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    convidados.assignAll(lista);
    unawaited(_sincronizarResumoDosGrupos());
  }

  Future<void> adicionarGrupo(GrupoConvidado grupo) async {
    await _executarPersistencia(
      mensagemErro: 'Erro ao adicionar grupo',
      acao: () => _repository.salvarGrupo(grupo),
    );
  }

  /// Garante o grupo [nomeGrupoPadrao] (e os demais iniciais) para o cadastro
  /// do primeiro convidado poder continuar.
  Future<GrupoConvidado?> garantirGrupoPadrao({String? idEvento}) async {
    final criados = await garantirGruposIniciais(idEvento: idEvento);
    return _buscarGrupoPorNome(nomeGrupoPadrao) ??
        criados.firstWhereOrNull(
          (grupo) => _normalizarTexto(grupo.nome) == _normalizarTexto(nomeGrupoPadrao),
        );
  }

  /// Garante Geral, Família e Amigos no evento. Idempotente: só cria os que
  /// ainda não existem pelo nome.
  Future<List<GrupoConvidado>> garantirGruposIniciais({String? idEvento}) {
    final emAndamento = _garantiaGruposIniciais;
    if (emAndamento != null) return emAndamento;

    final futuro = _garantirGruposIniciais(idEvento: idEvento);
    _garantiaGruposIniciais = futuro;
    return futuro.whenComplete(() {
      if (identical(_garantiaGruposIniciais, futuro)) {
        _garantiaGruposIniciais = null;
      }
    });
  }

  Future<List<GrupoConvidado>> _garantirGruposIniciais({
    String? idEvento,
  }) async {
    final eventoId = (idEvento ?? _idEventoAtual ?? '').trim();
    if (eventoId.isEmpty) {
      throw StateError(
        'Nenhum evento selecionado para cadastrar os grupos iniciais.',
      );
    }

    await _deduplicarGruposIniciais();

    // Snapshot no início: evita duplicar se a lista local mudar no meio do loop.
    final porNome = <String, GrupoConvidado>{
      for (final grupo in grupos) _normalizarTexto(grupo.nome): grupo,
    };

    final criados = <GrupoConvidado>[];
    final agora = DateTime.now();

    for (final definicao in gruposIniciais) {
      final nomeNormalizado = _normalizarTexto(definicao.nome);
      final idEstavel = idGrupoInicial(eventoId, definicao.nome);
      final existente = porNome[nomeNormalizado] ?? _buscarGrupoPorId(idEstavel);
      if (existente != null) continue;

      final grupo = GrupoConvidado(
        idGrupo: idEstavel,
        idEvento: eventoId,
        nome: definicao.nome,
        descricao: definicao.descricao,
        icone: definicao.icone,
        corHex: definicao.corHex,
        dataCadastro: agora,
        dataAtualizacao: agora,
      );
      await adicionarGrupo(grupo);
      if (_buscarGrupoPorId(grupo.idGrupo) == null) {
        grupos.add(grupo);
      }
      porNome[nomeNormalizado] = grupo;
      criados.add(grupo);
    }

    return criados;
  }

  List<GrupoConvidado> _unicosPorIdGrupo(List<GrupoConvidado> lista) {
    final vistos = <String>{};
    final unicos = <GrupoConvidado>[];
    for (final grupo in lista) {
      final id = grupo.idGrupo.trim();
      if (id.isEmpty || !vistos.add(id)) continue;
      unicos.add(grupo);
    }
    return unicos;
  }

  bool _temDuplicatasGruposIniciais(List<GrupoConvidado> lista) {
    final nomesSeed = {
      for (final def in gruposIniciais) _normalizarTexto(def.nome),
    };
    final contagem = <String, int>{};
    for (final grupo in lista) {
      final nome = _normalizarTexto(grupo.nome);
      if (!nomesSeed.contains(nome)) continue;
      contagem[nome] = (contagem[nome] ?? 0) + 1;
      if (contagem[nome]! > 1) return true;
    }
    return false;
  }

  bool _faltamGruposIniciais(List<GrupoConvidado> lista) {
    final existentes = {
      for (final grupo in lista) _normalizarTexto(grupo.nome),
    };
    return gruposIniciais.any(
      (def) => !existentes.contains(_normalizarTexto(def.nome)),
    );
  }

  /// Escolhe um representante por nome seed (id estável > mais convidados > mais antigo).
  List<GrupoConvidado> _colapsarGruposIniciaisParaExibicao(
    List<GrupoConvidado> lista,
  ) {
    final nomesSeed = {
      for (final def in gruposIniciais) _normalizarTexto(def.nome),
    };
    final porNome = <String, List<GrupoConvidado>>{};
    final demais = <GrupoConvidado>[];

    for (final grupo in lista) {
      final nome = _normalizarTexto(grupo.nome);
      if (!nomesSeed.contains(nome)) {
        demais.add(grupo);
        continue;
      }
      (porNome[nome] ??= <GrupoConvidado>[]).add(grupo);
    }

    final colapsados = <GrupoConvidado>[];
    for (final entry in porNome.entries) {
      final candidatos = List<GrupoConvidado>.from(entry.value);
      if (candidatos.length == 1) {
        colapsados.add(candidatos.first);
        continue;
      }
      final idPreferido = _idEventoAtual == null
          ? null
          : idGrupoInicial(
              _idEventoAtual!,
              candidatos.first.nome,
            );
      candidatos.sort((a, b) => _compararCandidatosGrupo(a, b, idPreferido));
      colapsados.add(candidatos.first);
    }

    return [...colapsados, ...demais]
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  }

  int _compararCandidatosGrupo(
    GrupoConvidado a,
    GrupoConvidado b,
    String? idPreferido,
  ) {
    if (idPreferido != null) {
      if (a.idGrupo == idPreferido) return -1;
      if (b.idGrupo == idPreferido) return 1;
    }
    final qa = convidadosDoGrupo(a.idGrupo).length;
    final qb = convidadosDoGrupo(b.idGrupo).length;
    if (qa != qb) return qb.compareTo(qa);
    return a.dataCadastro.compareTo(b.dataCadastro);
  }

  /// Remove cópias extras dos grupos seed no Firestore (e na lista local).
  Future<void> _deduplicarGruposIniciais() async {
    final fonte = _ultimaListaBruta.isNotEmpty
        ? List<GrupoConvidado>.from(_ultimaListaBruta)
        : grupos.toList();

    for (final definicao in gruposIniciais) {
      final nomeAlvo = _normalizarTexto(definicao.nome);
      final duplicados =
          fonte.where((g) => _normalizarTexto(g.nome) == nomeAlvo).toList();
      if (duplicados.length <= 1) continue;

      final idPreferido = _idEventoAtual == null
          ? null
          : idGrupoInicial(_idEventoAtual!, definicao.nome);

      duplicados.sort((a, b) => _compararCandidatosGrupo(a, b, idPreferido));

      final keep = duplicados.first;
      for (final dup in duplicados.skip(1)) {
        final lista = convidadosDoGrupo(dup.idGrupo);
        for (final convidado in lista) {
          await vincularConvidadoAoGrupo(convidado: convidado, grupo: keep);
        }
        try {
          await _repository.excluirGrupo(
            dup.idGrupo,
            idEvento: _idEventoAtual,
            desvincularConvidados: false,
          );
          fonte.removeWhere((g) => g.idGrupo == dup.idGrupo);
          _ultimaListaBruta =
              _ultimaListaBruta.where((g) => g.idGrupo != dup.idGrupo).toList();
          grupos.removeWhere((g) => g.idGrupo == dup.idGrupo);
        } catch (e) {
          erro.value = 'Erro ao remover grupo duplicado: $e';
        }
      }
    }

    // Garante UI alinhada ao que restou após a limpeza.
    if (_ultimaListaBruta.isNotEmpty) {
      grupos.assignAll(
        _unicosPorIdGrupo(
          _colapsarGruposIniciaisParaExibicao(_ultimaListaBruta),
        ),
      );
    }
  }

  Future<void> atualizarGrupo(GrupoConvidado grupo) async {
    await _executarPersistencia(
      mensagemErro: 'Erro ao atualizar grupo',
      acao: () => _repository.salvarGrupo(grupo),
    );
  }

  Future<void> excluirGrupo(
    String idGrupo, {
    bool desvincularConvidados = true,
  }) async {
    if (convidadosDoGrupo(idGrupo).isNotEmpty) {
      erro.value =
          'Não é possível excluir um grupo que ainda possui convidados.';
      throw StateError(erro.value);
    }

    await _executarPersistencia(
      mensagemErro: 'Erro ao excluir grupo',
      acao: () => _repository.excluirGrupo(
        idGrupo,
        idEvento: _idEventoAtual,
        desvincularConvidados: desvincularConvidados,
      ),
    );
  }

  Future<void> vincularConvidadoAoGrupo({
    required Convidado convidado,
    required GrupoConvidado grupo,
  }) async {
    await _executarPersistencia(
      mensagemErro: 'Erro ao vincular convidado ao grupo',
      acao: () => _repository.vincularConvidadoAoGrupo(convidado, grupo),
    );
  }

  Future<void> removerConvidadoDoGrupo(Convidado convidado) async {
    await _executarPersistencia(
      mensagemErro: 'Erro ao remover convidado do grupo',
      acao: () => _repository.removerConvidadoDoGrupo(convidado),
    );
  }

  Future<void> vincularConvidadoNaMesa({
    required Convidado convidado,
    required String idMesa,
    required int numeroMesa,
  }) async {
    await _executarPersistencia(
      mensagemErro: 'Erro ao vincular convidado à mesa',
      acao: () => _repository.vincularConvidadoNaMesa(
        convidado,
        idMesa,
        numeroMesa,
      ),
    );
  }

  Future<void> removerConvidadoDaMesa(Convidado convidado) async {
    await _executarPersistencia(
      mensagemErro: 'Erro ao remover convidado da mesa',
      acao: () => _repository.removerConvidadoDaMesa(convidado),
    );
  }

  Future<void> _executarPersistencia({
    required String mensagemErro,
    required Future<void> Function() acao,
  }) async {
    erro.value = '';
    try {
      await acao();
    } catch (e) {
      erro.value = '$mensagemErro: $e';
      rethrow;
    }
  }

  List<Convidado> convidadosDoGrupo(String idGrupo) {
    final grupo = _buscarGrupoPorId(idGrupo);
    final nomeGrupo = _normalizarTexto(grupo?.nome ?? '');
    final lista = convidados.where((convidado) {
      if ((convidado.idGrupo ?? '').trim() == idGrupo) return true;
      if (nomeGrupo.isEmpty) return false;
      return _normalizarTexto(convidado.nomeGrupo ?? '') == nomeGrupo;
    }).toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return lista;
  }

  List<Convidado> convidadosSemGrupo() {
    final lista = convidados.where((convidado) {
      return (convidado.idGrupo ?? '').trim().isEmpty &&
          (convidado.nomeGrupo ?? '').trim().isEmpty;
    }).toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return lista;
  }

  List<Convidado> convidadosDaMesa(String idMesa) {
    return convidados.where((c) => c.idMesa == idMesa).toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  }

  List<Convidado> convidadosDaMesaNumero(int numeroMesa) {
    return convidados.where((c) => c.numeroMesa == numeroMesa).toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  }

  Map<String, List<Convidado>> get convidadosPorGrupoId {
    return {
      for (final grupo in grupos)
        grupo.idGrupo: convidadosDoGrupo(grupo.idGrupo),
    };
  }

  Map<int, List<Convidado>> get convidadosPorMesaNumero {
    final mapa = <int, List<Convidado>>{};
    for (final convidado in convidados) {
      final numero = convidado.numeroMesa;
      if (numero == null) continue;
      mapa.putIfAbsent(numero, () => <Convidado>[]).add(convidado);
    }
    for (final lista in mapa.values) {
      lista
          .sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    }
    return mapa;
  }

  EstatisticasGruposConvidado get estatisticasGrupos => EstatisticasGruposConvidado(
        totalGrupos: grupos.length,
        gruposComConvidados: gruposComConvidados,
        gruposVazios: gruposVazios,
        totalConvidados: convidados.length,
        confirmados: _totalStatus(StatusConvidado.confirmado),
        pendentes: _totalStatus(StatusConvidado.pendente),
        recusados: _totalStatus(StatusConvidado.recusado),
        adultos: _totalTipo(TipoConvidado.adulto),
        criancas: _totalTipo(TipoConvidado.crianca),
        bebes: _totalTipo(TipoConvidado.bebe),
        semGrupo: convidadosSemGrupo().length,
      );

  EstatisticasMesas get estatisticasMesas {
    final ocupados =
        convidados.where((c) => c.idMesa != null).length;
    return EstatisticasMesas(
      totalMesas: convidadosPorMesaNumero.length,
      assentos: ocupados,
      ocupados: ocupados,
      livres: 0,
    );
  }

  int get totalGrupos => grupos.length;
  int get gruposComConvidados =>
      grupos.where((g) => convidadosDoGrupo(g.idGrupo).isNotEmpty).length;
  int get gruposVazios =>
      grupos.where((g) => convidadosDoGrupo(g.idGrupo).isEmpty).length;
  int get totalConvidados => convidados.length;
  int get totalConfirmados => _totalStatus(StatusConvidado.confirmado);
  int get totalAdultos => _totalTipo(TipoConvidado.adulto);
  int get totalCriancas => _totalTipo(TipoConvidado.crianca);
  int get totalBebes => _totalTipo(TipoConvidado.bebe);

  int _totalStatus(StatusConvidado status) =>
      convidados.where((c) => c.status == status).length;
  int _totalTipo(TipoConvidado tipo) =>
      convidados.where((c) => c.tipoConvidado == tipo).length;

  Future<void> _sincronizarResumoDosGrupos() async {
    if (_idEventoAtual == null || grupos.isEmpty) return;
    final resumos = <ResumoGrupoConvidado>[];
    for (final grupo in grupos) {
      final lista = convidadosDoGrupo(grupo.idGrupo);
      final resumo = ResumoGrupoConvidado(
        idGrupo: grupo.idGrupo,
        total: lista.length,
        adultos:
            lista.where((c) => c.tipoConvidado == TipoConvidado.adulto).length,
        criancas:
            lista.where((c) => c.tipoConvidado == TipoConvidado.crianca).length,
        bebes: lista.where((c) => c.tipoConvidado == TipoConvidado.bebe).length,
        confirmados:
            lista.where((c) => c.status == StatusConvidado.confirmado).length,
      );
      final mudou = grupo.totalConvidados != resumo.total ||
          grupo.totalAdultos != resumo.adultos ||
          grupo.totalCriancas != resumo.criancas ||
          grupo.totalBebes != resumo.bebes ||
          grupo.totalConfirmados != resumo.confirmados;
      if (mudou) resumos.add(resumo);
    }

    try {
      await _repository.atualizarResumos(resumos);
    } catch (e) {
      erro.value = 'Erro ao sincronizar resumo dos grupos: $e';
    }
  }

  GrupoConvidado? _buscarGrupoPorId(String idGrupo) {
    return grupos.firstWhereOrNull((grupo) => grupo.idGrupo == idGrupo);
  }

  GrupoConvidado? _buscarGrupoPorNome(String nome) {
    final alvo = _normalizarTexto(nome);
    if (alvo.isEmpty) return null;
    return grupos.firstWhereOrNull(
      (grupo) => _normalizarTexto(grupo.nome) == alvo,
    );
  }

  String _normalizarTexto(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<void> recarregar() async {
    final idEvento = _idEventoAtual;
    if (idEvento == null || idEvento.trim().isEmpty) return;
    await escutarGrupos(idEvento);
  }

  Future<void> _cancelarEscutas() async {
    await _subGrupos?.cancel();
    await _subConvidados?.cancel();
    _subGrupos = null;
    _subConvidados = null;
  }

  Future<void> encerrarEscutas() async {
    await _cancelarEscutas();
    _idEventoAtual = null;
    _convidadosRecebidos = const [];
    _ultimaListaBruta = const [];
    _gruposIniciaisSolicitados = false;
    grupos.clear();
    convidados.clear();
    carregando.value = false;
  }

  @override
  void onClose() {
    unawaited(_cancelarEscutas());
    super.onClose();
  }
}
