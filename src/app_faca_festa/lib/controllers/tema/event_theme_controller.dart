import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/evento/evento.dart';

class EventThemeController extends GetxController {
  EventThemeController() {
    debugPrint("🎯 [ThemeController] Instância única ativa.");
  }

  /// 🎨 Cores principais do tema
  final Rx<Color> primaryColor = const Color(0xFF009688).obs;
  final Rx<Color> secondaryColor = const Color(0xFFE0F2F1).obs;
  final Rx<LinearGradient> gradient = const LinearGradient(
    colors: [Color(0xFF009688), Color(0xFF4DB6AC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ).obs;

  /// 🌟 Ícone e título dinâmicos
  final Rx<IconData> icon = Icons.star.obs;
  final RxString tituloCabecalho = "🎉 Sua Festa Incrível".obs;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, String> _cacheTiposEvento = {};

  // ======================================================
  // 🔹 1. Tema baseado no ID do tipo_evento (Firestore)
  // ======================================================
  Future<void> aplicarTemaPorId(String idTipoEvento) async {
    try {
      debugPrint("🎨 [Theme] Aplicando tema por ID: $idTipoEvento");

      if (_cacheTiposEvento.containsKey(idTipoEvento)) {
        final nome = _cacheTiposEvento[idTipoEvento]!;
        debugPrint("✅ [Theme] Cache encontrado: $nome");
        aplicarTemaPorNome(nome);
        return;
      }

      final doc = await _db.collection('tipo_evento').doc(idTipoEvento).get();
      if (!doc.exists) {
        debugPrint("⚠️ [Theme] Documento não encontrado. Aplicando tema padrão.");
        aplicarTemaPorNome("Padrão");
        return;
      }

      final tipo = TipoEventoModel.fromMap(doc.data()!);
      _cacheTiposEvento[idTipoEvento] = tipo.nome;

      debugPrint("📘 [Theme] Tipo carregado do Firestore: ${tipo.nome}");
      aplicarTemaPorNome(tipo.nome);
    } catch (e, s) {
      debugPrint("❌ [Theme] Erro ao aplicar tema por ID: $e\n$s");
      aplicarTemaPorNome("Padrão");
    }
  }

  // ======================================================
  // 🔹 2. Tema baseado no nome (usado em todo o app)
  // ======================================================
  void aplicarTemaPorNome(String nomeTipoEvento) {
    final nome = nomeTipoEvento.replaceAll(RegExp(r'[^\w\sÀ-ú]'), '').trim().toLowerCase();

    debugPrint("🎯 [Theme] Aplicando tema por nome: '$nomeTipoEvento' → normalizado: '$nome'");

    switch (nome) {
      case 'casamento':
        _setTheme(
          primary: const Color(0xFFE91E63),
          secondary: const Color(0xFFFCE4EC),
          gradient: const LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFFF06292)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icone: Icons.favorite_rounded,
          titulo: "💍 Casamento dos Sonhos",
        );
        break;

      case 'festa infantil':
        _setTheme(
          primary: const Color(0xFFFF9800),
          secondary: const Color(0xFFFFF3E0),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icone: Icons.celebration_rounded,
          titulo: "🎈 Festa Infantil",
        );
        break;

      case 'chá de bebê':
        _setTheme(
          primary: const Color(0xFF03A9F4),
          secondary: const Color(0xFFE1F5FE),
          gradient: const LinearGradient(
            colors: [Color(0xFF03A9F4), Color(0xFF81D4FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icone: Icons.baby_changing_station,
          titulo: "🍼 Chá de Bebê",
        );
        break;

      case 'aniversário':
        _setTheme(
          primary: const Color(0xFF9C27B0),
          secondary: const Color(0xFFF3E5F5),
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icone: Icons.cake_rounded,
          titulo: "🎂 Aniversário Especial",
        );
        break;

      // 💼 Evento Corporativo
      case 'evento corporativo':
      case 'corporativo':
        _setTheme(
          primary: const Color(0xFF00796B),
          secondary: const Color(0xFFE0F2F1),
          gradient: const LinearGradient(
            colors: [Color(0xFF00796B), Color(0xFF48A999)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icone: Icons.business_center_rounded,
          titulo: "💼 Evento Corporativo",
        );
        break;

      // 🎓 Formatura
      case 'formatura':
        _setTheme(
          primary: const Color(0xFF7E57C2),
          secondary: const Color(0xFFEDE7F6),
          gradient: const LinearGradient(
            colors: [Color(0xFF7E57C2), Color(0xFFB39DDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icone: Icons.school_rounded,
          titulo: "🎓 Formatura dos Sonhos",
        );
        break;

      default:
        _setTheme(
          primary: const Color(0xFF009688),
          secondary: const Color(0xFFE0F2F1),
          gradient: const LinearGradient(
            colors: [Color(0xFF009688), Color(0xFF4DB6AC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icone: Icons.star_rounded,
          titulo: "🎉 Faça a Festa",
        );
    }
  }

  // ======================================================
  // 🔹 3. Atualiza tema completo (centralizado)
  // ======================================================
  void _setTheme({
    required Color primary,
    required Color secondary,
    required LinearGradient gradient,
    required IconData icone,
    required String titulo,
  }) {
    primaryColor.value = primary;
    secondaryColor.value = secondary;
    this.gradient.value = gradient;
    icon.value = icone;
    tituloCabecalho.value = titulo;

    // 📋 LOG: resumo visual do tema aplicado
    debugPrint(
      '''
--------------------------------------------------------
🌈 [Theme] Tema aplicado com sucesso:
• Título: $titulo
• Cor principal: ${_colorToHex(primary)}
• Cor secundária: ${_colorToHex(secondary)}
• Ícone: $icone
--------------------------------------------------------
''',
    );
  }

  // ======================================================
  // 🔹 4. Seletor manual de tema (UI)
  // ======================================================
  void mostrarSeletorDeTema(BuildContext context) {
    final temas = [
      {'nome': 'Casamento', 'icone': Icons.favorite_rounded},
      {'nome': 'Festa Infantil', 'icone': Icons.celebration_rounded},
      {'nome': 'Chá de Bebê', 'icone': Icons.baby_changing_station},
      {'nome': 'Aniversário', 'icone': Icons.cake_rounded},
      {'nome': 'Padrão', 'icone': Icons.star_rounded},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  leading: Icon(
                    tema['icone'] as IconData,
                    color: primaryColor.value,
                  ),
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

  // ======================================================
  // 🔹 5. Utilitário: converter cor para string legível
  // ======================================================
  String _colorToHex(Color color) {
    final a = color.a.toInt().toRadixString(16).padLeft(2, '0').toUpperCase();
    final r = color.r.toInt().toRadixString(16).padLeft(2, '0').toUpperCase();
    final g = color.g.toInt().toRadixString(16).padLeft(2, '0').toUpperCase();
    final b = color.b.toInt().toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#$a$r$g$b';
  }
}
