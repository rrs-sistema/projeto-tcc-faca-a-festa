import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:math';

import 'package:app_faca_festa/data/models/DTO/fornecedor_detalhado_dto.dart';
import 'package:app_faca_festa/data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import 'package:app_faca_festa/data/models/model.dart';
import 'package:app_faca_festa/data/models/servico_produto/categoria_servico_model.dart';
import 'package:app_faca_festa/data/models/servico_produto/fornecedor_categoria_model.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedor_localizacao.dart';

class FornecedorLocalizacaoController extends GetxController {
  FornecedorLocalizacaoController({
    GerenciarFornecedorLocalizacao? localizacao,
  }) : _localizacao = localizacao ?? Get.find<GerenciarFornecedorLocalizacao>();

  static FornecedorLocalizacaoController get to {
    return Get.find<FornecedorLocalizacaoController>();
  }

  final GerenciarFornecedorLocalizacao _localizacao;

  var avaliacaoMinima = 0.0.obs;
  bool _dadosCarregados = false;
  bool _escutasAtivas = false;
  bool _escutaServicosAtiva = false;
  bool _inicializando = false;
  final Set<String> _fontesProntas = <String>{};
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _reconstrucaoDebounce;

  var userLongitude = 0.0.obs;
  var userLatitude = 0.0.obs;
  var carregando = true.obs;
  var raio = 10.0.obs;

  // Listas brutas (para reatividade)
  final _fornecedoresRaw = <FornecedorModel>[].obs;
  final _relacoesRaw = <FornecedorCategoriaModel>[].obs;
  final territoriosFornecedores = <TerritorioModel>[].obs;

  // Listas principais
  var fornecedores = <FornecedorDetalhadoDto>[].obs;
  var fornecedoresFiltrados = <FornecedorDetalhadoDto>[].obs;
  var categorias = <CategoriaServicoModel>[].obs;
  var servicosFornecedor = <FornecedorServicoDetalhadoDto>[].obs;
  var servicosPorCategoria = <FornecedorServicoDetalhadoDto>[].obs;
  var allService = <FornecedorServicoDetalhadoDto>[].obs;
  var carregandoServicosFornecedor = false.obs;
  final RxnString servicoSelecionadoId = RxnString();

  // Listas auxiliares
  var fornecedoresProximos = <FornecedorDetalhadoDto>[].obs;
  var fornecedoresDestaque = <FornecedorDetalhadoDto>[].obs;

  // Mapa auxiliar de médias de avaliações
  var mediasAvaliacoes = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    raio.value = 25.0;
    unawaited(inicializar());
  }

  @override
  void onClose() {
    _reconstrucaoDebounce?.cancel();
    unawaited(encerrarEscutas());
    super.onClose();
  }

  Future<void> encerrarEscutas() async {
    _reconstrucaoDebounce?.cancel();
    _reconstrucaoDebounce = null;
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _escutasAtivas = false;
    _escutaServicosAtiva = false;
    _dadosCarregados = false;
  }

  /// Carga única de GPS + streams. Reentradas na tela não disparam de novo.
  Future<void> inicializar({bool forcarLocalizacao = false}) async {
    if (_inicializando) return;
    if (_escutasAtivas && _dadosCarregados && !forcarLocalizacao) return;

    _inicializando = true;
    try {
      await Future.wait<void>([
        _obterLocalizacaoUsuario(forcar: forcarLocalizacao),
        carregarDados(),
      ]);
      if (forcarLocalizacao || _dadosCarregados) {
        _reconstruirLista();
      }
    } finally {
      _inicializando = false;
    }
  }

  /// Catálogo global de serviços: só sob demanda (detalhe / cotação).
  void ensureTodosServicos() {
    if (_escutaServicosAtiva) return;
    unawaited(escutarTodosServicos());
  }

  // ==========================================================
  // === LOCALIZAÇÃO DO USUÁRIO (com fallback)
  // ==========================================================
  Future<void> _obterLocalizacaoUsuario({bool forcar = false}) async {
    if (!forcar && (userLatitude.value != 0.0 || userLongitude.value != 0.0)) {
      return;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint(
            '⚠️ Serviço de localização desativado — fallback (Curitiba).');
        _aplicarFallbackCuritiba();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint(
            '⚠️ Permissão negada — usando coordenadas padrão (Curitiba).');
        _aplicarFallbackCuritiba();
        return;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _aplicarPosicao(lastKnown, origem: 'última conhecida');
        if (!forcar) {
          unawaited(_atualizarPosicaoAtualEmBackground());
          return;
        }
      }

      final pos = await _buscarPosicaoAtual();
      if (pos != null) {
        _aplicarPosicao(pos, origem: 'GPS');
        return;
      }

      if (userLatitude.value == 0.0 && userLongitude.value == 0.0) {
        debugPrint('⚠️ GPS não respondeu a tempo — usando Curitiba.');
        _aplicarFallbackCuritiba();
      }
    } catch (e) {
      debugPrint('⚠️ Não foi possível obter localização: $e');
      if (userLatitude.value == 0.0 && userLongitude.value == 0.0) {
        _aplicarFallbackCuritiba();
      }
    }
  }

  Future<void> _atualizarPosicaoAtualEmBackground() async {
    final pos = await _buscarPosicaoAtual();
    if (pos == null) return;
    _aplicarPosicao(pos, origem: 'GPS');
    if (_dadosCarregados) _reconstruirLista();
  }

  Future<Position?> _buscarPosicaoAtual() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } on TimeoutException {
      debugPrint('⚠️ GPS atual não respondeu a tempo.');
      return null;
    }
  }

  void _aplicarPosicao(Position posicao, {required String origem}) {
    userLatitude.value = posicao.latitude;
    userLongitude.value = posicao.longitude;
    debugPrint(
        '📍 Localização ($origem): ${posicao.latitude}, ${posicao.longitude}');
  }

  void _aplicarFallbackCuritiba() {
    userLatitude.value = -25.43;
    userLongitude.value = -49.27;
  }

  // ==========================================================
  // === CARGA PRINCIPAL (streams reativas)
  // ==========================================================
  Future<void> carregarDados() async {
    if (_escutasAtivas) return;
    _escutasAtivas = true;
    carregando.value = true;

    try {
      _subscriptions.add(
        _localizacao.observarCategoriasAtivas().listen(
          (lista) {
            categorias.assignAll(lista);
            _onFontePronta('categorias');
          },
        ),
      );

      _subscriptions.add(
        _localizacao.observarFornecedoresAtivos().listen(
          (lista) {
            _fornecedoresRaw.assignAll(lista);
            debugPrint('✅ Fornecedores carregados: ${lista.length}');
            _onFontePronta('fornecedores');
          },
        ),
      );

      _subscriptions.add(
        _localizacao.observarTerritoriosAtivos().listen(
          (lista) {
            territoriosFornecedores.assignAll(lista);
            debugPrint('✅ Territórios carregados: ${lista.length}');
            _onFontePronta('territorios');
          },
        ),
      );

      _subscriptions.add(
        _localizacao.observarCategoriasFornecedor().listen((lista) {
          _relacoesRaw.assignAll(lista);
          _onFontePronta('relacoes');
        }),
      );

      _subscriptions.add(
        _localizacao.observarMediasAvaliacoes().listen((medias) {
          mediasAvaliacoes.assignAll(medias);
          debugPrint('✅ Avaliações carregadas: ${medias.length}');
          if (_dadosCarregados) _atualizarListasPorTipo();
        }),
      );
    } catch (e, s) {
      carregando.value = false;
      debugPrint('❌ Erro na escuta reativa: $e\n$s');
    }
  }

  void _onFontePronta(String fonte) {
    _fontesProntas.add(fonte);
    if (_fontesProntas.containsAll(
        const {'categorias', 'fornecedores', 'territorios', 'relacoes'})) {
      _dadosCarregados = true;
    }
    _agendarReconstrucao();
  }

  void _agendarReconstrucao() {
    _reconstrucaoDebounce?.cancel();
    _reconstrucaoDebounce = Timer(const Duration(milliseconds: 80), () {
      _reconstruirLista();
      if (_dadosCarregados) {
        carregando.value = false;
      }
    });
  }

  // ==========================================================
  // === RECONSTRUÇÃO DE LISTAS DETALHADAS
  // ==========================================================
  void _reconstruirLista() {
    if (_fornecedoresRaw.isEmpty ||
        categorias.isEmpty ||
        territoriosFornecedores.isEmpty) {
      return;
    }
    final userLat = userLatitude.value;
    final userLon = userLongitude.value;

    final relacoesPorFornecedor = <String, List<FornecedorCategoriaModel>>{};
    for (final r in _relacoesRaw) {
      relacoesPorFornecedor.putIfAbsent(r.idFornecedor, () => []).add(r);
    }

    final categoriaPorId = {for (var c in categorias) c.id: c.nome};
    final territorioPorFornecedor = {
      for (var t in territoriosFornecedores) t.idFornecedor.trim(): t
    };

    final List<FornecedorDetalhadoDto> listaDetalhada = [];

    for (final f in _fornecedoresRaw) {
      final relacoesFornecedor = relacoesPorFornecedor[f.idFornecedor] ?? [];
      if (relacoesFornecedor.isEmpty) continue;

      final nomeCategoria = relacoesFornecedor
          .map((r) => categoriaPorId[r.idCategoria])
          .whereType<String>()
          .toSet()
          .join(', ');

      if (nomeCategoria.isEmpty) continue;

      final territorio = territorioPorFornecedor[f.idFornecedor.trim()];
      double? distanciaKm;
      if (territorio != null) {
        if (territorio.tipoCobertura == 'raio' &&
            territorio.latitude != null &&
            territorio.longitude != null) {
          // 🔹 Cálculo padrão de distância
          distanciaKm = _calcularDistancia(
            userLat,
            userLon,
            territorio.latitude!,
            territorio.longitude!,
          );
        } else if (territorio.tipoCobertura == 'regiao' &&
            territorio.regioes != null &&
            territorio.regioes!.isNotEmpty) {
          final dentro =
              _pontoDentroDaRegiao(userLat, userLon, territorio.regioes!);

          if (dentro) {
            distanciaKm = 0.0;
          } else {
            distanciaKm =
                _distanciaAteRegiao(userLat, userLon, territorio.regioes!);
          }
        }
      }

      listaDetalhada.add(
        FornecedorDetalhadoDto(
          fornecedor: f,
          categoriaNome: nomeCategoria,
          categoriaId: relacoesFornecedor.first.idCategoria,
          territorio: territorio,
          distanciaKm: distanciaKm,
        ),
      );
    }

    fornecedores.assignAll(listaDetalhada);
    _filtrarPorRaio();
    _atualizarListasPorTipo();
  }

  Future<void> escutarServicosFornecedor(String idFornecedor) async {
    carregandoServicosFornecedor.value = true;
    try {
      final sub =
          _localizacao.observarServicosFornecedor(idFornecedor).listen((lista) {
        servicosFornecedor.assignAll(lista);
        carregandoServicosFornecedor.value = false;
      });
      _subscriptions.add(sub);
    } catch (e, s) {
      carregandoServicosFornecedor.value = false;
      debugPrint(
          '❌ [FornecedorController] Erro ao escutar serviços fornecedor: $e\n$s');
    }
  }

  Future<void> escutarTodosServicos() async {
    if (_escutaServicosAtiva) return;
    _escutaServicosAtiva = true;
    carregandoServicosFornecedor.value = true;
    try {
      _subscriptions.add(
        _localizacao.observarTodosServicos().listen((lista) {
          allService.assignAll(lista);
          carregandoServicosFornecedor.value = false;
        }),
      );
    } catch (e, s) {
      _escutaServicosAtiva = false;
      carregandoServicosFornecedor.value = false;
      debugPrint(
          '❌ [FornecedorController] Erro ao escutar serviços fornecedor: $e\n$s');
    }
  }

  Future<List<FornecedorServicoDetalhadoDto>> escutarTodosServicosDoFornecedor(
      String idFornecedor) async {
    carregandoServicosFornecedor.value = true;

    try {
      allService.clear();
      final lista =
          await _localizacao.listarTodosServicosDoFornecedor(idFornecedor);
      return lista;
    } catch (e, s) {
      debugPrint(
          '❌ [FornecedorController] Erro ao escutar serviços fornecedor: $e\n$s');
      return <FornecedorServicoDetalhadoDto>[];
    } finally {
      carregandoServicosFornecedor.value = false;
    }
  }

  Future<void> buscarServicosPorCategoria(String idCategoria) async {
    try {
      carregandoServicosFornecedor.value = true;
      servicosPorCategoria.clear();
      final lista = await _localizacao.listarServicosPorCategoria(idCategoria);
      servicosPorCategoria.assignAll(lista);
    } catch (e) {
      debugPrint('Erro ao buscar serviços por categoria: $e');
      servicosFornecedor.clear();
    } finally {
      carregandoServicosFornecedor.value = false;
    }
  }

  /// 🔹 Busca fornecedores que ainda não possuem categorias vinculadas
  Future<void> buscarFornecedoresSemCategoria() async {
    try {
      carregandoServicosFornecedor.value = true;
      servicosFornecedor.clear();
      final lista = await _localizacao.listarFornecedoresSemCategoria();
      debugPrint('📊 Fornecedores sem categoria: ${lista.length}');
      servicosFornecedor.assignAll(lista);
    } catch (e) {
      debugPrint('❌ Erro ao buscar fornecedores sem categoria: $e');
      servicosFornecedor.clear();
    } finally {
      carregandoServicosFornecedor.value = false;
    }
  }

  bool _pontoDentroDaRegiao(double lat, double lon, List<String> regioes) {
    final pontos = regioes.map((r) {
      final parts = r.split(',');
      return LatLng(double.parse(parts[0]), double.parse(parts[1]));
    }).toList();

    bool dentro = false;
    for (int i = 0, j = pontos.length - 1; i < pontos.length; j = i++) {
      final xi = pontos[i].latitude, yi = pontos[i].longitude;
      final xj = pontos[j].latitude, yj = pontos[j].longitude;

      final intersect = ((yi > lon) != (yj > lon)) &&
          (lat < (xj - xi) * (lon - yi) / ((yj - yi) + 0.0000001) + xi);
      if (intersect) dentro = !dentro;
    }
    return dentro;
  }

  double _distanciaAteRegiao(double lat, double lon, List<String> regioes) {
    final pontos = regioes.map((r) {
      final parts = r.split(',');
      return LatLng(double.parse(parts[0]), double.parse(parts[1]));
    }).toList();

    double menorDistancia = double.infinity;

    for (int i = 0; i < pontos.length; i++) {
      final p1 = pontos[i];
      final p2 = pontos[(i + 1) % pontos.length];

      final distancia = _distanciaPontoParaSegmento(lat, lon, p1, p2);
      if (distancia < menorDistancia) menorDistancia = distancia;
    }

    return menorDistancia;
  }

  /// 🔹 Calcula a distância mínima entre um ponto e um segmento de reta (em km)
  double _distanciaPontoParaSegmento(
      double lat, double lon, LatLng p1, LatLng p2) {
    const r = 6371; // Raio da Terra em km

    // Converter coordenadas para radianos
    final lat1 = p1.latitude * pi / 180;
    final lon1 = p1.longitude * pi / 180;
    final lat2 = p2.latitude * pi / 180;
    final lon2 = p2.longitude * pi / 180;
    final latP = lat * pi / 180;
    final lonP = lon * pi / 180;

    // Vetores
    final a = [cos(lat1) * cos(lon1), cos(lat1) * sin(lon1), sin(lat1)];
    final b = [cos(lat2) * cos(lon2), cos(lat2) * sin(lon2), sin(lat2)];
    final p = [cos(latP) * cos(lonP), cos(latP) * sin(lonP), sin(latP)];

    // Projeção de P sobre o segmento AB
    final ab = [b[0] - a[0], b[1] - a[1], b[2] - a[2]];
    final ap = [p[0] - a[0], p[1] - a[1], p[2] - a[2]];
    final t = (ap[0] * ab[0] + ap[1] * ab[1] + ap[2] * ab[2]) /
        (ab[0] * ab[0] + ab[1] * ab[1] + ab[2] * ab[2]);

    // Clampeia t (para ficar dentro do segmento)
    final tClamped = t.clamp(0.0, 1.0);
    final proj = [
      a[0] + ab[0] * tClamped,
      a[1] + ab[1] * tClamped,
      a[2] + ab[2] * tClamped
    ];

    // Distância entre P e projeção
    final d = acos((p[0] * proj[0] + p[1] * proj[1] + p[2] * proj[2]) /
        (sqrt(p[0] * p[0] + p[1] * p[1] + p[2] * p[2]) *
            sqrt(proj[0] * proj[0] + proj[1] * proj[1] + proj[2] * proj[2])));

    return r * d;
  }

  // ==========================================================
  // === FILTRO POR RAIO
  // ==========================================================
  void _filtrarPorRaio() {
    if (fornecedores.isEmpty) {
      fornecedoresFiltrados.clear();
      return;
    }

    final raioGlobal = raio.value;

    fornecedoresFiltrados.value = fornecedores.where((f) {
      final territorio = f.territorio;
      final distancia = f.distanciaKm;

      if (territorio == null) return false;

      // 🔹 Caso o território seja "região"
      if (territorio.tipoCobertura == 'regiao') {
        // Se estiver dentro da região, sempre exibe
        if (distancia == 0.0) return true;

        // Se estiver fora, mostra se estiver próximo da borda
        return distancia != null && distancia <= raioGlobal;
      }

      // 🔹 Caso o território seja "raio"
      if (territorio.tipoCobertura == 'raio') {
        final raioFornecedor = territorio.raioKm ?? raioGlobal;
        if (distancia == null) return false;
        return distancia <= min(raioGlobal, raioFornecedor);
      }

      return false;
    }).toList();

    debugPrint('✅ Fornecedores filtrados: ${fornecedoresFiltrados.length}');
  }

  // ==========================================================
  // === DISTÂNCIA (Haversine)
  // ==========================================================
  double _calcularDistancia(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371;
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  // ==========================================================
  // === LISTAS DE “PRÓXIMOS” E “DESTAQUES”
  // ==========================================================
  void _atualizarListasPorTipo() {
    if (!_dadosCarregados || fornecedores.isEmpty) return;

    fornecedoresProximos.value = fornecedores.where((f) {
      final t = f.territorio;
      if (t == null) return false;
      if (f.distanciaKm == null) return false;

      // 🔹 Tipo raio → mesma lógica de antes
      if (t.tipoCobertura == 'raio') {
        final limite = (t.raioKm ?? raio.value) + 2.0;
        return f.distanciaKm! <= limite;
      }

      // 🔹 Tipo região → mostrar se dentro da área ou muito próximo
      if (t.tipoCobertura == 'regiao') {
        return f.distanciaKm == 0.0 || (f.distanciaKm ?? 9999) <= raio.value;
      }

      return false;
    }).toList();

    fornecedoresDestaque.value = fornecedores.where((f) {
      final media = mediasAvaliacoes[f.fornecedor.idFornecedor] ?? 0.0;
      return media >= 4.5;
    }).toList();

    debugPrint(
        '📍 Próximos: ${fornecedoresProximos.length} | ⭐ Destaque: ${fornecedoresDestaque.length}');
  }

  // ==========================================================
  // === APOIO
  // ==========================================================
  void atualizarRaio(double novoRaio) {
    raio.value = novoRaio;
    _filtrarPorRaio();
  }

  void removerServico(
      String idProdutoServico, String idFornecedor, String idSubcategoria) {
    servicosFornecedor.removeWhere(
      (sev) =>
          sev.idProdutoServico == idProdutoServico &&
          sev.idFornecedor == idFornecedor &&
          sev.idSubcategoria == idSubcategoria,
    );
  }
}
