part of '../pages/area/area_convidado_home_screen.dart';

extension _AreaConvidadoPresencaSection on _AreaConvidadoHomeScreenState {
  Widget _buildConfirmacaoPage(Convidado? convidado) {
    if (convidado == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final primary = theme.primaryColor.value;
    final statusAtual = _statusPresencaLocal ?? convidado.status;
    final confirmado = statusAtual == StatusConvidado.confirmado;
    final naoVai = statusAtual == StatusConvidado.recusado;
    final aguardando = !confirmado && !naoVai;

    final statusLinha = confirmado
        ? 'Presença confirmada'
        : naoVai
            ? 'Ausência informada'
            : 'Ainda sem resposta';

    return Padding(
      key: ValueKey('confirmacao_${statusAtual.name}'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Text(
            'Você vai à festa?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusLinha,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: confirmado
                  ? Colors.green.shade700
                  : naoVai
                      ? Colors.redAccent.shade400
                      : primary,
            ),
          ),
          const SizedBox(height: 16),
          _presencaChoiceTile(
            selected: confirmado,
            icon: Icons.celebration_rounded,
            titulo: 'Vou',
            cor: Colors.green.shade600,
            onTap: () {
              if (confirmado) return;
              _confirmarAlteracaoPresenca(
                convidado: convidado,
                novoStatus: StatusConvidado.confirmado,
                titulo: 'Confirmar presença?',
                mensagem: 'O organizador verá que você vai à festa.',
                textoBotao: 'Confirmar',
                icone: Icons.celebration_rounded,
              );
            },
          ),
          const SizedBox(height: 8),
          _presencaChoiceTile(
            selected: aguardando,
            icon: Icons.help_outline_rounded,
            titulo: 'Ainda não sei',
            cor: primary,
            onTap: () {
              if (aguardando) return;
              _confirmarAlteracaoPresenca(
                convidado: convidado,
                novoStatus: StatusConvidado.pendente,
                titulo: 'Deixar em dúvida?',
                mensagem: 'Você pode confirmar ou recusar depois.',
                textoBotao: 'Deixar em dúvida',
                icone: Icons.help_outline_rounded,
              );
            },
          ),
          const SizedBox(height: 8),
          _presencaChoiceTile(
            selected: naoVai,
            icon: Icons.event_busy_rounded,
            titulo: 'Não vou',
            cor: Colors.redAccent.shade400,
            onTap: () {
              if (naoVai) return;
              _confirmarAlteracaoPresenca(
                convidado: convidado,
                novoStatus: StatusConvidado.recusado,
                titulo:
                    confirmado ? 'Cancelar presença?' : 'Informar ausência?',
                mensagem: 'O organizador verá que você não poderá ir.',
                textoBotao: confirmado ? 'Cancelar presença' : 'Não vou',
                icone: Icons.event_busy_rounded,
              );
            },
          ),
          const Spacer(),
          Text(
            'Pode alterar depois.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _presencaChoiceTile({
    required bool selected,
    required IconData icon,
    required String titulo,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? cor : cor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? cor : cor.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? Colors.white : cor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_rounded : Icons.chevron_right_rounded,
                color: selected ? Colors.white : cor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _salvarStatusPresenca(Convidado convidado, StatusConvidado novoStatus) {
    _atualizarTela(() => _statusPresencaLocal = novoStatus);
    convidadoController.atualizarStatusPresenca(convidado, novoStatus);
    final mensagem = switch (novoStatus) {
      StatusConvidado.confirmado => 'Presença confirmada.',
      StatusConvidado.recusado => 'Ausência informada.',
      StatusConvidado.pendente => 'Resposta: ainda não sei.',
    };
    Get.snackbar(
      'Pronto',
      mensagem,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(14),
      borderRadius: 16,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      duration: const Duration(seconds: 2),
    );
  }

  void _confirmarAlteracaoPresenca({
    required Convidado convidado,
    required StatusConvidado novoStatus,
    required String titulo,
    required String mensagem,
    required String textoBotao,
    required IconData icone,
  }) {
    final actionColor = switch (novoStatus) {
      StatusConvidado.confirmado => Colors.green.shade600,
      StatusConvidado.recusado => Colors.redAccent.shade400,
      StatusConvidado.pendente => theme.primaryColor.value,
    };

    Get.bottomSheet(
      SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
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
