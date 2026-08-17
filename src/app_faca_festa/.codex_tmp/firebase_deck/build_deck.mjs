import fs from "node:fs/promises";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const OUT_DIR = "D:/repository/unicesumar/tcc/app/src/app_faca_festa/.codex_tmp/firebase_deck/rendered";
const OUT_PPTX = "D:/repository/unicesumar/tcc/app/src/app_faca_festa/document/Apresentacao_Mapeamento_Firebase_Faca_Festa.pptx";
const W = 1280;
const H = 720;
const ink = "#111111";
const muted = "#59616C";
const panel = "#F0F2F4";
const rule = "#BBC1C8";
const accent = "#3D8DFF";
const accentSoft = "#DCEBFF";
const dangerSoft = "#FFF0ED";
const font = "Arial";

async function writeBlob(path, blob) {
  await fs.writeFile(path, new Uint8Array(await blob.arrayBuffer()));
}

function addText(slide, value, left, top, width, height, options = {}) {
  const box = slide.shapes.add({
    geometry: "textbox",
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

function addFooter(slide, number) {
  addText(slide, String(number).padStart(2, "0"), 1170, 668, 68, 24, {
    fontSize: 12,
    color: muted,
    alignment: "right",
  });
}

function addTitle(slide, title, subtitle, number) {
  addText(slide, title, 42, 34, 1196, 70, { fontSize: 38, bold: true });
  if (subtitle) addText(slide, subtitle, 42, 112, 1196, 60, { fontSize: 19, color: muted });
  addFooter(slide, number);
}

function addNotes(slide, talk, sources) {
  slide.speakerNotes.textFrame.setText(
    `${talk}\n\n[Sources]\n${sources.map((s) => `- ${s}`).join("\n")}`,
  );
  slide.speakerNotes.setVisible(true);
}

function addTable(slide, values, columnWidths, top = 205, height = 420) {
  const table = slide.tables.add({
    rows: values.length,
    columns: values[0].length,
    left: 42,
    top,
    width: 1196,
    height,
    columnWidths,
    values,
  });
  table.styleOptions = { headerRow: true, bandedRows: true };
  table.borders.assign({ style: "solid", fill: rule, width: 1 });
  const all = table.cells.block({ row: 0, column: 0, rowCount: values.length, columnCount: values[0].length });
  all.textStyle.fontSize = 16;
  all.textStyle.color = ink;
  all.margins = { left: 8, right: 8, top: 6, bottom: 6 };
  const header = table.cells.block({ row: 0, column: 0, rowCount: 1, columnCount: values[0].length });
  header.fill = ink;
  header.textStyle.color = "#FFFFFF";
  header.textStyle.bold = true;
  header.textStyle.fontSize = 17;
  return table;
}

function addPanel(slide, left, top, width, height, fill = panel) {
  return slide.shapes.add({
    geometry: "rect",
    position: { left, top, width, height },
    fill,
    line: { style: "solid", fill: fill, width: 0 },
  });
}

async function main() {
  await fs.mkdir(OUT_DIR, { recursive: true });
  const deck = Presentation.create({ slideSize: { width: W, height: H } });

  // 1 — Codex Grid cover hierarchy (layout 01)
  {
    const slide = deck.slides.add();
    slide.background.fill = "#FFFFFF";
    addText(slide, "FAÇA A FESTA · BANCO DE DADOS", 42, 42, 620, 40, { fontSize: 22, bold: true, color: accent });
    addText(slide, "O que o aplicativo realmente usa no Firebase", 42, 184, 1030, 220, { fontSize: 58, bold: true });
    addText(slide, "Coleções, documentos, campos e chaves lógicas mapeados a partir do código", 42, 510, 820, 90, { fontSize: 25, color: muted });
    addText(slide, "Apresentação técnica · 10 minutos", 42, 640, 500, 28, { fontSize: 16, color: muted });
    addNotes(slide,
      "Abra dizendo que o objetivo não foi desenhar um banco ideal, mas comprovar o banco que o código usa hoje. Explique que o levantamento cruzou modelos, acessos do app e Cloud Functions.",
      ["lib/data/models/**", "lib/controllers/**", "lib/data/repositories/**", "functions/src/**"],
    );
  }

  // 2 — layout 19: three headline statistics
  {
    const slide = deck.slides.add();
    addTitle(slide, "Os 74 modelos não equivalem a 74 tabelas", "Só foram contabilizados caminhos com evidência de leitura ou gravação no Firestore.", 2);
    const stats = [
      ["29", "coleções raiz", "Usadas pelo app ou pelas Cloud Functions"],
      ["17", "caminhos de subcoleção", "Dados aninhados sob usuário, evento, cotação e outros"],
      ["74", "arquivos de modelo", "Incluem DTOs, projeções, cálculos e armazenamento local"],
    ];
    stats.forEach((s, i) => {
      const left = 42 + i * 411;
      addPanel(slide, left, 300, 374, 320, i === 1 ? accentSoft : panel);
      addText(slide, s[0], left + 30, 334, 310, 106, { fontSize: 66, bold: true, color: i === 1 ? accent : ink });
      addText(slide, s[1], left + 30, 455, 310, 42, { fontSize: 24, bold: true });
      addText(slide, s[2], left + 30, 515, 310, 78, { fontSize: 17, color: muted });
    });
    addNotes(slide,
      "Esta é a principal correção do mapeamento antigo: classe não significa coleção. Há modelos para telas administrativas, respostas de IA, DTOs e banco local. A apresentação passa a focar somente nos caminhos comprovados.",
      ["lib/data/models/** (74 arquivos .dart)", "Ocorrências de collection(...) em lib/**", "Constantes de coleção em functions/src/**"],
    );
  }

  // 3 — layout 17: three-stage data hierarchy
  {
    const slide = deck.slides.add();
    addTitle(slide, "No Firestore, a estrutura é coleção → documento → subcoleção", "As relações existem por convenção do código; não há chave estrangeira automática.", 3);
    const y = 340;
    slide.shapes.add({ geometry: "straightConnector1", position: { left: 70, top: y, width: 1090, height: 0 }, fill: "none", line: { style: "solid", fill: ink, width: 2 } });
    const items = [
      [90, "COLEÇÃO", "evento", "Agrupa documentos do mesmo domínio"],
      [465, "DOCUMENTO", "{idEvento}", "A PK real é o ID do caminho"],
      [840, "SUBCOLEÇÃO", "presentes/{id}", "Dados filhos ficam aninhados"],
    ];
    items.forEach(([x, label, main, desc], idx) => {
      slide.shapes.add({ geometry: "ellipse", position: { left: x, top: y - 7, width: 15, height: 15 }, fill: idx === 1 ? accent : ink, line: { style: "solid", fill: "none", width: 0 } });
      addText(slide, label, x, 278, 240, 32, { fontSize: 16, bold: true, color: muted });
      addText(slide, main, x, 390, 300, 45, { fontSize: 29, bold: true });
      addText(slide, desc, x, 447, 300, 80, { fontSize: 18, color: muted });
    });
    addText(slide, "Exemplo completo: evento/{idEvento}/presentes/{idPresente}/contributions/{id}", 90, 585, 1050, 38, { fontSize: 20, bold: true, color: accent });
    addNotes(slide,
      "Use um exemplo concreto. O documento do evento pode ter presentes; cada presente pode ter contribuições. Campos como id_evento funcionam como FK lógica, mas o Firestore não impede que apontem para um documento inexistente.",
      ["lib/data/datasources/remote/gift_remote_datasource.dart:12-151", "lib/data/models/gift/gift_model.dart", "lib/data/models/gift/gift_contribution_model.dart"],
    );
  }

  // 4 — core data table
  {
    const slide = deck.slides.add();
    addTitle(slide, "O núcleo liga usuário, evento e operação da festa", "A maior parte das consultas filtra os documentos filhos por id_evento.", 4);
    addTable(slide, [
      ["Coleção", "PK do documento", "FKs lógicas", "Campos mais usados"],
      ["usuarios", "UID / id_usuario", "—", "nome, email, tipo, ativo, cidade, uf"],
      ["evento", "id_evento", "id_usuario, id_tipo_evento", "nome_evento, data, status, totais, endereço"],
      ["convidado", "id_convidado", "id_evento, id_grupo, id_mesa", "nome, contato, status, tipo_convidado"],
      ["grupos_convidado", "id_grupo", "id_evento", "nome, cor_hex, totais e datas"],
      ["tarefa", "id_tarefa", "id_evento, id_responsavel", "titulo, data_prevista, status"],
      ["cardapios/{id}/itens", "id_cardapio / id_item", "id_evento", "tipo, público, quantidades, confirmado"],
    ], [220, 230, 300, 446], 195, 440);
    addNotes(slide,
      "Apresente primeiro o caminho principal: o usuário cria um evento; convidados e tarefas referenciam o evento; cardápios possuem itens aninhados. Ressalte que o ID costuma ser repetido no corpo do documento.",
      ["lib/data/models/usuario/usuario_model.dart", "lib/data/models/evento/evento_model.dart", "lib/data/models/convidado/convidado_model.dart", "lib/data/models/tarefa/tarefa_model.dart", "lib/controllers/convidado/cardapio_controller.dart"],
    );
  }

  // 5 — supplier data table
  {
    const slide = deck.slides.add();
    addTitle(slide, "O catálogo de fornecedores usa coleções de ligação", "Fornecedor e serviço têm uma relação muitos-para-muitos representada por documentos intermediários.", 5);
    addTable(slide, [
      ["Coleção", "PK", "Vínculo", "Campos principais"],
      ["fornecedor", "UID / id_fornecedor", "id_usuario", "razão social, CNPJ, ativo, preços, métricas"],
      ["categoria_servico", "id", "—", "nome, descrição, ativo"],
      ["subcategoria_servico", "id", "id_categoria", "nome, descrição, ativo"],
      ["servico_produto", "id", "id_subcategoria", "nome, tipo_medida, descrição, ativo"],
      ["fornecedor_categoria", "auto", "fornecedor + categoria", "nome_categoria, subcategorias, cadastro"],
      ["fornecedor_servico", "geralmente composto", "fornecedor + serviço", "preço, promoção, ativo, avaliações"],
      ["territorio / servico_foto", "id próprio", "id_fornecedor", "cobertura geográfica / URLs do catálogo"],
    ], [240, 220, 285, 451], 185, 455);
    addNotes(slide,
      "Explique a função das coleções de ligação. fornecedor_categoria e fornecedor_servico evitam colocar todo o catálogo em um único documento e permitem consultas por fornecedor, categoria e serviço.",
      ["lib/data/models/fornecedor/fornecedor_model.dart", "lib/data/models/servico_produto/**", "lib/controllers/servico/servico_produto_controller.dart", "lib/controllers/fornecedor/fornecedor_controller.dart"],
    );
  }

  // 6 — commercial flow
  {
    const slide = deck.slides.add();
    addTitle(slide, "A cotação concentra propostas, serviços e mensagens", "O orçamento fechado é gravado em outra coleção e detalhado por uma subcoleção de gastos.", 6);
    addTable(slide, [
      ["Caminho", "Chave", "Referências", "Campos centrais"],
      ["cotacao/{id}", "idCotacao", "evento + solicitante", "descrição, categoria, datas, status"],
      [".../fornecedores/{id}", "idFornecedor", "cotação + fornecedor", "prazo, pagamento, status, resposta"],
      [".../servicos/{id}", "idServico", "produto/serviço", "quantidade, valor unitário e total"],
      [".../mensagens/{id}", "automática", "id_usuario", "mensagem, data, lido"],
      ["orcamento/{id}", "id_orcamento", "evento + fornecedor", "custo, status, datas, anotações"],
      [".../orcamento_gasto/{id}", "id_gasto", "orçamento + serviço", "nome, custo, pago, cadastro"],
    ], [295, 205, 275, 421], 195, 440);
    addNotes(slide,
      "Mostre que cotação é um agregado aninhado: fornecedores, serviços e chat ficam abaixo dela. Quando há fechamento, o sistema também cria orçamento, que passa a controlar gastos e pagamento.",
      ["lib/controllers/contacao/cotacao_controller.dart", "lib/controllers/contacao/solicitacoes_controller.dart", "lib/controllers/orcamento_controller.dart", "lib/controllers/orcamento_gasto_controller.dart", "lib/presentation/pages/fornecedor/chat/chat_mensagens_page.dart"],
    );
  }

  // 7 — advanced modules
  {
    const slide = deck.slides.add();
    addTitle(slide, "Módulos avançados ampliam o banco sem criar tabelas para cada modelo", "Calculadora, inspiração, presentes e recomendação usam documentos compostos e histórico aninhado.", 7);
    addTable(slide, [
      ["Domínio", "Coleções", "Chaves / estrutura", "Dados relevantes"],
      ["Calculadora", "calculadora_festa + itens", "id_calculo; itens filhos", "perfil, convidados, custos, status"],
      ["IA da calculadora", "analises_ia", "filha do cálculo", "índices, diagnóstico, versões de prompt/schema"],
      ["Base de cálculo", "calculadora_*_itens", "IDs semânticos", "regras, unidade, público, ordem, ativo"],
      ["Inspiração", "inspiracoes + referencias", "referência filha do evento", "imagens, tags, favoritos, sugestões"],
      ["Presentes", "presentes + contributions", "filhas do evento/presente", "reserva, meta, arrecadação, contribuições"],
      ["Recomendação", "fornecedor_*", "evento + fornecedor + usuário", "interações, score, motivos e compatibilidade"],
    ], [220, 275, 285, 416], 190, 445);
    addNotes(slide,
      "Esta parte demonstra por que modelos de resposta de IA não devem ser contados automaticamente como tabelas. Só entram no mapa quando existe um caminho persistido, como calculadora_festa/analises_ia.",
      ["lib/data/repositories/calculadora_festa_repository.dart", "functions/src/services/calculadora/calculadoraFirestoreService.ts", "lib/controllers/inspiracao/inspiracao_controller.dart", "lib/data/datasources/remote/gift_remote_datasource.dart", "functions/src/services/fornecedores/**"],
    );
  }

  // 8 — three key types
  {
    const slide = deck.slides.add();
    addTitle(slide, "As chaves são lógicas — o código precisa manter a consistência", "Três estratégias aparecem repetidamente na implementação.", 8);
    const cols = [
      ["PK do documento", "evento/{idEvento}", "É a identidade real no Firestore. Em vários casos ela também é repetida como id_evento."],
      ["FK textual", "tarefa.id_evento", "Permite consultas com where(), mas não impede referência órfã após uma exclusão."],
      ["ID composto", "fornecedor_servico/{fornecedor_servico}", "Evita duplicidade de vínculo, desde que todos os pontos usem a mesma fórmula."],
    ];
    cols.forEach((c, i) => {
      const left = 42 + i * 411;
      addPanel(slide, left, 250, 374, 360, i === 0 ? accentSoft : panel);
      addText(slide, c[0], left + 28, 285, 318, 42, { fontSize: 24, bold: true });
      addText(slide, c[1], left + 28, 355, 318, 55, { fontSize: 22, bold: true, color: accent });
      addText(slide, c[2], left + 28, 440, 318, 125, { fontSize: 18, color: muted });
    });
    addNotes(slide,
      "Diferencie PK real, FK lógica e ID composto. O ganho de flexibilidade do NoSQL exige disciplina: as relações não são validadas pelo banco como em SQL.",
      ["lib/controllers/evento_controller.dart", "lib/controllers/tarefa_controller.dart", "lib/controllers/avaliacao/avaliacao_servico_controller.dart", "lib/controllers/servico/servico_produto_controller.dart"],
    );
  }

  // 9 — findings
  {
    const slide = deck.slides.add();
    addTitle(slide, "Quatro pontos hoje podem gerar dados divergentes", "O problema principal não é o Firestore; é a falta de uma convenção única entre os módulos.", 9);
    const findings = [
      ["1", "Avaliações em várias origens", "fornecedor/avaliacoes, fornecedor_servico/avaliacoes, avaliacao_fornecedor, avaliacoes e fornecedor_avaliacoes"],
      ["2", "Dois caminhos para tarefas e orçamento", "Coleções raiz coexistem com evento/{id}/tarefas e evento/{id}/orcamento"],
      ["3", "snake_case + camelCase", "Recomendações mantêm consultas de compatibilidade para os dois padrões"],
      ["4", "Regras fora do versionamento", "firebase.json não referencia firestore.rules nem firestore.indexes.json"],
    ];
    findings.forEach((f, i) => {
      const row = Math.floor(i / 2);
      const col = i % 2;
      const left = 42 + col * 610;
      const top = 205 + row * 205;
      addPanel(slide, left, top, 575, 170, i === 3 ? dangerSoft : panel);
      addText(slide, f[0], left + 24, top + 25, 48, 52, { fontSize: 32, bold: true, color: accent });
      addText(slide, f[1], left + 88, top + 22, 455, 42, { fontSize: 22, bold: true });
      addText(slide, f[2], left + 88, top + 76, 455, 72, { fontSize: 16, color: muted });
    });
    addNotes(slide,
      "Apresente estes pontos como achados do código, não como falhas do banco. Eles explicam por que o novo mapeamento deve ser mantido como contrato de dados.",
      ["lib/controllers/avaliacao/avaliacao_servico_controller.dart", "lib/controllers/inspiracao/inspiracao_controller.dart", "lib/controllers/fornecedor/fornecedor_recomendacao_controller.dart", "firebase.json"],
    );
  }

  // 10 — close, Codex Grid end hierarchy
  {
    const slide = deck.slides.add();
    addText(slide, "CONCLUSÃO", 42, 42, 300, 36, { fontSize: 22, bold: true, color: accent });
    addText(slide, "O próximo passo é transformar o mapa em contrato de dados", 42, 175, 1050, 180, { fontSize: 54, bold: true });
    const actions = [
      "1. Padronizar nomes e campos obrigatórios",
      "2. Escolher uma fonte por conceito",
      "3. Versionar regras, índices e exclusões em cascata",
    ];
    actions.forEach((a, i) => addText(slide, a, 42, 455 + i * 52, 1000, 36, { fontSize: 22, color: i === 0 ? accent : ink, bold: i === 0 }));
    addText(slide, "Resultado: banco explicável, consultas previsíveis e menos risco de documentos órfãos.", 42, 635, 1110, 32, { fontSize: 18, color: muted });
    addNotes(slide,
      "Feche retomando a pergunta inicial: agora sabemos o que é realmente persistido. A recomendação é manter este dicionário junto do código e usar uma única convenção por domínio.",
      ["document/MAPEAMENTO_FIREBASE_APRESENTACAO.md", "Levantamento consolidado em 11/08/2026"],
    );
  }

  for (const [index, slide] of deck.slides.items.entries()) {
    const stem = `slide-${String(index + 1).padStart(2, "0")}`;
    const png = await deck.export({ slide, format: "png", scale: 1 });
    await writeBlob(`${OUT_DIR}/${stem}.png`, png);
    const layout = await slide.export({ format: "layout" });
    await fs.writeFile(`${OUT_DIR}/${stem}.layout.json`, await layout.text());
  }
  const montage = await deck.export({ format: "webp", montage: true, scale: 1 });
  await writeBlob(`${OUT_DIR}/montage.webp`, montage);
  const pptx = await PresentationFile.exportPptx(deck);
  await pptx.save(OUT_PPTX);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
