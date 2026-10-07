export type TipoAviso = "convites" | "cotacoes" | "chat" | "avaliacoes";

type Firestore = FirebaseFirestore.Firestore;

function prefsDe(data: FirebaseFirestore.DocumentData | undefined): Record<string, unknown> | null {
  const bruto = data?.preferencias_notificacao;
  if (!bruto || typeof bruto !== "object") return null;
  return bruto as Record<string, unknown>;
}

/** Ausência de preferência mantém o aviso ligado. `false` explícito bloqueia. */
export function permiteAviso(
  data: FirebaseFirestore.DocumentData | undefined,
  tipo: TipoAviso,
): boolean {
  const prefs = prefsDe(data);
  if (!prefs) return true;
  return prefs[tipo] !== false;
}

export async function usuarioPermiteAviso(
  db: Firestore,
  idUsuario: string,
  tipo: TipoAviso,
): Promise<boolean> {
  if (!idUsuario) return true;
  const snap = await db.collection("usuarios").doc(idUsuario).get();
  return permiteAviso(snap.data(), tipo);
}

export async function emailPermiteConvite(
  db: Firestore,
  email: string,
): Promise<boolean> {
  const alvo = email.trim().toLowerCase();
  if (!alvo) return true;
  const snap = await db
    .collection("usuarios")
    .where("email", "==", alvo)
    .limit(1)
    .get();
  if (snap.empty) return true;
  return permiteAviso(snap.docs[0].data(), "convites");
}

export function prefsDesligadas() {
  return {
    convites: false,
    cotacoes: false,
    chat: false,
    avaliacoes: false,
  };
}
