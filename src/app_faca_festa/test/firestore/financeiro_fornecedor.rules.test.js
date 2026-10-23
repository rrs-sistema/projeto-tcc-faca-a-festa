/**
 * Regras: custos privados só pelo dono do fornecedor.
 * Requer JDK 21+: npm run test:rules:financeiro:fornecedor
 */
const fs = require("fs");
const path = require("path");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

const PROJECT = "demo-faca-festa-fin-forn";
const RULES = fs.readFileSync(
  path.join(__dirname, "../../firestore.rules"),
  "utf8",
);

async function seed(env) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc("usuarios/forn-1").set({ tipo: "F", ativo: true });
    await db.doc("usuarios/org-1").set({ tipo: "O", ativo: true });
    await db.doc("usuarios/admin-1").set({ tipo: "A", ativo: true });
    await db.doc("fornecedor/forn-1").set({ nome: "Buffet" });
    await db.doc("fornecedor/forn-1/custos_internos/c1").set({
      valor_incorrido: { centavos: 300000, moeda: "BRL" },
      perspectiva: "fornecedor_privado",
    });
  });
}

async function main() {
  const env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: { rules: RULES, host: "127.0.0.1", port: 8080 },
  });
  await seed(env);

  const dono = env.authenticatedContext("forn-1").firestore();
  const org = env.authenticatedContext("org-1").firestore();
  const admin = env.authenticatedContext("admin-1").firestore();

  await assertSucceeds(dono.doc("fornecedor/forn-1/custos_internos/c1").get());
  await assertFails(org.doc("fornecedor/forn-1/custos_internos/c1").get());
  await assertFails(admin.doc("fornecedor/forn-1/custos_internos/c1").get());

  await env.cleanup();
  console.log("✓ custos privados: só dono; org/admin negados");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
