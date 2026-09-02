import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/admin_dashboard_stats.dart';
import '../../models/evento/tema_festa_model.dart';

class AdminDashboardRemoteDatasource {
  AdminDashboardRemoteDatasource({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  Future<AdminDashboardStats> carregarIndicadores() async {
    final results = await Future.wait([
      _db.collection('categoria_servico').get(),
      _db.collection('subcategoria_servico').get(),
      _db.collection('servico_produto').get(),
      _db.collection('fornecedor').get(),
      _db.collection('usuarios').get(),
      _db.collection('evento').get(),
      _db.collection(TemaFestaModel.colecao).get(),
      _db.collection('orcamento').get(),
      _db.collection('territorio').get(),
    ]);

    final categorias = results[0].docs;
    final subcategorias = results[1].docs;
    final servicos = results[2].docs;
    final fornecedores = results[3].docs;
    final usuarios = results[4].docs;
    final eventos = results[5].docs;
    final temas = results[6].docs;
    final orcamentos = results[7].docs;
    final territorios = results[8].docs;

    const statusEventoAtivo = {
      'rascunho',
      'planejamento',
      'confirmado',
      'emAndamento',
      'em_andamento',
    };
    const statusOrcamentoAberto = {
      'pendente',
      'emNegociacao',
      'em_negociacao',
      'Pendente',
      'Em negociação',
    };

    return AdminDashboardStats(
      categorias: categorias.length,
      categoriasAtivas:
          categorias.where((d) => d.data()['ativo'] != false).length,
      subcategorias: subcategorias.length,
      servicos: servicos.where((d) => d.data()['ativo'] != false).length,
      fornecedores: fornecedores.length,
      fornecedoresAptos: fornecedores.where((d) {
        final data = d.data();
        return data['ativo'] != false &&
            (data['apto_para_operar'] == true ||
                data['aptoParaOperar'] == true);
      }).length,
      fornecedoresPendentes: fornecedores.where((d) {
        final data = d.data();
        return data['ativo'] != false &&
            data['apto_para_operar'] != true &&
            data['aptoParaOperar'] != true;
      }).length,
      usuarios: usuarios.length,
      usuariosAtivos: usuarios.where((d) => d.data()['ativo'] != false).length,
      eventos: eventos.length,
      eventosAtivos: eventos.where((d) {
        final data = d.data();
        final status = (data['status'] ?? '').toString();
        if (status.isNotEmpty) return statusEventoAtivo.contains(status);
        return data['ativo'] != false;
      }).length,
      temas: temas.length,
      orcamentos: orcamentos.length,
      orcamentosAbertos: orcamentos.where((d) {
        final status = (d.data()['status'] ?? 'pendente').toString();
        return statusOrcamentoAberto.contains(status);
      }).length,
      territorios: territorios.length,
    );
  }
}
