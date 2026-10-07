import { onSchedule } from "firebase-functions/v2/scheduler";
import { Timestamp } from "firebase-admin/firestore";
import { logger } from "firebase-functions";

import { admin } from "../../shared/firebaseAdmin";

const REGION = "southamerica-east1";
const RETENCAO_MS = 365 * 24 * 60 * 60 * 1000;
const LOTE = 400;

export const expurgarAuditoriaAntiga = onSchedule(
  {
    schedule: "every day 03:00",
    timeZone: "America/Sao_Paulo",
    region: REGION,
    timeoutSeconds: 300,
    memory: "256MiB",
  },
  async () => {
    const db = admin.firestore();
    const limite = Timestamp.fromDate(new Date(Date.now() - RETENCAO_MS));
    const snap = await db
      .collection("auditoria_eventos")
      .where("criado_em", "<", limite)
      .limit(LOTE)
      .get();

    if (snap.empty) {
      logger.info("Nenhum log de auditoria fora do prazo de 365 dias.");
      return;
    }

    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    logger.info("Logs de auditoria expurgados", { total: snap.size });
  },
);
