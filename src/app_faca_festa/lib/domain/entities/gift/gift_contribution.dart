import 'package:cloud_firestore/cloud_firestore.dart';

class GiftContribution {
  final String id;
  final String nome;
  final String? uid;
  final double valor;
  final String? mensagem;
  final DateTime data;

  const GiftContribution({
    required this.id,
    required this.nome,
    this.uid,
    required this.valor,
    this.mensagem,
    required this.data,
  });

  // 🔹 CONVERTE PARA MAP (Para salvar no Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'uid': uid,
      'valor': valor,
      'mensagem': mensagem,
      // Usamos Timestamp do Firebase para melhor compatibilidade
      'data': Timestamp.fromDate(data),
      'created_at': FieldValue.serverTimestamp(), // Auditoria no servidor
    };
  }

  // 🔹 CRIA A PARTIR DO MAP (Para ler do Firebase)
  factory GiftContribution.fromMap(Map<String, dynamic> map) {
    return GiftContribution(
      id: map['id'] ?? '',
      nome: map['nome'] ?? 'Anônimo',
      uid: map['uid'],
      valor: (map['valor'] ?? 0).toDouble(),
      mensagem: map['mensagem'],
      data: (map['data'] as Timestamp).toDate(),
    );
  }
}
