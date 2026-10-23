/**
 * Regras financeiras: leitura autorizada; escrita direta de liquidação negada.
 * Requer emulador: npm run test:rules:financeiro
 */
const fs = require("fs");
const path = require("path");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

const PROJECT = "demo-faca-festa-financeiro";
const RULES = fs.readFileSync(
  path.join(__dirname, "../../firestore.rules"),
  "utf8",
);

async function seed(env) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc("usuarios/dono").set({ tipo: "O", ativo: true });
    await db.doc("usuarios/intruso").set({ tipo: "O", ativo: true });
    await db.doc("evento/ev1").set({ id_usuario: "dono", nome: "Festa" });
    await db.doc("orcamento/orc1").set({
      id_orcamento: "orc1",
      id_evento: "ev1",
      id_solicitante: "dono",
      custo_estimado: 10000,
    });
    await db.doc("orcamento/orc1/liquidacoes/l1").set({
      id_liquidacao: "l1",
      id_evento: "ev1",
      valor: { centavos: 300000, moeda: "BRL" },
    });
  });
}

async function main() {
  const env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: { rules: RULES, host: "127.0.0.1", port: 8080 },
  });
  await seed(env);

  const dono = env.authenticatedContext("dono").firestore();
  const intruso = env.authenticatedContext("intruso").firestore();

  await assertSucceeds(dono.doc("orcamento/orc1/liquidacoes/l1").get());
  await assertFails(intruso.doc("orcamento/orc1/liquidacoes/l1").get());
  await assertFails(
    dono.doc("orcamento/orc1/liquidacoes/l2").set({
      id_liquidacao: "l2",
      valor: { centavos: 100, moeda: "BRL" },
    }),
  );
  await assertFails(
    dono.doc("orcamento/orc1/obrigacoes/parcela-1").set({
      id_obrigacao: "parcela-1",
      valor: { centavos: 100, moeda: "BRL" },
    }),
  );

  await env.cleanup();
  console.log("✓ regras financeiras: leitura dono ok; intruso e write negados");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
