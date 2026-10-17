import 'revisao_cardapio_service.dart';

class CompromissoPlanejamentoService {
  const CompromissoPlanejamentoService();

  Map<String, dynamic>? mapear(String id, Map<String, dynamic> data,
      {List<Map<String, dynamic>> gastos = const []}) {
    final status = [data['status'], data['status_orcamento']]
        .map((v) => RevisaoCardapioService.normalizar(v?.toString() ?? ''));
    if (data['ativo'] == false ||
        data['deletado'] == true ||
        status.any((s) =>
            ['cancelado', 'cancelada', 'canceled', 'cancelled'].contains(s))) {
      return null;
    }
    final nome = (data['nome'] ?? data['item'] ?? '').toString().trim();
    final unidade = (data['unidade'] ?? '').toString().trim();
    final real = data['custo_real'] is num
        ? (data['custo_real'] as num).toDouble()
        : 0.0;
    final previsto = data['custo_estimado'] is num
        ? (data['custo_estimado'] as num).toDouble()
        : 0.0;
    final detalhado = gastos.fold<double>(
        0, (s, g) => s + ((g['custo'] as num?)?.toDouble() ?? 0));
    final pago = gastos.fold<double>(
        0, (s, g) => s + ((g['pago'] as num?)?.toDouble() ?? 0));
    final coberturas =
        List<String>.from(data['calculadora_cobre_itens'] as List? ?? []);
    final valor = [real, previsto, detalhado].reduce((a, b) => a > b ? a : b);
    final identidade = RevisaoCardapioService.identidade(
        nome, unidade, (data['publico_alvo'] ?? 'todos').toString());
    final raw = data['calculadora_conferencia_financeira'];
    final coberturasConferidas = raw is Map && raw['coberturas'] is List
        ? List<String>.from(raw['coberturas'])
        : <String>[];
    final confere = raw is Map &&
        raw['valor'] == valor &&
        raw['identidade'] == identidade &&
        coberturasConferidas.toSet().length == coberturas.toSet().length &&
        coberturasConferidas.toSet().containsAll(coberturas);
    final modo = confere &&
            ['realizado', 'sem_itens'].contains(raw['modo']) &&
            (raw['modo'] != 'sem_itens' || coberturas.isEmpty)
        ? raw['modo']
        : 'revisar';
    return {
      'id': id,
      'conferencia_financeira': modo,
      'valor': valor.isFinite ? valor.clamp(0, double.infinity) : 0.0,
      'pago': gastos.isNotEmpty
          ? pago
          : data['pago'] == true
              ? valor
              : 0.0,
      'contratado':
          data['orcamento_fechado'] == true || status.contains('fechado'),
      'descricao': nome.isNotEmpty
          ? nome
          : (data['anotacoes'] ?? data['nome_servico'] ?? 'Serviço/orçamento')
              .toString(),
      'cobre_itens': coberturas,
      'cobertura_identificavel': (nome.isNotEmpty && unidade.isNotEmpty) ||
          coberturas.isNotEmpty ||
          modo == 'sem_itens',
      'identidade': identidade,
    };
  }
}
