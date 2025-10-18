// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/model.dart';
import './../../../controllers/event_theme_controller.dart';
import './../../../controllers/app_controller.dart';

class ComunidadeScreen extends StatefulWidget {
  const ComunidadeScreen({super.key});

  @override
  State<ComunidadeScreen> createState() => _ComunidadeScreenState();
}

class _ComunidadeScreenState extends State<ComunidadeScreen> {
  final themeController = Get.find<EventThemeController>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _postController = TextEditingController();
  final appController = Get.find<AppController>();

  final RxBool loading = false.obs;

  @override
  Widget build(BuildContext context) {
    final usuarioLogado = appController.usuarioLogado.value;
    final gradiente = themeController.gradient.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Comunidade',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: gradiente),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('posts').orderBy('data', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              return _buildPostCard(posts[index].id, post, usuarioLogado!);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        onPressed: _mostrarDialogNovoPost,
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildPostCard(String id, Map<String, dynamic> post, UsuarioModel usuarioLogado) {
    final comentarios = _db
        .collection('posts')
        .doc(id)
        .collection('comentarios')
        .orderBy('data', descending: true)
        .snapshots();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.pinkAccent,
                    child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 8),
                Text(post['autor'] ?? 'Usuário Anônimo',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            if (post['imagem'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(post['imagem'],
                    height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
            Text(post['texto'] ?? '',
                style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: comentarios,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text('Nenhum comentário ainda.',
                      style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13));
                }
                final docs = snapshot.data!.docs;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: docs.map((c) {
                    final data = c.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.pinkAccent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${data['autor']}: ${data['texto']}',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Adicionar comentário...',
                hintStyle: GoogleFonts.poppins(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onSubmitted: (valor) async {
                if (valor.trim().isEmpty) return;
                await _db.collection('posts').doc(id).collection('comentarios').add({
                  'autor': usuarioLogado.nome, // substituir pelo nome logado
                  'texto': valor.trim(),
                  'data': Timestamp.now(),
                });
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Nenhum post ainda. Seja o primeiro a compartilhar uma ideia! 💡',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogNovoPost() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Novo Post', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _postController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Compartilhe uma dica, inspiração ou dúvida...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final texto = _postController.text.trim();
                if (texto.isNotEmpty) {
                  await _db.collection('posts').add({
                    'autor': 'Usuário Atual', // Substituir por usuário logado
                    'texto': texto,
                    'data': Timestamp.now(),
                    'imagem': null,
                  });
                  _postController.clear();
                  Navigator.pop(context);
                }
              },
              child: Text('Publicar', style: GoogleFonts.poppins(color: Colors.white)),
            )
          ],
        );
      },
    );
  }
}
