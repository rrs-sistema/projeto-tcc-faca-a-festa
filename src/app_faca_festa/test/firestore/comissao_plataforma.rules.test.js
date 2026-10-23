/**
 * Regras: políticas só admin; obrigações admin ou próprio pagador.
 * JDK 21+: npm run test:rules:comissao
 */
const fs = require("fs");
const path = require("path");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

const PROJECT = "demo-faca-festa-comissao";
const RULES = fs.readFileSync(
  path.join(__dirname, "../../firestore.rules"),
  "utf8",
);

async function seed(env) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc("usuarios/admin-1").set({ tipo: "A", ativo: true });
    await db.doc("usuarios/forn-1").set({ tipo: "F", ativo: true });
    await db.doc("usuarios/forn-2").set({ tipo: "F", ativo: true });
    await db.doc("plataforma_comissao_politicas/p1").set({
      percentual_bps: 500,
      ativa: true,
    });
    await db.doc("plataforma_comissao_obrigacoes/o1").set({
      id_pagador: "forn-1",
      valor_original: { centavos: 50000, moeda: "BRL" },
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
  const outro = env.authenticatedContext("forn-2").firestore();

  await assertSucceeds(admin.doc("plataforma_comissao_politicas/p1").get());
  await assertFails(forn.doc("plataforma_comissao_politicas/p1").get());
  await assertSucceeds(forn.doc("plataforma_comissao_obrigacoes/o1").get());
  await assertFails(outro.doc("plataforma_comissao_obrigacoes/o1").get());
  await assertFails(forn.doc("plataforma_comissao_politicas/p1").set({ x: 1 }));

  await env.cleanup();
  console.log("✓ comissão: admin lê políticas; pagador só próprias obrigações");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
