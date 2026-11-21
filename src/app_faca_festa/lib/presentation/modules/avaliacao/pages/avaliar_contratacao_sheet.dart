import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/star_rating_widget.dart';

const _rotulosNota = ['', 'Ruim', 'Fraca', 'Ok', 'Boa', 'Ótima'];

/// Abre as duas notas da contratação: fornecedor e serviço.
Future<bool?> mostrarAvaliarContratacao(
  BuildContext context, {
  required String idFornecedor,
  required String idEvento,
  required AvaliacaoServicoController controller,
  required EventThemeController themeController,
  String? idOrcamento,
  String? idServico,
  String? nomeFornecedor,
  String? nomeServico,
  String? nomeEvento,
  bool aposAceite = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: AvaliarContratacaoSheet(
        idFornecedor: idFornecedor,
        idEvento: idEvento,
        controller: controller,
        themeController: themeController,
        idOrcamento: idOrcamento,
        idServico: idServico,
        nomeFornecedor: nomeFornecedor,
        nomeServico: nomeServico,
        nomeEvento: nomeEvento,
        aposAceite: aposAceite,
      ),
    ),
  );
}

class AvaliarContratacaoSheet extends StatefulWidget {
  const AvaliarContratacaoSheet({
    super.key,
    required this.idFornecedor,
    required this.idEvento,
    required this.controller,
    required this.themeController,
    this.idOrcamento,
    this.idServico,
    this.nomeFornecedor,
    this.nomeServico,
    this.nomeEvento,
    this.aposAceite = false,
  });

  final String idFornecedor;
  final String idEvento;
  final AvaliacaoServicoController controller;
  final EventThemeController themeController;
  final String? idOrcamento;
  final String? idServico;
  final String? nomeFornecedor;
  final String? nomeServico;
  final String? nomeEvento;
  final bool aposAceite;

  @override
  State<AvaliarContratacaoSheet> createState() =>
      _AvaliarContratacaoSheetState();
}

class _ContratacaoNota {
  _ContratacaoNota(this.dados);
  final Map<String, dynamic> dados;
  String get idOrcamento => dados['idOrcamento']?.toString() ?? '';
  String get nome => dados['nome']?.toString() ?? 'Contratação';
  String? get idServico {
    final s = dados['idServico']?.toString().trim();
    return s == null || s.isEmpty ? null : s;
  }

  bool get pendenteFornecedor => dados['pendenteFornecedor'] == true;
  bool get pendenteServico => dados['pendenteServico'] == true;
  bool get detalhada => dados.containsKey('pendenteFornecedor');
}

class _AvaliarContratacaoSheetState extends State<AvaliarContratacaoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _comentarioFornecedor = TextEditingController();
  final _comentarioServico = TextEditingController();
  var _autovalidate = AutovalidateMode.disabled;
  var _carregando = true;
  var _enviando = false;
  String? _erro;
  String? _avisoEnvio;
  List<_ContratacaoNota> _opcoes = [];
  _ContratacaoNota? _escolhida;
  int? _notaFornecedor;
  int? _notaServico;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _comentarioFornecedor.dispose();
    _comentarioServico.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final lista = await widget.controller.contratosAvaliaveis(
        idFornecedor: widget.idFornecedor,
        idEvento: widget.idEvento,
        idOrcamento: widget.idOrcamento,
        detalhar: true,
      );
      if (!mounted) return;
      final alvo = widget.idOrcamento;
      final opcoes = lista
          .map((item) => _ContratacaoNota(Map<String, dynamic>.from(item)))
          .where((item) =>
              item.idOrcamento.isNotEmpty &&
              (alvo == null || item.idOrcamento == alvo))
          .toList();
      setState(() {
        _carregando = false;
        _opcoes = opcoes;
        if (opcoes.length == 1) _escolhida = opcoes.single;
        _aplicarServicoConhecido();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Não foi possível consultar as contratações com entrega aceita.';
      });
    }
  }

  void _aplicarServicoConhecido() {
    final atual = _escolhida;
    final hint = widget.idServico?.trim();
    if (atual == null || hint == null || hint.isEmpty) return;
    if (atual.idServico != null) return;
    atual.dados['idServico'] = hint;
  }

  bool get _pendenteFornecedor {
    final item = _escolhida;
    if (item == null) return false;
    if (item.detalhada) return item.pendenteFornecedor;
    return true;
  }

  bool get _pendenteServico {
    final item = _escolhida;
    if (item == null || item.idServico == null) return false;
    if (item.detalhada) return item.pendenteServico;
    return true;
  }

  bool get _prontoParaEnviar {
    if (_escolhida == null || _enviando) return false;
    if (_pendenteFornecedor && _notaFornecedor == null) return false;
    if (_pendenteServico && _notaServico == null) return false;
    return _pendenteFornecedor || _pendenteServico;
  }

  String get _rotuloBotao {
    if (_pendenteFornecedor && _pendenteServico) return 'Enviar as duas notas';
    if (_pendenteFornecedor) return 'Enviar nota do fornecedor';
    return 'Enviar nota do serviço';
  }

  Future<void> _enviar() async {
    final item = _escolhida;
    if (!_prontoParaEnviar || item == null) return;
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _enviando = true;
      _avisoEnvio = null;
    });
    var salvouFornecedor = false;
    try {
      if (_pendenteFornecedor) {
        await widget.controller.registrarAvaliacao(
          idFornecedor: widget.idFornecedor,
          idOrcamento: item.idOrcamento,
          nota: _notaFornecedor!,
          comentario: _comentarioFornecedor.text.trim(),
          idEvento: widget.idEvento,
        );
        salvouFornecedor = true;
        item.dados['pendenteFornecedor'] = false;
      }
      if (_pendenteServico) {
        await widget.controller.registrarAvaliacao(
          idFornecedor: widget.idFornecedor,
          idOrcamento: item.idOrcamento,
          idServico: item.idServico,
          nota: _notaServico!,
          comentario: _comentarioServico.text.trim(),
          idEvento: widget.idEvento,
        );
        item.dados['pendenteServico'] = false;
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _avisoEnvio = salvouFornecedor
            ? 'A nota do fornecedor foi salva. A do serviço não foi. Toque de novo para enviar só ela.'
            : 'Não foi possível enviar. Tente de novo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.themeController.primaryColor.value;
    final altura = MediaQuery.sizeOf(context).height * 0.92;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: altura),
        child: Material(
          color: const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: _carregando
              ? const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _erro != null
                  ? _mensagem(_erro!, primary, fechar: true)
                  : _escolhida == null
                      ? _lista(primary)
                      : SizedBox(height: altura, child: _formulario(primary)),
        ),
      ),
    );
  }

  Widget _lista(Color primary) {
    if (_opcoes.isEmpty) {
      return _mensagem(
        widget.idOrcamento == null
            ? 'Nenhuma contratação com entrega aceita está pendente de nota neste evento.'
            : 'Esta contratação ainda não está pronta para nota. Aceite a entrega no acompanhamento e volte aqui.',
        primary,
        complemento: 'A nota abre depois que você aceita a entrega.',
        fechar: true,
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        _alca(),
        Text('Qual contratação você quer avaliar?',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          'Cada item tem duas notas: a do fornecedor e a deste serviço.',
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        for (final item in _opcoes)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.nome,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            subtitle: Text(_resumoPendencia(item),
                style: GoogleFonts.poppins(fontSize: 12.5)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => setState(() {
              _escolhida = item;
              _aplicarServicoConhecido();
            }),
          ),
      ],
    );
  }

  String _resumoPendencia(_ContratacaoNota item) {
    if (!item.detalhada) return 'Entrega aceita. Escolha para avaliar.';
    final partes = [
      if (item.pendenteFornecedor) 'fornecedor',
      if (item.pendenteServico) 'serviço',
    ];
    if (partes.isEmpty) return 'As duas notas já foram enviadas.';
    return 'Falta a nota ${partes.join(' e ')}.';
  }

  Widget _formulario(Color primary) {
    final item = _escolhida!;
    final servico = (widget.nomeServico?.trim().isNotEmpty == true
            ? widget.nomeServico!
            : item.nome)
        .trim();
    final fornecedor = widget.nomeFornecedor?.trim();
    final ambasProntas = item.detalhada &&
        !item.pendenteFornecedor &&
        !item.pendenteServico;
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidate,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              children: [
                _alca(),
                Text(
                  widget.aposAceite
                      ? 'Entrega aceita'
                      : 'Como foi esta contratação?',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w800, height: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    servico,
                    if (fornecedor != null && fornecedor.isNotEmpty) fornecedor,
                  ].join(' · '),
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.aposAceite
                      ? 'Se quiser, deixe as duas notas agora. Dá para fazer isso depois neste card.'
                      : 'São duas notas separadas. A do fornecedor entra na reputação pública. A do serviço fica neste item. Elas não se somam.',
                  style: GoogleFonts.poppins(
                      fontSize: 13, height: 1.4, color: const Color(0xFF334155)),
                ),
                if (_opcoes.length > 1)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _enviando
                          ? null
                          : () => setState(() {
                                _escolhida = null;
                                _notaFornecedor = null;
                                _notaServico = null;
                              }),
                      child: const Text('Escolher outra contratação'),
                    ),
                  ),
                if (ambasProntas)
                  _mensagem(
                    'Você já avaliou o fornecedor e este serviço. As notas ficam registradas e não podem ser alteradas.',
                    primary,
                  )
                else ...[
                  const SizedBox(height: 8),
                  Text('Toque na estrela. A nota é inteira, de 1 a 5.',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: const Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  _blocoNota(
                    primary: primary,
                    titulo: 'O fornecedor',
                    ajuda:
                        'Atendimento, combinado e confiança nesta contratação.',
                    destino: 'Entra na reputação pública do fornecedor.',
                    pendente: _pendenteFornecedor,
                    nota: _notaFornecedor,
                    comentario: _comentarioFornecedor,
                    hint: 'Comentário sobre o fornecedor (opcional)',
                    jaEnviada:
                        'A nota do fornecedor já foi enviada. Ela não pode ser alterada.',
                    onNota: (v) => setState(() => _notaFornecedor = v),
                  ),
                  const SizedBox(height: 12),
                  if (item.idServico == null)
                    _caixa(
                      'Não identificamos o serviço deste contrato. A nota do fornecedor continua disponível.',
                    )
                  else
                    _blocoNota(
                      primary: primary,
                      titulo: 'Este serviço',
                      ajuda: 'Qualidade do que foi entregue neste item.',
                      destino: 'Fica na página deste serviço.',
                      pendente: _pendenteServico,
                      nota: _notaServico,
                      comentario: _comentarioServico,
                      hint: 'Comentário sobre o serviço (opcional)',
                      jaEnviada:
                          'A nota deste serviço já foi enviada. Ela não pode ser alterada.',
                      onNota: (v) => setState(() => _notaServico = v),
                    ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_avisoEnvio != null) ...[
                  Text(_avisoEnvio!,
                      style: GoogleFonts.poppins(
                          color: const Color(0xFFB45309), fontSize: 13)),
                  const SizedBox(height: 8),
                ],
                if (!ambasProntas) ...[
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _prontoParaEnviar ? _enviar : null,
                      style: FilledButton.styleFrom(backgroundColor: primary),
                      child: Text(
                        _enviando ? 'Enviando...' : _rotuloBotao,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (!_prontoParaEnviar)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Escolha a nota de 1 a 5 em cada bloco que ainda está pendente.',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ),
                ],
                TextButton(
                  onPressed: _enviando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocoNota({
    required Color primary,
    required String titulo,
    required String ajuda,
    required String destino,
    required bool pendente,
    required int? nota,
    required TextEditingController comentario,
    required String hint,
    required String jaEnviada,
    required ValueChanged<int> onNota,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: pendente
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(ajuda,
                    style: GoogleFonts.poppins(
                        fontSize: 12.5, color: const Color(0xFF334155))),
                Text(destino,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: const Color(0xFF64748B))),
                const SizedBox(height: 8),
                StarRatingWidget(
                  rating: (nota ?? 0).toDouble(),
                  apenasInteiras: true,
                  size: 40,
                  onChanged: (v) => onNota(v.round()),
                ),
                if (nota != null)
                  Text(_rotulosNota[nota],
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, color: primary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: comentario,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => FormValidators.descricao(
                    v,
                    campo: 'o comentário',
                    obrigatorio: false,
                    minimo: 3,
                    maximo: 500,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF047857)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    jaEnviada,
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _mensagem(String texto, Color primary,
      {String? complemento, bool fechar = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _alca(),
          Text(texto,
              style: GoogleFonts.poppins(fontSize: 14, height: 1.4)),
          if (complemento != null) ...[
            const SizedBox(height: 8),
            Text(complemento,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: const Color(0xFF64748B))),
          ],
          if (fechar)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Fechar',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, color: primary)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _caixa(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(texto,
          style: GoogleFonts.poppins(fontSize: 13, height: 1.35)),
    );
  }

  Widget _alca() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

/// Botão do perfil. A consulta fica neste widget, sem flag global do controller.
class BotaoAvaliarContratacaoEvento extends StatefulWidget {
  const BotaoAvaliarContratacaoEvento({
    super.key,
    required this.idFornecedor,
    required this.idEvento,
    required this.nomeFornecedor,
    required this.controller,
    required this.themeController,
    this.nomeEvento,
  });

  final String idFornecedor;
  final String idEvento;
  final String nomeFornecedor;
  final String? nomeEvento;
  final AvaliacaoServicoController controller;
  final EventThemeController themeController;

  @override
  State<BotaoAvaliarContratacaoEvento> createState() =>
      _BotaoAvaliarContratacaoEventoState();
}

class _BotaoAvaliarContratacaoEventoState
    extends State<BotaoAvaliarContratacaoEvento> {
  var _visivel = false;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  Future<void> _consultar() async {
    if (widget.idEvento.trim().isEmpty) return;
    try {
      final lista = await widget.controller.contratosAvaliaveis(
        idFornecedor: widget.idFornecedor,
        idEvento: widget.idEvento,
        detalhar: true,
      );
      if (!mounted) return;
      final pendente = lista.any((item) =>
          item['pendenteFornecedor'] == true ||
          item['pendenteServico'] == true ||
          !item.containsKey('pendenteFornecedor'));
      setState(() => _visivel = pendente && lista.isNotEmpty);
    } catch (_) {
      if (mounted) setState(() => _visivel = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visivel) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          icon: Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 18),
          label: Text(
            'Avaliar contratação deste evento',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          onPressed: () => mostrarAvaliarContratacao(
            context,
            idFornecedor: widget.idFornecedor,
            idEvento: widget.idEvento,
            nomeFornecedor: widget.nomeFornecedor,
            nomeEvento: widget.nomeEvento,
            controller: widget.controller,
            themeController: widget.themeController,
          ),
        ),
      ),
    );
  }
}
