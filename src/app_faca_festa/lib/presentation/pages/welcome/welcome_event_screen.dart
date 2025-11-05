// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/evento_controller.dart';
import '../../../role_selector_screen.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import './../usuario/cadastro_evento_bottom_sheet.dart';
import './../../../controllers/app_controller.dart';
import './../../../data/models/model.dart';
import './../login/login_screen.dart';
import './../home_event_screen.dart';

class WelcomeEventScreen extends StatefulWidget {
  const WelcomeEventScreen({super.key});

  @override
  State<WelcomeEventScreen> createState() => _WelcomeEventScreenState();
}

class _WelcomeEventScreenState extends State<WelcomeEventScreen> {
  final _db = FirebaseFirestore.instance;
  final themeController = Get.find<EventThemeController>();
  final appController = Get.find<AppController>();
  final eventoController = Get.find<EventoController>();

  List<TipoEventoModel> _tiposEvento = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarTiposEvento();
  }

  Future<void> _carregarTiposEvento() async {
    try {
      final snap = await _db.collection('tipo_evento').where('ativo', isEqualTo: true).get();
      setState(() {
        _tiposEvento = snap.docs.map((d) => TipoEventoModel.fromMap(d.data())).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint("❌ Erro ao carregar tipos de evento: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🎉 Fundo de boas-vindas
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_event_001.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🎨 Overlay colorido e suave
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF9C4),
                  Color(0xFFFFC1E3),
                  Color(0xFFB3E5FC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Container(color: Colors.white.withValues(alpha: 0.35)),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  "🎊 Faça a Festa",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.pink.shade800,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.7),
                        offset: const Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Escolha o tipo de evento",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    color: Colors.pink.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),

                // 🧩 Grid de Tipos de Evento (carregado do Firebase)
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 24,
                            crossAxisSpacing: 24,
                            childAspectRatio: 1,
                          ),
                          itemCount: _tiposEvento.length,
                          itemBuilder: (context, index) {
                            final tipo = _tiposEvento[index];
                            return _EventTypeCard(
                              nome: tipo.nome,
                              cor: _getColorFromName(tipo.nome),
                              onTap: () async {
                                debugPrint(
                                    "🎯 [WelcomeEventScreen] Tipo selecionado: ${tipo.nome}");

                                // 🔹 Aplica imediatamente o tema ao selecionar o tipo
                                themeController.aplicarTemaPorNome(tipo.nome);

                                final appController = Get.find<AppController>();
                                final usuario = await appController.prepararUsuarioComEndereco();

                                if (usuario == null) {
                                  Get.snackbar(
                                    'Sessão expirada',
                                    'Por favor, faça login novamente.',
                                    backgroundColor: Colors.redAccent,
                                    colorText: Colors.white,
                                  );
                                  Get.offAll(() => const RoleSelectorScreen());
                                  return;
                                }

                                await showCadastroEventoBottomSheet(context);

                                if (eventoController.eventoAtual.value != null) {
                                  await eventoController.buscarUltimoEvento(
                                      eventoController.eventoAtual.value!.idUsuario);
                                } else {
                                  final novoEvento = EventoModel(
                                    idEvento: DateTime.now().millisecondsSinceEpoch.toString(),
                                    idTipoEvento: tipo.idTipoEvento,
                                    idUsuario: appController.usuarioLogado.value!.idUsuario,
                                    nome:
                                        "Novo ${tipo.nome.replaceAll(RegExp(r'[^\w\sÀ-ú]'), '').trim()}",
                                    data: DateTime.now().add(const Duration(days: 30)),
                                  );

                                  eventoController.eventoAtual.value = novoEvento;

                                  Get.to(
                                    () => HomeEventScreen(),
                                    transition: Transition.fadeIn,
                                    duration: const Duration(milliseconds: 700),
                                  );
                                }
                              },
                            );
                          },
                        ),
                ),

                // ✨ Rodapé
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          Get.to(
                            () => const LoginScreen(),
                            transition: Transition.fadeIn,
                            duration: const Duration(milliseconds: 500),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Já tem uma conta? ",
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: "Entrar aqui",
                                style: GoogleFonts.poppins(
                                  color: Colors.pink.shade800,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          Get.to(
                            () => const RoleSelectorScreen(),
                            transition: Transition.fadeIn,
                            duration: const Duration(milliseconds: 500),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Deseja voltar para o incicio? ",
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: "Clique aqui",
                                style: GoogleFonts.poppins(
                                  color: Colors.pink.shade800,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Text(
                      "por RRS System Technology",
                      style: GoogleFonts.poppins(
                        color: Colors.pink.shade800.withValues(alpha: 0.7),
                        fontSize: 13,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 💡 Extrai cor do nome (usando os mesmos tons que você usava)
  Color _getColorFromName(String nome) {
    final lower = nome.toLowerCase();
    if (lower.contains("casamento")) return Colors.pinkAccent;
    if (lower.contains("infantil")) return Colors.orangeAccent;
    if (lower.contains("bebê")) return Colors.lightBlueAccent;
    if (lower.contains("aniversário")) return Colors.purpleAccent;
    if (lower.contains("fornecedor")) return Colors.greenAccent;
    return Colors.teal;
  }
}

/// 🎀 Card de evento (moderno e animado)
class _EventTypeCard extends StatefulWidget {
  final String nome;
  final Color cor;
  final VoidCallback onTap;

  const _EventTypeCard({
    required this.nome,
    required this.cor,
    required this.onTap,
  });

  @override
  State<_EventTypeCard> createState() => _EventTypeCardState();
}

class _EventTypeCardState extends State<_EventTypeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final nome = widget.nome;
    final emoji = nome.characters.first; // 💍 Casamento → 💍
    final texto = nome.replaceAll(RegExp(r'[^\w\sÀ-ú]'), '').trim(); // remove emoji

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hovered = true),
      onTapCancel: () => setState(() => _hovered = false),
      onTapUp: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.cor.withValues(alpha: 0.9),
              widget.cor.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.cor.withValues(alpha: _hovered ? 0.5 : 0.3),
              blurRadius: _hovered ? 16 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _hovered ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Text(emoji, style: const TextStyle(fontSize: 56)),
              ),
              const SizedBox(height: 10),
              Text(
                texto,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(1, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
