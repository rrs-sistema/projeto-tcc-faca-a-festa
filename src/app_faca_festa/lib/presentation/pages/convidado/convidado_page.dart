import 'package:flutter/material.dart';

import 'components/cardapios_tab.dart';
import 'components/estatisticas_tab.dart';
import 'components/grupos_tab.dart';
import 'components/mesa_tab.dart';

class ConvidadosPage extends StatefulWidget {
  const ConvidadosPage({super.key});

  @override
  State<ConvidadosPage> createState() => _ConvidadosPageState();
}

class _ConvidadosPageState extends State<ConvidadosPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus Convidados',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF8A80), Color(0xFFFF5252)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Mesas'),
            Tab(text: 'Grupos'),
            Tab(text: 'Cardápios'),
            Tab(text: 'Estatísticas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MesasTab(),
          GruposTab(),
          CardapiosTab(),
          EstatisticasTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        onPressed: () {},
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Convidado'),
      ),
    );
  }
}
