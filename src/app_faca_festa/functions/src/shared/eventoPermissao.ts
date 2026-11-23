import { HttpsError } from "firebase-functions/v2/https";
import { DocumentData, Firestore, Transaction } from "firebase-admin/firestore";

/** Máximo de co-organizadores por evento (além do dono). */
export const MAX_CO_ORGANIZADORES = 3;

export type EventoPermissao = {
  id: string;
  data: DocumentData;
  idUsuario: string;
  coOrganizadores: string[];
};

function texto(valor: unknown): string {
  return typeof valor === "string" ? valor.trim() : "";
}

function listarUids(valor: unknown): string[] {
  if (!Array.isArray(valor)) return [];
  const vistos = new Set<string>();
  const saida: string[] = [];
  for (const item of valor) {
    const uid = texto(item);
    if (!uid || vistos.has(uid)) continue;
    vistos.add(uid);
    saida.push(uid);
  }
  return saida;
}

export function coOrganizadoresDoEvento(data: DocumentData | undefined): string[] {
  return listarUids(data?.co_organizadores);
}

export function donoDoEvento(data: DocumentData | undefined): string {
  return texto(data?.id_usuario ?? data?.idUsuario ?? data?.usuarioId);
}

export function ehDonoNosDados(data: DocumentData | undefined, uid: string): boolean {
  const dono = donoDoEvento(data);
  return !!dono && dono === uid;
}

export function ehGestorNosDados(data: DocumentData | undefined, uid: string): boolean {
  if (!uid) return false;
  if (ehDonoNosDados(data, uid)) return true;
  return coOrganizadoresDoEvento(data).includes(uid);
}

export async function carregarEvento(
  db: Firestore,
  idEvento: string,
): Promise<EventoPermissao> {
  const id = texto(idEvento);
  if (!id) {
    throw new HttpsError("invalid-argument", "Informe o evento.");
  }
  const snap = await db.collection("evento").doc(id).get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Evento não encontrado.");
  }
  const data = snap.data() ?? {};
  return {
    id: snap.id,
    data,
    idUsuario: donoDoEvento(data),
    coOrganizadores: coOrganizadoresDoEvento(data),
  };
}

export async function carregarEventoTx(
  db: Firestore,
  tx: Transaction,
  idEvento: string,
): Promise<EventoPermissao> {
  const id = texto(idEvento);
  if (!id) {
    throw new HttpsError("invalid-argument", "Informe o evento.");
  }
  const snap = await tx.get(db.collection("evento").doc(id));
  if (!snap.exists) {
    throw new HttpsError("not-found", "Evento não encontrado.");
  }
  const data = snap.data() ?? {};
  return {
    id: snap.id,
    data,
    idUsuario: donoDoEvento(data),
    coOrganizadores: coOrganizadoresDoEvento(data),
  };
}

export async function exigirDonoEvento(
  db: Firestore,
  uid: string,
  idEvento: string,
): Promise<EventoPermissao> {
  const evento = await carregarEvento(db, idEvento);
  if (!ehDonoNosDados(evento.data, uid)) {
    throw new HttpsError(
      "permission-denied",
      "Somente o dono do evento pode realizar esta ação.",
    );
  }
  return evento;
}

export async function exigirGestorEvento(
  db: Firestore,
  uid: string,
  idEvento: string,
): Promise<EventoPermissao> {
  const evento = await carregarEvento(db, idEvento);
  if (!ehGestorNosDados(evento.data, uid)) {
    throw new HttpsError(
      "permission-denied",
      "Você não tem permissão para gerir este evento.",
    );
  }
  return evento;
}

export async function ehGestorEvento(
  db: Firestore,
  uid: string,
  idEvento: string,
): Promise<boolean> {
  try {
    const evento = await carregarEvento(db, idEvento);
    return ehGestorNosDados(evento.data, uid);
  } catch (erro) {
    if (erro instanceof HttpsError && erro.code === "not-found") return false;
    throw erro;
  }
}

export async function ehGestorEventoTx(
  db: Firestore,
  tx: Transaction,
  uid: string,
  idEvento: string,
): Promise<boolean> {
  try {
    const evento = await carregarEventoTx(db, tx, idEvento);
    return ehGestorNosDados(evento.data, uid);
  } catch (erro) {
    if (erro instanceof HttpsError && erro.code === "not-found") return false;
    throw erro;
  }
}
