import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/data/models/evento/evento_model.dart';

void main() {
  EventoModel evento({DateTime? fim}) => EventoModel(
        idEvento: 'retiro',
        idTipoEvento: 'retiro',
        idUsuario: 'organizador',
        nomeEvento: 'Retiro',
        localEvento: 'Chácara',
        data: DateTime(2026, 10, 30, 18),
        dataFim: fim,
      );

  test('documentos antigos continuam com um dia', () {
    final antigo = evento().toMap();
    expect(antigo.containsKey('data_fim'), isFalse);
    expect(EventoModel.fromMap(antigo).duracaoDias, 1);
  });

  test('conta dias inclusivos e preserva período entre meses', () {
    final retiro = evento(fim: DateTime(2026, 11, 3));
    expect(retiro.duracaoDias, 5);
    final salvo = EventoModel.fromMap(retiro.toMap());
    expect(salvo.dataFim, retiro.dataFim);
    expect(salvo.duracaoDias, 5);
    expect(EventoModel.fromEntity(salvo).dataFim, retiro.dataFim);
    expect(salvo.copyWith(nomeEvento: 'Outro título').dataFim, retiro.dataFim);
    expect(salvo.copyWith(limparDataFim: true).duracaoDias, 1);
  });

  test('início e término no mesmo dia contam como um dia', () {
    expect(evento(fim: DateTime(2026, 10, 30)).duracaoDias, 1);
  });
}
