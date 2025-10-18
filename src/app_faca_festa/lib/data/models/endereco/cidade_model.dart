import './estado_model.dart';

class CidadeModel {
  final int idCidade;
  final String uf; // FK para estado
  final String nome;
  final EstadoModel? estado;

  const CidadeModel({
    required this.idCidade,
    required this.uf,
    required this.nome,
    this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_cidade': idCidade,
      'uf': uf,
      'nome': nome,
      if (estado != null) 'estado': estado!.toMap(),
    };
  }

  factory CidadeModel.fromMap(Map<String, dynamic> map) {
    return CidadeModel(
      idCidade: map['id_cidade'] is int
          ? map['id_cidade']
          : int.tryParse(map['id_cidade'].toString()) ?? 0,
      uf: map['uf'] ?? '',
      nome: map['nome'] ?? '',
      estado: map['estado'] != null
          ? EstadoModel.fromMap(Map<String, dynamic>.from(map['estado']))
          : null,
    );
  }

  CidadeModel copyWith({
    String? uf,
    String? nome,
    EstadoModel? estado,
  }) {
    return CidadeModel(
      idCidade: idCidade,
      uf: uf ?? this.uf,
      nome: nome ?? this.nome,
      estado: estado ?? this.estado,
    );
  }
}
