/**
 * Estoque empresarial do fornecedor (privado).
 * Distinto do estoque alimentar da calculadora (lotes por evento/refeição).
 * Valorização gerencial: custo médio móvel; FEFO físico não altera o método.
 */

export type NaturezaItem = "consumivel" | "reutilizavel" | "locado_terceiro";
export type StatusFisico = "disponivel" | "manutencao" | "vencido" | "inativo";
export type StatusReserva =
  | "ativa"
  | "retirada"
  | "consumida"
  | "devolvida"
  | "cancelada"
  | "perdida";

export interface Intervalo {
  inicio: Date;
  fim: Date;
}

export interface ItemEstoque {
  idItem: string;
  idFornecedor: string;
  nome: string;
  natureza: NaturezaItem;
  quantidadeTotal: number;
  quantidadeReservada: number;
  quantidadeEmUso: number;
  status: StatusFisico;
  custoMedioUnitarioCentavos: number;
  custoUsoCentavos: number;
  custoLocacaoCentavos: number;
  montagemMinutos: number;
  transporteMinutos: number;
  desmontagemMinutos: number;
  custoAusente?: boolean;
}

export interface ReservaEstoque {
  idReserva: string;
  idItem: string;
  idFornecedor: string;
  idEvento: string;
  quantidade: number;
  status: StatusReserva;
  intervaloEfetivo: Intervalo;
  chaveIdempotencia?: string;
}

export const LIMITE_INTERVALO_DIAS = 30;

export function ofereceDisponibilidade(status: StatusFisico): boolean {
  return status === "disponivel";
}

export function overlaps(a: Intervalo, b: Intervalo): boolean {
  return a.inicio < b.fim && b.inicio < a.fim;
}

export function intervaloEfetivo(
  inicio: Date,
  fim: Date,
  item: ItemEstoque,
): Intervalo {
  if (!(fim > inicio)) {
    throw new Error("Intervalo inválido: fim deve ser após início.");
  }
  const dias = (fim.getTime() - inicio.getTime()) / (24 * 60 * 60 * 1000);
  if (dias > LIMITE_INTERVALO_DIAS) {
    throw new Error(`Intervalo excede o limite de ${LIMITE_INTERVALO_DIAS} dias.`);
  }
  const pre = (item.montagemMinutos + item.transporteMinutos) * 60_000;
  const pos = (item.desmontagemMinutos + item.transporteMinutos) * 60_000;
  return {
    inicio: new Date(inicio.getTime() - pre),
    fim: new Date(fim.getTime() + pos),
  };
}

export function quantidadeLivre(item: ItemEstoque): number {
  if (!ofereceDisponibilidade(item.status)) return 0;
  return Math.max(
    0,
    item.quantidadeTotal - item.quantidadeReservada - item.quantidadeEmUso,
  );
}

export function capacidadeNoIntervalo(
  item: ItemEstoque,
  intervalo: Intervalo,
  reservas: ReservaEstoque[],
): number {
  if (!ofereceDisponibilidade(item.status)) return 0;
  if (item.natureza === "consumivel") return quantidadeLivre(item);
  let comprometido = 0;
  for (const r of reservas) {
    if (r.idItem !== item.idItem) continue;
    if (r.status !== "ativa" && r.status !== "retirada") continue;
    if (overlaps(r.intervaloEfetivo, intervalo)) {
      comprometido += r.quantidade;
    }
  }
  return Math.max(0, item.quantidadeTotal - comprometido);
}

/** Custo médio móvel gerencial. */
export function custoMedioAposEntrada(
  saldoAnterior: number,
  cmpCentavosAnterior: number,
  quantidadeEntrada: number,
  custoUnitarioEntradaCentavos: number,
): number {
  if (quantidadeEntrada <= 0) throw new Error("Quantidade de entrada inválida.");
  if (custoUnitarioEntradaCentavos < 0) throw new Error("Custo unitário inválido.");
  const total =
    saldoAnterior * cmpCentavosAnterior +
    quantidadeEntrada * custoUnitarioEntradaCentavos;
  return Math.round(total / (saldoAnterior + quantidadeEntrada));
}

export function reservar(params: {
  item: ItemEstoque;
  idReserva: string;
  idEvento: string;
  quantidade: number;
  intervalo: Intervalo;
  reservasAtivas: ReservaEstoque[];
  chaveIdempotencia?: string;
  existenteMesmaChave?: ReservaEstoque | null;
}): { item: ItemEstoque; reserva: ReservaEstoque; idempotente?: boolean } {
  const {
    item,
    idReserva,
    idEvento,
    quantidade,
    intervalo,
    reservasAtivas,
    chaveIdempotencia,
    existenteMesmaChave,
  } = params;
  if (existenteMesmaChave) {
    return { item, reserva: existenteMesmaChave, idempotente: true };
  }
  if (!ofereceDisponibilidade(item.status)) {
    throw Object.assign(
      new Error("Item vencido ou em manutenção não é oferecido como disponível."),
      { code: "failed-precondition" },
    );
  }
  if (quantidade <= 0) throw new Error("Quantidade de reserva inválida.");
  const livre = capacidadeNoIntervalo(item, intervalo, reservasAtivas);
  if (quantidade > livre) {
    throw Object.assign(
      new Error(
        `Saldo insuficiente para reserva concorrente (disponível ${livre}, solicitado ${quantidade}).`,
      ),
      { code: "failed-precondition" },
    );
  }
  const reserva: ReservaEstoque = {
    idReserva,
    idItem: item.idItem,
    idFornecedor: item.idFornecedor,
    idEvento,
    quantidade,
    status: "ativa",
    intervaloEfetivo: intervalo,
    chaveIdempotencia,
  };
  const novo: ItemEstoque =
    item.natureza === "consumivel"
      ? {
          ...item,
          quantidadeReservada: item.quantidadeReservada + quantidade,
        }
      : { ...item };
  return { item: novo, reserva };
}

/** Retirada não desconta novamente a disponibilidade já comprometida. */
export function retirarDeReserva(
  item: ItemEstoque,
  reserva: ReservaEstoque,
): { item: ItemEstoque; reserva: ReservaEstoque; idempotente?: boolean } {
  if (reserva.status === "retirada") {
    return { item, reserva, idempotente: true };
  }
  if (reserva.status !== "ativa") {
    throw Object.assign(new Error("Só reservas ativas podem ser retiradas."), {
      code: "failed-precondition",
    });
  }
  let novo: ItemEstoque;
  if (item.natureza === "consumivel") {
    novo = {
      ...item,
      quantidadeReservada: Math.max(
        0,
        item.quantidadeReservada - reserva.quantidade,
      ),
      quantidadeEmUso: item.quantidadeEmUso + reserva.quantidade,
    };
  } else {
    novo = {
      ...item,
      quantidadeEmUso: item.quantidadeEmUso + reserva.quantidade,
    };
  }
  return {
    item: novo,
    reserva: { ...reserva, status: "retirada" },
  };
}

export function consumir(params: {
  item: ItemEstoque;
  quantidade: number;
  reserva?: ReservaEstoque | null;
  jaProcessado?: boolean;
}): {
  item: ItemEstoque;
  reserva?: ReservaEstoque;
  custoAtribuidoCentavos: number;
  origemCusto: "estoque_consumo";
  geraDesembolso: false;
  idempotente?: boolean;
} {
  const { item, quantidade, reserva, jaProcessado } = params;
  if (jaProcessado) {
    return {
      item,
      reserva: reserva ?? undefined,
      custoAtribuidoCentavos: 0,
      origemCusto: "estoque_consumo",
      geraDesembolso: false,
      idempotente: true,
    };
  }
  if (quantidade <= 0) throw new Error("Quantidade de consumo inválida.");

  let novo: ItemEstoque;
  let reservaAtualizada: ReservaEstoque | undefined;

  if (reserva) {
    if (reserva.status === "consumida") {
      return {
        item,
        reserva,
        custoAtribuidoCentavos: 0,
        origemCusto: "estoque_consumo",
        geraDesembolso: false,
        idempotente: true,
      };
    }
    if (quantidade > reserva.quantidade) {
      throw Object.assign(new Error("Consumo maior que a reserva."), {
        code: "failed-precondition",
      });
    }
    if (reserva.status === "ativa") {
      novo = {
        ...item,
        quantidadeTotal: Math.max(0, item.quantidadeTotal - quantidade),
        quantidadeReservada: Math.max(0, item.quantidadeReservada - quantidade),
      };
    } else if (reserva.status === "retirada") {
      novo = {
        ...item,
        quantidadeTotal: Math.max(0, item.quantidadeTotal - quantidade),
        quantidadeEmUso: Math.max(0, item.quantidadeEmUso - quantidade),
      };
    } else {
      throw Object.assign(
        new Error("Reserva não pode ser consumida neste status."),
        { code: "failed-precondition" },
      );
    }
    reservaAtualizada = { ...reserva, status: "consumida" };
  } else {
    if (quantidade > quantidadeLivre(item)) {
      throw Object.assign(new Error("Saldo livre insuficiente para consumo."), {
        code: "failed-precondition",
      });
    }
    novo = {
      ...item,
      quantidadeTotal: item.quantidadeTotal - quantidade,
    };
  }

  const unit = custoUnitarioAplicavel(item);
  return {
    item: novo,
    reserva: reservaAtualizada,
    custoAtribuidoCentavos: Math.max(0, unit * quantidade),
    origemCusto: "estoque_consumo",
    geraDesembolso: false,
  };
}

function custoUnitarioAplicavel(item: ItemEstoque): number {
  if (item.natureza === "locado_terceiro") return item.custoLocacaoCentavos;
  if (item.natureza === "reutilizavel") {
    return item.custoUsoCentavos > 0
      ? item.custoUsoCentavos
      : item.custoMedioUnitarioCentavos;
  }
  return item.custoMedioUnitarioCentavos;
}

export function cancelarReserva(
  item: ItemEstoque,
  reserva: ReservaEstoque,
  jaProcessado = false,
): { item: ItemEstoque; reserva: ReservaEstoque; idempotente?: boolean } {
  if (jaProcessado || reserva.status === "cancelada") {
    return { item, reserva, idempotente: true };
  }
  if (reserva.status !== "ativa") {
    throw Object.assign(
      new Error(
        "Cancelamento libera apenas reservas ainda não consumidas/retiradas.",
      ),
      { code: "failed-precondition" },
    );
  }
  const novo =
    item.natureza === "consumivel"
      ? {
          ...item,
          quantidadeReservada: Math.max(
            0,
            item.quantidadeReservada - reserva.quantidade,
          ),
        }
      : { ...item };
  return { item: novo, reserva: { ...reserva, status: "cancelada" } };
}

export function devolverReserva(
  item: ItemEstoque,
  reserva: ReservaEstoque,
  jaProcessado = false,
): { item: ItemEstoque; reserva: ReservaEstoque; idempotente?: boolean } {
  if (jaProcessado || reserva.status === "devolvida") {
    return { item, reserva, idempotente: true };
  }
  if (reserva.status !== "retirada" && reserva.status !== "ativa") {
    throw Object.assign(
      new Error("Devolução só para reserva ativa ou retirada."),
      { code: "failed-precondition" },
    );
  }
  let novo: ItemEstoque;
  if (reserva.status === "retirada") {
    novo = {
      ...item,
      quantidadeEmUso: Math.max(0, item.quantidadeEmUso - reserva.quantidade),
    };
  } else if (item.natureza === "consumivel") {
    novo = {
      ...item,
      quantidadeReservada: Math.max(
        0,
        item.quantidadeReservada - reserva.quantidade,
      ),
    };
  } else {
    novo = { ...item };
  }
  return { item: novo, reserva: { ...reserva, status: "devolvida" } };
}
