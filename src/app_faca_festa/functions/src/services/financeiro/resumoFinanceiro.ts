/**
 * Resumo por evento: alternativas da mesma necessidade não somam obrigação.
 */
export type Compromisso = Record<string, unknown>;

export type ResumoFinanceiro = {
  estimado: number;
  cotado: number;
  contratado: number;
  pagoLiquido: number;
  saldoDevido: number;
  completo: boolean;
};

export function calcularResumo(compromissos: Compromisso[]): ResumoFinanceiro {
  let estimado = 0;
  let cotado = 0;
  let contratado = 0;
  let pagoLiquido = 0;
  let saldoDevido = 0;
  let completo = true;

  const grupos = new Map<string, Compromisso[]>();
  for (const c of compromissos) {
    const chave = String(c.id_necessidade ?? c.id ?? "");
    const lista = grupos.get(chave) ?? [];
    lista.push(c);
    grupos.set(chave, lista);
  }

  for (const grupo of grupos.values()) {
    let est = 0;
    let cot = 0;
    for (const c of grupo) {
      if (c.financeiro_valido === false || c.consulta_sincronizada === false) {
        completo = false;
      }
      const e = numero(c.estimado);
      const q = numero(c.cotado);
      if (e > est) est = e;
      if (q > cot) cot = q;
      if (c.contratado === true) {
        const vc = numero(c.valor_contratado ?? c.valor);
        contratado += vc;
        const pl = numero(c.pago, true);
        pagoLiquido += pl;
        if (typeof c.saldo_devido === "number" && Number.isFinite(c.saldo_devido)) {
          saldoDevido += c.saldo_devido;
        } else {
          saldoDevido += vc - pl;
        }
      } else {
        pagoLiquido += numero(c.pago, true);
      }
    }
    estimado += est;
    cotado += cot;
  }

  return { estimado, cotado, contratado, pagoLiquido, saldoDevido, completo };
}

function numero(v: unknown, permiteNegativo = false): number {
  if (typeof v !== "number" || !Number.isFinite(v)) {
    return 0;
  }
  if (v < 0 && !permiteNegativo) return 0;
  return v;
}
