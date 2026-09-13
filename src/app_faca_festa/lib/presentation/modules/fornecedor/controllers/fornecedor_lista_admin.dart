import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/entities/categoria_servico.dart';
import 'package:app_faca_festa/domain/entities/endereco_usuario.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';
import 'package:app_faca_festa/domain/entities/subcategoria_servico.dart';
import 'package:app_faca_festa/domain/services/auditoria_registrar.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';

/// Lista, filtros e aprovação de fornecedores no painel admin.
class FornecedorListaAdmin {
  FornecedorListaAdmin({
    required this.fornecedores,
    required this.enderecos,
    required this.categoriasFornecedor,
    required this.categorias,
    required this.subCategorias,
    required this.allServicosFornecedor,
    required this.filtroNome,
    required this.filtroCidade,
    required this.filtroCategoria,
    required this.filtroAprovado,
    required this.filtroAtivo,
    required this.ordenacaoSelecionada,
    required GerenciarFornecedores Function() usecase,
    required AuditoriaRegistrar Function() auditoria,
    required String? Function() tipoUsuario,
    required RxBool carregando,
    required RxString erro,
  })  : _usecase = usecase,
        _auditoria = auditoria,
        _tipoUsuario = tipoUsuario,
        _carregando = carregando,
        _erro = erro;

  final RxList<Fornecedor> fornecedores;
  final RxList<EnderecoUsuario> enderecos;
  final RxList<FornecedorCategoria> categoriasFornecedor;
  final RxList<CategoriaServico> categorias;
  final RxList<SubcategoriaServico> subCategorias;
  final RxList<FornecedorProdutoServico> allServicosFornecedor;
  final RxString filtroNome;
  final RxnString filtroCidade;
  final RxnString filtroCategoria;
  final RxnBool filtroAprovado;
  final RxnBool filtroAtivo;
  final RxString ordenacaoSelecionada;

  final GerenciarFornecedores Function() _usecase;
  final AuditoriaRegistrar Function() _auditoria;
  final String? Function() _tipoUsuario;
  final RxBool _carregando;
  final RxString _erro;

  int get totalAptos =>
      fornecedores.where((f) => f.ativo && f.aptoParaOperar).length;
  int get totalPendentes =>
      fornecedores.where((f) => f.ativo && !f.aptoParaOperar).length;
  int get totalInativos => fornecedores.where((f) => !f.ativo).length;

  Future<void> carregarTodos() async {
    try {
      _carregando.value = true;
      _erro.value = '';

      final snapshot = await _usecase().carregarSnapshotAdmin(
        incluirEnderecos: _tipoUsuario() == 'A',
      );

      fornecedores.value = snapshot.fornecedores;
      enderecos.value = snapshot.enderecos;
      categoriasFornecedor.value = snapshot.categoriasFornecedor;
      categorias.value = snapshot.categorias;
      subCategorias.value = snapshot.subcategorias;
      allServicosFornecedor.assignAll(snapshot.servicosFornecedor);
    } catch (e) {
      _erro.value = 'Erro ao carregar fornecedores: $e';
    } finally {
      _carregando.value = false;
    }
  }

  List<Fornecedor> get filtrados {
    return fornecedores.where((f) {
      final endereco =
          enderecos.firstWhereOrNull((e) => e.idUsuario == f.idUsuario);
      final cat = categoriasFornecedor
          .firstWhereOrNull((c) => c.idFornecedor == f.idFornecedor)
          ?.idCategoria;

      final matchNome = filtroNome.value.isEmpty ||
          f.razaoSocial
              .toLowerCase()
              .contains(filtroNome.value.toLowerCase()) ||
          (f.descricao
                  ?.toLowerCase()
                  .contains(filtroNome.value.toLowerCase()) ??
              false) ||
          f.email.toLowerCase().contains(filtroNome.value.toLowerCase());

      final matchCidade = filtroCidade.value == null ||
          (endereco?.nomeCidade
                  ?.toLowerCase()
                  .contains(filtroCidade.value!.toLowerCase()) ??
              false);

      final matchCategoria =
          filtroCategoria.value == null || cat == filtroCategoria.value;

      final matchStatusAprovacao = filtroAprovado.value == null ||
          f.aptoParaOperar == filtroAprovado.value;

      final matchStatusAtivo =
          filtroAtivo.value == null || f.ativo == filtroAtivo.value;

      return matchNome &&
          matchCidade &&
          matchCategoria &&
          matchStatusAprovacao &&
          matchStatusAtivo;
    }).toList();
  }

  String cidadeDoFornecedor(Fornecedor f) {
    return enderecos
            .firstWhereOrNull((e) => e.idUsuario == f.idUsuario)
            ?.nomeCidade ??
        '';
  }

  List<String> nomesCategoriasDoFornecedor(Fornecedor f) {
    return categoriasFornecedor
        .where((c) => c.idFornecedor == f.idFornecedor)
        .map((c) => (c.nomeCategoria ?? '').trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
  }

  int servicosDoFornecedor(Fornecedor f) {
    return allServicosFornecedor
        .where((s) => s.idFornecedor == f.idFornecedor)
        .length;
  }

  void ordenar() {
    final lista = [...fornecedores];
    switch (ordenacaoSelecionada.value) {
      case 'nome':
        lista.sort((a, b) =>
            a.razaoSocial.toLowerCase().compareTo(b.razaoSocial.toLowerCase()));
        break;
      case 'recentes':
        lista.sort((a, b) => (b.dataCadastro).compareTo(a.dataCadastro));
        break;
      default:
        lista.sort((a, b) {
          if (a.ativo != b.ativo) return b.ativo ? 1 : -1;
          if (a.aptoParaOperar != b.aptoParaOperar) {
            return b.aptoParaOperar ? 1 : -1;
          }
          return a.razaoSocial
              .toLowerCase()
              .compareTo(b.razaoSocial.toLowerCase());
        });
    }
    fornecedores.assignAll(lista);
  }

  Future<bool> aprovar(String idFornecedor) {
    return _definirAptoParaOperar(idFornecedor, true);
  }

  Future<bool> reprovar(String idFornecedor) {
    return _definirAptoParaOperar(idFornecedor, false);
  }

  Future<void> desativar(String idFornecedor) async {
    try {
      final atual = fornecedores.firstWhereOrNull(
        (f) => f.idFornecedor == idFornecedor,
      );
      await _usecase().atualizarStatusAtivo(
        idFornecedor: idFornecedor,
        ativo: false,
      );
      fornecedores.removeWhere((f) => f.idFornecedor == idFornecedor);
      _auditoria().registrar(
        acao: 'FORNECEDOR_DESATIVADO',
        resumo: 'Fornecedor desativado pelo administrador.',
        entidadeTipo: 'fornecedor',
        entidadeId: idFornecedor,
        entidadeNome: atual?.razaoSocial,
        idFornecedor: idFornecedor,
        mudancas: const [
          AuditoriaMudanca(campo: 'Ativo', de: 'sim', para: 'não'),
        ],
      );
    } catch (e) {
      debugPrint('❌ Erro ao desativar fornecedor $idFornecedor: $e');
    }
  }

  Future<void> ativar(String idFornecedor) async {
    try {
      await _usecase().atualizarStatusAtivo(
        idFornecedor: idFornecedor,
        ativo: true,
      );
      final f =
          fornecedores.firstWhereOrNull((x) => x.idFornecedor == idFornecedor);
      if (f != null) {
        fornecedores[fornecedores.indexOf(f)] = f.copyWith(ativo: true);
      }
      _auditoria().registrar(
        acao: 'FORNECEDOR_ATIVADO',
        resumo: 'Fornecedor reativado pelo administrador.',
        entidadeTipo: 'fornecedor',
        entidadeId: idFornecedor,
        entidadeNome: f?.razaoSocial,
        idFornecedor: idFornecedor,
        mudancas: const [
          AuditoriaMudanca(campo: 'Ativo', de: 'não', para: 'sim'),
        ],
      );
    } catch (e) {
      debugPrint('❌ Erro ao ativar fornecedor $idFornecedor: $e');
    }
  }

  Future<bool> _definirAptoParaOperar(String idFornecedor, bool apto) async {
    try {
      final id = idFornecedor.trim();
      if (id.isEmpty) {
        debugPrint('❌ idFornecedor vazio ao atualizar apto_para_operar');
        return false;
      }

      await _usecase().atualizarAptoParaOperar(
        idFornecedor: id,
        apto: apto,
      );

      final i = fornecedores.indexWhere(
        (x) => x.idFornecedor == id || x.idUsuario == id,
      );
      final nome = i >= 0 ? fornecedores[i].razaoSocial : null;
      if (i >= 0) {
        fornecedores[i] = fornecedores[i].copyWith(aptoParaOperar: apto);
      }
      fornecedores.refresh();
      _auditoria().registrar(
        acao: apto ? 'FORNECEDOR_APROVADO' : 'FORNECEDOR_REPROVADO',
        resumo: apto
            ? 'Fornecedor liberado para operar na plataforma.'
            : 'Fornecedor voltou para análise.',
        entidadeTipo: 'fornecedor',
        entidadeId: id,
        entidadeNome: nome,
        idFornecedor: id,
        mudancas: [
          AuditoriaMudanca(
            campo: 'Apto para operar',
            de: apto ? 'não' : 'sim',
            para: apto ? 'sim' : 'não',
          ),
        ],
      );
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao atualizar apto_para_operar de $idFornecedor: $e');
      return false;
    }
  }

  void aplicarFiltros({
    String? nome,
    String? cidade,
    String? categoria,
    bool? aprovado,
    bool? ativo,
  }) {
    filtroNome.value = nome ?? '';
    filtroCidade.value = cidade?.isEmpty ?? true ? null : cidade;
    filtroCategoria.value = categoria?.isEmpty ?? true ? null : categoria;
    filtroAprovado.value = aprovado;
    filtroAtivo.value = ativo;
  }

  void limparFiltros() {
    filtroNome.value = '';
    filtroCidade.value = null;
    filtroCategoria.value = null;
    filtroAprovado.value = null;
    filtroAtivo.value = null;
  }
}
