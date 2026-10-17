const assert = require("node:assert/strict");
const { test } = require("node:test");
const { montarHtml, selecionarCapaConvite } = require("../lib/functions/convite/conviteEmailTemplate");

const convite = {
  nome: "Convidada", nomeEvento: "Convivência", quando: "23/10/2026",
  hora: "18:00", local: "Salão", mensagem: "", link: "https://faca-a-festa.web.app/#/convite/teste",
  nomeTema: "Tropical chique", traje: "", capaUrl: "",
  corPrimaria: "#2E7D32", corSecundaria: "#FFB300",
};

test("tema sem imagem gera convite sem img ou espaço reservado para capa", () => {
  const html = montarHtml(convite);
  assert.doesNotMatch(html, /<img|height:160px|firebasestorage/);
  assert.match(html, /Tropical chique/);
  assert.match(html, /background:#2E7D32/);
  assert.match(html, /border-radius:12px 12px 0 0/);
  assert.match(html, /Abrir convite/);
});

test("capa personalizada tem prioridade sobre a capa do tema", () => {
  assert.equal(selecionarCapaConvite("https://example.com/evento.jpg", "https://example.com/tema.jpg"),
    "https://example.com/evento.jpg");
});

test("usa capa cadastrada no tema quando evento não tem imagem", () => {
  const capaUrl = selecionarCapaConvite("", "https://example.com/tema.jpg");
  const html = montarHtml({ ...convite, capaUrl });
  assert.match(html, /<img src="https:\/\/example.com\/tema.jpg"/);
  assert.match(html, /border-radius:0 0 0 0/);
});

test("não inventa capa quando evento e tema não possuem URL", () => {
  assert.equal(selecionarCapaConvite(undefined, null, ""), "");
});

test("ignora assets e URLs inválidas e permite fallback para capa explícita", () => {
  assert.equal(selecionarCapaConvite("assets/images/capa.jpg", "https://example.com/tema.jpg"),
    "https://example.com/tema.jpg");
  for (const capaUrl of ["assets/images/capa.jpg", "gs://bucket/capa.jpg", "javascript:alert(1)", "inválida"]) {
    assert.doesNotMatch(montarHtml({ ...convite, capaUrl }), /<img/);
  }
});

test("escapa dados do evento e parâmetros da URL no HTML", () => {
  const html = montarHtml({ ...convite, nomeEvento: '<script>alert("x")</script>',
    capaUrl: "https://example.com/capa.jpg?a=1&b=2" });
  assert.doesNotMatch(html, /<script>/);
  assert.match(html, /&lt;script&gt;/);
  assert.match(html, /a=1&amp;b=2/);
});
