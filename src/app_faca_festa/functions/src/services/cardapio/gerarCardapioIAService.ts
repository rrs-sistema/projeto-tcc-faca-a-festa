import {
  TIPOS_ITEM_PERMITIDOS,
  UNIDADES_PERMITIDAS,
  PUBLICOS_PERMITIDOS,
  CARDAPIO_IA_SCHEMA_VERSION,
} from "../../ia/cardapio/schema";
import {
  CardapioIaEntrada,
  buildInput,
  buildInstructions,
} from "../../ia/cardapio/prompt";

export type CardapioIaItem = {
  nome: string;
  tipo: string;
  quantidade: number;
  unidade: string;
  observacao: string | null;
  publico_alvo: string;
};

export type CardapioIaCategoria = {
  nome: string;
  itens: CardapioIaItem[];
};

export type CardapioIaSugestao = {
  nome_cardapio: string;
  resumo_publico: string;
  justificativa: string;
  premissas: string[];
  bebes_considerados: boolean;
  aviso_bebes: string | null;
  categorias: CardapioIaCategoria[];
  fonte: "ia_generativa" | "fallback_local";
  versao_schema: string;
  aviso_estimativa: string;
};

const AVISO_ESTIMATIVA =
  "As quantidades são estimativas e podem variar conforme a duração da festa e o perfil dos convidados.";

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

function asString(value: unknown, fallback = ""): string {
  if (typeof value === "string") return value.trim();
  if (typeof value === "number" && Number.isFinite(value)) return String(value);
  return fallback;
}

function asNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim()) {
    const n = Number(value.replace(",", "."));
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

function normalizarUnidade(raw: string): string {
  const u = raw.trim().toLowerCase();
  if (u === "litro" || u === "litros" || u === "lt") return "l";
  if (u === "unidade" || u === "unidades" || u === "und") return "un";
  if (u === "quilo" || u === "quilos" || u === "kilo" || u === "kilos") {
    return "kg";
  }
  if (u === "grama" || u === "gramas") return "g";
  return u;
}

function normalizarTipo(raw: string): string {
  const t = raw
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
  if (t.includes("bebida")) return "bebida";
  if (t.includes("sobremesa") || t.includes("doce")) return "sobremesa";
  if (t.includes("bolo")) return "bolo";
  if (t.includes("descart")) return "descartavel";
  if (t.includes("comida") || t.includes("salgado") || t.includes("prato")) {
    return "comida";
  }
  return TIPOS_ITEM_PERMITIDOS.includes(t as (typeof TIPOS_ITEM_PERMITIDOS)[number])
    ? t
    : "outro";
}

function normalizarPublico(raw: string): string {
  const p = raw
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
  if (p.startsWith("adult")) return "adultos";
  if (p.startsWith("crianc")) return "criancas";
  if (p.startsWith("beb")) return "bebes";
  return "todos";
}

function arredondarQuantidade(q: number, unidade: string): number {
  if (unidade === "un") return Math.max(1, Math.round(q));
  if (unidade === "g") return Math.max(1, Math.round(q / 10) * 10);
  return Math.round(q * 10) / 10;
}

export function validarENormalizarSugestao(
  raw: unknown,
  entrada: CardapioIaEntrada,
  fonte: CardapioIaSugestao["fonte"],
): CardapioIaSugestao | null {
  const data = asRecord(raw);
  const categoriasRaw = Array.isArray(data.categorias) ? data.categorias : [];
  const categorias: CardapioIaCategoria[] = [];

  for (const catRaw of categoriasRaw.slice(0, 8)) {
    const cat = asRecord(catRaw);
    const nomeCat = asString(cat.nome);
    const itensRaw = Array.isArray(cat.itens) ? cat.itens : [];
    if (!nomeCat || itensRaw.length === 0) continue;

    const itens: CardapioIaItem[] = [];
    for (const itemRaw of itensRaw.slice(0, 12)) {
      const item = asRecord(itemRaw);
      const nome = asString(item.nome);
      if (!nome || nome.length > 80) continue;

      const unidade = normalizarUnidade(asString(item.unidade, "un"));
      if (!(UNIDADES_PERMITIDAS as readonly string[]).includes(unidade)) {
        continue;
      }

      const quantidade = asNumber(item.quantidade);
      if (quantidade == null || quantidade <= 0 || quantidade > 100000) continue;

      const tipo = normalizarTipo(asString(item.tipo, "outro"));
      if (!(TIPOS_ITEM_PERMITIDOS as readonly string[]).includes(tipo)) continue;

      const publico = normalizarPublico(asString(item.publico_alvo, "todos"));
      if (!(PUBLICOS_PERMITIDOS as readonly string[]).includes(publico)) continue;

      // Bebidas alcoólicas não entram por padrão.
      const nomeLower = nome.toLowerCase();
      const alcool =
        /(cerveja|vinho|espumante|whisky|vodka|gim|gin|caipirinha|drink alco|sangria|chopp|champanhe|champagne)/i
          .test(nomeLower);
      const pediuAlcool = /alcool|alcoó|cerveja|vinho/i.test(
        `${entrada.observacoes ?? ""} ${entrada.restricoes ?? ""}`,
      );
      if (alcool && !pediuAlcool) continue;

      const observacao = asString(item.observacao) || null;
      itens.push({
        nome,
        tipo,
        quantidade: arredondarQuantidade(quantidade, unidade),
        unidade,
        observacao: observacao && observacao.length > 180
          ? observacao.slice(0, 180)
          : observacao,
        publico_alvo: publico,
      });
    }

    if (itens.length > 0) {
      categorias.push({ nome: nomeCat.slice(0, 60), itens });
    }
  }

  if (categorias.length === 0) return null;

  const bebesInformados = (entrada.bebes ?? 0) > 0;
  const bebesConsiderados = data.bebes_considerados === true && bebesInformados;
  let avisoBebes = asString(data.aviso_bebes) || null;
  if (bebesInformados && !bebesConsiderados && !avisoBebes) {
    avisoBebes =
      "Bebês informados não foram considerados nas porções gerais do cardápio.";
  }

  const premissas = (Array.isArray(data.premissas) ? data.premissas : [])
    .map((p) => asString(p))
    .filter(Boolean)
    .slice(0, 8);

  if (premissas.length === 0) {
    premissas.push(
      `Estimativa para ${entrada.total_pessoas} pessoas no ${entrada.momento_refeicao}.`,
    );
  }

  return {
    nome_cardapio: asString(data.nome_cardapio, `Cardápio — ${entrada.momento_refeicao}`)
      .slice(0, 80),
    resumo_publico: asString(
      data.resumo_publico,
      montarResumoPublico(entrada),
    ).slice(0, 160),
    justificativa: asString(
      data.justificativa,
      "Sugestão montada conforme o tipo de festa, a refeição e o público informado.",
    ).slice(0, 400),
    premissas,
    bebes_considerados: bebesConsiderados,
    aviso_bebes: avisoBebes,
    categorias,
    fonte,
    versao_schema: CARDAPIO_IA_SCHEMA_VERSION,
    aviso_estimativa: AVISO_ESTIMATIVA,
  };
}

export function montarResumoPublico(entrada: CardapioIaEntrada): string {
  const partes: string[] = [];
  if (entrada.adultos != null || entrada.criancas != null) {
    if (entrada.adultos != null) partes.push(`${entrada.adultos} adultos`);
    if (entrada.criancas != null) partes.push(`${entrada.criancas} crianças`);
    if ((entrada.bebes ?? 0) > 0) partes.push(`${entrada.bebes} bebês`);
  } else {
    partes.push(`${entrada.total_pessoas} pessoas`);
  }
  return `${partes.join(" · ")} · ${entrada.momento_refeicao}`;
}

export function construirFallbackLocal(
  entrada: CardapioIaEntrada,
): CardapioIaSugestao {
  const total = Math.max(1, entrada.total_pessoas);
  const adultos = entrada.adultos ?? total;
  const criancas = entrada.criancas ?? 0;
  const momento = entrada.momento_refeicao.toLowerCase();
  const estilo = (entrada.estilo ?? "tradicional").toLowerCase();
  const fatorEstilo = estilo.includes("econom")
    ? 0.85
    : estilo.includes("elabor")
      ? 1.15
      : 1;
  const duracao = entrada.duracao_horas && entrada.duracao_horas > 0
    ? entrada.duracao_horas
    : momento.includes("churrasco")
      ? 4
      : momento.includes("coquetel")
        ? 3
        : 3;

  const equiv = adultos + criancas * 0.6;
  const litrosAgua = arredondarQuantidade(
    Math.max(2, (equiv * 0.4 * (duracao / 3)) * fatorEstilo),
    "l",
  );
  const litrosRefri = arredondarQuantidade(
    Math.max(1, (equiv * 0.35 * (duracao / 3)) * fatorEstilo),
    "l",
  );

  const categorias: CardapioIaCategoria[] = [
    {
      nome: "Bebidas",
      itens: [
        {
          nome: "Água mineral",
          tipo: "bebida",
          quantidade: litrosAgua,
          unidade: "l",
          observacao:
            "Quantidade estimada para o público e duração informados.",
          publico_alvo: "todos",
        },
        {
          nome: "Refrigerante ou suco",
          tipo: "bebida",
          quantidade: litrosRefri,
          unidade: "l",
          observacao: "Alternativas dividem o consumo total estimado.",
          publico_alvo: "todos",
        },
      ],
    },
  ];

  if (momento.includes("churrasco")) {
    categorias.push({
      nome: "Carnes e acompanhamentos",
      itens: [
        {
          nome: "Carne para churrasco (mista)",
          tipo: "comida",
          quantidade: arredondarQuantidade(equiv * 0.35 * fatorEstilo, "kg"),
          unidade: "kg",
          observacao: "Peso estimado de compra cru, antes do rendimento.",
          publico_alvo: "todos",
        },
        {
          nome: "Pão de alho / farofa",
          tipo: "comida",
          quantidade: arredondarQuantidade(equiv * 0.08 * fatorEstilo, "kg"),
          unidade: "kg",
          observacao: null,
          publico_alvo: "todos",
        },
      ],
    });
  } else if (
    momento.includes("coquetel") ||
    momento.includes("lanche") ||
    momento.includes("café")
  ) {
    categorias.push({
      nome: "Salgados e doces",
      itens: [
        {
          nome: "Salgados variados",
          tipo: "comida",
          quantidade: arredondarQuantidade(
            Math.max(total * 6, equiv * 8) * fatorEstilo,
            "un",
          ),
          unidade: "un",
          observacao: "Variedades compartilham o total; não somar por tipo.",
          publico_alvo: "todos",
        },
        {
          nome: "Docinhos",
          tipo: "sobremesa",
          quantidade: arredondarQuantidade(total * 4 * fatorEstilo, "un"),
          unidade: "un",
          observacao: null,
          publico_alvo: "todos",
        },
      ],
    });
  } else {
    categorias.push({
      nome: "Pratos principais",
      itens: [
        {
          nome: "Prato principal (proteína)",
          tipo: "comida",
          quantidade: arredondarQuantidade(equiv * 0.18 * fatorEstilo, "kg"),
          unidade: "kg",
          observacao: "Estimativa de porção pronta para servir.",
          publico_alvo: "adultos",
        },
        {
          nome: "Acompanhamentos (arroz, salada ou massa)",
          tipo: "comida",
          quantidade: arredondarQuantidade(equiv * 0.15 * fatorEstilo, "kg"),
          unidade: "kg",
          observacao: "Acompanhamentos dividem o consumo entre si.",
          publico_alvo: "todos",
        },
      ],
    });
    categorias.push({
      nome: "Sobremesas",
      itens: [
        {
          nome: "Sobremesa compartilhada",
          tipo: "sobremesa",
          quantidade: arredondarQuantidade(
            Math.max(1, total / 10) * fatorEstilo,
            "un",
          ),
          unidade: "un",
          observacao: null,
          publico_alvo: "todos",
        },
      ],
    });
  }

  if (criancas > 0) {
    categorias.push({
      nome: "Opções infantis",
      itens: [
        {
          nome: "Mini sanduíches ou salgadinhos infantis",
          tipo: "comida",
          quantidade: arredondarQuantidade(criancas * 4 * fatorEstilo, "un"),
          unidade: "un",
          observacao: "Porções pensadas para o público infantil informado.",
          publico_alvo: "criancas",
        },
      ],
    });
  }

  const bebesInformados = (entrada.bebes ?? 0) > 0;
  const restricaoAlcool = /sem\s+bebidas?\s+alc|sem\s+alcool|não\s+alcool/i.test(
    `${entrada.observacoes ?? ""} ${entrada.restricoes ?? ""}`,
  );

  return {
    nome_cardapio: `Cardápio — ${entrada.momento_refeicao}`,
    resumo_publico: montarResumoPublico(entrada),
    justificativa:
      "Sugestão local com base em porções médias por pessoa, ajustadas ao momento da refeição e ao estilo informado.",
    premissas: [
      `Público estimado: ${montarResumoPublico(entrada)}.`,
      `Duração considerada: cerca de ${duracao} hora(s).`,
      "Itens semelhantes dividem o consumo total.",
      restricaoAlcool
        ? "Restrição de bebidas alcoólicas respeitada."
        : "Bebidas alcoólicas não foram incluídas por padrão.",
    ],
    bebes_considerados: false,
    aviso_bebes: bebesInformados
      ? "Bebês informados não foram considerados nas porções gerais do cardápio."
      : null,
    categorias,
    fonte: "fallback_local",
    versao_schema: CARDAPIO_IA_SCHEMA_VERSION,
    aviso_estimativa: AVISO_ESTIMATIVA,
  };
}

export async function chamarOpenAiCardapio(
  entrada: CardapioIaEntrada,
  apiKey: string,
  modelo = "gpt-4.1-mini",
): Promise<unknown> {
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    signal: AbortSignal.timeout(50000),
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: modelo,
      temperature: 0.35,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: buildInstructions() },
        { role: "user", content: buildInput(entrada) },
      ],
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Provider IA retornou HTTP ${response.status}: ${body}`);
  }

  const data = asRecord(await response.json());
  const choices = Array.isArray(data.choices) ? data.choices : [];
  const first = asRecord(choices[0]);
  const message = asRecord(first.message);
  const content = asString(message.content);
  if (!content) throw new Error("Resposta da IA sem conteúdo JSON.");
  return JSON.parse(content);
}

export function normalizarEntrada(
  raw: Record<string, unknown>,
): CardapioIaEntrada {
  const tipo = asString(raw.tipo_festa ?? raw.tipoFesta);
  const momento = asString(raw.momento_refeicao ?? raw.momentoRefeicao);
  const total = asNumber(raw.total_pessoas ?? raw.totalPessoas);
  if (!tipo) throw new Error("Informe o tipo de festa.");
  if (!momento) throw new Error("Informe o momento da refeição.");
  if (total == null || total <= 0) {
    throw new Error("Informe a quantidade de pessoas maior que zero.");
  }
  if (total > 5000) throw new Error("Quantidade de pessoas acima do limite.");

  const adultos = asNumber(raw.adultos);
  const criancas = asNumber(raw.criancas ?? raw.crianças);
  const bebes = asNumber(raw.bebes ?? raw.bebês);
  const duracao = asNumber(raw.duracao_horas ?? raw.duracaoHoras);

  return {
    tipo_festa: tipo.slice(0, 60),
    total_pessoas: Math.round(total),
    adultos: adultos != null && adultos >= 0 ? Math.round(adultos) : null,
    criancas: criancas != null && criancas >= 0 ? Math.round(criancas) : null,
    bebes: bebes != null && bebes >= 0 ? Math.round(bebes) : null,
    momento_refeicao: momento.slice(0, 40),
    estilo: asString(raw.estilo) || null,
    restricoes: asString(raw.restricoes ?? raw.restrições).slice(0, 400) || null,
    observacoes: asString(raw.observacoes ?? raw.observações).slice(0, 400) ||
      null,
    duracao_horas:
      duracao != null && duracao > 0 && duracao <= 24 ? duracao : null,
  };
}
