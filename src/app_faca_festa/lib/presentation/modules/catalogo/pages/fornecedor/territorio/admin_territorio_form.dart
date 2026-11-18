import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/territorio.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_territorio_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/pages/fornecedor/components/territorio_atendimento_screen.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';

Future<void> mostrarFormularioTerritorioAdmin(
  BuildContext context, {
  required AdminTerritorioController controller,
  required List<Fornecedor> fornecedores,
  Territorio? existente,
}) async {
  final tema = Theme.of(context);
  final cameraAnterior = controller.mapController.camera;
  bool? salvo;
  try {
    if (existente != null) controller.mostrarPreviaCobertura(existente);
    salvo = await showGeneralDialog<bool>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      barrierColor: const Color(0x330F172A),
      pageBuilder: (context, _, __) {
        final largura = MediaQuery.sizeOf(context).width;
        final lateral = largura >= 1100;
        return SafeArea(
          bottom: false,
          child: Align(
            alignment: lateral ? Alignment.centerLeft : Alignment.bottomCenter,
            child: Padding(
              padding: lateral
                  ? const EdgeInsets.fromLTRB(20, 24, 0, 24)
                  : const EdgeInsets.only(top: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: lateral ? math.min(496, largura * 3 / 8 - 40) : 640,
                ),
                child: Theme(
                  data: tema,
                  child: _FormularioTerritorio(
                    controller: controller,
                    fornecedores: fornecedores,
                    existente: existente,
                    lateral: lateral,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  } finally {
    if (!controller.isClosed) {
      controller.encerrarPreviaCobertura(
        cameraAnterior: salvo == true ? null : cameraAnterior,
      );
    }
  }
}

class _FormularioTerritorio extends StatefulWidget {
  const _FormularioTerritorio({
    required this.controller,
    required this.fornecedores,
    required this.lateral,
    this.existente,
  });

  final AdminTerritorioController controller;
  final List<Fornecedor> fornecedores;
  final Territorio? existente;
  final bool lateral;

  @override
  State<_FormularioTerritorio> createState() => _FormularioTerritorioState();
}

class _FormularioTerritorioState extends State<_FormularioTerritorio> {
  final _form = GlobalKey<FormState>();
  late Territorio _rascunho;
  late final TextEditingController _descricao;
  late final TextEditingController _raio;
  late final Map<String, String> _nomes;
  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.existente != null;
  bool get _porRaio => _rascunho.tipoCobertura != 'regiao';
  bool get _temCobertura => _porRaio
      ? _rascunho.latitude != null && _rascunho.longitude != null
      : (_rascunho.regioes?.length ?? 0) >= 3;

  @override
  void initState() {
    super.initState();
    _rascunho = widget.existente ??
        Territorio(
          idTerritorio: const Uuid().v4(),
          idFornecedor: '',
          tipoCobertura: 'raio',
          raioKm: 10,
        );
    _descricao = TextEditingController(text: _rascunho.descricao);
    _raio = TextEditingController(
      text: NumericInput.quantidade(_rascunho.raioKm ?? 10),
    );
    _nomes = {};
    for (final fornecedor in widget.fornecedores) {
      final id = fornecedor.idFornecedor.trim();
      final nome = fornecedor.razaoSocial.trim();
      if (id.isNotEmpty) _nomes.putIfAbsent(id, () => nome.isEmpty ? id : nome);
    }
  }

  @override
  void dispose() {
    _descricao.dispose();
    _raio.dispose();
    super.dispose();
  }

  Future<void> _editarNoMapa() async {
    FocusScope.of(context).unfocus();
    final cobertura = await editarCoberturaNoMapa(
      context,
      territorio: _rascunho,
      cor: AdminPalette.primary,
      controller: widget.controller,
    );
    if (!mounted || cobertura == null) return;
    setState(() {
      _rascunho = cobertura;
      _raio.text = NumericInput.quantidade(cobertura.raioKm ?? 10);
      _erro = null;
    });
    _atualizarPrevia();
  }

  void _alterarRaio(String valor) {
    final raio = NumericInput.parse(valor);
    if (raio == null || raio <= 0) return;
    setState(() => _rascunho = _rascunho.copyWith(raioKm: raio));
    _atualizarPrevia();
  }

  void _atualizarPrevia() {
    if (_temCobertura) widget.controller.mostrarPreviaCobertura(_rascunho);
  }

  Future<void> _salvar() async {
    if (_salvando || !_form.currentState!.validate()) return;
    if (!_editando && !_temCobertura) {
      setState(
          () => _erro = 'Defina a cobertura no mapa para criar o território.');
      return;
    }

    final territorio = _rascunho.copyWith(
      idFornecedor: widget.existente?.idFornecedor ?? _rascunho.idFornecedor,
      descricao: _descricao.text.trim(),
      raioKm: _porRaio ? NumericInput.parse(_raio.text) : null,
    );
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.controller.salvarTerritorio(territorio);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = 'Não foi possível salvar o território. Tente novamente.';
      });
    }
  }

  Widget _cabecalho(TextTheme texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AdminPalette.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                _editando
                    ? Icons.edit_location_alt_outlined
                    : Icons.add_location_alt_outlined,
                color: AdminPalette.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _editando ? 'Editar território' : 'Novo território',
              style: texto.titleLarge?.copyWith(
                color: AdminPalette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Fechar formulário',
            onPressed: _salvando ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: AdminPalette.muted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return PopScope(
      canPop: !_salvando,
      child: AnimatedPadding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        duration: const Duration(milliseconds: 180),
        child: Material(
          color: Colors.white,
          elevation: widget.lateral ? 12 : 0,
          borderRadius: widget.lateral
              ? BorderRadius.circular(24)
              : const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _cabecalho(texto),
                  const Divider(height: 1, color: AdminPalette.border),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _campoFornecedor(texto),
                          const SizedBox(height: 20),
                          _campoCobertura(texto),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _descricao,
                            enabled: !_salvando,
                            minLines: 2,
                            maxLines: 3,
                            decoration: _campo(
                              'Descrição (opcional)',
                              hint: 'Ex.: Atende Maringá e região',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _painel(
                            child: SwitchListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              title: const Text('Território ativo'),
                              subtitle: Text(_rascunho.ativo
                                  ? 'Visível no mapa geral de cobertura.'
                                  : 'Oculto no mapa geral de cobertura.'),
                              value: _rascunho.ativo,
                              onChanged: _salvando
                                  ? null
                                  : (ativo) => setState(() {
                                        _rascunho =
                                            _rascunho.copyWith(ativo: ativo);
                                      }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AdminPalette.border),
                  _rodape(texto),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoFornecedor(TextTheme texto) {
    final id = _rascunho.idFornecedor;
    if (_editando) {
      return _painel(
        preenchimento: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined, color: AdminPalette.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fornecedor vinculado',
                      style: texto.labelMedium
                          ?.copyWith(color: AdminPalette.muted)),
                  Text(
                    _nomes[id] ??
                        (id.isEmpty
                            ? 'Fornecedor não encontrado'
                            : 'Fornecedor não encontrado ($id)'),
                    style:
                        texto.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.lock_outline, size: 18, color: AdminPalette.muted),
          ],
        ),
      );
    }
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: id.isEmpty ? null : id,
      decoration: _campo(
        'Fornecedor',
        hint: _nomes.isEmpty
            ? 'Nenhum fornecedor disponível'
            : 'Selecione um fornecedor',
      ),
      items: [
        for (final fornecedor in _nomes.entries)
          DropdownMenuItem(
            value: fornecedor.key,
            child: Text(fornecedor.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: _salvando || _nomes.isEmpty
          ? null
          : (id) => setState(() {
                _rascunho = _rascunho.copyWith(idFornecedor: id ?? '');
              }),
      validator: (id) => id == null ? 'Selecione um fornecedor.' : null,
    );
  }

  Widget _campoCobertura(TextTheme texto) {
    final pontos = widget.lateral
        ? const <LatLng>[]
        : widget.controller.pontosDeCobertura(_rascunho);
    final exibirPrevia = _temCobertura && pontos.length >= 3;
    return _painel(
      preenchimento: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Cobertura',
              style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (_porRaio)
            TextFormField(
              controller: _raio,
              enabled: !_salvando,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [NumericInput.decimal()],
              decoration: _campo('Raio de atendimento', sufixo: 'km'),
              onChanged: _alterarRaio,
              validator: (valor) => (NumericInput.parse(valor) ?? 0) <= 0
                  ? 'Informe um raio maior que zero.'
                  : null,
            )
          else
            const Text('Região desenhada'),
          if (_temCobertura) ...[
            const SizedBox(height: 8),
            Text(
              'Prévia no mapa. As alterações são aplicadas ao salvar.',
              style: texto.bodySmall?.copyWith(color: AdminPalette.muted),
            ),
          ],
          if (exibirPrevia) ...[
            const SizedBox(height: 12),
            _PreviaMapa(territorio: _rascunho, pontos: pontos),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _salvando ? null : _editarNoMapa,
              icon: const Icon(Icons.map_outlined),
              label: Text(_temCobertura ? 'Editar no mapa' : 'Definir no mapa'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _painel({
    required Widget child,
    EdgeInsetsGeometry preenchimento = EdgeInsets.zero,
  }) {
    return Container(
      padding: preenchimento,
      decoration: BoxDecoration(
        color: AdminPalette.surface,
        border: Border.all(color: AdminPalette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _rodape(TextTheme texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_erro case final String erro)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(erro,
                    style:
                        texto.bodyMedium?.copyWith(color: AdminPalette.danger)),
              ),
            ),
          OverflowBar(
            spacing: 8,
            overflowSpacing: 8,
            alignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _salvando ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: _salvando ? null : _salvar,
                child: Text(_salvando
                    ? 'Salvando…'
                    : _editando
                        ? 'Salvar alterações'
                        : 'Criar território'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _campo(String rotulo, {String? hint, String? sufixo}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: rotulo,
      hintText: hint,
      suffixText: sufixo,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminPalette.border),
      ),
    );
  }
}

class _PreviaMapa extends StatefulWidget {
  const _PreviaMapa({required this.territorio, required this.pontos});

  final Territorio territorio;
  final List<LatLng> pontos;

  @override
  State<_PreviaMapa> createState() => _PreviaMapaState();
}

class _PreviaMapaState extends State<_PreviaMapa> {
  final _mapa = MapController();

  CameraFit get _enquadramento => CameraFit.coordinates(
        coordinates: widget.pontos,
        padding: const EdgeInsets.all(14),
        maxZoom: 12,
      );

  @override
  void didUpdateWidget(covariant _PreviaMapa antigo) {
    super.didUpdateWidget(antigo);
    if (identical(antigo.territorio, widget.territorio)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapa.fitCamera(_enquadramento);
    });
  }

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cor = AdminPalette.primary;
    final territorio = widget.territorio;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 132,
        child: FlutterMap(
          key: const ValueKey('mapaPreviaCobertura'),
          mapController: _mapa,
          options: MapOptions(
            initialCenter: widget.pontos.first,
            initialCameraFit: _enquadramento,
            interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'app_faca_festa',
            ),
            if (territorio.tipoCobertura == 'regiao')
              PolygonLayer(polygons: [
                Polygon(
                  points: widget.pontos,
                  color: cor.withValues(alpha: 0.22),
                  borderColor: cor,
                  borderStrokeWidth: 2,
                ),
              ])
            else
              CircleLayer(circles: [
                CircleMarker(
                  point: LatLng(territorio.latitude!, territorio.longitude!),
                  radius: (territorio.raioKm ?? 10) * 1000,
                  color: cor.withValues(alpha: 0.22),
                  borderColor: cor,
                  borderStrokeWidth: 2,
                  useRadiusInMeter: true,
                ),
              ]),
          ],
        ),
      ),
    );
  }
}
