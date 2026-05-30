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

        // Extrair dados da Query
        List<Map<String, dynamic>> presentes = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

        // Ordenar: Disponíveis no topo, "Já Escolhidos" vão para o final
        presentes.sort((a, b) {
          final resA = _isIndisponivel(a) ? 1 : 0;
          final resB = _isIndisponivel(b) ? 1 : 0;
          return resA.compareTo(resB);
        });

        // Renderiza a lista na tela de forma mais compacta
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 100), // Paddings menores
          itemCount: presentes.length,
          itemBuilder: (context, index) {
            final data = presentes[index];

            return GuestGiftTile(
              item: data,
              primary: primary,
              onPixTap: () {
                _mostrarPixQrModal(
                  data['nome'] ?? 'Presente',
                  data['valor']?.toString() ?? '',
                  data['pix'] ?? '',
                  primary,
                );
              },
              onContributeTap: () {
                _mostrarPixQrModal(
                  data['nome'] ?? 'Cota Coletiva',
                  data['valor']?.toString() ?? '',
                  data['pix'] ?? '',
                  primary,
                );
              },
              onReserveTap: () {
                Get.snackbar(
                  'Em breve',
                  'Lógica de confirmação de reserva do presente físico.',
                  backgroundColor: primary.withValues(alpha: 0.8),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(12), // Compacto
                );
              },
            );
          },
        );
      },
    );
  }

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

  Widget _emptyState(Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.redeem_rounded, color: primary, size: 40),
            ),
            const SizedBox(height: 12),
            Text(
              'Lista sendo preparada 🎁',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              'O organizador vai disponibilizar as opções de presentes em breve!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarPixQrModal(String nome, String valorInicial, String chavePix, Color primary) {
    final TextEditingController valorController = TextEditingController(text: valorInicial);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(16), // Menos margem no modal
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(Icons.pix_rounded, color: primary, size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Presentear: $nome',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), // Mais fino
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Text('R\$',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: valorController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.bold, color: primary),
                            decoration:
                                const InputDecoration(border: InputBorder.none, hintText: '0,00'),
                          ),
                        ),
                        Icon(Icons.edit, size: 14, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Você pode alterar o valor sugerido se desejar.',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primary.withValues(alpha: 0.2)),
                    ),
                    child: QrImageView(
                      data: chavePix,
                      size: 140, // QR um pouco menor
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44, // Botão alinhado e compacto
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                      label: const Text('Copiar Chave PIX'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: chavePix));
                        Get.back();
                        Get.snackbar(
                          'Copiado com sucesso!',
                          'A chave PIX foi copiada. É só colar no app do seu banco.',
                          backgroundColor: Colors.green.shade600,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(12),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
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
    final tipoStr = item['tipo']?.toString().toLowerCase() ?? 'fisico';
    final isColetivo = tipoStr == 'coletivo';
    final isPix = tipoStr == 'pix';
    final isFisico = tipoStr == 'fisico' || (!isColetivo && !isPix);

    final nome = item['nome'] ?? 'Presente';
    final loja = item['loja'] ?? '';
    final link = item['link'] ?? '';
    final imagem = item['imagem'] ?? '';
    final temFoto = imagem.trim().isNotEmpty;

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
        margin: const EdgeInsets.only(bottom: 10), // Margem inferior reduzida
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // Borda ligeiramente mais suave
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Padding do card mais justinho
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (isFisico && temFoto)
                      ? _buildProductImage(imagem)
                      : _buildIconContainer(isPix, isColetivo),

                  const SizedBox(width: 10), // Espaçamento menor

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Fonte do título reduzida
                            color: Colors.black87,
                            decoration: indisponivel ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        _buildSubtitleRow(tipoStr, link.isNotEmpty, loja),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildStatusBadge(indisponivel, metaAlcancada),
                ],
              ),

              const SizedBox(height: 12), // Margem centralizada menor

              if (isColetivo)
                _buildProgressSection(meta, arrecadado)
              else if (valorNumerico > 0 || isPix)
                _buildSimplePrice(valorFormatado),

              const Divider(height: 16), // Divisor menor

              _buildGuestAction(indisponivel, isPix, isColetivo, isFisico, link),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String url) {
    String finalUrl = url;
    if (kIsWeb) {
      finalUrl = 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
    }

    return Container(
      width: 50, // Imagem mais compacta
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.network(
          finalUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildIconContainer(false, false, isError: true);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: 16,
                height: 16,
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
      width: 50, // Ícone alinhado ao tamanho da imagem compacta
      height: 50,
      decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: isError ? Colors.grey : primary, size: 24),
    );
  }

  Widget _buildSubtitleRow(String tipo, bool temLink, String loja) {
    final tipoNome = tipo == 'pix' ? 'PIX' : (tipo == 'coletivo' ? 'Cota Coletiva' : 'Físico');
    final texto = loja.isNotEmpty ? loja : tipoNome;

    return Row(
      children: [
        Expanded(
          child: Text(texto,
              style: TextStyle(color: Colors.grey[600], fontSize: 11), // Fonte reduzida
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        if (temLink) ...[
          const SizedBox(width: 4),
          Icon(Icons.link, size: 12, color: primary.withValues(alpha: 0.6)),
        ]
      ],
    );
  }

  Widget _buildStatusBadge(bool indisponivel, bool metaAlcancada) {
    String texto = "Disponível";
    Color cor = Colors.green;

    if (metaAlcancada) {
      texto = "Atingida";
      cor = Colors.purple;
    } else if (indisponivel) {
      texto = "Escolhido";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // Badge reduzida
      decoration:
          BoxDecoration(color: cor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(texto, style: TextStyle(color: cor, fontSize: 9, fontWeight: FontWeight.bold)),
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
            Text("Progresso da Meta", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            Text("${(percent * 100).toStringAsFixed(0)}%",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: primary)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[200],
          color: primary,
          minHeight: 6, // Barra mais fina
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(height: 4),
        Text("R\$ ${arrecadado.toStringAsFixed(2)} arrecadados",
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSimplePrice(String valorFormatado) {
    return Row(
      children: [
        Text("Valor: ", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text("R\$ $valorFormatado",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // Preço reduzido
      ],
    );
  }

  Widget _buildGuestAction(
      bool indisponivel, bool isPix, bool isColetivo, bool isFisico, String link) {
    if (indisponivel) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Text("Este presente já foi garantido!",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
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
        if (await canLaunchUrl(Uri.parse(link))) {
          await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
        }
      };
    }

    return SizedBox(
      width: double.infinity,
      height: 40, // Botão ligeiramente mais baixo
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(label),
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 1,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Borda menor
          textStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
