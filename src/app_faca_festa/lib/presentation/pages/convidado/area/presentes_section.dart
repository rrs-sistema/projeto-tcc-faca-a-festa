import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../data/models/model.dart';

class PresentesSection extends StatelessWidget {
  final EventoModel evento;
  final EventThemeController theme;

  const PresentesSection({
    super.key,
    required this.evento,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final primary = theme.primaryColor.value;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('evento')
          .doc(evento.idEvento)
          .collection('presentes')
          .orderBy('nome')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: primary));
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _emptyState(primary);
        }

        // 🔹 Extrair dados da Query
        List<Map<String, dynamic>> presentes = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Guardamos o ID do doc para uso futuro
          return data;
        }).toList();

        // 🔹 Ordenar: Disponíveis no topo, "Já Escolhidos" vão para o final
        presentes.sort((a, b) {
          final resA = _isIndisponivel(a) ? 1 : 0;
          final resB = _isIndisponivel(b) ? 1 : 0;
          return resA.compareTo(resB);
        });

        // 🔹 Renderiza a lista na tela
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), // Espaço pro BottomBar
          itemCount: presentes.length,
          itemBuilder: (context, index) {
            final data = presentes[index];

            return GuestGiftTile(
              item: data,
              primary: primary,
              // 🎯 Ação 1: Abrir Modal PIX inteligente
              onPixTap: () {
                _mostrarPixQrModal(
                  data['nome'] ?? 'Presente',
                  data['valor']?.toString() ?? '',
                  data['pix'] ?? '',
                  primary,
                );
              },
              // 🎯 Ação 2: Contribuir em Cota
              onContributeTap: () {
                _mostrarPixQrModal(
                  data['nome'] ?? 'Cota Coletiva',
                  data['valor']?.toString() ?? '',
                  data['pix'] ?? '',
                  primary,
                );
              },
              // 🎯 Ação 3: Reservar Presente Físico
              onReserveTap: () {
                // TODO: Implementar lógica de update no Firestore para setar reservado_por
                Get.snackbar(
                  'Em breve',
                  'Lógica de confirmação de reserva do presente físico.',
                  backgroundColor: primary.withValues(alpha: 0.8),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(16),
                );
              },
            );
          },
        );
      },
    );
  }

  // Lógica inteligente para saber se o item já foi levado
  bool _isIndisponivel(Map<String, dynamic> data) {
    final reservadoPor = data['reservado_por'];
    final status = data['status'];
    final isColetivo = data['tipo'] == 'coletivo';

    final isReservado =
        (reservadoPor != null && reservadoPor.toString().isNotEmpty) || status == 'reservado';

    final double meta = (data['meta_valor'] ?? 1.0).toDouble();
    final double arrecadado = (data['valor_arrecadado'] ?? 0.0).toDouble();
    final bool metaAlcancada = isColetivo && (arrecadado >= meta);

    return isReservado || metaAlcancada;
  }

  // Estado Vazio
  Widget _emptyState(Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.redeem_rounded, color: primary, size: 56),
            ),
            const SizedBox(height: 16),
            Text(
              'Lista sendo preparada 🎁',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'O organizador vai disponibilizar as opções de presentes em breve!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 💳 MODAL INTELIGENTE DE PIX (Com campo editável)
  // ============================================================
  void _mostrarPixQrModal(String nome, String valorInicial, String chavePix, Color primary) {
    final TextEditingController valorController = TextEditingController(text: valorInicial);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.all(20),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(Icons.pix_rounded, color: primary, size: 40),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Presentear: $nome',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // 🧠 Campo de texto editável para o convidado mudar o valor
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Text('R\$',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: valorController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.poppins(
                                fontSize: 22, fontWeight: FontWeight.bold, color: primary),
                            decoration:
                                const InputDecoration(border: InputBorder.none, hintText: '0,00'),
                          ),
                        ),
                        Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Você pode alterar o valor sugerido se desejar.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primary.withValues(alpha: 0.2)),
                    ),
                    child: QrImageView(
                      data: chavePix,
                      size: 160,
                      backgroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.copy_rounded, color: Colors.white),
                      label: const Text('Copiar Chave PIX'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: chavePix));
                        Get.back(); // Fecha modal
                        Get.snackbar(
                          'Copiado com sucesso!',
                          'A chave PIX foi copiada. É só colar no app do seu banco.',
                          backgroundColor: Colors.green.shade600,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// 🛍️ CARD DO CONVIDADO (VISUAL DA VITRINE CORRIGIDO)
// ============================================================
class GuestGiftTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color primary;
  final VoidCallback onPixTap;
  final VoidCallback onContributeTap;
  final VoidCallback onReserveTap;

  const GuestGiftTile({
    super.key,
    required this.item,
    required this.primary,
    required this.onPixTap,
    required this.onContributeTap,
    required this.onReserveTap,
  });

  @override
  Widget build(BuildContext context) {
    // 🧠 1. Validação Estrita de Tipo (Impede que vire PIX por acidente)
    final tipoStr = item['tipo']?.toString().toLowerCase() ?? 'fisico';
    final isColetivo = tipoStr == 'coletivo';
    final isPix = tipoStr == 'pix';
    final isFisico = tipoStr == 'fisico' || (!isColetivo && !isPix);

    final nome = item['nome'] ?? 'Presente';
    final loja = item['loja'] ?? '';
    final link = item['link'] ?? '';
    final imagem = item['imagem'] ?? '';
    final temFoto = imagem.trim().isNotEmpty;

    print('IMAGEM DO PRODUTO ==> $imagem');

    // 🧠 2. Tratamento e Formatação Rigorosa do Valor (Ex: 0 -> 0,00)
    final rawValor = item['valor']?.toString() ?? '0';
    final double valorNumerico = double.tryParse(rawValor.replaceAll(',', '.')) ?? 0.0;
    final String valorFormatado = valorNumerico.toStringAsFixed(2).replaceAll('.', ',');

    final reservadoPor = item['reservado_por'];
    final bool isReservado = (reservadoPor != null && reservadoPor.toString().isNotEmpty) ||
        item['status'] == 'reservado';

    final double meta = (item['meta_valor'] ?? 1.0).toDouble();
    final double arrecadado = (item['valor_arrecadado'] ?? 0.0).toDouble();
    final bool metaAlcancada = isColetivo && (arrecadado >= meta);

    final bool indisponivel = isReservado || metaAlcancada;

    return Opacity(
      opacity: indisponivel ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exibe imagem se for físico e tiver URL, senão ícone
                  (isFisico && temFoto)
                      ? _buildProductImage(imagem)
                      : _buildIconContainer(isPix, isColetivo),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                            decoration: indisponivel ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildSubtitleRow(tipoStr, link.isNotEmpty, loja),
                      ],
                    ),
                  ),

                  _buildStatusBadge(indisponivel, metaAlcancada),
                ],
              ),

              const SizedBox(height: 16),

              // 🧠 3. Lógica inteligente de exibição de preço
              if (isColetivo)
                _buildProgressSection(meta, arrecadado)
              else if (valorNumerico > 0 || isPix)
                // Exibe valor apenas se for maior que zero ou se for Pix explicitamente
                _buildSimplePrice(valorFormatado),

              const Divider(height: 24),

              _buildGuestAction(indisponivel, isPix, isColetivo, isFisico, link),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String url) {
    // 🧠 Inteligência contra o CORS:
    // Se estiver na Web, usamos um proxy para contornar o bloqueio do navegador.
    // Se for Mobile (Android/iOS), usa a URL direta pois não há CORS.
    String finalUrl = url;
    if (kIsWeb) {
      // Opção 1: corsproxy.io (muito rápido e estável)
      finalUrl = 'https://corsproxy.io/?${Uri.encodeComponent(url)}';

      // Opção 2 (caso a opção 1 falhe algum dia):
      // finalUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.network(
          finalUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Se der erro mesmo com o proxy, exibe o ícone de presente elegantemente
            debugPrint('Erro ao carregar imagem: $error');
            return _buildIconContainer(false, false, isError: true);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: primary.withValues(alpha: 0.5)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIconContainer(bool isPix, bool isColetivo, {bool isError = false}) {
    IconData icon = Icons.card_giftcard_outlined;
    if (isError) {
      icon = Icons.image_not_supported_outlined;
    } else if (isPix) {
      icon = Icons.pix;
    } else if (isColetivo) {
      icon = Icons.groups_outlined;
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: isError ? Colors.grey : primary, size: 28),
    );
  }

  Widget _buildSubtitleRow(String tipo, bool temLink, String loja) {
    final tipoNome = tipo == 'pix' ? 'PIX' : (tipo == 'coletivo' ? 'Cota Coletiva' : 'Físico');
    final texto = loja.isNotEmpty ? loja : tipoNome;

    return Row(
      children: [
        Expanded(
          child: Text(texto,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        if (temLink) ...[
          const SizedBox(width: 6),
          Icon(Icons.link, size: 14, color: primary.withValues(alpha: 0.6)),
        ]
      ],
    );
  }

  Widget _buildStatusBadge(bool indisponivel, bool metaAlcancada) {
    String texto = "Disponível";
    Color cor = Colors.green;

    if (metaAlcancada) {
      texto = "Meta Atingida";
      cor = Colors.purple;
    } else if (indisponivel) {
      texto = "Já Escolhido";
      cor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: cor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(texto, style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProgressSection(double meta, double arrecadado) {
    final percent = meta > 0 ? (arrecadado / meta) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Progresso da Meta", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text("${(percent * 100).toStringAsFixed(0)}%",
                style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[200],
          color: primary,
          minHeight: 8,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(height: 4),
        Text("R\$ ${arrecadado.toStringAsFixed(2)} arrecadados",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSimplePrice(String valorFormatado) {
    return Row(
      children: [
        Text("Valor: ", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text("R\$ $valorFormatado",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildGuestAction(
      bool indisponivel, bool isPix, bool isColetivo, bool isFisico, String link) {
    if (indisponivel) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text("Este presente já foi garantido!",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      );
    }

    String label = "Reservar Presente";
    IconData icon = Icons.shopping_bag_outlined;
    VoidCallback action = onReserveTap;

    if (isPix) {
      label = "Presentear com Pix";
      icon = Icons.pix;
      action = onPixTap;
    } else if (isColetivo) {
      label = "Contribuir com Cota";
      icon = Icons.volunteer_activism;
      action = onContributeTap;
    } else if (isFisico && link.isNotEmpty) {
      label = "Comprar na Loja";
      icon = Icons.open_in_new;
      action = () async {
        if (await canLaunchUrl(Uri.parse(link)))
          await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
      };
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
