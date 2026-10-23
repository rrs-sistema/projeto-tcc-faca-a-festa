/**
 * Autorização financeira: evento alheio é rejeitado (espelho da regra do service).
 */
const assert = require("assert");

function exigirAcesso({ uid, tipo, eventoDono, orcSolicitante }) {
  const isDono = eventoDono === uid;
  const isAdmin = tipo === "A";
  if (isDono || orcSolicitante === uid || isAdmin) return true;
  const err = new Error("permission-denied");
  err.code = "permission-denied";
  throw err;
}

assert.doesNotThrow(() =>
  exigirAcesso({
    uid: "dono",
    tipo: "O",
    eventoDono: "dono",
    orcSolicitante: "dono",
  }),
);

assert.throws(
  () =>
    exigirAcesso({
      uid: "intruso",
      tipo: "O",
      eventoDono: "dono",
      orcSolicitante: "dono",
    }),
  (e) => e.code === "permission-denied",
);

console.log("✓ acesso a evento alheio rejeitado");
