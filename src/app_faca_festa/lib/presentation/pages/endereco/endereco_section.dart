import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../core/utils/form_validators.dart';
import './../../widgets/custom_input_field.dart';
import './endereco_section_controller.dart';

class EnderecoSection extends StatefulWidget {
  final Color cor;
  final String titulo;
  final EnderecoSectionController controller;
  final bool camposObrigatorios;

  const EnderecoSection({
    super.key,
    required this.cor,
    required this.controller,
    required this.titulo,
    this.camposObrigatorios = true,
  });

  @override
  State<EnderecoSection> createState() => _EnderecoSectionState();
}

class _EnderecoSectionState extends State<EnderecoSection> {
  late bool expandido;

  @override
  void initState() {
    super.initState();
    expandido = widget.camposObrigatorios;
  }

  @override
  Widget build(BuildContext context) {
    final cor = widget.cor;
    final c = widget.controller;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(Icons.location_on_rounded, color: cor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          trailing: Icon(
            expandido ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: cor,
            size: 26,
          ),
          initiallyExpanded: widget.camposObrigatorios,
          onExpansionChanged: (value) => setState(() => expandido = value),
          children: [
            CustomInputField(
              label: "CEP",
              hintlabel: "00000-000",
              icon: Icons.local_post_office_outlined,
              controller: c.cepController,
              color: cor,
              titleColor: cor,
              keyboardType: TextInputType.number,
              type: InputType.cep,
              isRequired: widget.camposObrigatorios,
              suffixIcon: Obx(
                () => c.consultandoCep.value
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cor,
                          ),
                        ),
                      )
                    : IconButton(
                        tooltip: 'Buscar CEP',
                        onPressed: () => c.buscarPorCep(forcar: true),
                        icon: Icon(Icons.search_rounded, color: cor),
                      ),
              ),
            ),
            CustomInputField(
              label: "Logradouro",
              icon: Icons.home_outlined,
              controller: c.logradouroController,
              color: cor,
              titleColor: cor,
              isRequired: widget.camposObrigatorios,
              validator: (value) => FormValidators.logradouro(
                value,
                obrigatorio: widget.camposObrigatorios,
              ),
            ),
            CustomInputField(
              label: "Número",
              icon: Icons.tag,
              controller: c.numeroController,
              focusNode: c.numeroFocusNode,
              color: cor,
              titleColor: cor,
              keyboardType: TextInputType.text,
              isRequired: widget.camposObrigatorios,
              validator: (value) => FormValidators.numeroEndereco(
                value,
                obrigatorio: widget.camposObrigatorios,
              ),
            ),
            CustomInputField(
              label: "Complemento",
              icon: Icons.add_location_alt_outlined,
              controller: c.complementoController,
              color: cor,
              titleColor: cor,
            ),
            CustomInputField(
              label: "Bairro",
              icon: Icons.map_outlined,
              controller: c.bairroController,
              color: cor,
              titleColor: cor,
              isRequired: widget.camposObrigatorios,
              validator: (value) => FormValidators.bairro(
                value,
                obrigatorio: widget.camposObrigatorios,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: CustomInputField(
                    label: "Cidade",
                    icon: Icons.location_city_outlined,
                    controller: c.nomeCidadeController,
                    color: cor,
                    titleColor: cor,
                    isRequired: widget.camposObrigatorios,
                    validator: (value) => FormValidators.cidade(
                      value,
                      obrigatorio: widget.camposObrigatorios,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomInputField(
                    label: "UF",
                    hintlabel: "UF",
                    icon: Icons.flag_outlined,
                    controller: c.ufController,
                    color: cor,
                    titleColor: cor,
                    maxLength: 2,
                    isRequired: widget.camposObrigatorios,
                    validator: (value) => FormValidators.uf(
                      value,
                      obrigatorio: widget.camposObrigatorios,
                    ),
                    onChanged: (value) {
                      final uf = value
                          .replaceAll(RegExp(r'[^A-Za-z]'), '')
                          .toUpperCase();
                      final limitado =
                          uf.length > 2 ? uf.substring(0, 2) : uf;
                      if (limitado != value) {
                        c.ufController.value = TextEditingValue(
                          text: limitado,
                          selection: TextSelection.collapsed(
                            offset: limitado.length,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
