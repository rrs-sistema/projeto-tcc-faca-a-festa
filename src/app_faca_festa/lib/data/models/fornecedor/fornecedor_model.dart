import 'package:cloud_firestore/cloud_firestore.dart';

class FornecedorModel {
  final String idFornecedor;
  final String idUsuario;
  final String razaoSocial;
  final String? cnpj;
  final String telefone;
  final String email;
  final String? descricao;
  final bool aptoParaOperar;
  final bool ativo;
  final DateTime dataCadastro;

  final String? bannerUrl;

  /// 🔹 Lista de categorias e subcategorias
  final List<Map<String, dynamic>> categorias;

  /// ⭐ NOVOS CAMPOS DE AVALIAÇÃO
  final double mediaAvaliacoes; // média geral
  final int totalAvaliacoes; // total de avaliações
  final bool isTopCategoria; // selo calculado posteriormente
  final String? fcmToken;

  FornecedorModel({
    required this.idFornecedor,
    required this.idUsuario,
    required this.razaoSocial,
    required this.telefone,
    required this.email,
    this.cnpj,
    this.descricao,
    this.aptoParaOperar = false,
    this.ativo = true,
    DateTime? dataCadastro,
    this.bannerUrl,
    this.categorias = const [],

    /// campos novos
    this.mediaAvaliacoes = 0.0,
    this.totalAvaliacoes = 0,
    this.isTopCategoria = false,
    this.fcmToken,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  // =======================================================
  // 🔹 Conversão para Firestore
  // =======================================================
  Map<String, dynamic> toMap() {
    final categoriasLimpa = categorias.map((c) {
      final map = Map<String, dynamic>.from(c);

      if (map['dataCadastro'] is DateTime) {
        map['dataCadastro'] = Timestamp.fromDate(map['dataCadastro']);
      }

      if (map['dataCadastro'] is FieldValue) {
        map.remove('dataCadastro');
      }

      return map;
    }).toList();

    return {
      'id_fornecedor': idFornecedor,
      'id_usuario': idUsuario,
      'cnpj': cnpj,
      'razao_social': razaoSocial,
      'telefone': telefone,
      'email': email,
      'descricao': descricao,
      'apto_para_operar': aptoParaOperar,
      'ativo': ativo,
      'data_cadastro': Timestamp.fromDate(dataCadastro),
      'banner_url': bannerUrl,
      'categorias': categoriasLimpa,

      // ⭐ Avaliações
      'media_avaliacoes': mediaAvaliacoes,
      'total_avaliacoes': totalAvaliacoes,
      'is_top_categoria': isTopCategoria,
      'fcm_token': fcmToken,
    };
  }

  // =======================================================
  // 🔹 Conversão de Firestore → Model
  // =======================================================
  factory FornecedorModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final data = map['data_cadastro'];
    DateTime parsedDate;

    if (data is Timestamp) {
      parsedDate = data.toDate();
    } else if (data is DateTime) {
      parsedDate = data;
    } else {
      parsedDate = DateTime.now();
    }

    return FornecedorModel(
      idFornecedor: map['id_fornecedor'] ?? documentId ?? '',
      idUsuario: map['id_usuario'] ?? '',
      razaoSocial: map['razao_social'] ?? '',
      telefone: map['telefone'] ?? '',
      email: map['email'] ?? '',
      cnpj: map['cnpj'],
      descricao: map['descricao'],
      aptoParaOperar: map['apto_para_operar'] ?? false,
      ativo: map['ativo'] ?? true,
      dataCadastro: parsedDate,
      bannerUrl: map['banner_url'],
      categorias:
          map['categorias'] != null ? List<Map<String, dynamic>>.from(map['categorias']) : [],

      /// ⭐ campos novos (com fallback)
      mediaAvaliacoes: (map['media_avaliacoes'] as num?)?.toDouble() ?? 0.0,
      totalAvaliacoes: (map['total_avaliacoes'] as num?)?.toInt() ?? 0,
      isTopCategoria: map['is_top_categoria'] ?? false,
    );
  }

  // =======================================================
  // 🔹 Atualização parcial
  // =======================================================
  FornecedorModel copyWith({
    String? razaoSocial,
    String? telefone,
    String? email,
    String? descricao,
    bool? aptoParaOperar,
    bool? ativo,
    String? bannerUrl,
    List<Map<String, dynamic>>? categorias,
    double? mediaAvaliacoes,
    int? totalAvaliacoes,
    bool? isTopCategoria,
    String? fcmToken,
  }) {
    return FornecedorModel(
      idFornecedor: idFornecedor,
      idUsuario: idUsuario,
      razaoSocial: razaoSocial ?? this.razaoSocial,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      descricao: descricao ?? this.descricao,
      aptoParaOperar: aptoParaOperar ?? this.aptoParaOperar,
      ativo: ativo ?? this.ativo,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      categorias: categorias ?? this.categorias,
      mediaAvaliacoes: mediaAvaliacoes ?? this.mediaAvaliacoes,
      totalAvaliacoes: totalAvaliacoes ?? this.totalAvaliacoes,
      isTopCategoria: isTopCategoria ?? this.isTopCategoria,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
