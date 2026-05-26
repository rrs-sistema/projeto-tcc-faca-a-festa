import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/evento/calculadora_festa_item_model.dart';
import './../../controllers/convidado/cardapio_controller.dart';
import '../../data/models/evento/calculadora_festa_model.dart';
import './../../controllers/calculadora_festa_controller.dart';
import './../../controllers/evento_controller.dart';

// ============================================================================
// 🔹 Tela da Calculadora Inteligente de Festa
// Mantida neste arquivo para aproveitar a tela/rota já existente do contador.
// O ContadorEventoScreen continua sendo usado como header fixo na Home.
// ============================================================================

class CalculadoraFestaScreen extends StatefulWidget {
  final String? idEvento;
  final String? tipoEvento;
  final int duracaoInicialHoras;
  final bool permitirEstimativaSemEvento;
  final BaseCalculoFesta? baseInicial;
  final int adultosIniciais;
  final int criancasIniciais;
  final int bebesIniciais;

  const CalculadoraFestaScreen({
    super.key,
    this.idEvento,
    this.tipoEvento,
    this.duracaoInicialHoras = 4,
    this.permitirEstimativaSemEvento = false,
    this.baseInicial,
    this.adultosIniciais = 0,
    this.criancasIniciais = 0,
    this.bebesIniciais = 0,
  });

  @override
  State<CalculadoraFestaScreen> createState() => _CalculadoraFestaScreenState();
}

class _CalculadoraFestaScreenState extends State<CalculadoraFestaScreen> {
  late final CalculadoraFestaController calculadoraController;
  late final EventoController eventoController;
  late final CardapioController cardapioController;

  final TextEditingController adultosCtrl = TextEditingController();
  final TextEditingController criancasCtrl = TextEditingController();
  final TextEditingController bebesCtrl = TextEditingController();

  final RxString idCardapioSelecionado = ''.obs;
  Worker? _cardapiosWorker;

  @override
  void initState() {
    super.initState();

    calculadoraController = Get.isRegistered<CalculadoraFestaController>()
        ? Get.find<CalculadoraFestaController>()
        : Get.put(CalculadoraFestaController());

    eventoController = Get.isRegistered<EventoController>()
        ? Get.find<EventoController>()
        : Get.put(EventoController());

    cardapioController = Get.isRegistered<CardapioController>()
        ? Get.find<CardapioController>()
        : Get.put(CardapioController());

    _cardapiosWorker = ever(
      cardapioController.cardapios,
      (_) => _selecionarPrimeiroCardapioDisponivel(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _prepararCalculadora();
    });
  }

  @override
  void dispose() {
    _cardapiosWorker?.dispose();
    adultosCtrl.dispose();
    criancasCtrl.dispose();
    bebesCtrl.dispose();
    super.dispose();
  }

  Future<void> _prepararCalculadora() async {
    final idEventoInformado = widget.idEvento?.trim() ?? '';
    final podeAbrirComoEstimativa = widget.permitirEstimativaSemEvento && idEventoInformado.isEmpty;
    final evento = podeAbrirComoEstimativa ? null : eventoController.eventoAtual.value;
    final idEvento = idEventoInformado.isNotEmpty ? idEventoInformado : evento?.idEvento ?? '';
    final estimativaSemEvento = idEvento.trim().isEmpty && widget.permitirEstimativaSemEvento;

    if (idEvento.isEmpty && !estimativaSemEvento) {
      Get.snackbar(
        'Atenção',
        'Nenhum evento selecionado para calcular as quantidades.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    final tipoEvento = widget.tipoEvento ??
        eventoController.tipoEventoAtual.value?.nome ??
        evento?.nomeEvento ??
        'Evento';

    final baseInicial = widget.baseInicial ??
        (estimativaSemEvento ? BaseCalculoFesta.manual : BaseCalculoFesta.todosConvidados);

    await calculadoraController.prepararCalculadora(
      idEvento: idEvento,
      tipoEvento: tipoEvento,
      base: baseInicial,
      duracaoInicialHoras: widget.duracaoInicialHoras,
      permitirEstimativaSemEvento: widget.permitirEstimativaSemEvento,
      adultosManuais: widget.adultosIniciais,
      criancasManuais: widget.criancasIniciais,
      bebesManuais: widget.bebesIniciais,
    );

    if (calculadoraController.possuiEventoVinculado) {
      await cardapioController.escutarCardapios(idEvento);
    } else {
      cardapioController.cardapios.clear();
      idCardapioSelecionado.value = '';
    }

    _sincronizarCamposManuais();
    _selecionarPrimeiroCardapioDisponivel();
  }

  void _selecionarPrimeiroCardapioDisponivel() {
    final cardapios = cardapioController.cardapios;

    if (cardapios.isEmpty) {
      idCardapioSelecionado.value = '';
      return;
    }

    final selecionadoExiste = cardapios.any(
      (cardapio) => cardapio.idCardapio == idCardapioSelecionado.value,
    );

    if (!selecionadoExiste) {
      idCardapioSelecionado.value = cardapios.first.idCardapio;
    }
  }

  void _sincronizarCamposManuais() {
    adultosCtrl.text = calculadoraController.totalAdultos.value.toString();
    criancasCtrl.text = calculadoraController.totalCriancas.value.toString();
    bebesCtrl.text = calculadoraController.totalBebes.value.toString();
  }

  int _parseInt(String value) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  void _atualizarManual() {
    calculadoraController.atualizarTotaisManuais(
      adultos: _parseInt(adultosCtrl.text),
      criancas: _parseInt(criancasCtrl.text),
      bebes: _parseInt(bebesCtrl.text),
    );
  }

  Future<void> _salvarCalculo() async {
    if (calculadoraController.totalConvidados <= 0) {
      Get.snackbar(
        'Atenção',
        'Informe pelo menos um convidado para salvar o cálculo.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    await calculadoraController.salvarCalculo();
  }

  Future<void> _enviarParaCardapio() async {
    if (calculadoraController.itensCalculados.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Calcule as quantidades antes de enviar para o cardápio.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    final idCardapio = idCardapioSelecionado.value.trim();

    if (idCardapio.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Selecione o cardápio de destino.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    await calculadoraController.enviarResultadoParaCardapio(
      idCardapio: idCardapio,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: Text(
          'Calculadora Inteligente',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        ),
      ),
      body: Obx(() {
        if (calculadoraController.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _prepararCalculadora,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
            children: [
              _buildHero(primary),
              const SizedBox(height: 16),
              if (calculadoraController.modoEstimativaManualSemEvento) ...[
                _buildAvisoEstimativaSemEvento(primary),
                const SizedBox(height: 16),
              ],
              _buildBaseCalculoCard(primary),
              const SizedBox(height: 16),
              _buildTotaisCard(primary),
              const SizedBox(height: 16),
              _buildDuracaoCard(primary),
              const SizedBox(height: 16),
              _buildResultadoCard(primary),
              if (calculadoraController.possuiEventoVinculado) ...[
                const SizedBox(height: 16),
                _buildCardapioCard(primary),
              ],
              const SizedBox(height: 18),
              _buildAcoes(primary),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHero(Color primary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withValues(alpha: 0.92), primary.withValues(alpha: 0.62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Calcule o número de cada item para sua festa',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sugestões baseadas em adultos, crianças, bebês, duração e tipo do evento.',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvisoEstimativaSemEvento(Color primary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Esta é uma estimativa rápida para apoiar o cadastro do evento. '
              'Depois que o evento for salvo, você poderá usar os convidados cadastrados, '
              'salvar o cálculo e enviar as sugestões para o cardápio.',
              style: GoogleFonts.poppins(
                color: const Color(0xFF334155),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseCalculoCard(Color primary) {
    final baseAtual = calculadoraController.baseCalculo.value;
    final possuiEvento = calculadoraController.possuiEventoVinculado;
    final totalCadastrado = calculadoraController.convidados.length;

    return _SectionCard(
      title: 'Como deseja calcular?',
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          _BaseOptionTile(
            icon: Icons.groups_rounded,
            title: 'Usar convidados cadastrados',
            subtitle: possuiEvento
                ? totalCadastrado > 0
                    ? 'Preenche adultos, crianças e bebês usando a lista do evento.'
                    : 'O evento ainda não possui convidados cadastrados.'
                : 'Disponível depois que o evento for salvo.',
            selected: baseAtual != BaseCalculoFesta.manual,
            enabled: possuiEvento,
            primary: primary,
            onTap: () {
              calculadoraController.alterarBaseCalculo(BaseCalculoFesta.todosConvidados);
              _sincronizarCamposManuais();
            },
          ),
          const SizedBox(height: 10),
          _BaseOptionTile(
            icon: Icons.edit_note_rounded,
            title: 'Informar quantidade manualmente',
            subtitle: 'Use para simular uma estimativa antes de cadastrar todos os convidados.',
            selected: baseAtual == BaseCalculoFesta.manual,
            enabled: true,
            primary: primary,
            onTap: () {
              calculadoraController.alterarBaseCalculo(BaseCalculoFesta.manual);
              _sincronizarCamposManuais();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTotaisCard(Color primary) {
    final manual = calculadoraController.baseCalculo.value == BaseCalculoFesta.manual;

    return _SectionCard(
      title: 'Convidados',
      icon: Icons.groups_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${calculadoraController.totalConvidados} no total',
          style: GoogleFonts.poppins(
            color: primary,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: adultosCtrl,
                  label: 'Adultos',
                  icon: Icons.person_rounded,
                  enabled: manual,
                  onChanged: (_) => _atualizarManual(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NumberField(
                  controller: criancasCtrl,
                  label: 'Crianças',
                  icon: Icons.child_care_rounded,
                  enabled: manual,
                  onChanged: (_) => _atualizarManual(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _NumberField(
            controller: bebesCtrl,
            label: 'Bebês',
            icon: Icons.baby_changing_station_rounded,
            enabled: manual,
            onChanged: (_) => _atualizarManual(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  manual
                      ? 'Informe uma quantidade estimada para simular os itens da festa.'
                      : 'Os totais foram preenchidos automaticamente pela lista de convidados.',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDuracaoCard(Color primary) {
    return _SectionCard(
      title: 'Duração da festa',
      icon: Icons.schedule_rounded,
      trailing: Text(
        '${calculadoraController.duracaoHoras.value}h',
        style: GoogleFonts.poppins(
          color: primary,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      child: Slider(
        value: calculadoraController.duracaoHoras.value.toDouble(),
        min: 2,
        max: 8,
        divisions: 6,
        label: '${calculadoraController.duracaoHoras.value}h',
        onChanged: (value) {
          calculadoraController.atualizarDuracao(value.round());
        },
      ),
    );
  }

  Widget _buildResultadoCard(Color primary) {
    final itens = calculadoraController.itensCalculados;

    return _SectionCard(
      title: 'Sugestão inteligente',
      icon: Icons.insights_rounded,
      child: itens.isEmpty
          ? _EmptyMessage(
              icon: Icons.calculate_outlined,
              text: 'Informe convidados para gerar as sugestões.',
            )
          : Column(
              children: itens.map((item) => _ResultadoItemTile(item: item)).toList(),
            ),
    );
  }

  Widget _buildCardapioCard(Color primary) {
    return _SectionCard(
      title: 'Enviar para cardápio',
      icon: Icons.restaurant_menu_rounded,
      child: Obx(() {
        final cardapios = cardapioController.cardapios;

        if (cardapios.isEmpty) {
          return _EmptyMessage(
            icon: Icons.no_meals_outlined,
            text: 'Crie um cardápio antes de enviar os itens calculados.',
          );
        }

        final selectedValue = cardapios.any(
          (cardapio) => cardapio.idCardapio == idCardapioSelecionado.value,
        )
            ? idCardapioSelecionado.value
            : null;

        return DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: InputDecoration(
            labelText: 'Cardápio de destino',
            prefixIcon: const Icon(Icons.restaurant_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: cardapios.map((cardapio) {
            return DropdownMenuItem<String>(
              value: cardapio.idCardapio,
              child: Text(cardapio.titulo),
            );
          }).toList(),
          onChanged: (value) => idCardapioSelecionado.value = value ?? '',
        );
      }),
    );
  }

  Widget _buildAcoes(Color primary) {
    return Obx(() {
      final salvando = calculadoraController.salvando.value;
      final enviando = calculadoraController.enviandoParaCardapio.value;
      final possuiEvento = calculadoraController.possuiEventoVinculado;

      if (!possuiEvento) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(
                  'Voltar ao cadastro do evento',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Para salvar este cálculo ou enviar ao cardápio, primeiro salve o evento.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }

      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: salvando ? null : _salvarCalculo,
              icon: salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                salvando ? 'Salvando...' : 'Salvar cálculo',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.55)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed:
                  enviando || idCardapioSelecionado.value.isEmpty ? null : _enviarParaCardapio,
              icon: enviando
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                    )
                  : const Icon(Icons.playlist_add_check_rounded),
              label: Text(
                enviando ? 'Enviando...' : 'Adicionar ao cardápio',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _BaseOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final Color primary;
  final VoidCallback onTap;

  const _BaseOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? primary : Colors.grey.shade400;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? primary.withValues(alpha: 0.42) : Colors.grey.shade200,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: enabled ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: enabled ? const Color(0xFF111827) : Colors.grey.shade500,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: enabled ? Colors.grey.shade600 : Colors.grey.shade500,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? primary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
      ),
    );
  }
}

class _ResultadoItemTile extends StatelessWidget {
  final CalculadoraFestaItemModel item;

  const _ResultadoItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final Color color = item.adicionadoAoCardapio ? Colors.teal : Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconeItem(item.tipoItem), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nome,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.regraAplicada,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            item.quantidadeFormatada,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconeItem(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'comida':
        return Icons.lunch_dining_rounded;
      case 'bolo':
        return Icons.cake_rounded;
      case 'sobremesa':
        return Icons.icecream_rounded;
      case 'bebida':
        return Icons.local_drink_rounded;
      case 'descartavel':
        return Icons.local_cafe_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }
}

class _EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
