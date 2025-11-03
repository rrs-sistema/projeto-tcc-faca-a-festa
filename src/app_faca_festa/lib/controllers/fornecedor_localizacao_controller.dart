import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:math';

import './../data/models/servico_produto/fornecedor_categoria_model.dart';
import './../data/models/servico_produto/categoria_servico_model.dart';
import './../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import './../data/models/DTO/fornecedor_detalhado_dto.dart';
import './../data/models/model.dart';

class FornecedorLocalizacaoController extends GetxController {
  final db = FirebaseFirestore.instance;

  // Estados reativos
  var userLatitude = 0.0.obs;
  var userLongitude = 0.0.obs;
  var raio = 10.0.obs;
  var avaliacaoMinima = 0.0.obs;
  var carregando = true.obs;
  bool _dadosCarregados = false;

  // Listas brutas (para reatividade)
  final _fornecedoresRaw = <FornecedorModel>[].obs;
  final _relacoesRaw = <FornecedorCategoriaModel>[].obs;
  final territoriosFornecedores = <TerritorioModel>[].obs;

  // Listas principais
  var fornecedores = <FornecedorDetalhadoDto>[].obs;
  var fornecedoresFiltrados = <FornecedorDetalhadoDto>[].obs;
  var categorias = <CategoriaServicoModel>[].obs;
  var servicosFornecedor = <FornecedorServicoDetalhadoDto>[].obs;
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
    raio.value = 25.0; // 25 km de raio
    _obterLocalizacaoUsuario();
    escutarTodosServicos();
    super.onInit();
  }

  // ==========================================================
  // === LOCALIZAÇÃO DO USUÁRIO (com fallback)
  // ==========================================================
  Future<void> _obterLocalizacaoUsuario() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      var permission = await Geolocator.checkPermission();

      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Permissão negada — usando coordenadas padrão (Curitiba).');
        userLatitude.value = -25.43;
        userLongitude.value = -49.27;
        await carregarDados();
        return;
      }

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Permissão de localização ainda negada — fallback ativado.');
        userLatitude.value = -25.43;
        userLongitude.value = -49.27;
        await carregarDados();
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      userLatitude.value = pos.latitude;
      userLongitude.value = pos.longitude;
      debugPrint('📍 Localização obtida: ${pos.latitude}, ${pos.longitude}');
      await carregarDados();
    } catch (e) {
      debugPrint('❌ Erro ao obter localização: $e — fallback (Curitiba).');
      userLatitude.value = -25.43;
      userLongitude.value = -49.27;
      await carregarDados();
    }
  }

  // ==========================================================
  // === CARGA PRINCIPAL (streams reativas)
  // ==========================================================
  Future<void> carregarDados() async {
    carregando.value = true;
    try {
      // Categorias
      db
          .collection('categoria_servico')
          .where('ativo', isEqualTo: true)
          .snapshots()
          .listen((snapshot) {
        categorias.assignAll(snapshot.docs.map((d) {
          return CategoriaServicoModel.fromMap({'id': d.id, ...d.data()});
        }).toList());
        _reconstruirLista();
        _tentarMarcarComoPronto();
      });

      // Fornecedores
      db.collection('fornecedor').where('ativo', isEqualTo: true).snapshots().listen((snapshot) {
        final lista = snapshot.docs.map((d) {
          return FornecedorModel.fromMap(d.data(), documentId: d.id);
        }).toList();
        _fornecedoresRaw.assignAll(lista);
        debugPrint('✅ Fornecedores carregados: ${lista.length}');
        _reconstruirLista();
        _tentarMarcarComoPronto();
      });

      // Territórios
      db.collection('territorio').where('ativo', isEqualTo: true).snapshots().listen((snapshot) {
        final lista = snapshot.docs.map((d) => TerritorioModel.fromMap(d.data())).toList();
        territoriosFornecedores.assignAll(lista);
        debugPrint('✅ Territórios carregados: ${lista.length}');
        _reconstruirLista();
        _tentarMarcarComoPronto();
      });

      // Relações fornecedor ↔ categoria
      db.collection('fornecedor_categoria').snapshots().listen((snapshot) {
        final lista = snapshot.docs.map((d) => FornecedorCategoriaModel.fromMap(d.data())).toList();
        _relacoesRaw.assignAll(lista);
        _reconstruirLista();
        _tentarMarcarComoPronto();
      });

      // Avaliações
      db.collection('avaliacoes').snapshots().listen((snapshot) {
        final Map<String, List<int>> notasPorFornecedor = {};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final idFornecedor = data['id_fornecedor'] ?? '';
          if (idFornecedor.isEmpty) continue;
          notasPorFornecedor.putIfAbsent(idFornecedor, () => []).add((data['nota'] ?? 0).toInt());
        }

        final Map<String, double> medias = {};
        notasPorFornecedor.forEach((id, notas) {
          final media = notas.reduce((a, b) => a + b) / notas.length;
          medias[id] = double.parse(media.toStringAsFixed(2));
        });

        mediasAvaliacoes.assignAll(medias);
        debugPrint('✅ Avaliações carregadas: ${medias.length}');
        if (_dadosCarregados) _atualizarListasPorTipo();
      });
    } catch (e, s) {
      debugPrint('❌ Erro na escuta reativa: $e\n$s');
    } finally {
      carregando.value = false;
    }
  }

  // ==========================================================
  // === MARCA DADOS COMO PRONTOS
  // ==========================================================
  void _tentarMarcarComoPronto() {
    if (!_dadosCarregados &&
        _fornecedoresRaw.isNotEmpty &&
        territoriosFornecedores.isNotEmpty &&
        categorias.isNotEmpty) {
      _dadosCarregados = true;

      // Validação de correspondência fornecedor ↔ território
      debugPrint('🔍 Validando correspondência fornecedor ↔ território');
      for (var t in territoriosFornecedores) {
        final match = _fornecedoresRaw.firstWhereOrNull(
          (f) => f.idFornecedor.trim() == t.idFornecedor.trim(),
        );
        if (match != null) {
          debugPrint('✅ MATCH → ${match.razaoSocial} | ${t.idFornecedor}');
        } else {
          debugPrint('⚠️ SEM MATCH → ${t.idFornecedor}');
        }
      }

      debugPrint('✅ Dados prontos — reconstruindo listas finais...');
      _reconstruirLista();
      _atualizarListasPorTipo();
    }
  }

  // ==========================================================
  // === RECONSTRUÇÃO DE LISTAS DETALHADAS
  // ==========================================================
  void _reconstruirLista() {
    if (_fornecedoresRaw.isEmpty || categorias.isEmpty || territoriosFornecedores.isEmpty) return;

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

      if (territorio?.latitude != null && territorio?.longitude != null) {
        final userLat = userLatitude.value;
        final userLon = userLongitude.value;
        final lat2 = territorio!.latitude!;
        final lon2 = territorio.longitude!;

        distanciaKm = _calcularDistancia(userLat, userLon, lat2, lon2);
        debugPrint(
            '📏 ${f.razaoSocial} → Distância: ${distanciaKm.toStringAsFixed(2)} km | Território: ($lat2, $lon2)');
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
    final db = FirebaseFirestore.instance;
    try {
      db
          .collection('fornecedor_categoria')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .snapshots()
          .listen((snapshot) async {
        List<FornecedorServicoDetalhadoDto> lista = [];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final nomeCategoria = data['nome_categoria'] ?? '';
          final subcategorias = (data['subcategorias'] as List?) ?? [];
          for (final sub in subcategorias) {
            final idSub = sub['idSubcategoria'];
            final nomeSub = sub['nomeSubcategoria'] ?? 'Sem subcategoria';
            if (idSub == null || idSub.isEmpty) continue;
            final servSnap = await db
                .collection('servico_produto')
                .where('id_subcategoria', isEqualTo: idSub)
                .where('ativo', isEqualTo: true)
                .get();
            for (final servDoc in servSnap.docs) {
              final servData = servDoc.data();
              final fotoSnap = await db
                  .collection('servico_foto')
                  .where('id_fornecedor', isEqualTo: idFornecedor)
                  .where('id_produto_servico', isEqualTo: servDoc.id)
                  .limit(1)
                  .get();
              final imagemUrl =
                  fotoSnap.docs.isNotEmpty ? fotoSnap.docs.first.data()['url'] as String? : null;
              lista.add(FornecedorServicoDetalhadoDto(
                id: '${idFornecedor}_${servDoc.id}',
                idFornecedor: idFornecedor,
                idProdutoServico: servDoc.id,
                idSubcategoria: idSub,
                nomeServico: servData['nome'],
                descricaoServico: servData['descricao'],
                preco: (servData['preco'] as num?)?.toDouble() ?? 0.0,
                precoPromocao: (servData['preco_promocao'] as num?)?.toDouble(),
                nomeSubcategoria: nomeSub,
                nomeCategoria: nomeCategoria,
                imagemUrl: imagemUrl,
                ativo: servData['ativo'] ?? true,
              ));
            }
          }
        }
        servicosFornecedor.assignAll(lista);
        carregandoServicosFornecedor.value = false;
      });
    } catch (e, s) {
      carregandoServicosFornecedor.value = false;
      debugPrint('❌ [FornecedorController] Erro ao escutar serviços fornecedor: $e\n$s');
    }
  }

  Future<void> escutarTodosServicos() async {
    carregandoServicosFornecedor.value = true;
    final db = FirebaseFirestore.instance;
    try {
      allService.clear();
      db.collection('fornecedor_categoria').snapshots().listen((snapshot) async {
        List<FornecedorServicoDetalhadoDto> lista = [];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final nomeCategoria = data['nome_categoria'] ?? '';
          final subcategorias = (data['subcategorias'] as List?) ?? [];
          for (final sub in subcategorias) {
            final idSub = sub['idSubcategoria'];
            final nomeSub = sub['nomeSubcategoria'] ?? 'Sem subcategoria';
            if (idSub == null || idSub.isEmpty) continue;
            final servSnap = await db
                .collection('servico_produto')
                .where('id_subcategoria', isEqualTo: idSub)
                .where('ativo', isEqualTo: true)
                .get();
            for (final servDoc in servSnap.docs) {
              final servData = servDoc.data();
              final fotoSnap = await db
                  .collection('servico_foto')
                  .where('id_produto_servico', isEqualTo: servDoc.id)
                  .limit(1)
                  .get();
              final imagemUrl =
                  fotoSnap.docs.isNotEmpty ? fotoSnap.docs.first.data()['url'] as String? : null;
              lista.add(FornecedorServicoDetalhadoDto(
                id: servDoc.id,
                idFornecedor: '',
                idProdutoServico: servDoc.id,
                idSubcategoria: idSub,
                nomeServico: servData['nome'],
                descricaoServico: servData['descricao'],
                preco: (servData['preco'] as num?)?.toDouble() ?? 0.0,
                precoPromocao: (servData['preco_promocao'] as num?)?.toDouble(),
                nomeSubcategoria: nomeSub,
                nomeCategoria: nomeCategoria,
                imagemUrl: imagemUrl,
                ativo: servData['ativo'] ?? true,
              ));
            }
          }
        }
        allService.assignAll(lista);
      });
    } catch (e, s) {
      debugPrint('❌ [FornecedorController] Erro ao escutar serviços fornecedor: $e\n$s');
    }
  }

  Future<void> buscarServicosPorCategoria(String idCategoria) async {
    try {
      carregandoServicosFornecedor.value = true;
      final db = FirebaseFirestore.instance;
      servicosFornecedor.clear();
      final subSnap = await db
          .collection('subcategoria_servico')
          .where('id_categoria', isEqualTo: idCategoria)
          .get();
      final subIds = subSnap.docs.map((d) => d.id).toList();
      if (subIds.isEmpty) {
        servicosFornecedor.clear();
        carregandoServicosFornecedor.value = false;
        return;
      }
      final fornServSnap =
          await db.collection('fornecedor_servico').where('id_subcategoria', whereIn: subIds).get();
      List<FornecedorServicoDetalhadoDto> lista = [];
      for (final doc in fornServSnap.docs) {
        final data = doc.data();
        final idSubcategoria = data['id_subcategoria'];
        final idProdutoServico = data['id_produto_servico'];
        final idFornecedor = data['id_fornecedor'];
        final servicoSnap = await db.collection('servico_produto').doc(idProdutoServico).get();
        final servicoData = servicoSnap.data();
        String? nomeSubcategoria;
        if (idSubcategoria != null && idSubcategoria.isNotEmpty) {
          final subData = subSnap.docs.firstWhere((s) => s.id == idSubcategoria).data();
          nomeSubcategoria = subData['nome'];
        }
        final catSnap = await db.collection('categoria_servico').doc(idCategoria).get();
        final nomeCategoria = catSnap.data()?['nome'];
        final fotoSnap = await db
            .collection('servico_foto')
            .where('id_fornecedor', isEqualTo: idFornecedor)
            .where('id_produto_servico', isEqualTo: idProdutoServico)
            .limit(1)
            .get();
        final imagemUrl =
            fotoSnap.docs.isNotEmpty ? fotoSnap.docs.first.data()['url'] as String? : null;
        lista.add(FornecedorServicoDetalhadoDto(
            id: doc.id,
            idFornecedor: idFornecedor,
            idProdutoServico: idProdutoServico,
            idSubcategoria: idSubcategoria,
            nomeServico: servicoData?['nome'],
            descricaoServico: servicoData?['descricao'],
            preco: (data['preco'] as num?)?.toDouble() ?? 0.0,
            precoPromocao: (data['preco_promocao'] as num?)?.toDouble(),
            nomeSubcategoria: nomeSubcategoria,
            nomeCategoria: nomeCategoria,
            imagemUrl: imagemUrl,
            ativo: true));
      }
      servicosFornecedor.assignAll(lista);
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
      final db = FirebaseFirestore.instance;
      servicosFornecedor.clear();

      // 1️⃣ Buscar todos os fornecedores ativos
      final fornecedoresSnap =
          await db.collection('fornecedor').where('ativo', isEqualTo: true).get();

      final todosFornecedores = fornecedoresSnap.docs.map((d) => d.id).toList();

      if (todosFornecedores.isEmpty) {
        debugPrint('⚠️ Nenhum fornecedor ativo encontrado.');
        carregandoServicosFornecedor.value = false;
        return;
      }

      // 2️⃣ Buscar fornecedores que já têm vínculos em fornecedor_categoria
      final vinculosSnap = await db.collection('fornecedor_categoria').get();
      final fornecedoresComCategoria =
          vinculosSnap.docs.map((d) => d.data()['id_fornecedor'] as String).toSet();

      // 3️⃣ Filtrar os que NÃO possuem vínculo
      final fornecedoresSemCategoria =
          todosFornecedores.where((id) => !fornecedoresComCategoria.contains(id)).toList();

      debugPrint('📊 Fornecedores sem categoria: ${fornecedoresSemCategoria.length}');

      // 4️⃣ Montar a lista detalhada com informações do fornecedor
      List<FornecedorServicoDetalhadoDto> lista = [];

      for (final idFornecedor in fornecedoresSemCategoria) {
        final fornSnap = await db.collection('fornecedor').doc(idFornecedor).get();
        final fornData = fornSnap.data();

        if (fornData == null) continue;

        final bannerUrl = fornData['bannerUrl'];
        final nomeFornecedor = fornData['nome'] ?? 'Fornecedor sem nome';
        final descricaoFornecedor = fornData['descricao'] ??
            'Fornecedor parceiro do Faça a Festa — aguardando cadastro de categorias.';
        final cidade = fornData['cidade'] ?? '';

        lista.add(FornecedorServicoDetalhadoDto(
          id: idFornecedor,
          idFornecedor: idFornecedor,
          idProdutoServico: '',
          idSubcategoria: null,
          nomeServico: 'Sem serviços vinculados',
          descricaoServico: descricaoFornecedor,
          preco: 0.0,
          precoPromocao: null,
          nomeSubcategoria: null,
          nomeCategoria: 'Sem categoria',
          imagemUrl: bannerUrl,
          ativo: true,
        ));

        debugPrint('✅ Fornecedor sem categoria: $nomeFornecedor ($cidade)');
      }

      servicosFornecedor.assignAll(lista);
    } catch (e) {
      debugPrint('❌ Erro ao buscar fornecedores sem categoria: $e');
      servicosFornecedor.clear();
    } finally {
      carregandoServicosFornecedor.value = false;
    }
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
      final distancia = f.distanciaKm;
      final raioFornecedor = f.territorio?.raioKm ?? 999;
      if (distancia == null) return false;
      final limite = min(raioGlobal, raioFornecedor);
      return distancia <= limite;
    }).toList();
  }

  // ==========================================================
  // === DISTÂNCIA (Haversine)
  // ==========================================================
  double _calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  // ==========================================================
  // === LISTAS DE “PRÓXIMOS” E “DESTAQUES”
  // ==========================================================
  void _atualizarListasPorTipo() {
    if (!_dadosCarregados || fornecedores.isEmpty) return;

    fornecedoresProximos.value = fornecedores.where((f) {
      final t = f.territorio;
      if (t?.latitude == null || t?.longitude == null) return false;
      if (f.distanciaKm == null) return false;

      final limite = (t?.raioKm ?? raio.value) + 2.0; // ✅ tolerância + raio do território
      return f.distanciaKm! <= limite;
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
}
