const fs = require("fs");
const path = require("path");

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const { doc, setDoc, updateDoc, Timestamp } = require("firebase/firestore");

const projectId = "faca-festa-presentes-rules";
const EVENTO = "evento-org-1";

function convidadoDb(env, uid, idConvidado) {
  return env.authenticatedContext(uid, {
    email: `${uid}@faca.test`,
    papel: "C",
    idEvento: EVENTO,
    idConvidado,
  }).firestore();
}

function reserva(idConvidado, nome) {
  return {
    reservado_por: nome,
    id_convidado: idConvidado,
    data_reserva: Timestamp.now(),
  };
}

async function run() {
  const env = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, "../../firestore.rules"),
        "utf8",
      ),
      host: "127.0.0.1",
      port: 8080,
    },
  });

  try {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "usuarios/org-1"), { tipo: "O", ativo: true });
      await setDoc(doc(db, `evento/${EVENTO}`), {
        id_evento: EVENTO,
        id_usuario: "org-1",
      });
      for (const id of ["livre", "vazio", "outro"]) {
        await setDoc(doc(db, `evento/${EVENTO}/presentes/${id}`), {
          nome: id,
          status: "disponivel",
          reservado_por: id === "vazio" ? "" : null,
        });
      }
    });

    const ana = convidadoDb(env, "c_ana", "conv-ana");
    const beto = convidadoDb(env, "c_beto", "conv-beto");
    const presente = (db, id) => doc(db, `evento/${EVENTO}/presentes/${id}`);

    await assertSucceeds(updateDoc(presente(ana, "livre"), reserva("conv-ana", "Ana")));
    await assertSucceeds(updateDoc(presente(ana, "vazio"), reserva("conv-ana", "Ana")));
    // A mesma reserva reenviada ao reconectar continua aceita.
    await assertSucceeds(updateDoc(presente(ana, "livre"), reserva("conv-ana", "Ana")));

    // Duas reservas offline do mesmo presente: a segunda a chegar é recusada.
    await assertSucceeds(updateDoc(presente(beto, "outro"), reserva("conv-beto", "Beto")));
    await assertFails(updateDoc(presente(ana, "outro"), reserva("conv-ana", "Ana")));
    await assertFails(updateDoc(presente(beto, "livre"), reserva("conv-beto", "Beto")));

    // O convidado continua sem poder mexer em outros campos.
    await assertFails(updateDoc(presente(ana, "livre"), { status: "comprado" }));

    console.log("Presentes Firestore rules: OK");
  } finally {
    await env.cleanup();
  }
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
