import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/uf_cidade_controller.dart';
import './../../widgets/custom_input_field.dart';
import './endereco_section_controller.dart';

class EnderecoSection extends StatefulWidget {
  final Color cor;
  final String titulo;
  final EnderecoSectionController controller;

  const EnderecoSection({
    super.key,
    required this.cor,
    required this.controller,
    required this.titulo,
  });

  @override
  State<EnderecoSection> createState() => _EnderecoSectionState();
}

class _EnderecoSectionState extends State<EnderecoSection> {
  late final UFCidadeController ufCidadeController;
  bool expandido = false;

  @override
  void initState() {
    super.initState();
    ufCidadeController = widget.controller.ufCidadeController;
    _carregarEstadosInicial();
  }

  Future<void> _carregarEstadosInicial() async {
    await ufCidadeController.carregarEstados();

    // ✅ Se já temos um estado/cidade pré-selecionados, sincroniza
    final c = widget.controller;
    final ufAtual = c.ufController.text.trim();
    final cidadeAtual = c.nomeCidadeController.text.trim();

    if (ufAtual.isNotEmpty) {
      final estado = ufCidadeController.estados.firstWhereOrNull((e) => e['uf'] == ufAtual);
      if (estado != null) {
        await ufCidadeController.selecionarEstado(estado);
      }
    }

    if (cidadeAtual.isNotEmpty) {
      final cidade = ufCidadeController.cidades.firstWhereOrNull(
        (c) => c['nome'].toString().toLowerCase() == cidadeAtual.toLowerCase(),
      );
      if (cidade != null) {
        ufCidadeController.selecionarCidade(cidade);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = widget.cor;
    final c = widget.controller;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(Icons.location_on_rounded, color: cor),
              const SizedBox(width: 8),
              Text(
                widget.titulo,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cor,
                ),
              ),
            ],
          ),
          trailing: Icon(
            expandido ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: cor,
            size: 26,
          ),
          onExpansionChanged: (value) => setState(() => expandido = value),
          children: [
            Obx(() {
              if (ufCidadeController.carregando.value) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomInputField(
                    label: "CEP",
                    icon: Icons.local_post_office_outlined,
                    controller: c.cepController,
                    color: cor,
                    keyboardType: TextInputType.number,
                  ),
                  CustomInputField(
                    label: "Logradouro",
                    icon: Icons.home_outlined,
                    controller: c.logradouroController,
                    color: cor,
                  ),
                  CustomInputField(
                    label: "Número",
                    icon: Icons.tag,
                    controller: c.numeroController,
                    color: cor,
                    keyboardType: TextInputType.number,
                  ),
                  CustomInputField(
                    label: "Complemento",
                    icon: Icons.add_location_alt_outlined,
                    controller: c.complementoController,
                    color: cor,
                  ),
                  CustomInputField(
                    label: "Bairro",
                    icon: Icons.map_outlined,
                    controller: c.bairroController,
                    color: cor,
                  ),
                  const SizedBox(height: 10),

                  // === Dropdown Estado ===
                  DropdownButtonFormField<String>(
                    value: ufCidadeController.estadoSelecionado.value?['id'],
                    items: ufCidadeController.estados
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e['id'],
                            child: Text('${e['nome']} (${e['uf']})'),
                          ),
                        )
                        .toList(),
                    onChanged: (id) async {
                      if (id != null) {
                        final estado = ufCidadeController.estados.firstWhere((e) => e['id'] == id);
                        c.ufController.text = estado['uf'];
                        await ufCidadeController.selecionarEstado(estado);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // === Dropdown Cidade ===
                  DropdownButtonFormField<String>(
                    value: ufCidadeController.cidadeSelecionada.value?['id'],
                    items: ufCidadeController.cidades
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c['id'],
                            child: Text(c['nome']),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id != null) {
                        final cidade = ufCidadeController.cidades.firstWhere((c) => c['id'] == id);
                        c.nomeCidadeController.text = cidade['nome'];
                        ufCidadeController.selecionarCidade(cidade);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Cidade',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
