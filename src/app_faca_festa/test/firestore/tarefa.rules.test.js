const fs = require("fs");
const path = require("path");

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  deleteDoc,
  where,
} = require("firebase/firestore");

const projectId = "faca-festa-tarefa-rules";

function authedDb(env, uid, extras = {}) {
  return env.authenticatedContext(uid, {
    email: `${uid}@faca.test`,
    ...extras,
  }).firestore();
}

async function seed(env) {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, "usuarios/admin-1"), {
      tipo: "A",
      ativo: true,
      nome: "Admin",
    });
    await setDoc(doc(db, "usuarios/org-1"), {
      tipo: "O",
      ativo: true,
      nome: "Organizador",
    });
    await setDoc(doc(db, "usuarios/org-2"), {
      tipo: "O",
      ativo: true,
      nome: "Outro organizador",
    });
    await setDoc(doc(db, "usuarios/guest-1"), {
      tipo: "C",
      ativo: true,
      nome: "Silvio",
    });
    await setDoc(doc(db, "usuarios/guest-2"), {
      tipo: "C",
      ativo: true,
      nome: "Outro convidado",
    });

    await setDoc(doc(db, "evento/evento-org-1"), {
      id_evento: "evento-org-1",
      id_usuario: "org-1",
      nome_evento: "Baile de máscaras",
    });

    await setDoc(doc(db, "convidado/convidado-silvio"), {
      id_convidado: "convidado-silvio",
      id_evento: "evento-org-1",
      id_usuario: "guest-1",
      nome: "Silvio",
    });
    await setDoc(doc(db, "convidado/convidado-outro"), {
      id_convidado: "convidado-outro",
      id_evento: "evento-org-1",
      id_usuario: "guest-2",
      nome: "Outro",
    });

    await setDoc(doc(db, "tarefa/tarefa-silvio"), {
      id_tarefa: "tarefa-silvio",
      id_evento: "evento-org-1",
      id_responsavel: "convidado-silvio",
      titulo: "Cotação para o vestido",
      status: "a_fazer",
    });
    await setDoc(doc(db, "tarefa/tarefa-outro"), {
      id_tarefa: "tarefa-outro",
      id_evento: "evento-org-1",
      id_responsavel: "convidado-outro",
      titulo: "Fazer cotação das chacaras",
      status: "concluida",
    });
  });
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
    await seed(env);

    const adminDb = authedDb(env, "admin-1");
    const organizerDb = authedDb(env, "org-1");
    const otherOrganizerDb = authedDb(env, "org-2");
    const guestDb = authedDb(env, "guest-1");
    const otherGuestDb = authedDb(env, "guest-2");
    const visitorDb = authedDb(env, "c_visitante", {
      papel: "C",
      idConvidado: "convidado-silvio",
      idEvento: "evento-org-1",
      conviteToken: "cf89bbba-55fc-4db8",
    });
    const anonDb = env.unauthenticatedContext().firestore();

    await assertSucceeds(getDoc(doc(organizerDb, "tarefa/tarefa-silvio")));
    await assertSucceeds(getDoc(doc(organizerDb, "tarefa/tarefa-outro")));
    await assertSucceeds(
      getDocs(
        query(
          collection(organizerDb, "tarefa"),
          where("id_evento", "==", "evento-org-1"),
        ),
      ),
    );

    await assertFails(getDoc(doc(otherOrganizerDb, "tarefa/tarefa-silvio")));
    await assertFails(getDoc(doc(anonDb, "tarefa/tarefa-silvio")));

    await assertSucceeds(getDoc(doc(guestDb, "tarefa/tarefa-silvio")));
    await assertFails(getDoc(doc(guestDb, "tarefa/tarefa-outro")));
    await assertFails(
      getDocs(
        query(
          collection(guestDb, "tarefa"),
          where("id_evento", "==", "evento-org-1"),
        ),
      ),
    );
    await assertSucceeds(
      getDocs(
        query(
          collection(guestDb, "tarefa"),
          where("id_evento", "==", "evento-org-1"),
          where("id_responsavel", "==", "convidado-silvio"),
        ),
      ),
    );

    await assertSucceeds(getDoc(doc(visitorDb, "tarefa/tarefa-silvio")));
    await assertFails(getDoc(doc(visitorDb, "tarefa/tarefa-outro")));

    await assertSucceeds(
      updateDoc(doc(guestDb, "tarefa/tarefa-silvio"), { status: "em_andamento" }),
    );
    await assertFails(
      updateDoc(doc(guestDb, "tarefa/tarefa-silvio"), {
        titulo: "Não pode alterar o título",
      }),
    );
    await assertFails(
      updateDoc(doc(otherGuestDb, "tarefa/tarefa-silvio"), {
        status: "concluida",
      }),
    );
    await assertFails(
      updateDoc(doc(visitorDb, "tarefa/tarefa-silvio"), {
        status: "em_andamento",
      }),
    );

    await assertFails(deleteDoc(doc(guestDb, "tarefa/tarefa-silvio")));
    await assertFails(
      setDoc(doc(guestDb, "tarefa/tarefa-nova"), {
        id_tarefa: "tarefa-nova",
        id_evento: "evento-org-1",
        id_responsavel: "convidado-silvio",
        titulo: "Criada pelo convidado",
        status: "a_fazer",
      }),
    );

    await assertSucceeds(
      setDoc(doc(organizerDb, "tarefa/tarefa-org"), {
        id_tarefa: "tarefa-org",
        id_evento: "evento-org-1",
        id_responsavel: "convidado-silvio",
        titulo: "Criada pelo anfitrião",
        status: "a_fazer",
      }),
    );
    await assertSucceeds(getDoc(doc(adminDb, "tarefa/tarefa-org")));

    console.log("Tarefa Firestore rules: OK");
  } finally {
    await env.cleanup();
  }
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
