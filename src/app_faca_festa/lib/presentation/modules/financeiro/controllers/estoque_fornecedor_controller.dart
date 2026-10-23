import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'package:app_faca_festa/data/datasources/remote/estoque_fornecedor_remote_datasource.dart';
import 'package:app_faca_festa/domain/entities/financeiro/item_estoque_fornecedor.dart';
import 'package:app_faca_festa/domain/services/estoque_fornecedor_service.dart';

class EstoqueFornecedorController extends GetxController {
  EstoqueFornecedorController({
    required FirebaseFirestore firestore,
    required this.idFornecedor,
    String? Function()? usuarioAtual,
    EstoqueFornecedorRemoteDatasource? remote,
  })  : _firestore = firestore,
        _usuarioAtual = usuarioAtual,
        _remote = remote;

  final FirebaseFirestore _firestore;
  final String idFornecedor;
  final String? Function()? _usuarioAtual;
  final EstoqueFornecedorRemoteDatasource? _remote;
  final _uuid = const Uuid();

  final itens = <ItemEstoqueFornecedor>[].obs;
  final alertas = <AlertaEstoqueFornecedor>[].obs;
  final carregando = false.obs;
  final enviando = false.obs;
  final erro = ''.obs;
  final filtroNatureza = ''.obs;
  final buscaTexto = ''.obs;

  final List<StreamSubscription> _subs = [];
  int _geracao = 0;

  bool get autorizado {
    final uid = _usuarioAtual?.call();
    return uid != null && uid == idFornecedor && idFornecedor.isNotEmpty;
  }

  @override
  void onClose() {
    aoTrocarSessao();
    super.onClose();
  }

  void aoTrocarSessao() {
    _geracao++;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  Future<void> iniciar() async {
    final geracao = ++_geracao;
    aoTrocarSessao();
    _geracao = geracao;
    erro.value = '';
    if (!autorizado) {
      erro.value = 'Sem autorização para o estoque privado.';
      itens.clear();
      return;
    }
    carregando.value = true;
    final base = _firestore.collection('fornecedor').doc(idFornecedor);
    _subs.add(base.collection('estoque_itens').snapshots().listen((snap) {
      if (geracao != _geracao) return;
      itens.assignAll(
        snap.docs.map((d) {
          final m = Map<String, dynamic>.from(d.data());
          m['id_item'] = d.id;
          return ItemEstoqueFornecedor.fromMap(m);
        }),
      );
      _recalcularAlertas();
      carregando.value = false;
    }, onError: (e) {
      if (geracao != _geracao) return;
      erro.value = 'Falha ao ouvir estoque: $e';
      carregando.value = false;
    }));
  }

  void _recalcularAlertas() {
    final lista = <AlertaEstoqueFornecedor>[];
    for (final item in itens) {
      lista.addAll(
        EstoqueFornecedorService.avaliarAlertas(item: item, reservas: const []),
      );
    }
    alertas.assignAll(lista);
  }

  List<ItemEstoqueFornecedor> get itensFiltrados {
    final n = filtroNatureza.value;
    final q = buscaTexto.value.trim().toLowerCase();
    Iterable<ItemEstoqueFornecedor> base = itens;
    if (n.isNotEmpty) {
      base = base.where((i) => i.natureza.valor == n);
    }
    if (q.isNotEmpty) {
      base = base.where((i) => i.nome.toLowerCase().contains(q));
    }
    return base.toList();
  }

  /// Quantidade de cadastros por tipo (não soma quantidades físicas).
  Map<String, int> contagemCadastrosPorTipo() {
    var consumivel = 0;
    var reutilizavel = 0;
    var locado = 0;
    for (final i in itens) {
      switch (i.natureza) {
        case NaturezaItemEstoque.consumivel:
          consumivel++;
        case NaturezaItemEstoque.reutilizavel:
          reutilizavel++;
        case NaturezaItemEstoque.locadoTerceiro:
          locado++;
      }
    }
    return {
      'consumivel': consumivel,
      'reutilizavel': reutilizavel,
      'locado_terceiro': locado,
      'total': itens.length,
    };
  }

  List<AlertaEstoqueAgrupado> get alertasAgrupados =>
      agruparAlertasEstoque(alertas);

  void limparFiltros() {
    filtroNatureza.value = '';
    buscaTexto.value = '';
  }

  Future<void> cadastrarItem({
    required String nome,
    required String natureza,
    required int quantidade,
    required int custoUnitarioCentavos,
    int custoUsoCentavos = 0,
    int montagemMinutos = 0,
    int desmontagemMinutos = 0,
    String unidade = 'un',
  }) async {
    final remote = _remote;
    if (!autorizado || remote == null) {
      erro.value = 'Sem autorização.';
      return;
    }
    if (enviando.value) return;
    enviando.value = true;
    final geracao = _geracao;
    final uid = _usuarioAtual?.call();
    try {
      await remote.cadastrarItem(
        idFornecedor: idFornecedor,
        nome: nome,
        natureza: natureza,
        quantidadeTotal: quantidade,
        custoUnitarioCentavos: custoUnitarioCentavos,
        custoUsoCentavos: custoUsoCentavos,
        montagemMinutos: montagemMinutos,
        desmontagemMinutos: desmontagemMinutos,
        unidade: unidade,
      );
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return;
      erro.value = '';
    } catch (e) {
      if (geracao != _geracao) return;
      erro.value = e.toString();
    } finally {
      enviando.value = false;
    }
  }

  Future<String?> reservar({
    required String idItem,
    required String idEvento,
    required int quantidade,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    final remote = _remote;
    if (!autorizado || remote == null) {
      erro.value = 'Sem autorização.';
      return null;
    }
    if (enviando.value) return null;
    enviando.value = true;
    final geracao = _geracao;
    final uid = _usuarioAtual?.call();
    try {
      final res = await remote.reservar(
        idFornecedor: idFornecedor,
        idItem: idItem,
        idEvento: idEvento,
        quantidade: quantidade,
        inicioIso: inicio.toIso8601String(),
        fimIso: fim.toIso8601String(),
        chaveIdempotencia: _uuid.v4(),
      );
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return null;
      return res['idReserva']?.toString();
    } catch (e) {
      erro.value = e.toString();
      return null;
    } finally {
      enviando.value = false;
    }
  }

  Future<Map<String, dynamic>?> consumir({
    required String idItem,
    required String idEvento,
    required int quantidade,
    String? idReserva,
  }) async {
    final remote = _remote;
    if (!autorizado || remote == null) {
      erro.value = 'Sem autorização.';
      return null;
    }
    if (enviando.value) return null;
    enviando.value = true;
    final geracao = _geracao;
    final uid = _usuarioAtual?.call();
    try {
      final res = await remote.consumir(
        idFornecedor: idFornecedor,
        idItem: idItem,
        idEvento: idEvento,
        quantidade: quantidade,
        chaveIdempotencia: _uuid.v4(),
        idReserva: idReserva,
      );
      if (geracao != _geracao || uid != _usuarioAtual?.call()) return null;
      return res;
    } catch (e) {
      erro.value = e.toString();
      return null;
    } finally {
      enviando.value = false;
    }
  }
}

class AlertaEstoqueAgrupado {
  const AlertaEstoqueAgrupado({
    required this.codigo,
    required this.mensagem,
    required this.severidade,
    required this.quantidade,
    required this.itens,
  });

  final String codigo;
  final String mensagem;
  final String severidade;
  final int quantidade;
  final List<String> itens;
}

/// Agrupa alertas pela mesma causa (código + mensagem).
List<AlertaEstoqueAgrupado> agruparAlertasEstoque(
  List<AlertaEstoqueFornecedor> origem,
) {
  final map = <String, AlertaEstoqueAgrupado>{};
  for (final a in origem) {
    final key = '${a.codigo}|${a.mensagem}';
    final prev = map[key];
    if (prev == null) {
      map[key] = AlertaEstoqueAgrupado(
        codigo: a.codigo,
        mensagem: a.mensagem,
        severidade: a.severidade,
        quantidade: 1,
        itens: [if (a.idItem != null && a.idItem!.isNotEmpty) a.idItem!],
      );
    } else {
      final itens = [...prev.itens];
      if (a.idItem != null &&
          a.idItem!.isNotEmpty &&
          !itens.contains(a.idItem)) {
        itens.add(a.idItem!);
      }
      map[key] = AlertaEstoqueAgrupado(
        codigo: prev.codigo,
        mensagem: prev.mensagem,
        severidade: prev.severidade,
        quantidade: prev.quantidade + 1,
        itens: itens,
      );
    }
  }
  return map.values.toList();
}
