const fs = require("fs");
const path = require("path");

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  setDoc,
  updateDoc,
  where,
} = require("firebase/firestore");

const projectId = "faca-festa-auditoria-rules";

function authedDb(env, uid, tipo) {
  return env.authenticatedContext(uid, {
    email: `${uid}@faca.test`,
    tipo,
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
    await setDoc(doc(db, "usuarios/forn-1"), {
      tipo: "F",
      ativo: true,
      nome: "Fornecedor 1",
    });
    await setDoc(doc(db, "usuarios/forn-2"), {
      tipo: "F",
      ativo: true,
      nome: "Fornecedor 2",
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
    await setDoc(doc(db, "usuarios/admin-inativo"), {
      tipo: "A",
      ativo: false,
      nome: "Admin inativo",
    });

    await setDoc(doc(db, "auditoria_eventos/audit-admin"), {
      acao: "USUARIO_TIPO_ALTERADO",
      area: "USUARIO",
      nivel: "WARN",
      resumo: "Alteração administrativa",
      visivel_fornecedor: false,
    });
    await setDoc(doc(db, "auditoria_eventos/audit-forn-1"), {
      acao: "SERVICO_FORNECEDOR_ATUALIZADO",
      area: "SERVICO",
      nivel: "INFO",
      resumo: "Serviço alterado",
      id_fornecedor: "forn-1",
      visivel_fornecedor: true,
    });
    await setDoc(doc(db, "auditoria_eventos/audit-forn-2"), {
      acao: "SERVICO_FORNECEDOR_ATUALIZADO",
      area: "SERVICO",
      nivel: "INFO",
      resumo: "Serviço de outro fornecedor",
      id_fornecedor: "forn-2",
      visivel_fornecedor: true,
    });
    await setDoc(doc(db, "auditoria_eventos/audit-forn-hidden"), {
      acao: "FORNECEDOR_DESATIVADO",
      area: "FORNECEDOR",
      nivel: "WARN",
      resumo: "Evento oculto ao fornecedor",
      id_fornecedor: "forn-1",
      visivel_fornecedor: false,
    });
    await setDoc(doc(db, "evento/evento-org-1"), {
      id_evento: "evento-org-1",
      id_usuario: "org-1",
      nome_evento: "Festa do organizador",
      custo_estimado: 1000,
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

    const adminDb = authedDb(env, "admin-1", "A");
    const inactiveAdminDb = authedDb(env, "admin-inativo", "A");
    const supplierDb = authedDb(env, "forn-1", "F");
    const otherSupplierDb = authedDb(env, "forn-2", "F");
    const organizerDb = authedDb(env, "org-1", "O");
    const otherOrganizerDb = authedDb(env, "org-2", "O");
    const anonDb = env.unauthenticatedContext().firestore();

    await assertSucceeds(getDoc(doc(adminDb, "auditoria_eventos/audit-admin")));
    await assertSucceeds(getDocs(collection(adminDb, "auditoria_eventos")));

    await assertFails(
      getDoc(doc(inactiveAdminDb, "auditoria_eventos/audit-admin")),
    );
    await assertFails(getDoc(doc(anonDb, "auditoria_eventos/audit-admin")));
    await assertFails(getDoc(doc(organizerDb, "auditoria_eventos/audit-admin")));

    await assertSucceeds(
      getDoc(doc(supplierDb, "auditoria_eventos/audit-forn-1")),
    );
    await assertFails(
      getDoc(doc(supplierDb, "auditoria_eventos/audit-forn-2")),
    );
    await assertFails(
      getDoc(doc(supplierDb, "auditoria_eventos/audit-forn-hidden")),
    );

    await assertSucceeds(
      getDocs(
        query(
          collection(supplierDb, "auditoria_eventos"),
          where("id_fornecedor", "==", "forn-1"),
          where("visivel_fornecedor", "==", true),
        ),
      ),
    );
    await assertFails(getDocs(collection(supplierDb, "auditoria_eventos")));
    await assertFails(
      getDocs(
        query(
          collection(otherSupplierDb, "auditoria_eventos"),
          where("id_fornecedor", "==", "forn-1"),
          where("visivel_fornecedor", "==", true),
        ),
      ),
    );

    await assertFails(
      setDoc(doc(adminDb, "auditoria_eventos/client-create"), {
        acao: "CLIENTE_TENTOU_CRIAR",
        area: "SISTEMA",
      }),
    );
    await assertFails(
      updateDoc(doc(adminDb, "auditoria_eventos/audit-admin"), {
        resumo: "alterado pelo cliente",
      }),
    );
    await assertFails(deleteDoc(doc(adminDb, "auditoria_eventos/audit-admin")));

    await assertSucceeds(
      setDoc(doc(organizerDb, "orcamento/orcamento-allowed"), {
        id_orcamento: "orcamento-allowed",
        id_evento: "evento-org-1",
        id_servico_fornecido: null,
        id_fornecedor: null,
        id_solicitante: null,
        custo_estimado: 350,
        orcamento_fechado: false,
        anotacoes: "Decoracao",
        status: "pendente",
        data_cadastro: new Date("2026-01-10T12:00:00.000Z"),
      }),
    );
    await assertFails(
      setDoc(doc(otherOrganizerDb, "orcamento/orcamento-other-org"), {
        id_orcamento: "orcamento-other-org",
        id_evento: "evento-org-1",
        id_servico_fornecido: null,
        custo_estimado: 200,
        status: "pendente",
      }),
    );
    await assertFails(
      setDoc(doc(supplierDb, "orcamento/orcamento-supplier"), {
        id_orcamento: "orcamento-supplier",
        id_evento: "evento-org-1",
        id_servico_fornecido: null,
        custo_estimado: 200,
        status: "pendente",
      }),
    );
    await assertSucceeds(
      getDocs(
        query(
          collection(organizerDb, "orcamento"),
          where("id_evento", "==", "evento-org-1"),
        ),
      ),
    );

    await assertSucceeds(
      setDoc(
        doc(
          organizerDb,
          "orcamento/orcamento-allowed/orcamento_gasto/gasto-allowed",
        ),
        {
          id_gasto: "gasto-allowed",
          id_orcamento: "orcamento-allowed",
          nome: "Flores",
          custo: 120,
          pago: 0,
          data_cadastro: new Date("2026-01-10T12:30:00.000Z"),
        },
      ),
    );
    await assertSucceeds(
      getDocs(
        query(
          collection(
            organizerDb,
            "orcamento/orcamento-allowed/orcamento_gasto",
          ),
          orderBy("data_cadastro", "desc"),
        ),
      ),
    );
    await assertFails(
      setDoc(
        doc(
          otherOrganizerDb,
          "orcamento/orcamento-allowed/orcamento_gasto/gasto-blocked",
        ),
        {
          id_gasto: "gasto-blocked",
          id_orcamento: "orcamento-allowed",
          nome: "Som",
          custo: 180,
          pago: 0,
        },
      ),
    );

    console.log("Auditoria Firestore rules: OK");
  } finally {
    await env.cleanup();
  }
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
