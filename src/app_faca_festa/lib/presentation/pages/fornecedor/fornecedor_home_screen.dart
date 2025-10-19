import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/fornecedor_controller.dart';
import './sections/solicitacoes_section.dart';
import './sections/avaliacoes_section.dart';
import './sections/financeiro_section.dart';
import './sections/mensagens_section.dart';
import './sections/servicos_section.dart';
import './sections/insights_section.dart';
import './sections/header_section.dart';
import './sections/resumo_section.dart';
import './sections/perfil_section.dart';

class FornecedorHomeScreen extends StatelessWidget {
  final controller = Get.find<FornecedorController>();

  FornecedorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeaderSection(),
              const SizedBox(height: 20),
              const ResumoSection(),
              const SizedBox(height: 20),
              const SolicitacoesSection(),
              const SizedBox(height: 20),
              const ServicosSection(),
              const SizedBox(height: 20),
              const MensagensSection(),
              const SizedBox(height: 20),
              const AvaliacoesSection(),
              const SizedBox(height: 20),
              const FinanceiroSection(),
              const SizedBox(height: 20),
              const PerfilSection(),
              const SizedBox(height: 20),
              const InsightsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

/*
class FornecedorHomeScreen extends StatelessWidget {
  final FornecedorModel fornecedor;

  const FornecedorHomeScreen({super.key, required this.fornecedor});

  @override
  Widget build(BuildContext context) {
    final appController = Get.find<AppController>();

    // 🔹 Cards com controle de acesso por aprovação
    final cards = [
      _FornecedorCardData(
        title: "Solicitações Pendentes",
        subtitle:
            fornecedor.aptoParaOperar ? "Orçamentos a responder" : "Acesso bloqueado até aprovação",
        icon: Icons.pending_actions_outlined,
        color1: const Color(0xFF81C784),
        color2: const Color(0xFF388E3C),
        ativo: fornecedor.aptoParaOperar,
      ),
      _FornecedorCardData(
        title: "Serviços Cadastrados",
        subtitle:
            fornecedor.aptoParaOperar ? "Gerencie seu portfólio" : "Bloqueado temporariamente",
        icon: Icons.home_repair_service_outlined,
        color1: const Color(0xFFA5D6A7),
        color2: const Color(0xFF43A047),
        ativo: fornecedor.aptoParaOperar,
      ),
      _FornecedorCardData(
        title: "Mensagens / Orçamentos",
        subtitle: "Converse com clientes",
        icon: Icons.chat_bubble_outline,
        color1: const Color(0xFFB2DFDB),
        color2: const Color(0xFF00796B),
        ativo: true, // sempre acessível
      ),
      _FornecedorCardData(
        title: "Avaliações Recebidas",
        subtitle: "Veja seu desempenho",
        icon: Icons.star_border_rounded,
        color1: const Color(0xFFC5E1A5),
        color2: const Color(0xFF558B2F),
        ativo: true, // sempre acessível
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Painel do Fornecedor",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Encerrar sessão',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (_) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🔹 Ícone superior
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Colors.redAccent,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🔹 Título
                        Text(
                          "Encerrar sessão",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 🔹 Mensagem
                        Text(
                          "Deseja realmente sair da sua conta?",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 🔹 Botões
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade400),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  "Cancelar",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context, true),
                                icon: const Icon(Icons.logout_rounded, size: 18),
                                label: Text(
                                  "Sair",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
              if (confirmar == true) await appController.logoutFornecedor();
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      // ==========================================
      // 🔹 Corpo principal
      // ==========================================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🧾 Cabeçalho com status
              if (!fornecedor.aptoParaOperar)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF57C00),
                        const Color(0xFF2E7D32)
                      ] // Verde padrão ativo
                      , // Laranja padrão pendente
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF57C00).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 🔹 Textos principais
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cadastro em análise",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Aguarde a aprovação do administrador para começar a operar.",
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                color: Colors.white.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w800,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 🔹 Status visual
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Color(0xFFF57C00).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Color(0xFFF57C00).withValues(alpha: 0.4), width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.hourglass_bottom_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Pendente",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // 🔹 Grid de cards
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 1,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return _FornecedorCard(
                    data: card,
                    onTap: () {
                      if (!card.ativo) {
                        Get.snackbar(
                          "Acesso bloqueado",
                          "Aguarde aprovação do administrador.",
                          backgroundColor: Colors.orange.shade400,
                          colorText: Colors.white,
                        );
                        return;
                      }
                      Get.snackbar(
                        card.title,
                        "Abrindo ${card.title.toLowerCase()}...",
                        backgroundColor: card.color2.withValues(alpha: 0.85),
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FornecedorCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color1;
  final Color color2;
  final bool ativo;
  _FornecedorCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.ativo,
  });
}

class _FornecedorCard extends StatefulWidget {
  final _FornecedorCardData data;
  final VoidCallback onTap;
  const _FornecedorCard({required this.data, required this.onTap});
  @override
  State<_FornecedorCard> createState() => _FornecedorCardState();
}

class _FornecedorCardState extends State<_FornecedorCard> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTapDown: (_) => setState(() => hovered = true),
      onTapUp: (_) => setState(() => hovered = false),
      onTapCancel: () => setState(() => hovered = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              d.color1,
              d.color2.withValues(alpha: hovered ? 1.0 : 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: d.color2.withValues(alpha: 0.4),
              blurRadius: hovered ? 10 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(d.icon, color: Colors.white, size: 48),
                const SizedBox(height: 10),
                Text(
                  d.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  d.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 14,
              top: 14,
              child: AnimatedOpacity(
                opacity: hovered ? 1 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
