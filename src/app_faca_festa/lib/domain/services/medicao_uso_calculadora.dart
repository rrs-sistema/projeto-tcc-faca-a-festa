/// Diagnóstico da sessão em memória. Não envia dados e não identifica pessoas/eventos.
class MedicaoUsoCalculadora {
  final Stopwatch _tempo = Stopwatch()..start();
  int listasAbertas = 0,
      listasCopiadas = 0,
      ajustes = 0,
      consumosRegistrados = 0;
  int? segundosPrimeiraLista, pendenciasUltimaLista;
  void abrirLista(int pendencias) {
    listasAbertas++;
    segundosPrimeiraLista ??= _tempo.elapsed.inSeconds;
    pendenciasUltimaLista = pendencias;
  }

  String relatorio({int? facilidade}) => [
        'Avaliação da sessão da calculadora',
        'Listas abertas: $listasAbertas',
        'Listas copiadas: $listasCopiadas',
        'Ajustes de regras e cenários: $ajustes',
        'Registros de consumo salvos: $consumosRegistrados',
        'Tempo decorrido até a primeira lista: ${segundosPrimeiraLista ?? 'não aberta'} s',
        'Pendências na última lista: ${pendenciasUltimaLista ?? 'não aberta'}',
        if (facilidade != null) 'Facilidade informada: $facilidade de 5',
        'Dados desta sessão, sem identificação. Tempo decorrido inclui pausas; não comprova eficiência nem redução de desperdício.'
      ].join('\n');
}
