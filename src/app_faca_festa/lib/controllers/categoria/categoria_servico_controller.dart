import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import './../../data/models/servico_produto/categoria_servico_model.dart';
import './../../data/models/servico_produto/subcategoria_servico_model.dart';
import './../../data/seeds/categoria_servico_seed.dart';

class CategoriaServicoController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final categorias = <CategoriaServicoModel>[].obs;
  final contagemSubcategorias = <String, int>{}.obs;
  final busca = ''.obs;
  final filtroAtivo = RxnBool();
  final carregando = false.obs;
  final erro = ''.obs;

  @override
  void onInit() {
    super.onInit();
    carregarCategorias();
  }

  List<CategoriaServicoModel> get categoriasFiltradas {
    final termo = busca.value.trim().toLowerCase();
    var lista = categorias.toList();

    if (filtroAtivo.value != null) {
      lista = lista.where((c) => c.ativo == filtroAtivo.value).toList();
    }

    if (termo.isNotEmpty) {
      lista = lista.where((c) {
        final nome = c.nome.toLowerCase();
        final desc = (c.descricao ?? '').toLowerCase();
        return nome.contains(termo) || desc.contains(termo);
      }).toList();
    }

    lista.sort((a, b) {
      if (a.ordem != b.ordem) return a.ordem.compareTo(b.ordem);
      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });
    return lista;
  }

  int get totalAtivas => categorias.where((c) => c.ativo).length;

  int subcategoriasDe(String idCategoria) => contagemSubcategorias[idCategoria] ?? 0;

  Future<void> carregarCategorias() async {
    try {
      carregando.value = true;
      erro.value = '';
      final snapshot = await _db.collection('categoria_servico').get();
      categorias.value = snapshot.docs
          .map((d) => CategoriaServicoModel.fromMap(d.data(), documentId: d.id))
          .toList();
      await _atualizarContagensSubcategorias();
    } catch (e) {
      erro.value = e.toString();
    } finally {
      carregando.value = false;
    }
  }

  Future<void> _atualizarContagensSubcategorias() async {
    try {
      final snap = await _db.collection('subcategoria_servico').get();
      final map = <String, int>{};
      for (final d in snap.docs) {
        final data = d.data();
        final id = (data['id_categoria'] ?? data['idCategoria'] ?? '').toString().trim();
        if (id.isEmpty) continue;
        map[id] = (map[id] ?? 0) + 1;
      }
      contagemSubcategorias.assignAll(map);
    } catch (_) {}
  }

  Future<void> salvarCategoria(CategoriaServicoModel model) async {
    await _db.collection('categoria_servico').doc(model.id).set(model.toMap(), SetOptions(merge: true));
    await carregarCategorias();
  }

  Future<void> atualizarStatus(CategoriaServicoModel model, bool ativo) async {
    await _db.collection('categoria_servico').doc(model.id).update({
      'ativo': ativo,
      'data_atualizacao': FieldValue.serverTimestamp(),
    });
    final idx = categorias.indexWhere((c) => c.id == model.id);
    if (idx >= 0) {
      categorias[idx] = model.copyWith(ativo: ativo);
      categorias.refresh();
    }
  }

  /// Grava (merge) o catálogo padrão de festas no Firestore.
  /// Preserva IDs já usados por fornecedores e serviços.
  Future<({int categorias, int subcategorias})> popularCatalogoInicial() async {
    final batch = _db.batch();
    final agora = FieldValue.serverTimestamp();

    final categoriasExistentes = await _db.collection('categoria_servico').get();
    final subcategoriasExistentes = await _db.collection('subcategoria_servico').get();
    final idsCategoria = categoriasExistentes.docs.map((d) => d.id).toSet();
    final idsSubcategoria = subcategoriasExistentes.docs.map((d) => d.id).toSet();

    for (final categoria in CatalogoCategoriaServico.categorias) {
      final ref = _db.collection('categoria_servico').doc(categoria.id);
      batch.set(
        ref,
        _mapaSeedCategoria(categoria, agora, novo: !idsCategoria.contains(categoria.id)),
        SetOptions(merge: true),
      );
    }
    for (final subcategoria in CatalogoCategoriaServico.subcategorias) {
      final ref = _db.collection('subcategoria_servico').doc(subcategoria.id);
      batch.set(
        ref,
        _mapaSeedSubcategoria(
          subcategoria,
          agora,
          novo: !idsSubcategoria.contains(subcategoria.id),
        ),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    await carregarCategorias();

    return (
      categorias: CatalogoCategoriaServico.categorias.length,
      subcategorias: CatalogoCategoriaServico.subcategorias.length,
    );
  }

  Map<String, dynamic> _mapaSeedCategoria(
    CategoriaServicoModel categoria,
    FieldValue agora, {
    required bool novo,
  }) {
    return {
      'id': categoria.id,
      'nome': categoria.nome,
      'descricao': categoria.descricao,
      'ativo': categoria.ativo,
      'ordem': categoria.ordem,
      'icone': categoria.icone,
      if (novo) 'data_cadastro': agora,
      'data_atualizacao': agora,
    };
  }

  Map<String, dynamic> _mapaSeedSubcategoria(
    SubcategoriaServicoModel subcategoria,
    FieldValue agora, {
    required bool novo,
  }) {
    return {
      'id': subcategoria.id,
      'id_categoria': subcategoria.idCategoria,
      'nome': subcategoria.nome,
      'descricao': subcategoria.descricao,
      'ativo': subcategoria.ativo,
      'ordem': subcategoria.ordem,
      'icone': subcategoria.icone,
      if (novo) 'data_cadastro': agora,
      'data_atualizacao': agora,
    };
  }

  Future<void> excluirCategoria(String id) async {
    final batch = _db.batch();
    final porCampo = await _db
        .collection('subcategoria_servico')
        .where('id_categoria', isEqualTo: id)
        .get();

    var docs = porCampo.docs;
    if (docs.isEmpty) {
      final todas = await _db.collection('subcategoria_servico').get();
      docs = todas.docs.where((d) {
        final data = d.data();
        final idCat = (data['id_categoria'] ?? data['idCategoria'] ?? '').toString();
        return idCat == id;
      }).toList();
    }

    for (final d in docs) {
      batch.delete(d.reference);
    }
    batch.delete(_db.collection('categoria_servico').doc(id));
    await batch.commit();
    await carregarCategorias();
  }
}
