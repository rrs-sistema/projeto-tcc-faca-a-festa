class ComentarioReputacao {
  ComentarioReputacao.fromMap(Map<String, dynamic> m)
      : id = m['id'] as String,
        nota = (m['nota'] as num?)?.toInt(),
        comentario = m['comentario'] as String? ?? '',
        data = DateTime.tryParse(m['data']?.toString() ?? ''),
        verificada = m['verificada'] == true,
        servico = m['servico'] as String? ?? 'Fornecedor',
        contexto = m['contexto'] as String? ?? '',
        situacao = m['situacao'] as String? ?? 'publicada',
        resposta = m['resposta'] is Map
            ? Map<String, dynamic>.from(m['resposta'] as Map)
            : null,
        denuncia = m['denuncia'] is Map
            ? Map<String, dynamic>.from(m['denuncia'] as Map)
            : null;
  final String id, comentario, servico, contexto, situacao;
  final int? nota;
  final DateTime? data;
  final bool verificada;
  final Map<String, dynamic>? resposta, denuncia;
}
