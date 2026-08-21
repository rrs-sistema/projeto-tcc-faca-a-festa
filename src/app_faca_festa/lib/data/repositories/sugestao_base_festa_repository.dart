import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/sugestao_base_festa_repository_contract.dart';
import './../models/evento/sugestao_base_festa_model.dart';

class SugestaoBaseFestaRepository
    implements SugestaoBaseFestaRepositoryContract {
  SugestaoBaseFestaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'ia_sugestoes_base';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Future<List<SugestaoBaseFestaModel>> buscarSugestoesAtivasPorModulo({
    required String modulo,
  }) async {
    final moduloNormalizado = _normalize(modulo);
    if (moduloNormalizado.isEmpty) return <SugestaoBaseFestaModel>[];

    final snapshot = await _collection
        .where('ativo', isEqualTo: true)
        .where('modulo', isEqualTo: moduloNormalizado)
        .orderBy('ordem')
        .get();

    return snapshot.docs
        .map(SugestaoBaseFestaModel.fromFirestore)
        .where((item) => item.ativo && item.modulo == moduloNormalizado)
        .toList();
  }

  @override
  Future<void> ativarDesativarSugestao({
    required String id,
    required bool ativo,
  }) async {
    if (id.trim().isEmpty) {
      throw ArgumentError(
          'ID da sugestão é obrigatório para ativar/desativar.');
    }

    await _collection.doc(id.trim()).update({
      'ativo': ativo,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> excluirLogicamente(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('ID da sugestão é obrigatório para exclusão lógica.');
    }

    await _collection.doc(id.trim()).update({
      'ativo': false,
      'excluido': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> atualizarSugestao(SugestaoBaseFestaModel sugestao) async {
    if (sugestao.id.trim().isEmpty) {
      throw ArgumentError('ID da sugestão é obrigatório para atualização.');
    }

    final data = sugestao.toMap(includeDates: false);
    data['updated_at'] = FieldValue.serverTimestamp();

    await _collection
        .doc(sugestao.id.trim())
        .set(data, SetOptions(merge: true));
  }

  @override
  Future<List<SugestaoBaseFestaModel>> listarSugestoes() async {
    final snapshot = await _collection.orderBy('ordem').get();

    return snapshot.docs
        .map(SugestaoBaseFestaModel.fromFirestore)
        .where((item) => !item.excluido)
        .toList();
  }

  Future<List<SugestaoBaseFestaModel>>
      buscarSugestoesAtivasPorModuloETipoEvento({
    required String modulo,
    String? tipoEvento,
  }) async {
    final sugestoes = await buscarSugestoesAtivasPorModulo(modulo: modulo);
    final tipoNormalizado = _normalize(tipoEvento ?? '');

    if (tipoNormalizado.isEmpty) {
      return sugestoes;
    }

    return sugestoes
        .where((item) => item.aceitaTipoEvento(tipoNormalizado))
        .toList();
  }

  Future<List<SugestaoBaseFestaModel>> buscarSugestoesParaCalculadora({
    String? tipoEvento,
    String? perfilFesta,
    int limit = 12,
  }) async {
    final sugestoes = await buscarSugestoesAtivasPorModulo(
      modulo: ModuloSugestaoIA.calculadora.value,
    );

    final tipoNormalizado = _normalize(tipoEvento ?? '');
    final perfilNormalizado = _normalize(perfilFesta ?? '');

    final filtradas = sugestoes.where((item) {
      final aceitaTipo = item.aceitaTipoEvento(tipoNormalizado);
      final aceitaPerfil = item.aceitaPerfilFesta(perfilNormalizado);
      return aceitaTipo && aceitaPerfil;
    }).toList();

    if (filtradas.isNotEmpty) {
      return _ordenarEPriorizar(filtradas).take(limit).toList();
    }

    // Fallback: caso não exista sugestão específica para o tipo/perfil,
    // retorna sugestões genéricas do módulo calculadora.
    final genericas = sugestoes.where((item) {
      final tipoGenerico =
          item.tipoEvento.isEmpty || item.tipoEvento.contains('todos');
      final perfilGenerico =
          item.perfisFesta.isEmpty || item.perfisFesta.contains('todos');
      return tipoGenerico || perfilGenerico;
    }).toList();

    return _ordenarEPriorizar(genericas.isNotEmpty ? genericas : sugestoes)
        .take(limit)
        .toList();
  }

  @override
  Future<void> salvarSugestao(SugestaoBaseFestaModel sugestao) async {
    final id = sugestao.id.trim().isNotEmpty
        ? sugestao.id.trim()
        : _collection.doc().id;
    final model = sugestao.copyWith(id: id);

    await _collection.doc(id).set(
          model.toMap(includeDates: true),
          SetOptions(merge: true),
        );
  }

  @override
  Future<int> importarSugestoesTeste(
    List<Map<String, dynamic>> sugestoes, {
    bool sobrescrever = true,
  }) async {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    for (final item in sugestoes) {
      final id = (item['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;

      final ref = _collection.doc(id);
      final data = <String, dynamic>{
        ...item,
        'id': id,
        'deleted': false,
        'created_at': now,
        'updated_at': now,
      };

      if (sobrescrever) {
        batch.set(ref, data, SetOptions(merge: true));
      } else {
        final snapshot = await ref.get();
        if (!snapshot.exists) {
          batch.set(ref, data);
        }
      }
    }

    await batch.commit();
    return sugestoes.length;
  }

  List<SugestaoBaseFestaModel> _ordenarEPriorizar(
    List<SugestaoBaseFestaModel> sugestoes,
  ) {
    final list = List<SugestaoBaseFestaModel>.from(sugestoes);
    list.sort((a, b) {
      final prioridadeCompare = _pesoPrioridade(b.prioridade).compareTo(
        _pesoPrioridade(a.prioridade),
      );
      if (prioridadeCompare != 0) return prioridadeCompare;
      return a.ordem.compareTo(b.ordem);
    });
    return list;
  }

  int _pesoPrioridade(String prioridade) {
    switch (_normalize(prioridade)) {
      case 'critica':
        return 4;
      case 'alta':
        return 3;
      case 'media':
        return 2;
      case 'baixa':
        return 1;
      default:
        return 0;
    }
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  }
}
