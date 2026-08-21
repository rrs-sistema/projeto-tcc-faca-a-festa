import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../controllers/tema/admin_theme.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import '../../../controllers/tema/tema_festa_controller.dart';
import '../../../data/models/evento/tema_festa_model.dart';
import '../../widgets/tema_capa_imagem.dart';

Future<void> showTemaFestaFormBottomSheet(
  BuildContext context, {
  TemaFestaModel? tema,
}) async {
  final wide = MediaQuery.sizeOf(context).width >= 720;
  final form = TemaFestaFormSheet(tema: tema, comoDialog: wide);

  if (wide) {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
          child: form,
        ),
      ),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.92,
        child: form,
      ),
    ),
  );
}

class TemaFestaFormSheet extends StatefulWidget {
  const TemaFestaFormSheet({
    super.key,
    this.tema,
    this.comoDialog = false,
  });

  final TemaFestaModel? tema;
  final bool comoDialog;

  @override
  State<TemaFestaFormSheet> createState() => _TemaFestaFormSheetState();
}

class _TemaFestaFormSheetState extends State<TemaFestaFormSheet> {
  static const Color _dark = Color(0xFF1F2937);

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _dressCtrl;
  late final TextEditingController _primariaCtrl;
  late final TextEditingController _secundariaCtrl;

  late final RxString _categoria;
  late final RxString _icone;
  late final RxBool _ativo;
  late final RxList<String> _tipos;
  late final RxString _primariaHex;
  late final RxString _secundariaHex;
  Uint8List? _capaBytes;
  String? _capaUrl;
  bool _removerCapa = false;

  @override
  void initState() {
    super.initState();
    final tema = widget.tema;
    _nomeCtrl = TextEditingController(text: tema?.nome ?? '');
    _descCtrl = TextEditingController(text: tema?.descricao ?? '');
    _dressCtrl = TextEditingController(text: tema?.dressCodeSugerido ?? '');
    _primariaCtrl = TextEditingController(text: tema?.corPrimaria ?? '#009688');
    _secundariaCtrl = TextEditingController(text: tema?.corSecundaria ?? '#4DB6AC');
    _categoria = (tema?.categoria ?? TemaFestaCategorias.criativo).obs;
    _icone = (tema?.icone ?? 'star').obs;
    _ativo = (tema?.ativo ?? true).obs;
    _tipos = <String>[...(tema?.tiposEvento ?? const [])].obs;
    _primariaHex = _primariaCtrl.text.obs;
    _secundariaHex = _secundariaCtrl.text.obs;
    _capaUrl = tema?.imagemCapaUrl;
    _nomeCtrl.addListener(() => setState(() {}));
    _primariaCtrl.addListener(() => _primariaHex.value = _primariaCtrl.text);
    _secundariaCtrl.addListener(() => _secundariaHex.value = _secundariaCtrl.text);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _dressCtrl.dispose();
    _primariaCtrl.dispose();
    _secundariaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final controller = Get.find<TemaFestaController>();

    return Theme(
      data: theme.adminThemeData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Column(
              children: [
                if (!widget.comoDialog)
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.tema == null ? 'Novo tema' : 'Editar tema',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Obx(() {
                final primaria = TemaFestaModel.parseCor(_primariaHex.value);
                final secundaria = TemaFestaModel.parseCor(_secundariaHex.value);
                final icone = TemaFestaIcones.iconeDe(_icone.value);
                final nome = _nomeCtrl.text.trim();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PreviewTema(
                      nome: nome.isEmpty ? 'Nome do tema' : nome,
                      categoria: TemaFestaCategorias.rotulo(_categoria.value),
                      icone: icone,
                      primaria: primaria,
                      secundaria: secundaria,
                      capaUrl: _removerCapa
                          ? null
                          : (_capaUrl ?? widget.tema?.capaEfetiva),
                      capaBytes: _capaBytes,
                    ),
                    const SizedBox(height: 12),
                    _campoCapa(controller),
                    const SizedBox(height: 20),
                    _secao('Identidade'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nomeCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _input(
                        'Nome do tema',
                        hint: 'Ex.: Super-heróis',
                        icon: Icons.auto_awesome_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Categoria',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: TemaFestaCategorias.todas.map((item) {
                        final selecionado = _categoria.value == item;
                        return ChoiceChip(
                          label: Text(TemaFestaCategorias.rotulo(item)),
                          selected: selecionado,
                          selectedColor: _dark,
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selecionado ? Colors.white : _dark,
                          ),
                          onSelected: (_) => _categoria.value = item,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _secao('Paleta e ícone'),
                    const SizedBox(height: 4),
                    Text(
                      'A principal pinta cabeçalho e botões. A de destaque só aparece em detalhes. O fundo claro é gerado sozinho.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _CampoCor(
                            label: 'Cor principal',
                            controller: _primariaCtrl,
                            cor: primaria,
                            onPicked: (hex) {
                              _primariaCtrl.text = hex;
                              _primariaHex.value = hex;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CampoCor(
                            label: 'Cor de destaque',
                            controller: _secundariaCtrl,
                            cor: secundaria,
                            onPicked: (hex) {
                              _secundariaCtrl.text = hex;
                              _secundariaHex.value = hex;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Ícone',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TemaFestaIcones.mapa.keys.map((key) {
                        final selecionado = _icone.value == key;
                        return Tooltip(
                          message: TemaFestaIcones.rotulo(key),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _icone.value = key,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: selecionado ? _dark : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selecionado ? _dark : Colors.grey.shade300,
                                ),
                              ),
                              child: Icon(
                                TemaFestaIcones.iconeDe(key),
                                color: selecionado ? Colors.white : _dark,
                                size: 20,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    _secao('Onde aparece'),
                    const SizedBox(height: 4),
                    Text(
                      'Escolha os tipos de evento que poderão usar este tema.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TemaFestaTipos.catalogo.map((tipo) {
                        final selecionado = _tipos.contains(tipo);
                        return FilterChip(
                          label: Text(TemaFestaTipos.rotulo(tipo)),
                          selected: selecionado,
                          selectedColor: _dark,
                          checkmarkColor: Colors.white,
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selecionado ? Colors.white : _dark,
                          ),
                          onSelected: (value) {
                            if (value) {
                              _tipos.add(tipo);
                            } else {
                              _tipos.remove(tipo);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    _secao('Textos'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dressCtrl,
                      decoration: _input(
                        'Dress code sugerido',
                        hint: 'Ex.: Fantasia de herói, cores primárias',
                        icon: Icons.checkroom_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: _input(
                        'Descrição',
                        hint: 'Como a festa deve parecer para o organizador.',
                        icon: Icons.notes_outlined,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Tema ativo',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Inativos não aparecem no cadastro do organizador.',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      value: _ativo.value,
                      activeTrackColor: _dark,
                      onChanged: (value) => _ativo.value = value,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: controller.salvando.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          widget.tema == null ? 'Cadastrar tema' : 'Salvar alterações',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        onPressed: controller.salvando.value
                            ? null
                            : () => _salvar(controller),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _salvar(TemaFestaController controller) async {
    final nome = _nomeCtrl.text.trim();
    if (nome.length < 2) {
      Get.snackbar('Tema', 'Informe o nome do tema.');
      return;
    }
    if (_tipos.isEmpty) {
      Get.snackbar('Tema', 'Selecione pelo menos um tipo de evento.');
      return;
    }
    final slug = widget.tema?.slug ?? TemaFestaModel.slugify(nome);
    final id = widget.tema?.idTema ?? slug;
    final idTema = id.isEmpty ? const Uuid().v4() : id;
    var capaUrl = _removerCapa ? null : (_capaUrl ?? widget.tema?.imagemCapaUrl);
    if (_capaBytes != null) {
      final enviada = await controller.enviarCapa(idTema: idTema, bytes: _capaBytes!);
      if (enviada == null) return;
      capaUrl = enviada;
    } else if (_removerCapa && (widget.tema?.imagemCapaUrl ?? '').isNotEmpty) {
      await controller.removerCapaStorage(idTema: widget.tema!.idTema);
    }
    final model = TemaFestaModel(
      idTema: idTema,
      slug: slug.isEmpty ? idTema : slug,
      nome: nome,
      categoria: _categoria.value,
      tiposEvento: _tipos.toList(),
      corPrimaria: _normalizarHex(_primariaCtrl.text),
      corSecundaria: _normalizarHex(_secundariaCtrl.text),
      icone: _icone.value,
      descricao: _descCtrl.text.trim(),
      dressCodeSugerido: _dressCtrl.text.trim(),
      imagemCapaUrl: capaUrl,
      ativo: _ativo.value,
      ordem: widget.tema?.ordem ?? (controller.temas.length + 1) * 10,
      tags: widget.tema?.tags ?? const [],
    );
    await controller.salvar(model);
    Get.back();
  }

  Future<void> _escolherCapa(TemaFestaController controller) async {
    final arquivo = await controller.escolherCapa();
    if (arquivo == null) return;
    final bytes = await arquivo.readAsBytes();
    if (bytes.isEmpty) return;
    setState(() {
      _capaBytes = bytes;
      _removerCapa = false;
    });
  }

  Widget _campoCapa(TemaFestaController controller) {
    final temCapa = _capaBytes != null ||
        (!_removerCapa &&
            ((_capaUrl ?? widget.tema?.capaEfetiva) ?? '').trim().isNotEmpty);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _escolherCapa(controller),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(
              temCapa ? 'Trocar capa' : 'Adicionar capa',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (temCapa) ...[
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Remover capa',
            onPressed: () {
              setState(() {
                _capaBytes = null;
                _removerCapa = true;
              });
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ],
    );
  }

  String _normalizarHex(String value) {
    final limpo = value.trim();
    if (limpo.isEmpty) return '#009688';
    return limpo.startsWith('#') ? limpo.toUpperCase() : '#${limpo.toUpperCase()}';
  }

  Widget _secao(String titulo) {
    return Text(
      titulo,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _dark,
      ),
    );
  }

  InputDecoration _input(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _PreviewTema extends StatelessWidget {
  const _PreviewTema({
    required this.nome,
    required this.categoria,
    required this.icone,
    required this.primaria,
    required this.secundaria,
    this.capaUrl,
    this.capaBytes,
  });

  final String nome;
  final String categoria;
  final IconData icone;
  final Color primaria;
  final Color secundaria;
  final String? capaUrl;
  final Uint8List? capaBytes;

  @override
  Widget build(BuildContext context) {
    final fundo = TemaFestaModel.misturarComBranco(primaria, 0.92);
    final onPrimary = TemaFestaModel.contrasteSobre(primaria);
    final temFoto = (capaBytes != null && capaBytes!.isNotEmpty) ||
        (capaUrl ?? '').trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: secundaria.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 148,
            decoration: BoxDecoration(
              color: primaria,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TemaCapaImagem(
                    url: capaUrl,
                    bytes: capaBytes,
                    fallback: ColoredBox(color: primaria),
                  ),
                  if (temFoto)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x33000000),
                            Color(0x00000000),
                            Color(0x99000000),
                          ],
                          stops: [0, 0.45, 1],
                        ),
                      ),
                    )
                  else
                    ColoredBox(color: primaria.withValues(alpha: 0.46)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                    child: Column(
                      children: [
                        Icon(icone, color: onPrimary, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          nome,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          categoria,
                          style: GoogleFonts.poppins(
                            color: onPrimary.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 6, color: secundaria),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Fundo gerado automaticamente',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaria,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Botão',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoCor extends StatelessWidget {
  const _CampoCor({
    required this.label,
    required this.controller,
    required this.cor,
    required this.onPicked,
  });

  final String label;
  final TextEditingController controller;
  final Color cor;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
        LengthLimitingTextInputFormatter(7),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: InkWell(
            onTap: () async {
              final escolhida = await _escolherCor(context, cor);
              if (escolhida != null) {
                onPicked(TemaFestaModel.colorToHex(escolhida));
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<Color?> _escolherCor(BuildContext context, Color inicial) {
  var atual = HSVColor.fromColor(inicial);
  return showDialog<Color>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Escolher cor',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: atual.toColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _slider('Matiz', atual.hue, 360, (value) {
                    setState(() => atual = atual.withHue(value));
                  }),
                  _slider('Saturação', atual.saturation * 100, 100, (value) {
                    setState(() => atual = atual.withSaturation(value / 100));
                  }),
                  _slider('Brilho', atual.value * 100, 100, (value) {
                    setState(() => atual = atual.withValue(value / 100));
                  }),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      Color(0xFF1565C0),
                      Color(0xFFEF5350),
                      Color(0xFF009688),
                      Color(0xFF8D6E63),
                      Color(0xFFC5E1A5),
                      Color(0xFF7B1FA2),
                      Color(0xFFFF6F00),
                      Color(0xFF37474F),
                    ].map((preset) {
                      return InkWell(
                        onTap: () => setState(() => atual = HSVColor.fromColor(preset)),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: preset,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2937),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, atual.toColor()),
                child: const Text('Usar cor'),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _slider(
  String label,
  double value,
  double max,
  ValueChanged<double> onChanged,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      Slider(value: value.clamp(0, max), min: 0, max: max, onChanged: onChanged),
    ],
  );
}
