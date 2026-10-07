import 'package:app_faca_festa/domain/entities/convidado.dart';

String exportarConvidadosCsv(List<Convidado> convidados) {
  final linhas = <String>[
    'nome,contato,email,status,tipo,grupo',
    for (final convidado in convidados)
      [
        _csv(convidado.nome),
        _csv(convidado.contato),
        _csv(convidado.email ?? ''),
        _csv(convidado.status.label),
        _csv(convidado.tipoConvidado.label),
        _csv(convidado.nomeGrupo ?? ''),
      ].join(','),
  ];
  return linhas.join('\n');
}

String _csv(String value) {
  final limpo = value.replaceAll('"', '""');
  if (limpo.contains(',') || limpo.contains('"') || limpo.contains('\n')) {
    return '"$limpo"';
  }
  return limpo;
}
