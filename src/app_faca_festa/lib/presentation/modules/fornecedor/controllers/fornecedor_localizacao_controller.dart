import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:app_faca_festa/domain/entities/categoria_servico.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_detalhado.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_servico_detalhado.dart';
import 'package:app_faca_festa/domain/entities/territorio.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedor_localizacao.dart';

class FornecedorLocalizacaoController extends GetxController {
  FornecedorLocalizacaoController({
    required GerenciarFornecedorLocalizacao localizacao,
  }) : _localizacao = localizacao;

  final GerenciarFornecedorLocalizacao _localizacao;

  var avaliacaoMinima = 0.0.obs;
  bool _dadosCarregados = false;
  bool _escutasAtivas = false;
  bool _escutaServicosAtiva = false;
  bool _inicializando = false;
  int _tentativasAuth = 0;
  final Set<String> _fontesProntas = <String>{};
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _reconstrucaoDebounce;
  Timer? _loadingTimeout;

  var userLongitude = 0.0.obs;
  var userLatitude = 0.0.obs;
  var carregando = true.obs;
  var raio = 10.0.obs;

  // Listas brutas (para reatividade)
  final _fornecedoresRaw = <Fornecedor>[].obs;
  final _relacoesRaw = <FornecedorCategoria>[].obs;
  final territoriosFornecedores = <Territorio>[].obs;

  // Listas principais
  var fornecedores = <FornecedorDetalhado>[].obs;
  var fornecedoresFiltrados = <FornecedorDetalhado>[].obs;
  var categorias = <CategoriaServico>[].obs;
  var servicosFornecedor = <FornecedorServicoDetalhado>[].obs;
  var servicosPorCategoria = <FornecedorServicoDetalhado>[].obs;
  var allService = <FornecedorServicoDetalhado>[].obs;
  var carregandoServicosFornecedor = false.obs;
  final RxnString servicoSelecionadoId = RxnString();

  // Listas auxiliares
  var fornecedoresProximos = <FornecedorDetalhado>[].obs;
  var fornecedoresDestaque = <FornecedorDetalhado>[].obs;

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
    _loadingTimeout?.cancel();
    _loadingTimeout = null;
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _escutasAtivas = false;
    _escutaServicosAtiva = false;
    _dadosCarregados = false;
    _fontesProntas.clear();
  }

  /// Carga única de GPS + streams. Reentradas na tela não disparam de novo.
  Future<void> inicializar({bool forcarLocalizacao = false}) async {
    if (_inicializando) return;
    if (_escutasAtivas && _dadosCarregados && !forcarLocalizacao) return;

    _inicializando = true;
    try {
      if (!_usuarioAutenticado) {
        carregando.value = false;
        debugPrint(
          '⏭️ Localização de fornecedores ignorada: usuário não autenticado.',
        );
        return;
      }

      if (forcarLocalizacao && _escutasAtivas) {
        await encerrarEscutas();
      }

      carregando.value = true;
      await Future.wait<void>([
        _obterLocalizacaoUsuario(forcar: forcarLocalizacao).timeout(
          const Duration(seconds: 6),
          onTimeout: () {
            if (userLatitude.value == 0.0 && userLongitude.value == 0.0) {
              _aplicarFallbackCuritiba();
            }
          },
        ),
        carregarDados(),
      ]);
      _reconstruirLista();
      if (_dadosCarregados) {
        carregando.value = false;
      }
    } catch (e, s) {
      debugPrint('❌ Falha ao inicializar fornecedores: $e\n$s');
      carregando.value = false;
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

      final lastKnown = await Geolocator.getLastKnownPosition().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
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

  bool get _usuarioAutenticado {
    if (!Get.isRegistered<AutenticacaoRepository>()) return false;
    return Get.find<AutenticacaoRepository>().idUsuarioAtual != null;
  }

  void _onErroEscuta(String fonte, Object e, StackTrace s) {
    debugPrint('❌ Escuta "$fonte" falhou: $e\n$s');
    _onFontePronta(fonte);
    final mensagem = e.toString();
    final semPermissao = mensagem.contains('permission-denied') ||
        mensagem.contains('PERMISSION_DENIED') ||
        mensagem.contains('Missing or insufficient permissions');
    if (!semPermissao) return;

    _escutasAtivas = false;
    if (_tentativasAuth >= 3) {
      carregando.value = false;
      return;
    }
    _tentativasAuth++;
    Future<void>.delayed(const Duration(seconds: 1), () async {
      if (isClosed || _escutasAtivas || !_usuarioAutenticado) return;
      await encerrarEscutas();
      unawaited(inicializar());
    });
  }

  // ==========================================================
  // === CARGA PRINCIPAL (streams reativas)
  // ==========================================================
  Future<void> carregarDados() async {
    if (_escutasAtivas) return;

    // fornecedor / territorio / fornecedor_categoria / avaliacoes exigem signedIn.
    if (!_usuarioAutenticado) {
      carregando.value = false;
      debugPrint(
        '⏭️ Escutas de localização ignoradas: usuário não autenticado.',
      );
      return;
    }

    _escutasAtivas = true;
    carregando.value = true;
    _iniciarTimeoutCarregamento();

    try {
      _subscriptions.add(
        _localizacao.observarCategoriasAtivas().listen(
          (lista) {
            categorias.assignAll(lista);
            _onFontePronta('categorias');
          },
          onError: (Object e, StackTrace s) =>
              _onErroEscuta('categorias', e, s),
        ),
      );

      _subscriptions.add(
        _localizacao.observarFornecedoresAtivos().listen(
          (lista) {
            _fornecedoresRaw.assignAll(lista);
            debugPrint('✅ Fornecedores carregados: ${lista.length}');
            _onFontePronta('fornecedores');
          },
          onError: (Object e, StackTrace s) =>
              _onErroEscuta('fornecedores', e, s),
        ),
      );

      _subscriptions.add(
        _localizacao.observarTerritoriosAtivos().listen(
          (lista) {
            territoriosFornecedores.assignAll(lista);
            debugPrint('✅ Territórios carregados: ${lista.length}');
            _onFontePronta('territorios');
          },
          onError: (Object e, StackTrace s) =>
              _onErroEscuta('territorios', e, s),
        ),
      );

      _subscriptions.add(
        _localizacao.observarCategoriasFornecedor().listen(
          (lista) {
            _relacoesRaw.assignAll(lista);
            _onFontePronta('relacoes');
          },
          onError: (Object e, StackTrace s) =>
              _onErroEscuta('relacoes', e, s),
        ),
      );

      _subscriptions.add(
        _localizacao.observarMediasAvaliacoes().listen(
          (medias) {
            mediasAvaliacoes.assignAll(medias);
            debugPrint('✅ Avaliações carregadas: ${medias.length}');
            if (_dadosCarregados) _atualizarListasPorTipo();
          },
          onError: (Object e, StackTrace s) =>
              _onErroEscuta('avaliacoes', e, s),
        ),
      );
    } catch (e, s) {
      _escutasAtivas = false;
      carregando.value = false;
      debugPrint('❌ Erro na escuta reativa: $e\n$s');
    }
  }

  void _iniciarTimeoutCarregamento() {
    _loadingTimeout?.cancel();
    _loadingTimeout = Timer(const Duration(seconds: 8), () {
      if (!carregando.value) return;
      debugPrint(
        '⏰ Timeout ao carregar fornecedores. Fontes prontas: $_fontesProntas',
      );
      _dadosCarregados = true;
      _reconstruirLista();
      carregando.value = false;
    });
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
        _loadingTimeout?.cancel();
        carregando.value = false;
      }
    });
  }

  // ==========================================================
  // === RECONSTRUÇÃO DE LISTAS DETALHADAS
  // ==========================================================
  void _reconstruirLista() {
    if (_fornecedoresRaw.isEmpty) {
      fornecedores.clear();
      fornecedoresFiltrados.clear();
      fornecedoresProximos.clear();
      return;
    }

    try {
      final userLat = userLatitude.value;
      final userLon = userLongitude.value;

      final relacoesPorFornecedor = <String, List<FornecedorCategoria>>{};
      for (final r in _relacoesRaw) {
        relacoesPorFornecedor.putIfAbsent(r.idFornecedor, () => []).add(r);
      }

      final categoriaPorId = {for (var c in categorias) c.id: c.nome};
      final territorioPorFornecedor = {
        for (var t in territoriosFornecedores) t.idFornecedor.trim(): t
      };

      final List<FornecedorDetalhado> listaDetalhada = [];

      for (final f in _fornecedoresRaw) {
        try {
          final relacoesFornecedor =
              relacoesPorFornecedor[f.idFornecedor] ?? [];
          final nomesCategoria = relacoesFornecedor
              .map((r) => categoriaPorId[r.idCategoria])
              .whereType<String>()
              .toSet();
          if (nomesCategoria.isEmpty && f.categorias.isNotEmpty) {
            nomesCategoria.addAll(
              f.categorias
                  .map((c) => c.nomeCategoria.trim())
                  .where((nome) => nome.isNotEmpty),
            );
          }
          final nomeCategoria = nomesCategoria.join(', ');

          final territorio = territorioPorFornecedor[f.idFornecedor.trim()];
          listaDetalhada.add(
            FornecedorDetalhado(
              fornecedor: f,
              categoriaNome: nomeCategoria,
              categoriaId: relacoesFornecedor.isNotEmpty
                  ? relacoesFornecedor.first.idCategoria
                  : (f.categorias.isNotEmpty
                      ? f.categorias.first.idCategoria
                      : ''),
              territorio: territorio,
              distanciaKm: territorio == null
                  ? null
                  : _distanciaDoTerritorio(userLat, userLon, territorio),
            ),
          );
        } catch (e, s) {
          debugPrint(
            '⚠️ Fornecedor ${f.idFornecedor} ignorado na vitrine: $e\n$s',
          );
        }
      }

      fornecedores.assignAll(listaDetalhada);
      _filtrarPorRaio();
      _atualizarListasPorTipo();
    } catch (e, s) {
      debugPrint('❌ Falha ao reconstruir vitrine de fornecedores: $e\n$s');
    }
  }

  double? _distanciaDoTerritorio(
    double userLat,
    double userLon,
    Territorio territorio,
  ) {
    if (territorio.tipoCobertura == 'raio' &&
        territorio.latitude != null &&
        territorio.longitude != null) {
      return _calcularDistancia(
        userLat,
        userLon,
        territorio.latitude!,
        territorio.longitude!,
      );
    }
    if (territorio.tipoCobertura == 'regiao' &&
        territorio.regioes != null &&
        territorio.regioes!.isNotEmpty) {
      final pontos = _pontosDaRegiao(territorio.regioes!);
      if (pontos.isEmpty) return null;
      if (_pontoDentroDaRegiao(userLat, userLon, pontos)) return 0.0;
      return _distanciaAteRegiao(userLat, userLon, pontos);
    }
    if (territorio.latitude != null && territorio.longitude != null) {
      return _calcularDistancia(
        userLat,
        userLon,
        territorio.latitude!,
        territorio.longitude!,
      );
    }
    return null;
  }

  Future<void> escutarServicosFornecedor(String idFornecedor) async {
    if (!_usuarioAutenticado) {
      carregandoServicosFornecedor.value = false;
      return;
    }
    carregandoServicosFornecedor.value = true;
    try {
      final sub = _localizacao.observarServicosFornecedor(idFornecedor).listen(
        (lista) {
          servicosFornecedor.assignAll(lista);
          carregandoServicosFornecedor.value = false;
        },
        onError: (Object e, StackTrace s) {
          carregandoServicosFornecedor.value = false;
          _onErroEscuta('servicos_fornecedor', e, s);
        },
        cancelOnError: true,
      );
      _subscriptions.add(sub);
    } catch (e, s) {
      carregandoServicosFornecedor.value = false;
      debugPrint(
          '❌ [FornecedorController] Erro ao escutar serviços fornecedor: $e\n$s');
    }
  }

  Future<void> escutarTodosServicos() async {
    if (_escutaServicosAtiva) return;
    if (!_usuarioAutenticado) {
      carregandoServicosFornecedor.value = false;
      return;
    }
    _escutaServicosAtiva = true;
    carregandoServicosFornecedor.value = true;
    try {
      _subscriptions.add(
        _localizacao.observarTodosServicos().listen(
          (lista) {
            allService.assignAll(lista);
            carregandoServicosFornecedor.value = false;
          },
          onError: (Object e, StackTrace s) {
            _escutaServicosAtiva = false;
            carregandoServicosFornecedor.value = false;
            _onErroEscuta('todos_servicos', e, s);
          },
          cancelOnError: true,
        ),
      );
    } catch (e, s) {
      _escutaServicosAtiva = false;
      carregandoServicosFornecedor.value = false;
      debugPrint(
          '❌ [FornecedorController] Erro ao escutar serviços fornecedor: $e\n$s');
    }
  }

  Future<List<FornecedorServicoDetalhado>> escutarTodosServicosDoFornecedor(
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
      return <FornecedorServicoDetalhado>[];
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

  List<LatLng> _pontosDaRegiao(List<String> regioes) {
    final pontos = <LatLng>[];
    for (final r in regioes) {
      final parts = r.split(',');
      if (parts.length < 2) continue;
      final lat = double.tryParse(parts[0].trim());
      final lon = double.tryParse(parts[1].trim());
      if (lat == null || lon == null) continue;
      pontos.add(LatLng(lat, lon));
    }
    return pontos;
  }

  bool _pontoDentroDaRegiao(double lat, double lon, List<LatLng> pontos) {
    if (pontos.length < 3) return false;
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

  double _distanciaAteRegiao(double lat, double lon, List<LatLng> pontos) {
    if (pontos.isEmpty) return double.infinity;
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

      // Sem território cadastrado ainda entra na vitrine (não trava o catálogo).
      if (territorio == null || distancia == null) return true;

      if (territorio.tipoCobertura == 'regiao') {
        if (distancia == 0.0) return true;
        return distancia <= raioGlobal;
      }

      if (territorio.tipoCobertura == 'raio') {
        final raioFornecedor = territorio.raioKm ?? raioGlobal;
        return distancia <= min(raioGlobal, raioFornecedor);
      }

      return true;
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
