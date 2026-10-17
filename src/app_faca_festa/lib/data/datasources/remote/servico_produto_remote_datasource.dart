import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../../models/servico_produto/fornecedor_produto_servico_model.dart';
import '../../models/servico_produto/servico_produto_model.dart';
import '../../seeds/servico_produto_seed.dart';

class ServicoProdutoRemoteDatasource {
  ServicoProdutoRemoteDatasource({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  Future<List<ServicoProdutoModel>> listarServicos() async {
    final snapshot = await _db.collection('servico_produto').get();
    return snapshot.docs
        .map((doc) => ServicoProdutoModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<ServicoProdutoModel>> listarServicosAtivos() async {
    final snapshot = await _db
        .collection('servico_produto')
        .where('ativo', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      return ServicoProdutoModel.fromMap({...doc.data(), 'id': doc.id});
    }).toList();
  }

  Future<List<ServicoProdutoModel>> listarServicosAtivosPorSubcategoria(
    String idSubcategoria,
  ) async {
    final snap = await _db
        .collection('servico_produto')
        .where('id_subcategoria', isEqualTo: idSubcategoria)
        .where('ativo', isEqualTo: true)
        .get();

    return snap.docs.map((d) {
      return ServicoProdutoModel.fromMap({...d.data(), 'id': d.id});
    }).toList();
  }

  Future<List<ServicoProdutoModel>> listarServicosAtivosPorCategoriasFornecedor(
    String idFornecedor,
  ) async {
    final categoriaSnap = await _db
        .collection('fornecedor_categoria')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .get();

    if (categoriaSnap.docs.isEmpty) {
      return <ServicoProdutoModel>[];
    }

    final subcategoriasIds = <String>{};
    for (final doc in categoriaSnap.docs) {
      final subs = (doc.data()['subcategorias'] as List?) ?? [];
      for (final sub in subs) {
        final idSubcategoria = sub['idSubcategoria']?.toString();
        if (idSubcategoria != null && idSubcategoria.isNotEmpty) {
          subcategoriasIds.add(idSubcategoria);
        }
      }
    }

    if (subcategoriasIds.isEmpty) {
      return <ServicoProdutoModel>[];
    }

    final servicos = <ServicoProdutoModel>[];
    for (final chunk in _dividirChunks(subcategoriasIds.toList(), 30)) {
      final snap = await _db
          .collection('servico_produto')
          .where('id_subcategoria', whereIn: chunk)
          .where('ativo', isEqualTo: true)
          .get();

      servicos.addAll(
        snap.docs.map((doc) {
          return ServicoProdutoModel.fromMap({...doc.data(), 'id': doc.id});
        }),
      );
    }

    return servicos;
  }

  Future<List<FornecedorServicoDetalhadoDto>> listarServicosComDetalhes({
    String? idFornecedor,
  }) async {
    if (idFornecedor == null) {
      return _listarServicosAdmin();
    }
    return _listarServicosFornecedor(idFornecedor);
  }

  Future<List<FornecedorServicoDetalhadoDto>> _listarServicosAdmin() async {
    final catSnap = await _db.collection('categoria_servico').get();
    final subSnap = await _db.collection('subcategoria_servico').get();

    final mapaCategorias = <String, String>{};
    final mapaSubcategorias = <String, String>{};
    final mapaSubParaCat = <String, String>{};

    for (final c in catSnap.docs) {
      mapaCategorias[c.id] = c.data()['nome'] ?? 'Sem nome';
    }
    for (final s in subSnap.docs) {
      final data = s.data();
      final idCat = data['id_categoria'] ?? '';
      mapaSubcategorias[s.id] = data['nome'] ?? 'Sem nome';
      mapaSubParaCat[s.id] = idCat;
    }

    final servSnap = await _db
        .collection('servico_produto')
        .where('ativo', isEqualTo: true)
        .get();

    return servSnap.docs.map((d) {
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
        quantidade: 1,
      );
    }).toList();
  }

  Future<List<FornecedorServicoDetalhadoDto>> _listarServicosFornecedor(
    String idFornecedor,
  ) async {
    final vinculosSnap = await _lerAtual(
      _db
          .collection('fornecedor_servico')
          .where('id_fornecedor', isEqualTo: idFornecedor),
    );

    if (vinculosSnap.docs.isEmpty) {
      return <FornecedorServicoDetalhadoDto>[];
    }

    final vinculos = <Map<String, dynamic>>[];
    final idsServico = <String>{};
    for (final doc in vinculosSnap.docs) {
      final data = doc.data();
      final idServico = (data['id_produto_servico'] ?? '').toString().trim();
      if (idServico.isEmpty || !idsServico.add(idServico)) continue;
      vinculos.add(data);
    }
    if (vinculos.isEmpty) return <FornecedorServicoDetalhadoDto>[];

    final servicos = <String, Map<String, dynamic>>{};
    for (final chunk in _dividirChunks(idsServico.toList(), 30)) {
      final snap = await _db
          .collection('servico_produto')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        servicos[doc.id] = doc.data();
      }
    }

    final idsSub = <String>{};
    for (final data in servicos.values) {
      final idSub = (data['id_subcategoria'] ?? '').toString().trim();
      if (idSub.isNotEmpty) idsSub.add(idSub);
    }
    for (final vinculo in vinculos) {
      final idSub = (vinculo['id_subcategoria'] ?? '').toString().trim();
      if (idSub.isNotEmpty) idsSub.add(idSub);
    }

    final mapaSub = <String, Map<String, dynamic>>{};
    for (final chunk in _dividirChunks(idsSub.toList(), 30)) {
      final snap = await _db
          .collection('subcategoria_servico')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        mapaSub[doc.id] = doc.data();
      }
    }

    final idsCat = <String>{
      for (final data in mapaSub.values)
        (data['id_categoria'] ?? data['idCategoria'] ?? '').toString().trim(),
    }..remove('');
    final mapaCat = <String, String>{};
    for (final chunk in _dividirChunks(idsCat.toList(), 30)) {
      final snap = await _db
          .collection('categoria_servico')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        mapaCat[doc.id] = (doc.data()['nome'] ?? 'Sem nome').toString();
      }
    }

    final fotosSnap = await _db
        .collection('servico_foto')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .get();
    final fotosMap = <String, String>{};
    for (final doc in fotosSnap.docs) {
      final idServico =
          (doc.data()['id_produto_servico'] ?? '').toString().trim();
      final url = doc.data()['url']?.toString();
      if (idServico.isNotEmpty && url != null && url.isNotEmpty) {
        fotosMap[idServico] = url;
      }
    }

    return [
      for (final vinculo in vinculos)
        _detalheDoVinculo(
          idFornecedor: idFornecedor,
          vinculo: vinculo,
          servicos: servicos,
          mapaSub: mapaSub,
          mapaCat: mapaCat,
          fotosMap: fotosMap,
        ),
    ];
  }

  FornecedorServicoDetalhadoDto _detalheDoVinculo({
    required String idFornecedor,
    required Map<String, dynamic> vinculo,
    required Map<String, Map<String, dynamic>> servicos,
    required Map<String, Map<String, dynamic>> mapaSub,
    required Map<String, String> mapaCat,
    required Map<String, String> fotosMap,
  }) {
    final idServico = (vinculo['id_produto_servico'] ?? '').toString().trim();
    final servico = servicos[idServico];
    final idSub =
        (servico?['id_subcategoria'] ?? vinculo['id_subcategoria'] ?? '')
            .toString()
            .trim();
    final sub = mapaSub[idSub];
    final idCat =
        (sub?['id_categoria'] ?? sub?['idCategoria'] ?? '').toString().trim();
    final promo = vinculo['preco_promocao'];

    return FornecedorServicoDetalhadoDto(
      id: idServico,
      idFornecedor: idFornecedor,
      idProdutoServico: idServico,
      idSubcategoria: idSub,
      nomeServico: (servico?['nome'] ?? 'Serviço sem nome').toString(),
      descricaoServico: (servico?['descricao'] ?? '').toString(),
      tipoMedida: (servico?['tipo_medida'] ?? 'U').toString(),
      preco: (vinculo['preco'] as num?)?.toDouble() ?? 0,
      precoPromocao: promo is num ? promo.toDouble() : null,
      nomeSubcategoria: (sub?['nome'] ?? 'Sem subcategoria').toString(),
      nomeCategoria: mapaCat[idCat] ?? 'Sem categoria',
      imagemUrl: fotosMap[idServico],
      ativo: vinculo['ativo'] ?? true,
      quantidade: 1,
    );
  }

  Future<void> excluirServico(String id) {
    return _db.collection('servico_produto').doc(id).delete();
  }

  Future<void> salvarServico(ServicoProdutoModel model) {
    return _db.collection('servico_produto').doc(model.id).set(model.toMap());
  }

  Future<int> popularCatalogoInicial() async {
    final existentes = await _db.collection('servico_produto').get();
    final idsExistentes = existentes.docs.map((d) => d.id).toSet();
    final agora = FieldValue.serverTimestamp();

    WriteBatch lote = _db.batch();
    var operacoes = 0;

    Future<void> commitSeCheio() async {
      if (operacoes >= 400) {
        await lote.commit();
        lote = _db.batch();
        operacoes = 0;
      }
    }

    for (final item in CatalogoServicoProduto.itens) {
      await commitSeCheio();
      lote.set(
        _db.collection('servico_produto').doc(item.id),
        {
          'id': item.id,
          'nome': item.nome,
          'descricao': item.descricao,
          'tipo_medida': item.tipoMedida,
          'id_subcategoria': item.idSubcategoria,
          'ativo': item.ativo,
          if (!idsExistentes.contains(item.id)) 'data_cadastro': agora,
          'data_atualizacao': agora,
        },
        SetOptions(merge: true),
      );
      operacoes++;
    }
    if (operacoes > 0) {
      await lote.commit();
    }

    return CatalogoServicoProduto.itens.length;
  }

  Stream<void> observarVinculosFornecedor(String idFornecedor) {
    return _db
        .collection('fornecedor_servico')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .snapshots()
        .map((_) {});
  }

  Future<bool> validarSubcategoriaFornecedor(
    String idFornecedor,
    String idSubcategoria,
  ) async {
    final snap = await _db
        .collection('fornecedor_categoria')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .get();

    if (snap.docs.isEmpty) return false;

    for (final doc in snap.docs) {
      final subs = (doc.data()['subcategorias'] as List?) ?? [];
      if (subs.any((s) => s['idSubcategoria'] == idSubcategoria)) {
        return true;
      }
    }
    return false;
  }

  Future<void> adicionarSubcategoriaAoFornecedor(
    String idFornecedor,
    String idSubcategoria,
  ) async {
    final ref = _db
        .collection('fornecedor_categoria')
        .where('id_fornecedor', isEqualTo: idFornecedor);

    final snap = await ref.get();
    if (snap.docs.isEmpty) return;

    for (final doc in snap.docs) {
      final subs = List.of((doc.data()['subcategorias'] as List?) ?? []);
      if (subs.any((s) => s['idSubcategoria'] == idSubcategoria)) {
        return;
      }

      subs.add({
        'idSubcategoria': idSubcategoria,
        'nomeSubcategoria': 'Subcategoria',
      });

      await doc.reference.update({'subcategorias': subs});
    }
  }

  Future<void> salvarVinculo(FornecedorProdutoServicoModel model) {
    final vinculoId = '${model.idFornecedor}_${model.idProdutoServico}';
    final data = model.toMap();
    data['data_atualizacao'] = FieldValue.serverTimestamp();

    return _db
        .collection('fornecedor_servico')
        .doc(vinculoId)
        .set(data, SetOptions(merge: true));
  }

  Future<void> excluirVinculo(String id) {
    return _db.collection('fornecedor_servico').doc(id).delete();
  }

  /// A primeira leitura do painel não pode ficar no cache vazio.
  Future<QuerySnapshot<Map<String, dynamic>>> _lerAtual(
    Query<Map<String, dynamic>> consulta,
  ) async {
    try {
      return await consulta.get(const GetOptions(source: Source.server));
    } catch (_) {
      return consulta.get();
    }
  }

  List<List<String>> _dividirChunks(List<String> lista, int tamanho) {
    final chunks = <List<String>>[];
    for (var i = 0; i < lista.length; i += tamanho) {
      chunks.add(
        lista.sublist(
          i,
          i + tamanho > lista.length ? lista.length : i + tamanho,
        ),
      );
    }
    return chunks;
  }
}
