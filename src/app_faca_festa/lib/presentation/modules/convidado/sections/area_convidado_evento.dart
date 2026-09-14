part of '../pages/area/area_convidado_home_screen.dart';

extension _AreaConvidadoEventoSection on _AreaConvidadoHomeScreenState {
  Widget _buildInformacoesPage(Evento evento) {
    return Obx(() {
      final eventoObservado = eventoController.eventoAtual.value;
      final eventoAtual = eventoObservado?.idEvento == evento.idEvento
          ? eventoObservado!
          : evento;
      final tipo = eventoController.tipoEventoAtualEntidade?.nome ?? '';
      final nomeEvento = eventoAtual.nomeEvento.trim().isEmpty
          ? 'Evento Especial'
          : eventoAtual.nomeEvento;

      return SingleChildScrollView(
        key: const ValueKey('info'),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), // 🔹 Compacto
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.poppins(
                    fontSize: 16, color: Colors.black87), // 🔹 Menor
                children: [
                  if (tipo.isNotEmpty)
                    TextSpan(
                      text: '$tipo: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: theme.primaryColor.value,
                        fontSize: 14,
                      ),
                    ),
                  TextSpan(
                    text: nomeEvento,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _infoTileDataHora(
              eventoAtual.data,
              eventoAtual.hora,
            ),
            _infoTileComAcao(
              Icons.location_on,
              'Local',
              eventoAtual.localEvento.isNotEmpty
                  ? eventoAtual.localEvento
                  : (eventoAtual.logradouro?.isNotEmpty == true
                      ? '${eventoAtual.logradouro}, ${eventoAtual.numero ?? ''}'
                      : 'Local a definir'),
              onTap: () => _abrirNoMapa(eventoAtual),
            ),
            if ((eventoAtual.tema ?? '').trim().isNotEmpty)
              _infoTile(
                Icons.palette_outlined,
                'Tema',
                eventoAtual.tema!.trim(),
              ),
            if ((eventoAtual.dressCode ?? '').trim().isNotEmpty)
              _infoTile(
                Icons.checkroom_outlined,
                'Traje',
                eventoAtual.dressCode!.trim(),
              ),
            _infoTile(
                Icons.message,
                'Mensagem',
                eventoAtual.mensagemConvidado ??
                    'Prepare-se para uma celebração especial! 💖'),
          ],
        ),
      );
    });
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), // 🔹 Compacto
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        dense: true,
        leading: Icon(icon, color: theme.primaryColor.value, size: 20),
        title: Text(title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black87)),
        subtitle: Text(value,
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
      ),
    );
  }

  Widget _infoTileDataHora(DateTime? data, String? hora) {
    final color = theme.primaryColor.value;
    final dataFormatada =
        data != null ? DateFormat('dd/MM/yyyy').format(data) : '--/--/----';
    final horaFormatada =
        (hora != null && hora.isNotEmpty) ? hora : 'a definir';

    return Container(
      margin: const EdgeInsets.only(bottom: 10), // 🔹 Compacto
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.event_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data e Hora',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 14, color: color.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Text(dataFormatada,
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_rounded,
                          size: 14, color: color.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Text(horaFormatada,
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _infoTileComAcao(IconData icon, String titulo, String valor,
      {VoidCallback? onTap}) {
    final color = theme.primaryColor.value;
    return Container(
      margin: const EdgeInsets.only(bottom: 10), // 🔹 Compacto
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36, height: 36, // 🔹 Ícone menor
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo.toUpperCase(),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            color: Colors.grey.shade600)),
                    const SizedBox(height: 2),
                    Text(valor,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                  ],
                ),
              ),
              if (onTap != null)
                Container(
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.navigation_rounded, color: color, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
