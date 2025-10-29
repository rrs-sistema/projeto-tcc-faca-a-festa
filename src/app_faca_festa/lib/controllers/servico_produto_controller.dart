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

  final RxBool carregando = false.obs;

  @override
  void onInit() {
    super.onInit();
    carregarServicos();
    //buscarServicosComCategoriaESubcategoria();
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

  Future<void> converterServicosComDetalhes(
    String idFornecedor,
    List<ServicoProdutoModel> servicos,
  ) async {
    final db = FirebaseFirestore.instance;

    // 🔹 Carrega todas as subcategorias e categorias de uma vez
    final subSnap = await db.collection('subcategoria_servico').get();
    final catSnap = await db.collection('categoria_servico').get();

    final mapaSub = {
      for (var s in subSnap.docs) s.id: s.data()['nome'] ?? '',
    };
    final mapaCat = {
      for (var c in catSnap.docs) c.id: c.data()['nome'] ?? '',
    };
    final mapaSubParaCat = {
      for (var s in subSnap.docs) s.id: s.data()['id_categoria'] ?? '',
    };

    final lista = servicos.map((s) {
      final nomeSub = mapaSub[s.idSubcategoria] ?? '';
      final idCat = mapaSubParaCat[s.idSubcategoria];
      final nomeCat = mapaCat[idCat] ?? '';

      return FornecedorServicoDetalhadoDto(
          idFornecedorServico: 'vinc_${s.id}_$idFornecedor',
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
          ativo: s.ativo);
    }).toList();

    servicosFornecedor.assignAll(lista);
  }

  /// subcategorias e categorias (consulta completa e otimizada).
  Future<void> buscarServicosComCategoriaESubcategoria01() async {
    try {
      carregando.value = true;
      final db = FirebaseFirestore.instance;
      //servicosFornecedor.clear();
      // 4️⃣ Montar a lista detalhada
      List<FornecedorServicoDetalhadoDto> lista = [];
      // 1️⃣ Buscar todos os serviços/produtos
      final servicoSnap = await db.collection('servico_produto').get();
      if (servicoSnap.docs.isEmpty) {
        debugPrint('Nenhum serviço encontrado.');
        carregando.value = false;
        return;
      }

      // Mapa: idSubcategoria -> lista de serviços
      final Map<String, List<Map<String, dynamic>>> servicosPorSub = {};

      for (final doc in servicoSnap.docs) {
        final data = doc.data();
        final idSub = data['id_subcategoria'];
        if (idSub == null || idSub.isEmpty) continue;
        servicosPorSub.putIfAbsent(idSub, () => []).add({
          'id': doc.id,
          ...data,
        });
      }

      final subIds = servicosPorSub.keys.toList();
      if (subIds.isEmpty) {
        debugPrint('Nenhum serviço possui subcategoria vinculada.');
        carregando.value = false;
        return;
      }

      // 2️⃣ Buscar as subcategorias correspondentes
      final subSnap = await db
          .collection('subcategoria_servico')
          .where(FieldPath.documentId, whereIn: subIds)
          .get();

      if (subSnap.docs.isEmpty) {
        debugPrint('Subcategorias não encontradas.');
        carregando.value = false;
        return;
      }

      final subMap = {
        for (var d in subSnap.docs)
          d.id: {
            'nome': d.data()['nome'],
            'id_categoria': d.data()['id_categoria'],
          }
      };

      // 3️⃣ Buscar as categorias correspondentes
      final catIds =
          subMap.values.map((s) => s['id_categoria']).whereType<String>().toSet().toList();

      final catSnap = await db
          .collection('categoria_servico')
          .where(FieldPath.documentId, whereIn: catIds)
          .get();

      final catMap = {for (var c in catSnap.docs) c.id: c.data()['nome'] ?? 'Sem categoria'};

      for (final entry in servicosPorSub.entries) {
        final idSub = entry.key;
        final subInfo = subMap[idSub];
        final nomeSub = subInfo?['nome'] ?? 'Sem subcategoria';
        final idCategoria = subInfo?['id_categoria'];
        final nomeCategoria = catMap[idCategoria] ?? 'Sem categoria';

        for (final servicoData in entry.value) {
          lista.add(FornecedorServicoDetalhadoDto(
              idFornecedorServico: '', // não aplicável aqui
              idFornecedor: '', // genérico, pois é lista global
              idProdutoServico: servicoData['id'],
              idSubcategoria: idSub,
              nomeServico: servicoData['nome'] ?? 'Serviço sem nome',
              descricaoServico: servicoData['descricao'] ?? '',
              tipoMedida: servicoData['tipo_medida'] ?? 'U',
              preco: 0.0,
              precoPromocao: null,
              nomeSubcategoria: nomeSub,
              nomeCategoria: nomeCategoria,
              imagemUrl: null,
              ativo: servicoData['ativo']));
        }
      }

      // 5️⃣ Atualizar lista reativa
      //servicosFornecedor.assignAll(lista);
      //servicosFornecedor.refresh();
      debugPrint('✅ ${lista.length} serviços carregados com categoria e subcategoria.');
    } catch (e, s) {
      debugPrint('⚠️ Erro ao buscar serviços com categorias: $e');
      debugPrint(s.toString());
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
}
