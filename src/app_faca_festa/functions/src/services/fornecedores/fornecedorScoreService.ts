import {
  EventoRecomendacaoContexto,
  FornecedorCandidato,
  FornecedorCategoriaVinculo,
  InteracaoFornecedorResumo,
  ScoreFornecedorResultado,
  TerritorioFornecedor,
} from "../../types/fornecedorRecomendacao.types";
import { PESOS_RECOMENDACAO_FORNECEDOR } from "../../ia/fornecedores/recomendacao/pesos";

export function calcularScoreFornecedor(params: {
  evento: EventoRecomendacaoContexto;
  fornecedor: FornecedorCandidato;
  categoriasFornecedor: FornecedorCategoriaVinculo[];
  territorio?: TerritorioFornecedor;
  interacao?: InteracaoFornecedorResumo;
}): ScoreFornecedorResultado {
  const { evento, fornecedor, categoriasFornecedor, territorio, interacao } = params;

  let score = 0;
  const motivos: string[] = [];

  const categoriaPrincipal = resolverCategoriaPrincipal(fornecedor, categoriasFornecedor);
  const distanciaKm = calcularDistanciaEventoFornecedor(evento, territorio);

  const compatibilidadeTipoEvento = calcularCompatibilidadeTipoEvento(evento, fornecedor);

  if (compatibilidadeTipoEvento.tipoEventoIncompativel) {
    return {
      score: 0,
      nivel: "incompativel",
      nivelLabel: "Incompatível com este evento",
      motivos: compatibilidadeTipoEvento.motivos,
      motivoPrincipal: compatibilidadeTipoEvento.motivos[0] ?? "Fornecedor incompatível com o tipo de evento",
      distanciaKm,
      categoriaPrincipal,
      tipoEventoInformado: true,
      tipoEventoCompativel: false,
      tipoEventoIncompativel: true,
    };
  }

  score += compatibilidadeTipoEvento.score;
  motivos.push(...compatibilidadeTipoEvento.motivos);

  // Com poucos fornecedores cadastrados, nem todo evento possui categoriasNecessarias
  // preenchidas. Por isso, além das categorias salvas no evento, usamos um perfil
  // esperado por tipo de evento para reconhecer fornecedores coerentes, como
  // "Beleza e Estética" para Casamento/Formatura.
  const categoriasEvento = removerDuplicados([
    ...evento.categoriasNecessarias,
    ...resolverCategoriasEsperadasPorTipoEvento(evento),
  ].map(normalizarTexto).filter(Boolean));

  const palavrasEvento = removerDuplicados([
    ...evento.palavrasChave,
    ...categoriasEvento,
  ].map(normalizarTexto).filter(Boolean));

  const categoriasFornecedorNorm = montarCategoriasFornecedorNormalizadas(fornecedor, categoriasFornecedor);

  const possuiCategoriaCompativel = categoriasEvento.some((categoriaEvento) =>
    categoriasFornecedorNorm.some((categoriaFornecedor) =>
      textosSaoCompativeis(categoriaEvento, categoriaFornecedor),
    ),
  );

  if (possuiCategoriaCompativel) {
    score += PESOS_RECOMENDACAO_FORNECEDOR.categoriaCompativel;
    motivos.push("Possui categoria compatível com o tipo de evento");
  }

  // Piso mínimo: se o fornecedor declarou atender o tipo de evento, a
  // compatibilidade inicial não deve ficar baixa apenas porque não há avaliações
  // ou orçamento ainda. Isso evita casos como "Casamento + Beleza" ficar com 34%.
  if (compatibilidadeTipoEvento.tipoEventoCompativel && score < 45) {
    score = 45;
  }

  if (compatibilidadeTipoEvento.tipoEventoCompativel && possuiCategoriaCompativel) {
    score += 12;
    motivos.push("Perfil do fornecedor combina com o evento selecionado");
  }

  const descricaoFornecedor = normalizarTexto(fornecedor.descricao);
  const possuiDescricaoCompativel = palavrasEvento.some((palavra) =>
    palavra.length >= 4 && descricaoFornecedor.includes(palavra),
  );

  if (possuiDescricaoCompativel) {
    score += PESOS_RECOMENDACAO_FORNECEDOR.descricaoCompativel;
    motivos.push("Descrição do serviço combina com o perfil do evento");
  }

  const cidadeEvento = normalizarTexto(evento.cidade);
  const estadoEvento = normalizarTexto(evento.estado);
  const cidadeFornecedor = normalizarTexto(fornecedor.cidade);
  const estadoFornecedor = normalizarTexto(fornecedor.estado);

  if (cidadeEvento && cidadeFornecedor && cidadeEvento === cidadeFornecedor) {
    score += PESOS_RECOMENDACAO_FORNECEDOR.mesmaCidade;
    motivos.push(`Atende a cidade de ${evento.cidade}`);
  } else if (estadoEvento && estadoFornecedor && estadoEvento === estadoFornecedor) {
    score += PESOS_RECOMENDACAO_FORNECEDOR.mesmoEstado;
    motivos.push("Atende o estado do evento");
  }

  const scoreTerritorio = calcularScoreTerritorio({ evento, territorio, distanciaKm });
  score += scoreTerritorio.score;
  motivos.push(...scoreTerritorio.motivos);

  if (fornecedor.ativo !== false && fornecedor.aptoParaOperar !== false) {
    score += 10;
    motivos.push("Fornecedor ativo e apto para atendimento");
  }

  if (fornecedor.mediaAvaliacoes >= 4.5) {
    score += PESOS_RECOMENDACAO_FORNECEDOR.avaliacaoExcelente;
    motivos.push(`Excelente avaliação média: ${fornecedor.mediaAvaliacoes.toFixed(1)}`);
  } else if (fornecedor.mediaAvaliacoes >= 4.0) {
    score += PESOS_RECOMENDACAO_FORNECEDOR.avaliacaoBoa;
    motivos.push(`Boa avaliação média: ${fornecedor.mediaAvaliacoes.toFixed(1)}`);
  } else if (fornecedor.mediaAvaliacoes >= 3.5) {
    score += PESOS_RECOMENDACAO_FORNECEDOR.avaliacaoPositiva;
    motivos.push("Possui avaliações positivas");
  }

  if (fornecedor.totalAvaliacoes >= 20) {
    score += PESOS_RECOMENDACAO_FORNECEDOR.volumeAvaliacoesAlto;
    motivos.push("Possui bom volume de avaliações");
  } else if (fornecedor.totalAvaliacoes >= 5) {
    score += PESOS_RECOMENDACAO_FORNECEDOR.volumeAvaliacoesMedio;
    motivos.push("Já possui avaliações de clientes");
  }

  if (fornecedor.isTopCategoria) {
    score += PESOS_RECOMENDACAO_FORNECEDOR.fornecedorDestaque;
    motivos.push("Fornecedor destaque na categoria");
  }

  if (interacao && interacao.score !== 0) {
    const limitePositivo = PESOS_RECOMENDACAO_FORNECEDOR.limiteInteracaoPositiva;
    const limiteNegativo = PESOS_RECOMENDACAO_FORNECEDOR.limiteInteracaoNegativa;
    const scoreInteracao = Math.max(limiteNegativo, Math.min(limitePositivo, interacao.score));

    score += scoreInteracao;

    if (scoreInteracao > 0) {
      motivos.push("Seu comportamento indica interesse nesse perfil de fornecedor");
    }
  }

  score = Math.max(0, Math.min(PESOS_RECOMENDACAO_FORNECEDOR.scoreMaximo, score));
  score = Number(score.toFixed(2));

  const nivel = definirNivelRecomendacao(score);
  const nivelLabel = definirNivelRecomendacaoLabel(score);
  const motivosUnicos = removerDuplicados(motivos).slice(0, 5);

  return {
    score,
    nivel,
    nivelLabel,
    motivos: motivosUnicos,
    motivoPrincipal: motivosUnicos[0] ?? "Fornecedor compatível com o perfil do evento",
    distanciaKm,
    categoriaPrincipal,
    tipoEventoInformado: compatibilidadeTipoEvento.tipoEventoInformado,
    tipoEventoCompativel: compatibilidadeTipoEvento.tipoEventoCompativel,
    tipoEventoIncompativel: false,
  };
}

function calcularCompatibilidadeTipoEvento(
  evento: EventoRecomendacaoContexto,
  fornecedor: FornecedorCandidato,
): {
  score: number;
  motivos: string[];
  tipoEventoInformado: boolean;
  tipoEventoCompativel: boolean;
  tipoEventoIncompativel: boolean;
} {
  const motivos: string[] = [];

  const eventoId = normalizarTexto(evento.tipoEventoId);
  const eventoNome = normalizarTexto(evento.tipoEventoNome);
  const eventoSlug = normalizarSlug(evento.tipoEventoSlug || evento.tipoEventoNome);

  const eventoTokens = removerDuplicados([
    eventoId,
    eventoNome,
    eventoSlug,
  ].filter(Boolean));

  const fornecedorIds = fornecedor.tipoEventoIds.map(normalizarTexto).filter(Boolean);
  const fornecedorNomes = fornecedor.tipoEventoNomes.map(normalizarTexto).filter(Boolean);
  const fornecedorSlugs = fornecedor.tipoEventoSlugs.map((value) => normalizarSlug(value)).filter(Boolean);

  const fornecedorTokens = removerDuplicados([
    ...fornecedorIds,
    ...fornecedorNomes,
    ...fornecedorSlugs,
    ...fornecedor.tipoEventoNomes.map((value) => normalizarSlug(value)).filter(Boolean),
  ]);

  const tipoEventoInformado = fornecedorTokens.length > 0;
  const eventoTemTipo = eventoTokens.length > 0;

  if (!eventoTemTipo) {
    return {
      score: 0,
      motivos: [],
      tipoEventoInformado,
      tipoEventoCompativel: false,
      tipoEventoIncompativel: false,
    };
  }

  if (!tipoEventoInformado) {
    return {
      score: PESOS_RECOMENDACAO_FORNECEDOR.tipoEventoNaoInformado,
      motivos: ["Fornecedor ainda não informou tipos de evento atendidos"],
      tipoEventoInformado: false,
      tipoEventoCompativel: false,
      tipoEventoIncompativel: false,
    };
  }

  const matchId = eventoId && fornecedorIds.includes(eventoId);
  const matchSlug = eventoSlug && fornecedorSlugs.includes(eventoSlug);
  const matchNome = eventoNome && fornecedorNomes.some((nome) => textosSaoCompativeis(eventoNome, nome));

  if (matchId) {
    motivos.push(`Atende eventos de ${evento.tipoEventoNome || "tipo selecionado"}`);
    return {
      score: PESOS_RECOMENDACAO_FORNECEDOR.tipoEventoId,
      motivos,
      tipoEventoInformado: true,
      tipoEventoCompativel: true,
      tipoEventoIncompativel: false,
    };
  }

  if (matchSlug) {
    motivos.push(`Atende eventos de ${evento.tipoEventoNome || "tipo selecionado"}`);
    return {
      score: PESOS_RECOMENDACAO_FORNECEDOR.tipoEventoSlug,
      motivos,
      tipoEventoInformado: true,
      tipoEventoCompativel: true,
      tipoEventoIncompativel: false,
    };
  }

  if (matchNome) {
    motivos.push(`Possui experiência com ${evento.tipoEventoNome || "esse tipo de evento"}`);
    return {
      score: PESOS_RECOMENDACAO_FORNECEDOR.tipoEventoNome,
      motivos,
      tipoEventoInformado: true,
      tipoEventoCompativel: true,
      tipoEventoIncompativel: false,
    };
  }

  return {
    score: PESOS_RECOMENDACAO_FORNECEDOR.penalidadeTipoEventoIncompativel,
    motivos: [
      `Fornecedor informou outros tipos de evento e não atende ${evento.tipoEventoNome || "o tipo selecionado"}`,
    ],
    tipoEventoInformado: true,
    tipoEventoCompativel: false,
    tipoEventoIncompativel: true,
  };
}

function calcularScoreTerritorio(params: {
  evento: EventoRecomendacaoContexto;
  territorio?: TerritorioFornecedor;
  distanciaKm: number | null;
}): { score: number; motivos: string[] } {
  const { evento, territorio, distanciaKm } = params;

  if (!territorio || territorio.ativo === false) {
    return { score: 0, motivos: [] };
  }

  const motivos: string[] = [];
  let score = 0;

  const tipoCobertura = normalizarTexto(territorio.tipoCobertura);

  if (tipoCobertura === "raio" && distanciaKm !== null && territorio.raioKm !== null) {
    if (distanciaKm <= territorio.raioKm) {
      score += PESOS_RECOMENDACAO_FORNECEDOR.dentroRaioAtendimento;
      motivos.push(`Atende a região do evento (${distanciaKm.toFixed(1)} km de distância)`);
    } else if (distanciaKm <= territorio.raioKm + 10) {
      score += PESOS_RECOMENDACAO_FORNECEDOR.proximoRaioAtendimento;
      motivos.push("Fica próximo da região de atendimento informada");
    }
  }

  if (tipoCobertura === "regiao" && territorio.regioes.length > 0) {
    const cidadeEvento = normalizarTexto(evento.cidade);
    const estadoEvento = normalizarTexto(evento.estado);
    const regioes = territorio.regioes.map(normalizarTexto);

    const atendeRegiaoPorTexto = regioes.some((regiao) =>
      (cidadeEvento && regiao.includes(cidadeEvento)) ||
      (estadoEvento && regiao.includes(estadoEvento)),
    );

    if (atendeRegiaoPorTexto) {
      score += PESOS_RECOMENDACAO_FORNECEDOR.regiaoAtendimentoTexto;
      motivos.push("Território de atendimento compatível com o local do evento");
    }
  }

  return { score, motivos };
}

export function definirNivelRecomendacao(score: number): string {
  if (score >= 85) return "altamente_recomendado";
  if (score >= 65) return "muito_compativel";
  if (score >= 45) return "compativel";
  return "sugestao_complementar";
}

export function definirNivelRecomendacaoLabel(score: number): string {
  if (score >= 85) return "Altamente recomendado";
  if (score >= 65) return "Muito compatível";
  if (score >= 45) return "Compatível";
  return "Sugestão complementar";
}

export function normalizarTexto(valor: unknown): string {
  return String(valor ?? "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9\s_-]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function normalizarSlug(valor: unknown): string {
  return normalizarTexto(valor)
    .replace(/[_\s-]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

function textosSaoCompativeis(a: string, b: string): boolean {
  if (!a || !b) return false;
  if (a === b) return true;
  if (a.length >= 4 && b.includes(a)) return true;
  if (b.length >= 4 && a.includes(b)) return true;
  return normalizarSlug(a) === normalizarSlug(b);
}


function resolverCategoriasEsperadasPorTipoEvento(evento: EventoRecomendacaoContexto): string[] {
  const tipo = normalizarSlug(
    `${evento.tipoEventoId} ${evento.tipoEventoSlug} ${evento.tipoEventoNome}`,
  );

  const comunsSociais = [
    "buffet",
    "bolo",
    "doces",
    "docinhos",
    "salgados",
    "decoracao",
    "decoração",
    "fotografia",
    "filmagem",
    "papelaria",
    "lembrancas",
    "lembranças",
  ];

  if (tipo.includes("casamento") || tipo.includes("302191a2")) {
    return [
      ...comunsSociais,
      "cerimonial",
      "assessoria",
      "noiva",
      "noivo",
      "beleza",
      "estetica",
      "estética",
      "salao",
      "salão",
      "cabelo",
      "maquiagem",
      "penteado",
      "transporte",
      "musica",
      "música",
      "dj",
      "banda",
      "iluminacao",
      "iluminação",
    ];
  }

  if (tipo.includes("festa_infantil") || tipo.includes("infantil") || tipo.includes("ccbdb965")) {
    return [
      ...comunsSociais,
      "buffet infantil",
      "kids",
      "crianca",
      "criança",
      "recreacao",
      "recreação",
      "animacao",
      "animação",
      "brinquedos",
      "playground",
      "personagem",
    ];
  }

  if (tipo.includes("aniversario") || tipo.includes("aniversário") || tipo.includes("7f8aa427")) {
    return [
      ...comunsSociais,
      "festa",
      "recreacao",
      "recreação",
      "animacao",
      "animação",
      "musica",
      "música",
      "dj",
      "beleza",
      "estetica",
      "estética",
    ];
  }

  if (tipo.includes("cha_bebe") || tipo.includes("cha de bebe") || tipo.includes("chá de bebê") || tipo.includes("1eab2c53")) {
    return [
      ...comunsSociais,
      "bebe",
      "bebê",
      "revelacao",
      "revelação",
      "maternidade",
      "lembrancinha",
    ];
  }

  if (tipo.includes("formatura") || tipo.includes("wll")) {
    return [
      ...comunsSociais,
      "cerimonial",
      "baile",
      "colacao",
      "colação",
      "beca",
      "beleza",
      "estetica",
      "estética",
      "salao",
      "salão",
      "cabelo",
      "maquiagem",
      "transporte",
      "musica",
      "música",
      "dj",
      "banda",
      "iluminacao",
      "iluminação",
    ];
  }

  if (tipo.includes("corporativo") || tipo.includes("lxf0m5")) {
    return [
      "coffee break",
      "buffet",
      "coquetel",
      "transporte",
      "fotografia",
      "filmagem",
      "papelaria",
      "sonorizacao",
      "sonorização",
      "musica",
      "música",
      "iluminacao",
      "iluminação",
      "equipamentos",
    ];
  }

  return comunsSociais;
}


function montarCategoriasFornecedorNormalizadas(
  fornecedor: FornecedorCandidato,
  vinculos: FornecedorCategoriaVinculo[],
): string[] {
  const categoriasEmbed = fornecedor.categoriasEmbed.flatMap((categoria) => {
    const nome = String(
      categoria.nome_categoria ??
      categoria.nomeCategoria ??
      categoria.nome ??
      categoria.categoria ??
      categoria.id_categoria ??
      "",
    );

    const subcategoriasRaw = Array.isArray(categoria.subcategorias)
      ? categoria.subcategorias
      : [];

    const subcategorias = subcategoriasRaw.map((sub) => {
      if (typeof sub === "string") return sub;
      if (sub && typeof sub === "object") {
        const subRecord = sub as Record<string, unknown>;
        return String(subRecord.nomeSubcategoria ?? subRecord.nome ?? subRecord.idSubcategoria ?? "");
      }
      return "";
    });

    return [nome, ...subcategorias];
  });

  const categoriasVinculos = vinculos.flatMap((vinculo) => [
    vinculo.nomeCategoria,
    vinculo.idCategoria,
    ...vinculo.subcategorias,
  ]);

  return removerDuplicados([...categoriasEmbed, ...categoriasVinculos].map(normalizarTexto).filter(Boolean));
}

function resolverCategoriaPrincipal(
  fornecedor: FornecedorCandidato,
  vinculos: FornecedorCategoriaVinculo[],
): string | null {
  if (vinculos.length > 0 && vinculos[0].nomeCategoria) {
    return vinculos[0].nomeCategoria;
  }

  const primeiraCategoria = fornecedor.categoriasEmbed[0];
  if (!primeiraCategoria) return null;

  return String(
    primeiraCategoria.nome_categoria ??
    primeiraCategoria.nomeCategoria ??
    primeiraCategoria.nome ??
    primeiraCategoria.categoria ??
    "",
  ) || null;
}

function calcularDistanciaEventoFornecedor(
  evento: EventoRecomendacaoContexto,
  territorio?: TerritorioFornecedor,
): number | null {
  if (
    !territorio ||
    evento.latitude === null ||
    evento.longitude === null ||
    territorio.latitude === null ||
    territorio.longitude === null
  ) {
    return null;
  }

  return calcularDistanciaKm(
    evento.latitude,
    evento.longitude,
    territorio.latitude,
    territorio.longitude,
  );
}

function calcularDistanciaKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const raioTerraKm = 6371;
  const dLat = grausParaRadianos(lat2 - lat1);
  const dLon = grausParaRadianos(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(grausParaRadianos(lat1)) *
    Math.cos(grausParaRadianos(lat2)) *
    Math.sin(dLon / 2) *
    Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Number((raioTerraKm * c).toFixed(2));
}

function grausParaRadianos(graus: number): number {
  return graus * (Math.PI / 180);
}

function removerDuplicados(lista: string[]): string[] {
  return [...new Set(lista.filter((item) => item.trim().length > 0))];
}
