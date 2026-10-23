/**
 * Fixture + seed determinístico para emulador (Prompt 08).
 *
 * Sem emulador: só grava o contrato JSON.
 * Com FIRESTORE_EMULATOR_HOST: grava documentos sintéticos via Admin SDK.
 *
 *   $env:JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"
 *   firebase emulators:exec --project demo-financeiro-integrado --only firestore `
 *     "node functions/scripts/prepararFinanceiroIntegradoEmulador.js"
 *
 * NÃO aponta para produção. NÃO faz deploy.
 */
const fs = require("fs");
const path = require("path");

const OUT = path.join(
  __dirname,
  "../../docs/evidencias_validacao/financeiro/fixture-08-personas.json",
);

const fixture = {
  projeto: "demo-financeiro-integrado",
  timezone: "America/Sao_Paulo",
  personas: [
    { uid: "org-1", email: "org1@example.test", tipo: "O", papel: "organizador_a" },
    { uid: "org-2", email: "org2@example.test", tipo: "O", papel: "organizador_b" },
    { uid: "forn-1", email: "forn1@example.test", tipo: "F", papel: "fornecedor_a" },
    { uid: "forn-2", email: "forn2@example.test", tipo: "F", papel: "fornecedor_b" },
    { uid: "admin-1", email: "admin@example.test", tipo: "A", papel: "administrador" },
  ],
  cenarios: {
    contrato: "10000 contratado / 3000 pago / 7000 saldo",
    previsao: "limite 30000 / contratos 18000 / restantes 8000 → 26000",
    comissao: "5% de 10000 = 500 (política inativa até decisão comercial)",
  },
  senha_sintetica: "TesteLocal123!",
  recusa_producao: true,
};

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(fixture, null, 2), "utf8");
console.log("Fixture escrita em", OUT);

async function seedAuth(admin) {
  const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  if (!authHost) {
    console.log("FIREBASE_AUTH_EMULATOR_HOST ausente — Auth não seedado.");
    return { authSeeded: false };
  }
  if (!authHost.includes("127.") && !authHost.includes("localhost")) {
    throw new Error("Recusa: Auth emulator deve ser local.");
  }
  const auth = admin.auth();
  for (const p of fixture.personas) {
    try {
      await auth.getUser(p.uid);
    } catch {
      await auth.createUser({
        uid: p.uid,
        email: p.email,
        password: fixture.senha_sintetica,
        emailVerified: true,
      });
    }
  }
  console.log("Seed Auth emulador ok @", authHost);
  return { authSeeded: true, authHost };
}

async function seedEmulador() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host) {
    console.log(
      "FIRESTORE_EMULATOR_HOST ausente — só JSON. Rode via firebase emulators:exec para seed.",
    );
    return { seeded: false };
  }
  if (!host.includes("127.") && !host.includes("localhost")) {
    throw new Error("Recusa: emulador deve ser local (127.0.0.1/localhost).");
  }

  // eslint-disable-next-line node/no-missing-require
  const admin = require("firebase-admin");
  if (!admin.apps.length) {
    admin.initializeApp({ projectId: fixture.projet });
  }
  const authResult = await seedAuth(admin);
  const db = admin.firestore();

  for (const p of fixture.personas) {
    await db.doc(`usuarios/${p.uid}`).set({
      tipo: p.tipo,
      ativo: true,
      email: p.email,
      papel_sintetico: p.papel,
    });
  }

  await db.doc("evento/evt-1").set({
    id_usuario: "org-1",
    nome: "Festa integrada org-1",
    data: "2026-11-15",
    custo_estimado: 30000,
    timezone: "America/Sao_Paulo",
  });
  await db.doc("evento/evt-2").set({
    id_usuario: "org-2",
    nome: "Festa alheia org-2",
    data: "2026-12-01",
    custo_estimado: 10000,
  });

  await db.doc("orcamento/orc-1").set({
    id_orcamento: "orc-1",
    id_evento: "evt-1",
    id_fornecedor: "forn-1",
    id_solicitante: "org-1",
    id_necessidade: "n-decor",
    status: "fechado",
    orcamento_fechado: true,
    valor_contratado: 10000,
    valor_contratado_centavos: 1000000,
    pago_liquido_centavos: 300000,
    custo_estimado: 10000,
  });
  await db.doc("orcamento/orc-1/liquidacoes/liq-1").set({
    id_liquidacao: "liq-1",
    id_evento: "evt-1",
    valor: { centavos: 300000, moeda: "BRL" },
    origem: "fixture_sintetica",
  });

  await db.doc("orcamento/orc-2").set({
    id_orcamento: "orc-2",
    id_evento: "evt-1",
    id_fornecedor: "forn-2",
    id_solicitante: "org-1",
    status: "fechado",
    orcamento_fechado: true,
    valor_contratado: 8000,
    valor_contratado_centavos: 800000,
    pago_liquido_centavos: 0,
  });

  await db.doc("fornecedor/forn-1/custos_internos/custo-1").set({
    id_evento: "evt-1",
    valor: { centavos: 200000, moeda: "BRL" },
    valor_incorrido: { centavos: 200000, moeda: "BRL" },
    previsto_restante: { centavos: 0, moeda: "BRL" },
    valor_desembolso: { centavos: 200000, moeda: "BRL" },
    tipo: "material",
    origem: "manual",
    direto: true,
    privado: true,
  });

  await db.doc("fornecedor/forn-1/estoque_itens/cadeiras").set({
    id_item: "cadeiras",
    id_fornecedor: "forn-1",
    nome: "Cadeira",
    natureza: "consumivel",
    unidade: "un",
    quantidade_total: 100,
    quantidade_reservada: 0,
    quantidade_em_uso: 0,
    status: "disponivel",
    custo_medio_unitario_centavos: 500,
  });

  await db.doc("plataforma_comissao_politicas/pol-1").set({
    id_politica: "pol-1",
    versao: 1,
    percentual_bps: 500,
    base_elegivel: "servicos_contratados_plataforma",
    pagador: "fornecedor",
    gatilho_geracao: "contratacao_confirmada",
    reversao: "proporcional",
    ativa: false,
    completa: true,
    observacoes_comerciais: "Inativa até decisão comercial",
  });

  console.log("Seed Firestore emulador ok @", host);
  console.log(
    "Personas:",
    fixture.personas.map((p) => p.uid).join(", "),
  );
  return { seeded: true, host, ...authResult };
}

seedEmulador()
  .then((r) => {
    console.log(JSON.stringify({ fixture: OUT, ...r }));
  })
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
