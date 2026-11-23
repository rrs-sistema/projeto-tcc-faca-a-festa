// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/data/services/cardapio/gerar_cardapio_ia_service.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/sugestao_cardapio_ia.dart';
import 'package:app_faca_festa/domain/entities/tipo_evento.dart';
import 'package:app_faca_festa/domain/repositories/evento_repository.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/components/show_cadastro_bottom_sheet.dart';

enum _EtapaIa { formulario, gerando, preview, erro }

const _momentos = <({String label, IconData icon})>[
  (label: 'Café da manhã', icon: Icons.free_breakfast_rounded),
  (label: 'Almoço', icon: Icons.lunch_dining_rounded),
  (label: 'Jantar', icon: Icons.dinner_dining_rounded),
  (label: 'Lanche', icon: Icons.bakery_dining_rounded),
  (label: 'Churrasco', icon: Icons.outdoor_grill_rounded),
  (label: 'Coquetel', icon: Icons.local_bar_rounded),
];

const _estilos = <String>['Econômico', 'Tradicional', 'Elaborado'];
const _unidades = <String>['un', 'kg', 'g', 'l'];

Future<void> abrirGerarCardapioIa({
  required BuildContext context,
  required String idEvento,
  required CardapioController controller,
  required Color primaryColor,
  Evento? evento,
  TipoEvento? tipoEvento,
  String? tipoFestaNome,
  GerarCardapioIaService? service,
}) {
  return showCadastroBottomSheet(
    context: context,
    builder: (_) => GerarCardapioIaBottomSheet(
      idEvento: idEvento,
      controller: controller,
      primaryColor: primaryColor,
      evento: evento,
      tipoEvento: tipoEvento,
      tipoFestaNome: tipoFestaNome,
      service: service ?? GerarCardapioIaService.fromGet(),
    ),
  );
}

class GerarCardapioIaBottomSheet extends StatefulWidget {
  const GerarCardapioIaBottomSheet({
    super.key,
    required this.idEvento,
    required this.controller,
    required this.primaryColor,
    required this.service,
    this.evento,
    this.tipoEvento,
    this.tipoFestaNome,
  });

  final String idEvento;
  final CardapioController controller;
  final Color primaryColor;
  final GerarCardapioIaService service;
  final Evento? evento;
  final TipoEvento? tipoEvento;
  final String? tipoFestaNome;

  @override
  State<GerarCardapioIaBottomSheet> createState() =>
      _GerarCardapioIaBottomSheetState();
}

class _GerarCardapioIaBottomSheetState
    extends State<GerarCardapioIaBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _totalCtrl;
  late final TextEditingController _adultosCtrl;
  late final TextEditingController _criancasCtrl;
  late final TextEditingController _restricoesCtrl;
  late final TextEditingController _observacoesCtrl;
  late final TextEditingController _duracaoCtrl;
  late final TextEditingController _nomeCardapioCtrl;

  List<TipoEvento> _tipos = const [];
  TipoEvento? _tipoSelecionado;
  bool _carregandoTipos = true;
  String? _erroTipos;

  String _momento = 'Almoço';
  String? _estilo;
  bool _mostrarPersonalizar = false;
  bool _editadoManual = false;
  bool _salvando = false;

  _EtapaIa _etapa = _EtapaIa.formulario;
  SugestaoCardapioIa? _sugestao;
  String? _mensagemErro;

  @override
  void initState() {
    super.initState();
    final evento = widget.evento;
    final adultos = evento?.totalAdultos;
    final criancas = evento?.totalCriancas;
    final total = evento?.totalConvidadosCalculado ?? 0;

    _totalCtrl = TextEditingController(text: total > 0 ? '$total' : '');
    _adultosCtrl = TextEditingController(
      text: adultos != null && adultos > 0 ? '$adultos' : '',
    );
    _criancasCtrl = TextEditingController(
      text: criancas != null && criancas > 0 ? '$criancas' : '',
    );
    _restricoesCtrl = TextEditingController();
    _observacoesCtrl = TextEditingController();
    _duracaoCtrl = TextEditingController();
    _nomeCardapioCtrl = TextEditingController();
    _carregarTipos();
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    _adultosCtrl.dispose();
    _criancasCtrl.dispose();
    _restricoesCtrl.dispose();
    _observacoesCtrl.dispose();
    _duracaoCtrl.dispose();
    _nomeCardapioCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarTipos() async {
    setState(() {
      _carregandoTipos = true;
      _erroTipos = null;
    });
    try {
      if (!Get.isRegistered<EventoRepository>()) {
        throw StateError('Repositório de eventos indisponível.');
      }
      final lista =
          await Get.find<EventoRepository>().listarTiposAtivos();
      final ativos = lista.where((t) => t.ativo).toList()
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

      final selecionado = _resolverTipoPadrao(ativos);
      var tipos = List<TipoEvento>.from(ativos);
      if (selecionado != null &&
          !tipos.any((t) => t.idTipoEvento == selecionado.idTipoEvento)) {
        tipos = [selecionado, ...tipos];
      }

      if (!mounted) return;
      setState(() {
        _tipos = tipos;
        _tipoSelecionado = selecionado ?? (tipos.isNotEmpty ? tipos.first : null);
        _carregandoTipos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregandoTipos = false;
        _erroTipos = 'Não foi possível carregar os tipos de festa.';
        final fallback = widget.tipoEvento;
        if (fallback != null) {
          _tipos = [fallback];
          _tipoSelecionado = fallback;
        } else {
          final nome = (widget.tipoFestaNome ?? '').trim();
          if (nome.isNotEmpty) {
            final temp = TipoEvento(
              idTipoEvento: widget.evento?.idTipoEvento ?? 'temp',
              nome: nome,
            );
            _tipos = [temp];
            _tipoSelecionado = temp;
          }
        }
      });
    }
  }

  TipoEvento? _resolverTipoPadrao(List<TipoEvento> tipos) {
    final atual = widget.tipoEvento;
    final idEvento = (widget.evento?.idTipoEvento ?? '').trim();
    final nomeHint = (widget.tipoFestaNome ?? atual?.nome ?? '').trim();

    if (atual != null) {
      final porId = tipos
          .where((t) => t.idTipoEvento == atual.idTipoEvento)
          .firstOrNull;
      if (porId != null) return porId;
    }
    if (idEvento.isNotEmpty) {
      final porId =
          tipos.where((t) => t.idTipoEvento == idEvento).firstOrNull;
      if (porId != null) return porId;
    }
    if (nomeHint.isNotEmpty) {
      final lower = nomeHint.toLowerCase();
      final exact = tipos
          .where((t) => t.nome.trim().toLowerCase() == lower)
          .firstOrNull;
      if (exact != null) return exact;
      final parcial = tipos
          .where((t) =>
              t.nome.toLowerCase().contains(lower) ||
              lower.contains(t.nome.toLowerCase()))
          .firstOrNull;
      if (parcial != null) return parcial;
    }
    return atual;
  }

  EntradaGeracaoCardapioIa? _montarEntrada() {
    final total = int.tryParse(_totalCtrl.text.trim()) ?? 0;
    if (total <= 0) return null;
    final tipoNome = (_tipoSelecionado?.nome ?? '').trim();
    if (tipoNome.isEmpty) return null;

    final adultos = int.tryParse(_adultosCtrl.text.trim());
    final criancas = int.tryParse(_criancasCtrl.text.trim());
    final duracao = double.tryParse(
      _duracaoCtrl.text.trim().replaceAll(',', '.'),
    );
    final bebes = widget.evento?.totalBebes;

    return EntradaGeracaoCardapioIa(
      idEvento: widget.idEvento,
      tipoFesta: tipoNome,
      totalPessoas: total,
      momentoRefeicao: _momento,
      adultos: adultos != null && adultos >= 0 ? adultos : null,
      criancas: criancas != null && criancas >= 0 ? criancas : null,
      bebes: bebes != null && bebes > 0 ? bebes : null,
      estilo: _estilo,
      restricoes: _restricoesCtrl.text.trim().isEmpty
          ? null
          : _restricoesCtrl.text.trim(),
      observacoes: _observacoesCtrl.text.trim().isEmpty
          ? null
          : _observacoesCtrl.text.trim(),
      duracaoHoras: duracao != null && duracao > 0 ? duracao : null,
    );
  }

  Future<void> _gerar() async {
    if (_carregandoTipos) return;
    if (!_formKey.currentState!.validate()) return;
    if (_tipoSelecionado == null) {
      setState(() {
        _mensagemErro = 'Selecione o tipo de festa.';
        _etapa = _EtapaIa.erro;
      });
      return;
    }

    final entrada = _montarEntrada();
    if (entrada == null) {
      setState(() {
        _mensagemErro = 'Informe a quantidade de pessoas maior que zero.';
        _etapa = _EtapaIa.erro;
      });
      return;
    }

    setState(() {
      _etapa = _EtapaIa.gerando;
      _mensagemErro = null;
    });

    try {
      final sugestao = await widget.service.gerar(entrada);
      if (!mounted) return;
      _nomeCardapioCtrl.text = sugestao.nomeCardapio;
      setState(() {
        _sugestao = sugestao;
        _editadoManual = false;
        _etapa = _EtapaIa.preview;
      });
    } on GerarCardapioIaException catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagemErro = e.message;
        _etapa = _EtapaIa.erro;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mensagemErro =
            'Não foi possível gerar o cardápio agora. Tente novamente.';
        _etapa = _EtapaIa.erro;
      });
    }
  }

  Future<void> _gerarOutra() async {
    if (_editadoManual) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Substituir sugestão?'),
          content: const Text(
            'Você editou a prévia. Gerar outra sugestão substitui essas alterações.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Gerar outra'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    await _gerar();
  }

  Future<void> _salvar() async {
    final atual = _sugestao;
    if (atual == null ||
        _salvando ||
        widget.controller.salvandoSugestaoIa.value) {
      return;
    }

    final nome = _nomeCardapioCtrl.text.trim();
    if (nome.isEmpty) {
      Get.snackbar(
        'Nome obrigatório',
        'Informe um nome para o cardápio.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (atual.todosItens.isEmpty) {
      Get.snackbar(
        'Sem itens',
        'Inclua ao menos um item antes de salvar.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      await widget.controller.salvarSugestaoIa(
        idEvento: widget.idEvento,
        sugestao: atual.copyWith(nomeCardapio: nome),
      );
      if (!mounted) return;
      Get.back<void>();
      Get.snackbar(
        'Cardápio salvo',
        'A sugestão foi adicionada. Você pode continuar editando os itens.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF059669),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    } catch (_) {
      Get.snackbar(
        'Não foi possível salvar',
        'Verifique sua conexão e tente novamente. Seus dados da prévia foram mantidos.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _atualizarSugestao(SugestaoCardapioIa nova) {
    setState(() {
      _sugestao = nova;
      _editadoManual = true;
    });
  }

  void _removerItem(String idLocal) {
    final atual = _sugestao;
    if (atual == null) return;
    final cats = <SugestaoCardapioIaCategoria>[];
    for (final c in atual.categorias) {
      final itens = c.itens.where((i) => i.idLocal != idLocal).toList();
      if (itens.isNotEmpty) cats.add(c.copyWith(itens: itens));
    }
    _atualizarSugestao(atual.copyWith(categorias: cats));
  }

  Future<void> _editarItem(SugestaoCardapioIaItem item) async {
    final nomeCtrl = TextEditingController(text: item.nome);
    final qCtrl = TextEditingController(
      text: item.quantidade.toString().replaceAll(RegExp(r'\.0$'), ''),
    );
    final obsCtrl = TextEditingController(text: item.observacao ?? '');
    var unidade = item.unidade;
    var tipo = item.tipo;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: qCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantidade'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: unidade,
                decoration: const InputDecoration(labelText: 'Unidade'),
                items: _unidades
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) unidade = v;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TipoItemCardapio>(
                value: tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: TipoItemCardapio.values
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) tipo = v;
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: obsCtrl,
                decoration: const InputDecoration(labelText: 'Observação'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );

    if (ok != true || _sugestao == null) return;
    final q = double.tryParse(qCtrl.text.trim().replaceAll(',', '.'));
    if (nomeCtrl.text.trim().isEmpty || q == null || q <= 0) {
      Get.snackbar(
        'Dados inválidos',
        'Informe nome e quantidade maior que zero.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final atualizado = item.copyWith(
      nome: nomeCtrl.text.trim(),
      quantidade: q,
      unidade: unidade,
      tipo: tipo,
      observacao: obsCtrl.text.trim().isEmpty ? null : obsCtrl.text.trim(),
      limparObservacao: obsCtrl.text.trim().isEmpty,
    );
    final cats = _sugestao!.categorias.map((c) {
      return c.copyWith(
        itens: c.itens
            .map((i) => i.idLocal == item.idLocal ? atualizado : i)
            .toList(),
      );
    }).toList();
    _atualizarSugestao(_sugestao!.copyWith(categorias: cats));
  }

  Future<void> _adicionarItem() async {
    final atual = _sugestao;
    if (atual == null) return;

    final nomeCtrl = TextEditingController();
    final qCtrl = TextEditingController(text: '1');
    var unidade = 'un';
    var tipo = TipoItemCardapio.comida;
    var categoria = atual.categorias.first.nome;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: qCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantidade'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: unidade,
                decoration: const InputDecoration(labelText: 'Unidade'),
                items: _unidades
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) unidade = v;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TipoItemCardapio>(
                value: tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: TipoItemCardapio.values
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) tipo = v;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: categoria,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: atual.categorias
                    .map((c) =>
                        DropdownMenuItem(value: c.nome, child: Text(c.nome)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) categoria = v;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final q = double.tryParse(qCtrl.text.trim().replaceAll(',', '.'));
    if (nomeCtrl.text.trim().isEmpty || q == null || q <= 0) return;

    final novo = SugestaoCardapioIaItem(
      idLocal: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      nome: nomeCtrl.text.trim(),
      tipo: tipo,
      quantidade: q,
      unidade: unidade,
      nomeCategoria: categoria,
    );
    final cats = atual.categorias.map((c) {
      if (c.nome != categoria) return c;
      return c.copyWith(itens: [...c.itens, novo]);
    }).toList();
    _atualizarSugestao(atual.copyWith(categorias: cats));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teclado = MediaQuery.viewInsetsOf(context).bottom;
    final primary = widget.primaryColor;

    return FractionallySizedBox(
      heightFactor: 0.94,
      child: Material(
        color: const Color(0xFFF7F8F6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: teclado),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6D3D1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                _cabecalho(theme, primary),
                Expanded(child: _corpo(theme, primary)),
                _rodape(primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecalho(ThemeData theme, Color primary) {
    final etapaLabel = switch (_etapa) {
      _EtapaIa.formulario => 'Passo 1 de 2 · Contar a festa',
      _EtapaIa.gerando => 'Preparando sugestão',
      _EtapaIa.preview => 'Passo 2 de 2 · Revisar e salvar',
      _EtapaIa.erro => 'Algo deu errado',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary,
                  primary.withValues(alpha: 0.72),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etapaLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primary.withValues(alpha: 0.9),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Seu cardápio com IA',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _etapa == _EtapaIa.preview
                      ? 'Ajuste o que fizer sentido antes de salvar no cardápio do evento.'
                      : 'Três respostas rápidas. Nós estimamos comidas, bebidas e quantidades.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.35,
                    color: const Color(0xFF78716C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _corpo(ThemeData theme, Color primary) {
    switch (_etapa) {
      case _EtapaIa.gerando:
        return _estadoCentral(
          primary: primary,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  color: primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Estamos preparando uma sugestão para sua festa…',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF44403C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Isso costuma levar alguns segundos.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF78716C),
                ),
              ),
            ],
          ),
        );
      case _EtapaIa.erro:
        return _estadoCentral(
          primary: primary,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: primary, size: 42),
              const SizedBox(height: 12),
              Text(
                _mensagemErro ??
                    'Não foi possível gerar o cardápio agora. Tente novamente.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF44403C),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  setState(() => _etapa = _EtapaIa.formulario);
                  _gerar();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Tentar novamente'),
              ),
              TextButton(
                onPressed: () => setState(() => _etapa = _EtapaIa.formulario),
                child: const Text('Voltar ao formulário'),
              ),
            ],
          ),
        );
      case _EtapaIa.preview:
        return _preview(theme, primary);
      case _EtapaIa.formulario:
        return _formulario(theme, primary);
    }
  }

  Widget _estadoCentral({required Color primary, required Widget child}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: primary.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _formulario(ThemeData theme, Color primary) {
    return Form(
      key: _formKey,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        children: [
          _secao(
            numero: '1',
            titulo: 'Tipo de festa',
            ajuda: 'Usamos os tipos cadastrados no sistema.',
            primary: primary,
            child: _tiposWidget(primary),
          ),
          const SizedBox(height: 12),
          _secao(
            numero: '2',
            titulo: 'Quem será servido',
            ajuda: 'Pode ajustar só para esta sugestão.',
            primary: primary,
            child: Column(
              children: [
                TextFormField(
                  controller: _totalCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: _decoracao(
                    'Total de pessoas',
                    icone: Icons.groups_rounded,
                    primary: primary,
                  ),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim()) ?? 0;
                    if (n <= 0) return 'Informe um número maior que zero';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _adultosCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: _decoracao(
                          'Adultos',
                          hint: 'Opcional',
                          primary: primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _criancasCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: _decoracao(
                          'Crianças',
                          hint: 'Opcional',
                          primary: primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _secao(
            numero: '3',
            titulo: 'Momento da refeição',
            ajuda: 'Escolha o que melhor descreve o serviço.',
            primary: primary,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final colunas = constraints.maxWidth >= 520 ? 3 : 2;
                final largura =
                    (constraints.maxWidth - (colunas - 1) * 8) / colunas;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in _momentos)
                      SizedBox(
                        width: largura,
                        child: _tileSelecao(
                          selecionado: _momento == m.label,
                          primary: primary,
                          icone: m.icon,
                          titulo: m.label,
                          onTap: () => setState(() => _momento = m.label),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _personalizar(primary),
        ],
      ),
    );
  }

  Widget _tiposWidget(Color primary) {
    if (_carregandoTipos) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: primary),
            ),
            const SizedBox(width: 10),
            Text(
              'Carregando tipos de festa…',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF78716C),
              ),
            ),
          ],
        ),
      );
    }

    if (_tipos.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _erroTipos ?? 'Nenhum tipo de festa disponível.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFFB45309),
            ),
          ),
          TextButton(
            onPressed: _carregarTipos,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tipoSelecionado != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selecionado: ${_tipoSelecionado!.nome}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1917),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final colunas = constraints.maxWidth >= 560
                ? 3
                : constraints.maxWidth >= 360
                    ? 2
                    : 1;
            final largura =
                (constraints.maxWidth - (colunas - 1) * 8) / colunas;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tipo in _tipos)
                  SizedBox(
                    width: largura,
                    child: _tileSelecao(
                      selecionado:
                          _tipoSelecionado?.idTipoEvento == tipo.idTipoEvento,
                      primary: primary,
                      icone: Icons.celebration_rounded,
                      titulo: tipo.nome,
                      onTap: () => setState(() => _tipoSelecionado = tipo),
                    ),
                  ),
              ],
            );
          },
        ),
        if (_erroTipos != null) ...[
          const SizedBox(height: 8),
          Text(
            _erroTipos!,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFFB45309),
            ),
          ),
        ],
      ],
    );
  }

  Widget _personalizar(Color primary) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () =>
            setState(() => _mostrarPersonalizar = !_mostrarPersonalizar),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _mostrarPersonalizar
                        ? Icons.expand_less_rounded
                        : Icons.tune_rounded,
                    color: primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalizar sugestão',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: const Color(0xFF1C1917),
                          ),
                        ),
                        Text(
                          'Estilo, restrições e duração — opcional',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: const Color(0xFF78716C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _mostrarPersonalizar
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFFA8A29E),
                  ),
                ],
              ),
              if (_mostrarPersonalizar) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Estilo',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in _estilos)
                      ChoiceChip(
                        label: Text(e),
                        selected: _estilo == e,
                        onSelected: (_) => setState(
                          () => _estilo = _estilo == e ? null : e,
                        ),
                        selectedColor: primary.withValues(alpha: 0.14),
                        labelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: _estilo == e
                              ? primary
                              : const Color(0xFF44403C),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _restricoesCtrl,
                  maxLines: 2,
                  decoration: _decoracao(
                    'Restrições e preferências',
                    hint: 'Ex.: vegetariano, sem glúten',
                    primary: primary,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _observacoesCtrl,
                  maxLines: 2,
                  decoration: _decoracao(
                    'Observações',
                    hint: 'Ex.: sem bebidas alcoólicas',
                    primary: primary,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _duracaoCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoracao(
                    'Duração estimada (horas)',
                    hint: 'Opcional',
                    icone: Icons.schedule_rounded,
                    primary: primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview(ThemeData theme, Color primary) {
    final sugestao = _sugestao!;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        _secao(
          numero: null,
          titulo: 'Nome do cardápio',
          ajuda: 'Pode editar antes de salvar.',
          primary: primary,
          child: TextField(
            controller: _nomeCardapioCtrl,
            onChanged: (_) => setState(() => _editadoManual = true),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            decoration: _decoracao(
              'Nome',
              icone: Icons.menu_book_rounded,
              primary: primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sugestao.resumoPublico,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: const Color(0xFF1C1917),
                ),
              ),
              if (sugestao.justificativa.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  sugestao.justificativa,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.35,
                    color: const Color(0xFF57534E),
                  ),
                ),
              ],
              if (sugestao.avisoBebes != null) ...[
                const SizedBox(height: 8),
                Text(
                  sugestao.avisoBebes!,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                sugestao.avisoEstimativa,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF78716C),
                ),
              ),
            ],
          ),
        ),
        if (sugestao.premissas.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Premissas',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          for (final p in sugestao.premissas)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $p',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF57534E),
                ),
              ),
            ),
        ],
        const SizedBox(height: 14),
        for (final cat in sugestao.categorias) ...[
          Text(
            cat.nome,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 8),
          for (final item in cat.itens)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7E5E4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.nome} — ${_fmtQtd(item.quantidade)} ${_labelUnidade(item.unidade)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (item.observacao != null &&
                            item.observacao!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Observação: ${item.observacao}',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: const Color(0xFF78716C),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Editar',
                    icon: Icon(Icons.edit_rounded, size: 18, color: primary),
                    onPressed: () => _editarItem(item),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Remover',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFFDC2626),
                    ),
                    onPressed: () => _removerItem(item.idLocal),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
        ],
        OutlinedButton.icon(
          onPressed: _adicionarItem,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Adicionar item'),
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            minimumSize: const Size.fromHeight(46),
            side: BorderSide(color: primary.withValues(alpha: 0.35)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rodape(Color primary) {
    final gerando = _etapa == _EtapaIa.gerando;
    final preview = _etapa == _EtapaIa.preview;
    final formularioPronto =
        !_carregandoTipos && _tipoSelecionado != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: Color(0xFFE7E5E4))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (preview)
            TextButton.icon(
              onPressed: gerando || _salvando ? null : _gerarOutra,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Gerar outra sugestão'),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: gerando || _salvando
                      ? null
                      : () {
                          if (preview) {
                            setState(() => _etapa = _EtapaIa.formulario);
                          } else {
                            Get.back<void>();
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: const Color(0xFF44403C),
                    side: const BorderSide(color: Color(0xFFD6D3D1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(preview ? 'Voltar' : 'Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: preview
                    ? FilledButton.icon(
                        onPressed: gerando || _salvando ? null : _salvar,
                        icon: _salvando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(_salvando ? 'Salvando…' : 'Salvar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed:
                            gerando || !formularioPronto ? null : _gerar,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: const Text('Gerar sugestão'),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          disabledBackgroundColor:
                              primary.withValues(alpha: 0.35),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _secao({
    required String? numero,
    required String titulo,
    required String ajuda,
    required Color primary,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E5E4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (numero != null) ...[
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    numero,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: const Color(0xFF1C1917),
                      ),
                    ),
                    Text(
                      ajuda,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF78716C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _tileSelecao({
    required bool selecionado,
    required Color primary,
    required IconData icone,
    required String titulo,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selecionado ? primary.withValues(alpha: 0.10) : const Color(0xFFFAFAF9),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selecionado ? primary : const Color(0xFFE7E5E4),
              width: selecionado ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icone,
                size: 18,
                color: selecionado ? primary : const Color(0xFF78716C),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: selecionado
                        ? primary
                        : const Color(0xFF292524),
                  ),
                ),
              ),
              if (selecionado)
                Icon(Icons.check_circle_rounded, size: 16, color: primary),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracao(
    String label, {
    String? hint,
    IconData? icone,
    required Color primary,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icone == null ? null : Icon(icone, size: 20),
      filled: true,
      fillColor: const Color(0xFFFAFAF9),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    );
  }

  String _fmtQtd(double q) {
    if (q == q.roundToDouble()) return q.toInt().toString();
    return q.toStringAsFixed(1).replaceAll('.', ',');
  }

  String _labelUnidade(String u) {
    switch (u) {
      case 'l':
        return 'litros';
      case 'kg':
        return 'kg';
      case 'g':
        return 'g';
      default:
        return 'unidades';
    }
  }
}
