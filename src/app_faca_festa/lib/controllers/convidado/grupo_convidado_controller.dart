import 'dart:async';

import 'package:get/get.dart';

import './../../domain/entities/convidado.dart';
import './../../domain/entities/grupo_convidado.dart';
import './../../domain/repositories/grupo_convidado_repository.dart';

class GrupoConvidadoController extends GetxController {
  GrupoConvidadoController({required GrupoConvidadoRepository repository})
      : _repository = repository;

  final GrupoConvidadoRepository _repository;

  final RxList<GrupoConvidado> grupos = <GrupoConvidado>[].obs;
  final RxList<Convidado> convidados = <Convidado>[].obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  StreamSubscription<List<GrupoConvidado>>? _subGrupos;
  StreamSubscription<List<Convidado>>? _subConvidados;
  List<Convidado> _convidadosRecebidos = const [];
  String? _idEventoAtual;

  Future<void> escutarGrupos(String idEvento) async {
    final eventoId = idEvento.trim();
    if (eventoId.isEmpty) {
      await _cancelarEscutas();
      _idEventoAtual = null;
      _convidadosRecebidos = const [];
      grupos.clear();
      convidados.clear();
      carregando.value = false;
      return;
    }

    _idEventoAtual = eventoId;
    carregando.value = true;
    erro.value = '';
    await _cancelarEscutas();
    grupos.clear();
    convidados.clear();
    _convidadosRecebidos = const [];

    _subGrupos = _repository.observarGrupos(eventoId).listen(
      (lista) {
        grupos.assignAll(lista);
        _publicarConvidadosNormalizados();
        carregando.value = false;
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

  Map<String, dynamic> get estatisticasGrupos => {
        'totalGrupos': grupos.length,
        'gruposComConvidados': gruposComConvidados,
        'gruposVazios': gruposVazios,
        'totalConvidados': convidados.length,
        'confirmados': _totalStatus(StatusConvidado.confirmado),
        'pendentes': _totalStatus(StatusConvidado.pendente),
        'recusados': _totalStatus(StatusConvidado.recusado),
        'adultos': _totalTipo(TipoConvidado.adulto),
        'criancas': _totalTipo(TipoConvidado.crianca),
        'bebes': _totalTipo(TipoConvidado.bebe),
        'semGrupo': convidadosSemGrupo().length,
      };

  Map<String, dynamic> get estatisticasMesas {
    return {
      'totalMesas': convidadosPorMesaNumero.length,
      'totalAssentosOcupados': convidados.where((c) => c.idMesa != null).length,
      'confirmadosEmMesa': convidados
          .where(
              (c) => c.idMesa != null && c.status == StatusConvidado.confirmado)
          .length,
    };
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
