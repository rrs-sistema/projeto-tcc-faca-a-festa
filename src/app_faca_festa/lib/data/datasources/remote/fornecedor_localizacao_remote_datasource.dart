import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../../models/fornecedor/fornecedor_model.dart';
import '../../models/servico_produto/categoria_servico_model.dart';
import '../../models/servico_produto/fornecedor_categoria_model.dart';
import '../../models/fornecedor/territorio_model.dart';

class FornecedorLocalizacaoRemoteDatasource {
  FornecedorLocalizacaoRemoteDatasource({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  Stream<List<CategoriaServicoModel>> observarCategoriasAtivas() {
    return _db
        .collection('categoria_servico')
        .where('ativo', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CategoriaServicoModel.fromMap({
                    'id': doc.id,
                    ...doc.data(),
                  }))
              .toList(),
        );
  }

  Stream<List<FornecedorModel>> observarFornecedoresAtivos() {
    return _db
        .collection('fornecedor')
        .where('ativo', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FornecedorModel.fromMap(
                    doc.data(),
                    documentId: doc.id,
                  ))
              .toList(),
        );
  }

  Stream<List<TerritorioModel>> observarTerritoriosAtivos() {
    return _db
        .collection('territorio')
        .where('ativo', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TerritorioModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<FornecedorCategoriaModel>> observarCategoriasFornecedor() {
    return _db.collection('fornecedor_categoria').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => FornecedorCategoriaModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<Map<String, double>> observarMediasAvaliacoes() {
    return _db.collection('avaliacoes').snapshots().map((snapshot) {
      final notasPorFornecedor = <String, List<int>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final idFornecedor = (data['id_fornecedor'] ?? '').toString();
        if (idFornecedor.isEmpty) continue;
        notasPorFornecedor
            .putIfAbsent(idFornecedor, () => <int>[])
            .add((data['nota'] ?? 0).toInt());
      }

      return notasPorFornecedor.map((id, notas) {
        final media = notas.reduce((a, b) => a + b) / notas.length;
        return MapEntry(id, double.parse(media.toStringAsFixed(2)));
      });
    });
  }

  Stream<List<FornecedorServicoDetalhadoDto>> observarServicosFornecedor(
    String idFornecedor,
  ) {
    return _db
        .collection('fornecedor_categoria')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .snapshots()
        .asyncMap(
          (snapshot) => _montarServicosPorCategorias(
            categoriasDocs: snapshot.docs,
            fornecedorFixo: idFornecedor,
            usarPrecoFornecedor: false,
          ),
        );
  }

  Stream<List<FornecedorServicoDetalhadoDto>> observarTodosServicos() {
    return _db.collection('fornecedor_categoria').snapshots().asyncMap(
          (snapshot) => _montarServicosPorCategorias(
            categoriasDocs: snapshot.docs,
            usarPrecoFornecedor: true,
          ),
        );
  }

  Future<List<FornecedorServicoDetalhadoDto>> listarTodosServicosDoFornecedor(
    String idFornecedor,
  ) async {
    final categoriasSnap = await _db
        .collection('fornecedor_categoria')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .get();

    return _montarServicosPorCategorias(
      categoriasDocs: categoriasSnap.docs,
      fornecedorFixo: idFornecedor,
      usarPrecoFornecedor: true,
    );
  }

  Future<List<FornecedorServicoDetalhadoDto>> listarServicosPorCategoria(
    String idCategoria,
  ) async {
    final subSnap = await _db
        .collection('subcategoria_servico')
        .where('id_categoria', isEqualTo: idCategoria)
        .get();
    final subIds = subSnap.docs.map((doc) => doc.id).toList();
    if (subIds.isEmpty) return <FornecedorServicoDetalhadoDto>[];

    final categoriaSnap =
        await _db.collection('categoria_servico').doc(idCategoria).get();
    final nomeCategoria = categoriaSnap.data()?['nome'];
    final lista = <FornecedorServicoDetalhadoDto>[];

    for (final chunk in _chunks(subIds, 30)) {
      final fornServSnap = await _db
          .collection('fornecedor_servico')
          .where('id_subcategoria', whereIn: chunk)
          .get();

      for (final doc in fornServSnap.docs) {
        final data = doc.data();
        final idSubcategoria = data['id_subcategoria'];
        final idProdutoServico = data['id_produto_servico'];
        final idFornecedor = data['id_fornecedor'];
        final servicoSnap =
            await _db.collection('servico_produto').doc(idProdutoServico).get();
        final servicoData = servicoSnap.data();
        final subData = subSnap.docs
            .where((sub) => sub.id == idSubcategoria)
            .map((sub) => sub.data())
            .firstOrNull;
        final imagemUrl = await _buscarImagemServico(
          idFornecedor: idFornecedor,
          idProdutoServico: idProdutoServico,
        );
        final nomeFornecedor = await _buscarNomeFornecedor(idFornecedor);

        lista.add(
          FornecedorServicoDetalhadoDto(
            id: doc.id,
            idFornecedor: idFornecedor,
            idProdutoServico: idProdutoServico,
            idSubcategoria: idSubcategoria,
            nomeServico: servicoData?['nome'],
            nomeFornecedor: nomeFornecedor,
            descricaoServico: servicoData?['descricao'],
            preco: (data['preco'] as num?)?.toDouble() ?? 0.0,
            precoPromocao: (data['preco_promocao'] as num?)?.toDouble(),
            nomeSubcategoria: subData?['nome'],
            nomeCategoria: nomeCategoria,
            imagemUrl: imagemUrl,
            ativo: true,
            quantidade: 1,
          ),
        );
      }
    }

    return lista;
  }

  Future<List<FornecedorServicoDetalhadoDto>>
      listarFornecedoresSemCategoria() async {
    final fornecedoresSnap = await _db
        .collection('fornecedor')
        .where('ativo', isEqualTo: true)
        .get();
    final todosFornecedores =
        fornecedoresSnap.docs.map((doc) => doc.id).toList();
    if (todosFornecedores.isEmpty) return <FornecedorServicoDetalhadoDto>[];

    final vinculosSnap = await _db.collection('fornecedor_categoria').get();
    final fornecedoresComCategoria = vinculosSnap.docs
        .map((doc) => doc.data()['id_fornecedor'] as String?)
        .whereType<String>()
        .toSet();
    final fornecedoresSemCategoria = todosFornecedores
        .where((id) => !fornecedoresComCategoria.contains(id))
        .toList();

    final lista = <FornecedorServicoDetalhadoDto>[];
    for (final idFornecedor in fornecedoresSemCategoria) {
      final doc = await _db.collection('fornecedor').doc(idFornecedor).get();
      final data = doc.data();
      if (data == null) continue;

      lista.add(
        FornecedorServicoDetalhadoDto(
          id: idFornecedor,
          idFornecedor: idFornecedor,
          idProdutoServico: '',
          idSubcategoria: null,
          nomeServico: 'Sem serviços vinculados',
          descricaoServico: data['descricao'] ??
              'Fornecedor parceiro do Faça a Festa — aguardando cadastro de categorias.',
          preco: 0.0,
          precoPromocao: null,
          nomeSubcategoria: null,
          nomeCategoria: 'Sem categoria',
          imagemUrl: data['bannerUrl'],
          ativo: true,
          quantidade: 1,
        ),
      );
    }
    return lista;
  }

  Future<List<FornecedorServicoDetalhadoDto>> _montarServicosPorCategorias({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> categoriasDocs,
    String? fornecedorFixo,
    required bool usarPrecoFornecedor,
  }) async {
    final lista = <FornecedorServicoDetalhadoDto>[];
    for (final doc in categoriasDocs) {
      final data = doc.data();
      final idFornecedor =
          fornecedorFixo ?? (data['id_fornecedor'] ?? '').toString();
      final nomeCategoria = data['nome_categoria'] ?? '';
      final subcategorias = (data['subcategorias'] as List?) ?? const [];

      for (final sub in subcategorias) {
        final subData = sub is Map ? sub : const <String, dynamic>{};
        final idSub = subData['idSubcategoria'];
        final nomeSub = subData['nomeSubcategoria'] ?? 'Sem subcategoria';
        if (idSub == null || idSub.toString().isEmpty) continue;

        final servSnap = await _db
            .collection('servico_produto')
            .where('id_subcategoria', isEqualTo: idSub)
            .where('ativo', isEqualTo: true)
            .get();

        final precoFornecedor = usarPrecoFornecedor
            ? await _buscarPrecoFornecedor(
                idFornecedor: idFornecedor,
                idSubcategoria: idSub,
              )
            : const _PrecoFornecedor();

        for (final servDoc in servSnap.docs) {
          final servData = servDoc.data();
          final imagemUrl = await _buscarImagemServico(
            idFornecedor: idFornecedor,
            idProdutoServico: servDoc.id,
          );
          final nomeFornecedor = fornecedorFixo == null
              ? await _buscarNomeFornecedor(idFornecedor)
              : null;

          lista.add(
            FornecedorServicoDetalhadoDto(
              id: fornecedorFixo == null
                  ? servDoc.id
                  : '${idFornecedor}_${servDoc.id}',
              idFornecedor: idFornecedor,
              idProdutoServico: servDoc.id,
              idSubcategoria: idSub,
              nomeServico: servData['nome'],
              nomeFornecedor: nomeFornecedor,
              descricaoServico: servData['descricao'],
              preco: usarPrecoFornecedor
                  ? precoFornecedor.preco
                  : (servData['preco'] as num?)?.toDouble() ?? 0.0,
              precoPromocao: usarPrecoFornecedor
                  ? precoFornecedor.precoPromocao
                  : (servData['preco_promocao'] as num?)?.toDouble(),
              nomeSubcategoria: nomeSub,
              nomeCategoria: nomeCategoria,
              imagemUrl: imagemUrl,
              ativo: servData['ativo'] ?? true,
              quantidade: 1,
            ),
          );
        }
      }
    }
    return lista;
  }

  Future<String?> _buscarImagemServico({
    required String idFornecedor,
    required String idProdutoServico,
  }) async {
    final fotoSnap = await _db
        .collection('servico_foto')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('id_produto_servico', isEqualTo: idProdutoServico)
        .limit(1)
        .get();
    return fotoSnap.docs.isNotEmpty
        ? fotoSnap.docs.first.data()['url'] as String?
        : null;
  }

  Future<_PrecoFornecedor> _buscarPrecoFornecedor({
    required String idFornecedor,
    required String idSubcategoria,
  }) async {
    final snap = await _db
        .collection('fornecedor_servico')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('id_subcategoria', isEqualTo: idSubcategoria)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return const _PrecoFornecedor();
    final data = snap.docs.first.data();
    return _PrecoFornecedor(
      preco: (data['preco'] as num?)?.toDouble() ?? 0.0,
      precoPromocao: (data['preco_promocao'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Future<String> _buscarNomeFornecedor(String idFornecedor) async {
    final doc = await _db.collection('fornecedor').doc(idFornecedor).get();
    final data = doc.data();
    return data?['razao_social'] ??
        data?['nome'] ??
        data?['nome_fantasia'] ??
        'Fornecedor não localizado';
  }

  Iterable<List<T>> _chunks<T>(List<T> values, int size) sync* {
    for (var i = 0; i < values.length; i += size) {
      yield values.sublist(
          i, i + size > values.length ? values.length : i + size);
    }
  }
}

class _PrecoFornecedor {
  const _PrecoFornecedor({
    this.preco = 0.0,
    this.precoPromocao,
  });

  final double preco;
  final double? precoPromocao;
}
