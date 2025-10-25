import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../data/models/evento/evento.dart';

class EventThemeController extends GetxController {
  final Rx<Color> primaryColor = const Color(0xFF009688).obs;
  final Rx<LinearGradient> gradient = const LinearGradient(
    colors: [Color(0xFF009688), Color(0xFF80CBC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ).obs;
  final Rx<IconData> icon = Icons.star.obs;
  final RxString tituloCabecalho = "🎉 Sua Festa Incrível".obs;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, String> _cacheTiposEvento = {};

  Future<void> aplicarTemaPorId(String idTipoEvento) async {
    try {
      if (_cacheTiposEvento.containsKey(idTipoEvento)) {
        aplicarTemaPorNome(_cacheTiposEvento[idTipoEvento]!);
        return;
      }

      final doc = await _db.collection('tipo_evento').doc(idTipoEvento).get();
      if (!doc.exists) {
        aplicarTemaPorNome("Padrão");
        return;
      }

      final tipo = TipoEventoModel.fromMap(doc.data()!);
      _cacheTiposEvento[idTipoEvento] = tipo.nome;
      aplicarTemaPorNome(tipo.nome);
    } catch (e) {
      aplicarTemaPorNome("Padrão");
    }
  }

  /// 🔹 Gradientes suaves e coerentes com a WelcomeScreen
  void aplicarTemaPorNome(String nomeTipoEvento) {
    final nome = nomeTipoEvento.replaceAll(RegExp(r'[^\w\sÀ-ú]'), '').trim().toLowerCase();

    switch (nome) {
      case 'casamento':
        primaryColor.value = const Color(0xFFE48BA3); // Rosé suave elegante
        gradient.value = const LinearGradient(
          colors: [
            Color(0xFFE48BA3), // rosé médio elegante
            Color(0xFFFADADD), // rosa claro pêssego
            Color(0xFFE48BA3), // rosé médio elegante
            Color(0xFFB76E79), // rosé gold profundo
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        icon.value = Icons.favorite_rounded;
        break;

      case 'festa infantil':
        primaryColor.value = Colors.orange.shade300;
        gradient.value = const LinearGradient(
          colors: [Color(0xFFFFF9C4), Color(0xFFFFE0B2), Color(0xFFFFCC80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        icon.value = Icons.celebration;
        break;

      case 'chá de bebê':
        primaryColor.value = Colors.lightBlue.shade300;
        gradient.value = const LinearGradient(
          colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA), Color(0xFF4FC3F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        icon.value = Icons.baby_changing_station;
        break;

      case 'aniversário':
        primaryColor.value = Colors.purple.shade300;
        gradient.value = const LinearGradient(
          colors: [Color(0xFFE1BEE7), Color(0xFFD1C4E9), Color(0xFFCE93D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        icon.value = Icons.cake;
        break;

      default:
        primaryColor.value = Colors.teal.shade400;
        gradient.value = const LinearGradient(
          colors: [Color(0xFFC8E6C9), Color(0xFFB2DFDB), Color(0xFF80CBC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        icon.value = Icons.star;
        break;
    }
  }

  void mostrarSeletorDeTema(BuildContext context) {
    final temas = [
      {'nome': 'Casamento', 'icone': Icons.favorite_rounded},
      {'nome': 'Festa Infantil', 'icone': Icons.celebration},
      {'nome': 'Chá de Bebê', 'icone': Icons.baby_changing_station},
      {'nome': 'Aniversário', 'icone': Icons.cake},
      {'nome': 'Padrão', 'icone': Icons.star},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "🎨 Escolha o Tema",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...temas.map((tema) {
                return ListTile(
                  leading: Icon(tema['icone'] as IconData, color: primaryColor.value),
                  title: Text(
                    tema['nome'] as String,
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  onTap: () {
                    aplicarTemaPorNome((tema['nome'] as String).toLowerCase());
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 55),
            ],
          ),
        );
      },
    );
  }

  void aplicarTemaPorFirestore(String nomeTipoEvento) {
    final emoji = nomeTipoEvento.isNotEmpty ? nomeTipoEvento.characters.first : "";
    switch (emoji) {
      case '👶':
        _setTheme(const Color(0xFFFFC1CC), const Color(0xFFFFE6E6), Icons.child_friendly_rounded);
        break;
      case '🎉':
        _setTheme(const Color(0xFFFF9800), const Color(0xFFFFE0B2), Icons.cake_rounded);
        break;
      case '🎈':
        _setTheme(const Color(0xFF8E24AA), const Color(0xFFE1BEE7), Icons.toys_rounded);
        break;
      case '💍':
        _setTheme(const Color(0xFFB388FF), const Color(0xFFF3E5F5), Icons.favorite_rounded);
        break;
      default:
        _setTheme(Colors.blueAccent, Colors.white, Icons.event);
    }
  }

  void _setTheme(Color primary, Color bg, IconData icone) {
    primaryColor.value = primary;
    primaryColor.value = bg;
    gradient.value = LinearGradient(
      colors: [bg.withOpacity(0.9), Colors.white],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    icon.value = icone;
  }
}
