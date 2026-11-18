/// Demanda agregada (sem dados pessoais) para radar do fornecedor.
class DemandaLatenteBucket {
  const DemandaLatenteBucket({
    required this.tipoNome,
    required this.cidade,
    required this.quantidade,
    required this.semCotacao,
    required this.proximos90Dias,
    required this.convidadosMedios,
  });

  final String tipoNome;
  final String cidade;
  final int quantidade;
  final int semCotacao;
  final int proximos90Dias;
  final int convidadosMedios;

  factory DemandaLatenteBucket.fromMap(Map<String, dynamic> map) {
    return DemandaLatenteBucket(
      tipoNome: (map['tipoNome'] ?? map['tipo_nome'] ?? 'Evento').toString(),
      cidade: (map['cidade'] ?? 'Cidade não informada').toString(),
      quantidade: _int(map['quantidade']),
      semCotacao: _int(map['semCotacao'] ?? map['sem_cotacao']),
      proximos90Dias: _int(map['proximos90Dias'] ?? map['proximos_90_dias']),
      convidadosMedios:
          _int(map['convidadosMedios'] ?? map['convidados_medios']),
    );
  }

  static int _int(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class DemandaLatenteResumo {
  const DemandaLatenteResumo({
    required this.geradoEm,
    required this.totalEventos,
    required this.totalSemCotacao,
    required this.buckets,
    this.criterio = '',
  });

  final DateTime? geradoEm;
  final int totalEventos;
  final int totalSemCotacao;
  final List<DemandaLatenteBucket> buckets;
  final String criterio;

  factory DemandaLatenteResumo.fromMap(Map<String, dynamic> map) {
    final raw = map['buckets'];
    final buckets = <DemandaLatenteBucket>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          buckets.add(
              DemandaLatenteBucket.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    DateTime? gerado;
    final g = map['geradoEm'] ?? map['gerado_em'];
    if (g is String) gerado = DateTime.tryParse(g);
    return DemandaLatenteResumo(
      geradoEm: gerado,
      totalEventos: DemandaLatenteBucket._int(
          map['totalEventos'] ?? map['total_eventos']),
      totalSemCotacao: DemandaLatenteBucket._int(
          map['totalSemCotacao'] ?? map['total_sem_cotacao']),
      buckets: buckets,
      criterio: (map['criterio'] ?? '').toString(),
    );
  }
}
