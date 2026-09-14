part of '../pages/area/area_convidado_home_screen.dart';

extension _AreaConvidadoPresencaSection on _AreaConvidadoHomeScreenState {
  Widget _buildConfirmacaoPage(Convidado? convidado) {
    if (convidado == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // VERSÃO PREMIUM V2 - resposta sempre editável pelo convidado.
    final primary = theme.primaryColor.value;
    final statusAtual = _statusPresencaLocal ?? convidado.status;
    final confirmado = statusAtual == StatusConvidado.confirmado;
    final naoVai = statusAtual == StatusConvidado.recusado;
    final aguardando = !confirmado && !naoVai;

    final statusColor = confirmado
        ? Colors.green.shade600
        : naoVai
            ? Colors.redAccent.shade400
            : primary;

    final statusIcon = confirmado
        ? Icons.verified_rounded
        : naoVai
            ? Icons.event_busy_rounded
            : Icons.favorite_border_rounded;

    final statusLabel = confirmado
        ? 'Presença confirmada'
        : naoVai
            ? 'Ausência informada'
            : 'Aguardando resposta';

    final statusMessage = confirmado
        ? 'Que alegria! Sua presença está confirmada para este momento especial.'
        : naoVai
            ? 'Tudo certo. Se mudar de ideia, você pode confirmar presença agora.'
            : 'Responda abaixo para ajudar o organizador a preparar tudo com carinho.';

    return ListView(
      key: ValueKey('confirmacao_premium_v2_${statusAtual.name}'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 112),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                statusColor.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: statusColor.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.14)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.98),
                      statusColor.withValues(alpha: 0.62),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(statusIcon, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 16),
              Text(
                aguardando ? 'Você vai participar?' : statusLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  height: 1.45,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: primary.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child:
                        Icon(Icons.touch_app_rounded, color: primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Escolha sua resposta',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Você pode alterar sua decisão a qualquer momento. O organizador receberá a resposta mais recente.',
                style: GoogleFonts.poppins(
                  fontSize: 11.6,
                  height: 1.4,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              _presencaChoiceTile(
                selected: confirmado,
                icon: Icons.celebration_rounded,
                titulo: confirmado ? 'Estou confirmado' : 'Vou participar',
                subtitulo: confirmado
                    ? 'Sua presença já está registrada'
                    : 'Confirmar minha presença no evento',
                cor: Colors.green.shade600,
                onTap: () {
                  if (confirmado) {
                    _mostrarRespostaJaSelecionada(
                        'Sua presença já está confirmada.');
                    return;
                  }

                  _confirmarAlteracaoPresenca(
                    convidado: convidado,
                    novoStatus: StatusConvidado.confirmado,
                    titulo: naoVai
                        ? 'Mudar para confirmado?'
                        : 'Confirmar presença?',
                    mensagem: naoVai
                        ? 'Sua resposta será atualizada de “não poderei ir” para “vou participar”.'
                        : 'O organizador será avisado que você participará do evento.',
                    textoBotao:
                        naoVai ? 'Sim, vou participar' : 'Confirmar presença',
                    icone: Icons.celebration_rounded,
                  );
                },
              ),
              const SizedBox(height: 10),
              _presencaChoiceTile(
                selected: naoVai,
                icon: Icons.event_busy_rounded,
                titulo: naoVai ? 'Não vou participar' : 'Não poderei ir',
                subtitulo: naoVai
                    ? 'Sua ausência já está registrada'
                    : 'Avisar que não conseguirá participar',
                cor: Colors.redAccent.shade400,
                onTap: () {
                  if (naoVai) {
                    _mostrarRespostaJaSelecionada(
                        'Sua ausência já está registrada.');
                    return;
                  }

                  _confirmarAlteracaoPresenca(
                    convidado: convidado,
                    novoStatus: StatusConvidado.recusado,
                    titulo: confirmado
                        ? 'Cancelar presença?'
                        : 'Informar ausência?',
                    mensagem: confirmado
                        ? 'Sua resposta será atualizada de “presença confirmada” para “não poderei ir”.'
                        : 'O organizador será avisado que você não poderá participar.',
                    textoBotao: confirmado
                        ? 'Sim, cancelar presença'
                        : 'Não poderei ir',
                    icone: Icons.event_busy_rounded,
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: primary.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Icon(Icons.sync_rounded, size: 18, color: primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  confirmado
                      ? 'Mudou de ideia? Use “Não poderei ir” para cancelar sua presença.'
                      : naoVai
                          ? 'Mudou de ideia? Use “Vou participar” para confirmar sua presença.'
                          : 'Sua resposta ajuda na organização da festa, lista de convidados e preparativos.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    height: 1.35,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _presencaChoiceTile({
    required bool selected,
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [
                      cor,
                      cor.withValues(alpha: 0.78),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : cor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.36)
                  : cor.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: cor.withValues(alpha: selected ? 0.22 : 0.07),
                blurRadius: selected ? 18 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.20)
                        : cor.withValues(alpha: 0.10),
                  ),
                ),
                child:
                    Icon(icon, color: selected ? Colors.white : cor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.poppins(
                        fontSize: 13.4,
                        fontWeight: FontWeight.w900,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: GoogleFonts.poppins(
                        fontSize: 11.2,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white.withValues(alpha: 0.90)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.20)
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: selected
                          ? Colors.white
                          : cor.withValues(alpha: 0.20)),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  color: selected ? Colors.white : cor,
                  size: selected ? 18 : 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarRespostaJaSelecionada(String mensagem) {
    Get.snackbar(
      'Resposta atual',
      mensagem,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(14),
      borderRadius: 16,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      duration: const Duration(seconds: 2),
    );
  }

  void _salvarStatusPresenca(Convidado convidado, StatusConvidado novoStatus) {
    _atualizarTela(() => _statusPresencaLocal = novoStatus);
    convidadoController.atualizarStatusPresenca(convidado, novoStatus);
  }

  void _confirmarAlteracaoPresenca({
    required Convidado convidado,
    required StatusConvidado novoStatus,
    required String titulo,
    required String mensagem,
    required String textoBotao,
    required IconData icone,
  }) {
    final isConfirmando = novoStatus == StatusConvidado.confirmado;
    final actionColor =
        isConfirmando ? Colors.green.shade600 : Colors.redAccent.shade400;

    Get.bottomSheet(
      SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: actionColor, size: 32),
              ),
              const SizedBox(height: 14),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  height: 1.45,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(icone, size: 18, color: Colors.white),
                  label: Text(textoBotao),
                  onPressed: () {
                    Get.back();
                    _salvarStatusPresenca(convidado, novoStatus);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17)),
                    textStyle: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.poppins(
                        fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Manter resposta atual'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
