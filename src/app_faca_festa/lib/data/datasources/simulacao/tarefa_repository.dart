import 'package:intl/intl.dart';

class TarefaRepository {
  static final List<TarefaData> tarefas = [
    TarefaData(
      titulo: 'Confirmar o DJ',
      descricao: 'Entrar em contato com o fornecedor e fechar contrato.',
      dataPrevista: DateTime(2025, 10, 25),
      concluida: false,
      responsavel: 'Rivaldo Roberto',
      fotoUrl: 'https://i.pravatar.cc/150?img=5',
    ),
    TarefaData(
      titulo: 'Comprar balões',
      descricao: 'Comprar 200 balões coloridos para a decoração.',
      dataPrevista: DateTime(2025, 10, 20),
      concluida: true,
      responsavel: 'Jullia Acsa',
      fotoUrl: 'https://i.pravatar.cc/150?img=3',
    ),
    TarefaData(
      titulo: 'Encomendar bolo',
      descricao: 'Ver modelos com a confeiteira e confirmar sabores.',
      dataPrevista: DateTime(2025, 10, 22),
      concluida: false,
      responsavel: 'Brian',
      fotoUrl: 'https://i.pravatar.cc/150?img=8',
    ),
  ];

  static void adicionar(TarefaData tarefa) => tarefas.add(tarefa);
  static void remover(TarefaData tarefa) => tarefas.remove(tarefa);
}

class TarefaData {
  final String titulo;
  final String descricao;
  final DateTime dataPrevista;
  final bool concluida;
  final String responsavel;
  final String fotoUrl;

  TarefaData({
    required this.titulo,
    required this.descricao,
    required this.dataPrevista,
    required this.concluida,
    required this.responsavel,
    required this.fotoUrl,
  });

  TarefaData copyWith({bool? concluida}) {
    return TarefaData(
      titulo: titulo,
      descricao: descricao,
      dataPrevista: dataPrevista,
      concluida: concluida ?? this.concluida,
      responsavel: responsavel,
      fotoUrl: fotoUrl,
    );
  }

  @override
  String toString() => '$titulo - ${DateFormat("dd/MM/yyyy").format(dataPrevista)} ($responsavel)';
}
