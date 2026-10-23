import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/transacao_firestore.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_dados_cadastrais.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_cadastro_edicao.dart';
import '../../models/usuario/usuario_model.dart';

import '../../models/cotacao/cotacao_model.dart';
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
  Future<FornecedorCadastroEdicao> carregarCadastroEdicao(String idFornecedor);
  Future<void> salvarCadastroEdicao(FornecedorCadastroAlteracao alteracao);
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

  Future<List<CotacaoModel>> listarSolicitacoesPendentesDetalhadas(
    String idFornecedor,
  );

  Future<FornecedorEstatisticasModel> carregarEstatisticas(
    String idFornecedor,
  );

  Future<void> atualizarFornecedor(FornecedorModel fornecedor);

  Future<void> atualizarDadosCadastrais({
    required String idFornecedor,
    required FornecedorDadosCadastrais dados,
  });

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
    required List<int> bytes,
    required String nomeArquivo,
    required String uid,
  });

  Future<int> limparDuplicatasFornecedorCategoria();
}

class FirebaseFornecedorRemoteDatasource implements FornecedorRemoteDatasource {
  @override
  Future<FornecedorCadastroEdicao> carregarCadastroEdicao(
      String idFornecedor) async {
    final doc =
        await firestore.collection('fornecedor').doc(idFornecedor).get();
    if (!doc.exists) throw StateError('Fornecedor não encontrado.');
    final fornecedor = FornecedorModel.fromMap(
        {...doc.data()!, 'id_fornecedor': doc.id},
        documentId: doc.id);
    final uid = fornecedor.idUsuario.trim();
    if (uid.isEmpty) {
      throw StateError(
          'Este fornecedor não possui um usuário responsável vinculado.');
    }
    final resultados = await Future.wait([
      firestore.collection('usuarios').doc(uid).get(),
      firestore.collection('usuarios').doc(uid).collection('enderecos').get(),
      firestore
          .collection('fornecedor_categoria')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get(),
      firestore
          .collection('fornecedor_servico')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .get(),
    ]);
    final usuarioDoc = resultados[0] as DocumentSnapshot<Map<String, dynamic>>;
    if (!usuarioDoc.exists) {
      throw StateError('O usuário responsável vinculado não foi encontrado.');
    }
    final enderecos =
        (resultados[1] as QuerySnapshot<Map<String, dynamic>>).docs;
    final end =
        enderecos.where((e) => e.data()['principal'] == true).firstOrNull ??
            enderecos.firstOrNull;
    final categorias = (resultados[2] as QuerySnapshot<Map<String, dynamic>>)
        .docs
        .map((d) => FornecedorCategoriaModel.fromMap(d.data()))
        .toList();
    if (categorias.isEmpty) {
      categorias.addAll(fornecedor.categorias
          .where((c) => c.idCategoria.isNotEmpty)
          .map((c) => FornecedorCategoriaModel(
              idFornecedor: fornecedor.idFornecedor,
              idCategoria: c.idCategoria,
              nomeCategoria: c.nomeCategoria,
              subcategorias: c.subcategorias)));
    }
    return FornecedorCadastroEdicao(
      fornecedor: fornecedor,
      usuario: UsuarioModel.fromMap({...usuarioDoc.data()!, 'id_usuario': uid}),
      endereco: end == null
          ? null
          : EnderecoUsuarioModel.fromMap(
              {...end.data(), 'id': end.id, 'id_usuario': uid}),
      categorias: categorias,
      vinculos: (resultados[3] as QuerySnapshot<Map<String, dynamic>>)
          .docs
          .map((d) =>
              FornecedorProdutoServicoModel.fromMap({...d.data(), 'id': d.id}))
          .toList(),
      revisao: (doc.data()!['cadastro_revisao'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> salvarCadastroEdicao(
      FornecedorCadastroAlteracao alteracao) async {
    final origem = alteracao.origem;
    final id = origem.fornecedor.idFornecedor;
    final uid = origem.fornecedor.idUsuario;
    if (id.isEmpty || uid.isEmpty || alteracao.endereco.idUsuario != uid) {
      throw StateError('Vínculo do cadastro inválido. Reabra a edição.');
    }
    final categoriasAtuais = await firestore
        .collection('fornecedor_categoria')
        .where('id_fornecedor', isEqualTo: id)
        .get();
    final servicosAtuais = await firestore
        .collection('fornecedor_servico')
        .where('id_fornecedor', isEqualTo: id)
        .get();
    if (categoriasAtuais.size +
            servicosAtuais.size +
            alteracao.categorias.length +
            alteracao.servicos.length >
        450) {
      throw StateError(
          'Este catálogo excede o limite desta edição. Reduza a seleção antes de salvar.');
    }
    final fornecedorRef = firestore.collection('fornecedor').doc(id);
    final usuarioRef = firestore.collection('usuarios').doc(uid);
    final endereco = alteracao.endereco.copyWith(
        id: origem.endereco?.id ?? 'principal',
        principal: origem.endereco?.principal ?? true);
    await executarTransacaoFirestore(() => firestore.runTransaction((tx) async {
          final atual = await tx.get(fornecedorRef);
          final usuario = await tx.get(usuarioRef);
          if (!atual.exists ||
              !usuario.exists ||
              (atual.data()?['id_usuario'] ?? atual.data()?['idUsuario']) !=
                  uid) {
            throw StateError('O vínculo do fornecedor mudou. Reabra a edição.');
          }
          if (((atual.data()?['cadastro_revisao'] as num?)?.toInt() ?? 0) !=
              origem.revisao) {
            throw StateError(
                'Outro administrador atualizou este cadastro. Reabra para revisar os dados atuais.');
          }
          tx.update(fornecedorRef, {
            ...alteracao.dados.toMap(),
            if (alteracao.novoBannerUrl != null)
              'banner_url': alteracao.novoBannerUrl,
            'tipoEventoIds': alteracao.tipoEventoIds,
            'tipo_evento_ids': alteracao.tipoEventoIds,
            'tipoEventoSlugs': alteracao.tipoEventoSlugs,
            'tipo_evento_slugs': alteracao.tipoEventoSlugs,
            'tipoEventoNomes': alteracao.tipoEventoNomes,
            'tipo_evento_nomes': alteracao.tipoEventoNomes,
            'categorias': alteracao.categorias
                .map((c) => {
                      'idCategoria': c.idCategoria,
                      'nomeCategoria': c.nomeCategoria,
                      'subcategorias': c.subcategorias
                          .map((s) => {
                                'idSubcategoria': s.idSubcategoria,
                                'nomeSubcategoria': s.nomeSubcategoria
                              })
                          .toList()
                    })
                .toList(),
            'cadastro_revisao': origem.revisao + 1,
          });
          tx.update(usuarioRef, {
            'nome': alteracao.nomeResponsavel.trim(),
            'cidade': endereco.nomeCidade,
            'uf': endereco.uf
          });
          tx.set(
              usuarioRef.collection('enderecos').doc(endereco.id),
              EnderecoUsuarioModel.fromEntity(endereco).toMap(),
              SetOptions(merge: true));
          final categoriasPorId = {
            for (final c in alteracao.categorias) c.idCategoria: c
          };
          final gravadas = <String>{};
          for (final doc in categoriasAtuais.docs) {
            final categoriaId = doc.data()['id_categoria']?.toString();
            final categoria = categoriasPorId[categoriaId];
            if (categoria == null || !gravadas.add(categoria.idCategoria)) {
              tx.delete(doc.reference);
            } else {
              final map = FornecedorCategoriaModel.fromEntity(
                      categoria.copyWith(idFornecedor: id))
                  .toMap()
                ..remove('data_cadastro');
              tx.update(doc.reference, map);
            }
          }
          for (final categoria in alteracao.categorias) {
            if (!gravadas.add(categoria.idCategoria)) continue;
            tx.set(
                firestore
                    .collection('fornecedor_categoria')
                    .doc('${id}_${categoria.idCategoria}'),
                FornecedorCategoriaModel.fromEntity(
                        categoria.copyWith(idFornecedor: id))
                    .toMap());
          }
          final selecionados = {for (final s in alteracao.servicos) s.id: s};
          final encontrados = <String>{};
          final preferidos = <String, String>{};
          for (final doc in servicosAtuais.docs) {
            final servicoId = (doc.data()['id_produto_servico'] ??
                        doc.data()['idProdutoServico'])
                    ?.toString() ??
                '';
            if (doc.data()['ativo'] != false) {
              preferidos.putIfAbsent(servicoId, () => doc.id);
            }
          }
          for (final doc in servicosAtuais.docs) {
            final servicoId = (doc.data()['id_produto_servico'] ??
                        doc.data()['idProdutoServico'])
                    ?.toString() ??
                '';
            preferidos.putIfAbsent(servicoId, () => doc.id);
          }
          for (final doc in servicosAtuais.docs) {
            final servicoId = (doc.data()['id_produto_servico'] ??
                        doc.data()['idProdutoServico'])
                    ?.toString() ??
                '';
            final selecionado = selecionados.containsKey(servicoId) &&
                preferidos[servicoId] == doc.id;
            // Mantém preço, fotos, notas e IDs existentes; não exclui histórico.
            tx.update(doc.reference, {
              'ativo': selecionado,
              'data_atualizacao': FieldValue.serverTimestamp()
            });
            encontrados.add(servicoId);
          }
          for (final servico in selecionados.values) {
            if (encontrados.contains(servico.id)) continue;
            final vinculoId = '${id}_${servico.id}';
            tx.set(
                firestore.collection('fornecedor_servico').doc(vinculoId),
                FornecedorProdutoServicoModel(
                  id: vinculoId,
                  idFornecedor: id,
                  idProdutoServico: servico.id,
                  idSubcategoria: servico.idSubcategoria,
                  preco: 0,
                ).toMap());
          }
        }));
  }

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
    final categorias = catServSnap.docs
        .map((d) => CategoriaServicoModel.fromMap(d.data(), documentId: d.id))
        .toList();

    final subcatSnap = await firestore.collection('subcategoria_servico').get();
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
      categorias: categorias,
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
  Future<List<CotacaoModel>> listarSolicitacoesPendentesDetalhadas(
    String idFornecedor,
  ) async {
    final id = idFornecedor.trim();
    if (id.isEmpty) return <CotacaoModel>[];

    final resultado = <CotacaoModel>[];
    final snapshot = await firestore
        .collectionGroup('fornecedores')
        .where('id_fornecedor', isEqualTo: id)
        .where('status', isEqualTo: 'aguardando')
        .get();

    for (final doc in snapshot.docs) {
      final cotacaoRef = doc.reference.parent.parent;
      if (cotacaoRef == null) continue;

      final cotacaoSnap = await cotacaoRef.get();
      if (!cotacaoSnap.exists) continue;

      final cotacao = CotacaoModel.fromMap(
        cotacaoSnap.data() ?? <String, dynamic>{},
        cotacaoRef.id,
      );
      if (cotacao.id.trim().isEmpty) continue;
      resultado.add(cotacao);
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
  Future<void> atualizarDadosCadastrais({
    required String idFornecedor,
    required FornecedorDadosCadastrais dados,
  }) =>
      firestore
          .collection('fornecedor')
          .doc(idFornecedor)
          .update(dados.toMap());

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
    required List<int> bytes,
    required String nomeArquivo,
    required String uid,
  }) async {
    final fileName =
        'banners_fornecedores/$uid/${_now().millisecondsSinceEpoch}_$nomeArquivo';
    final ref = storage.ref().child(fileName);
    final snapshot = await ref.putData(Uint8List.fromList(bytes));
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
