import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../local/cadastro_armazenamento.dart';
import 'agenda_servico_remote.dart';
import '../../../domain/services/plano_execucao_service.dart';
import '../../../domain/services/compromisso_planejamento_service.dart';
import '../../models/cardapio/cardapio_model.dart';
import '../../models/cardapio/cardapio_item_model.dart';

class PlanoExecucaoRemoteDatasource {
  PlanoExecucaoRemoteDatasource(this.db, this.auth,
      {this.enviar,
      this.functions,
      this.emulador,
      ArmazenamentoCadastroLocal? recuperacao})
      : recuperacao = recuperacao ?? criarArmazenamentoCadastro();
  final ArmazenamentoCadastroLocal recuperacao;
  String _prefixo(String uid, String evento) =>
      'execucao_v1_${base64Url.encode(utf8.encode(uid))}_${base64Url.encode(utf8.encode(evento))}_';
  final FirebaseFunctions? functions;
  final Uri? emulador;
  final Future<dynamic> Function(Map<String, dynamic>)? enviar;
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  static dynamic normalizar(dynamic v) {
    if (v is Timestamp) {
      return {'__timestamp': v.toDate().toUtc().toIso8601String()};
    }
    if (v is GeoPoint) {
      return {
        '__geo': [v.latitude, v.longitude]
      };
    }
    if (v is DocumentReference) return {'__ref': v.path};
    if (v is Map) return v.map((k, v) => MapEntry(k.toString(), normalizar(v)));
    if (v is List) return v.map(normalizar).toList();
    return v;
  }

  Future<ContextoExecucaoPlano> carregar(String evento) async {
    final uid = auth.currentUser?.uid;
    if (uid == null || evento.isEmpty || evento.contains('/')) {
      throw StateError('Entre na conta do organizador.');
    }
    final fontes = <String, Map<String, dynamic>?>{};
    void fonte(DocumentSnapshot<Map<String, dynamic>> d) {
      fontes[d.reference.path] =
          d.exists ? Map<String, dynamic>.from(normalizar(d.data())) : null;
      if (fontes.length > 240) {
        throw StateError(
            'Há muitos registros para uma aplicação conjunta. Organize por etapas.');
      }
    }

    final ev = await db
        .collection('evento')
        .doc(evento)
        .get(const GetOptions(source: Source.server));
    if (ev.data()?['id_usuario'] != uid) {
      throw StateError('Somente o organizador pode aplicar o plano.');
    }
    fonte(ev);
    final recibos = <String>[];
    final recuperados = <String>[];
    for (final entry
        in (await recuperacao.listar(_prefixo(uid, evento))).entries) {
      final pedido = jsonDecode(entry.value)['pedido'] as String;
      if (pedido.isEmpty || pedido.contains('/')) {
        throw StateError('A recuperação local precisa de conferência.');
      }
      final recibo = await db
          .doc('calculadora_operacao/$evento/aplicacoes/$pedido')
          .get(const GetOptions(source: Source.server));
      if (auth.currentUser?.uid != uid) {
        throw StateError('Sua sessão mudou. Reabra o evento.');
      }
      if (recibo.exists && recibo.data()?['id_usuario'] == uid) {
        recibos.add(pedido);
        recuperados.add(entry.key);
      }
    }
    final op = await db
        .collection('calculadora_operacao')
        .doc(evento)
        .get(const GetOptions(source: Source.server));
    fonte(op);
    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> consulta(
        Query<Map<String, dynamic>> q, int max) async {
      final docs =
          (await q.limit(max + 1).get(const GetOptions(source: Source.server)))
              .docs;
      if (docs.length > max) {
        throw StateError(
            'A consulta excede o limite da revisão conjunta. Nenhum dado foi aplicado.');
      }
      for (final d in docs) {
        fonte(d);
      }
      return docs;
    }

    final menusRaw = await consulta(
        db.collection('cardapios').where('id_evento', isEqualTo: evento), 20);
    final menus = menusRaw
        .map((d) => CardapioModel.fromMap(
            {...d.data(), 'id_cardapio': d.id, 'id_evento': evento}))
        .where((m) => m.ativo)
        .toList();
    final itens = <String, List<CardapioItemModel>>{};
    for (final menu in menus) {
      final docs = await consulta(
          db.collection('cardapios').doc(menu.idCardapio).collection('itens'),
          60);
      itens[menu.idCardapio] = docs
          .map((d) => CardapioItemModel.fromMap({
                ...d.data(),
                'id_evento': evento,
                'id_cardapio': menu.idCardapio,
                'id_item': d.id
              }))
          .toList();
    }
    // Conhecidos na revisão: alterações em presenças impedem uma aplicação antiga.
    await consulta(
        db.collection('convidado').where('id_evento', isEqualTo: evento), 120);
    final gastos = await consulta(
        db.collection('orcamento').where('id_evento', isEqualTo: evento), 40);
    final compromissos = <Map<String, dynamic>>[];
    for (final g in gastos) {
      final filhos =
          await consulta(g.reference.collection('orcamento_gasto'), 40);
      final m = const CompromissoPlanejamentoService()
          .mapear(g.id, g.data(), gastos: filhos.map((d) => d.data()).toList());
      if (m != null) compromissos.add(m);
    }
    final tarefas = await consulta(
        db.collection('tarefa').where('id_evento', isEqualTo: evento), 100);
    if (auth.currentUser?.uid != uid) {
      throw StateError('Sua sessão mudou. Reabra o evento.');
    }
    for (final chave in recuperados) {
      await recuperacao.remover(chave);
    }
    return ContextoExecucaoPlano(
        recibosRecuperados: recibos,
        evento: evento,
        fontes: fontes,
        operacao: op.data() ?? {},
        cardapios: menus,
        itens: itens,
        compromissos: compromissos,
        tarefas: {for (final t in tarefas) t.id: t.data()});
  }

  Future<bool> aplicar(PropostaExecucaoPlano p) async {
    final uid = auth.currentUser?.uid;
    final evento = p.contexto.evento;
    if (uid == null ||
        p.pedido.isEmpty ||
        p.pedido.contains('/') ||
        p.alteracoes.length > 100 ||
        p.contexto.fontes.length > 240 ||
        utf8.encode(p.assinatura).length > 650000) {
      throw StateError('A revisão não está pronta para aplicar.');
    }
    if (p.contexto.fontes['evento/$evento']?['id_usuario'] != uid) {
      throw StateError(
          'Esta revisão pertence a outro organizador. Reabra o evento.');
    }
    final command = <String, dynamic>{
      'evento': evento,
      'pedido': p.pedido,
      'plano': jsonDecode(p.assinatura),
      'pendencias': p.pendencias,
    };
    final chave =
        '${_prefixo(uid, evento)}${base64Url.encode(utf8.encode(p.pedido))}';
    // Confirmação já autorizada: guarda somente a identidade do pedido antes
    // de enviá-lo. Uma resposta perdida é recuperada pelo recibo do servidor.
    await recuperacao.gravar(chave, jsonEncode({'pedido': p.pedido}));
    try {
      final response = enviar != null
          ? await enviar!(command)
          : functions == null
              ? await CallableCalculadoraRemote(auth, emulador: emulador)
                  .chamar('aplicarPlanoCalculadora', command)
              : (await functions!
                      .httpsCallable('aplicarPlanoCalculadora',
                          options: HttpsCallableOptions(
                              timeout: const Duration(seconds: 120)))
                      .call<dynamic>(command))
                  .data;
      if (response is! Map || response['aplicado'] is! bool) {
        throw StateError(
            'O servidor não confirmou a aplicação. Atualize antes de tentar novamente.');
      }
      if (auth.currentUser?.uid != uid) {
        throw StateError(
            'Sua sessão mudou. Reabra o evento para conferir o recibo.');
      }
      await recuperacao.remover(chave);
      return response['aplicado'] as bool;
    } on FirebaseFunctionsException catch (e) {
      if ([
        'failed-precondition',
        'permission-denied',
        'invalid-argument',
        'unauthenticated'
      ].contains(e.code)) {
        await recuperacao.remover(chave);
      }
      final detalhes = e.details;
      if (detalhes is Map && detalhes['fontes'] is List) {
        final grupos = (detalhes['fontes'] as List)
            .map((path) {
              final raiz = path.toString().split('/').first;
              return switch (raiz) {
                'evento' || 'convidado' => 'público ou dados do evento',
                'cardapios' => 'cardápios e itens',
                'calculadora_operacao' => 'estoque ou escolhas salvas',
                'orcamento' => 'despesas e serviços',
                'tarefa' => 'tarefas',
                _ => 'fontes do planejamento',
              };
            })
            .toSet()
            .join(', ');
        throw StateError(
            'Mudanças encontradas: $grupos. Nenhum efeito deste pedido foi gravado. Atualize pelas fontes atuais e revise novamente.');
      }
      throw StateError(e.message ??
          'Não foi possível aplicar. Atualize a proposta e tente novamente.');
    }
  }
}
