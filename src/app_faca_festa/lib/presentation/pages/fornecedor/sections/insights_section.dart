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
    await tts.setLanguage('pt-BR');
    await tts.setSpeechRate(0.9);
    await tts.setPitch(1.1);
    await tts.setVolume(1.0);
  }

  Future<void> _falar(String texto) async {
    if (!mounted) return;
    setState(() => _falando = true);
    await tts.speak(texto);
    tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() => _falando = false);
    });
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();

    return Obx(() {
      final insights = _gerarInsights(controller);
      final saudacao = _gerarSaudacao(controller.fornecedor.value?.razaoSocial ?? 'Parceiro');
      final mensagemFalada = '${saudacao['titulo']} ${saudacao['mensagem']}';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
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
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.lightbulb_outline_rounded, size: 19, color: Color(0xFF4F46E5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inteligência LIA',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Leitura rápida das métricas para orientar próximas melhorias.',
                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (controller.fornecedor.value?.aptoParaOperar ?? false)
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final avatar = SizedBox(
                    width: compact ? 68 : 80,
                    height: compact ? 68 : 80,
                    child: Lottie.asset(
                      _falando ? 'assets/lottie/lia_talking.json' : 'assets/lottie/lia_idle.json',
                    ),
                  );
                  final text = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        saudacao['titulo']!,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        saudacao['mensagem']!,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6B7280),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          foregroundColor: const Color(0xFF111827),
                        ),
                        onPressed: _falando ? null : () => _falar(mensagemFalada),
                        icon: const Icon(Icons.volume_up_rounded, size: 16),
                        label: Text(
                          _falando ? 'Reproduzindo...' : 'Ouvir resumo',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [avatar, const SizedBox(height: 12), text],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [avatar, const SizedBox(width: 16), Expanded(child: text)],
                  );
                },
              ),
            const Divider(height: 34, color: Color(0xFFEEEEEE)),
            ...insights.map((i) => _InsightCard(insight: i)),
          ],
        ),
      );
    });
  }

  Map<String, String> _gerarSaudacao(String nome) {
    final hora = DateTime.now().hour;
    final cumprimento = hora < 12
        ? 'Bom dia, $nome'
        : hora < 18
            ? 'Boa tarde, $nome'
            : 'Boa noite, $nome';
    return {
      'titulo': cumprimento,
      'mensagem':
          'Separei pontos de atenção com base no atendimento, reputação e completude do catálogo.',
    };
  }

  List<_InsightModel> _gerarInsights(FornecedorController c) {
    final fornecedor = c.fornecedor.value;
    final media = c.avaliacaoMedia.value > 0 ? c.avaliacaoMedia.value : (fornecedor?.mediaAvaliacoes ?? 0.0);
    final respostaHoras = fornecedor?.tempoMedioRespostaHoras ??
        (c.tempoMedioResposta.value > 0 ? c.tempoMedioResposta.value / 60 : null);
    final servicosAtivos = c.servicosFornecedor.where((s) => s.ativo).length;
    final temDescricao = (fornecedor?.descricao ?? '').trim().isNotEmpty;
    final temEventos = fornecedor?.tipoEventoNomes.isNotEmpty ?? false;
    final catalogoScore = ((servicosAtivos > 0 ? 0.45 : 0.0) +
            (temDescricao ? 0.25 : 0.0) +
            (temEventos ? 0.20 : 0.0) +
            ((fornecedor?.bannerUrl ?? '').trim().isNotEmpty ? 0.10 : 0.0))
        .clamp(0.0, 1.0);

    return [
      _InsightModel(
        icone: Icons.flash_on_rounded,
        titulo: 'Agilidade comercial',
        descricao: respostaHoras == null || respostaHoras <= 0
            ? 'Ainda não há histórico suficiente para calcular o tempo médio de resposta.'
            : 'Tempo médio de resposta: ${_formatarResposta(respostaHoras)}.',
        progresso: _scoreResposta(respostaHoras),
        cor: const Color(0xFF16A34A),
        fraseIa:
            'Mantenha respostas curtas, claras e com próximos passos para reduzir dúvidas do organizador.',
      ),
      _InsightModel(
        icone: Icons.star_rate_rounded,
        titulo: 'Reputação no marketplace',
        descricao: media <= 0
            ? 'Ainda não há avaliações suficientes para consolidar a reputação.'
            : 'Avaliação média consolidada: ${media.toStringAsFixed(1)} estrelas.',
        progresso: (media / 5).clamp(0.0, 1.0),
        cor: const Color(0xFF2563EB),
        fraseIa:
            'Avaliações recentes e respostas educadas fortalecem a confiança antes da contratação.',
      ),
      _InsightModel(
        icone: Icons.storefront_outlined,
        titulo: 'Força da vitrine',
        descricao: '$servicosAtivos serviço${servicosAtivos == 1 ? '' : 's'} ativo${servicosAtivos == 1 ? '' : 's'} no catálogo.',
        progresso: catalogoScore,
        cor: const Color(0xFF7C3AED),
        fraseIa:
            'Complete fotos, descrição, categorias e tipos de evento para melhorar sua apresentação ao cliente.',
      ),
    ];
  }

  double _scoreResposta(double? horas) {
    if (horas == null || horas <= 0) return 0.25;
    if (horas <= 1) return 1.0;
    if (horas <= 4) return 0.78;
    if (horas <= 12) return 0.55;
    if (horas <= 24) return 0.35;
    return 0.20;
  }

  String _formatarResposta(double horas) {
    if (horas < 1) return '${(horas * 60).round()} minutos';
    if (horas < 24) return '${horas.toStringAsFixed(horas < 10 ? 1 : 0)} horas';
    return '${(horas / 24).toStringAsFixed(1)} dias';
  }
}

class _InsightCard extends StatelessWidget {
  final _InsightModel insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: insight.cor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(insight.icone, color: insight.cor, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insight.titulo,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                '${(insight.progresso * 100).round()}%',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: insight.cor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight.descricao,
            style: GoogleFonts.poppins(fontSize: 12.8, color: const Color(0xFF4B5563)),
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            percent: insight.progresso.clamp(0.0, 1.0),
            lineHeight: 6,
            barRadius: const Radius.circular(4),
            progressColor: insight.cor,
            backgroundColor: const Color(0xFFF3F4F6),
            padding: EdgeInsets.zero,
            animation: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insight.fraseIa,
                    style: GoogleFonts.poppins(
                      fontSize: 12.2,
                      color: const Color(0xFF4B5563),
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
