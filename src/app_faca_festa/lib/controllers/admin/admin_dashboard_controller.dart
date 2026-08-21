import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../data/models/evento/tema_festa_model.dart';

class AdminDashboardStats {
  final int categorias;
  final int categoriasAtivas;
  final int subcategorias;
  final int servicos;
  final int fornecedores;
  final int fornecedoresAptos;
  final int fornecedoresPendentes;
  final int usuarios;
  final int usuariosAtivos;
  final int eventos;
  final int eventosAtivos;
  final int temas;
  final int orcamentos;
  final int orcamentosAbertos;
  final int territorios;

  const AdminDashboardStats({
    this.categorias = 0,
    this.categoriasAtivas = 0,
    this.subcategorias = 0,
    this.servicos = 0,
    this.fornecedores = 0,
    this.fornecedoresAptos = 0,
    this.fornecedoresPendentes = 0,
    this.usuarios = 0,
    this.usuariosAtivos = 0,
    this.eventos = 0,
    this.eventosAtivos = 0,
    this.temas = 0,
    this.orcamentos = 0,
    this.orcamentosAbertos = 0,
    this.territorios = 0,
  });

  static const empty = AdminDashboardStats();
}

class AdminDashboardController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final stats = AdminDashboardStats.empty.obs;
  final carregando = false.obs;
  final erro = ''.obs;
  final atualizadoEm = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    carregar();
  }

  Future<void> carregar() async {
    try {
      carregando.value = true;
      erro.value = '';

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

      stats.value = AdminDashboardStats(
        categorias: categorias.length,
        categoriasAtivas: categorias.where((d) => d.data()['ativo'] != false).length,
        subcategorias: subcategorias.length,
        servicos: servicos.where((d) => d.data()['ativo'] != false).length,
        fornecedores: fornecedores.length,
        fornecedoresAptos: fornecedores.where((d) {
          final data = d.data();
          return data['ativo'] != false &&
              (data['apto_para_operar'] == true || data['aptoParaOperar'] == true);
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
      atualizadoEm.value = DateTime.now();
    } catch (e) {
      erro.value = 'Não foi possível atualizar os indicadores.';
    } finally {
      carregando.value = false;
    }
  }
}
