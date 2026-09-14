part of '../pages/inspiracao_admin_form_page.dart';

extension _InspiracaoAdminFormLayout on _InspiracaoAdminFormPageState {
  Widget _buildHeroCard({required bool isWide}) {
    return Container(
      padding: EdgeInsets.fromLTRB(isWide ? 22 : 18, 18, isWide ? 22 : 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isWide ? 58 : 50,
            height: isWide ? 58 : 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdicao
                      ? 'Editar inspiração pública'
                      : 'Cadastrar inspiração pública',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: isWide ? 22 : 18,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Preencha os dados com cuidado para que a ideia apareça corretamente nas buscas, filtros e sugestões do evento.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w500,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Obx(() {
          final salvando =
              controller.salvando.value || controller.enviandoImagem.value;
          final compact = MediaQuery.sizeOf(context).width < 520;

          final cancelar = OutlinedButton.icon(
            onPressed: salvando ? null : () => Get.back(result: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _dark,
              side: BorderSide(color: _dark.withValues(alpha: 0.16)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancelar'),
          );

          final salvar = FilledButton.icon(
            onPressed: salvando ? null : _salvar,
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            ),
            icon: salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(salvando ? 'Salvando...' : 'Salvar'),
          );

          if (compact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                salvar,
                const SizedBox(height: 8),
                cancelar,
              ],
            );
          }

          return Row(
            children: [
              if (_isEdicao)
                TextButton.icon(
                  onPressed: salvando ? null : _confirmarExclusao,
                  style: TextButton.styleFrom(foregroundColor: _danger),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Excluir logicamente'),
                ),
              const Spacer(),
              cancelar,
              const SizedBox(width: 10),
              salvar,
            ],
          );
        }),
      ),
    );
  }

  Widget _responsiveFields({
    required bool isWide,
    required List<Widget> children,
  }) {
    if (!isWide) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children
          .map(
            (child) => SizedBox(
              width: 360,
              child: child,
            ),
          )
          .toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool requiredField = false,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      style: GoogleFonts.poppins(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: _dark,
      ),
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        alignLabelWithHint: maxLines > 1,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: GoogleFonts.poppins(
          color: _muted,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        hintStyle: GoogleFonts.poppins(
          color: _muted.withValues(alpha: 0.72),
          fontWeight: FontWeight.w500,
          fontSize: 12.5,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _dark.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _dark.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _danger, width: 1.2),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: GoogleFonts.poppins(
        color: _muted,
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: _dark.withValues(alpha: 0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: _dark.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _primary, width: 1.4),
      ),
    );
  }

  Widget _buildInlineWarning(String text,
      {required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: _dark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoEventoChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tiposEventoPadrao.map((option) {
        final selected = _tipoEventoIdsSelecionados.contains(option.id);
        return FilterChip(
          selected: selected,
          label: Text(option.nome),
          avatar: selected
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : null,
          onSelected: (value) {
            _atualizarCampo(() {
              if (value) {
                _tipoEventoIdsSelecionados.add(option.id);
              } else {
                _tipoEventoIdsSelecionados.remove(option.id);
              }
              _sincronizarCamposTipos();
            });
          },
          labelStyle: GoogleFonts.poppins(
            color: selected ? Colors.white : _dark,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          selectedColor: _primary,
          checkmarkColor: Colors.white,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: selected ? _primary : _dark.withValues(alpha: 0.10),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildPublicacaoCards({required bool isWide}) {
    final cards = <Widget>[
      _SwitchStatusCard(
        title: 'Ativa',
        subtitle: 'Permite que a inspiração continue disponível no catálogo.',
        icon: Icons.toggle_on_outlined,
        color: _success,
        value: _ativo,
        onChanged: (value) => _atualizarCampo(() => _ativo = value),
      ),
      _SwitchStatusCard(
        title: 'Publicada',
        subtitle: 'Exibe a inspiração para os organizadores no app público.',
        icon: Icons.public_rounded,
        color: _info,
        value: _publicado,
        onChanged: (value) => _atualizarCampo(() => _publicado = value),
      ),
      _SwitchStatusCard(
        title: 'Destaque',
        subtitle: 'Prioriza a inspiração em listas e vitrines de ideias.',
        icon: Icons.star_rounded,
        color: _warning,
        value: _destaque,
        onChanged: (value) => _atualizarCampo(() => _destaque = value),
      ),
    ];

    if (!isWide) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}
