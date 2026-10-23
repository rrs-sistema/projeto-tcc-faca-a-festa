/**
 * Smoke integrado (Prompt 08): 2 orgs, 2 fornecedores, admin, anônimo.
 * Negação cruzada + admin sem custos privados.
 * JDK 21+: npm run test:rules:financeiro:integrado
 */
const fs = require("fs");
const path = require("path");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

const PROJECT = "demo-financeiro-integrado";
const RULES = fs.readFileSync(
  path.join(__dirname, "../../firestore.rules"),
  "utf8",
);

async function seed(env) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc("usuarios/org-1").set({ tipo: "O", ativo: true });
    await db.doc("usuarios/org-2").set({ tipo: "O", ativo: true });
    await db.doc("usuarios/forn-1").set({ tipo: "F", ativo: true });
    await db.doc("usuarios/forn-2").set({ tipo: "F", ativo: true });
    await db.doc("usuarios/admin-1").set({ tipo: "A", ativo: true });

    await db.doc("evento/evt-1").set({
      id_usuario: "org-1",
      nome: "Festa org-1",
      custo_estimado: 30000,
    });
    await db.doc("evento/evt-2").set({
      id_usuario: "org-2",
      nome: "Festa org-2",
    });

    await db.doc("orcamento/orc-1").set({
      id_orcamento: "orc-1",
      id_evento: "evt-1",
      id_fornecedor: "forn-1",
      id_solicitante: "org-1",
      status: "fechado",
      orcamento_fechado: true,
      valor_contratado: 10000,
      valor_contratado_centavos: 1000000,
      pago_liquido_centavos: 300000,
    });
    await db.doc("orcamento/orc-1/liquidacoes/liq-1").set({
      id_liquidacao: "liq-1",
      id_evento: "evt-1",
      valor: { centavos: 300000, moeda: "BRL" },
    });

    await db.doc("fornecedor/forn-1/custos_internos/c1").set({
      id_evento: "evt-1",
      valor_incorrido: { centavos: 200000, moeda: "BRL" },
      privado: true,
    });
    await db.doc("fornecedor/forn-1/estoque_itens/cadeiras").set({
      id_item: "cadeiras",
      id_fornecedor: "forn-1",
      nome: "Cadeira",
      quantidade_total: 100,
    });

    await db.doc("plataforma_comissao_politicas/pol-1").set({
      percentual_bps: 500,
      ativa: false,
    });
    await db.doc("plataforma_comissao_obrigacoes/ob-1").set({
      id_pagador: "forn-1",
      id_evento: "evt-1",
      valor_original_centavos: 50000,
    });
  });
}

async function main() {
  const env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: { rules: RULES, host: "127.0.0.1", port: 8080 },
  });
  await seed(env);

  const org1 = env.authenticatedContext("org-1").firestore();
  const org2 = env.authenticatedContext("org-2").firestore();
  const forn1 = env.authenticatedContext("forn-1").firestore();
  const forn2 = env.authenticatedContext("forn-2").firestore();
  const admin = env.authenticatedContext("admin-1").firestore();
  const anon = env.unauthenticatedContext().firestore();

  // Dono do evento lê liquidação; evento alheio / anônimo negados.
  await assertSucceeds(org1.doc("orcamento/orc-1/liquidacoes/liq-1").get());
  await assertFails(org2.doc("orcamento/orc-1/liquidacoes/liq-1").get());
  await assertFails(anon.doc("orcamento/orc-1/liquidacoes/liq-1").get());

  // Elevação de papel pelo cliente: org não escreve liquidação.
  await assertFails(
    org1.doc("orcamento/orc-1/liquidacoes/liq-hack").set({
      id_liquidacao: "liq-hack",
      valor: { centavos: 1, moeda: "BRL" },
    }),
  );

  // Custos privados: só forn-1; org, outro fornecedor e admin negados.
  await assertSucceeds(forn1.doc("fornecedor/forn-1/custos_internos/c1").get());
  await assertFails(org1.doc("fornecedor/forn-1/custos_internos/c1").get());
  await assertFails(forn2.doc("fornecedor/forn-1/custos_internos/c1").get());
  await assertFails(admin.doc("fornecedor/forn-1/custos_internos/c1").get());

  // Estoque privado: mesma matriz.
  await assertSucceeds(
    forn1.doc("fornecedor/forn-1/estoque_itens/cadeiras").get(),
  );
  await assertFails(
    forn2.doc("fornecedor/forn-1/estoque_itens/cadeiras").get(),
  );

  // Comissão: admin lê política; pagador lê própria obrigação; outro negado.
  await assertSucceeds(admin.doc("plataforma_comissao_politicas/pol-1").get());
  await assertFails(forn1.doc("plataforma_comissao_politicas/pol-1").get());
  await assertSucceeds(forn1.doc("plataforma_comissao_obrigacoes/ob-1").get());
  await assertFails(forn2.doc("plataforma_comissao_obrigacoes/ob-1").get());

  await env.cleanup();
  console.log(
    "✓ integrado: org-1/org-2/forn-1/forn-2/admin/anônimo — cruzamentos negados",
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
