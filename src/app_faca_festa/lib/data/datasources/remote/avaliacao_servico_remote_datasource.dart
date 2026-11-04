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

  Future<Map<String, dynamic>> _comprovar(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final d = doc.data();
    var comprovada = false;
    if (d['schema'] == 2 &&
        d['id_contrato'] is String &&
        (d['id_contrato'] as String).isNotEmpty) {
      final h =
          await doc.reference.collection('historico').doc('criacao').get();
      comprovada = h.data()?['acao'] == 'criar' &&
          [
            'id_contrato',
            'id_cliente',
            'id_fornecedor',
            'id_servico',
            'tipo',
            'nota',
            'comentario'
          ].every((k) => h.data()?[k] == d[k]);
    }
    final resposta=await doc.reference.collection('respostas_publicas').doc('atual').get();
    return {
      ...d,
      '_resposta_publica':resposta.data(),
      '_integridade_confirmada': comprovada,
      'verificada': d['verificada'] == true && comprovada
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
    // Uma consulta canônica, sem espelho da avaliação do fornecedor.
    final fonte = _db
        .collection('fornecedor')
        .doc(idFornecedor)
        .collection('avaliacoes')
        .snapshots()
        .asyncMap((s) async {
      final historico = await _historico(idFornecedor, servico: idServico);
      final antigos = await _db
          .collection('fornecedor_servico')
          .doc('${idFornecedor}_$idServico')
          .collection('avaliacoes')
          .get();
      final novos = s.docs.where((d) =>
          d.data()['tipo'] == 'servico' &&
          d.data()['id_servico'] == idServico &&
          d.data()['moderacao'] != 'oculta');
      final lista = [
        ...historico.map((d) => AvaliacaoServicoModel.fromMap(d,
            idFornecedorServico: '${idFornecedor}_$idServico')),
        ...await Future.wait(novos.map((d) async =>
            AvaliacaoServicoModel.fromMap(await _comprovar(d),
                documentId: d.id,
                idFornecedorServico: '${idFornecedor}_$idServico'))),
        ...antigos.docs.map((d) => AvaliacaoServicoModel.fromMap(
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
      String? idServico}) async {
    final r =
        await _functions.httpsCallable('consultarContratosAvaliaveis').call({
      'idFornecedor': idFornecedor,
      'idEvento': idEvento,
      if (idServico != null) 'idServico': idServico
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
    await _functions.httpsCallable('registrarAvaliacaoVerificada').call({
      'idFornecedor': idFornecedor,
      'idOrcamento': idOrcamento,
      if (idServico != null) 'idServico': idServico,
      'nota': nota,
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
          String idFornecedor) =>
      _sessao(
          _db
              .collection('fornecedor')
              .doc(idFornecedor)
              .collection('avaliacoes')
              .snapshots()
              .asyncMap((s) async {
            final historico = await _historico(idFornecedor);
            final lista = await Future.wait(s.docs
                .where((d) =>
                    d.data()['tipo'] != 'servico' &&
                    d.data()['moderacao'] != 'oculta')
                .map((d) async => AvaliacaoModel.fromMap(
                    {...await _comprovar(d), 'id': d.id})));
            lista.addAll(historico.map(AvaliacaoModel.fromMap));
            lista.sort((a, b) => b.data.compareTo(a.data));
            return lista;
          }),
          <AvaliacaoModel>[]);
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
