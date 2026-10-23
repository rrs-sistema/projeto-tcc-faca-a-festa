import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Data e hora civis pertencem ao fuso declarado. Null continua desconhecido.
/// O cardápio de execução é uma cópia independente do modelo reutilizável.
class OcorrenciaServico {
  final String id, evento, modelo, cardapio, titulo, formato;
  final String? dataLocal, horaLocal, fuso;
  final int? duracaoMinutos;
  const OcorrenciaServico(
      {required this.id,
      required this.evento,
      required this.modelo,
      required this.cardapio,
      required this.titulo,
      this.dataLocal,
      this.horaLocal,
      this.fuso,
      this.duracaoMinutos,
      this.formato = 'nao_definido'});
  static bool _zonas = false;
  static const formatos = [
    'nao_definido',
    'buffet',
    'empratado',
    'volante',
    'autosservico'
  ];
  static DateTime? dataCivil(String? s) {
    if (s == null) return null;
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
      throw ArgumentError('Informe a data no formato AAAA-MM-DD.');
    }
    final d = DateTime.tryParse(s);
    if (d == null ||
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}' !=
            s) {
      throw ArgumentError('Data inválida.');
    }
    return DateTime.utc(d.year, d.month, d.day);
  }

  void validar({DateTime? inicioEvento, DateTime? fimEvento}) {
    for (final s in [id, evento, modelo, cardapio]) {
      if (s.isEmpty || s.length > 200 || s.contains('/')) {
        throw ArgumentError('Confira o vínculo da ocorrência.');
      }
    }
    if (cardapio == modelo ||
        id != cardapio ||
        titulo.trim().isEmpty ||
        titulo.length > 120 ||
        !formatos.contains(formato)) {
      throw ArgumentError('Confira a identificação e o formato do serviço.');
    }
    final d = dataCivil(dataLocal);
    if (horaLocal != null &&
        !RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(horaLocal!)) {
      throw ArgumentError('Horário inválido. Use HH:mm ou deixe em aberto.');
    }
    if (duracaoMinutos != null &&
        (duracaoMinutos! < 1 || duracaoMinutos! > 1440)) {
      throw ArgumentError(
          'Informe duração entre 1 e 1.440 minutos ou deixe em aberto.');
    }
    if (fuso != null) {
      if (!_zonas) {
        tzdata.initializeTimeZones();
        _zonas = true;
      }
      try {
        tz.getLocation(fuso!);
      } catch (_) {
        throw ArgumentError('Informe um fuso IANA válido ou deixe em aberto.');
      }
    }
    if (d != null) {
      final inicio = inicioEvento == null
          ? null
          : DateTime.utc(
              inicioEvento.year, inicioEvento.month, inicioEvento.day);
      final fim = fimEvento == null
          ? inicio
          : DateTime.utc(fimEvento.year, fimEvento.month, fimEvento.day);
      if (inicio != null && d.isBefore(inicio) ||
          fim != null && d.isAfter(fim)) {
        throw ArgumentError(
            'A data do serviço deve estar dentro do período do evento.');
      }
      if (horaLocal != null && duracaoMinutos != null && fim != null) {
        final partes = horaLocal!.split(':').map(int.parse).toList();
        final termino = d.add(
            Duration(hours: partes[0], minutes: partes[1] + duracaoMinutos!));
        if (termino.isAfter(fim.add(const Duration(days: 1)))) {
          throw ArgumentError('O intervalo do serviço termina fora do evento.');
        }
      }
      if (horaLocal != null && fuso != null) {
        final p = horaLocal!.split(':').map(int.parse).toList();
        final local = tz.TZDateTime(
            tz.getLocation(fuso!), d.year, d.month, d.day, p[0], p[1]);
        if (local.year != d.year ||
            local.month != d.month ||
            local.day != d.day ||
            local.hour != p[0] ||
            local.minute != p[1]) {
          throw ArgumentError(
              'Esse horário não existe no fuso e data declarados.');
        }
      }
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'id_evento': evento,
        'id_modelo': modelo,
        'id_cardapio': cardapio,
        'titulo': titulo,
        'data_local': dataLocal,
        'hora_local': horaLocal,
        'fuso': fuso,
        'duracao_minutos': duracaoMinutos,
        'formato': formato
      };
  factory OcorrenciaServico.fromMap(Map<String, dynamic> m) {
    if (m.keys.any((k) => ![
          'id',
          'id_evento',
          'id_modelo',
          'id_cardapio',
          'titulo',
          'data_local',
          'hora_local',
          'fuso',
          'duracao_minutos',
          'formato'
        ].contains(k))) {
      throw ArgumentError('Campos de ocorrência incompatíveis.');
    }
    for (final k in [
      'id',
      'id_evento',
      'id_modelo',
      'id_cardapio',
      'titulo',
      'formato'
    ]) {
      if (m[k] is! String) {
        throw ArgumentError('Ocorrência inválida.');
      }
    }
    for (final k in ['data_local', 'hora_local', 'fuso']) {
      if (m[k] != null && m[k] is! String) {
        throw ArgumentError('Agenda inválida.');
      }
    }
    if (m['duracao_minutos'] != null && m['duracao_minutos'] is! int) {
      throw ArgumentError('Duração inválida.');
    }
    final o = OcorrenciaServico(
        id: m['id'],
        evento: m['id_evento'],
        modelo: m['id_modelo'],
        cardapio: m['id_cardapio'],
        titulo: m['titulo'],
        dataLocal: m['data_local'],
        horaLocal: m['hora_local'],
        fuso: m['fuso'],
        duracaoMinutos: m['duracao_minutos'],
        formato: m['formato']);
    o.validar();
    return o;
  }
  String get resumo =>
      '$titulo · ${dataLocal ?? 'data em aberto'} · ${horaLocal ?? 'horário em aberto'}${fuso == null ? '' : ' · $fuso'}${duracaoMinutos == null ? '' : ' · $duracaoMinutos min'}';
}
