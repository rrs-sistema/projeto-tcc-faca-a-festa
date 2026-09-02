import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/endereco/endereco_usuario.dart';
import '../../models/evento/evento_model.dart';
import '../../models/fornecedor/fornecedor_admin_snapshot.dart';
import '../../models/fornecedor/fornecedor_estatisticas_model.dart';
import '../../models/fornecedor/fornecedor_model.dart';
import '../../models/servico_produto/categoria_servico_model.dart';
import '../../models/servico_produto/fornecedor_categoria_model.dart';
import '../../models/servico_produto/fornecedor_produto_servico_model.dart';
import '../../models/servico_produto/subcategoria_servico_model.dart';

abstract interface class FornecedorRemoteDatasource {
  Future<FornecedorAdminSnapshot> carregarSnapshotAdmin({
    required bool incluirEnderecos,
  });

  Future<FornecedorModel?> buscarPorUsuario(String idUsuario);

  Future<FornecedorModel?> buscarPorIdUsuario(String idUsuario);

  Future<EventoModel?> buscarEventoPorId(String idEvento);

  Stream<FornecedorModel?> observarFornecedorAtivo(String idFornecedor);

  Stream<int> observarMensagensNaoLidas(String idFornecedor);

  Stream<int> observarSolicitacoesPendentes(String idFornecedor);

  Stream<List<FornecedorProdutoServicoModel>> observarServicosFornecedor(
    String idFornecedor,
  );

  Future<List<FornecedorProdutoServicoModel>> listarServicosPorEvento(
    String idEvento,
  );

  Future<List<FornecedorModel>> listarFornecedoresDoEvento(String idEvento);

  Future<List<Map<String, dynamic>>> listarSolicitacoesPendentesDetalhadas(
    String idFornecedor,
  );

  Future<FornecedorEstatisticasModel> carregarEstatisticas(
    String idFornecedor,
  );

  Future<void> atualizarFornecedor(FornecedorModel fornecedor);

  Future<void> salvarFornecedor(FornecedorModel fornecedor);

  Future<void> salvarCategoriaFornecedor(FornecedorCategoriaModel categoria);

  Future<void> atualizarStatusAtivo({
    required String idFornecedor,
    required bool ativo,
  });

  Future<void> atualizarAptoParaOperar({
    required String idFornecedor,
    required bool apto,
  });

  Future<void> atualizarFcmToken({
    required String idFornecedor,
    required String token,
  });

  Future<String> uploadBanner({
    required File imageFile,
    Uint8List? bytesWeb,
    required String uid,
  });

  Future<int> limparDuplicatasFornecedorCategoria();
}

class FirebaseFornecedorRemoteDatasource implements FornecedorRemoteDatasource {
  FirebaseFornecedorRemoteDatasource(
    this.firestore, {
    required this.storage,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final DateTime Function() _now;

  @override
  Future<FornecedorAdminSnapshot> carregarSnapshotAdmin({
    required bool incluirEnderecos,
  }) async {
    final fornecedoresSnap = await firestore.collection('fornecedor').get();
    final listaFornecedores = fornecedoresSnap.docs
        .map((d) => FornecedorModel.fromMap(d.data(), documentId: d.id))
        .toList()
      ..sort(_ordenarFornecedorAdmin);

    final enderecos = <EnderecoUsuarioModel>[];
    if (incluirEnderecos) {
      final endSnap = await firestore.collectionGroup('enderecos').get();
      enderecos.addAll(
        endSnap.docs.map((d) => EnderecoUsuarioModel.fromMap(d.data())),
      );
    }

    final catSnap = await firestore.collection('fornecedor_categoria').get();
    final categoriasFornecedor = catSnap.docs
        .map((d) => FornecedorCategoriaModel.fromMap(d.data()))
        .toList();

    final catServSnap = await firestore.collection('categoria_servico').get();
    final categoriasServico = catServSnap.docs
        .map((d) => {
              'id': d.data()['id'] ?? d.id,
              'nome': d.data()['nome'],
              'descricao': d.data()['descricao'],
              'ativo': d.data()['ativo'],
            })
        .toList();
    final categorias = catServSnap.docs
        .map((d) => CategoriaServicoModel.fromMap(d.data(), documentId: d.id))
        .toList();

    final subcatSnap = await firestore.collection('subcategoria_servico').get();
    final subcategoriasServico = subcatSnap.docs
        .map((d) => {
              'id': d.data()['id'] ?? d.id,
              'nome': d.data()['nome'],
              'id_categoria':
                  d.data()['id_categoria'] ?? d.data()['idCategoria'],
              'descricao': d.data()['descricao'],
              'ativo': d.data()['ativo'],
            })
        .toList();
    final subcategorias = subcatSnap.docs
        .map(
          (d) => SubcategoriaServicoModel.fromMap(d.data(), documentId: d.id),
        )
        .toList();

    final servicosSnap = await firestore.collection('fornecedor_servico').get();
    final servicosFornecedor = servicosSnap.docs
        .map(
          (doc) => FornecedorProdutoServicoModel.fromMap({
            'id': doc.id,
            ...doc.data(),
          }),
        )
        .toList();

    return FornecedorAdminSnapshot(
      fornecedores: listaFornecedores,
      enderecos: enderecos,
      categoriasFornecedor: categoriasFornecedor,
      categoriasServico: categoriasServico,
      categorias: categorias,
      subcategoriasServico: subcategoriasServico,
      subcategorias: subcategorias,
      servicosFornecedor: servicosFornecedor,
    );
  }

  @override
  Future<FornecedorModel?> buscarPorUsuario(String idUsuario) async {
    final doc = await firestore.collection('fornecedor').doc(idUsuario).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return FornecedorModel.fromMap(data, documentId: doc.id);
  }

  @override
  Future<FornecedorModel?> buscarPorIdUsuario(String idUsuario) async {
    final snapshot = await firestore
        .collection('fornecedor')
        .where('id_usuario', isEqualTo: idUsuario)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return FornecedorModel.fromMap(doc.data(), documentId: doc.id);
  }

  @override
  Future<EventoModel?> buscarEventoPorId(String idEvento) async {
    final id = idEvento.trim();
    if (id.isEmpty) return null;

    final byDocumentId = await firestore.collection('evento').doc(id).get();
    if (byDocumentId.exists && byDocumentId.data() != null) {
      return EventoModel.fromMap(byDocumentId.data()!);
    }

    final snapshot = await firestore
        .collection('evento')
        .where('id_evento', isEqualTo: id)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return EventoModel.fromMap(snapshot.docs.first.data());
  }

  @override
  Stream<FornecedorModel?> observarFornecedorAtivo(String idFornecedor) {
    return firestore
        .collection('fornecedor')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('ativo', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return FornecedorModel.fromMap(doc.data(), documentId: doc.id);
    });
  }

  @override
  Stream<int> observarMensagensNaoLidas(String idFornecedor) {
    final id = idFornecedor.trim();
    if (id.isEmpty) return Stream<int>.value(0);

    late StreamController<int> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? cotacoesSub;
    final mensagemSubs =
        <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
    final contadores = <String, int>{};

    Future<void> cancelarMensagens() async {
      for (final sub in mensagemSubs.values) {
        await sub.cancel();
      }
      mensagemSubs.clear();
      contadores.clear();
    }

    void emitirTotal() {
      if (!controller.isClosed) {
        controller.add(contadores.values.fold<int>(0, (t, v) => t + v));
      }
    }

    controller = StreamController<int>.broadcast(
      onListen: () {
        cotacoesSub = firestore
            .collectionGroup('fornecedores')
            .where('id_fornecedor', isEqualTo: id)
            .snapshots()
            .listen((fornecedorSnap) {
          final cotacoesAtuais = <String>{};

          for (final f in fornecedorSnap.docs) {
            final cotacaoRef = f.reference.parent.parent;
            if (cotacaoRef == null) continue;

            final idCotacao = cotacaoRef.id;
            cotacoesAtuais.add(idCotacao);
            if (mensagemSubs.containsKey(idCotacao)) continue;

            contadores[idCotacao] = 0;
            mensagemSubs[idCotacao] = cotacaoRef
                .collection('fornecedores')
                .doc(id)
                .collection('mensagens')
                .where('id_usuario', isNotEqualTo: id)
                .where('lido', isEqualTo: false)
                .snapshots()
                .listen((msgSnap) {
              contadores[idCotacao] = msgSnap.docs.length;
              emitirTotal();
            }, onError: controller.addError);
          }

          final removidas = contadores.keys
              .where((idCotacao) => !cotacoesAtuais.contains(idCotacao))
              .toList();
          for (final idCotacao in removidas) {
            contadores.remove(idCotacao);
            mensagemSubs.remove(idCotacao)?.cancel();
          }
          emitirTotal();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await cotacoesSub?.cancel();
        await cancelarMensagens();
      },
    );

    return controller.stream;
  }

  @override
  Stream<int> observarSolicitacoesPendentes(String idFornecedor) {
    final id = idFornecedor.trim();
    if (id.isEmpty) return Stream<int>.value(0);
    return firestore
        .collectionGroup('fornecedores')
        .where('id_fornecedor', isEqualTo: id)
        .where('status', isEqualTo: 'aguardando')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Stream<List<FornecedorProdutoServicoModel>> observarServicosFornecedor(
    String idFornecedor,
  ) {
    final id = idFornecedor.trim();
    if (id.isEmpty) {
      return Stream<List<FornecedorProdutoServicoModel>>.value(
        const <FornecedorProdutoServicoModel>[],
      );
    }
    return firestore
        .collection('fornecedor_servico')
        .where('id_fornecedor', isEqualTo: id)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (d) => FornecedorProdutoServicoModel.fromMap({
                  'id': d.id,
                  ...d.data(),
                }),
              )
              .toList(),
        );
  }

  @override
  Future<List<FornecedorProdutoServicoModel>> listarServicosPorEvento(
    String idEvento,
  ) async {
    final orcamentosSnap = await firestore
        .collection('orcamento')
        .where('id_evento', isEqualTo: idEvento)
        .get();

    final fornecedoresIds = orcamentosSnap.docs
        .map((d) => d.data()['id_servico_fornecido'])
        .where((id) => id != null && id.toString().isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    if (fornecedoresIds.isEmpty) {
      return <FornecedorProdutoServicoModel>[];
    }

    final servicos = <FornecedorProdutoServicoModel>[];
    for (final chunk in _dividirChunks(fornecedoresIds, 30)) {
      final servicosSnap = await firestore
          .collection('fornecedor_servico')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      servicos.addAll(
        servicosSnap.docs.map(
          (d) => FornecedorProdutoServicoModel.fromMap({
            'id': d.id,
            ...d.data(),
          }),
        ),
      );
    }
    return servicos;
  }

  @override
  Future<List<FornecedorModel>> listarFornecedoresDoEvento(
    String idEvento,
  ) async {
    final servicos = await listarServicosPorEvento(idEvento);
    final fornecedorIds = servicos
        .map((s) => s.idFornecedor)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();
    if (fornecedorIds.isEmpty) return <FornecedorModel>[];

    final fornecedores = <FornecedorModel>[];
    for (final chunk in _dividirChunks(fornecedorIds, 30)) {
      final fornecedoresSnap = await firestore
          .collection('fornecedor')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      fornecedores.addAll(
        fornecedoresSnap.docs.map(
          (d) => FornecedorModel.fromMap(d.data(), documentId: d.id),
        ),
      );
    }
    return fornecedores;
  }

  @override
  Future<List<Map<String, dynamic>>> listarSolicitacoesPendentesDetalhadas(
    String idFornecedor,
  ) async {
    final id = idFornecedor.trim();
    if (id.isEmpty) return <Map<String, dynamic>>[];

    final resultado = <Map<String, dynamic>>[];
    final snapshot = await firestore
        .collectionGroup('fornecedores')
        .where('id_fornecedor', isEqualTo: id)
        .where('status', isEqualTo: 'aguardando')
        .get();

    for (final doc in snapshot.docs) {
      final dataFornecedor = doc.data();
      final cotacaoRef = doc.reference.parent.parent;
      if (cotacaoRef == null) continue;

      final cotacaoSnap = await cotacaoRef.get();
      if (!cotacaoSnap.exists) continue;

      final dataCotacao = cotacaoSnap.data() ?? <String, dynamic>{};
      resultado.add({
        'idCotacao': cotacaoRef.id,
        'categoriaNome': dataCotacao['categoria_nome'] ?? 'Cotação',
        'descricao': dataCotacao['observacao'] ?? '',
        'dataEnvio': dataCotacao['data_envio'],
        'dataLimite': dataCotacao['data_limite_resposta'],
        'status': dataCotacao['status'],
        'idEvento': dataCotacao['id_evento'],
        'idUsuarioSolicitante': dataCotacao['id_usuario_solicitante'],
        'prazoEntrega': dataFornecedor['prazo_entrega'],
        'condicaoPagamento': dataFornecedor['condicao_pagamento'],
        'observacaoFornecedor': dataFornecedor['observacao_fornecedor'],
        'nomeSolicitante': dataCotacao['nome_usuario_solicitante'],
        'valorEstimadoTotal': dataCotacao['valor_estimado_total'] ?? 0.0,
      });
    }

    return resultado;
  }

  @override
  Future<FornecedorEstatisticasModel> carregarEstatisticas(
    String idFornecedor,
  ) async {
    final orcSnap = await firestore
        .collection('orcamento')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .get();

    final pendentes = orcSnap.docs.where((d) {
      final status = d.data()['status']?.toString().toLowerCase();
      return status == 'pendente' || status == 'em_negociacao';
    }).length;

    final servSnap = await firestore
        .collection('fornecedor_servico')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('ativo', isEqualTo: true)
        .get();

    final msgSnap = await firestore
        .collectionGroup('mensagens')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('lida', isEqualTo: false)
        .get();

    final avalSnap = await firestore
        .collection('avaliacoes')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .get();

    var media = 0.0;
    if (avalSnap.docs.isNotEmpty) {
      final soma = avalSnap.docs
          .map((d) => (d.data()['nota'] as num?)?.toDouble() ?? 0.0)
          .fold<double>(0, (total, nota) => total + nota);
      media = soma / avalSnap.docs.length;
    }

    return FornecedorEstatisticasModel(
      solicitacoesPendentes: pendentes,
      servicosAtivos: servSnap.docs
          .map(
            (d) => FornecedorProdutoServicoModel.fromMap({
              'id': d.id,
              ...d.data(),
            }),
          )
          .toList(),
      mensagensNaoLidas: msgSnap.docs.length,
      avaliacaoMedia: media,
    );
  }

  @override
  Future<void> atualizarFornecedor(FornecedorModel fornecedor) {
    return firestore
        .collection('fornecedor')
        .doc(fornecedor.idFornecedor)
        .update(fornecedor.toMap());
  }

  @override
  Future<void> salvarFornecedor(FornecedorModel fornecedor) {
    return firestore
        .collection('fornecedor')
        .doc(fornecedor.idFornecedor)
        .set(fornecedor.toMap());
  }

  @override
  Future<void> salvarCategoriaFornecedor(FornecedorCategoriaModel categoria) {
    return firestore.collection('fornecedor_categoria').add(categoria.toMap());
  }

  @override
  Future<void> atualizarStatusAtivo({
    required String idFornecedor,
    required bool ativo,
  }) {
    return firestore.collection('fornecedor').doc(idFornecedor).update({
      'ativo': ativo,
    });
  }

  @override
  Future<void> atualizarAptoParaOperar({
    required String idFornecedor,
    required bool apto,
  }) {
    return firestore.collection('fornecedor').doc(idFornecedor).update({
      'apto_para_operar': apto,
    });
  }

  @override
  Future<void> atualizarFcmToken({
    required String idFornecedor,
    required String token,
  }) {
    return firestore.collection('fornecedor').doc(idFornecedor).update({
      'fcm_token': token,
    });
  }

  @override
  Future<String> uploadBanner({
    required File imageFile,
    Uint8List? bytesWeb,
    required String uid,
  }) async {
    final nomeArquivo = imageFile.path.split(RegExp(r'[\\/]')).last;
    final fileName =
        'banners_fornecedores/$uid/${_now().millisecondsSinceEpoch}_$nomeArquivo';
    final ref = storage.ref().child(fileName);
    final uploadTask =
        bytesWeb != null ? ref.putData(bytesWeb) : ref.putFile(imageFile);
    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  @override
  Future<int> limparDuplicatasFornecedorCategoria() async {
    final snap = await firestore.collection('fornecedor_categoria').get();
    final agrupados =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      final fornecedor = data['id_fornecedor'] ?? '';
      final categoria = data['id_categoria'] ?? '';
      if (fornecedor.isEmpty || categoria.isEmpty) continue;

      final chave = '$fornecedor|$categoria';
      agrupados.putIfAbsent(
          chave, () => <QueryDocumentSnapshot<Map<String, dynamic>>>[]);
      agrupados[chave]!.add(doc);
    }

    var duplicatasRemovidas = 0;
    for (final lista in agrupados.values) {
      if (lista.length <= 1) continue;

      lista.sort((a, b) {
        final da = a.data()['data_cadastro'];
        final db = b.data()['data_cadastro'];
        return da.toString().compareTo(db.toString());
      });

      final principal = lista.first;
      final dataPrincipal = Map<String, dynamic>.from(principal.data());
      final subcategoriasPrincipais =
          List<Map<String, dynamic>>.from(dataPrincipal['subcategorias'] ?? []);

      for (final duplicada in lista.skip(1)) {
        final dataDup = Map<String, dynamic>.from(duplicada.data());
        final subs =
            List<Map<String, dynamic>>.from(dataDup['subcategorias'] ?? []);

        for (final sub in subs) {
          final idSub = sub['idSubcategoria'];
          final jaExiste =
              subcategoriasPrincipais.any((s) => s['idSubcategoria'] == idSub);
          if (!jaExiste) {
            subcategoriasPrincipais.add(sub);
          }
        }

        await firestore
            .collection('fornecedor_categoria')
            .doc(duplicada.id)
            .delete();
        duplicatasRemovidas++;
      }

      await firestore
          .collection('fornecedor_categoria')
          .doc(principal.id)
          .update({
        'subcategorias': subcategoriasPrincipais,
        'nome_categoria': dataPrincipal['nome_categoria'] ?? '',
      });
    }

    return duplicatasRemovidas;
  }

  int _ordenarFornecedorAdmin(FornecedorModel a, FornecedorModel b) {
    if (a.ativo != b.ativo) return b.ativo ? 1 : -1;
    if (a.aptoParaOperar != b.aptoParaOperar) {
      return b.aptoParaOperar ? 1 : -1;
    }
    return a.razaoSocial.toLowerCase().compareTo(b.razaoSocial.toLowerCase());
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
