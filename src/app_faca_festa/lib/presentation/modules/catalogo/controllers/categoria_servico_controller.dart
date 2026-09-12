import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/categoria_servico.dart';
import 'package:app_faca_festa/domain/services/auditoria_registrar.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_catalogo_servico.dart';

class CategoriaServicoController extends GetxController {
  CategoriaServicoController({
    required GerenciarCatalogoServico catalogo,
    AuditoriaRegistrar? auditoria,
    AuditoriaRegistrar? Function()? auditoriaResolver,
  })  : _catalogo = catalogo,
        _auditoria = auditoria,
        _auditoriaResolver = auditoriaResolver;

  final GerenciarCatalogoServico _catalogo;
  final AuditoriaRegistrar? _auditoria;
  final AuditoriaRegistrar? Function()? _auditoriaResolver;
  AuditoriaRegistrar get _registradorAuditoria =>
      _auditoria ??
      _auditoriaResolver?.call() ??
      const AuditoriaRegistrarVazio();

  final categorias = <CategoriaServico>[].obs;
  final contagemSubcategorias = <String, int>{}.obs;
  final busca = ''.obs;
  final filtroAtivo = RxnBool();
  final carregando = false.obs;
  final erro = ''.obs;

  @override
  void onInit() {
    super.onInit();
    carregarCategorias();
  }

  List<CategoriaServico> get categoriasFiltradas {
    final termo = busca.value.trim().toLowerCase();
    var lista = categorias.toList();

    if (filtroAtivo.value != null) {
      lista = lista.where((c) => c.ativo == filtroAtivo.value).toList();
    }

    if (termo.isNotEmpty) {
      lista = lista.where((c) {
        final nome = c.nome.toLowerCase();
        final desc = (c.descricao ?? '').toLowerCase();
        return nome.contains(termo) || desc.contains(termo);
      }).toList();
    }

    lista.sort((a, b) {
      if (a.ordem != b.ordem) return a.ordem.compareTo(b.ordem);
      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });
    return lista;
  }

  int get totalAtivas => categorias.where((c) => c.ativo).length;

  int subcategoriasDe(String idCategoria) =>
      contagemSubcategorias[idCategoria] ?? 0;

  Future<void> carregarCategorias() async {
    try {
      carregando.value = true;
      erro.value = '';
      categorias.value = await _catalogo.listarCategorias();
      await _atualizarContagensSubcategorias();
    } catch (e) {
      erro.value = e.toString();
    } finally {
      carregando.value = false;
    }
  }

  Future<void> _atualizarContagensSubcategorias() async {
    try {
      contagemSubcategorias.assignAll(
        await _catalogo.contarSubcategoriasPorCategoria(),
      );
    } catch (_) {}
  }

  Future<void> salvarCategoria(CategoriaServico model) async {
    await _catalogo.salvarCategoria(model);
    _registradorAuditoria.registrar(
      acao: 'CATEGORIA_SALVA',
      resumo: 'Categoria de serviço salva no catálogo.',
      entidadeTipo: 'categoria_servico',
      entidadeId: model.id,
      entidadeNome: model.nome,
    );
    await carregarCategorias();
  }

  Future<void> atualizarStatus(CategoriaServico model, bool ativo) async {
    await _catalogo.atualizarStatusCategoria(model.id, ativo);
    final idx = categorias.indexWhere((c) => c.id == model.id);
    if (idx >= 0) {
      categorias[idx] = model.copyWith(ativo: ativo);
      categorias.refresh();
    }
  }

  /// Grava (merge) o catálogo padrão de festas no Firestore.
  /// Preserva IDs já usados por fornecedores e serviços.
  Future<({int categorias, int subcategorias})> popularCatalogoInicial() async {
    final resultado = await _catalogo.popularCatalogoInicial();
    await carregarCategorias();
    return resultado;
  }

  Future<void> excluirCategoria(String id) async {
    final atual = categorias.firstWhereOrNull((c) => c.id == id);
    await _catalogo.excluirCategoria(id);
    _registradorAuditoria.registrar(
      acao: 'CATEGORIA_EXCLUIDA',
      resumo: 'Categoria removida do catálogo.',
      entidadeTipo: 'categoria_servico',
      entidadeId: id,
      entidadeNome: atual?.nome,
    );
    await carregarCategorias();
  }
}
