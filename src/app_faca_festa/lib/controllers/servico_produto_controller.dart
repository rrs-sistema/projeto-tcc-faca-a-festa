import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
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
  }

  Future<void> escutarServicosFornecedor(String idFornecedor) async {
    debugPrint('📡 Listener FORNECEDOR iniciado → $idFornecedor');

    await _servicosSubscription?.cancel();

    _servicosSubscription = _db
        .collection('fornecedor_servico')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .snapshots()
        .listen((snapshot) async {
      debugPrint('♻️ Detectada mudança REAL-TIME → recarregando...');
      await carregarServicosComDetalhesOtimizado(idFornecedor: idFornecedor);
    });
  }

  /// 🔹 Carrega serviços com detalhes completos (modo ADMIN ou FORNECEDOR)
  Future<void> carregarServicosComDetalhesOtimizado({String? idFornecedor}) async {
    try {
      carregando.value = true;
      servicosFornecedor.clear();
      erro.value = '';

      // ===========================================================
      // 1️⃣ MODO ADMIN — carrega TODOS os serviços do sistema
      // ===========================================================
      if (idFornecedor == null) {
        debugPrint('📡 [SERVIÇOS] Modo ADMIN — carregando todos os serviços ativos');

        final catSnap = await _db.collection('categoria_servico').get();
        final subSnap = await _db.collection('subcategoria_servico').get();

        final mapaCategorias = <String, String>{};
        final mapaSubcategorias = <String, String>{};
        final mapaSubParaCat = <String, String>{};

        for (var c in catSnap.docs) {
          mapaCategorias[c.id] = c.data()['nome'] ?? 'Sem nome';
        }
        for (var s in subSnap.docs) {
          final data = s.data();
          final idCat = data['id_categoria'] ?? '';
          mapaSubcategorias[s.id] = data['nome'] ?? 'Sem nome';
          mapaSubParaCat[s.id] = idCat;
        }

        final servSnap =
            await _db.collection('servico_produto').where('ativo', isEqualTo: true).get();

        final lista = servSnap.docs.map((d) {
          final data = d.data();
          final idSub = data['id_subcategoria'] ?? '';
          final idCat = mapaSubParaCat[idSub] ?? '';

          return FornecedorServicoDetalhadoDto(
            id: d.id,
            idFornecedor: '',
            idProdutoServico: d.id,
            idSubcategoria: idSub,
            nomeServico: data['nome'] ?? 'Serviço sem nome',
            descricaoServico: data['descricao'] ?? '',
            tipoMedida: data['tipo_medida'] ?? 'U',
            preco: 0.0,
            precoPromocao: null,
            nomeSubcategoria: mapaSubcategorias[idSub] ?? 'Sem subcategoria',
            nomeCategoria: mapaCategorias[idCat] ?? 'Sem categoria',
            imagemUrl: null,
            ativo: data['ativo'] ?? true,
          );
        }).toList();

        servicosFornecedor.assignAll(lista);
        debugPrint('🟢 [SERVIÇOS] Lista ADMIN carregada: ${lista.length} itens.');
        return;
      }

      // ===========================================================
      // 2️⃣ MODO FORNECEDOR — carrega SOMENTE serviços vinculados
      // ===========================================================
      debugPrint('📡 [SERVIÇOS] Modo FORNECEDOR — carregando serviços de $idFornecedor');

      // 🔸 Buscar categorias e subcategorias do fornecedor
      final categoriaSnap = await _db
          .collection('fornecedor_categoria')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get();

      if (categoriaSnap.docs.isEmpty) {
        debugPrint('⚠️ Nenhuma categoria encontrada para o fornecedor $idFornecedor');
        return;
      }

      final mapaCategorias = <String, String>{};
      final mapaSubcategorias = <String, String>{};
      final mapaSubParaCat = <String, String>{};

      /// 🔥 IMPORTANTÍSSIMO → aqui vira SET para remover duplicados
      final Set<String> subIds = {};

      for (var catDoc in categoriaSnap.docs) {
        final data = catDoc.data();
        final idCat = data['id_categoria'] ?? '';
        mapaCategorias[idCat] = data['nome_categoria'] ?? 'Sem nome';

        final subs = (data['subcategorias'] as List?) ?? [];
        for (var sub in subs) {
          final idSub = sub['idSubcategoria'] ?? '';
          final nomeSub = sub['nomeSubcategoria'] ?? '';

          if (idSub.isNotEmpty) {
            mapaSubcategorias[idSub] = nomeSub;
            mapaSubParaCat[idSub] = idCat;
            subIds.add(idSub);
          }
        }
      }

      debugPrint('📌 Subcategorias únicas encontradas: ${subIds.length}');

      if (subIds.isEmpty) {
        debugPrint('⚠️ Nenhuma subcategoria vinculada ao fornecedor.');
        return;
      }

      // ===========================================================
      // 🔥 Criar função interna para dividir lista em chunks de 30
      // ===========================================================
      List<List<String>> dividirChunks(List<String> lista, int tamanho) {
        final chunks = <List<String>>[];
        for (var i = 0; i < lista.length; i += tamanho) {
          chunks.add(lista.sublist(
            i,
            i + tamanho > lista.length ? lista.length : i + tamanho,
          ));
        }
        return chunks;
      }

      final subIdsList = subIds.toList();
      final chunks = dividirChunks(subIdsList, 30);

      debugPrint('📦 Total de chunks necessários: ${chunks.length}');

      // ===========================================================
      // 3️⃣ Buscar vínculos (preço, promoção, ativo)
      // ===========================================================
      final vinculosSnap = await _db
          .collection('fornecedor_servico')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get();

      final vinculosMap = {
        for (var doc in vinculosSnap.docs) doc.data()['id_produto_servico']: doc.data()
      };

      // ===========================================================
      // 4️⃣ Buscar fotos
      // ===========================================================
      final fotosSnap = await _db
          .collection('servico_foto')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get();

      final fotosMap = {
        for (var doc in fotosSnap.docs) doc.data()['id_produto_servico']: doc.data()['url']
      };

      // ===========================================================
      // 5️⃣ Buscar serviços — AGORA sem erro, em várias consultas
      // ===========================================================
      final List<QueryDocumentSnapshot> todosServicosDocs = [];

      for (final chunk in chunks) {
        debugPrint('🔎 Consultando chunk com ${chunk.length} subcategorias...');
        final snap = await _db
            .collection('servico_produto')
            .where('id_subcategoria', whereIn: chunk)
            .where('ativo', isEqualTo: true)
            .get();

        todosServicosDocs.addAll(snap.docs);
      }

      debugPrint('🧩 Total de serviços encontrados: ${todosServicosDocs.length}');

      // ===========================================================
      // 6️⃣ Montar lista final com detalhes
      // ===========================================================
      final lista = <FornecedorServicoDetalhadoDto>[];

      for (var servDoc in todosServicosDocs) {
        final data = servDoc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final idServico = servDoc.id;
        final idSub = (data['id_subcategoria'] ?? '').toString();

        final vinculo = vinculosMap[idServico];
        if (vinculo == null) continue;

        final preco = (vinculo['preco'] ?? 0).toDouble();
        final precoPromocao = vinculo['preco_promocao'] != null
            ? (vinculo['preco_promocao'] as num).toDouble()
            : null;

        final ativo = vinculo['ativo'] ?? true;
        final imagemUrl = fotosMap[idServico];

        lista.add(FornecedorServicoDetalhadoDto(
          id: idServico,
          idFornecedor: idFornecedor,
          idProdutoServico: idServico,
          idSubcategoria: idSub,
          nomeServico: data['nome'] ?? 'Serviço sem nome',
          descricaoServico: data['descricao'] ?? '',
          tipoMedida: data['tipo_medida'] ?? 'U',
          preco: preco,
          precoPromocao: precoPromocao,
          nomeSubcategoria: mapaSubcategorias[idSub] ?? 'Sem subcategoria',
          nomeCategoria: mapaCategorias[mapaSubParaCat[idSub]] ?? 'Sem categoria',
          imagemUrl: imagemUrl,
          ativo: ativo,
        ));
      }

      servicosFornecedor.assignAll(lista);
      debugPrint('🟢 [SERVIÇOS] Lista do fornecedor carregada: ${lista.length} itens.');
    } catch (e, s) {
      erro.value = e.toString();
      servicosFornecedor.clear();
      debugPrint('❌ Erro ao carregar serviços: $e\n$s');
    } finally {
      carregando.value = false;
    }
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

  Future<void> buscarServicosDoFornecedorPeloAdmin(String idFornecedor) async {
    toggleListenerFornecedor(idFornecedor: idFornecedor);
  }

  void pararListenerServicosAdmin() {
    _servicosAdminSubscription?.cancel();
    _servicosAdminSubscription = null;
    debugPrint('🛑 Listener de serviços ADMIN encerrado.');
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
      carregarServicosComDetalhesOtimizado();
      listenerAtivoAdmin.value = true;
    }
  }

  Future<void> toggleListenerFornecedor({
    required String idFornecedor,
    Duration timeout = const Duration(minutes: 2),
  }) async {
    if (listenerAtivoFornecedor.value) {
      // PARAR LISTENER
      debugPrint('🛑 Parando listener do fornecedor $idFornecedor...');
      await _servicosSubscription?.cancel();
      _servicosSubscription = null;
      listenerAtivoFornecedor.value = false;

      _fornecedorTimeoutTimer?.cancel();
      _fornecedorTimeoutTimer = null;

      return;
    }

    // INICIAR LISTENER
    debugPrint('▶️ Iniciando listener do fornecedor $idFornecedor...');

    // Carrega imediatamente antes de abrir o listener realtime
    await carregarServicosComDetalhesOtimizado(idFornecedor: idFornecedor);

    // Agora sim: cria o listener real-time
    await escutarServicosFornecedor(idFornecedor);

    listenerAtivoFornecedor.value = true;

    // Timeout opcional
    _fornecedorTimeoutTimer?.cancel();
    _fornecedorTimeoutTimer = Timer(timeout, () async {
      if (listenerAtivoFornecedor.value) {
        debugPrint('⏰ Timeout: encerrando listener fornecedor.');
        await _servicosSubscription?.cancel();
        _servicosSubscription = null;
        listenerAtivoFornecedor.value = false;
      }
    });

    debugPrint('⏱️ Listener ativo por ${timeout.inMinutes} min.');
  }

  /// 🔍 Valida se o fornecedor realmente possui a subcategoria
  Future<bool> validarSubcategoriaFornecedor(String idFornecedor, String idSubcat) async {
    final snap = await _db
        .collection('fornecedor_categoria')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .get();

    if (snap.docs.isEmpty) return false;

    for (var doc in snap.docs) {
      final subs = (doc.data()['subcategorias'] as List?) ?? [];
      if (subs.any((s) => s['idSubcategoria'] == idSubcat)) {
        return true;
      }
    }
    return false;
  }

  /// ============================================================
  /// 🔗 Vincular serviço ao fornecedor — VERSÃO CORRIGIDA
  /// ============================================================
  Future<void> vincularServico(FornecedorProdutoServicoModel model) async {
    try {
      carregando.value = true;

      debugPrint('💾 [VÍNCULO] Salvando vínculo do serviço...');

      /// 1) VALIDAR SUBCATEGORIA
      final ok = await validarSubcategoriaFornecedor(
        model.idFornecedor,
        model.idSubcategoria ?? '',
      );

      // 2) Se não possuir → cadastrar automaticamente
      if (!ok) {
        debugPrint('⚠ Subcategoria não encontrada. Adicionando...');
        await adicionarSubcategoriaAoFornecedor(
          model.idFornecedor,
          model.idSubcategoria!,
        );
      }

      /// 2) SALVAR VÍNCULO
      final String vinculoId = '${model.idFornecedor}_${model.idProdutoServico}';

      final Map<String, dynamic> data = model.toMap();
      data['data_atualizacao'] = FieldValue.serverTimestamp();

      await _db.collection('fornecedor_servico').doc(vinculoId).set(data, SetOptions(merge: true));

      debugPrint('🟢 Vínculo salvo com sucesso → $vinculoId');

      /// 3) RECARREGAR SERVIÇOS (SEMPRE)
      await carregarServicosComDetalhesOtimizado(
        idFornecedor: model.idFornecedor,
      );

      Get.snackbar(
        'Sucesso',
        'Serviço vinculado ao fornecedor!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
    } catch (e, s) {
      debugPrint('❌ Erro ao vincular serviço: $e\n$s');
      erro.value = e.toString();
      Get.snackbar(
        'Erro',
        erro.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      carregando.value = false;
    }
  }

  Future<void> adicionarSubcategoriaAoFornecedor(
    String idFornecedor,
    String idSubcat,
  ) async {
    final ref =
        _db.collection('fornecedor_categoria').where('id_fornecedor', isEqualTo: idFornecedor);

    final snap = await ref.get();

    if (snap.docs.isEmpty) {
      debugPrint('⚠ Nenhuma categoria principal encontrada para esse fornecedor.');
      return;
    }

    for (var doc in snap.docs) {
      final List subs = (doc.data()['subcategorias'] as List?) ?? [];

      // Já existe → nada a fazer
      if (subs.any((s) => s['idSubcategoria'] == idSubcat)) {
        return;
      }

      final nova = {
        'idSubcategoria': idSubcat,
        'nomeSubcategoria': 'Subcategoria',
      };

      subs.add(nova);

      await doc.reference.update({
        'subcategorias': subs,
      });

      debugPrint("🟢 Subcategoria adicionada automaticamente ao fornecedor.");
    }
  }

  Future<void> excluirVinculo(String id, String idFornecedor) async {
    await _db.collection('fornecedor_servico').doc(id).delete();
    await carregarServicosComDetalhesOtimizado(
      idFornecedor: idFornecedor,
    );
  }
}
