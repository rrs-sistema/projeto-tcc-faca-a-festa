import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/auth/widgets/auth_festa_brand.dart';
import 'package:app_faca_festa/presentation/modules/legal/pages/privacidade_screen.dart';

class AceitePrivacidadeTile extends StatelessWidget {
  const AceitePrivacidadeTile({
    super.key,
    required this.aceito,
    required this.onChanged,
    required this.cor,
  });

  final bool aceito;
  final ValueChanged<bool> onChanged;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF1F6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!aceito),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: aceito,
                activeColor: cor,
                onChanged: (value) => onChanged(value ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 8),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Li e aceito a ',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.35,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(PrivacidadeScreen.rota());
                        },
                        child: Text(
                          'Política de Privacidade',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: AuthFestaBrand.rosa,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(
                        '.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
