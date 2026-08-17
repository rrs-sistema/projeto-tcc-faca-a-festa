import fs from "node:fs/promises";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const ROOT = "D:/repository/unicesumar/tcc/app/src/app_faca_festa";
const TMP = `${ROOT}/.codex_tmp/tcc_market_deck`;
const OUT_DIR = `${TMP}/rendered`;
const OUT_PPTX = `${ROOT}/document/Apresentacao_TCC_Banco_Dados_Faca_Festa_Profissional.pptx`;
const LOGO = `${ROOT}/assets/logo/logo-faca-festa.png`;
const EVENT_IMG = `${ROOT}/assets/images/fornecedor_default.jpg`;
const VYCANIS_IMG = "C:/Users/User/AppData/Local/Temp/codex-clipboard-9619a521-5e06-4afe-8b5d-06b74955ba01.png";

const W = 1280;
const H = 720;
const navy = "#0B1220";
const navy2 = "#162239";
const paper = "#F7F5F6";
const white = "#FFFFFF";
const ink = "#131B2A";
const muted = "#667085";
const blue = "#1769C2";
const pink = "#E83D91";
const gold = "#F8C84A";
const lavender = "#B89CFF";
const line = "#D6D9E0";
const font = "Arial";

async function writeBlob(path, blob) {
  await fs.writeFile(path, new Uint8Array(await blob.arrayBuffer()));
}

async function fileBuffer(path) {
  const bytes = await fs.readFile(path);
  return bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
}

function addText(slide, value, left, top, width, height, options = {}) {
  const box = slide.shapes.add({
    geometry: "textbox",
    name: options.name,
    position: { left, top, width, height },
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  box.text = value;
  box.text.style = {
    fontSize: options.fontSize ?? 20,
    bold: options.bold ?? false,
    color: options.color ?? ink,
    fontFamily: font,
    alignment: options.alignment ?? "left",
  };
  return box;
}

function rect(slide, left, top, width, height, fill, options = {}) {
  return slide.shapes.add({
    geometry: options.geometry ?? "rect",
    name: options.name,
    position: { left, top, width, height },
    fill,
    line: { style: "solid", fill: options.stroke ?? fill, width: options.strokeWidth ?? 0 },
  });
}

function connector(slide, left, top, width, height, color = line, weight = 2) {
  return slide.shapes.add({
    geometry: "straightConnector1",
    position: { left, top, width, height },
    fill: "none",
    line: { style: "solid", fill: color, width: weight },
  });
}

function footer(slide, number, dark = false) {
  rect(slide, 52, 674, 90, 3, number % 2 === 0 ? pink : blue);
  addText(slide, "FAÇA A FESTA · TCC", 52, 683, 260, 20, { fontSize: 11, color: dark ? "#B9C4D8" : muted });
  addText(slide, String(number).padStart(2, "0"), 1190, 681, 38, 20, { fontSize: 11, color: dark ? "#B9C4D8" : muted, alignment: "right" });
}

function header(slide, title, subtitle, number, dark = false) {
  addText(slide, title, 52, 42, 1176, 60, { fontSize: 39, bold: true, color: dark ? white : ink });
  if (subtitle) addText(slide, subtitle, 52, 112, 1120, 46, { fontSize: 18, color: dark ? "#C7D0E1" : muted });
  footer(slide, number, dark);
}

function notes(slide, talk, sources) {
  slide.speakerNotes.textFrame.setText(`${talk}\n\n[Sources]\n${sources.map((s) => `- ${s}`).join("\n")}`);
  slide.speakerNotes.setVisible(true);
}

function table(slide, values, widths, top, height, dark = false) {
  const t = slide.tables.add({ rows: values.length, columns: values[0].length, left: 52, top, width: 1176, height, columnWidths: widths, values });
  t.styleOptions = { headerRow: true, bandedRows: true };
  t.borders.assign({ style: "solid", fill: dark ? "#40506A" : line, width: 1 });
  const all = t.cells.block({ row: 0, column: 0, rowCount: values.length, columnCount: values[0].length });
  all.textStyle.fontSize = 17;
  all.textStyle.color = dark ? white : ink;
  all.margins = { left: 10, right: 10, top: 8, bottom: 8 };
  const h = t.cells.block({ row: 0, column: 0, rowCount: 1, columnCount: values[0].length });
  h.fill = dark ? blue : navy;
  h.textStyle.color = white;
  h.textStyle.bold = true;
  h.textStyle.fontSize = 18;
  return t;
}

async function addImage(slide, path, left, top, width, height, fit = "cover", contentType = "image/jpeg") {
  slide.images.add({ blob: await fileBuffer(path), contentType, fit, position: { left, top, width, height }, alt: `Imagem: ${path.split("/").pop()}` });
}

async function main() {
  await fs.mkdir(OUT_DIR, { recursive: true });
  const deck = Presentation.create({ slideSize: { width: W, height: H } });

  // 1. Capa institucional
  {
    const slide = deck.slides.add();
    slide.background.fill = navy;
    await addImage(slide, EVENT_IMG, 720, 0, 560, 720, "cover");
    rect(slide, 700, 0, 34, 720, pink);
    await addImage(slide, LOGO, 52, 42, 118, 118, "contain", "image/png");
    addText(slide, "BANCO DE DADOS\nDO FAÇA A FESTA", 52, 210, 590, 160, { fontSize: 53, bold: true, color: white });
    addText(slide, "Mapeamento atual, chaves e modelo relacional para um produto preparado para o mercado", 52, 397, 570, 95, { fontSize: 24, color: "#D2DBEA" });
    rect(slide, 52, 540, 250, 4, gold);
    addText(slide, "Trabalho de Conclusão de Curso", 52, 566, 420, 30, { fontSize: 18, color: white, bold: true });
    addText(slide, "Sistemas · 2026", 52, 607, 260, 28, { fontSize: 16, color: "#AFC0DA" });
    notes(slide,
      "Abra relacionando tecnologia e negócio: o banco de dados sustenta os fluxos do organizador, do convidado e do fornecedor. O objetivo desta apresentação é mostrar o modelo que existe hoje e como ele foi formalizado para evolução do produto.",
      ["assets/logo/logo-faca-festa.png", "assets/images/fornecedor_default.jpg", "document/MAPEAMENTO_FIREBASE_APRESENTACAO.md"],
    );
  }

  // 2. Escala comprovada
  {
    const slide = deck.slides.add();
    slide.background.fill = paper;
    header(slide, "O banco já reflete um ecossistema de produto", "O levantamento separou modelos de código das estruturas realmente persistidas.", 2);
    const stats = [
      ["29", "coleções raiz", blue],
      ["17", "caminhos aninhados", pink],
      ["54", "tabelas no modelo SQL", gold],
    ];
    stats.forEach((s, i) => {
      const x = 60 + i * 405;
      addText(slide, s[0], x, 225, 300, 120, { fontSize: 76, bold: true, color: s[2] });
      addText(slide, s[1], x, 350, 310, 42, { fontSize: 24, bold: true });
      connector(slide, x, 418, 310, 0, line, 1);
    });
    addText(slide, "74 arquivos de modelo foram analisados — mas classe não significa tabela.", 60, 488, 1090, 44, { fontSize: 25, bold: true });
    addText(slide, "DTOs, projeções administrativas, cálculos locais e respostas de IA só entraram no modelo quando representam informação persistida ou uma entidade de domínio relevante.", 60, 548, 1110, 68, { fontSize: 18, color: muted });
    notes(slide,
      "A mensagem é maturidade: o projeto cresceu e o modelo antigo ficou menor que a implementação. Os números mostram a diferença entre código e persistência e justificam a atualização do DER.",
      ["lib/data/models/**", "lib/controllers/**", "functions/src/**", "document/modelo_sql_vycanis.sql"],
    );
  }

  // 3. Método de mapeamento
  {
    const slide = deck.slides.add();
    slide.background.fill = navy;
    header(slide, "O novo modelo nasceu do uso real do sistema", "Três evidências foram cruzadas para evitar tabelas fictícias ou campos desatualizados.", 3, true);
    connector(slide, 170, 360, 925, 0, "#42516B", 3);
    const steps = [
      [150, "01", "Modelos", "Campos e tipos definidos em Dart", blue],
      [520, "02", "Persistência", "Leituras, gravações e consultas no Firestore", pink],
      [890, "03", "Contrato SQL", "PKs, FKs e normalização para o Vycanis", gold],
    ];
    steps.forEach((s) => {
      rect(slide, s[0], 320, 54, 54, s[4], { geometry: "ellipse" });
      addText(slide, s[1], s[0] + 9, 332, 36, 26, { fontSize: 16, bold: true, color: s[4] === gold ? ink : white, alignment: "center" });
      addText(slide, s[2], s[0] - 10, 418, 280, 40, { fontSize: 26, bold: true, color: white });
      addText(slide, s[3], s[0] - 10, 473, 280, 75, { fontSize: 18, color: "#C7D0E1" });
    });
    addText(slide, "Resultado: um modelo rastreável ao código e explicável para a banca.", 150, 590, 900, 35, { fontSize: 22, bold: true, color: lavender });
    notes(slide,
      "Explique que o trabalho não foi apenas copiar classes. Foram verificados controllers, repositories, telas e funções de backend. Em seguida, subcoleções e listas foram convertidas em relações SQL.",
      ["lib/data/models/**", "lib/controllers/**", "lib/data/repositories/**", "lib/data/datasources/**", "functions/src/**"],
    );
  }

  // 4. Núcleo relacional do produto
  {
    const slide = deck.slides.add();
    slide.background.fill = paper;
    header(slide, "O evento conecta os principais fluxos do produto", "A entidade central concentra planejamento, convidados, consumo e decisões financeiras.", 4);
    // connectors first
    connector(slide, 365, 198, 85, 0, "#BFC6D2", 2);
    connector(slide, 450, 198, 0, 127, "#BFC6D2", 2);
    connector(slide, 450, 325, 70, 0, "#BFC6D2", 2);
    connector(slide, 365, 538, 85, 0, "#BFC6D2", 2);
    connector(slide, 450, 405, 0, 133, "#BFC6D2", 2);
    connector(slide, 450, 405, 70, 0, "#BFC6D2", 2);
    [[315,178],[345,308],[385,458],[415,588]].forEach(([portY,nodeY]) => {
      connector(slide, 760, portY, 90, 0, "#BFC6D2", 2);
      connector(slide, 850, Math.min(portY,nodeY), 0, Math.abs(nodeY-portY), "#BFC6D2", 2);
      connector(slide, 850, nodeY, 80, 0, "#BFC6D2", 2);
    });
    rect(slide, 520, 285, 240, 160, navy, { geometry: "roundRect" });
    addText(slide, "evento", 558, 317, 165, 38, { fontSize: 32, bold: true, color: white, alignment: "center" });
    addText(slide, "PK · id_evento", 558, 374, 165, 26, { fontSize: 16, color: gold, alignment: "center" });
    const nodes = [
      [135, 155, "usuario", "id_usuario", blue],
      [135, 495, "tipo_evento", "id_tipo_evento", lavender],
      [930, 135, "convidado", "id_evento", pink],
      [930, 265, "tarefa", "id_evento", gold],
      [930, 415, "cardapio", "id_evento", blue],
      [930, 545, "orcamento", "id_evento", pink],
    ];
    nodes.forEach((n) => {
      rect(slide, n[0], n[1], 230, 86, white, { geometry: "roundRect", stroke: n[4], strokeWidth: 2 });
      addText(slide, n[2], n[0] + 20, n[1] + 15, 190, 28, { fontSize: 22, bold: true });
      addText(slide, n[3], n[0] + 20, n[1] + 51, 190, 20, { fontSize: 14, color: muted });
    });
    notes(slide,
      "Mostre o relacionamento central: um usuário organiza eventos; o tipo classifica; convidados, tarefas, cardápios e orçamentos dependem do evento. No Firestore essas são FKs lógicas; no modelo SQL passaram a ser relacionamentos explícitos.",
      ["lib/data/models/evento/evento_model.dart", "lib/data/models/usuario/usuario_model.dart", "lib/data/models/convidado/convidado_model.dart", "lib/data/models/tarefa/tarefa_model.dart", "document/modelo_sql_vycanis.sql"],
    );
  }

  // 5. Campos e chaves centrais
  {
    const slide = deck.slides.add();
    slide.background.fill = paper;
    header(slide, "As tabelas centrais preservam identidade e contexto", "Campos essenciais foram priorizados; detalhes completos permanecem no dicionário de dados.", 5);
    table(slide, [
      ["Entidade", "Chave primária", "Chaves estrangeiras", "Campos essenciais"],
      ["usuario", "id_usuario", "—", "nome · email · tipo · ativo"],
      ["evento", "id_evento", "id_usuario · id_tipo_evento · id_cidade", "nome · data · status · totais · endereço"],
      ["convidado", "id_convidado", "id_evento · id_grupo · id_mesa", "nome · contato · status · tipo"],
      ["tarefa", "id_tarefa", "id_evento · id_responsavel", "título · data prevista · status"],
      ["cardapio_item", "id_item", "id_cardapio · id_evento", "tipo · público · quantidades · confirmação"],
    ], [210, 230, 340, 396], 205, 400);
    rect(slide, 52, 622, 1176, 4, pink);
    addText(slide, "No Firestore, a relação é uma convenção. No SQL, a FK torna o vínculo documentado e verificável.", 52, 636, 1120, 30, { fontSize: 18, bold: true, color: blue });
    notes(slide,
      "Não leia todos os campos. Use um exemplo: evento.id_usuario liga o evento ao organizador; convidado.id_evento liga cada pessoa à festa. A diferença entre PK e FK deve ficar clara para a banca.",
      ["lib/data/models/usuario/usuario_model.dart", "lib/data/models/evento/evento_model.dart", "lib/data/models/convidado/convidado_model.dart", "lib/data/models/cardapio/**"],
    );
  }

  // 6. Marketplace de fornecedores
  {
    const slide = deck.slides.add();
    slide.background.fill = navy;
    header(slide, "O marketplace exige relações muitos-para-muitos", "Fornecedor, catálogo e território foram separados para permitir busca, preço e expansão regional.", 6, true);
    // connectors first
    connector(slide, 320, 210, 240, 145, "#53627A", 2);
    connector(slide, 320, 355, 240, 0, "#53627A", 2);
    connector(slide, 320, 355, 240, 145, "#53627A", 2);
    connector(slide, 780, 210, 210, 145, "#53627A", 2);
    rect(slide, 110, 285, 240, 140, blue, { geometry: "roundRect" });
    addText(slide, "fornecedor", 140, 315, 180, 38, { fontSize: 30, bold: true, color: white, alignment: "center" });
    addText(slide, "PK · id_fornecedor", 140, 375, 180, 24, { fontSize: 15, color: "#DCE9F8", alignment: "center" });
    const marketNodes = [
      [560, 160, "fornecedor_categoria", "fornecedor + categoria", pink],
      [560, 310, "fornecedor_servico", "preço · promoção · ativo", gold],
      [560, 460, "territorio", "região · raio · coordenadas", lavender],
      [990, 310, "servico_produto", "nome · medida · descrição", blue],
    ];
    marketNodes.forEach((n) => {
      rect(slide, n[0], n[1], 245, 92, navy2, { geometry: "roundRect", stroke: n[4], strokeWidth: 2 });
      addText(slide, n[2], n[0] + 18, n[1] + 16, 210, 26, { fontSize: 20, bold: true, color: white });
      addText(slide, n[3], n[0] + 18, n[1] + 54, 210, 22, { fontSize: 14, color: "#C7D0E1" });
    });
    addText(slide, "A tabela associativa fornecedor_servico resolve a relação N:N e centraliza preço, disponibilidade e reputação do serviço.", 110, 575, 1070, 50, { fontSize: 20, color: white, bold: true });
    notes(slide,
      "Este é o núcleo de mercado do aplicativo. Um fornecedor pode oferecer vários serviços e um serviço pode ser oferecido por vários fornecedores. A tabela associativa também guarda preço e métricas.",
      ["lib/data/models/fornecedor/fornecedor_model.dart", "lib/data/models/servico_produto/**", "lib/controllers/fornecedor/**", "lib/controllers/servico/**"],
    );
  }

  // 7. Fluxo comercial
  {
    const slide = deck.slides.add();
    slide.background.fill = paper;
    header(slide, "A jornada comercial permanece rastreável ponta a ponta", "Da solicitação ao gasto realizado, cada etapa possui identidade e vínculo com o evento.", 7);
    connector(slide, 145, 355, 930, 0, "#BFC6D2", 4);
    const flow = [
      [95, "1", "cotacao", "evento + solicitante", blue],
      [330, "2", "cotacao_fornecedor", "prazo + resposta", pink],
      [565, "3", "cotacao_servico", "quantidade + valores", gold],
      [800, "4", "orcamento", "fornecedor + status", lavender],
      [1035, "5", "orcamento_gasto", "custo + pago", blue],
    ];
    flow.forEach((f) => {
      rect(slide, f[0], 322, 66, 66, f[4], { geometry: "ellipse" });
      addText(slide, f[1], f[0] + 17, 337, 32, 28, { fontSize: 20, bold: true, color: f[4] === gold ? ink : white, alignment: "center" });
      addText(slide, f[2], f[0] - 25, 425, 190, 50, { fontSize: 20, bold: true, alignment: "center" });
      addText(slide, f[3], f[0] - 25, 485, 190, 48, { fontSize: 15, color: muted, alignment: "center" });
    });
    addText(slide, "Mensagens e serviços ficam associados ao fornecedor dentro da cotação; gastos detalham o orçamento aprovado.", 112, 588, 1030, 38, { fontSize: 20, bold: true, color: blue, alignment: "center" });
    notes(slide,
      "Conte o fluxo como uma história: o evento abre uma cotação, fornecedores respondem, serviços recebem valores, a proposta escolhida gera orçamento e os gastos passam a ser controlados.",
      ["lib/controllers/contacao/**", "lib/controllers/orcamento_controller.dart", "lib/controllers/orcamento_gasto_controller.dart", "lib/presentation/pages/fornecedor/chat/**"],
    );
  }

  // 8. Recursos escaláveis
  {
    const slide = deck.slides.add();
    slide.background.fill = paper;
    header(slide, "Recursos avançados já têm estrutura para escalar", "Dados de cálculo, inspiração e inteligência permanecem separados do núcleo transacional.", 8);
    const lanes = [
      [52, "CALCULADORA", blue, "calculadora_festa", "itens · custos · conversão", "analises_ia"],
      [454, "INSPIRAÇÃO", pink, "inspiracao", "galeria · tags · sugestões", "evento_referencia"],
      [856, "INTELIGÊNCIA", gold, "fornecedor_recomendacao", "score · motivos · compatibilidade", "fornecedor_interacao"],
    ];
    lanes.forEach((l) => {
      rect(slide, l[0], 205, 360, 6, l[2]);
      addText(slide, l[1], l[0], 232, 330, 30, { fontSize: 18, bold: true, color: l[2] });
      addText(slide, l[3], l[0], 300, 330, 44, { fontSize: 25, bold: true });
      addText(slide, l[4], l[0], 370, 330, 52, { fontSize: 18, color: muted });
      connector(slide, l[0], 445, 330, 0, line, 1);
      addText(slide, l[5], l[0], 475, 330, 38, { fontSize: 20, bold: true });
      addText(slide, "Histórico e contexto preservados sem sobrecarregar evento e fornecedor.", l[0], 530, 330, 68, { fontSize: 16, color: muted });
    });
    notes(slide,
      "A separação por domínios reduz acoplamento. A calculadora pode evoluir, a inspiração pode receber novos conteúdos e os algoritmos de recomendação podem mudar sem alterar as tabelas centrais.",
      ["lib/data/repositories/calculadora_festa_repository.dart", "functions/src/services/calculadora/**", "lib/controllers/inspiracao/**", "functions/src/services/fornecedores/**"],
    );
  }

  // 9. Modernização no Vycanis
  {
    const slide = deck.slides.add();
    slide.background.fill = navy;
    await addImage(slide, VYCANIS_IMG, 0, 0, 770, 720, "cover", "image/png");
    rect(slide, 755, 0, 20, 720, pink);
    addText(slide, "O modelo inicial evoluiu para um contrato relacional completo", 820, 58, 390, 150, { fontSize: 38, bold: true, color: white });
    addText(slide, "MODELO ATUAL", 820, 246, 220, 28, { fontSize: 16, bold: true, color: gold });
    addText(slide, "54", 820, 285, 160, 90, { fontSize: 70, bold: true, color: pink });
    addText(slide, "tabelas SQL", 965, 330, 210, 34, { fontSize: 23, bold: true, color: white });
    addText(slide, "PKs e FKs explícitas", 820, 410, 300, 32, { fontSize: 21, bold: true, color: white });
    addText(slide, "Subcoleções normalizadas", 820, 462, 330, 32, { fontSize: 21, bold: true, color: white });
    addText(slide, "DDL validado sem FKs inválidas", 820, 514, 360, 32, { fontSize: 21, bold: true, color: white });
    rect(slide, 820, 582, 320, 4, gold);
    addText(slide, "Pronto para Engenharia Reversa no Vycanis", 820, 603, 370, 50, { fontSize: 18, color: "#C7D0E1" });
    notes(slide,
      "A captura representa o modelo inicial. A atualização não é apenas visual: o DDL atual inclui 54 tabelas, converte subcoleções em relações e valida todas as referências. O arquivo pode ser importado pela Engenharia Reversa do Vycanis.",
      ["Captura do Vycanis fornecida pelo usuário", "document/modelo_sql_vycanis.sql", "document/GUIA_MODELO_SQL_VYCANIS.md"],
    );
  }

  // 10. Fechamento orientado a mercado
  {
    const slide = deck.slides.add();
    slide.background.fill = navy;
    await addImage(slide, LOGO, 52, 46, 104, 104, "contain", "image/png");
    addText(slide, "O banco deixa de ser apenas implementação e passa a ser um ativo do produto", 52, 190, 1030, 150, { fontSize: 48, bold: true, color: white });
    const commitments = [
      ["01", "Contrato de dados", "campos, chaves e domínios documentados"],
      ["02", "Governança", "uma fonte oficial para cada conceito"],
      ["03", "Escalabilidade", "módulos evoluem sem romper o núcleo"],
      ["04", "Prontidão de mercado", "modelo revisável por equipe e investidores"],
    ];
    commitments.forEach((c, i) => {
      const x = 52 + i * 298;
      addText(slide, c[0], x, 410, 60, 28, { fontSize: 16, bold: true, color: i % 2 === 0 ? pink : gold });
      addText(slide, c[1], x, 452, 260, 34, { fontSize: 21, bold: true, color: white });
      addText(slide, c[2], x, 500, 255, 62, { fontSize: 15, color: "#B9C4D8" });
    });
    rect(slide, 52, 618, 1176, 4, blue);
    addText(slide, "Próximo passo: manter o SQL e o dicionário atualizados junto de cada evolução do aplicativo.", 52, 638, 1120, 32, { fontSize: 20, bold: true, color: white });
    notes(slide,
      "Feche conectando o trabalho técnico à visão de mercado. Um produto que pretende crescer precisa de um banco explicável, governado e compartilhável. O resultado do TCC é também uma base para manutenção e evolução comercial.",
      ["document/MAPEAMENTO_FIREBASE_APRESENTACAO.md", "document/modelo_sql_vycanis.sql", "document/GUIA_MODELO_SQL_VYCANIS.md"],
    );
  }

  for (const [index, slide] of deck.slides.items.entries()) {
    const stem = `slide-${String(index + 1).padStart(2, "0")}`;
    await writeBlob(`${OUT_DIR}/${stem}.png`, await deck.export({ slide, format: "png", scale: 1 }));
    await fs.writeFile(`${OUT_DIR}/${stem}.layout.json`, await (await slide.export({ format: "layout" })).text());
  }
  await writeBlob(`${OUT_DIR}/montage.webp`, await deck.export({ format: "webp", montage: true, scale: 1 }));
  const pptx = await PresentationFile.exportPptx(deck);
  await pptx.save(OUT_PPTX);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
