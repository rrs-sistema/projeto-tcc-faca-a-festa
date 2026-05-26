import 'dart:math';

import '../../data/models/evento/calculadora_festa_item_model.dart';
import '../../data/models/evento/calculadora_festa_model.dart';

class CalculadoraFestaService {
  List<CalculadoraFestaItemModel> calcularItens({
    required CalculadoraFestaModel calculo,
  }) {
    if (calculo.totalConvidados <= 0) return [];

    final adultos = calculo.totalAdultos;
    final criancas = calculo.totalCriancas;
    final bebes = calculo.totalBebes;
    final fatorFinal = _fatorDuracao(calculo.duracaoHoras) * _fatorTipoEvento(calculo.tipoEvento);

    final salgadinhos = _arredondarParaCima(
      ((adultos * 6) + (criancas * 4) + (bebes * 0.5)) * fatorFinal,
      multiplo: 10,
    );

    final boloKg = _arredondarDecimalParaCima(
      ((adultos * 0.12) + (criancas * 0.09) + (bebes * 0.02)) * fatorFinal,
      multiplo: 0.5,
    );

    final docinhos = _arredondarParaCima(
      ((adultos * 1.2) + (criancas * 1.5) + (bebes * 0.2)) * fatorFinal,
      multiplo: 10,
    );

    final copos = _arredondarParaCima(
      ((adultos * 1.5) + (criancas * 1.3) + (bebes * 0.3)) * fatorFinal,
      multiplo: 10,
    );

    final refrigeranteLitros = _arredondarDecimalParaCima(
      ((adultos * 0.20) + (criancas * 0.25) + (bebes * 0.05)) * fatorFinal,
      multiplo: 1,
    );

    final aguaLitros = _arredondarDecimalParaCima(
      ((adultos * 0.20) + (criancas * 0.12) + (bebes * 0.05)) * fatorFinal,
      multiplo: 1,
    );

    return [
      CalculadoraFestaItemModel(
        idItemResultado: '${calculo.idCalculo}_salgadinhos',
        idCalculo: calculo.idCalculo,
        idEvento: calculo.idEvento,
        nome: 'Salgadinhos',
        tipoItem: 'comida',
        quantidade: salgadinhos.toDouble(),
        unidade: 'un',
        regraAplicada: 'Adulto: 6 un | Criança: 4 un | Ajustado por duração e tipo do evento.',
      ),
      CalculadoraFestaItemModel(
        idItemResultado: '${calculo.idCalculo}_bolo',
        idCalculo: calculo.idCalculo,
        idEvento: calculo.idEvento,
        nome: 'Bolo',
        tipoItem: 'bolo',
        quantidade: boloKg,
        unidade: 'kg',
        regraAplicada: 'Adulto: 120g | Criança: 90g | Ajustado por duração e tipo do evento.',
      ),
      CalculadoraFestaItemModel(
        idItemResultado: '${calculo.idCalculo}_docinhos',
        idCalculo: calculo.idCalculo,
        idEvento: calculo.idEvento,
        nome: 'Docinhos',
        tipoItem: 'sobremesa',
        quantidade: docinhos.toDouble(),
        unidade: 'un',
        regraAplicada: 'Adulto: 1,2 un | Criança: 1,5 un | Ajustado por duração e tipo do evento.',
      ),
      CalculadoraFestaItemModel(
        idItemResultado: '${calculo.idCalculo}_copos',
        idCalculo: calculo.idCalculo,
        idEvento: calculo.idEvento,
        nome: 'Copos descartáveis',
        tipoItem: 'descartavel',
        quantidade: copos.toDouble(),
        unidade: 'un',
        regraAplicada: 'Adulto: 1,5 un | Criança: 1,3 un | Ajustado por duração e tipo do evento.',
      ),
      CalculadoraFestaItemModel(
        idItemResultado: '${calculo.idCalculo}_refrigerante',
        idCalculo: calculo.idCalculo,
        idEvento: calculo.idEvento,
        nome: 'Refrigerante',
        tipoItem: 'bebida',
        quantidade: refrigeranteLitros,
        unidade: 'L',
        regraAplicada: 'Adulto: 200ml | Criança: 250ml | Ajustado por duração e tipo do evento.',
      ),
      CalculadoraFestaItemModel(
        idItemResultado: '${calculo.idCalculo}_agua',
        idCalculo: calculo.idCalculo,
        idEvento: calculo.idEvento,
        nome: 'Água',
        tipoItem: 'bebida',
        quantidade: aguaLitros,
        unidade: 'L',
        regraAplicada: 'Adulto: 200ml | Criança: 120ml | Ajustado por duração e tipo do evento.',
      ),
    ];
  }

  double _fatorDuracao(int duracaoHoras) {
    final horas = duracaoHoras <= 0 ? 4 : duracaoHoras;
    if (horas == 4) return 1;
    if (horas > 4) return min(1 + ((horas - 4) * 0.12), 1.6);
    return max(1 - ((4 - horas) * 0.10), 0.7);
  }

  double _fatorTipoEvento(String tipoEvento) {
    final tipo = tipoEvento.trim().toLowerCase();
    if (tipo.contains('casamento')) return 1.15;
    if (tipo.contains('ano novo') || tipo.contains('natal')) return 1.10;
    if (tipo.contains('chá') || tipo.contains('cha')) return 0.90;
    if (tipo.contains('infantil')) return 0.95;
    return 1.0;
  }

  int _arredondarParaCima(double valor, {int multiplo = 10}) {
    if (valor <= 0) return 0;
    return ((valor / multiplo).ceil() * multiplo);
  }

  double _arredondarDecimalParaCima(double valor, {double multiplo = 0.5}) {
    if (valor <= 0) return 0;
    return (valor / multiplo).ceil() * multiplo;
  }
}
