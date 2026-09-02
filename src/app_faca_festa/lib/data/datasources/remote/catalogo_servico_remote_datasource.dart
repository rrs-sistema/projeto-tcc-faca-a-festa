import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/servico_produto/categoria_servico_model.dart';
import '../../models/servico_produto/subcategoria_servico_model.dart';
import '../../seeds/categoria_servico_seed.dart';
import '../../../domain/repositories/catalogo_servico_repository.dart';

class CatalogoServicoRemoteDatasource {
  CatalogoServicoRemoteDatasource({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  Future<List<CategoriaServicoModel>> listarCategorias() async {
    final snapshot = await _db.collection('categoria_servico').get();
    return snapshot.docs
        .map((d) => CategoriaServicoModel.fromMap(d.data(), documentId: d.id))
        .toList();
  }

  Future<Map<String, int>> contarSubcategoriasPorCategoria() async {
    final snap = await _db.collection('subcategoria_servico').get();
    final map = <String, int>{};
    for (final d in snap.docs) {
      final data = d.data();
      final id =
          (data['id_categoria'] ?? data['idCategoria'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      map[id] = (map[id] ?? 0) + 1;
    }
    return map;
  }

  Future<void> salvarCategoria(CategoriaServicoModel model) {
    return _db
        .collection('categoria_servico')
        .doc(model.id)
        .set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> atualizarStatusCategoria(String idCategoria, bool ativo) {
    return _db.collection('categoria_servico').doc(idCategoria).update({
      'ativo': ativo,
      'data_atualizacao': FieldValue.serverTimestamp(),
    });
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
        final idCat =
            (data['id_categoria'] ?? data['idCategoria'] ?? '').toString();
        return idCat == id;
      }).toList();
    }

    for (final d in docs) {
      batch.delete(d.reference);
    }
    batch.delete(_db.collection('categoria_servico').doc(id));
    await batch.commit();
  }

  Future<CatalogoServicoSeedResultado> popularCatalogoInicial() async {
    final batch = _db.batch();
    final agora = FieldValue.serverTimestamp();

    final categoriasExistentes =
        await _db.collection('categoria_servico').get();
    final subcategoriasExistentes =
        await _db.collection('subcategoria_servico').get();
    final idsCategoria = categoriasExistentes.docs.map((d) => d.id).toSet();
    final idsSubcategoria =
        subcategoriasExistentes.docs.map((d) => d.id).toSet();

    for (final categoria in CatalogoCategoriaServico.categorias) {
      final ref = _db.collection('categoria_servico').doc(categoria.id);
      batch.set(
        ref,
        _mapaSeedCategoria(
          categoria,
          agora,
          novo: !idsCategoria.contains(categoria.id),
        ),
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
    return (
      categorias: CatalogoCategoriaServico.categorias.length,
      subcategorias: CatalogoCategoriaServico.subcategorias.length,
    );
  }

  Future<List<SubcategoriaServicoModel>> listarSubcategorias({
    String? idCategoria,
  }) async {
    final snap = await _db.collection('subcategoria_servico').get();
    var lista = snap.docs
        .map(
            (d) => SubcategoriaServicoModel.fromMap(d.data(), documentId: d.id))
        .toList();
    if (idCategoria != null && idCategoria.isNotEmpty) {
      lista = lista.where((s) => s.idCategoria == idCategoria).toList();
    }
    return lista;
  }

  Future<Map<String, int>> contarServicosPorSubcategoria(
      List<String> ids) async {
    if (ids.isEmpty) return <String, int>{};

    final snap = await _db.collection('servico_produto').get();
    final map = {for (final id in ids) id: 0};
    for (final d in snap.docs) {
      final data = d.data();
      final idSub =
          (data['id_subcategoria'] ?? data['idSubcategoria'] ?? '').toString();
      if (map.containsKey(idSub)) {
        map[idSub] = (map[idSub] ?? 0) + 1;
      }
    }
    return map;
  }

  Future<void> salvarSubcategoria(SubcategoriaServicoModel model) {
    return _db
        .collection('subcategoria_servico')
        .doc(model.id)
        .set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> atualizarStatusSubcategoria(String idSubcategoria, bool ativo) {
    return _db.collection('subcategoria_servico').doc(idSubcategoria).update({
      'ativo': ativo,
      'data_atualizacao': FieldValue.serverTimestamp(),
    });
  }

  Future<void> excluirSubcategoria(String id) {
    return _db.collection('subcategoria_servico').doc(id).delete();
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
}
