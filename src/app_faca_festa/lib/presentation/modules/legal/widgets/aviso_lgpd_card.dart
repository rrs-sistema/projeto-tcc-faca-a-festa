import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AvisoLgpdCard extends StatelessWidget {
  const AvisoLgpdCard({
    super.key,
    required this.texto,
    this.icone = Icons.privacy_tip_outlined,
    this.compacto = false,
  });

  final String texto;
  final IconData icone;
  final bool compacto;

  static const acessoRestritoCotacao =
      'Acesso restrito: você vê apenas a sua cotação, não o orçamento global do evento.';

  static const orcamentoCompletoOrganizador =
      'Este é o orçamento completo do evento. Só você vê estes valores. O fornecedor recebe apenas a cotação do serviço dele.';

  static const dadosCrianca =
      'Dados de criança ou bebê (art. 14 da LGPD). Informe só o primeiro nome. Você declara ser o responsável por esses dados. Não pedimos documento da criança.';

  static const minimizacaoEndereco =
      'O match com fornecedores usa cidade e região. O endereço completo fica só com você, para o local do evento.';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compacto ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: const Color(0xFFC2410C), size: compacto ? 16 : 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.poppins(
                fontSize: compacto ? 11.5 : 12.5,
                height: 1.35,
                color: const Color(0xFF7C2D12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
