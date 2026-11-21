part of '../pages/area/area_convidado_home_screen.dart';

extension _AreaConvidadoEventoSection on _AreaConvidadoHomeScreenState {
  Widget _buildInformacoesPage(Evento evento, Convidado convidado) {
    return Obx(() {
      final eventoObservado = eventoController.eventoAtual.value;
      final eventoAtual = eventoObservado?.idEvento == evento.idEvento
          ? eventoObservado!
          : evento;
      final cor = theme.primaryColor.value;
      final nome = convidado.nome.split(' ').first;
      final pendente = _statusPresencaAtual == StatusConvidado.pendente;
      final titulo = eventoAtual.nomeEvento.trim().isEmpty
          ? theme.tituloCabecalho.value
          : eventoAtual.nomeEvento.trim();
      final tipo = theme.tituloCabecalho.value.trim();

      return Padding(
        key: const ValueKey('info'),
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: LayoutBuilder(
          builder: (context, limites) {
            return Align(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: limites.maxWidth,
                  child: _cartaoConvite(
                    cor: cor,
                    nomeConvidado: nome,
                    tipoEvento: tipo,
                    titulo: titulo,
                    evento: eventoAtual,
                    pendente: pendente,
                    compacto: limites.maxHeight < 620,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _cartaoConvite({
    required Color cor,
    required String nomeConvidado,
    required String tipoEvento,
    required String titulo,
    required Evento evento,
    required bool pendente,
    required bool compacto,
  }) {
    final dia = DateFormat('d', 'pt_BR').format(evento.data);
    final mesAno = DateFormat("MMMM y", 'pt_BR').format(evento.data);
    final diaSemana = DateFormat('EEEE', 'pt_BR').format(evento.data);
    final hora = (evento.hora != null && evento.hora!.trim().isNotEmpty)
        ? evento.hora!.trim()
        : null;
    final local = evento.localEvento.isNotEmpty
        ? evento.localEvento
        : (evento.logradouro?.isNotEmpty == true
            ? '${evento.logradouro}, ${evento.numero ?? ''}'.trim()
            : 'Local a definir');
    final tema = (evento.tema ?? '').trim();
    final traje = (evento.dressCode ?? '').trim();
    final mensagem = (evento.mensagemConvidado ?? '').trim();
    final tinta = Color.lerp(cor, const Color(0xFF1F2937), 0.42)!;
    final papel = Color.lerp(const Color(0xFFFFFBF5), cor, 0.03)!;
    final tipoLimpo = _textoTipoConvite(tipoEvento);
    final gap = compacto ? 8.0 : 12.0;
    final padV = compacto ? 16.0 : 22.0;

    return Semantics(
      label: 'Convite: $titulo. $dia de $mesAno. $local',
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              papel,
              Color.lerp(papel, Colors.white, 0.35)!,
            ],
          ),
          border: Border.all(color: cor.withValues(alpha: 0.28), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: cor.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ConviteCantosPainter(
                    cor: cor.withValues(alpha: 0.45),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(18, padV, 18, compacto ? 12 : 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'COM CARINHO PARA',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.4,
                        color: cor.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nomeConvidado,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: compacto ? 22 : 24,
                        fontWeight: FontWeight.w600,
                        color: tinta,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: gap),
                    _ornamento(cor),
                    SizedBox(height: gap),
                    Text(
                      'Você está convidado(a)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: compacto ? 18 : 20,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        height: 1.15,
                        color: tinta.withValues(alpha: 0.88),
                      ),
                    ),
                    if (tipoLimpo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tipoLimpo.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: compacto ? 26 : 30,
                        fontWeight: FontWeight.w700,
                        height: 1.08,
                        color: tinta,
                      ),
                    ),
                    SizedBox(height: gap + 2),
                    _blocoData(
                      cor: cor,
                      tinta: tinta,
                      dia: dia,
                      mesAno: mesAno,
                      diaSemana: diaSemana,
                      hora: hora,
                      compacto: compacto,
                    ),
                    SizedBox(height: gap),
                    _ornamento(cor),
                    SizedBox(height: gap - 2),
                    Text(
                      local,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: compacto ? 15 : 17,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: tinta,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _abrirNoMapa(evento),
                      style: TextButton.styleFrom(
                        foregroundColor: cor,
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        minimumSize: const Size(0, 28),
                      ),
                      child: Text(
                        'Ver no mapa',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: cor.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    if (tema.isNotEmpty || traje.isNotEmpty) ...[
                      SizedBox(height: gap - 4),
                      _ornamento(cor),
                      SizedBox(height: gap - 2),
                      if (tema.isNotEmpty)
                        _linhaCerimonial(
                            rotulo: 'Tema', valor: tema, cor: tinta),
                      if (tema.isNotEmpty && traje.isNotEmpty)
                        const SizedBox(height: 2),
                      if (traje.isNotEmpty)
                        _linhaCerimonial(
                            rotulo: 'Traje', valor: traje, cor: tinta),
                    ],
                    if (mensagem.isNotEmpty) ...[
                      SizedBox(height: gap),
                      Text(
                        '“$mensagem”',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          height: 1.25,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    if (pendente) ...[
                      SizedBox(height: gap + 2),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _irParaPresenca,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cor,
                            side: BorderSide(color: cor, width: 1.3),
                            padding: EdgeInsets.symmetric(
                                vertical: compacto ? 10 : 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            'Confirmar presença',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Faça a Festa',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                        color: cor.withValues(alpha: 0.38),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blocoData({
    required Color cor,
    required Color tinta,
    required String dia,
    required String mesAno,
    required String diaSemana,
    required String? hora,
    required bool compacto,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          dia,
          style: GoogleFonts.cormorantGaramond(
            fontSize: compacto ? 40 : 44,
            fontWeight: FontWeight.w600,
            height: 1,
            color: cor,
          ),
        ),
        Container(
          width: 1,
          height: compacto ? 40 : 44,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: cor.withValues(alpha: 0.25),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diaSemana,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              mesAno,
              style: GoogleFonts.cormorantGaramond(
                fontSize: compacto ? 16 : 17,
                fontWeight: FontWeight.w600,
                color: tinta,
                height: 1.1,
              ),
            ),
            if (hora != null)
              Text(
                'às $hora',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _linhaCerimonial({
    required String rotulo,
    required String valor,
    required Color cor,
  }) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$rotulo  ·  ',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.grey.shade600,
            ),
          ),
          TextSpan(
            text: valor,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  String _textoTipoConvite(String valor) {
    final limpo = valor
        .replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2600}-\u{27BF}]', unicode: true), '')
        .trim();
    return limpo.isEmpty ? valor.trim() : limpo;
  }

  Widget _ornamento(Color cor) {
    return Row(
      children: [
        Expanded(child: Divider(color: cor.withValues(alpha: 0.18), height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(child: Divider(color: cor.withValues(alpha: 0.18), height: 1)),
      ],
    );
  }

  Future<void> _abrirNoMapa(Evento evento) async {
    final endereco = [
      evento.logradouro,
      evento.numero,
      evento.bairro,
      evento.nomeCidade,
      evento.uf
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');
    final destino = endereco.isNotEmpty
        ? endereco
        : (evento.localEvento.isNotEmpty
            ? evento.localEvento
            : 'Local do evento');
    final url = Uri.encodeFull(
        'https://www.google.com/maps/search/?api=1&query=$destino');

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}

class _ConviteCantosPainter extends CustomPainter {
  _ConviteCantosPainter({required this.cor});

  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const reach = 16.0;
    const inset = 10.0;

    void canto(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y), Offset(x + dx * reach, y), paint);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * reach), paint);
    }

    canto(inset, inset, 1, 1);
    canto(size.width - inset, inset, -1, 1);
    canto(inset, size.height - inset, 1, -1);
    canto(size.width - inset, size.height - inset, -1, -1);
  }

  @override
  bool shouldRepaint(covariant _ConviteCantosPainter oldDelegate) =>
      oldDelegate.cor != cor;
}
