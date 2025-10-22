import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../../controllers/evento_cadastro_controller.dart';
import './../../controllers/event_theme_controller.dart';
import './fornecedor/fornecedor_localizacao_screen.dart';
import './../../controllers/evento_controller.dart';
import './../widgets/menu_drawer_faca_festa.dart';
import './../../controllers/app_controller.dart';
import './components/festa_cards_widget.dart';
import './comunidade/comunidade_screen.dart';
import './inspiracao/inspiracao_screen.dart';
import './components/festa_bottom_bar.dart';
import './../../data/models/model.dart';
import './contador_evento.dart';

class HomeEventScreen extends StatefulWidget {
  const HomeEventScreen({
    super.key,
  });

  @override
  State<HomeEventScreen> createState() => _HomeEventScreenState();
}

class _HomeEventScreenState extends State<HomeEventScreen> {
  late Duration timeRemaining;
  late Timer _timer;
  int _selectedIndex = 0;
  int _currentImageIndex = 0;
  late List<String> _images;
  late EventoModel eventoModel;
  late TipoEventoModel tipoEvento;

  final eventoCadastroController = Get.find<EventoCadastroController>();
  final themeController = Get.put(EventThemeController());
  final appController = Get.find<AppController>();
  final eventoController = Get.find<EventoController>();

  @override
  void initState() {
    super.initState();
    eventoModel = eventoController.eventoAtual.value!;
    tipoEvento = eventoCadastroController.tiposEvento
        .where((t) => t.idTipoEvento == eventoModel.idTipoEvento)
        .first;

    // 🔹 Aplica o tema baseado no ID do evento (com cache automático)
    themeController.aplicarTemaPorId(eventoModel.idTipoEvento);

    // 🔹 Continua com sua lógica normal
    _images = getImageAssetsForTipo(eventoModel.nome);
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _images.length;
      });
    });
  }

  void _updateTimeRemaining() {
    setState(() {
      timeRemaining = eventoModel.data.difference(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildOrganizadorPage(),
      const FornecedorLocalizacaoScreen(
        showLeading: false,
      ),
      InspiracaoScreen(tipoEvento: eventoModel.nome),
      ComunidadeScreen(),
      MenuDrawerFacaFesta(onLogout: appController.logoutFornecedor),
    ];
    double opacity = 0.075;
    int alpha = (opacity * 10.05).round();

    return Obx(() => Scaffold(
          backgroundColor: themeController.primaryColor.value.withValues(alpha: alpha.toDouble()),
          body: pages[_selectedIndex],
          bottomNavigationBar: FestaBottomBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
          ),
        ));
  }

  // ===============================
  // === PÁGINA ORGANIZADOR PRINCIPAL ===
  // ===============================
  Widget _buildOrganizadorPage() {
    return Obx(() {
      final cor = themeController.primaryColor.value;
      //final gradiente = themeController.gradient.value;
      //final icone = themeController.icon.value;
      final titulo = themeController.tituloCabecalho.value;

      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // === HEADER ===
              Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1200),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Container(
                      key: ValueKey<int>(_currentImageIndex),
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(_images[_currentImageIndex]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    right: 16,
                    left: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox.shrink(),
                        const Icon(Icons.mail_outline, color: Colors.white, size: 28),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            _mensagemSaudacao(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            titulo,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat("dd 'de' MMMM yyyy", 'pt_BR').format(eventoModel.data),
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // === CONTADOR ===
              ContadorEventoScreen(
                dataEvento: eventoModel.data,
                tipoEvento: eventoModel.nome, // 🔹 envia o tipo para personalizar
              ),
              const SizedBox(height: 20),
              // === LINK / INFORMAÇÕES ===
              GestureDetector(
                onTap: () {
                  // Abre mapa ou detalhes
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: cor.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      color: cor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Local do Evento",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: cor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // 🔹 Endereço
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      (eventoModel.logradouro != null &&
                                              eventoModel.logradouro!.isNotEmpty)
                                          ? eventoModel.logradouro!
                                          : "Defina o local do seu evento para encontrar fornecedores próximos.",
                                      style: GoogleFonts.poppins(
                                        color: (eventoModel.logradouro != null &&
                                                eventoModel.logradouro!.isNotEmpty)
                                            ? Colors.black87
                                            : Colors.grey.shade600,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // 🔹 Botão moderno de ação
                              Center(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.store_mall_directory_rounded, size: 18),
                                    label: Text(
                                      "Ver fornecedores próximos",
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: cor.withValues(alpha: 0.12),
                                      foregroundColor: cor,
                                      elevation: 0,
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => Get.to(() => const FornecedorLocalizacaoScreen(
                                          showLeading: true,
                                        )),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const FestaCardsWidget(),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cor.withValues(alpha: 0.1),
                        cor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _descricaoEvento(
                        eventoModel.nome, appController.usuarioLogado.value!.nome.split(' ').first),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: cor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "✨ Seu ${eventoModel.nome.toLowerCase()} está ganhando vida! ✨",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: cor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Continue acompanhando o progresso e aproveite cada detalhe.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    });
  }

  List<String> getImageAssetsForTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'casamento':
        return [
          'assets/images/wedding_1.jpeg',
          'assets/images/wedding_2.jpeg',
          'assets/images/wedding_3.jpeg',
        ];
      case 'festa infantil':
        return [
          'assets/images/kids_party_1.jpeg',
          'assets/images/kids_party_2.jpeg',
          'assets/images/kids_party_3.jpeg',
        ];
      case 'chá de bebê':
        return [
          'assets/images/baby_shower_1.jpeg',
          'assets/images/baby_shower_2.jpeg',
          'assets/images/baby_shower_3.jpeg',
        ];
      case 'aniversário':
        return [
          'assets/images/birthday_1.jpeg',
          'assets/images/birthday_2.jpeg',
          'assets/images/birthday_3.jpeg',
        ];
      default:
        return [
          'assets/images/event_generic_1.jpeg',
          'assets/images/event_generic_2.jpeg',
          'assets/images/event_generic_3.jpeg',
        ];
    }
  }

  String _mensagemSaudacao() {
    String nome = _normalizeTipoEvento(tipoEvento.nome.toLowerCase());
    final nomeswitch = _normalizeTipoEvento(tipoEvento.nome.toLowerCase());

    switch (nomeswitch) {
      case 'casamento':
        //return "💖 Bem-vindos, ${widget.userInfo.nome} & ${eventoModel.nomeParceiro ?? 'seu amor'}!";
        return "💖 Bem-vindos, ${eventoModel.nomeNoiva} & ${eventoModel.nomeNoivo}!";
      case 'festa infantil':
        return "🎈 Olá, $nome! A diversão está prestes a começar!";
      case 'chá de bebê':
        return "🍼 Que alegria, $nome! O seu grande dia está chegando!";
      case 'aniversário':
        return "🎂 Parabéns, $nome! Vamos celebrar em grande estilo!";
      default:
        return "🎉 Olá, $nome! Seu evento está ganhando vida!";
    }
  }

  String _descricaoEvento(String tipo, String nome) {
    tipo = _normalizeTipoEvento(tipo);
    switch (tipo.toLowerCase()) {
      case 'casamento':
        return "Um momento inesquecível está sendo preparado! 💍 "
            "Cada detalhe do casamento de $nome está sendo organizado com amor e sofisticação.";
      case 'festa infantil':
        return "Diversão garantida para os pequenos! 🎈 "
            "$nome está preparando uma festa cheia de cores, alegria e muita brincadeira.";
      case 'chá de bebê':
        return "🍼 Amor em cada detalhe! O chá de bebê de $nome "
            "está sendo planejado para receber com carinho uma nova vida.";
      case 'aniversário':
        return "🎂 O grande dia de $nome está chegando! "
            "Prepare-se para celebrar cada momento com estilo e alegria.";
      case 'natal':
        return "🎄 Magia e união! O Natal de $nome será repleto de amor, luzes e boas lembranças.";
      case 'ano novo':
        return "🎆 Um novo ciclo se aproxima! Que o Réveillon de $nome traga renovação e boas energias.";
      default:
        return "🎉 Seu evento está tomando forma! Tudo está sendo preparado com dedicação para um dia inesquecível.";
    }
  }

  String _normalizeTipoEvento(String tipo) {
    // Remove emojis e espaços extras
    final cleaned = tipo
        .replaceAll(RegExp(r'[^\w\s]'), '') // remove símbolos e emojis
        .trim()
        .toLowerCase();
    return cleaned;
  }
}
