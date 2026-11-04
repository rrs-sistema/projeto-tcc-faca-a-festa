const assert = require("node:assert/strict");
const { resumirAvaliacoes } = require("../lib/functions/publico/obterEstatisticasPublicas");

assert.deepEqual(resumirAvaliacoes([]), {
  totalAvaliacoes: 0, mediaFornecedores: null,
});
assert.deepEqual(resumirAvaliacoes([
  { reputacao_verificada:{schema:2,media:5,quantidade:2} },
  { reputacao_verificada:{schema:2,media:3,quantidade:6} },
]), { totalAvaliacoes: 8, mediaFornecedores: 3.5 });
assert.deepEqual(resumirAvaliacoes([
  { media_avaliacoes: 6, total_avaliacoes: 10 },
  { media_avaliacoes: 4, total_avaliacoes: 0 },
  { media_avaliacoes: 4, total_avaliacoes: -2 },
  { media_avaliacoes: "inválido", total_avaliacoes: 4 },
  {},
]), { totalAvaliacoes: 0, mediaFornecedores: null });
console.log("Estatísticas públicas: testes passaram.");
