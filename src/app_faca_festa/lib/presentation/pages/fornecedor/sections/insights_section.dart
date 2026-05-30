import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';

import '../../../../controllers/fornecedor/fornecedor_controller.dart';

class InsightsSection extends StatefulWidget {
  const InsightsSection({super.key});

  @override
  State<InsightsSection> createState() => _InsightsSectionState();
}

class _InsightsSectionState extends State<InsightsSection> {
  final tts = FlutterTts();
  bool _falando = false;

  @override
  void initState() {
    super.initState();
    _configurarTTS();
  }

  Future<void> _configurarTTS() async {
    await tts.setLanguage("pt-BR");
    await tts.setSpeechRate(0.9);
    await tts.setPitch(1.1);
    await tts.setVolume(1.0);
  }

  Future<void> _falar(String texto) async {
    setState(() => _falando = true);
    await tts.speak(texto);
    tts.setCompletionHandler(() {
      setState(() => _falando = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();
    final insights = _gerarInsights(controller);
    final saudacao = _gerarSaudacao(controller.fornecedor.value?.razaoSocial ?? "Parceiro");
    final mensagemFalada = "${saudacao['titulo']} ${saudacao['mensagem']}";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.lightbulb_outline_rounded, size: 20, color: Colors.indigo.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Inteligência LIA",
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (controller.fornecedor.value?.aptoParaOperar ?? false)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Lottie.asset(
                      _falando ? 'assets/lottie/lia_talking.json' : 'assets/lottie/lia_idle.json'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(saudacao['titulo']!,
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade900)),
                      const SizedBox(height: 4),
                      Text(saudacao['mensagem']!,
                          style: GoogleFonts.poppins(
                              color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
                      const SizedBox(height: 12),
                      Wrap(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _falar(mensagemFalada),
                            icon: Icon(Icons.volume_up_rounded,
                                size: 16, color: Colors.grey.shade800),
                            label: Text("Ouvir Relatório Analítico",
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const Divider(height: 40, color: Color(0xFFEEEEEE)),
          ...insights.map((i) => _InsightCard(insight: i)),
        ],
      ),
    );
  }

  Map<String, String> _gerarSaudacao(String nome) {
    final hora = DateTime.now().hour;
    String cumprimento = (hora < 12)
        ? "Bom dia, $nome"
        : (hora < 18)
            ? "Boa tarde, $nome"
            : "Boa noite, $nome";
    return {
      'titulo': cumprimento,
      'mensagem':
          "Analisei suas métricas das últimas semanas e preparei sugestões focadas na maximização da sua performance operacional."
    };
  }

  List<_InsightModel> _gerarInsights(FornecedorController c) {
    return [
      _InsightModel(
        icone: Icons.flash_on_rounded,
        titulo: "Agilidade Comercial",
        descricao: "Tempo médio de resposta atual: menos de ${c.tempoMedioResposta.value} minutos.",
        progresso: 0.95,
        cor: Colors.green.shade700,
        fraseIa:
            "Manter essa velocidade pode aumentar seus fechamentos em até 40% frente aos concorrentes da mesma categoria.",
      ),
      _InsightModel(
        icone: Icons.star_rate_rounded,
        titulo: "Reputação no Marketplace",
        descricao:
            "Sua avaliação média consolidada é de ${c.avaliacaoMedia.value.toStringAsFixed(1)} estrelas.",
        progresso: 0.9,
        cor: Colors.blue.shade700,
        fraseIa:
            "Notas consistentes acima de 4.5 garantem rankeamento preferencial no algoritmo de buscas orgânicas.",
      ),
    ];
  }
}

class _InsightCard extends StatelessWidget {
  final _InsightModel insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(insight.icone, color: insight.cor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(insight.titulo,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade900))),
            ],
          ),
          const SizedBox(height: 6),
          Text(insight.descricao,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            percent: insight.progresso,
            lineHeight: 6,
            barRadius: const Radius.circular(4),
            progressColor: insight.cor,
            backgroundColor: Colors.grey.shade100,
            padding: EdgeInsets.zero,
            animation: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(insight.fraseIa,
                        style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                            height: 1.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightModel {
  final IconData icone;
  final String titulo;
  final String descricao;
  final double progresso;
  final Color cor;
  final String fraseIa;

  _InsightModel(
      {required this.icone,
      required this.titulo,
      required this.descricao,
      required this.progresso,
      required this.cor,
      required this.fraseIa});
}
