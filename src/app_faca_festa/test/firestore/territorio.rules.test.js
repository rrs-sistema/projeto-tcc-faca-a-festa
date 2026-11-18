const fs = require("node:fs");
const path = require("node:path");
const { exigirEmuladorDemo } = require("../../functions/scripts/exigirEmuladorDemo");

const projectId = exigirEmuladorDemo("demo-territorio-rules");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const { doc, setDoc, updateDoc } = require("firebase/firestore");

async function testar() {
  const env = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8"),
    },
  });
  try {
    await env.withSecurityRulesDisabled(async context => {
      const db = context.firestore();
      await Promise.all([
        setDoc(doc(db, "usuarios/admin"), { tipo: "A", ativo: true }),
        setDoc(doc(db, "usuarios/fornecedor-a"), { tipo: "F", ativo: true }),
        setDoc(doc(db, "territorio/legado"), { idFornecedor: " fornecedor-a " }),
      ]);
    });

    const admin = env.authenticatedContext("admin").firestore();
    const fornecedor = env.authenticatedContext("fornecedor-a").firestore();
    const outro = env.authenticatedContext("fornecedor-b").firestore();
    const territorio = { id_fornecedor: "fornecedor-a", raio_km: 20 };

    await assertSucceeds(setDoc(doc(admin, "territorio/edicao"), territorio));
    await assertSucceeds(updateDoc(doc(admin, "territorio/edicao"), { raio_km: 25 }));
    await assertSucceeds(updateDoc(doc(fornecedor, "territorio/edicao"), { descricao: "Centro" }));
    await assertFails(updateDoc(doc(admin, "territorio/edicao"), { id_fornecedor: "fornecedor-b" }));
    await assertFails(updateDoc(doc(fornecedor, "territorio/edicao"), { id_fornecedor: "fornecedor-b" }));
    await assertFails(updateDoc(doc(outro, "territorio/edicao"), { raio_km: 30 }));
    await assertSucceeds(setDoc(doc(admin, "territorio/legado"), territorio));
    console.log("PASS território: criação, edição e preservação do vínculo inclusive em documentos legados.");
  } finally {
    await env.cleanup();
  }
}

testar().catch(erro => {
  console.error(erro);
  process.exitCode = 1;
});
