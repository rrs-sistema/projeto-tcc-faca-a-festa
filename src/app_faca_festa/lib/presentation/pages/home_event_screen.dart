import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import './usuario/models/user_info_model.dart';
import './components/festa_cards_widget.dart';
import './components/festa_bottom_bar.dart';

class HomeEventScreen extends StatefulWidget {
  final UserInfoModel userInfo;
  final String tipoEvento;

  const HomeEventScreen({
    super.key,
    required this.tipoEvento,
    required this.userInfo,
  });

  @override
  State<HomeEventScreen> createState() => _HomeEventScreenState();
}

class _HomeEventScreenState extends State<HomeEventScreen> {
  final DateTime eventDate = DateTime(2026, 7, 11, 0, 0, 0);
  late Duration timeRemaining;
  int _selectedIndex = 0;
  late final List<String> _images;
  int _currentImageIndex = 0;
  Timer? _timer;

  late Color _temaCor;
  late String _tituloCabecalho;
  late IconData _iconeEvento;

  @override
  void initState() {
    super.initState();
    _images = getImageAssetsForTipo(widget.tipoEvento);

    // 🎨 Define o tema e ícone
    switch (widget.tipoEvento.toLowerCase()) {
      case 'casamento':
        _temaCor = Colors.pinkAccent;
        _iconeEvento = Icons.favorite;
        _tituloCabecalho = "💍 Casamento dos Sonhos";
        break;
      case 'festa infantil':
        _temaCor = Colors.orangeAccent;
        _iconeEvento = Icons.celebration;
        _tituloCabecalho = "🎈 Festa Infantil";
        break;
      case 'chá de bebê':
        _temaCor = Colors.lightBlueAccent;
        _iconeEvento = Icons.baby_changing_station;
        _tituloCabecalho = "🍼 Chá de Bebê";
        break;
      case 'aniversário':
        _temaCor = Colors.purpleAccent;
        _iconeEvento = Icons.cake;
        _tituloCabecalho = "🎂 Aniversário Especial";
        break;
      default:
        _temaCor = Colors.teal;
        _iconeEvento = Icons.star;
        _tituloCabecalho = "🎉 Sua Festa Incrível";
        break;
    }

    _updateTimeRemaining();

    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _images.length;
      });
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

  void _updateTimeRemaining() {
    final now = DateTime.now();
    setState(() => timeRemaining = eventDate.difference(now));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = timeRemaining.inDays;
    final hours = timeRemaining.inHours % 24;
    final minutes = timeRemaining.inMinutes % 60;
    final seconds = timeRemaining.inSeconds % 60;

    final nome = widget.userInfo.nome.split(' ').first;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
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
                          Colors.black.withValues(alpha: 0.5),
                          Colors.black.withValues(alpha: 0.2),
                          Colors.transparent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),

                  // === Ícones no topo ===
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    right: 16,
                    left: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(_iconeEvento, color: Colors.white, size: 28),
                        const Icon(Icons.mail_outline, color: Colors.white, size: 28),
                      ],
                    ),
                  ),

                  // === Saudação principal ===
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mensagemSaudacao(nome),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              const Shadow(
                                color: Colors.black54,
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _tituloCabecalho,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat("dd 'de' MMMM yyyy", 'pt_BR').format(eventDate),
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // === CONTADOR ===
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                color: _temaCor.withValues(alpha: 0.85),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _contador("dias", days),
                    _contador("horas", hours),
                    _contador("min", minutes),
                    _contador("s", seconds),
                  ],
                ),
              ),

              // === LINK / INFORMAÇÕES DO EVENTO ===
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: _temaCor.withValues(alpha: 0.15),
                      child: Icon(_iconeEvento, color: _temaCor, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "🌍 Local do evento",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: _temaCor,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              "www.facafesta.com.br/${widget.tipoEvento.toLowerCase()}",
                              style: GoogleFonts.poppins(
                                color: Colors.blueAccent,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // === CARDS ===
              const FestaCardsWidget(),

              const SizedBox(height: 20),

              // === RODAPÉ / FRASE ===
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: _temaCor.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Text(
                  "✨ Seu ${widget.tipoEvento.toLowerCase()} está sendo preparado com carinho ✨",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: _temaCor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: FestaBottomBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
        ),
      ),
    );
  }

  // === CONTADOR E TEXTO DE SAUDAÇÃO ===

  Widget _contador(String label, int valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Text(
            valor.toString().padLeft(2, '0'),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _mensagemSaudacao(String nome) {
    switch (widget.tipoEvento.toLowerCase()) {
      case 'casamento':
        return "💖 Bem-vindos, ${widget.userInfo.nome} & ${widget.userInfo.nomeParceiro ?? 'seu amor'}!";
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
}
