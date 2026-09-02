// ignore_for_file: use_build_context_synchronously
import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_cadastro_controller.dart';
import './../usuario/cadastro_evento_bottom_sheet.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import './../../../domain/entities/tipo_evento.dart';
import './../../../role_selector_screen.dart';
import './../login/login_screen.dart';
import './../../widgets/festa_app_bar.dart';

class WelcomeEventScreen extends StatefulWidget {
  const WelcomeEventScreen({super.key});

  @override
  State<WelcomeEventScreen> createState() => _WelcomeEventScreenState();
}

class _WelcomeEventScreenState extends State<WelcomeEventScreen> {
  final themeController = Get.find<EventThemeController>();
  final appController = Get.find<AppController>();
  final eventoController = Get.find<EventoController>();

  final eventoCadastroController = Get.find<EventoCadastroController>();

  List<TipoEvento> _tiposEvento = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarTiposEvento();
  }

  Future<void> _carregarTiposEvento() async {
    try {
      await eventoCadastroController.carregarTiposEvento();
      setState(() {
        _tiposEvento = eventoCadastroController.tiposEvento.toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint("❌ Erro ao carregar tipos de evento: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoClaro,
      child: Scaffold(
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
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 2),
                  Text(
                    "Escolha o tipo de evento",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      color: Colors.pink.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🧩 Grid de Tipos de Evento (carregado do Firebase)
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 34, vertical: 6),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1,
                            ),
                            itemCount: _tiposEvento.length,
                            itemBuilder: (context, index) {
                              final tipo = _tiposEvento[index];
                              return _EventTypeCard(
                                nome: tipo.nome,
                                cor: _getColorFromName(tipo.nome),
                                onTap: () async {
                                  // 🔹 Aplica imediatamente o tema ao selecionar o tipo
                                  EasyLoading.show(status: 'Processando...');
                                  themeController.aplicarTemaPorNome(tipo.nome);

                                  final appController =
                                      Get.find<AppController>();
                                  final usuario = await appController
                                      .prepararUsuarioComEndereco();

                                  if (usuario == null) {
                                    Get.snackbar(
                                      'Sessão expirada',
                                      'Por favor, faça login novamente.',
                                      backgroundColor: Colors.redAccent,
                                      colorText: Colors.white,
                                    );
                                    EasyLoading.dismiss();
                                    Get.offAll(
                                        () => const RoleSelectorScreen());
                                    return;
                                  }

                                  final enderecoUsuario =
                                      appController.enderecoPrincipal.value;
                                  final endCtrl = eventoCadastroController
                                      .enderecoController.value;

                                  if (enderecoUsuario != null) {
                                    endCtrl.logradouroController.text =
                                        enderecoUsuario.logradouro;
                                    endCtrl.numeroController.text =
                                        enderecoUsuario.numero;
                                    endCtrl.complementoController.text =
                                        enderecoUsuario.complemento ?? '';
                                    endCtrl.bairroController.text =
                                        enderecoUsuario.bairro ?? '';
                                    endCtrl.cepController.text =
                                        enderecoUsuario.cep;
                                    endCtrl.nomeCidadeController.text =
                                        enderecoUsuario.nomeCidade ?? '';
                                    endCtrl.ufController.text =
                                        enderecoUsuario.uf ?? 'PR';

                                    // ✅ Atualiza seleção reativa no UF/CidadeController
                                    endCtrl.ufCidadeController.estadoSelecionado
                                        .value = {
                                      'nome': enderecoUsuario.uf ?? 'Paraná',
                                      'uf': enderecoUsuario.uf ?? 'PR',
                                    };
                                    endCtrl.ufCidadeController.cidadeSelecionada
                                        .value = {
                                      'id_cidade': enderecoUsuario.idCidade,
                                      'nome': enderecoUsuario.nomeCidade,
                                      'uf': enderecoUsuario.uf ?? 'PR',
                                    };
                                  }
                                  eventoCadastroController.limpar(
                                      manterEndereco: true);
                                  eventoCadastroController
                                      .tipoEventoSelecionado.value = tipo;
                                  EasyLoading.dismiss();

                                  await showCadastroEventoBottomSheet(context);

                                  final eventoAtual =
                                      eventoController.eventoAtualEntidade;
                                  if (eventoAtual != null &&
                                      Get.currentRoute != '/HomeEventScreen') {
                                    EasyLoading.dismiss();
                                    appController.abrirHomeOrganizador();
                                  }
                                },
                              );
                            },
                          ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 2,
                          width: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.pinkAccent.shade100
                                    .withValues(alpha: 0.8),
                                Colors.purpleAccent.shade100
                                    .withValues(alpha: 0.8),
                                Colors.blueAccent.shade100
                                    .withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),

                        if (appController.usuarioLogado.value != null) ...[
                          if (Navigator.of(context).canPop())
                            GestureDetector(
                              onTap: Get.back,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                    children: [
                                      const TextSpan(
                                          text: "Já tem um evento? "),
                                      TextSpan(
                                        text: "Voltar ao planejamento",
                                        style: GoogleFonts.poppins(
                                          color: Colors.pink.shade700,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                          decorationThickness: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () async {
                                Biblioteca.showConfirmDialog(
                                  context,
                                  title: 'Pergunta!',
                                  message: 'Deseja realmente sair dessa conta?',
                                  confirmLabel: 'Sim',
                                  color: themeController.primaryColor.value,
                                  onConfirm: () async {
                                    await appController.logoutFornecedor();
                                    return true;
                                  },
                                );
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                    children: [
                                      const TextSpan(
                                          text:
                                              "\nJá tem uma conta cadastrada nesse dispositivo\n\n"),
                                      TextSpan(
                                        text: "Sair da conta cadastrada?",
                                        style: GoogleFonts.poppins(
                                          color: Colors.pink.shade700,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                          decorationThickness: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ] else if (!appController.contaIncompleta.value) ...[
                          GestureDetector(
                            onTap: () {
                              Get.to(
                                () => const LoginScreen(),
                                transition: Transition.fadeIn,
                                duration: const Duration(milliseconds: 500),
                              );
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                  children: [
                                    const TextSpan(text: "Já tem uma conta? "),
                                    TextSpan(
                                      text: "Entrar aqui",
                                      style: GoogleFonts.poppins(
                                        color: Colors.pink.shade700,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationThickness: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 🔹 Link para voltar ao início
                          GestureDetector(
                            onTap: () {
                              Get.to(
                                () => const RoleSelectorScreen(),
                                transition: Transition.fadeIn,
                                duration: const Duration(milliseconds: 500),
                              );
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                  children: [
                                    const TextSpan(
                                        text: "Deseja voltar para o início? "),
                                    TextSpan(
                                      text: "Clique aqui",
                                      style: GoogleFonts.poppins(
                                        color: Colors.purple.shade700,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationThickness: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
                        ] else
                          GestureDetector(
                            onTap: () async {
                              // Deve desativar a conta cadastrada
                              Biblioteca.showConfirmDialog(
                                context,
                                title: 'Pergunta!',
                                message: 'Deseja realmente sair dessa conta?',
                                confirmLabel: 'Sim',
                                color: themeController.primaryColor.value,
                                onConfirm: () async {
                                  await appController.logoutFornecedor();
                                  return true;
                                },
                              );
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                  children: [
                                    const TextSpan(
                                        text:
                                            "\nJá tem uma conta cadastrada nesse dispositivo\n\n"),
                                    TextSpan(
                                      text: "Sair da conta cadastrada?",
                                      style: GoogleFonts.poppins(
                                        color: Colors.pink.shade700,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationThickness: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        // 🔹 Assinatura com ícone sutil e opacidade
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFFF80AB),
                                  Color(0xFFCE93D8),
                                  Color(0xFF81D4FA),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds),
                              child: Text(
                                "by Jullia A. Nicolas B. Rivaldo R.",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    // 💼 Evento Corporativo
    if (lower.contains("corporativo") || lower.contains("empresa")) {
      return const Color(0xFF00796B); // Azul Petróleo
    }
    // 🎓 Formatura
    if (lower.contains("formatura") || lower.contains("colação")) {
      return const Color(0xFF7E57C2); // Roxo Elegante
    }
    return Colors.teal; // padrão
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
    final texto =
        nome.replaceAll(RegExp(r'[^\w\sÀ-ú]'), '').trim(); // remove emoji

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
                textAlign: TextAlign.center,
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
