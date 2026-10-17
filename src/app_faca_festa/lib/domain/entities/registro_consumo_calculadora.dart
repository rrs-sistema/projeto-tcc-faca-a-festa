import 'convidados_equivalentes.dart';
import 'estimativa_financeira.dart';

class RegistroConsumoCalculadora {
  final String idEvento, contexto;
  final DateTime dataRegistro;
  final DateTime? dataConsumo;
  final ItemEstimativaFinanceira regra;
  final int adultos, criancas, bebes;
  final int duracaoHoras;
  final double disponibilizado, sobra, desperdicio;
  final bool faltou;
  final double? pesoBaseMedido, pesoProntoMedido;

  const RegistroConsumoCalculadora(
      {required this.idEvento,
      required this.contexto,
      required this.dataRegistro,
      this.dataConsumo,
      required this.regra,
      required this.adultos,
      required this.criancas,
      required this.bebes,
      required this.duracaoHoras,
      required this.disponibilizado,
      required this.sobra,
      required this.desperdicio,
      required this.faltou,
      this.pesoBaseMedido,
      this.pesoProntoMedido});

  double get consumidoPronto => disponibilizado - sobra - desperdicio;
  double get servidoPronto => disponibilizado - sobra;
  double get fatorPreparo => regra.premissas['estado'] == 'pronto'
      ? 1
      : pesoProntoMedido! / pesoBaseMedido!;
  ConvidadosEquivalentes get pessoas => ConvidadosEquivalentes(
      adultos: adultos, criancas: criancas, bebes: bebes);
  ItemEstimativaFinanceira get regraObservada => regra.copyWith(
      premissas: Map<String, dynamic>.from(regra.premissas)
        ..remove('publico_refeicao')
        ..remove('destino_publico'));
  double get porcaoObservada =>
      servidoPronto /
      fatorPreparo /
      regraObservada.publicoEquivalente(pessoas) /
      regra.numeroServicos /
      regra.fatorComposicao;

  void validar() {
    final unidade = regra.premissas['unidade_consumo'] ?? regra.unidade.label;
    final estado = regra.premissas['estado'];
    if ((dataConsumo != null &&
            dataConsumo!.isAfter(dataRegistro.add(const Duration(days: 1)))) ||
        duracaoHoras <= 0 ||
        idEvento.isEmpty ||
        contexto.isEmpty ||
        (regra.premissas['receita']?.toString().trim().isEmpty ?? true) ||
        !['principal', 'acompanhamento', 'bebida', 'outro']
            .contains(regra.premissas['papel_na_refeicao']) ||
        !['kg', 'L', 'un'].contains(unidade) ||
        !['cru', 'seco', 'pronto'].contains(estado) ||
        [adultos, criancas, bebes].any((n) => n < 0) ||
        [regra.pesoCrianca, regra.pesoBebe]
            .any((n) => !n.isFinite || n < 0 || n > 1) ||
        !regraObservada.publicoEquivalente(pessoas).isFinite ||
        regraObservada.publicoEquivalente(pessoas) <= 0 ||
        !regra.numeroServicos.isFinite ||
        regra.numeroServicos <= 0 ||
        !regra.fatorComposicao.isFinite ||
        regra.fatorComposicao <= 0 ||
        [disponibilizado, sobra, desperdicio]
            .any((n) => !n.isFinite || n < 0) ||
        disponibilizado <= 0 ||
        consumidoPronto < -1e-9) {
      throw ArgumentError(
          'Confira receita, papel, público, estado, medidas e quantidades. Sobra e desperdício não podem superar o disponibilizado.');
    }
    if (estado != 'pronto' &&
        (pesoBaseMedido == null ||
            pesoProntoMedido == null ||
            !pesoBaseMedido!.isFinite ||
            !pesoProntoMedido!.isFinite ||
            pesoBaseMedido! <= 0 ||
            pesoProntoMedido! <= 0)) {
      throw ArgumentError(
          'Para relacionar alimento pronto à base crua/seca, informe o rendimento medido.');
    }
  }

  Map<String, dynamic> toMap() => {
        'versao': 1,
        'id_evento': idEvento,
        'contexto': contexto,
        'data_registro': dataRegistro.toUtc().toIso8601String(),
        'data_consumo': dataConsumo?.toUtc().toIso8601String(),
        'regra': regra.toPlanejamento(),
        'adultos': adultos,
        'criancas': criancas,
        'bebes': bebes,
        'duracao_horas': duracaoHoras,
        'disponibilizado_pronto': disponibilizado,
        'sobra_pronta': sobra,
        'desperdicio_pronto': desperdicio,
        'faltou': faltou,
        'peso_base_medido': pesoBaseMedido,
        'peso_pronto_medido': pesoProntoMedido,
      };

  factory RegistroConsumoCalculadora.fromMap(Map<String, dynamic> m) {
    final r = RegistroConsumoCalculadora(
        idEvento: m['id_evento'] as String,
        contexto: m['contexto'] as String,
        dataRegistro: DateTime.parse(m['data_registro'] as String),
        dataConsumo: DateTime.tryParse(m['data_consumo']?.toString() ?? ''),
        regra: ItemEstimativaFinanceira.fromPlanejamento(
            Map<String, dynamic>.from(m['regra'] as Map)),
        adultos: (m['adultos'] as num).toInt(),
        criancas: (m['criancas'] as num).toInt(),
        bebes: (m['bebes'] as num).toInt(),
        duracaoHoras: (m['duracao_horas'] as num).toInt(),
        disponibilizado: (m['disponibilizado_pronto'] as num).toDouble(),
        sobra: (m['sobra_pronta'] as num).toDouble(),
        desperdicio: (m['desperdicio_pronto'] as num).toDouble(),
        faltou: m['faltou'] == true,
        pesoBaseMedido: (m['peso_base_medido'] as num?)?.toDouble(),
        pesoProntoMedido: (m['peso_pronto_medido'] as num?)?.toDouble());
    r.validar();
    return r;
  }
}
