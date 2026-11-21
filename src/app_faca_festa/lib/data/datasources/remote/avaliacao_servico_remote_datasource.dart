import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/avaliacao/avaliacao_model.dart';
import '../../models/fornecedor/avaliacao_servico_model.dart';
import '../../services/stream_da_sessao.dart';

class AvaliacaoServicoRemoteDatasource {
  AvaliacaoServicoRemoteDatasource(
      {required FirebaseFirestore firestore,
      FirebaseFunctions? functions,
      FirebaseAuth? auth})
      : _db = firestore,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'southamerica-east1'),
        _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  Stream<T> _sessao<T>(Stream<T> fonte, T vazio) => streamDaSessao(
      fonte: fonte,
      sessoes: _auth.authStateChanges().map((u) => u?.uid),
      identidade: _auth.currentUser?.uid,
      vazio: vazio);

  Future<Map<String, dynamic>> _paraExibicao(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final d = doc.data();
    final resposta =
        await doc.reference.collection('respostas_publicas').doc('atual').get();
    final confiavel = d['schema'] == 2 &&
        d['verificada'] == true &&
        d['moderacao'] != 'oculta';
    return {
      ...d,
      '_resposta_publica': resposta.data(),
      '_integridade_confirmada': confiavel,
    };
  }

  Future<List<Map<String, dynamic>>> _historico(String fornecedor,
      {String? servico}) async {
    final resultado = <Map<String, dynamic>>[];
    for (final colecao in [
      'avaliacao_fornecedor',
      'avaliacoes',
      'fornecedor_avaliacoes'
    ]) {
      final s = await _db
          .collection(colecao)
          .where('id_fornecedor', isEqualTo: fornecedor)
          .get();
      for (final doc in s.docs) {
        final d = doc.data();
        final objeto = d['id_servico'] ?? d['id_produto_servico'];
        if (servico == null ? objeto == null : objeto == servico) {
          resultado.add({...d, 'id': doc.reference.path, 'verificada': false});
        }
      }
    }
    return resultado;
  }

  Stream<List<AvaliacaoServicoModel>> observarAvaliacoesServico(
      {required String idFornecedor, required String idServico}) {
    final legado = _historico(idFornecedor, servico: idServico);
    final antigos = _db
        .collection('fornecedor_servico')
        .doc('${idFornecedor}_$idServico')
        .collection('avaliacoes')
        .get();
    final fonte = _db
        .collection('fornecedor')
        .doc(idFornecedor)
        .collection('avaliacoes')
        .snapshots()
        .asyncMap((s) async {
      final historico = await legado;
      final velhos = await antigos;
      final novos = s.docs.where((d) =>
          d.data()['tipo'] == 'servico' &&
          d.data()['id_servico'] == idServico &&
          d.data()['moderacao'] != 'oculta');
      final lista = [
        ...historico.map((d) => AvaliacaoServicoModel.fromMap(d,
            idFornecedorServico: '${idFornecedor}_$idServico')),
        ...await Future.wait(novos.map((d) async =>
            AvaliacaoServicoModel.fromMap(await _paraExibicao(d),
                documentId: d.id,
                idFornecedorServico: '${idFornecedor}_$idServico'))),
        ...velhos.docs.map((d) => AvaliacaoServicoModel.fromMap(
            {...d.data(), 'verificada': false},
            documentId: d.id,
            idFornecedorServico: '${idFornecedor}_$idServico'))
      ];
      lista.sort((a, b) => b.data.compareTo(a.data));
      return lista;
    });
    return _sessao(fonte, <AvaliacaoServicoModel>[]);
  }

  Future<double> getMediaServico(
      {required String idFornecedor, required String idServico}) async {
    final s =
        await _db.doc('fornecedor_servico/${idFornecedor}_$idServico').get();
    final r = s.data()?['reputacao_verificada'];
    return r is Map && r['schema'] == 2 ? (r['media'] as num).toDouble() : 0;
  }

  Future<List<Map<String, dynamic>>> contratosAvaliaveis(
      {required String idFornecedor,
      required String idEvento,
      String? idServico,
      String? idOrcamento,
      bool detalhar = false}) async {
    final r =
        await _functions.httpsCallable('consultarContratosAvaliaveis').call({
      'idFornecedor': idFornecedor,
      'idEvento': idEvento,
      if (idServico != null) 'idServico': idServico,
      if (idOrcamento != null) 'idOrcamento': idOrcamento,
      if (detalhar) 'detalhar': true,
    });
    return (r.data['contratos'] as List)
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  Future<void> _enviar(
      {required String idFornecedor,
      required double nota,
      required String comentario,
      String? idEvento,
      String? idServico,
      String? idOrcamento}) async {
    if (idOrcamento == null) {
      if (idEvento == null) {
        throw StateError('Selecione a contratação concluída.');
      }
      final contratos = await contratosAvaliaveis(
          idFornecedor: idFornecedor, idEvento: idEvento, idServico: idServico);
      if (contratos.length != 1) {
        throw StateError('Selecione explicitamente a contratação concluída.');
      }
      idOrcamento = contratos.single['idOrcamento'] as String;
    }
    final inteira = nota.round();
    if (inteira < 1 || inteira > 5 || (nota - inteira).abs() > 0.001) {
      throw StateError('Escolha uma nota inteira de 1 a 5.');
    }
    await _functions.httpsCallable('registrarAvaliacaoVerificada').call({
      'idFornecedor': idFornecedor,
      'idOrcamento': idOrcamento,
      if (idServico != null) 'idServico': idServico,
      'nota': inteira,
      'comentario': comentario
    });
  }

  Future<void> adicionarAvaliacaoServico(
          {required String idFornecedor,
          required String idServico,
          required String idCliente,
          required String nomeCliente,
          required double nota,
          required String comentario,
          String? idEvento,
          String? nomeEvento,
          String? idOrcamento}) =>
      _enviar(
          idFornecedor: idFornecedor,
          idServico: idServico,
          nota: nota,
          comentario: comentario,
          idEvento: idEvento,
          idOrcamento: idOrcamento);
  Future<void> adicionarAvaliacaoFornecedor(
          {required String idFornecedor,
          required String idCliente,
          required String nomeCliente,
          required double nota,
          required String comentario,
          String? idEvento,
          String? nomeEvento,
          String? idOrcamento}) =>
      _enviar(
          idFornecedor: idFornecedor,
          nota: nota,
          comentario: comentario,
          idEvento: idEvento,
          idOrcamento: idOrcamento);
  Stream<List<AvaliacaoModel>> observarAvaliacoesFornecedor(
          String idFornecedor) {
    final legado = _historico(idFornecedor);
    return _sessao(
        _db
            .collection('fornecedor')
            .doc(idFornecedor)
            .collection('avaliacoes')
            .snapshots()
            .asyncMap((s) async {
          final historico = await legado;
          final lista = await Future.wait(s.docs
              .where((d) =>
                  d.data()['tipo'] != 'servico' &&
                  d.data()['moderacao'] != 'oculta')
              .map((d) async => AvaliacaoModel.fromMap(
                  {...await _paraExibicao(d), 'id': d.id})));
          lista.addAll(historico.map(AvaliacaoModel.fromMap));
          lista.sort((a, b) => b.data.compareTo(a.data));
          return lista;
        }),
        <AvaliacaoModel>[]);
  }
  Future<bool> podeAvaliarFornecedor(
          {required String idFornecedor,
          required String idEvento,
          required String idUsuario}) async =>
      (await contratosAvaliaveis(
              idFornecedor: idFornecedor, idEvento: idEvento))
          .isNotEmpty;
  Future<bool> podeAvaliarCotacao(
          {required String idFornecedor,
          required String idEvento,
          required String idUsuario}) =>
      podeAvaliarFornecedor(
          idFornecedor: idFornecedor, idEvento: idEvento, idUsuario: idUsuario);
}
