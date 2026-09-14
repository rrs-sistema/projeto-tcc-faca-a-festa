part of '../pages/calculadora_festa_screen.dart';

extension _CalculadoraFestaLayout on _CalculadoraFestaScreenState {
  Widget _buildHero(Color primary, LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cálculo de Itens',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Sugestões inteligentes baseadas no público e duração.',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardapioCard(Color primary) {
    return _SectionCard(
      title: 'Cardápio',
      icon: Icons.restaurant_menu_rounded,
      primary: primary,
      child: Obx(() {
        final cardapios = cardapioController.cardapios;

        if (cardapios.isEmpty) {
          return _EmptyMessage(
            icon: Icons.no_meals_outlined,
            text: 'Crie um cardápio antes de enviar.',
            iconColor: primary,
          );
        }

        final selectedValue =
            cardapios.any((c) => c.idCardapio == idCardapioSelecionado.value)
                ? idCardapioSelecionado.value
                : null;

        return SizedBox(
          height: 44, // Força uma altura menor no dropdown
          child: DropdownButtonFormField<String>(
            value: selectedValue,
            isDense: true,
            iconEnabledColor: primary,
            iconDisabledColor: primary.withValues(alpha: 0.4),
            decoration: InputDecoration(
              labelText: 'Destino',
              labelStyle: GoogleFonts.poppins(fontSize: 12),
              prefixIcon: Icon(
                Icons.restaurant_rounded,
                size: 18,
                color: primary,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primary),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: cardapios.map((cardapio) {
              return DropdownMenuItem<String>(
                value: cardapio.idCardapio,
                child: Text(cardapio.titulo,
                    style: GoogleFonts.poppins(fontSize: 12)),
              );
            }).toList(),
            onChanged: (value) => idCardapioSelecionado.value = value ?? '',
          ),
        );
      }),
    );
  }

  Widget _buildAcoes(Color primary) {
    return Obx(() {
      final salvando = calculadoraController.salvando.value;
      final enviando = calculadoraController.enviandoParaCardapio.value;

      return Row(
        // Colocando os botões lado a lado para economizar mais espaço
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.zero,
                ),
                onPressed: salvando ? null : _salvarCalculo,
                icon: salvando
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18, color: Colors.white),
                label: Text(
                  salvando ? 'Salvando...' : 'Salvar',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.55)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.zero,
                ),
                onPressed: enviando || idCardapioSelecionado.value.isEmpty
                    ? null
                    : _enviarParaCardapio,
                icon: enviando
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primary))
                    : Icon(Icons.playlist_add_check_rounded,
                        size: 18, color: primary),
                label: Text(
                  enviando ? 'Enviando...' : 'Adicionar',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
