/// Adaptação de leitura apenas: nenhuma hipótese vira confirmação persistida.
class CompatibilidadePlanejamentoService {
  const CompatibilidadePlanejamentoService();
  static const motorAtual = 6;
  List<String> evento(Map<String, dynamic> dados) => [
        if (dados['data_fim'] == null)
          'Término não informado; confirme o período antes de organizar serviços.',
        if (dados['total_convidados'] != null &&
            ['total_adultos', 'total_criancas', 'total_bebes']
                .every((k) => dados[k] == null))
          'Previsão total preservada; distribuição etária não informada.',
      ];
  List<String> regra(Map<String, dynamic> dados) {
    final meta = dados['premissas'] is Map ? dados['premissas'] as Map : {};
    return [
      if (meta['fonte'] == null)
        'Regra legada sem origem declarada; confirme antes de reutilizar.',
      if (meta['id_ocorrencia'] == null)
        'Regra sem ocorrência confirmada; não foi criada uma data automaticamente.',
    ];
  }

  List<String> historico(Map<String, dynamic> contexto) => [
        if ((contexto['versao_motor'] is num
                ? (contexto['versao_motor'] as num).toInt()
                : 0) !=
            motorAtual)
          'Histórico de outro motor preservado; atualizar exige uma nova simulação.',
      ];
}
