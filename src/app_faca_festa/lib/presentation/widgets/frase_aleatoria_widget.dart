import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import './../../../../controllers/tema/event_theme_controller.dart';

class FraseAleatoriaWidget extends StatefulWidget {
  final String tipoEvento;
  const FraseAleatoriaWidget({super.key, required this.tipoEvento});

  @override
  State<FraseAleatoriaWidget> createState() => _FraseAleatoriaWidgetState();
}

class _FraseAleatoriaWidgetState extends State<FraseAleatoriaWidget>
    with SingleTickerProviderStateMixin {
  final random = Random();
  late String fraseAtual;
  bool visivel = true;
  Timer? _timer;

  final themeController = Get.find<EventThemeController>();

  final frasesGerais = [
    "🎉 Cada detalhe é um passo rumo ao seu sonho!",
    "💍 Organizar é transformar amor em celebração.",
    "✨ Tudo pronto para um momento inesquecível?",
    "🎶 Que cada escolha conte uma história linda.",
    "🌸 Grandes memórias nascem de pequenos detalhes.",
    "🥂 A festa começa no planejamento — e o brilho é todo seu!",
    "🌷 Transforme ideias em momentos, e momentos em lembranças eternas.",
    "💫 O segredo da festa perfeita está no carinho de cada escolha.",
    "🌟 Grandes histórias começam com uma boa organização.",
    "💎 O encanto está nos detalhes — e você está cuidando deles com amor.",
    "🌞 Hoje é o dia perfeito para dar mais um passo rumo à sua festa!",
    "🎁 O presente mais bonito é ver o seu sonho tomando forma!",
    "🎀 Alegria é ver o sonho se tornando realidade, um detalhe de cada vez.",
    "📅 Planejar com amor é a melhor forma de celebrar a vida.",
    "💖 Seu evento é único — e merece ser lembrado com carinho.",
  ];

  final frasesCasamento = [
    "💍 Que o amor seja o fio condutor de cada detalhe!",
    "💖 O grande dia começa a brilhar no planejamento!",
    "🌷 Cada flor, cada mesa... tudo traduz o amor de vocês.",
    "💫 O casamento dos sonhos nasce de decisões cheias de carinho.",
    "🎀 Amor em cada cor, em cada laço, em cada instante.",
    "🌸 O encanto está nos pequenos gestos e nos grandes sentimentos.",
    "💐 Planejar o casamento é reviver o primeiro ‘sim’ todos os dias.",
    "🕊️ Que cada escolha conte a história de um amor eterno.",
    "💎 Quando o amor é verdadeiro, o detalhe é só um reflexo da essência.",
    "✨ Celebre o amor que vocês constroem a cada passo juntos.",
    "🌹 A beleza do casamento está em quem o sonha e o realiza.",
    "🎶 Amor, cuidado e alegria — a trilha sonora perfeita do seu grande dia.",
    "🌼 Que o amor seja o tema principal da sua celebração.",
    "💞 Cada detalhe pensado com o coração faz o momento durar para sempre.",
    "🥂 Que o brinde de hoje seja lembrado por toda a vida.",
  ];

  final frasesAniversario = [
    "🎂 Mais um ano, mais histórias pra celebrar!",
    "🎉 Que seu novo ciclo venha repleto de alegrias!",
    "🎈 Planejar o aniversário é reviver sorrisos!",
    "🥳 Cada detalhe é um presente para o coração!",
    "🌟 Hoje o protagonista é você — e o palco é da felicidade!",
    "🎁 Um novo capítulo começa com uma grande comemoração!",
    "💫 Que a vida te abrace em cada sopro de vela.",
    "🌈 Cada balão carrega um desejo de alegria e gratidão.",
    "🎊 Faça da sua festa um reflexo da sua melhor versão!",
    "🌻 O brilho da festa é o mesmo dos seus sonhos.",
    "🎀 Mais que uma data, é um marco de amor e recomeços.",
    "🍰 Cada pedaço de bolo guarda um sorriso compartilhado.",
    "💖 Hoje é o dia perfeito para celebrar quem você é.",
    "🎵 Que o ritmo da sua festa seja o som da felicidade!",
    "🌼 Aniversariar é celebrar a dádiva de existir — e sorrir sem medida.",
  ];

  final frasesChaBebe = [
    "🍼 Amor em cada preparação para a chegada do pequeno milagre.",
    "👶 Cada mimo é um gesto de carinho esperando o bebê!",
    "🌷 O começo de uma nova vida merece uma festa cheia de amor!",
    "💫 Doce espera, lindas memórias!",
    "🧸 Cada presente simboliza o amor em construção.",
    "💖 O amor cresce, e com ele, a alegria de esperar.",
    "🌼 Pequenos detalhes para celebrar um grande milagre!",
    "🩷 A doçura da espera transforma tudo em emoção.",
    "🎀 Cada lacinho é um abraço de boas-vindas.",
    "🧁 Que a doçura do momento dure por toda a infância!",
    "🌸 Amor, ternura e sonhos embrulhados em fraldas e carinho.",
    "💝 Um novo capítulo começa — e ele tem o cheirinho de bebê!",
    "✨ Que a alegria da espera encha o coração de todos!",
    "👣 Pequenos passos, grandes emoções a caminho.",
    "🌈 O amor se multiplica, e a felicidade também!",
  ];

  final frasesCorporativo = [
    "💼 Grandes conquistas começam com grandes conexões.",
    "🚀 Um evento é o reflexo da força e união de uma equipe.",
    "🌟 Sucesso é quando cada detalhe comunica propósito.",
    "🤝 Reunir pessoas certas é o primeiro passo para ideias brilharem.",
    "🎯 Cada encontro é uma oportunidade de crescimento e inovação.",
    "💡 Inspiração nasce quando mentes criativas se encontram.",
    "🌍 Conectar, inspirar e transformar — o verdadeiro espírito corporativo.",
    "🏆 Um bom evento é aquele que deixa marcas de aprendizado e propósito.",
    "📈 Pequenos detalhes constroem grandes resultados.",
    "🗣️ Networking é a arte de transformar encontros em oportunidades.",
    "✨ Cada planejamento reflete o profissionalismo por trás do sucesso.",
    "💬 Comunicação é a ponte entre sonhos e resultados.",
    "🎬 O evento é o palco; a equipe, os protagonistas do sucesso.",
    "🔑 A excelência está nos detalhes que ninguém vê, mas todos sentem.",
    "🕊️ Inspire sua equipe, celebre conquistas, e construa novos horizontes.",
  ];

  final frasesFormatura = [
    "🎓 Um ciclo se encerra, e o futuro começa a brilhar!",
    "🌟 Cada conquista é fruto de sonhos, esforço e fé.",
    "🎉 Hoje é dia de celebrar vitórias e novos começos!",
    "✨ Formar-se é transformar aprendizado em propósito.",
    "📚 Anos de estudo, uma vida inteira de conquistas.",
    "💫 A jornada foi longa, mas o brilho da chegada é eterno.",
    "🏅 Cada aplauso celebra uma história de superação.",
    "🌈 O conhecimento é a chave que abre todas as portas.",
    "🎶 Que a trilha sonora de hoje ecoe por toda a sua vida!",
    "🌻 Orgulho, emoção e gratidão — os ingredientes da formatura perfeita.",
    "🎓 O fim de uma etapa, o início de uma grande aventura.",
    "💖 Que cada lembrança desse dia inspire o amanhã.",
    "🌠 O diploma é só o começo do que você é capaz de conquistar.",
    "📖 Hoje você escreve o capítulo mais bonito da sua história.",
    "🥂 Celebre suas conquistas — o futuro é todo seu!",
  ];

  final frasesNatal = [
    "🎄 Que o espírito natalino ilumine cada detalhe da sua festa!",
    "✨ Natal é tempo de celebrar o amor e espalhar alegria!",
    "🎁 Que cada enfeite conte uma história de carinho e união.",
    "🌟 A magia do Natal começa no seu toque especial!",
    "🎅 O brilho das luzes reflete a esperança que renasce em nós.",
    "❄️ Que o frio lá fora seja aquecido pelo amor aqui dentro.",
    "🕯️ Cada vela acesa é um desejo de paz e harmonia.",
    "🎀 Que o som dos sinos lembre o quanto é bom compartilhar.",
    "🍪 A melhor receita de Natal: amor, família e gratidão.",
    "🧣 Que o aconchego e o riso encham sua casa de alegria!",
    "🌠 É tempo de renovar os sonhos e agradecer pelas bênçãos.",
    "❤️ A melhor decoração de Natal é um coração em paz.",
    "🎶 Que o Natal traga novas melodias de esperança.",
    "🌹 O amor é o verdadeiro presente que nunca perde o valor.",
    "🎇 Que cada luz piscando traga uma lembrança feliz!",
  ];

  List<String> _selecionarFrasesPorTipo() {
    final tipoEvento = widget.tipoEvento.replaceAll(RegExp(r'[^\w\sÀ-ú]'), '').trim().toLowerCase();
    switch (tipoEvento) {
      case 'casamento':
        return frasesCasamento;
      case 'aniversário':
      case 'aniversario':
        return frasesAniversario;
      case 'chá de bebê':
      case 'cha de bebe':
        return frasesChaBebe;
      case 'natal':
        return frasesNatal;
      case 'evento corporativo':
      case 'corporativo':
        return frasesCorporativo;
      case 'formatura':
        return frasesFormatura;
      default:
        return frasesGerais;
    }
  }

  @override
  void initState() {
    super.initState();
    final frases = _selecionarFrasesPorTipo();
    fraseAtual = frases[random.nextInt(frases.length)];

    // ⏱️ Troca automática a cada 7 segundos
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      setState(() {
        final novasFrases = _selecionarFrasesPorTipo();
        fraseAtual = novasFrases[random.nextInt(novasFrases.length)];
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    return AnimatedOpacity(
      duration: const Duration(seconds: 3),
      opacity: visivel ? 1.0 : 0.0,
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          gradient: LinearGradient(
            colors: [
              gradient.colors.first.withValues(alpha: 0.09),
              gradient.colors.last.withValues(alpha: 0.09),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 1700),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            fraseAtual,
            key: ValueKey(fraseAtual),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
