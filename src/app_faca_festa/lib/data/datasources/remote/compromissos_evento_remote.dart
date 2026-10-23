import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_faca_festa/domain/services/compromisso_planejamento_service.dart';

class CompromissosEventoRemote {
  const CompromissosEventoRemote(this.db);
  final FirebaseFirestore db;

  static bool _semPermissao(Object e) {
    if (e is FirebaseException) {
      return e.code == 'permission-denied';
    }
    return e.toString().contains('permission-denied');
  }

  /// Subcoleção financeira: sem permissão → lista vazia (legado via pai/gastos).
  Future<List<Map<String, dynamic>>> _lerSubcolecao(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    try {
      final snap = await ref.get(const GetOptions(source: Source.server));
      return snap.docs.map((d) => d.data()).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return const [];
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> listarCompromissosDoEvento(
      String idEvento) async {
    final snapshot = await db
        .collection('orcamento')
        .where('id_evento', isEqualTo: idEvento)
        .get(const GetOptions(source: Source.server));
    final resultados = await Future.wait(snapshot.docs.map((doc) async {
      final gastos = await _lerSubcolecao(doc.reference.collection('orcamento_gasto'));
      final liquidacoes =
          await _lerSubcolecao(doc.reference.collection('liquidacoes'));
      return const CompromissoPlanejamentoService().mapear(doc.id, doc.data(),
          gastos: gastos, liquidacoes: liquidacoes);
    }));
    return resultados.whereType<Map<String, dynamic>>().toList();
  }

  Stream<List<Map<String, dynamic>>> observarCompromissosDoEvento(
      String idEvento) {
    late StreamController<List<Map<String, dynamic>>> saida;
    StreamSubscription? pais;
    final filhos = <StreamSubscription>[];
    var versao = 0;
    saida = StreamController<List<Map<String, dynamic>>>(onListen: () {
      pais = db
          .collection('orcamento')
          .where('id_evento', isEqualTo: idEvento)
          .snapshots(includeMetadataChanges: true)
          .listen((snapshot) async {
        final atual = ++versao;
        final antigos = filhos.toList();
        filhos.clear();
        await Future.wait(antigos.map((s) => s.cancel()));
        if (atual != versao || saida.isClosed) return;
        final cache = <String, Map<String, dynamic>?>{};
        if (snapshot.docs.isEmpty) {
          // Lista vazia (cache ou servidor) não é falha — evita bloquear a UI
          // com "Não foi possível atualizar o financeiro" sem orçamentos.
          saida.add([]);
        }
        for (final doc in snapshot.docs) {
          final gastosCache = <String, List<Map<String, dynamic>>>{};
          final liqCache = <String, List<Map<String, dynamic>>>{};
          final metaSync = <String, bool>{};
          void publicar() {
            if (atual != versao || saida.isClosed) return;
            if (!gastosCache.containsKey(doc.id) ||
                !liqCache.containsKey(doc.id)) {
              return;
            }
            cache[doc.id] = const CompromissoPlanejamentoService().mapear(
                doc.id, doc.data(),
                gastos: gastosCache[doc.id]!, liquidacoes: liqCache[doc.id]!);
            if (cache[doc.id] != null) {
              cache[doc.id]!['consulta_sincronizada'] =
                  metaSync['gastos'] == true && metaSync['liq'] == true;
            }
            if (cache.length == snapshot.docs.length) {
              saida
                  .add(cache.values.whereType<Map<String, dynamic>>().toList());
            }
          }

          void aoNegarSub(
            String chaveCache,
            Map<String, List<Map<String, dynamic>>> destino,
          ) {
            destino[doc.id] = const [];
            metaSync[chaveCache] = true;
            publicar();
          }

          filhos.add(doc.reference
              .collection('orcamento_gasto')
              .snapshots(includeMetadataChanges: true)
              .listen((gastos) {
            if (atual != versao || saida.isClosed) return;
            gastosCache[doc.id] = gastos.docs.map((g) => g.data()).toList();
            metaSync['gastos'] = !snapshot.metadata.isFromCache &&
                !snapshot.metadata.hasPendingWrites &&
                !gastos.metadata.isFromCache &&
                !gastos.metadata.hasPendingWrites;
            publicar();
          }, onError: (Object e) {
            if (atual != versao || saida.isClosed) return;
            if (_semPermissao(e)) {
              aoNegarSub('gastos', gastosCache);
              return;
            }
            saida.addError(e);
          }));
          filhos.add(doc.reference
              .collection('liquidacoes')
              .snapshots(includeMetadataChanges: true)
              .listen((liq) {
            if (atual != versao || saida.isClosed) return;
            liqCache[doc.id] = liq.docs.map((l) => l.data()).toList();
            metaSync['liq'] = !snapshot.metadata.isFromCache &&
                !snapshot.metadata.hasPendingWrites &&
                !liq.metadata.isFromCache &&
                !liq.metadata.hasPendingWrites;
            publicar();
          }, onError: (Object e) {
            if (atual != versao || saida.isClosed) return;
            if (_semPermissao(e)) {
              aoNegarSub('liq', liqCache);
              return;
            }
            saida.addError(e);
          }));
        }
      }, onError: (Object e) {
        if (!saida.isClosed) saida.addError(e);
      });
    }, onCancel: () async {
      versao++;
      await pais?.cancel();
      await Future.wait(filhos.map((s) => s.cancel()));
    });
    return saida.stream;
  }
}
