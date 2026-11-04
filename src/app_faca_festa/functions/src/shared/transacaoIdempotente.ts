import { Firestore, Transaction } from "firebase-admin/firestore";

/** Reinicia somente transações invalidadas/expiradas pelo servidor.
 * O callback deve conter apenas escritas transacionais e identidade idempotente.
 * Outros erros (inclusive validação/autorização) são preservados.
 */
export async function transacaoIdempotente<T>(db: Firestore, executar: (tx: Transaction) => Promise<T>): Promise<T> {
  for (let tentativa = 0; ; tentativa++) {
    try { return await db.runTransaction(executar); }
    catch (e) {
      const erro = e as { code?: unknown; message?: string; details?: string };
      if (tentativa >= 2 || erro.code !== 3 || !/transaction (is invalid or closed|has expired)/i.test(erro.details || erro.message || "")) throw e;
      await new Promise(resolve => setTimeout(resolve, 100 * (tentativa + 1)));
    }
  }
}
