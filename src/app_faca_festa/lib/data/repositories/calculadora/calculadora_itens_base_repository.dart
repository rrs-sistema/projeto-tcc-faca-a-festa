import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

import '../../models/calculadora/calculadora_evento_item_model.dart';
import '../../models/calculadora/calculadora_item_base_model.dart';

class CalculadoraItensBaseRepository {
  static const String collectionItensBase = 'calculadora_itens_base';
  static const String collectionEventoItens = 'calculadora_evento_itens';

  static const String fieldAtivo = 'ativo';
  static const String fieldOrdem = 'ordem';
  static const String fieldTipoEvento = 'tipo_evento';
  static const String fieldPerfisFesta = 'perfis_festa';
  static const String fieldUpdatedAt = 'updated_at';

  final FirebaseFirestore _firestore;

  CalculadoraItensBaseRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _itensBaseRef {
    return _firestore.collection(collectionItensBase);
  }

  CollectionReference<Map<String, dynamic>> get _eventoItensRef {
    return _firestore.collection(collectionEventoItens);
  }

  Future<List<CalculadoraItemBaseModel>> listarItensBaseAtivos() async {
    try {
      final snapshot =
          await _itensBaseRef.where(fieldAtivo, isEqualTo: true).orderBy(fieldOrdem).get();

      return _mapItensBase(snapshot);
    } on FirebaseException catch (error, stackTrace) {
      _logError(
        method: 'listarItensBaseAtivos',
        error: error,
        stackTrace: stackTrace,
      );

      if (_isIndexError(error)) {
        return _listarItensBaseAtivosFallbackLocalSort();
      }

      return <CalculadoraItemBaseModel>[];
    } catch (error, stackTrace) {
      _logError(
        method: 'listarItensBaseAtivos',
        error: error,
        stackTrace: stackTrace,
      );

      return <CalculadoraItemBaseModel>[];
    }
  }

  Future<List<CalculadoraEventoItemModel>> listarItensEventoAtivos() async {
    try {
      final snapshot =
          await _eventoItensRef.where(fieldAtivo, isEqualTo: true).orderBy(fieldOrdem).get();

      return _mapEventoItens(snapshot);
    } on FirebaseException catch (error, stackTrace) {
      _logError(
        method: 'listarItensEventoAtivos',
        error: error,
        stackTrace: stackTrace,
      );

      if (_isIndexError(error)) {
        return _listarItensEventoAtivosFallbackLocalSort();
      }

      return <CalculadoraEventoItemModel>[];
    } catch (error, stackTrace) {
      _logError(
        method: 'listarItensEventoAtivos',
        error: error,
        stackTrace: stackTrace,
      );

      return <CalculadoraEventoItemModel>[];
    }
  }

  Future<List<CalculadoraEventoItemModel>> buscarItensPorTipoEvento({
    required String tipoEvento,
    String? perfilFesta,
  }) async {
    final tipoEventoKey = _normalizarChave(tipoEvento);
    final perfilFestaKey = _normalizarChave(perfilFesta ?? '');

    if (tipoEventoKey.isEmpty) {
      return <CalculadoraEventoItemModel>[];
    }

    try {
      Query<Map<String, dynamic>> query = _eventoItensRef
          .where(fieldAtivo, isEqualTo: true)
          .where(fieldTipoEvento, isEqualTo: tipoEventoKey);

      if (perfilFestaKey.isNotEmpty) {
        query = query.where(
          fieldPerfisFesta,
          arrayContains: perfilFestaKey,
        );
      }

      final snapshot = await query.orderBy(fieldOrdem).get();

      return _mapEventoItens(snapshot);
    } on FirebaseException catch (error, stackTrace) {
      _logError(
        method: 'buscarItensPorTipoEvento',
        error: error,
        stackTrace: stackTrace,
      );

      if (_isIndexError(error)) {
        return _buscarItensPorTipoEventoFallbackLocalFilter(
          tipoEventoKey: tipoEventoKey,
          perfilFestaKey: perfilFestaKey,
        );
      }

      return <CalculadoraEventoItemModel>[];
    } catch (error, stackTrace) {
      _logError(
        method: 'buscarItensPorTipoEvento',
        error: error,
        stackTrace: stackTrace,
      );

      return <CalculadoraEventoItemModel>[];
    }
  }

  Future<List<CalculadoraEventoItemModel>> buscarItensPorTipoEventoComFallback({
    required String tipoEvento,
    String? perfilFesta,
  }) async {
    final perfilFestaKey = _normalizarChave(perfilFesta ?? '');

    final itensComPerfil = await buscarItensPorTipoEvento(
      tipoEvento: tipoEvento,
      perfilFesta: perfilFestaKey.isEmpty ? null : perfilFestaKey,
    );

    if (itensComPerfil.isNotEmpty) {
      return itensComPerfil;
    }

    if (perfilFestaKey.isNotEmpty) {
      final itensSemPerfil = await buscarItensPorTipoEvento(
        tipoEvento: tipoEvento,
      );

      if (itensSemPerfil.isNotEmpty) {
        return itensSemPerfil;
      }
    }

    return <CalculadoraEventoItemModel>[];
  }

  Future<CalculadoraEventoItemModel?> buscarItemEventoPorId(String id) async {
    final documentId = id.trim();

    if (documentId.isEmpty) {
      return null;
    }

    try {
      final document = await _eventoItensRef.doc(documentId).get();

      if (!document.exists) {
        return null;
      }

      return CalculadoraEventoItemModel.fromFirestore(document);
    } catch (error, stackTrace) {
      _logError(
        method: 'buscarItemEventoPorId',
        error: error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  Future<void> salvarItemBase(CalculadoraItemBaseModel item) async {
    final documentId = item.id.trim();

    if (documentId.isEmpty) {
      throw ArgumentError(
        'Não é possível salvar um item base sem id.',
      );
    }

    try {
      final itemToSave = item.copyWith(
        updatedAt: DateTime.now(),
      );

      await _itensBaseRef.doc(documentId).set(
            itemToSave.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (error, stackTrace) {
      _logError(
        method: 'salvarItemBase',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  Future<void> salvarItemEvento(CalculadoraEventoItemModel item) async {
    final documentId = item.id.trim();

    if (documentId.isEmpty) {
      throw ArgumentError(
        'Não é possível salvar um item de evento sem id.',
      );
    }

    try {
      final itemToSave = item.copyWith(
        tipoEvento: _normalizarChave(item.tipoEvento),
        perfisFesta: item.perfisFesta.map(_normalizarChave).toList(),
        updatedAt: DateTime.now(),
      );

      await _eventoItensRef.doc(documentId).set(
            itemToSave.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (error, stackTrace) {
      _logError(
        method: 'salvarItemEvento',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  Future<void> ativarDesativarItemEvento(
    String id,
    bool ativo,
  ) async {
    final documentId = id.trim();

    if (documentId.isEmpty) {
      throw ArgumentError(
        'Não é possível ativar/desativar um item de evento sem id.',
      );
    }

    try {
      await _eventoItensRef.doc(documentId).update({
        fieldAtivo: ativo,
        fieldUpdatedAt: Timestamp.fromDate(DateTime.now()),
      });
    } catch (error, stackTrace) {
      _logError(
        method: 'ativarDesativarItemEvento',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  Future<List<CalculadoraItemBaseModel>> _listarItensBaseAtivosFallbackLocalSort() async {
    try {
      final snapshot = await _itensBaseRef.where(fieldAtivo, isEqualTo: true).get();

      return _mapItensBase(snapshot);
    } catch (error, stackTrace) {
      _logError(
        method: '_listarItensBaseAtivosFallbackLocalSort',
        error: error,
        stackTrace: stackTrace,
      );

      return _listarTodosItensBaseFiltrandoLocal();
    }
  }

  Future<List<CalculadoraEventoItemModel>> _listarItensEventoAtivosFallbackLocalSort() async {
    try {
      final snapshot = await _eventoItensRef.where(fieldAtivo, isEqualTo: true).get();

      return _mapEventoItens(snapshot);
    } catch (error, stackTrace) {
      _logError(
        method: '_listarItensEventoAtivosFallbackLocalSort',
        error: error,
        stackTrace: stackTrace,
      );

      return _listarTodosItensEventoFiltrandoLocal();
    }
  }

  Future<List<CalculadoraEventoItemModel>> _buscarItensPorTipoEventoFallbackLocalFilter({
    required String tipoEventoKey,
    required String perfilFestaKey,
  }) async {
    try {
      final snapshot = await _eventoItensRef
          .where(fieldAtivo, isEqualTo: true)
          .where(fieldTipoEvento, isEqualTo: tipoEventoKey)
          .get();

      final itens = _mapEventoItens(snapshot);

      return _filtrarEventoItensLocalmente(
        itens: itens,
        tipoEventoKey: tipoEventoKey,
        perfilFestaKey: perfilFestaKey,
      );
    } catch (error, stackTrace) {
      _logError(
        method: '_buscarItensPorTipoEventoFallbackLocalFilter',
        error: error,
        stackTrace: stackTrace,
      );

      final itens = await _listarTodosItensEventoFiltrandoLocal();

      return _filtrarEventoItensLocalmente(
        itens: itens,
        tipoEventoKey: tipoEventoKey,
        perfilFestaKey: perfilFestaKey,
      );
    }
  }

  Future<List<CalculadoraItemBaseModel>> _listarTodosItensBaseFiltrandoLocal() async {
    try {
      final snapshot = await _itensBaseRef.get();

      final itens = snapshot.docs
          .map(CalculadoraItemBaseModel.fromFirestore)
          .where((item) => item.ativo)
          .toList();

      _ordenarItensBase(itens);

      return itens;
    } catch (error, stackTrace) {
      _logError(
        method: '_listarTodosItensBaseFiltrandoLocal',
        error: error,
        stackTrace: stackTrace,
      );

      return <CalculadoraItemBaseModel>[];
    }
  }

  Future<List<CalculadoraEventoItemModel>> _listarTodosItensEventoFiltrandoLocal() async {
    try {
      final snapshot = await _eventoItensRef.get();

      final itens = snapshot.docs
          .map(CalculadoraEventoItemModel.fromFirestore)
          .where((item) => item.ativo)
          .toList();

      _ordenarEventoItens(itens);

      return itens;
    } catch (error, stackTrace) {
      _logError(
        method: '_listarTodosItensEventoFiltrandoLocal',
        error: error,
        stackTrace: stackTrace,
      );

      return <CalculadoraEventoItemModel>[];
    }
  }

  List<CalculadoraItemBaseModel> _mapItensBase(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final itens = snapshot.docs
        .map(CalculadoraItemBaseModel.fromFirestore)
        .where((item) => item.ativo)
        .toList();

    _ordenarItensBase(itens);

    return itens;
  }

  List<CalculadoraEventoItemModel> _mapEventoItens(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final itens = snapshot.docs
        .map(CalculadoraEventoItemModel.fromFirestore)
        .where((item) => item.ativo)
        .toList();

    _ordenarEventoItens(itens);

    return itens;
  }

  List<CalculadoraEventoItemModel> _filtrarEventoItensLocalmente({
    required List<CalculadoraEventoItemModel> itens,
    required String tipoEventoKey,
    required String perfilFestaKey,
  }) {
    final filtrados = itens.where((item) {
      final mesmoTipoEvento = _normalizarChave(item.tipoEvento) == tipoEventoKey;

      if (!mesmoTipoEvento) {
        return false;
      }

      if (perfilFestaKey.isEmpty) {
        return true;
      }

      return item.perfisFesta.any(
        (perfil) => _normalizarChave(perfil) == perfilFestaKey,
      );
    }).toList();

    _ordenarEventoItens(filtrados);

    return filtrados;
  }

  void _ordenarItensBase(List<CalculadoraItemBaseModel> itens) {
    itens.sort((a, b) {
      final compareOrdem = a.ordem.compareTo(b.ordem);

      if (compareOrdem != 0) {
        return compareOrdem;
      }

      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });
  }

  void _ordenarEventoItens(List<CalculadoraEventoItemModel> itens) {
    itens.sort((a, b) {
      final compareOrdem = a.ordem.compareTo(b.ordem);

      if (compareOrdem != 0) {
        return compareOrdem;
      }

      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });
  }

  bool _isIndexError(FirebaseException error) {
    return error.code == 'failed-precondition' ||
        error.message?.toLowerCase().contains('index') == true;
  }

  String _normalizarChave(String value) {
    var text = value.trim().toLowerCase();

    if (text.isEmpty) {
      return '';
    }

    text = _removerAcentos(text);

    text = text
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_'), '')
        .replaceAll(RegExp(r'_$'), '');

    return text;
  }

  String _removerAcentos(String value) {
    const accents = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    var result = value;

    accents.forEach((accented, plain) {
      result = result.replaceAll(accented, plain);
    });

    return result;
  }

  void _logError({
    required String method,
    required Object error,
    required StackTrace stackTrace,
  }) {
    developer.log(
      'Erro em CalculadoraItensBaseRepository.$method',
      name: 'CalculadoraItensBaseRepository',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
