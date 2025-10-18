import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/app_controller.dart';
import './../../../../data/models/model.dart';

class AreaConvidadoHomeScreen extends StatefulWidget {
  final UsuarioModel convidado;
  final EventoModel evento;

  const AreaConvidadoHomeScreen({
    super.key,
    required this.convidado,
    required this.evento,
  });

  @override
  State<AreaConvidadoHomeScreen> createState() => _AreaConvidadoHomeScreenState();
}

class _AreaConvidadoHomeScreenState extends State<AreaConvidadoHomeScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  ConvidadoModel? _convidadoModel;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarConvidado();
  }

  /// 🔹 Carrega o convidado a partir do Firestore
  Future<void> _carregarConvidado() async {
    try {
      final snap = await _db
          .collection('eventos')
          .doc(widget.evento.idEvento)
          .collection('convidados')
          .doc(widget.convidado.idUsuario)
          .get();

      if (snap.exists) {
        _convidadoModel = ConvidadoModel.fromMap(snap.data()!);
      } else {
        // Cria registro inicial se ainda não existir
        _convidadoModel = ConvidadoModel(
          idConvidado: widget.convidado.idUsuario,
          idEvento: widget.evento.idEvento,
          nome: widget.convidado.nome,
          email: widget.convidado.email,
          status: 'P',
        );
        await _salvarConvidado(_convidadoModel!);
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar convidado: $e');
    } finally {
      setState(() => _carregando = false);
    }
  }

  /// 🔹 Salva o convidado no Firestore
  Future<void> _salvarConvidado(ConvidadoModel convidado) async {
    await _db
        .collection('eventos')
        .doc(convidado.idEvento)
        .collection('convidados')
        .doc(convidado.idConvidado)
        .set(convidado.toMap(), SetOptions(merge: true));
  }

  /// 🔹 Atualiza status de presença
  Future<void> _atualizarStatus(String novoStatus) async {
    if (_convidadoModel == null) return;

    final atualizado = _convidadoModel!.copyWith(
      status: novoStatus,
      dataResposta: DateTime.now(),
    );

    await _salvarConvidado(atualizado);
    setState(() => _convidadoModel = atualizado);

    String msg = switch (novoStatus) {
      'C' => '🎉 Presença Confirmada! Obrigado por confirmar.',
      'N' => '🙁 Sentiremos sua falta, confirmação registrada.',
      _ => 'Status atualizado.'
    };

    Get.snackbar(
      'Atualizado',
      msg,
      backgroundColor: novoStatus == 'C' ? Colors.green.shade400 : Colors.orange.shade400,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildInformacoesPage(),
      _buildPresentesPage(),
      _buildConfirmacaoPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🎁 Espaço do Convidado',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 3,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFC1E3), Color(0xFFB3E5FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: () => Get.find<AppController>().logout(),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: pages[_selectedIndex],
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFC1E3), Color(0xFFB3E5FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.pink.shade700,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              label: 'Informações',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard),
              label: 'Presentes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_available),
              label: 'Confirmação',
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 🏠 Informações do Evento
  // =====================================================
  Widget _buildInformacoesPage() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('eventos').doc(widget.evento.idEvento).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        return SingleChildScrollView(
          key: const ValueKey('info'),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, size: 80, color: Colors.pinkAccent),
              const SizedBox(height: 20),
              Text(
                data['nome'] ?? 'Evento Especial',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              _infoTile(
                  Icons.calendar_today,
                  'Data',
                  (data['data'] as Timestamp?)?.toDate().toString().split(' ').first ??
                      '--/--/----'),
              _infoTile(Icons.access_time, 'Horário', data['hora'] ?? 'a definir'),
              _infoTile(Icons.location_on, 'Local', data['local'] ?? 'local ainda não informado'),
              _infoTile(Icons.message, 'Mensagem',
                  data['mensagem'] ?? 'Prepare-se para uma celebração inesquecível! 💖'),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // 🎁 Sugestões de Presentes
  // =====================================================
  Widget _buildPresentesPage() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _db.collection('eventos').doc(widget.evento.idEvento).collection('presentes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Ainda não há sugestões de presentes 🎁\nO organizador pode adicionar novas opções em breve!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.black54, fontSize: 15),
              ),
            ),
          );
        }

        return ListView.builder(
          key: const ValueKey('gifts'),
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final item = docs[i].data() as Map<String, dynamic>;
            return _giftCard(
              item['nome'] ?? 'Presente',
              item['loja'] ?? 'Loja não informada',
              item['link'] ?? '',
            );
          },
        );
      },
    );
  }

  // =====================================================
  // ✅ Confirmação de Presença
  // =====================================================
  Widget _buildConfirmacaoPage() {
    final status = _convidadoModel?.status ?? 'P';
    final confirmado = status == 'C';
    final naoVai = status == 'N';

    return Center(
      key: const ValueKey('confirm'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available, size: 80, color: Colors.pinkAccent),
            const SizedBox(height: 20),
            Text(
              confirmado
                  ? '🎉 Presença Confirmada'
                  : naoVai
                      ? '😢 Você não poderá comparecer'
                      : 'Confirme sua presença!',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              confirmado
                  ? 'Aguardamos você com alegria! 💖'
                  : naoVai
                      ? 'Sentiremos sua falta no evento.'
                      : 'Por favor, confirme se você poderá participar.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            if (!confirmado && !naoVai)
              Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmar Presença'),
                    onPressed: () => _atualizarStatus('C'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Não Poderei Ir'),
                    onPressed: () => _atualizarStatus('N'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 🔹 Auxiliares
  // =====================================================
  Widget _infoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.pink.shade400),
      title: Text(title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.pink.shade800)),
      subtitle: Text(value, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
    );
  }

  Widget _giftCard(String nome, String loja, String link) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.card_giftcard, color: Colors.pinkAccent),
        title: Text(nome, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle:
            Text('$loja\n$link', style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54)),
        isThreeLine: true,
      ),
    );
  }
}
