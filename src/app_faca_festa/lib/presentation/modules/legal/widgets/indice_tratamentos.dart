import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/legal/registro_tratamento.dart';

class IndiceTratamentos extends StatefulWidget {
  const IndiceTratamentos({
    super.key,
    required this.primary,
    required this.secondary,
    required this.onPrimary,
  });

  final Color primary;
  final Color secondary;
  final Color onPrimary;

  @override
  State<IndiceTratamentos> createState() => _IndiceTratamentosState();
}

class _IndiceTratamentosState extends State<IndiceTratamentos> {
  final _busca = TextEditingController();
  String? _modulo;

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consulta = _busca.text.trim();
    var itens = RegistroTratamento.buscar(consulta);
    if (_modulo != null) {
      itens = itens.where((item) => item.modulo == _modulo).toList();
    }
    final modulos = <String>[];
    for (final item in itens) {
      if (!modulos.contains(item.modulo)) modulos.add(item.modulo);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: TextField(
            controller: _busca,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Tela, campo ou base legal',
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
              prefixIcon: Icon(Icons.search_rounded, color: widget.primary),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: widget.secondary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: widget.secondary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: widget.primary, width: 1.4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _Filtro(
                rotulo: 'Tudo',
                ativo: _modulo == null,
                primary: widget.primary,
                secondary: widget.secondary,
                onPrimary: widget.onPrimary,
                onTap: () => setState(() => _modulo = null),
              ),
              for (final modulo in RegistroTratamento.modulos) ...[
                const SizedBox(width: 8),
                _Filtro(
                  rotulo: modulo,
                  ativo: _modulo == modulo,
                  primary: widget.primary,
                  secondary: widget.secondary,
                  onPrimary: widget.onPrimary,
                  onTap: () => setState(() {
                    _modulo = _modulo == modulo ? null : modulo;
                  }),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Text(
            itens.isEmpty
                ? 'Nenhuma tela com esse termo.'
                : '${itens.length} telas com dados pessoais',
            style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              for (final modulo in modulos) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    modulo,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.primary,
                    ),
                  ),
                ),
                for (final item in itens.where((item) => item.modulo == modulo))
                  _Card(
                    item: item,
                    primary: widget.primary,
                    secondary: widget.secondary,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Filtro extends StatelessWidget {
  const _Filtro({
    required this.rotulo,
    required this.ativo,
    required this.primary,
    required this.secondary,
    required this.onPrimary,
    required this.onTap,
  });

  final String rotulo;
  final bool ativo;
  final Color primary;
  final Color secondary;
  final Color onPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ativo ? primary : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ativo ? primary : secondary),
          ),
          child: Text(
            rotulo,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: ativo ? onPrimary : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.item,
    required this.primary,
    required this.secondary,
  });

  final TratamentoDados item;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: secondary),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(12, 2, 8, 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          iconColor: primary,
          collapsedIconColor: primary,
          leading: Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            item.tela,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          subtitle: Text(
            item.campos.join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          children: [
            _linha('Titulares', item.titulares),
            _linha('Finalidade', item.finalidade),
            _linha('Base legal', item.baseLegal),
            _linha('Proteção', item.protecao),
            _linha('Retenção', item.retencao),
            _linha('Com quem', item.compartilhamento),
          ],
        ),
      ),
    );
  }

  Widget _linha(String rotulo, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: primary.withValues(alpha: 0.7),
            ),
          ),
          Text(
            texto,
            style: GoogleFonts.poppins(fontSize: 13, height: 1.35, color: const Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}
