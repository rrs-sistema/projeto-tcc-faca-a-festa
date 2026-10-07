import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/presentation/modules/legal/widgets/aviso_lgpd_card.dart';
import 'package:app_faca_festa/presentation/widgets/custom_input_field.dart';
import './endereco_section_controller.dart';

class EnderecoSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final c = controller;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0E6EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: cor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const AvisoLgpdCard(texto: AvisoLgpdCard.minimizacaoEndereco),
          const SizedBox(height: 10),
          CustomInputField(
            label: 'CEP',
            hintlabel: '00000-000',
            icon: Icons.pin_drop_outlined,
            controller: c.cepController,
            color: cor,
            titleColor: cor,
            keyboardType: TextInputType.number,
            type: InputType.cep,
            isRequired: camposObrigatorios,
            textInputAction: TextInputAction.search,
            onFieldSubmitted: (_) => c.buscarPorCep(forcar: true),
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
            label: 'Logradouro',
            hintlabel: 'Rua, avenida…',
            icon: Icons.home_outlined,
            controller: c.logradouroController,
            color: cor,
            titleColor: cor,
            isRequired: camposObrigatorios,
            validator: (value) => FormValidators.logradouro(
              value,
              obrigatorio: camposObrigatorios,
            ),
          ),
          CustomInputField(
            label: 'Número',
            hintlabel: '123',
            icon: Icons.tag,
            controller: c.numeroController,
            focusNode: c.numeroFocusNode,
            color: cor,
            titleColor: cor,
            keyboardType: TextInputType.text,
            isRequired: camposObrigatorios,
            validator: (value) => FormValidators.numeroEndereco(
              value,
              obrigatorio: camposObrigatorios,
            ),
          ),
          CustomInputField(
            label: 'Complemento',
            hintlabel: 'Apto, bloco…',
            icon: Icons.add_location_alt_outlined,
            controller: c.complementoController,
            color: cor,
            titleColor: cor,
          ),
          CustomInputField(
            label: 'Bairro',
            hintlabel: 'Bairro',
            icon: Icons.map_outlined,
            controller: c.bairroController,
            color: cor,
            titleColor: cor,
            isRequired: camposObrigatorios,
            validator: (value) => FormValidators.bairro(
              value,
              obrigatorio: camposObrigatorios,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomInputField(
                  label: 'Cidade',
                  hintlabel: 'Cidade',
                  icon: Icons.location_city_outlined,
                  controller: c.nomeCidadeController,
                  color: cor,
                  titleColor: cor,
                  isRequired: camposObrigatorios,
                  validator: (value) => FormValidators.cidade(
                    value,
                    obrigatorio: camposObrigatorios,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 88,
                child: CustomInputField(
                  label: 'UF',
                  hintlabel: 'PR',
                  controller: c.ufController,
                  color: cor,
                  titleColor: cor,
                  maxLength: 2,
                  showCounter: false,
                  textAlign: TextAlign.center,
                  isRequired: camposObrigatorios,
                  validator: (value) => FormValidators.uf(
                    value,
                    obrigatorio: camposObrigatorios,
                  ),
                  onChanged: (value) {
                    final uf = value
                        .replaceAll(RegExp(r'[^A-Za-z]'), '')
                        .toUpperCase();
                    final limitado = uf.length > 2 ? uf.substring(0, 2) : uf;
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
    );
  }
}
