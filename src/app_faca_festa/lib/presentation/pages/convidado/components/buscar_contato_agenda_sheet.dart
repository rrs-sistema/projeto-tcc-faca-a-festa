import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/agenda_contatos.dart';

Future<ContatoAgenda?> abrirBuscaContatoAgenda({
  required BuildContext context,
  required Color primary,
}) {
  return showModalBottomSheet<ContatoAgenda>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BuscaContatoAgendaSheet(primary: primary),
  );
}

class _BuscaContatoAgendaSheet extends StatefulWidget {
  const _BuscaContatoAgendaSheet({required this.primary});

  final Color primary;

  @override
  State<_BuscaContatoAgendaSheet> createState() =>
      _BuscaContatoAgendaSheetState();
}

class _BuscaContatoAgendaSheetState extends State<_BuscaContatoAgendaSheet> {
  final buscaCtrl = TextEditingController();
  List<ContatoAgenda> _todos = const [];
  List<ContatoAgenda> _filtrados = const [];
  bool _carregando = true;
  String? _erro;

  Color get primary => widget.primary;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await carregarContatosDaAgenda();
      if (!mounted) return;
      setState(() {
        _todos = lista;
        _filtrados = lista;
        _carregando = false;
      });
    } on AgendaContatosSemPermissao {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro =
            'Permita o acesso à agenda para buscar seus contatos.';
      });
    } on AgendaContatosIndisponivel {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'A agenda está disponível no celular (Android ou iOS).';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Não foi possível ler a agenda.';
      });
    }
  }

  void _filtrar(String texto) {
    final q = texto.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtrados = _todos;
        return;
      }
      _filtrados = _todos.where((contato) {
        if (contato.nome.toLowerCase().contains(q)) return true;
        return contato.telefones.any((tel) => tel.contains(q));
      }).toList();
    });
  }

  Future<void> _escolher(ContatoAgenda contato) async {
    if (contato.telefones.length == 1) {
      Navigator.of(context).pop(contato);
      return;
    }
    final escolhido = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qual telefone usar?',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  contato.nome,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                ...contato.telefones.map(
                  (tel) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.phone_outlined, color: primary),
                    title: Text(tel, style: GoogleFonts.poppins(fontSize: 14)),
                    onTap: () => Navigator.of(ctx).pop(tel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || escolhido == null) return;
    Navigator.of(context).pop(
      ContatoAgenda(
        nome: contato.nome,
        telefones: [escolhido],
        email: contato.email,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                color: primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Buscar na agenda',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contatos do celular, a mesma agenda do WhatsApp.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: buscaCtrl,
                  onChanged: _filtrar,
                  enabled: !_carregando && _erro == null,
                  decoration: InputDecoration(
                    hintText: 'Nome ou telefone',
                    prefixIcon: Icon(Icons.search_rounded, color: primary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
              Expanded(child: _corpo(scroll)),
            ],
          ),
        );
      },
    );
  }

  Widget _corpo(ScrollController scroll) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts_outlined, size: 48, color: primary),
            const SizedBox(height: 12),
            Text(
              _erro!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: _carregar, child: const Text('Tentar de novo')),
          ],
        ),
      );
    }
    if (_filtrados.isEmpty) {
      return Center(
        child: Text(
          'Nenhum contato encontrado.',
          style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
        ),
      );
    }
    return ListView.separated(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      itemCount: _filtrados.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final contato = _filtrados[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: primary.withValues(alpha: 0.12),
            child: Text(
              contato.nome.isEmpty ? '?' : contato.nome[0].toUpperCase(),
              style: TextStyle(color: primary, fontWeight: FontWeight.w800),
            ),
          ),
          title: Text(
            contato.nome,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            contato.telefonePrincipal,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          onTap: () => _escolher(contato),
        );
      },
    );
  }
}
