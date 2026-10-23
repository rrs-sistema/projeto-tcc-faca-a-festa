import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app_faca_festa/app/bootstrap/autenticacao_bootstrap.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_cadastro_edicao.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria_resumo.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_dados_cadastrais.dart';
import 'package:app_faca_festa/domain/entities/servico_produto.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/register_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/register_fornecedor_form.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';

Future<bool?> mostrarEditarFornecedorAdmin({
  required BuildContext context,
  required String idFornecedor,
  required FornecedorController controller,
  required CategoriaServicoController categorias,
  required SubcategoriaServicoController subcategorias,
  required ServicoProdutoController servicos,
}) =>
    Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => EditarFornecedorCadastroPage(
              idFornecedor: idFornecedor,
              controller: controller,
              categorias: categorias.novaSessao(),
              subcategorias: subcategorias.novaSessao(),
              servicos: servicos.novaSessao(),
              criarFormulario: AutenticacaoBootstrap.criarFormularioFornecedor,
            )));

class EditarFornecedorCadastroPage extends StatefulWidget {
  const EditarFornecedorCadastroPage(
      {super.key,
      required this.idFornecedor,
      required this.controller,
      required this.categorias,
      required this.subcategorias,
      required this.servicos,
      required this.criarFormulario});
  final String idFornecedor;
  final FornecedorController controller;
  final CategoriaServicoController categorias;
  final SubcategoriaServicoController subcategorias;
  final ServicoProdutoController servicos;
  final RegisterController Function() criarFormulario;
  @override
  State<EditarFornecedorCadastroPage> createState() =>
      _EditarFornecedorCadastroPageState();
}

class _EditarFornecedorCadastroPageState
    extends State<EditarFornecedorCadastroPage> {
  final _scroll = ScrollController();
  RegisterController? _formulario;
  FornecedorCadastroEdicao? _origem;
  Uint8List? _banner;
  String? _nomeBanner;
  String? _bannerEnviado;
  String? _erro;
  bool _carregando = true;
  int _etapa = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final origem = await widget.controller
          .carregarCadastroFornecedorAdmin(widget.idFornecedor);
      if (!mounted) return;
      final c = _formulario ??= widget.criarFormulario();
      c.nome.value = origem.usuario.nome;
      c.email.value = origem.fornecedor.email;
      c.telefone.value = origem.fornecedor.telefone;
      c.razaoSocial.value = origem.fornecedor.razaoSocial;
      c.cnpj.value = origem.fornecedor.cnpj ?? '';
      c.descricao.value = origem.fornecedor.descricao ?? '';
      c.bannerUrl = origem.fornecedor.bannerUrl;
      c.definirTiposEventoAtendidos(
          ids: origem.fornecedor.tipoEventoIds,
          slugs: origem.fornecedor.tipoEventoSlugs,
          nomes: origem.fornecedor.tipoEventoNomes);
      c.categoriasSelecionadas.assignAll(origem.categorias);
      final end = origem.endereco;
      if (end != null) {
        final e = c.enderecoController.value;
        e.suspenderConsulta = true;
        e.cepController.text = end.cep;
        e.logradouroController.text = end.logradouro;
        e.numeroController.text = end.numero;
        e.bairroController.text = end.bairro ?? '';
        e.complementoController.text = end.complemento ?? '';
        e.nomeCidadeController.text = end.nomeCidade ?? '';
        e.ufController.text = end.uf ?? '';
        e.suspenderConsulta = false;
      }
      await Future.wait([
        widget.categorias.carregarParaFormulario(),
        widget.subcategorias.carregarParaFormulario(),
        widget.servicos.carregarParaFormulario()
      ]);
      if (!mounted) return;
      if (widget.categorias.erro.value.isNotEmpty ||
          widget.servicos.erro.value.isNotEmpty) {
        throw StateError(
            'Não foi possível carregar o catálogo. Tente novamente antes de editar.');
      }
      final catalogo = widget.servicos.servicos.toList();
      c.servicosSelecionados.clear();
      for (final vinculo in origem.vinculos.where((s) => s.ativo)) {
        final servico = catalogo
                .firstWhereOrNull((s) => s.id == vinculo.idProdutoServico) ??
            ServicoProduto(
                id: vinculo.idProdutoServico,
                nome: 'Serviço cadastrado (${vinculo.idProdutoServico})',
                idSubcategoria: vinculo.idSubcategoria,
                ativo: true);
        if (!c.servicosSelecionados.any((s) => s.id == servico.id)) {
          c.servicosSelecionados.add(servico);
        }
      }
      final subcategorias = widget.subcategorias.todasSubcategorias;
      for (final categoria in c.categoriasSelecionadas.toList()) {
        final subs = subcategorias
            .where((s) => s.idCategoria == categoria.idCategoria)
            .toList();
        widget.subcategorias.subcategoriasPorCategoria[categoria.idCategoria] =
            subs;
        for (final sub in subs) {
          widget.servicos.servicosPorSubcategoria[sub.id] =
              catalogo.where((s) => s.idSubcategoria == sub.id).toList();
        }
        // Cadastros antigos nem sempre trazem subcategorias no resumo.
        final usados =
            c.servicosSelecionados.map((s) => s.idSubcategoria).toSet();
        final resumo = [...categoria.subcategorias];
        for (final sub in subs.where((s) => usados.contains(s.id))) {
          if (!resumo.any((s) => s.idSubcategoria == sub.id)) {
            resumo.add(FornecedorSubcategoriaResumo(
                idSubcategoria: sub.id, nomeSubcategoria: sub.nome));
          }
        }
        final index = c.categoriasSelecionadas
            .indexWhere((cat) => cat.idCategoria == categoria.idCategoria);
        c.categoriasSelecionadas[index] =
            categoria.copyWith(subcategorias: resumo);
      }
      setState(() {
        _origem = origem;
        _carregando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = e is StateError
              ? e.message.toString()
              : 'Não foi possível carregar o cadastro completo. Tente novamente.';
        });
      }
    }
  }

  Future<void> _salvar() async {
    final origem = _origem!;
    final c = _formulario!;
    if (!widget.controller.podeEditarDadosFornecedor) {
      throw StateError('A sessão de administrador não está ativa.');
    }
    if (_banner != null && _bannerEnviado == null) {
      _bannerEnviado = await widget.controller.uploadBanner(
          bytes: _banner!,
          nomeArquivo: _nomeBanner!,
          uid: origem.fornecedor.idUsuario);
    }
    final novo =
        c.enderecoController.value.toModel(origem.fornecedor.idUsuario);
    final anterior = origem.endereco;
    final endereco = novo.copyWith(
        id: anterior?.id ?? 'principal',
        idCidade:
            anterior?.nomeCidade == novo.nomeCidade && anterior?.uf == novo.uf
                ? anterior!.idCidade
                : novo.idCidade,
        dataCadastro: anterior?.dataCadastro,
        principal: anterior?.principal ?? true);
    await widget.controller
        .salvarCadastroFornecedorAdmin(FornecedorCadastroAlteracao(
      origem: origem,
      dados: FornecedorDadosCadastrais(
          razaoSocial: c.razaoSocial.value,
          email: c.email.value,
          telefone: c.telefone.value,
          cnpj: c.cnpj.value,
          descricao: c.descricao.value),
      nomeResponsavel: c.nome.value,
      endereco: endereco,
      categorias: c.categoriasSelecionadas.toList(),
      servicos: c.servicosSelecionados.toList(),
      tipoEventoIds: c.tipoEventoIds.toList(),
      tipoEventoSlugs: c.tipoEventoSlugs.toList(),
      tipoEventoNomes: c.tipoEventoNomes.toList(),
      novoBannerUrl: _bannerEnviado,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _formulario?.enderecoController.value.dispose();
    widget.categorias.onClose();
    widget.subcategorias.onClose();
    widget.servicos.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _formulario;
    return Theme(
        data: Theme.of(context)
            .copyWith(scaffoldBackgroundColor: AdminPalette.surface),
        child: Scaffold(
          appBar: AdminBackAppBar(
              title: 'Editar fornecedor',
              subtitle: 'Cadastro e catálogo do fornecedor',
              onBack: () {
                if (c?.carregando.value != true) Navigator.pop(context, false);
              }),
          body: _carregando
              ? const Center(child: CircularProgressIndicator())
              : _erro != null
                  ? Center(
                      child: AdminEmptyState(
                          icon: Icons.error_outline,
                          title: 'Cadastro indisponível',
                          message: _erro!,
                          actionLabel: 'Tentar novamente',
                          onAction: _carregar))
                  : Obx(() => PopScope(
                      canPop: !c!.carregando.value,
                      child: AbsorbPointer(
                          absorbing: c.carregando.value,
                          child: SingleChildScrollView(
                            controller: _scroll,
                            padding: EdgeInsets.all(
                                MediaQuery.sizeOf(context).width < 600
                                    ? 12
                                    : 24),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: Center(
                                child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                        maxWidth: _etapa == 3 ? 1040 : 760),
                                    child: Container(
                                      padding: EdgeInsets.all(
                                          MediaQuery.sizeOf(context).width < 600
                                              ? 16
                                              : 28),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(22)),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            ExpansionTile(
                                              tilePadding: EdgeInsets.zero,
                                              shape: const Border(),
                                              collapsedShape: const Border(),
                                              leading: const Icon(
                                                  Icons
                                                      .manage_accounts_outlined,
                                                  color: AdminPalette.primary),
                                              title: const Text(
                                                  'Conta de acesso',
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              subtitle: Text(
                                                  _origem!.usuario.email,
                                                  style: const TextStyle(
                                                      color: AdminPalette.muted,
                                                      fontSize: 12)),
                                              children: const [
                                                Padding(
                                                    padding: EdgeInsets.only(
                                                        bottom: 12),
                                                    child: Text(
                                                        'Atualize o e-mail comercial no formulário. A conta e a senha de acesso são preservadas.',
                                                        style: TextStyle(
                                                            color: AdminPalette
                                                                .muted,
                                                            fontSize: 12)))
                                              ],
                                            ),
                                            const SizedBox(height: 24),
                                            RegisterFornecedorForm(
                                              controller: c,
                                              fornecedorController:
                                                  widget.controller,
                                              picker: ImagePicker(),
                                              bannerBytes: _banner,
                                              bannerInicialUrl:
                                                  _origem!.fornecedor.bannerUrl,
                                              onBannerSelected:
                                                  (arquivo, bytes) async {
                                                if (mounted) {
                                                  setState(() {
                                                    _banner = bytes;
                                                    _nomeBanner = arquivo.name;
                                                    _bannerEnviado = null;
                                                  });
                                                }
                                              },
                                              primary: AdminPalette.primary,
                                              categoriaController:
                                                  widget.categorias,
                                              subcategoriaController:
                                                  widget.subcategorias,
                                              servicoController:
                                                  widget.servicos,
                                              modoEdicao: true,
                                              onSalvarEdicao: _salvar,
                                              onPassoAlterado: (etapa) {
                                                setState(() => _etapa = etapa);
                                                if (_scroll.hasClients) {
                                                  _scroll.jumpTo(0);
                                                }
                                              },
                                            ),
                                          ]),
                                    ))),
                          )))),
        ));
  }
}
