import { randomUUID } from "crypto";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";
import { admin } from "../../shared/firebaseAdmin";

const REGION = "southamerica-east1";
const MAX_BYTES = 1_500_000;
const ID_TEMA = /^[A-Za-z0-9_-]{2,80}$/;

type CapaData = {
  idTema?: unknown;
  bytesBase64?: unknown;
};

export const enviarCapaTemaFesta = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
    cors: true,
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["A"]);

    const data = request.data as CapaData;
    const idTema = typeof data.idTema === "string" ? data.idTema.trim() : "";
    const bruto =
      typeof data.bytesBase64 === "string" ? data.bytesBase64.trim() : "";
    if (!ID_TEMA.test(idTema)) {
      throw new HttpsError("invalid-argument", "Tema inválido.");
    }
    if (!bruto) {
      throw new HttpsError("invalid-argument", "Envie a imagem da capa.");
    }

    let buffer: Buffer;
    try {
      buffer = Buffer.from(bruto, "base64");
    } catch {
      throw new HttpsError("invalid-argument", "Imagem inválida.");
    }
    if (buffer.length < 32 || buffer.length > MAX_BYTES) {
      throw new HttpsError(
        "invalid-argument",
        "A capa precisa ter no máximo 1,5 MB.",
      );
    }

    const path = `temas/${idTema}/capa.jpg`;
    const token = randomUUID();
    const bucket = bucketStorage();
    await bucket.file(path).save(buffer, {
      resumable: false,
      metadata: {
        contentType: "image/jpeg",
        cacheControl: "public,max-age=3600",
        metadata: {
          firebaseStorageDownloadTokens: token,
        },
      },
    });

    const url = urlDownload(bucket.name, path, token);
    await admin.firestore().collection("tema_festa").doc(idTema).set(
      {
        imagem_capa_url: url,
      },
      { merge: true },
    );

    return { url };
  },
);

export const removerCapaTemaFesta = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    cors: true,
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["A"]);

    const data = request.data as CapaData;
    const idTema = typeof data.idTema === "string" ? data.idTema.trim() : "";
    if (!ID_TEMA.test(idTema)) {
      throw new HttpsError("invalid-argument", "Tema inválido.");
    }

    try {
      await bucketStorage().file(`temas/${idTema}/capa.jpg`).delete();
    } catch (error) {
      const codigo =
        error && typeof error === "object" && "code" in error
          ? Number((error as { code: unknown }).code)
          : 0;
      if (codigo !== 404) {
        console.error("[removerCapaTemaFesta]", error);
        throw new HttpsError(
          "internal",
          "Não foi possível remover a capa agora.",
        );
      }
    }
    await admin.firestore().collection("tema_festa").doc(idTema).set(
      { imagem_capa_url: admin.firestore.FieldValue.delete() },
      { merge: true },
    );
    return { ok: true };
  },
);

function bucketStorage() {
  const nome =
    admin.app().options.storageBucket ||
    `${process.env.GCLOUD_PROJECT || "faca-a-festa"}.firebasestorage.app`;
  return admin.storage().bucket(nome);
}

function urlDownload(bucket: string, path: string, token: string): string {
  const objeto = encodeURIComponent(path);
  return `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${objeto}?alt=media&token=${token}`;
}
