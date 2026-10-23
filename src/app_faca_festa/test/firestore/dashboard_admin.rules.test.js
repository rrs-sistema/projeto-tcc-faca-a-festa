/**
 * Dashboard admin não lê custos privados via rules cliente.
 * JDK 21+: npm run test:rules:dashboard:admin
 */
const fs = require("fs");
const path = require("path");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

const PROJECT = "demo-faca-festa-dash-admin";
const RULES = fs.readFileSync(
  path.join(__dirname, "../../firestore.rules"),
  "utf8",
);

async function seed(env) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc("usuarios/admin-1").set({ tipo: "A", ativo: true });
    await db.doc("usuarios/forn-1").set({ tipo: "F", ativo: true });
    await db.doc("fornecedor/forn-1").set({ nome: "X" });
    await db.doc("fornecedor/forn-1/custos_internos/c1").set({
      valor_incorrido: { centavos: 999 },
    });
    await db.doc("plataforma_comissao_obrigacoes/o1").set({
      id_pagador: "forn-1",
      valor_original: { centavos: 500 },
    });
  });
}

async function main() {
  const env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: { rules: RULES, host: "127.0.0.1", port: 8080 },
  });
  await seed(env);

  const admin = env.authenticatedContext("admin-1").firestore();
  const forn = env.authenticatedContext("forn-1").firestore();

  await assertFails(admin.doc("fornecedor/forn-1/custos_internos/c1").get());
  await assertSucceeds(admin.doc("plataforma_comissao_obrigacoes/o1").get());
  await assertSucceeds(forn.doc("plataforma_comissao_obrigacoes/o1").get());

  await env.cleanup();
  console.log("✓ admin não lê custos privados; lê comissões plataforma");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
