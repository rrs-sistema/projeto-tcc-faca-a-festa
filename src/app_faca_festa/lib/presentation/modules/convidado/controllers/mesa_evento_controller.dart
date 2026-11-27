import 'dart:async';

import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/grupo_convidado.dart';
import 'package:app_faca_festa/domain/entities/mesa_evento.dart';
import 'package:app_faca_festa/domain/entities/resultados_operacao.dart';
import 'package:app_faca_festa/domain/repositories/mesa_evento_repository.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/grupo_convidado_controller.dart';
import 'package:app_faca_festa/core/conectividade/recarregar_ao_reconectar.dart';

class MesaEventoController extends GetxController
    with RecarregarAoReconectar {
  MesaEventoController({
    required MesaEventoRepository repository,
    GrupoConvidadoController? Function()? grupoControllerOf,
  })  : _repository = repository,
        _grupoControllerOf = grupoControllerOf;

  final MesaEventoRepository _repository;
  final GrupoConvidadoController? Function()? _grupoControllerOf;

  final RxList<MesaEvento> mesas = <MesaEvento>[].obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  static const capacidadePadraoSeed = 8;

  static const mesasIniciais = <({
    int numero,
    String nome,
    int capacidade,
    String nomeGrupo,
    String corHex,
  })>[
    (
      numero: 4,
      nome: 'Mesa 4',
      capacidade: capacidadePadraoSeed,
      nomeGrupo: 'Família',
      corHex: '#FF7BAC',
    ),
    (
      numero: 6,
      nome: 'Mesa 6',
      capacidade: capacidadePadraoSeed,
      nomeGrupo: 'Amigos',
      corHex: '#6EC3F4',
    ),
  ];

  StreamSubscription<List<MesaEvento>>? _subMesas;
  Worker? _convidadosWorker;
  String? _idEventoAtual;
  List<MesaEvento> _ultimaListaBruta = const [];
  Future<List<MesaEvento>>? _garantiaMesasIniciais;
  bool _mesasIniciaisSolicitadas = false;

  GrupoConvidadoController? get _grupos => _grupoControllerOf?.call();

  String? get idEventoAtual => _idEventoAtual;

  List<MesaEvento> get mesasAtivas =>
      mesas.where((mesa) => mesa.ativa).toList(growable: false);

  Future<void> escutarMesas(String idEvento) async {
    final eventoId = idEvento.trim();
    if (eventoId.isEmpty) {
      await encerrarEscutas();
      return;
    }

    if (_idEventoAtual == eventoId && _subMesas != null) {
      return;
    }

    _idEventoAtual = eventoId;
    _mesasIniciaisSolicitadas = false;
    carregando.value = true;
    erro.value = '';
    await _cancelarEscutas();
    mesas.clear();
    _ultimaListaBruta = const [];

    _subMesas = _repository.observarMesas(eventoId).listen(
      (lista) {
        _ultimaListaBruta = List<MesaEvento>.from(lista);
        final tinhaDuplicatas = _temDuplicatasMesasIniciais(lista);
        mesas.assignAll(
          _unicosPorIdMesa(_colapsarMesasIniciaisParaExibicao(lista)),
        );
        carregando.value = false;
        _sincronizarOcupacaoLocal();
        // Seed/dedupe só na 1ª emissão; depois só dedupe se houver duplicata.
        // Criação de 4/6 só ocorre se o get() confirmar ZERO mesas no evento.
        if (!_mesasIniciaisSolicitadas) {
          _mesasIniciaisSolicitadas = true;
          unawaited(garantirMesasIniciais(idEvento: eventoId));
        } else if (tinhaDuplicatas) {
          unawaited(_deduplicarMesasIniciais());
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        erro.value = falhaDeConexao(error)
            ? semInternetPara('As mesas atualizam')
            : 'Erro ao carregar mesas do evento: $error';
        carregando.value = false;
        refazerAoReconectar('mesas', () async {
          if (_idEventoAtual != eventoId) return;
          await _cancelarEscutas();
          await escutarMesas(eventoId);
        });
      },
    );

    final grupos = _grupos;
    if (grupos != null) {
      _convidadosWorker?.dispose();
      _convidadosWorker = ever<List<Convidado>>(grupos.convidados, (_) {
        unawaited(_sincronizarOcupacaoPersistida());
      });
    }
  }

  static String idMesaInicial(String idEvento, int numero) =>
      'mesa_${idEvento.trim()}_$numero';

  Future<void> adicionarMesa(MesaEvento mesa) async {
    await _executarPersistencia(
      mensagemErro: 'Erro ao adicionar mesa',
      acao: () => _repository.salvarMesa(mesa),
    );
  }

  Future<void> atualizarMesa(MesaEvento mesa) async {
    await _executarPersistencia(
      mensagemErro: 'Erro ao atualizar mesa',
      acao: () => _repository.salvarMesa(mesa),
    );
  }

  Future<void> excluirMesa(
    String idMesa, {
    bool desvincularConvidados = true,
  }) async {
    if (convidadosDaMesa(idMesa).isNotEmpty) {
      erro.value =
          'Não é possível excluir uma mesa que ainda possui convidados.';
      throw StateError(erro.value);
    }

    await _executarPersistencia(
      mensagemErro: 'Erro ao excluir mesa',
      acao: () => _repository.excluirMesa(
        idMesa,
        idEvento: _idEventoAtual,
        desvincularConvidados: desvincularConvidados,
      ),
    );
  }

  /// Garante Mesa 4 (Família) e Mesa 6 (Amigos). Idempotente por número.
  Future<List<MesaEvento>> garantirMesasIniciais({String? idEvento}) {
    final emAndamento = _garantiaMesasIniciais;
    if (emAndamento != null) return emAndamento;

    final futuro = _garantirMesasIniciais(idEvento: idEvento);
    _garantiaMesasIniciais = futuro;
    return futuro.whenComplete(() {
      if (identical(_garantiaMesasIniciais, futuro)) {
        _garantiaMesasIniciais = null;
      }
    });
  }

  Future<List<MesaEvento>> _garantirMesasIniciais({String? idEvento}) async {
    final eventoId = (idEvento ?? _idEventoAtual ?? '').trim();
    if (eventoId.isEmpty) {
      throw StateError(
        'Nenhum evento selecionado para cadastrar as mesas iniciais.',
      );
    }

    final grupoController = _grupos;
    if (grupoController != null) {
      await grupoController.garantirGruposIniciais(idEvento: eventoId);
    }

    await _deduplicarMesasIniciais();

    // get() pontual: snapshot do stream pode chegar vazio por um instante no
    // hot restart e acabar criando Mesa 6 em cima de mesas já cadastradas.
    final noServidor = await _repository.buscarMesas(eventoId);
    _ultimaListaBruta = List<MesaEvento>.from(noServidor);
    if (noServidor.isNotEmpty) {
      mesas.assignAll(
        _unicosPorIdMesa(_colapsarMesasIniciaisParaExibicao(noServidor)),
      );
      return const [];
    }

    final criados = <MesaEvento>[];
    for (final definicao in mesasIniciais) {
      final idEstavel = idMesaInicial(eventoId, definicao.numero);
      final grupo = _buscarGrupoPorNome(definicao.nomeGrupo);
      final mesa = MesaEvento(
        idMesa: idEstavel,
        idEvento: eventoId,
        numeroMesa: definicao.numero,
        nomeMesa: definicao.nome,
        capacidadeAssentos: definicao.capacidade,
        idGrupo: grupo?.idGrupo,
        nomeGrupo: grupo?.nome ?? definicao.nomeGrupo,
        corHex: definicao.corHex,
      );
      await adicionarMesa(mesa);
      if (_buscarMesaPorId(mesa.idMesa) == null) {
        mesas.add(mesa);
      }
      _ultimaListaBruta = [..._ultimaListaBruta, mesa];
      criados.add(mesa);
    }

    return criados;
  }

  List<MesaEvento> _unicosPorIdMesa(List<MesaEvento> lista) {
    final vistos = <String>{};
    final unicos = <MesaEvento>[];
    for (final mesa in lista) {
      final id = mesa.idMesa.trim();
      if (id.isEmpty || !vistos.add(id)) continue;
      unicos.add(mesa);
    }
    return unicos;
  }

  bool _temDuplicatasMesasIniciais(List<MesaEvento> lista) {
    final numerosSeed = {for (final def in mesasIniciais) def.numero};
    final contagem = <int, int>{};
    for (final mesa in lista) {
      if (!numerosSeed.contains(mesa.numeroMesa)) continue;
      contagem[mesa.numeroMesa] = (contagem[mesa.numeroMesa] ?? 0) + 1;
      if (contagem[mesa.numeroMesa]! > 1) return true;
    }
    return false;
  }

  List<MesaEvento> _colapsarMesasIniciaisParaExibicao(List<MesaEvento> lista) {
    final numerosSeed = {for (final def in mesasIniciais) def.numero};
    final porNumero = <int, List<MesaEvento>>{};
    final demais = <MesaEvento>[];

    for (final mesa in lista) {
      if (!numerosSeed.contains(mesa.numeroMesa)) {
        demais.add(mesa);
        continue;
      }
      (porNumero[mesa.numeroMesa] ??= <MesaEvento>[]).add(mesa);
    }

    final colapsadas = <MesaEvento>[];
    for (final entry in porNumero.entries) {
      final candidatos = List<MesaEvento>.from(entry.value);
      if (candidatos.length == 1) {
        colapsadas.add(candidatos.first);
        continue;
      }
      final idPreferido = _idEventoAtual == null
          ? null
          : idMesaInicial(_idEventoAtual!, entry.key);
      candidatos.sort((a, b) {
        if (idPreferido != null) {
          if (a.idMesa == idPreferido) return -1;
          if (b.idMesa == idPreferido) return 1;
        }
        final oa = confirmadosDaMesa(a);
        final ob = confirmadosDaMesa(b);
        if (oa != ob) return ob.compareTo(oa);
        return a.nomeMesa.compareTo(b.nomeMesa);
      });
      colapsadas.add(candidatos.first);
    }

    return [...colapsadas, ...demais]
      ..sort((a, b) {
        final porNumeroCmp = a.numeroMesa.compareTo(b.numeroMesa);
        if (porNumeroCmp != 0) return porNumeroCmp;
        return a.nomeMesa.toLowerCase().compareTo(b.nomeMesa.toLowerCase());
      });
  }

  Future<void> _deduplicarMesasIniciais() async {
    final fonte = _ultimaListaBruta.isNotEmpty
        ? List<MesaEvento>.from(_ultimaListaBruta)
        : mesas.toList();

    for (final definicao in mesasIniciais) {
      final duplicados =
          fonte.where((m) => m.numeroMesa == definicao.numero).toList();
      if (duplicados.length <= 1) continue;

      final idPreferido = _idEventoAtual == null
          ? null
          : idMesaInicial(_idEventoAtual!, definicao.numero);

      duplicados.sort((a, b) {
        if (idPreferido != null) {
          if (a.idMesa == idPreferido) return -1;
          if (b.idMesa == idPreferido) return 1;
        }
        // Prefere o ID legado mais antigo (sem timestamp no fim) se ambos
        // forem vazios — na prática: estável > mais convidados > id menor.
        final oa = convidadosDaMesa(a.idMesa).length;
        final ob = convidadosDaMesa(b.idMesa).length;
        if (oa != ob) return ob.compareTo(oa);
        return a.idMesa.compareTo(b.idMesa);
      });

      final keep = duplicados.first;
      for (final dup in duplicados.skip(1)) {
        // Move convidados da cópia para a mesa que permanece.
        for (final convidado in convidadosDaMesa(dup.idMesa)) {
          final grupos = _grupos;
          if (grupos == null) continue;
          try {
            await grupos.vincularConvidadoNaMesa(
              convidado: convidado,
              idMesa: keep.idMesa,
              numeroMesa: keep.numeroMesa,
            );
          } catch (_) {}
        }
        try {
          await _repository.excluirMesa(
            dup.idMesa,
            idEvento: _idEventoAtual,
            desvincularConvidados: false,
          );
          fonte.removeWhere((m) => m.idMesa == dup.idMesa);
          _ultimaListaBruta =
              _ultimaListaBruta.where((m) => m.idMesa != dup.idMesa).toList();
          mesas.removeWhere((m) => m.idMesa == dup.idMesa);
        } catch (e) {
          erro.value = 'Erro ao remover mesa duplicada: $e';
        }
      }
    }

    if (_ultimaListaBruta.isNotEmpty) {
      mesas.assignAll(
        _unicosPorIdMesa(_colapsarMesasIniciaisParaExibicao(_ultimaListaBruta)),
      );
    }
  }

  List<Convidado> convidadosDaMesa(String idMesa) {
    final grupos = _grupos;
    if (grupos == null) return const [];
    final lista = grupos.convidados.where((c) {
      return (c.idMesa ?? '').trim() == idMesa;
    }).toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return lista;
  }

  List<Convidado> convidadosDaMesaNumero(int numeroMesa) {
    final grupos = _grupos;
    if (grupos == null) return const [];
    final lista = grupos.convidados.where((c) {
      return c.numeroMesa == numeroMesa;
    }).toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return lista;
  }

  int ocupadosDaMesa(MesaEvento mesa) {
    return convidadosDaMesa(mesa.idMesa)
        .where(
          (c) =>
              c.ocupaAssento &&
              (c.status == StatusConvidado.confirmado ||
                  c.status == StatusConvidado.pendente),
        )
        .length;
  }

  int confirmadosDaMesa(MesaEvento mesa) {
    return convidadosDaMesa(mesa.idMesa)
        .where(
          (c) => c.ocupaAssento && c.status == StatusConvidado.confirmado,
        )
        .length;
  }

  EstatisticasMesas get estatisticas {
    final ativas = mesasAtivas;
    var assentos = 0;
    var ocupados = 0;
    for (final mesa in ativas) {
      assentos += mesa.capacidadeAssentos;
      ocupados += confirmadosDaMesa(mesa);
    }
    return EstatisticasMesas(
      totalMesas: ativas.length,
      assentos: assentos,
      ocupados: ocupados,
      livres: (assentos - ocupados).clamp(0, assentos),
    );
  }

  MesaEvento? _buscarMesaPorId(String idMesa) {
    return mesas.firstWhereOrNull((mesa) => mesa.idMesa == idMesa);
  }

  MesaEvento? buscarPorNumero(int numero) {
    return mesas.firstWhereOrNull((mesa) => mesa.numeroMesa == numero);
  }

  GrupoConvidado? _buscarGrupoPorNome(String nome) {
    final grupos = _grupos;
    if (grupos == null) return null;
    final alvo = nome.trim().toLowerCase();
    return grupos.grupos.firstWhereOrNull(
      (g) => g.nome.trim().toLowerCase() == alvo,
    );
  }

  void _sincronizarOcupacaoLocal() {
    if (mesas.isEmpty) return;
    for (var i = 0; i < mesas.length; i++) {
      final mesa = mesas[i];
      final ocupados = confirmadosDaMesa(mesa);
      if (mesa.totalOcupados != ocupados) {
        mesas[i] = mesa.copyWith(totalOcupados: ocupados);
      }
    }
  }

  Future<void> _sincronizarOcupacaoPersistida() async {
    if (_idEventoAtual == null || mesas.isEmpty) return;
    _sincronizarOcupacaoLocal();
    for (final mesa in List<MesaEvento>.from(mesas)) {
      final ocupados = confirmadosDaMesa(mesa);
      if (mesa.totalOcupados == ocupados) continue;
      try {
        await _repository.atualizarOcupacao(
          idMesa: mesa.idMesa,
          totalOcupados: ocupados,
        );
      } catch (e) {
        erro.value = 'Erro ao sincronizar ocupação das mesas: $e';
      }
    }
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

  Future<void> _cancelarEscutas() async {
    await _subMesas?.cancel();
    _subMesas = null;
    _convidadosWorker?.dispose();
    _convidadosWorker = null;
  }

  Future<void> encerrarEscutas() async {
    await _cancelarEscutas();
    _idEventoAtual = null;
    _mesasIniciaisSolicitadas = false;
    _ultimaListaBruta = const [];
    mesas.clear();
    carregando.value = false;
  }

  @override
  void onClose() {
    unawaited(_cancelarEscutas());
    super.onClose();
  }
}
