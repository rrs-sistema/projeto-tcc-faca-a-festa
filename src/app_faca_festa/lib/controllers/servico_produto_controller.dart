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

  /// 🔹 Carrega serviços com ou sem filtro por fornecedor.
  Future<void> carregarServicosComDetalhesOtimizado({String? idFornecedor}) async {
    try {
      carregando.value = true;
      servicosFornecedor.clear();
      erro.value = '';

      // ===========================================================
      // 1️⃣ Se não tiver fornecedor → modo ADMIN (todos os serviços)
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
        debugPrint('✅ [SERVIÇOS] Lista ADMIN carregada: ${lista.length} itens.');
        return;
      }

      // ===========================================================
      // 2️⃣ Se tiver fornecedor → modo FORNECEDOR
      // ===========================================================
      debugPrint('📡 [SERVIÇOS] Modo FORNECEDOR — carregando $idFornecedor');

      // 🔸 Categorias e subcategorias do fornecedor
      final categoriaSnap = await _db
          .collection('fornecedor_categoria')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get();

      if (categoriaSnap.docs.isEmpty) {
        debugPrint('⚠️ Nenhuma categoria encontrada para o fornecedor $idFornecedor');
        carregando.value = false;
        return;
      }

      final mapaCategorias = <String, String>{};
      final mapaSubcategorias = <String, String>{};
      final mapaSubParaCat = <String, String>{};
      final subIds = <String>[];

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

      if (subIds.isEmpty) {
        debugPrint('⚠️ Nenhuma subcategoria vinculada ao fornecedor.');
        carregando.value = false;
        return;
      }

      // 🔸 Buscar vínculos (preço, promoção, ativo)
      final vinculosSnap = await _db
          .collection('fornecedor_servico')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get();

      final vinculosMap = {
        for (var doc in vinculosSnap.docs) doc.data()['id_produto_servico']: doc.data()
      };

      // 🔸 Buscar fotos do fornecedor
      final fotosSnap = await _db
          .collection('servico_foto')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get();

      final fotosMap = {
        for (var doc in fotosSnap.docs) doc.data()['id_produto_servico']: doc.data()['url']
      };

      // 🔸 Buscar serviços das subcategorias
      final servicosSnap = await _db
          .collection('servico_produto')
          .where('id_subcategoria', whereIn: subIds)
          .where('ativo', isEqualTo: true)
          .get();

      final lista = <FornecedorServicoDetalhadoDto>[];

      for (var servDoc in servicosSnap.docs) {
        final data = servDoc.data();
        final idServico = servDoc.id;
        final idSub = (data['id_subcategoria'] ?? '').toString();

        final vinculo = vinculosMap[idServico];
        if (vinculo == null) continue; // sem vínculo ativo

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
      debugPrint('✅ [SERVIÇOS] Lista do fornecedor carregada: ${lista.length} itens.');
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
      carregarServicosComDetalhesOtimizado(idFornecedor: idFornecedor);
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
