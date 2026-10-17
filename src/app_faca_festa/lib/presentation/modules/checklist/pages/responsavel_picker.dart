import 'package:flutter/material.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';

/// Mantém a busca e a rolagem de convidados fora do formulário da tarefa.
Future<Convidado?> showResponsavelPicker({
  required BuildContext context,
  required List<Convidado> pessoas,
  required Color primary,
  String? selecionadoId,
  String? idUsuarioLogado,
}) {
  return showModalBottomSheet<Convidado>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ResponsavelPicker(
      pessoas: pessoas,
      primary: primary,
      selecionadoId: selecionadoId,
      idUsuarioLogado: idUsuarioLogado,
    ),
  );
}

class ResponsavelPicker extends StatefulWidget {
  const ResponsavelPicker({
    super.key,
    required this.pessoas,
    required this.primary,
    this.selecionadoId,
    this.idUsuarioLogado,
  });

  final List<Convidado> pessoas;
  final Color primary;
  final String? selecionadoId;
  final String? idUsuarioLogado;

  @override
  State<ResponsavelPicker> createState() => _ResponsavelPickerState();
}

class _ResponsavelPickerState extends State<ResponsavelPicker> {
  final _busca = TextEditingController();

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  bool _voce(Convidado pessoa) =>
      widget.idUsuarioLogado != null &&
      (pessoa.idUsuario == widget.idUsuarioLogado ||
          pessoa.idConvidado == widget.idUsuarioLogado);

  @override
  Widget build(BuildContext context) {
    final consulta = _normalizar(_busca.text.trim());
    final palavras = consulta.split(RegExp(r'\s+'));
    final resultado = widget.pessoas.where((pessoa) {
      final texto = _normalizar('${pessoa.nome} ${pessoa.nomeGrupo ?? ''}');
      return palavras.every(texto.contains);
    }).toList()
      ..sort((a, b) {
        if (a.idConvidado == b.idConvidado) return 0;
        if (a.idConvidado == widget.selecionadoId) return -1;
        if (b.idConvidado == widget.selecionadoId) return 1;
        if (_voce(a) != _voce(b)) return _voce(a) ? -1 : 1;
        return _normalizar(a.nome).compareTo(_normalizar(b.nome));
      });
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFD7DDD9),
                    borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
              child: Row(children: [
                const Expanded(
                    child: Text('Escolher responsável',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700))),
                IconButton(
                    tooltip: 'Fechar seleção',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _busca,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar por nome ou grupo',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _busca.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: () {
                            _busca.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded)),
                  filled: true,
                  fillColor: const Color(0xFFF3F5F4),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      '${resultado.length} ${resultado.length == 1 ? 'pessoa' : 'pessoas'}',
                      style: const TextStyle(
                          color: Color(0xFF66736B), fontSize: 13))),
            ),
            Expanded(
              child: resultado.isEmpty
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                              'Nenhuma pessoa encontrada.\nTente outro nome ou grupo.',
                              textAlign: TextAlign.center)))
                  : Scrollbar(
                      child: ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: resultado.length,
                      itemBuilder: (context, index) {
                        final pessoa = resultado[index];
                        final selecionada =
                            pessoa.idConvidado == widget.selecionadoId;
                        final detalhe = [
                          if (_voce(pessoa)) 'Você',
                          if ((pessoa.nomeGrupo ?? '').trim().isNotEmpty)
                            pessoa.nomeGrupo!
                        ].join(' · ');
                        return ListTile(
                          selected: selecionada,
                          selectedTileColor:
                              widget.primary.withValues(alpha: .08),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          leading: CircleAvatar(
                              backgroundColor:
                                  widget.primary.withValues(alpha: .1),
                              foregroundColor: widget.primary,
                              child: Text(iniciaisResponsavel(pessoa.nome),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700))),
                          title: Text(pessoa.nome,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: detalhe.isEmpty ? null : Text(detalhe),
                          trailing: selecionada
                              ? Icon(Icons.check_circle_rounded,
                                  color: widget.primary)
                              : null,
                          onTap: () => Navigator.pop(context, pessoa),
                        );
                      },
                    )),
            ),
          ],
        ),
      ),
    );
  }
}

String iniciaisResponsavel(String nome) {
  final partes =
      nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  final primeira = String.fromCharCode(partes.first.runes.first);
  final ultima =
      partes.length > 1 ? String.fromCharCode(partes.last.runes.first) : '';
  return '$primeira$ultima'.toUpperCase();
}

String _normalizar(String texto) {
  const comAcentos = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const semAcentos = 'aaaaaeeeeiiiiooooouuuuc';
  var resultado = texto.toLowerCase();
  for (var i = 0; i < comAcentos.length; i++) {
    resultado = resultado.replaceAll(comAcentos[i], semAcentos[i]);
  }
  return resultado;
}
