import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/domain/entities/categoria_servico.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria.dart';
import 'package:app_faca_festa/domain/entities/servico_produto.dart';
import 'package:app_faca_festa/domain/entities/subcategoria_servico.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/register_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'fornecedor_selecao_widgets.dart';

class CategoriaSubcategoriaServicoSection extends StatefulWidget {
  const CategoriaSubcategoriaServicoSection(
      {super.key,
      required this.controller,
      required this.primary,
      required this.categoriaController,
      required this.subcategoriaController,
      required this.servicoController});
  final RegisterController controller;
  final Color primary;
  final CategoriaServicoController categoriaController;
  final SubcategoriaServicoController subcategoriaController;
  final ServicoProdutoController servicoController;
  @override
  State<CategoriaSubcategoriaServicoSection> createState() =>
      _CategoriaSubcategoriaServicoSectionState();
}

class _CategoriaSubcategoriaServicoSectionState
    extends State<CategoriaSubcategoriaServicoSection> {
  final _busca = TextEditingController();
  final _carregando = <String>{};
  final _erros = <String, String>{};
  final _servicosOriginais = <String, ServicoProduto>{};
  bool _catalogoLido = false;
  RegisterController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _servicosOriginais
        .addAll({for (final s in c.servicosSelecionados) s.id: s});
    _catalogoLido =
        widget.subcategoriaController.todasSubcategorias.isNotEmpty &&
            widget.servicoController.servicos.isNotEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final categoria in c.categoriasSelecionadas.toList()) {
        if (!mounted) return;
        if (widget.subcategoriaController.subcategoriasPorCategoria
            .containsKey(categoria.idCategoria)) {
          continue;
        }
        await _preparar(categoria.idCategoria);
      }
    });
  }

  @override
  void dispose() {
    _busca.dispose();
    c.carregandoAtuacao.value = false;
    super.dispose();
  }

  Future<void> _preparar(String categoriaId) async {
    setState(() {
      _carregando.add(categoriaId);
      _erros.remove(categoriaId);
    });
    c.carregandoAtuacao.value = true;
    try {
      if (!_catalogoLido) {
        await Future.wait([
          widget.subcategoriaController.carregarParaFormulario(),
          widget.servicoController.carregarParaFormulario()
        ]);
        _catalogoLido = true;
      }
      if (!mounted) return;
      final subs = widget.subcategoriaController.todasSubcategorias
          .where((s) => s.idCategoria == categoriaId)
          .toList();
      widget.subcategoriaController.subcategoriasPorCategoria[categoriaId] =
          subs;
      for (final sub in subs) {
        widget.servicoController.servicosPorSubcategoria[sub.id] = widget
            .servicoController.servicos
            .where((s) => s.idSubcategoria == sub.id)
            .toList();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _erros[categoriaId] =
            'Não foi possível carregar as opções desta área. Tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() => _carregando.remove(categoriaId));
        c.carregandoAtuacao.value = _carregando.isNotEmpty;
      }
    }
  }

  List<SubcategoriaServico> _subs(String categoriaId) =>
      widget.subcategoriaController.subcategoriasPorCategoria[categoriaId] ??
      [];

  Future<void> _alternarCategoria(
      CategoriaServico categoria, FormFieldState<int> state) async {
    final atual = c.categoriasSelecionadas
        .firstWhereOrNull((cat) => cat.idCategoria == categoria.id);
    if (atual != null) {
      final ids = {
        ..._subs(categoria.id).map((s) => s.id),
        ...atual.subcategorias.map((s) => s.idSubcategoria)
      };
      c.servicosSelecionados.removeWhere((s) => ids.contains(s.idSubcategoria));
      c.categoriasSelecionadas
          .removeWhere((cat) => cat.idCategoria == categoria.id);
      setState(() => _erros.remove(categoria.id));
    } else {
      c.adicionarCategoria(categoria);
      await _preparar(categoria.id);
    }
    if (mounted) state.didChange(c.categoriasSelecionadas.length);
  }

  Widget _erro(String? texto) => texto == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Semantics(
              liveRegion: true,
              child: Text(texto,
                  style: GoogleFonts.poppins(
                      fontSize: 12.5, color: const Color(0xFFB91C1C)))));

  Widget _servico(ServicoProduto servico, FormFieldState<int> state) {
    final selecionado = c.servicosSelecionados.any((s) => s.id == servico.id);
    return FornecedorEscolha(
        key: ValueKey('servico-${servico.id}'),
        titulo: servico.nome,
        selecionado: selecionado,
        cor: widget.primary,
        habilitado: _carregando.isEmpty && !c.carregando.value,
        onPressed: () {
          c.alternarServico(servico, !selecionado);
          state.didChange(c.servicosSelecionados.length);
        });
  }

  Widget _grupo(FornecedorCategoria categoria, FormFieldState<int> servState) {
    final subs = _subs(categoria.idCategoria);
    final ids = subs.map((s) => s.id).toSet();
    final selecionados = c.servicosSelecionados
        .where((s) => ids.contains(s.idSubcategoria))
        .length;
    final escolhidas =
        categoria.subcategorias.map((s) => s.idSubcategoria).toSet();
    return Container(
      key: ValueKey('grupo-${categoria.idCategoria}'),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        key: PageStorageKey('atuacao-${categoria.idCategoria}'),
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        iconColor: widget.primary,
        collapsedIconColor: widget.primary,
        title: Text(categoria.nomeCategoria ?? 'Área cadastrada',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(
            '$selecionados ${selecionados == 1 ? 'serviço selecionado' : 'serviços selecionados'}',
            style: GoogleFonts.poppins(
                fontSize: 12, color: const Color(0xFF64748B))),
        children: [
          if (_carregando.contains(categoria.idCategoria)) ...[
            LinearProgressIndicator(color: widget.primary),
            const SizedBox(height: 12),
            const Text('Carregando opções…'),
          ] else if (_erros.containsKey(categoria.idCategoria)) ...[
            _erro(_erros[categoria.idCategoria]),
            TextButton.icon(
                onPressed: () => _preparar(categoria.idCategoria),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente')),
          ] else ...[
            Align(
                alignment: Alignment.centerLeft,
                child: Text('Especialidades',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600))),
            const SizedBox(height: 6),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    'Escolha uma ou mais para ver os serviços disponíveis.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
            const SizedBox(height: 12),
            if (subs.isEmpty)
              const Text(
                  'Esta área ainda não possui especialidades disponíveis.')
            else
              FornecedorOpcoesGrid(
                  children: subs
                      .where((s) => s.ativo || escolhidas.contains(s.id))
                      .map((sub) => FornecedorEscolha(
                            key: ValueKey('especialidade-${sub.id}'),
                            titulo: sub.nome,
                            selecionado: escolhidas.contains(sub.id),
                            cor: widget.primary,
                            habilitado:
                                _carregando.isEmpty && !c.carregando.value,
                            onPressed: () {
                              final selecionada = escolhidas.contains(sub.id);
                              c.alternarSubcategoria(
                                  categoria, sub, !selecionada);
                              if (selecionada) {
                                c.servicosSelecionados.removeWhere(
                                    (s) => s.idSubcategoria == sub.id);
                              }
                              servState
                                  .didChange(c.servicosSelecionados.length);
                            },
                          ))
                      .toList()),
            for (final sub in subs.where((s) => escolhidas.contains(s.id))) ...[
              const SizedBox(height: 20),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(sub.nome,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: widget.primary,
                          fontWeight: FontWeight.w600))),
              const SizedBox(height: 10),
              Builder(builder: (_) {
                final lista =
                    widget.servicoController.servicosPorSubcategoria[sub.id] ??
                        <ServicoProduto>[];
                final visiveis = lista
                    .where((s) =>
                        (s.ativo ||
                            c.servicosSelecionados
                                .any((escolhido) => escolhido.id == s.id)) &&
                        s.nome
                            .toLowerCase()
                            .contains(_busca.text.trim().toLowerCase()))
                    .toList();
                if (visiveis.isEmpty) {
                  return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          _busca.text.trim().isEmpty
                              ? 'Nenhum serviço disponível nesta especialidade.'
                              : 'Nenhum serviço encontrado nesta especialidade.',
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 12)));
                }
                return FornecedorOpcoesGrid(
                    children:
                        visiveis.map((s) => _servico(s, servState)).toList());
              }),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FormField<int>(
          validator: (_) => FormValidators.selecao(c.categoriasSelecionadas,
              campo: 'pelo menos uma categoria de atuação'),
          builder: (state) => Obx(() {
            final selecionadas =
                c.categoriasSelecionadas.map((s) => s.idCategoria).toSet();
            final categorias = widget.categoriaController.categorias
                .where((cat) => cat.ativo || selecionadas.contains(cat.id))
                .toList();
            for (final categoria in c.categoriasSelecionadas) {
              if (!categorias.any((item) => item.id == categoria.idCategoria)) {
                categorias.add(CategoriaServico(
                    id: categoria.idCategoria,
                    nome: categoria.nomeCategoria ?? 'Área cadastrada'));
              }
            }
            return FornecedorSecaoSelecao(
              titulo: 'Áreas de atuação *',
              descricao:
                  'Marque as áreas em que você trabalha. Depois, escolha as especialidades e os serviços que oferece.',
              cor: widget.primary,
              icone: Icons.storefront_outlined,
              resumo:
                  '${selecionadas.length} ${selecionadas.length == 1 ? 'área selecionada' : 'áreas selecionadas'}',
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (categorias.isEmpty)
                      const Text('Nenhuma categoria disponível.')
                    else
                      FornecedorOpcoesGrid(
                          children: categorias
                              .map((cat) => FornecedorEscolha(
                                    key: ValueKey('categoria-${cat.id}'),
                                    titulo: cat.nome,
                                    icone: Icons.category_outlined,
                                    selecionado: selecionadas.contains(cat.id),
                                    cor: widget.primary,
                                    habilitado: _carregando.isEmpty &&
                                        !c.carregando.value,
                                    onPressed: () =>
                                        _alternarCategoria(cat, state),
                                  ))
                              .toList()),
                    _erro(state.errorText),
                  ]),
            );
          }),
        ),
        const SizedBox(height: 20),
        FormField<int>(
          validator: (_) => _erros.isNotEmpty
              ? 'Carregue as opções das áreas selecionadas antes de continuar.'
              : FormValidators.selecao(c.servicosSelecionados,
                  campo: 'pelo menos um serviço oferecido'),
          builder: (state) => Obx(() {
            final categorias = c.categoriasSelecionadas.toList();
            // Lê as listas reativas utilizadas pelos grupos antes de construir os filhos.
            widget.subcategoriaController.subcategoriasPorCategoria.length;
            widget.servicoController.servicosPorSubcategoria.length;
            final quantidade = c.servicosSelecionados.length;
            final idsCatalogo =
                widget.servicoController.servicos.map((s) => s.id).toSet();
            final adicionais = _servicosOriginais.values
                .where((s) => !idsCatalogo.contains(s.id))
                .toList();
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Especialidades e serviços',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                      quantidade == 1
                          ? '1 serviço selecionado'
                          : '$quantidade serviços selecionados',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: widget.primary,
                          fontWeight: FontWeight.w600)),
                  if (categorias.isEmpty)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text('Selecione uma área acima para começar.',
                            style: GoogleFonts.poppins(
                                color: const Color(0xFF64748B), fontSize: 13)))
                  else ...[
                    const SizedBox(height: 12),
                    if (widget.servicoController.servicos.length > 6)
                      TextField(
                        controller: _busca,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                            labelText: 'Buscar serviço',
                            hintText: 'Nome do serviço',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _busca.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Limpar busca',
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () => setState(_busca.clear)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0)))),
                      ),
                    ...categorias.map((cat) => _grupo(cat, state)),
                  ],
                  if (adicionais.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Outros serviços do cadastro',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text(
                        'Mantidos do seu cadastro. Ajuste a seleção se necessário.',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 10),
                    FornecedorOpcoesGrid(
                        children:
                            adicionais.map((s) => _servico(s, state)).toList()),
                  ],
                  _erro(state.errorText),
                ]);
          }),
        ),
      ]);
}
