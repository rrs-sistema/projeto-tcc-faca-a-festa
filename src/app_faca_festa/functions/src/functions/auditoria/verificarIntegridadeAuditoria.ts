import { onCall } from "firebase-functions/v2/https";

import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";
import { admin } from "../../shared/firebaseAdmin";
import { calcularHashIntegridadeAuditoria } from "./auditIntegrity";

const REGION = "southamerica-east1";
const LIMITE_PADRAO = 300;
const LIMITE_MAXIMO = 1000;

function limiteSeguro(value: unknown): number {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) return LIMITE_PADRAO;
  return Math.min(Math.floor(parsed), LIMITE_MAXIMO);
}

function texto(value: unknown): string {
  return String(value ?? "").trim();
}

/**
 * Verifica a integridade dos registros mais recentes de auditoria.
 * Apenas administradores podem executar esta rotina.
 */
export const verificarIntegridadeAuditoria = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
    cors: true,
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["A"]);

    const limite = limiteSeguro((request.data as Record<string, unknown> | undefined)?.limite);
    const snapshot = await admin
      .firestore()
      .collection("auditoria_eventos")
      .orderBy("criado_em", "desc")
      .limit(limite)
      .get();

    const invalidos: Array<{ id: string; motivo: string }> = [];
    const semHash: string[] = [];
    let validos = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const hashAtual = texto(data.hash_integridade);
      if (!hashAtual) {
        semHash.push(doc.id);
        continue;
      }

      const hashEsperado = calcularHashIntegridadeAuditoria(data);
      if (hashAtual === hashEsperado) {
        validos++;
      } else {
        invalidos.push({ id: doc.id, motivo: "hash_divergente" });
      }
    }

    return {
      ok: invalidos.length === 0 && semHash.length === 0,
      limite,
      total: snapshot.size,
      validos,
      sem_hash: semHash.length,
      invalidos: invalidos.length,
      amostras_sem_hash: semHash.slice(0, 20),
      amostras_invalidas: invalidos.slice(0, 20),
    };
  },
);
