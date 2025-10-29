import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';

import './../../../../controllers/fornecedor_controller.dart';

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

    final saudacao = _gerarSaudacao(controller.fornecedor.value!.razaoSocial);

    // Mensagem inicial da LIA
    final mensagemFalada = "${saudacao['titulo']} ${saudacao['mensagem']}";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Avatar da LIA ===
          if (controller.fornecedor.value?.aptoParaOperar ?? false)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Lottie.asset(
                    _falando ? 'assets/lottie/lia_talking.json' : 'assets/lottie/lia_idle.json',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(saudacao['titulo']!,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 6),
                      Text(
                        saudacao['mensagem']!,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade700,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _falar(mensagemFalada),
                        icon: const Icon(Icons.volume_up_rounded, size: 18),
                        label: const Text("Ouvir a LIA"),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          const SizedBox(height: 22),

          // === Insights Inteligentes ===
          Text(
            "💡 Dicas da LIA",
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          ...insights.map((i) => _InsightCard(insight: i)),
        ],
      ),
    );
  }

  Map<String, String> _gerarSaudacao(String nome) {
    final hora = DateTime.now().hour;
    String cumprimento;
    if (hora < 12) {
      cumprimento = "Bom dia, $nome! ☀️";
    } else if (hora < 18) {
      cumprimento = "Boa tarde, $nome! 🌤️";
    } else {
      cumprimento = "Boa noite, $nome! 🌙";
    }
    return {
      'titulo': cumprimento,
      'mensagem':
          "Eu analisei suas métricas e preparei sugestões personalizadas para o seu sucesso. 🎯"
    };
  }

  List<_InsightModel> _gerarInsights(FornecedorController c) {
    return [
      _InsightModel(
        icone: Icons.flash_on_rounded,
        titulo: "Agilidade impressionante ⚡",
        descricao: "Você responde orçamentos em menos de ${c.tempoMedioResposta.value} minutos!",
        progresso: 0.95,
        cor: Colors.green.shade700,
        fraseIa: "LIA diz: sua rapidez aumenta em até 40% suas chances de fechar novos contratos!",
      ),
      _InsightModel(
        icone: Icons.star_rate_rounded,
        titulo: "Reputação excelente 🌟",
        descricao: "Sua média é ${c.avaliacaoMedia.value.toStringAsFixed(1)}⭐ — impressionante!",
        progresso: 0.9,
        cor: Colors.teal.shade700,
        fraseIa: "LIA diz: continue pedindo avaliações, você está entre os melhores do app. 💚",
      ),
      _InsightModel(
        icone: Icons.photo_camera_rounded,
        titulo: "Mais imagens, mais clientes 📸",
        descricao:
            "Você tem ${c.totalFotos.value} fotos publicadas. Perfis com 5+ fotos têm o dobro de visualizações.",
        progresso: 0.6,
        cor: Colors.blue.shade700,
        fraseIa:
            "LIA diz: adicione fotos dos bastidores, elas criam conexão emocional com os organizadores. 💡",
      ),
    ];
  }
}

class _InsightCard extends StatelessWidget {
  final _InsightModel insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insight.cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: insight.cor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(insight.icone, color: insight.cor, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(insight.titulo,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 15.5, color: insight.cor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(insight.descricao,
              style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.grey.shade700, height: 1.4)),
          const SizedBox(height: 10),
          LinearPercentIndicator(
            percent: insight.progresso,
            lineHeight: 6,
            barRadius: const Radius.circular(10),
            progressColor: insight.cor,
            backgroundColor: Colors.grey.shade200,
            animation: true,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: insight.cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_alt_rounded, size: 18, color: Colors.black54),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    insight.fraseIa,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
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

  _InsightModel({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.progresso,
    required this.cor,
    required this.fraseIa,
  });
}
