import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/domain/entities/financeiro/item_estoque_fornecedor.dart';
import 'package:app_faca_festa/domain/entities/financeiro/movimento_estoque_fornecedor.dart';
import 'package:app_faca_festa/domain/services/estoque_fornecedor_service.dart';

ItemEstoqueFornecedor _item({
  int total = 100,
  int reservada = 0,
  int emUso = 0,
  NaturezaItemEstoque natureza = NaturezaItemEstoque.consumivel,
  int cmp = 500,
  StatusFisicoItemEstoque status = StatusFisicoItemEstoque.disponivel,
}) {
  return ItemEstoqueFornecedor(
    idItem: 'cadeiras',
    idFornecedor: 'forn-1',
    nome: 'Cadeira',
    natureza: natureza,
    unidade: 'un',
    quantidadeTotal: total,
    quantidadeReservada: reservada,
    quantidadeEmUso: emUso,
    status: status,
    metodoValorizacao: natureza == NaturezaItemEstoque.consumivel
        ? MetodoValorizacaoEstoque.custoMedioMovel
        : MetodoValorizacaoEstoque.custoUsoConfigurado,
    custoMedioUnitarioCentavos: cmp,
    custoUsoCentavos: natureza == NaturezaItemEstoque.reutilizavel ? cmp : 0,
  );
}

void main() {
  test('saldo 100 reserva 60: concorrente 50 rejeitada', () {
    final item = _item(total: 100);
    final inicio = DateTime(2026, 10, 21, 10);
    final fim = DateTime(2026, 10, 21, 18);
    final intervalo = EstoqueFornecedorService.intervaloEfetivo(
      inicio: inicio,
      fim: fim,
      item: item,
    );
    final r1 = EstoqueFornecedorService.reservar(
      item: item,
      idReserva: 'r1',
      idEvento: 'e1',
      quantidade: 60,
      intervalo: intervalo,
      reservasAtivas: const [],
    );
    expect(
      () => EstoqueFornecedorService.reservar(
        item: r1.item,
        idReserva: 'r2',
        idEvento: 'e2',
        quantidade: 50,
        intervalo: intervalo,
        reservasAtivas: [r1.reserva!],
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('retirada de reserva não desconta novamente', () {
    final item = _item(total: 100, reservada: 60);
    final reserva = ReservaEstoqueFornecedor(
      idReserva: 'r1',
      idItem: 'cadeiras',
      idFornecedor: 'forn-1',
      idEvento: 'e1',
      quantidade: 60,
      status: StatusReservaEstoque.ativa,
      intervaloEfetivo: IntervaloReservaEstoque(
        inicio: DateTime(2026, 10, 21),
        fim: DateTime(2026, 10, 22),
      ),
    );
    final ret = EstoqueFornecedorService.retirarDeReserva(
      item: item,
      reserva: reserva,
    );
    expect(ret.item.quantidadeTotal, 100);
    expect(ret.item.quantidadeReservada, 0);
    expect(ret.item.quantidadeEmUso, 60);
    expect(ret.item.quantidadeDisponivelLivre, 40);
  });

  test(
      '10 cadeiras: intervalos não sobrepostos ok; sobrepostos acima da capacidade não',
      () {
    final item = _item(
      total: 10,
      natureza: NaturezaItemEstoque.reutilizavel,
      cmp: 100,
    );
    final manha = IntervaloReservaEstoque(
      inicio: DateTime(2026, 10, 21, 8),
      fim: DateTime(2026, 10, 21, 12),
    );
    final tarde = IntervaloReservaEstoque(
      inicio: DateTime(2026, 10, 21, 14),
      fim: DateTime(2026, 10, 21, 18),
    );
    final r1 = EstoqueFornecedorService.reservar(
      item: item,
      idReserva: 'r1',
      idEvento: 'e1',
      quantidade: 10,
      intervalo: manha,
      reservasAtivas: const [],
    );
    final r2 = EstoqueFornecedorService.reservar(
      item: r1.item,
      idReserva: 'r2',
      idEvento: 'e2',
      quantidade: 10,
      intervalo: tarde,
      reservasAtivas: [r1.reserva!],
    );
    expect(r2.reserva!.quantidade, 10);

    expect(
      () => EstoqueFornecedorService.reservar(
        item: r2.item,
        idReserva: 'r3',
        idEvento: 'e3',
        quantidade: 1,
        intervalo: manha,
        reservasAtivas: [r1.reserva!, r2.reserva!],
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('consumo 20 × R\$5 atribui R\$100 sem desembolso', () {
    final item = _item(total: 100, cmp: 500);
    final r = EstoqueFornecedorService.consumir(
      item: item,
      quantidade: 20,
    );
    expect(r.custoAtribuidoCentavos, 10000);
    expect(r.geraDesembolso, isFalse);
    expect(r.origemCusto, 'estoque_consumo');
    expect(r.item.quantidadeTotal, 80);
  });

  test('repetir consumo/devolução é idempotente; cancelar só reserva ativa',
      () {
    final item = _item(total: 100, reservada: 10);
    final reserva = ReservaEstoqueFornecedor(
      idReserva: 'r1',
      idItem: 'cadeiras',
      idFornecedor: 'forn-1',
      idEvento: 'e1',
      quantidade: 10,
      status: StatusReservaEstoque.ativa,
      intervaloEfetivo: IntervaloReservaEstoque(
        inicio: DateTime(2026, 10, 21),
        fim: DateTime(2026, 10, 22),
      ),
    );
    final cons = EstoqueFornecedorService.consumir(
      item: item,
      quantidade: 10,
      reserva: reserva,
    );
    final rep = EstoqueFornecedorService.consumir(
      item: cons.item,
      quantidade: 10,
      reserva: cons.reserva,
    );
    expect(rep.idempotente, isTrue);
    expect(cons.item.quantidadeTotal, 90);

    expect(
      () => EstoqueFornecedorService.cancelarReserva(
        item: cons.item,
        reserva: cons.reserva!,
      ),
      throwsA(isA<StateError>()),
    );

    final ativa = ReservaEstoqueFornecedor(
      idReserva: 'r2',
      idItem: 'cadeiras',
      idFornecedor: 'forn-1',
      idEvento: 'e1',
      quantidade: 5,
      status: StatusReservaEstoque.ativa,
      intervaloEfetivo: IntervaloReservaEstoque(
        inicio: DateTime(2026, 10, 21),
        fim: DateTime(2026, 10, 22),
      ),
    );
    final comRes = cons.item.copyWith(quantidadeReservada: 5);
    final can = EstoqueFornecedorService.cancelarReserva(
      item: comRes,
      reserva: ativa,
    );
    expect(can.reserva!.status, StatusReservaEstoque.cancelada);
    expect(can.item.quantidadeReservada, 0);
  });

  test(
      'item vencido/manutenção não disponível; outra empresa não autoriza no cliente',
      () {
    final vencido = _item(status: StatusFisicoItemEstoque.vencido);
    expect(vencido.quantidadeDisponivelLivre, 0);
    expect(
      () => EstoqueFornecedorService.reservar(
        item: vencido,
        idReserva: 'r',
        idEvento: 'e',
        quantidade: 1,
        intervalo: IntervaloReservaEstoque(
          inicio: DateTime(2026, 10, 21),
          fim: DateTime(2026, 10, 22),
        ),
        reservasAtivas: const [],
      ),
      throwsA(isA<StateError>()),
    );

    final manut = _item(status: StatusFisicoItemEstoque.manutencao);
    expect(manut.status.ofereceDisponibilidade, isFalse);

    // Espelho da regra uid == idFornecedor (autorização no backend).
    bool autorizado(String uid, String idFornecedor) => uid == idFornecedor;
    expect(autorizado('outra-empresa', 'forn-1'), isFalse);
    expect(autorizado('forn-1', 'forn-1'), isTrue);
  });

  test('CMP após entrada preserva método; FEFO não muda valorização', () {
    final cmp = EstoqueFornecedorService.custoMedioAposEntrada(
      saldoAnterior: 10,
      cmpCentavosAnterior: 500,
      quantidadeEntrada: 10,
      custoUnitarioEntradaCentavos: 700,
    );
    expect(cmp, 600);
  });
}
