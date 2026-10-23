import 'package:app_faca_festa/domain/entities/financeiro/item_estoque_fornecedor.dart';
import 'package:app_faca_festa/domain/entities/financeiro/movimento_estoque_fornecedor.dart';
import 'package:app_faca_festa/domain/entities/financeiro/valor_monetario.dart';

class AlertaEstoqueFornecedor {
  const AlertaEstoqueFornecedor({
    required this.codigo,
    required this.mensagem,
    this.idItem,
    this.severidade = 'aviso',
  });

  final String codigo;
  final String mensagem;
  final String? idItem;
  final String severidade;
}

class ResultadoOperacaoEstoque {
  const ResultadoOperacaoEstoque({
    required this.item,
    this.reserva,
    this.custoAtribuidoCentavos = 0,
    this.geraDesembolso = false,
    this.origemCusto,
    this.alertas = const [],
    this.idempotente = false,
  });

  final ItemEstoqueFornecedor item;
  final ReservaEstoqueFornecedor? reserva;
  final int custoAtribuidoCentavos;
  final bool geraDesembolso;
  final String? origemCusto;
  final List<AlertaEstoqueFornecedor> alertas;
  final bool idempotente;
}

/// Estoque empresarial do fornecedor.
/// Não equivale ao estoque alimentar da calculadora (lotes por evento).
class EstoqueFornecedorService {
  static const int limiteIntervaloDias = 30;

  /// Amplia o intervalo com montagem/transporte/desmontagem configurados.
  static IntervaloReservaEstoque intervaloEfetivo({
    required DateTime inicio,
    required DateTime fim,
    required ItemEstoqueFornecedor item,
  }) {
    if (!fim.isAfter(inicio)) {
      throw ArgumentError('Intervalo inválido: fim deve ser após início.');
    }
    final dias = fim.difference(inicio).inDays;
    if (dias > limiteIntervaloDias) {
      throw ArgumentError(
        'Intervalo excede o limite de $limiteIntervaloDias dias.',
      );
    }
    final inicioEfetivo = inicio.subtract(Duration(
      minutes: item.montagemMinutos + item.transporteMinutos,
    ));
    final fimEfetivo = fim.add(Duration(
      minutes: item.desmontagemMinutos + item.transporteMinutos,
    ));
    return IntervaloReservaEstoque(inicio: inicioEfetivo, fim: fimEfetivo);
  }

  /// Capacidade livre no intervalo (reutilizáveis / locados).
  static int capacidadeDisponivelNoIntervalo({
    required ItemEstoqueFornecedor item,
    required IntervaloReservaEstoque intervalo,
    required List<ReservaEstoqueFornecedor> reservasAtivas,
  }) {
    if (!item.status.ofereceDisponibilidade) return 0;
    if (item.natureza == NaturezaItemEstoque.consumivel) {
      return item.quantidadeDisponivelLivre;
    }
    var comprometido = 0;
    for (final r in reservasAtivas) {
      if (r.idItem != item.idItem) continue;
      if (!r.status.aindaCompromete) continue;
      if (r.intervaloEfetivo.overlaps(intervalo)) {
        comprometido += r.quantidade;
      }
    }
    final livre = item.quantidadeTotal - comprometido;
    return livre < 0 ? 0 : livre;
  }

  /// Custo médio móvel gerencial: (saldo*cmp + qtd*custo) / (saldo+qtd).
  /// Seleção física por validade (FEFO) não altera este método.
  static int custoMedioAposEntrada({
    required int saldoAnterior,
    required int cmpCentavosAnterior,
    required int quantidadeEntrada,
    required int custoUnitarioEntradaCentavos,
  }) {
    if (quantidadeEntrada <= 0) {
      throw ArgumentError('Quantidade de entrada deve ser positiva.');
    }
    if (custoUnitarioEntradaCentavos < 0 ||
        custoUnitarioEntradaCentavos > ValorMonetario.limiteCentavos) {
      throw ArgumentError('Custo unitário inválido.');
    }
    if (saldoAnterior < 0) {
      throw ArgumentError('Saldo inconsistente.');
    }
    final totalCentavos = saldoAnterior * cmpCentavosAnterior +
        quantidadeEntrada * custoUnitarioEntradaCentavos;
    final novoSaldo = saldoAnterior + quantidadeEntrada;
    return (totalCentavos / novoSaldo).round();
  }

  static ResultadoOperacaoEstoque registrarEntrada({
    required ItemEstoqueFornecedor item,
    required int quantidade,
    required int custoUnitarioCentavos,
    bool geraObrigacao = true,
  }) {
    if (quantidade <= 0) {
      throw ArgumentError('Informe a quantidade de entrada.');
    }
    final cmp = custoMedioAposEntrada(
      saldoAnterior: item.quantidadeTotal,
      cmpCentavosAnterior: item.custoMedioUnitarioCentavos,
      quantidadeEntrada: quantidade,
      custoUnitarioEntradaCentavos: custoUnitarioCentavos,
    );
    // Compra abastece estoque; pode gerar obrigação, sem ser custo integral do evento.
    return ResultadoOperacaoEstoque(
      item: item.copyWith(
        quantidadeTotal: item.quantidadeTotal + quantidade,
        custoMedioUnitarioCentavos: cmp,
        custoAusente: false,
      ),
      geraDesembolso: false,
      alertas: [
        if (geraObrigacao)
          const AlertaEstoqueFornecedor(
            codigo: 'obrigacao_compra',
            mensagem:
                'Entrada pode gerar obrigação financeira; não atribui custo integral a um evento.',
          ),
      ],
    );
  }

  static ResultadoOperacaoEstoque reservar({
    required ItemEstoqueFornecedor item,
    required String idReserva,
    required String idEvento,
    required int quantidade,
    required IntervaloReservaEstoque intervalo,
    required List<ReservaEstoqueFornecedor> reservasAtivas,
    String? chaveIdempotencia,
    ReservaEstoqueFornecedor? existenteMesmaChave,
  }) {
    if (existenteMesmaChave != null) {
      return ResultadoOperacaoEstoque(
        item: item,
        reserva: existenteMesmaChave,
        idempotente: true,
      );
    }
    if (!item.status.ofereceDisponibilidade) {
      throw StateError(
        'Item vencido ou em manutenção não é oferecido como disponível.',
      );
    }
    if (quantidade <= 0) {
      throw ArgumentError('Quantidade de reserva inválida.');
    }
    final livre = capacidadeDisponivelNoIntervalo(
      item: item,
      intervalo: intervalo,
      reservasAtivas: reservasAtivas,
    );
    if (quantidade > livre) {
      throw StateError(
        'Saldo insuficiente para reserva concorrente '
        '(disponível $livre, solicitado $quantidade).',
      );
    }

    final reserva = ReservaEstoqueFornecedor(
      idReserva: idReserva,
      idItem: item.idItem,
      idFornecedor: item.idFornecedor,
      idEvento: idEvento,
      quantidade: quantidade,
      status: StatusReservaEstoque.ativa,
      intervaloEfetivo: intervalo,
      chaveIdempotencia: chaveIdempotencia,
    );

    // Consumíveis: compromete saldo livre. Reutilizáveis: só intervalo.
    final novoItem = item.natureza == NaturezaItemEstoque.consumivel
        ? item.copyWith(
            quantidadeReservada: item.quantidadeReservada + quantidade,
          )
        : item;

    final alertas = <AlertaEstoqueFornecedor>[];
    if (livre - quantidade == 0) {
      alertas.add(AlertaEstoqueFornecedor(
        codigo: 'falta',
        mensagem: 'Capacidade esgotada no intervalo para ${item.nome}.',
        idItem: item.idItem,
      ));
    }
    if (item.financeiroIncompleto) {
      alertas.add(AlertaEstoqueFornecedor(
        codigo: 'custo_ausente',
        mensagem:
            'Disponibilidade física conhecida; financeiro incompleto (custo ausente).',
        idItem: item.idItem,
        severidade: 'info',
      ));
    }

    return ResultadoOperacaoEstoque(
      item: novoItem,
      reserva: reserva,
      alertas: alertas,
    );
  }

  /// Retirada de reserva: não desconta novamente a disponibilidade comprometida.
  static ResultadoOperacaoEstoque retirarDeReserva({
    required ItemEstoqueFornecedor item,
    required ReservaEstoqueFornecedor reserva,
  }) {
    if (reserva.status == StatusReservaEstoque.retirada) {
      return ResultadoOperacaoEstoque(
          item: item, reserva: reserva, idempotente: true);
    }
    if (reserva.status != StatusReservaEstoque.ativa) {
      throw StateError('Só reservas ativas podem ser retiradas.');
    }
    // Já estava comprometida na reserva: só muda status → em uso.
    final novoItem = item.natureza == NaturezaItemEstoque.consumivel
        ? item.copyWith(
            quantidadeReservada: (item.quantidadeReservada - reserva.quantidade)
                .clamp(0, 1 << 30),
            quantidadeEmUso: item.quantidadeEmUso + reserva.quantidade,
          )
        : item.copyWith(
            quantidadeEmUso: item.quantidadeEmUso + reserva.quantidade,
          );
    return ResultadoOperacaoEstoque(
      item: novoItem,
      reserva: ReservaEstoqueFornecedor(
        idReserva: reserva.idReserva,
        idItem: reserva.idItem,
        idFornecedor: reserva.idFornecedor,
        idEvento: reserva.idEvento,
        quantidade: reserva.quantidade,
        status: StatusReservaEstoque.retirada,
        intervaloEfetivo: reserva.intervaloEfetivo,
        chaveIdempotencia: reserva.chaveIdempotencia,
      ),
    );
  }

  /// Consumo atribui custo ao evento sem novo desembolso (estoque prévio).
  static ResultadoOperacaoEstoque consumir({
    required ItemEstoqueFornecedor item,
    required int quantidade,
    ReservaEstoqueFornecedor? reserva,
    bool jaProcessado = false,
  }) {
    if (jaProcessado) {
      return ResultadoOperacaoEstoque(
          item: item, reserva: reserva, idempotente: true);
    }
    if (quantidade <= 0) {
      throw ArgumentError('Quantidade de consumo inválida.');
    }

    ItemEstoqueFornecedor novo;
    ReservaEstoqueFornecedor? reservaAtualizada = reserva;

    if (reserva != null) {
      if (reserva.status == StatusReservaEstoque.consumida) {
        return ResultadoOperacaoEstoque(
          item: item,
          reserva: reserva,
          idempotente: true,
        );
      }
      if (reserva.quantidade != quantidade &&
          reserva.status == StatusReservaEstoque.ativa) {
        // consumo parcial da reserva não implementado: exige quantidade igual
        if (quantidade > reserva.quantidade) {
          throw StateError('Consumo maior que a reserva.');
        }
      }
      // Consome a partir da reserva: libera compromisso e reduz saldo uma vez.
      if (reserva.status == StatusReservaEstoque.ativa) {
        novo = item.copyWith(
          quantidadeTotal:
              (item.quantidadeTotal - quantidade).clamp(0, 1 << 30),
          quantidadeReservada:
              (item.quantidadeReservada - quantidade).clamp(0, 1 << 30),
        );
      } else if (reserva.status == StatusReservaEstoque.retirada) {
        // Já saiu do reservado para em_uso; só reduz total e em_uso.
        novo = item.copyWith(
          quantidadeTotal:
              (item.quantidadeTotal - quantidade).clamp(0, 1 << 30),
          quantidadeEmUso:
              (item.quantidadeEmUso - quantidade).clamp(0, 1 << 30),
        );
      } else {
        throw StateError('Reserva não pode ser consumida neste status.');
      }
      reservaAtualizada = ReservaEstoqueFornecedor(
        idReserva: reserva.idReserva,
        idItem: reserva.idItem,
        idFornecedor: reserva.idFornecedor,
        idEvento: reserva.idEvento,
        quantidade: reserva.quantidade,
        status: StatusReservaEstoque.consumida,
        intervaloEfetivo: reserva.intervaloEfetivo,
        chaveIdempotencia: reserva.chaveIdempotencia,
      );
    } else {
      if (quantidade > item.quantidadeDisponivelLivre) {
        throw StateError('Saldo livre insuficiente para consumo.');
      }
      novo = item.copyWith(
        quantidadeTotal: item.quantidadeTotal - quantidade,
      );
    }

    final custoUnit = _custoUnitarioAplicavel(item);
    final custoTotal = custoUnit * quantidade;
    final alertas = <AlertaEstoqueFornecedor>[];
    if (custoUnit <= 0) {
      alertas.add(AlertaEstoqueFornecedor(
        codigo: 'custo_ausente',
        mensagem:
            'Consumo físico registrado; custo aplicável ausente — financeiro incompleto.',
        idItem: item.idItem,
      ));
    }

    return ResultadoOperacaoEstoque(
      item: novo.copyWith(custoAusente: custoUnit <= 0),
      reserva: reservaAtualizada,
      custoAtribuidoCentavos:
          custoTotal.clamp(0, ValorMonetario.limiteCentavos),
      geraDesembolso: false,
      origemCusto: 'estoque_consumo',
      alertas: alertas,
    );
  }

  static int _custoUnitarioAplicavel(ItemEstoqueFornecedor item) {
    switch (item.natureza) {
      case NaturezaItemEstoque.consumivel:
        return item.custoMedioUnitarioCentavos;
      case NaturezaItemEstoque.reutilizavel:
        return item.custoUsoCentavos > 0
            ? item.custoUsoCentavos
            : item.custoMedioUnitarioCentavos;
      case NaturezaItemEstoque.locadoTerceiro:
        return item.custoLocacaoCentavos;
    }
  }

  static ResultadoOperacaoEstoque devolver({
    required ItemEstoqueFornecedor item,
    required ReservaEstoqueFornecedor reserva,
    bool jaProcessado = false,
  }) {
    if (jaProcessado || reserva.status == StatusReservaEstoque.devolvida) {
      return ResultadoOperacaoEstoque(
        item: item,
        reserva: reserva,
        idempotente: true,
      );
    }
    if (reserva.status != StatusReservaEstoque.retirada &&
        reserva.status != StatusReservaEstoque.ativa) {
      throw StateError('Devolução só para reserva ativa ou retirada.');
    }
    ItemEstoqueFornecedor novo;
    if (reserva.status == StatusReservaEstoque.retirada) {
      novo = item.copyWith(
        quantidadeEmUso:
            (item.quantidadeEmUso - reserva.quantidade).clamp(0, 1 << 30),
      );
    } else {
      // Libera reserva sem ter retirado.
      novo = item.natureza == NaturezaItemEstoque.consumivel
          ? item.copyWith(
              quantidadeReservada:
                  (item.quantidadeReservada - reserva.quantidade)
                      .clamp(0, 1 << 30),
            )
          : item;
    }
    return ResultadoOperacaoEstoque(
      item: novo,
      reserva: ReservaEstoqueFornecedor(
        idReserva: reserva.idReserva,
        idItem: reserva.idItem,
        idFornecedor: reserva.idFornecedor,
        idEvento: reserva.idEvento,
        quantidade: reserva.quantidade,
        status: StatusReservaEstoque.devolvida,
        intervaloEfetivo: reserva.intervaloEfetivo,
        chaveIdempotencia: reserva.chaveIdempotencia,
      ),
    );
  }

  /// Cancelamento libera apenas reservas ainda não consumidas/retiradas.
  static ResultadoOperacaoEstoque cancelarReserva({
    required ItemEstoqueFornecedor item,
    required ReservaEstoqueFornecedor reserva,
    bool jaProcessado = false,
  }) {
    if (jaProcessado || reserva.status == StatusReservaEstoque.cancelada) {
      return ResultadoOperacaoEstoque(
        item: item,
        reserva: reserva,
        idempotente: true,
      );
    }
    if (!reserva.status.podeCancelar) {
      throw StateError(
        'Cancelamento libera apenas reservas ainda não consumidas/retiradas.',
      );
    }
    final novo = item.natureza == NaturezaItemEstoque.consumivel
        ? item.copyWith(
            quantidadeReservada: (item.quantidadeReservada - reserva.quantidade)
                .clamp(0, 1 << 30),
          )
        : item;
    return ResultadoOperacaoEstoque(
      item: novo,
      reserva: ReservaEstoqueFornecedor(
        idReserva: reserva.idReserva,
        idItem: reserva.idItem,
        idFornecedor: reserva.idFornecedor,
        idEvento: reserva.idEvento,
        quantidade: reserva.quantidade,
        status: StatusReservaEstoque.cancelada,
        intervaloEfetivo: reserva.intervaloEfetivo,
        chaveIdempotencia: reserva.chaveIdempotencia,
      ),
    );
  }

  static ResultadoOperacaoEstoque registrarPerda({
    required ItemEstoqueFornecedor item,
    required int quantidade,
  }) {
    if (quantidade <= 0) {
      throw ArgumentError('Quantidade de perda inválida.');
    }
    if (quantidade > item.quantidadeDisponivelLivre) {
      throw StateError('Perda maior que o saldo livre.');
    }
    final custo = item.custoMedioUnitarioCentavos * quantidade;
    return ResultadoOperacaoEstoque(
      item: item.copyWith(
        quantidadeTotal: item.quantidadeTotal - quantidade,
      ),
      custoAtribuidoCentavos: custo.clamp(0, ValorMonetario.limiteCentavos),
      geraDesembolso: false,
      origemCusto: 'estoque_consumo',
      alertas: const [
        AlertaEstoqueFornecedor(
          codigo: 'perda',
          mensagem:
              'Perda registrada com custo atribuído; sem nova saída de caixa.',
        ),
      ],
    );
  }

  static List<AlertaEstoqueFornecedor> avaliarAlertas({
    required ItemEstoqueFornecedor item,
    required List<ReservaEstoqueFornecedor> reservas,
    DateTime? agora,
  }) {
    final now = agora ?? DateTime.now();
    final alertas = <AlertaEstoqueFornecedor>[];
    if (item.status == StatusFisicoItemEstoque.manutencao) {
      alertas.add(AlertaEstoqueFornecedor(
        codigo: 'manutencao',
        mensagem: '${item.nome} em manutenção — não disponível.',
        idItem: item.idItem,
      ));
    }
    if (item.validade != null && item.validade!.isBefore(now)) {
      alertas.add(AlertaEstoqueFornecedor(
        codigo: 'validade',
        mensagem: '${item.nome} vencido — não oferecido como disponível.',
        idItem: item.idItem,
        severidade: 'erro',
      ));
    }
    if (item.quantidadeDisponivelLivre <= 0 &&
        item.natureza == NaturezaItemEstoque.consumivel) {
      alertas.add(AlertaEstoqueFornecedor(
        codigo: 'compra_necessaria',
        mensagem: 'Sem saldo livre de ${item.nome}: compra necessária.',
        idItem: item.idItem,
      ));
    }
    if (item.natureza == NaturezaItemEstoque.locadoTerceiro &&
        item.quantidadeDisponivelLivre <= 0) {
      alertas.add(AlertaEstoqueFornecedor(
        codigo: 'locacao_necessaria',
        mensagem: 'Locação adicional necessária para ${item.nome}.',
        idItem: item.idItem,
      ));
    }
    if (item.financeiroIncompleto) {
      alertas.add(AlertaEstoqueFornecedor(
        codigo: 'custo_ausente',
        mensagem:
            'Custo ausente: financeiro incompleto (disponibilidade física ok).',
        idItem: item.idItem,
        severidade: 'info',
      ));
    }
    for (final r in reservas) {
      if (r.status == StatusReservaEstoque.retirada &&
          r.intervaloEfetivo.fim.isBefore(now)) {
        alertas.add(AlertaEstoqueFornecedor(
          codigo: 'devolucao',
          mensagem: 'Devolução pendente da reserva ${r.idReserva}.',
          idItem: item.idItem,
        ));
      }
    }
    return alertas;
  }
}
