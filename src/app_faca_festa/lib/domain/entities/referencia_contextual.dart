import '../services/revisao_cardapio_service.dart';

/// Documento editorial imutável depois da publicação. Não contém preços.
class ReferenciaContextual {
  ReferenciaContextual(Map<String, dynamic> valor)
      : dados = Map<String, dynamic>.unmodifiable(valor) {
    validar();
  }
  final Map<String, dynamic> dados;
  String get id => dados['id'];
  int get versao => dados['versao'];
  String get tipo => dados['tipo'];
  String get nome => dados['nome'];
  String get chave => '$id@$versao';
  List<String> lista(String campo) => List<String>.from(dados[campo]);
  static const campos = {
    'schema',
    'motor_minimo',
    'id',
    'versao',
    'tipo',
    'nome',
    'aliases',
    'alimento_receita',
    'servicos',
    'formatos',
    'periodos',
    'publicos',
    'obtencoes',
    'papel',
    'unidade',
    'estado_consumo',
    'estado_compra',
    'contexto',
    'limitacoes',
    'fonte',
    'verificado_em',
    'revisao_editorial',
    'minimo',
    'maximo',
    'padrao',
    'itens',
    'origem_legado',
    'aprovado_por',
    'aprovado_em',
    'hora_inicio',
    'infraestrutura',
    'hora_fim',
    'duracao_minima',
    'duracao_maxima',
  };
  void validar() {
    void exigir(bool ok) {
      if (!ok) throw ArgumentError('Referência contextual incompatível.');
    }

    exigir(dados.keys.every(campos.contains));
    exigir(dados['schema'] == 1 && dados['motor_minimo'] == 1);
    exigir(dados['id'] is String &&
        RegExp(r'^[a-z0-9_\-]{1,120}$').hasMatch(dados['id']));
    exigir(dados['versao'] is int && versao > 0 && versao <= 1000000);
    exigir(['porcao', 'modelo', 'rendimento'].contains(dados['tipo']));
    for (final k in [
      'nome',
      'alimento_receita',
      'contexto',
      'limitacoes',
      'fonte',
      'revisao_editorial'
    ]) {
      exigir(dados[k] is String &&
          (dados[k] as String).trim().isNotEmpty &&
          (dados[k] as String).length <= 4000);
    }
    final uri = Uri.tryParse(dados['fonte']);
    exigir(uri != null &&
        (uri.scheme == 'https' && uri.host.isNotEmpty ||
            uri.scheme == 'codigo' && uri.path.isNotEmpty));
    for (final k in [
      'aliases',
      'servicos',
      'formatos',
      'periodos',
      'publicos',
      'obtencoes'
    ]) {
      exigir(dados[k] is List &&
          (dados[k] as List).isNotEmpty &&
          (dados[k] as List).length <= 30 &&
          (dados[k] as List).every(
              (s) => s is String && s.trim().isNotEmpty && s.length <= 160));
    }
    exigir(lista('servicos').every(['refeicao', 'lanche'].contains));
    exigir(lista('formatos')
        .every(['buffet', 'empratado', 'volante', 'autosservico'].contains));
    exigir(lista('periodos')
        .every(['manha', 'tarde', 'noite', 'qualquer'].contains));
    exigir(lista('publicos')
        .every(['adultos', 'criancas', 'bebes', 'todos'].contains));
    exigir(lista('obtencoes').every(['servir', 'pronto', 'preparar'].contains));
    exigir(['principal', 'acompanhamento', 'bebida', 'outro']
        .contains(dados['papel']));
    exigir(['quilo', 'litro', 'unidade'].contains(dados['unidade']));
    exigir(['cru', 'seco', 'pronto'].contains(dados['estado_consumo']) &&
        ['cru', 'seco', 'pronto'].contains(dados['estado_compra']));
    if (tipo != 'modelo') {
      for (final k in ['minimo', 'maximo', 'padrao']) {
        exigir(dados[k] is num &&
            (dados[k] as num).isFinite &&
            dados[k] > 0 &&
            dados[k] <= 10000);
      }
      exigir(dados['minimo'] <= dados['padrao'] &&
          dados['padrao'] <= dados['maximo']);
    } else {
      exigir(lista('servicos').length == 1 && lista('formatos').length == 1);
      exigir(dados['itens'] is List &&
          (dados['itens'] as List).isNotEmpty &&
          (dados['itens'] as List).length <= 30);
      for (final item in dados['itens']) {
        exigir(item is Map &&
            item.keys.every(['nome', 'tipo'].contains) &&
            item['nome'] is String &&
            (item['nome'] as String).trim().isNotEmpty &&
            (item['nome'] as String).length <= 120 &&
            ['comida', 'bebida', 'bolo', 'sobremesa', 'outro']
                .contains(item['tipo']));
      }
    }
    for (final k in ['verificado_em', 'aprovado_em']) {
      exigir(dados[k] == null ||
          dados[k] is String && DateTime.tryParse(dados[k]) != null);
    }
    exigir(dados['aprovado_por'] == null || dados['aprovado_por'] is String);
    exigir(dados['infraestrutura'] == null ||
        dados['infraestrutura'] is List &&
            (dados['infraestrutura'] as List).length <= 4 &&
            (dados['infraestrutura'] as List).every([
              'cozinha',
              'refrigeracao',
              'aquecimento',
              'equipe_preparo'
            ].contains));
    for (final k in ['duracao_minima', 'duracao_maxima']) {
      exigir(dados[k] == null ||
          dados[k] is int && dados[k] >= 1 && dados[k] <= 1440);
    }
    exigir(dados['duracao_minima'] == null ||
        dados['duracao_maxima'] == null ||
        dados['duracao_minima'] <= dados['duracao_maxima']);
    for (final k in ['hora_inicio', 'hora_fim']) {
      exigir(dados[k] == null ||
          dados[k] is String &&
              RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(dados[k]));
    }
    exigir((dados['hora_inicio'] == null) == (dados['hora_fim'] == null));
    exigir(dados['hora_inicio'] == null ||
        (dados['hora_inicio'] as String).compareTo(dados['hora_fim']) <= 0);
  }

  bool reconhece(String nome) => lista('aliases').any((a) =>
      RevisaoCardapioService.normalizar(a) ==
      RevisaoCardapioService.normalizar(nome));
  bool compativel(
          {required String servico,
          required String formato,
          required String publico,
          required String obtencao,
          String? periodo,
          String? hora,
          int? minutos}) =>
      lista('servicos').contains(servico) &&
      lista('formatos').contains(formato) &&
      lista('publicos').contains(publico) &&
      lista('obtencoes').contains(obtencao) &&
      (dados['hora_inicio'] == null ||
          hora != null &&
              hora.compareTo(dados['hora_inicio']) >= 0 &&
              hora.compareTo(dados['hora_fim']) <= 0) &&
      (dados['duracao_minima'] == null ||
          minutos != null && minutos >= dados['duracao_minima']) &&
      (dados['duracao_maxima'] == null ||
          minutos != null && minutos <= dados['duracao_maxima']) &&
      (lista('periodos').contains('qualquer') ||
          periodo != null && lista('periodos').contains(periodo));
}

class CatalogoContextual {
  const CatalogoContextual(this.referencias,
      {this.estado = 'disponivel', this.aviso = ''});
  final List<ReferenciaContextual> referencias;
  final String estado, aviso;
  static const indisponivel = CatalogoContextual([],
      estado: 'indisponivel',
      aviso:
          'Referências indisponíveis. Mantenha seu cardápio livre ou uma regra já confirmada; atualize para consultar propostas.');
  List<ReferenciaContextual> get modelos =>
      referencias.where((r) => r.tipo == 'modelo').toList();
  Map<String, dynamic> get snapshot => {
        'estado': estado,
        'aviso': aviso,
        'referencias': [for (final r in referencias) r.dados]
      };
}
