import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TarefasScreen extends StatefulWidget {
  const TarefasScreen({super.key});

  @override
  State<TarefasScreen> createState() => _TarefasScreenState();
}

class _TarefasScreenState extends State<TarefasScreen> {
  final List<_TarefaData> tarefas = [
    _TarefaData(
      titulo: 'Confirmar o DJ',
      descricao: 'Entrar em contato com o fornecedor e fechar contrato.',
      dataPrevista: DateTime(2025, 10, 25),
      concluida: false,
      responsavel: 'Rivaldo Roberto',
      fotoUrl: 'https://i.pravatar.cc/150?img=5',
    ),
    _TarefaData(
      titulo: 'Comprar balões',
      descricao: 'Comprar 200 balões coloridos para a decoração.',
      dataPrevista: DateTime(2025, 10, 20),
      concluida: true,
      responsavel: 'Jullia Acsa',
      fotoUrl: 'https://i.pravatar.cc/150?img=3',
    ),
    _TarefaData(
      titulo: 'Encomendar bolo',
      descricao: 'Ver modelos com a confeiteira e confirmar sabores.',
      dataPrevista: DateTime(2025, 10, 22),
      concluida: false,
      responsavel: 'Brian',
      fotoUrl: 'https://i.pravatar.cc/150?img=8',
    ),
  ];

  double get _progresso {
    final total = tarefas.length;
    final concluidas = tarefas.where((t) => t.concluida).length;
    return total == 0 ? 0 : concluidas / total;
  }

  @override
  Widget build(BuildContext context) {
    final concluidas = tarefas.where((t) => t.concluida).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Minhas Tarefas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00b09b), Color(0xFF96c93d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Nova tarefa',
            icon: const Icon(Icons.add_task_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),

      // 🔹 Corpo
      body: Column(
        children: [
          // Barra de progresso superior
          Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$concluidas de ${tarefas.length} tarefas concluídas',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progresso,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF00b09b), Color(0xFF96c93d)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de tarefas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: tarefas.length,
              itemBuilder: (context, index) {
                return _TarefaCard(
                  data: tarefas[index],
                  onToggle: (checked) {
                    setState(() {
                      tarefas[index] = tarefas[index].copyWith(concluida: checked);
                    });
                  },
                  onDelete: () {
                    setState(() {
                      tarefas.removeAt(index);
                    });
                  },
                  onEdit: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Editar: ${tarefas[index].titulo}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.teal.shade600,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Botão flutuante
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Tarefa'),
        backgroundColor: const Color(0xFF00b09b),
      ),
    );
  }
}

class _TarefaData {
  final String titulo;
  final String descricao;
  final DateTime dataPrevista;
  final bool concluida;
  final String responsavel;
  final String fotoUrl;

  _TarefaData({
    required this.titulo,
    required this.descricao,
    required this.dataPrevista,
    required this.concluida,
    required this.responsavel,
    required this.fotoUrl,
  });

  _TarefaData copyWith({bool? concluida}) {
    return _TarefaData(
      titulo: titulo,
      descricao: descricao,
      dataPrevista: dataPrevista,
      concluida: concluida ?? this.concluida,
      responsavel: responsavel,
      fotoUrl: fotoUrl,
    );
  }
}

class _TarefaCard extends StatefulWidget {
  final _TarefaData data;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TarefaCard({
    required this.data,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_TarefaCard> createState() => _TarefaCardState();
}

class _TarefaCardState extends State<_TarefaCard> {
  late bool concluida;

  @override
  void initState() {
    super.initState();
    concluida = widget.data.concluida;
  }

  @override
  Widget build(BuildContext context) {
    final tarefa = widget.data;
    final dataFormatada = DateFormat('dd/MM/yyyy').format(tarefa.dataPrevista);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: ValueKey(tarefa.titulo),
        closeOnScroll: true,
        startActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.4,
          children: [
            SlidableAction(
              onPressed: (_) => widget.onEdit(),
              backgroundColor: Colors.blue.shade400,
              foregroundColor: Colors.white,
              icon: Icons.edit_note_rounded,
              label: 'Editar',
              borderRadius: BorderRadius.circular(14),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.3,
          children: [
            SlidableAction(
              onPressed: (_) => widget.onDelete(),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: 'Excluir',
              borderRadius: BorderRadius.circular(14),
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: concluida
                  ? [Colors.green.shade50, Colors.green.shade100]
                  : [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: concluida ? Colors.green.shade300 : Colors.grey.shade300,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + status
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(tarefa.fotoUrl),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: concluida ? const Color(0xFF00b09b) : Colors.orangeAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Conteúdo textual
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarefa.titulo,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: concluida ? Colors.green.shade800 : Colors.grey.shade900,
                        decoration: concluida ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tarefa.descricao,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 15, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          dataFormatada,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.person_outline, size: 15, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            tarefa.responsavel,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botão de conclusão
              GestureDetector(
                onTap: () {
                  setState(() => concluida = !concluida);
                  widget.onToggle(concluida);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: concluida
                      ? Icon(Icons.check_circle_rounded,
                          key: const ValueKey(1), color: Colors.green.shade500, size: 30)
                      : Icon(Icons.radio_button_unchecked,
                          key: const ValueKey(0), color: Colors.grey.shade400, size: 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
