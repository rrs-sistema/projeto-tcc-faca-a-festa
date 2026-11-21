/** Regras puras do Pix Asaas do organizador. Sem rede e sem Firestore. */

export const PREFIXO_REFERENCIA = "FESTA|";
export const LIMITE_CENTAVOS_PIX = 100_000_000;
export const LIMITE_PAGAMENTOS_CONTRATO = 2;

export type StatusPix = "APPROVED" | "PENDING" | "CANCELLED" | "REFUNDED" | "REJECTED";

export function cpfValido(valor: unknown): string | null {
  const digitos = String(valor ?? "").replace(/\D/g, "");
  if (digitos.length !== 11 || /^(\d)\1{10}$/.test(digitos)) return null;
  const digito = (base: string, fatorInicial: number): number => {
    let soma = 0;
    for (let i = 0; i < base.length; i++) {
      soma += Number(base[i]) * (fatorInicial - i);
    }
    const resto = (soma * 10) % 11;
    return resto === 10 ? 0 : resto;
  };
  if (digito(digitos.slice(0, 9), 10) !== Number(digitos[9])) return null;
  if (digito(digitos.slice(0, 10), 11) !== Number(digitos[10])) return null;
  return digitos;
}

export function valorContratadoDoOrcamento(d: Record<string, unknown>): number {
  const direto = Number(d.valor_contratado_centavos ?? 0);
  if (Number.isInteger(direto) && direto > 0) return direto;
  const reais = Number(d.valor_contratado ?? d.valor ?? 0);
  if (Number.isFinite(reais) && reais > 0) return Math.round(reais * 100);
  return 0;
}

export function valorCobradoCentavos(
  solicitado: number | null,
  aPagarCentavos: number,
): { ok: true; centavos: number } | { ok: false; motivo: string } {
  if (!Number.isInteger(aPagarCentavos) || aPagarCentavos <= 0) {
    return { ok: false, motivo: "Não há valor pendente para pagar à plataforma." };
  }
  const valor = solicitado == null ? aPagarCentavos : solicitado;
  if (!Number.isInteger(valor) || valor <= 0) {
    return { ok: false, motivo: "Informe o valor do Pix em centavos." };
  }
  if (valor > LIMITE_CENTAVOS_PIX) {
    return { ok: false, motivo: "Valor acima do limite de cobrança." };
  }
  if (valor > aPagarCentavos) {
    return {
      ok: false,
      motivo: "O valor do Pix não pode passar do que ainda falta pagar.",
    };
  }
  return { ok: true, centavos: valor };
}

/** Data de vencimento no fuso de Brasília, sem horário de verão. */
export function vencimentoPix(agora = new Date()): { dueDate: string; expiraEm: Date } {
  const brasil = new Date(agora.getTime() - 3 * 60 * 60 * 1000);
  const base = new Date(Date.UTC(
    brasil.getUTCFullYear(),
    brasil.getUTCMonth(),
    brasil.getUTCDate(),
  ));
  if (brasil.getUTCHours() >= 18) base.setUTCDate(base.getUTCDate() + 1);
  return {
    dueDate: base.toISOString().slice(0, 10),
    expiraEm: new Date(agora.getTime() + 12 * 60 * 60 * 1000),
  };
}

export function referenciaExterna(idOrcamento: string, cobrancaId: string): string {
  return `${PREFIXO_REFERENCIA}${idOrcamento}|${cobrancaId}`;
}

export function lerReferenciaExterna(
  ref: string,
): { idOrcamento: string; cobrancaId: string } | null {
  if (!ref.startsWith(PREFIXO_REFERENCIA)) return null;
  const partes = ref.split("|");
  if (partes.length !== 3 || !partes[1] || !partes[2]) return null;
  if (partes[1].includes("/") || partes[2].includes("/")) return null;
  return { idOrcamento: partes[1], cobrancaId: partes[2] };
}

export function referenciaDesteProduto(ref: string): boolean {
  return ref.startsWith(PREFIXO_REFERENCIA);
}

export function mapearStatusAsaas(status: string): StatusPix {
  switch (String(status ?? "").toUpperCase().trim()) {
    case "RECEIVED":
    case "CONFIRMED":
    case "RECEIVED_IN_CASH":
      return "APPROVED";
    case "REFUNDED":
    case "REFUND_REQUESTED":
    case "CHARGEBACK_REQUESTED":
    case "CHARGEBACK_DISPUTE":
    case "AWAITING_CHARGEBACK_REVERSAL":
      return "REFUNDED";
    case "DELETED":
    case "CANCELED":
    case "CANCELLED":
      return "CANCELLED";
    case "REFUSED":
    case "REJECTED":
      return "REJECTED";
    default:
      return "PENDING";
  }
}

export function centavosDeValorAsaas(valor: unknown): number | null {
  const n = typeof valor === "number"
    ? valor
    : typeof valor === "string" && valor.trim()
      ? Number(valor)
      : NaN;
  if (!Number.isFinite(n) || n < 0) return null;
  const centavos = Math.round((n + Number.EPSILON) * 100);
  if (Math.abs(centavos / 100 - n) > 0.001) return null;
  if (!Number.isSafeInteger(centavos)) return null;
  return centavos;
}

export function cobrancaConfere(params: {
  valorEsperadoCentavos: number;
  valorPago: unknown;
  referenciaEsperada: string;
  referenciaRecebida: string;
  pagamentoIdEsperado: string;
  pagamentoIdRecebido: string;
}): { ok: true } | { ok: false; motivo: string } {
  if (!params.referenciaRecebida || params.referenciaRecebida !== params.referenciaEsperada) {
    return { ok: false, motivo: "Cobrança não corresponde ao contrato." };
  }
  if (
    params.pagamentoIdEsperado &&
    params.pagamentoIdRecebido !== params.pagamentoIdEsperado
  ) {
    return { ok: false, motivo: "Identificador do pagamento não confere." };
  }
  const pago = centavosDeValorAsaas(params.valorPago);
  if (pago == null || pago !== params.valorEsperadoCentavos) {
    return { ok: false, motivo: "Valor pago diferente do Pix gerado." };
  }
  return { ok: true };
}

export function reaisDeCentavos(centavos: number): number {
  return Number((centavos / 100).toFixed(2));
}

/** O que a plataforma confirmou nunca passa do valor contratado. */
export function confirmadoLimitado(contratadoCentavos: number, alocadoCentavos: number): number {
  const teto = Number.isInteger(contratadoCentavos) && contratadoCentavos > 0
    ? contratadoCentavos
    : 0;
  const alocado = Number.isInteger(alocadoCentavos) && alocadoCentavos > 0
    ? alocadoCentavos
    : 0;
  return Math.min(alocado, teto);
}

/**
 * Percentual citado na condição do fornecedor, como "20% de entrada".
 * É garantia sugerida, não mínimo obrigatório. 100% não conta como entrada.
 */
export function entradaSugerida(
  condicao: string | null | undefined,
  contratadoCentavos: number,
): { percentual: number; centavos: number } | null {
  if (!condicao || !Number.isInteger(contratadoCentavos) || contratadoCentavos <= 0) {
    return null;
  }
  const encontrado = condicao.match(/(\d{1,2})\s*%/);
  if (!encontrado) return null;
  const percentual = Number(encontrado[1]);
  if (!Number.isInteger(percentual) || percentual <= 0 || percentual >= 100) return null;
  const centavos = Math.round((contratadoCentavos * percentual) / 100);
  if (centavos <= 0 || centavos >= contratadoCentavos) return null;
  return { percentual, centavos };
}
