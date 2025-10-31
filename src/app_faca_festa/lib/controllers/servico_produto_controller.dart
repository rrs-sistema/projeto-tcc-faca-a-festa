import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import './../data/models/model.dart';

class ServicoProdutoController extends GetxController {
  final _db = FirebaseFirestore.instance;

  final RxList<ServicoProdutoModel> servicos = <ServicoProdutoModel>[].obs;
  final RxList<FornecedorServicoDetalhadoDto> servicosFornecedor =
      <FornecedorServicoDetalhadoDto>[].obs;
  final RxString erro = ''.obs;

  StreamSubscription<QuerySnapshot>? _servicosSubscription;
  StreamSubscription<QuerySnapshot>? _servicosAdminSubscription;

  /// 🔄 Alterna automaticamente o listener por fornecedor
  Timer? _fornecedorTimeoutTimer;

  final RxBool listenerAtivoAdmin = false.obs;
  final RxBool listenerAtivoFornecedor = false.obs;

  final RxBool carregando = false.obs;

  final RxMap<String, List<ServicoProdutoModel>> servicosPorSubcategoria =
      <String, List<ServicoProdutoModel>>{}.obs;

  @override
  void onClose() {
    _servicosAdminSubscription?.cancel();
    _servicosSubscription?.cancel();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    carregarServicos();
    //buscarServicosComCategoriaESubcategoria();
  }

  Future<List<ServicoProdutoModel>> carregarServicosPorSubcategoria(String idSubcategoria) async {
    try {
      carregando.value = true;
      debugPrint('🔹 [SERVIÇOS] Buscando serviços para subcategoria: $idSubcategoria');

      final snap = await _db
          .collection('servico_produto')
          .where('id_subcategoria', isEqualTo: idSubcategoria)
          .where('ativo', isEqualTo: true)
          .get();

      final lista = snap.docs.map((d) {
        return ServicoProdutoModel.fromMap({...d.data(), 'id': d.id});
      }).toList();

      servicosPorSubcategoria[idSubcategoria] = lista;
      servicos.assignAll(lista);

      debugPrint(
          '✅ [SERVIÇOS] ${lista.length} serviços encontrados para subcategoria $idSubcategoria');
      debugPrint('📊 [SERVIÇOS MAP] Chaves atuais: ${servicosPorSubcategoria.keys.toList()}');
      return lista;
    } catch (e) {
      debugPrint('⚠️ [SERVIÇOS] Erro ao carregar serviços da subcategoria $idSubcategoria: $e');
      return [];
    } finally {
      carregando.value = false;
    }
  }

  void limparServicos() {
    servicosPorSubcategoria.clear();
    servicos.clear();
    debugPrint('🧹 [SERVIÇOS] Lista e mapa de serviços limpos.');
    servicosPorSubcategoria.refresh();
  }

  void removerServicosPorSubcategoria(String idSubcategoria) {
    servicosPorSubcategoria.remove(idSubcategoria);
  }

  Future<void> carregarServicos() async {
    try {
      carregando.value = true;
      final snapshot = await _db.collection('servico_produto').get();
      servicos.assignAll(
        snapshot.docs.map((doc) => ServicoProdutoModel.fromMap(doc.data())).toList(),
      );
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao carregar serviços: $e');
    } finally {
      carregando.value = false;
    }
  }

  Future<void> converterServicosComDetalhes(String idFornecedor) async {
    final db = FirebaseFirestore.instance;

    try {
      // 🔹 1. Busca as categorias e subcategorias do fornecedor
      final catSnap = await db
          .collection('fornecedor_categoria')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get();

      if (catSnap.docs.isEmpty) {
        debugPrint('⚠️ Nenhuma categoria encontrada para o fornecedor $idFornecedor');
        servicosFornecedor.clear();
        return;
      }

      // 🔹 2. Monta mapas de subcategorias e categorias
      final Map<String, String> mapaSub = {}; // idSubcategoria → nomeSubcategoria
      final Map<String, String> mapaCat = {}; // idCategoria → nomeCategoria
      final Map<String, String> mapaSubParaCat = {}; // idSubcategoria → idCategoria

      for (var catDoc in catSnap.docs) {
        final data = catDoc.data();
        final idCategoria = data['id_categoria'] ?? '';
        final nomeCategoria = data['nome_categoria'] ?? '';
        mapaCat[idCategoria] = nomeCategoria;

        final subs = (data['subcategorias'] as List?) ?? [];
        for (var sub in subs) {
          final idSub = sub['idSubcategoria'] ?? '';
          final nomeSub = sub['nomeSubcategoria'] ?? '';
          if (idSub.isNotEmpty) {
            mapaSub[idSub] = nomeSub;
            mapaSubParaCat[idSub] = idCategoria;
          }
        }
      }

      // 🔹 3. Cria os DTOs dos serviços detalhados
      final lista = servicos.map((s) {
        final nomeSub = mapaSub[s.idSubcategoria] ?? 'Subcategoria não encontrada';
        final idCat = mapaSubParaCat[s.idSubcategoria];
        final nomeCat = mapaCat[idCat] ?? 'Categoria não encontrada';

        return FornecedorServicoDetalhadoDto(
          id: s.id,
          idFornecedor: idFornecedor,
          idProdutoServico: s.id,
          idSubcategoria: s.idSubcategoria,
          nomeServico: s.nome,
          descricaoServico: s.descricao,
          preco: 0.0,
          precoPromocao: null,
          nomeSubcategoria: nomeSub,
          nomeCategoria: nomeCat,
          imagemUrl: null,
          tipoMedida: s.tipoMedida,
          ativo: s.ativo,
        );
      }).toList();

      // 🔹 4. Atualiza o observable
      servicosFornecedor.assignAll(lista);
    } catch (e, s) {
      debugPrint('❌ Erro ao converter serviços detalhados: $e\n$s');
      servicosFornecedor.clear();
    }
  }

  Future<void> buscarServicosComCategoriaESubcategoria() async {
    //await carregarServicosOtimizado(filtrarPorFornecedor: false);
  }

  Future<void> buscarServicosPorFornecedorLogado(String idFornecedor) async {
    //await carregarServicosOtimizado(filtrarPorFornecedor: true, idFornecedor: idFornecedor);
  }

  Future<void> buscarServicosDoFornecedorPeloAdmin(String idFornecedor) async {
    toggleListenerFornecedor(idFornecedor: idFornecedor);
  }

  void iniciarListenerServicosAdmin() {
    final db = FirebaseFirestore.instance;

    debugPrint('📡 Iniciando listener de serviços (modo ADMIN)...');

    _servicosAdminSubscription?.cancel(); // cancela listener anterior, se existir

    _servicosAdminSubscription = db
        .collection('servico_produto')
        .where('ativo', isEqualTo: true)
        .snapshots()
        .listen((servSnap) async {
      try {
        carregando.value = true;
        erro.value = '';
        servicosFornecedor.clear();

        // ========================
        // 1️⃣ Buscar categorias e subcategorias (uma vez por atualização)
        // ========================
        final catSnap = await db.collection('categoria_servico').get();
        final subSnap = await db.collection('subcategoria_servico').get();

        final Map<String, String> mapaCategorias = {}; // idCategoria → nomeCategoria
        final Map<String, String> mapaSubcategorias = {}; // idSubcategoria → nomeSubcategoria
        final Map<String, String> mapaSubParaCat = {}; // idSubcategoria → idCategoria

        for (final doc in catSnap.docs) {
          final data = doc.data();
          mapaCategorias[doc.id] = data['nome'] ?? 'Sem nome';
        }

        for (final doc in subSnap.docs) {
          final data = doc.data();
          final idCat = data['id_categoria'] ?? '';
          mapaSubcategorias[doc.id] = data['nome'] ?? 'Sem nome';
          mapaSubParaCat[doc.id] = idCat;
        }

        debugPrint(
            '📦 Categorias: ${mapaCategorias.length}, Subcategorias: ${mapaSubcategorias.length}');
        debugPrint('📦 Serviços ativos recebidos: ${servSnap.docs.length}');

        // ========================
        // 2️⃣ Montar lista detalhada
        // ========================
        final List<FornecedorServicoDetalhadoDto> lista = [];

        for (final servDoc in servSnap.docs) {
          final data = servDoc.data();
          final idSub = data['id_subcategoria'] ?? '';
          final idCat = mapaSubParaCat[idSub] ?? '';
          final nomeCat = mapaCategorias[idCat] ?? 'Sem categoria';
          final nomeSub = mapaSubcategorias[idSub] ?? 'Sem subcategoria';

          lista.add(FornecedorServicoDetalhadoDto(
            id: 'admin_${servDoc.id}',
            idFornecedor: '',
            idProdutoServico: servDoc.id,
            idSubcategoria: idSub,
            nomeServico: data['nome'] ?? 'Serviço sem nome',
            descricaoServico: data['descricao'] ?? '',
            tipoMedida: data['tipo_medida'] ?? 'U',
            preco: 0.0,
            precoPromocao: null,
            nomeSubcategoria: nomeSub,
            nomeCategoria: nomeCat,
            imagemUrl: null,
            ativo: data['ativo'] ?? true,
          ));
        }

        servicosFornecedor.assignAll(lista);
        debugPrint('✅ Lista ADMIN atualizada: ${lista.length} serviços.');
      } catch (e, s) {
        erro.value = 'Erro ao carregar serviços (Admin): $e';
        debugPrint('❌ Erro ao atualizar lista ADMIN: $e\n$s');
        servicosFornecedor.clear();
      } finally {
        carregando.value = false;
      }
    });
  }

  void pararListenerServicosAdmin() {
    _servicosAdminSubscription?.cancel();
    _servicosAdminSubscription = null;
    debugPrint('🛑 Listener de serviços ADMIN encerrado.');
  }

  void carregarServicosOtimizado({
    bool filtrarPorFornecedor = false,
    String? idFornecedor,
  }) {
    debugPrint('BUSCANDO SERVIÇO DO FORNECEDOR: $idFornecedor');
    final db = FirebaseFirestore.instance;
    _servicosSubscription?.cancel();

    carregando.value = true;
    erro.value = '';
    servicosFornecedor.clear();

    Query query = db.collection('fornecedor_categoria');
    if (filtrarPorFornecedor && idFornecedor != null) {
      query = query.where('id_fornecedor', isEqualTo: idFornecedor);
      debugPrint('📡 Iniciando listener de categorias do fornecedor: $idFornecedor');
    } else {
      debugPrint('📡 Iniciando listener de TODAS as categorias (modo Admin)');
    }

    _servicosSubscription = query.snapshots().listen((catSnap) async {
      try {
        final docs = catSnap.docs;
        debugPrint('📄 FornecedorCategoria atualizada (${docs.length} docs)');

        if (docs.isEmpty) {
          debugPrint('⚠️ Nenhum vínculo encontrado em fornecedor_categoria para $idFornecedor.');
          servicosFornecedor.clear();
          carregando.value = false;
          return; // ⛔️ Interrompe a execução — não deve abrir listener de servico_produto
        }

        // 1️⃣ Mapear categorias e subcategorias
        final mapaCategorias = <String, String>{};
        final mapaSubcategorias = <String, String>{};
        final mapaSubParaCat = <String, String>{};
        final subcategoriasIds = <String>{};
        subcategoriasIds.clear();

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final idCat = (data['id_categoria'] ?? '').toString();
          final nomeCat = (data['nome_categoria'] ?? 'Sem nome').toString();

          mapaCategorias[idCat] = nomeCat;
          final subs = (data['subcategorias'] as List?) ?? [];

          for (final sub in subs) {
            if (sub is Map<String, dynamic>) {
              final idSub = (sub['idSubcategoria'] ?? '').toString();
              final nomeSub = (sub['nomeSubcategoria'] ?? 'Sem nome').toString();
              if (idSub.isNotEmpty) {
                mapaSubcategorias[idSub] = nomeSub;
                mapaSubParaCat[idSub] = idCat;
                subcategoriasIds.add(idSub);
              }
            }
          }
        }
// Força a conclusão antes de iniciar o próximo listener
        await Future.delayed(const Duration(milliseconds: 50));

        if (subcategoriasIds.isEmpty) {
          debugPrint('⚠️ Nenhuma subcategoria vinculada encontrada.');
          servicosFornecedor.clear();
          return;
        }

        if (subcategoriasIds.isEmpty) {
          debugPrint(
              '⚠️ Nenhuma subcategoria vinculada encontrada para o fornecedor $idFornecedor.');
          servicosFornecedor.clear();
          carregando.value = false;
          return; // ⛔️ Não cria listener desnecessário
        }

        // 2️⃣ Escutar mudanças em servico_produto em tempo real
        db
            .collection('servico_produto')
            .where('id_subcategoria', whereIn: subcategoriasIds.toList())
            .where('ativo', isEqualTo: true)
            .snapshots()
            .listen((servSnap) async {
          try {
            final lista = <FornecedorServicoDetalhadoDto>[];
            final resumoPorCategoria = <String, int>{};

            for (final servDoc in servSnap.docs) {
              final data = servDoc.data();
              final idSub = (data['id_subcategoria'] ?? '').toString();
              final idCat = mapaSubParaCat[idSub] ?? '';
              final nomeCat = mapaCategorias[idCat] ?? 'Sem categoria';
              final nomeSub = mapaSubcategorias[idSub] ?? 'Sem subcategoria';

              resumoPorCategoria[nomeCat] = (resumoPorCategoria[nomeCat] ?? 0) + 1;

              // 🧩 🔹 Se for modo fornecedor, verificar se ele tem vínculo no fornecedor_servico
              if (filtrarPorFornecedor && idFornecedor != null) {
                final vinculoSnap = await db
                    .collection('fornecedor_servico')
                    .where('id_fornecedor', isEqualTo: idFornecedor)
                    .where('id_produto_servico', isEqualTo: servDoc.id)
                    .limit(1)
                    .get();

                if (vinculoSnap.docs.isEmpty) continue; // 🔸 Pula serviços não vinculados
              }

              // Buscar foto principal (opcional)
              String? imagemUrl;
              if (filtrarPorFornecedor && idFornecedor != null) {
                final fotoSnap = await db
                    .collection('servico_foto')
                    .where('id_fornecedor', isEqualTo: idFornecedor)
                    .where('id_produto_servico', isEqualTo: servDoc.id)
                    .limit(1)
                    .get();
                if (fotoSnap.docs.isNotEmpty) {
                  imagemUrl = fotoSnap.docs.first.data()['url'];
                }
              }

              lista.add(FornecedorServicoDetalhadoDto(
                id: servDoc.id,
                idFornecedor: idFornecedor ?? '',
                idProdutoServico: servDoc.id,
                idSubcategoria: idSub,
                nomeServico: data['nome'] ?? 'Serviço sem nome',
                descricaoServico: data['descricao'] ?? '',
                tipoMedida: data['tipo_medida'] ?? 'U',
                preco: 0.0,
                precoPromocao: null,
                nomeSubcategoria: nomeSub,
                nomeCategoria: nomeCat,
                imagemUrl: imagemUrl,
                ativo: data['ativo'] ?? true,
              ));
            }

            servicosFornecedor.assignAll(lista);
            debugPrint(
                '✅ Lista atualizada (${lista.length}) serviços (${filtrarPorFornecedor ? "Fornecedor $idFornecedor" : "Admin"})');
          } catch (e, s) {
            debugPrint('❌ Erro ao atualizar serviços: $e\n$s');
          } finally {
            carregando.value = false;
          }
        });
      } catch (e, s) {
        erro.value = 'Erro no listener: $e';
        debugPrint('❌ Erro no listener de serviços: $e\n$s');
        servicosFornecedor.clear();
      }
    });
  }

  Future<void> _carregarServicos({
    bool filtrarPorFornecedor = false,
    String? idFornecedor,
  }) async {
    try {
      carregando.value = true;
      erro.value = '';
      servicosFornecedor.clear();

      final db = FirebaseFirestore.instance;

      // ========================
      // 1️⃣ Buscar categorias e subcategorias
      // ========================
      Query query = db.collection('fornecedor_categoria');

      if (filtrarPorFornecedor && idFornecedor != null) {
        query = query.where('id_fornecedor', isEqualTo: idFornecedor);
        debugPrint('📡 Buscando categorias do fornecedor: $idFornecedor');
      } else {
        debugPrint('📡 Buscando categorias de TODOS os fornecedores');
      }

      final catSnap = await query.get();

      debugPrint('📄 Documentos encontrados em fornecedor_categoria: ${catSnap.docs.length}');

      if (catSnap.docs.isEmpty) {
        debugPrint(
            '⚠️ Nenhuma categoria encontrada${filtrarPorFornecedor ? " para o fornecedor $idFornecedor" : ""}.');
        servicosFornecedor.clear();
        return;
      }

      // ========================
      // 2️⃣ Mapear categorias, subcategorias e vínculos
      // ========================
      final Map<String, String> mapaCategorias = {}; // idCategoria → nomeCategoria
      final Map<String, String> mapaSubcategorias = {}; // idSubcategoria → nomeSubcategoria
      final Map<String, String> mapaSubParaCat = {}; // idSubcategoria → idCategoria
      final List<String> subcategoriasIds = [];

      for (final doc in catSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final idFornecedorDoc = data['id_fornecedor'];
        final idCat = (data['id_categoria'] ?? '') as String;
        final nomeCat = (data['nome_categoria'] ?? '') as String;

        debugPrint(
            '📦 FornecedorCategoria → fornecedor:$idFornecedorDoc | idCat:$idCat | nomeCat:$nomeCat');

        mapaCategorias[idCat] = nomeCat;

        final subs = (data['subcategorias'] as List?) ?? [];
        debugPrint('   ↳ ${subs.length} subcategorias encontradas para $nomeCat');

        for (final sub in subs) {
          if (sub is Map<String, dynamic>) {
            final idSub = (sub['idSubcategoria'] ?? '') as String;
            final nomeSub = (sub['nomeSubcategoria'] ?? '') as String;
            if (idSub.isNotEmpty) {
              mapaSubcategorias[idSub] = nomeSub;
              mapaSubParaCat[idSub] = idCat;
              subcategoriasIds.add(idSub);
              debugPrint(
                  '      🟢 Subcategoria vinculada → id:$idSub | nome:$nomeSub | cat:$nomeCat');
            }
          }
        }
      }

      debugPrint('📊 Total de subcategorias coletadas: ${subcategoriasIds.length}');

      if (subcategoriasIds.isEmpty) {
        debugPrint('⚠️ Nenhuma subcategoria vinculada encontrada.');
        servicosFornecedor.clear();
        return;
      }

      // ========================
      // 3️⃣ Buscar serviços dessas subcategorias
      // ========================
      debugPrint('📡 Consultando servico_produto com ${subcategoriasIds.length} subcategorias...');
      final servSnap = await db
          .collection('servico_produto')
          .where('id_subcategoria', whereIn: subcategoriasIds)
          .where('ativo', isEqualTo: true)
          .get();

      debugPrint('📄 Serviços encontrados: ${servSnap.docs.length}');

      if (servSnap.docs.isEmpty) {
        debugPrint('⚠️ Nenhum serviço encontrado nas subcategorias vinculadas.');
        servicosFornecedor.clear();
        return;
      }

      // ========================
      // 4️⃣ Montar lista detalhada dos serviços
      // ========================
      final List<FornecedorServicoDetalhadoDto> lista = [];

      for (final servDoc in servSnap.docs) {
        final data = servDoc.data();
        final idSub = data['id_subcategoria'] ?? '';
        final idCat = mapaSubParaCat[idSub] ?? '';
        final nomeCat = mapaCategorias[idCat] ?? 'Sem categoria';
        final nomeSub = mapaSubcategorias[idSub] ?? 'Sem subcategoria';

        // 🔹 Log de vínculo
        debugPrint('🔗 Serviço: ${data['nome']} | sub:$idSub($nomeSub) | cat:$idCat($nomeCat)');

        // 🔹 Buscar imagem principal (opcional)
        String? imagemUrl;
        if (filtrarPorFornecedor && idFornecedor != null) {
          final fotoSnap = await db
              .collection('servico_foto')
              .where('id_fornecedor', isEqualTo: idFornecedor)
              .where('id_produto_servico', isEqualTo: servDoc.id)
              .limit(1)
              .get();

          if (fotoSnap.docs.isNotEmpty) {
            imagemUrl = fotoSnap.docs.first.data()['url'];
            debugPrint('   📸 Foto encontrada para serviço ${data['nome']}');
          }
        }

        lista.add(FornecedorServicoDetalhadoDto(
          id: servDoc.id,
          idFornecedor: idFornecedor ?? '',
          idProdutoServico: servDoc.id,
          idSubcategoria: idSub,
          nomeServico: data['nome'] ?? 'Serviço sem nome',
          descricaoServico: data['descricao'] ?? '',
          tipoMedida: data['tipo_medida'] ?? 'U',
          preco: 0.0,
          precoPromocao: null,
          nomeSubcategoria: nomeSub,
          nomeCategoria: nomeCat,
          imagemUrl: imagemUrl,
          ativo: data['ativo'] ?? true,
        ));
      }

      // ========================
      // 5️⃣ Atualizar lista
      // ========================
      servicosFornecedor.assignAll(lista);

      debugPrint(
          '✅ ${lista.length} serviços carregados (${filtrarPorFornecedor ? "Fornecedor $idFornecedor" : "Admin"}).');
    } catch (e, s) {
      erro.value = 'Erro ao carregar serviços: $e';
      debugPrint('❌ [FornecedorController] Erro ao carregar serviços: $e\n$s');
      servicosFornecedor.clear();
    } finally {
      carregando.value = false;
    }
  }

  ServicoProdutoModel? buscarPorId(String id) {
    return servicos.firstWhereOrNull((s) => s.id == id);
  }

  Future<void> excluirServico(String id) async {
    await _db.collection('servico_produto').doc(id).delete();
    await carregarServicos();
  }

  Future<void> salvarServico(ServicoProdutoModel model) async {
    await _db.collection('servico_produto').doc(model.id).set(model.toMap());
    await carregarServicos();
  }

  /// 🔄 Alterna automaticamente entre iniciar e parar o listener Admin
  Future<void> toggleListenerAdmin() async {
    if (listenerAtivoAdmin.value) {
      // Listener está ativo → parar
      debugPrint('🛑 Parando listener de serviços (Admin)...');
      await _servicosAdminSubscription?.cancel();
      _servicosAdminSubscription = null;
      listenerAtivoAdmin.value = false;
      debugPrint('✅ Listener (Admin) parado.');
    } else {
      // Listener está inativo → iniciar
      debugPrint('▶️ Iniciando listener de serviços (Admin)...');
      iniciarListenerServicosAdmin();
      listenerAtivoAdmin.value = true;
    }
  }

  Future<void> toggleListenerFornecedor({
    required String idFornecedor,
    Duration timeout = const Duration(minutes: 2),
  }) async {
    if (listenerAtivoFornecedor.value) {
      // 🔹 Parar listener manualmente
      debugPrint('🛑 Parando listener do fornecedor $idFornecedor...');
      await _servicosSubscription?.cancel();
      _servicosSubscription = null;
      listenerAtivoFornecedor.value = false;

      // 🔹 Cancela o timer se existir
      _fornecedorTimeoutTimer?.cancel();
      _fornecedorTimeoutTimer = null;

      debugPrint('✅ Listener do fornecedor $idFornecedor parado.');
    } else {
      // 🔹 Iniciar listener
      debugPrint('▶️ Iniciando listener do fornecedor $idFornecedor...');
      carregarServicosOtimizado(filtrarPorFornecedor: true, idFornecedor: idFornecedor);
      listenerAtivoFornecedor.value = true;

      // 🔹 Define o timer de timeout
      _fornecedorTimeoutTimer?.cancel(); // cancela anterior se existir
      _fornecedorTimeoutTimer = Timer(timeout, () async {
        if (listenerAtivoFornecedor.value) {
          debugPrint(
              '⏰ Timeout atingido (${timeout.inSeconds}s): encerrando listener fornecedor $idFornecedor.');
          await _servicosSubscription?.cancel();
          _servicosSubscription = null;
          listenerAtivoFornecedor.value = false;
        }
      });

      debugPrint(
          '⏱️ Listener do fornecedor $idFornecedor com timeout de ${timeout.inMinutes} min iniciado.');
    }
  }
}
