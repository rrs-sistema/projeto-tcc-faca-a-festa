/** Only explicit web URLs can be included in an email; never guess a Storage path. */
export function selecionarCapaConvite(...candidatas: unknown[]): string {
  for (const candidata of candidatas) {
    if (typeof candidata !== "string" || !candidata.trim()) continue;
    try {
      const url = new URL(candidata.trim());
      if ((url.protocol === "https:" || url.protocol === "http:") && url.hostname) {
        return url.href;
      }
    } catch (_) {
      // Local assets and malformed URLs cannot be loaded by email clients.
    }
  }
  return "";
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function misturarBranco(hex: string, fator = 0.9): string {
  const c = hex.replace("#", "");
  const mix = (inicio: number) => {
    const valor = Number.parseInt(c.slice(inicio, inicio + 2), 16);
    return Math.round(valor + (255 - valor) * fator)
      .toString(16)
      .padStart(2, "0");
  };
  return `#${mix(0)}${mix(2)}${mix(4)}`.toUpperCase();
}

function luminancia(hex: string): number {
  const c = hex.replace("#", "");
  const linear = (inicio: number) => {
    const s = Number.parseInt(c.slice(inicio, inicio + 2), 16) / 255;
    return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * linear(0) + 0.7152 * linear(2) + 0.0722 * linear(4);
}

function textoSobre(hex: string): string {
  return luminancia(hex) > 0.55 ? "#1F2937" : "#FFFFFF";
}

export function montarHtml(params: {
  nome: string;
  nomeEvento: string;
  quando: string;
  hora: string;
  local: string;
  mensagem: string;
  link: string;
  nomeTema: string;
  traje: string;
  capaUrl: string;
  corPrimaria: string;
  corSecundaria: string;
}): string {
  const detalhes: string[] = [];
  if (params.nomeTema) {
    detalhes.push(
      `<p style="margin:4px 0;color:#475569">Tema: ${escapeHtml(params.nomeTema)}</p>`,
    );
  }
  if (params.traje) {
    detalhes.push(
      `<p style="margin:4px 0;color:#475569">Traje: ${escapeHtml(params.traje)}</p>`,
    );
  }
  if (params.quando) {
    detalhes.push(`<p style="margin:4px 0;color:#475569">Quando: ${escapeHtml(params.quando)}</p>`);
  }
  if (params.hora) {
    detalhes.push(`<p style="margin:4px 0;color:#475569">Horário: ${escapeHtml(params.hora)}</p>`);
  }
  if (params.local) {
    detalhes.push(`<p style="margin:4px 0;color:#475569">Local: ${escapeHtml(params.local)}</p>`);
  }
  const mensagem = params.mensagem
    ? `<p style="margin:16px 0;color:#334155">${escapeHtml(params.mensagem)}</p>`
    : "";
  const primaria = params.corPrimaria;
  const onPrimary = textoSobre(primaria);
  const faixa =
    luminancia(params.corSecundaria) < 0.12
      ? primaria
      : params.corSecundaria;
  const fundo = misturarBranco(primaria, 0.92);

  const capaUrl = selecionarCapaConvite(params.capaUrl);
  const capa = capaUrl
    ? `<img src="${escapeHtml(capaUrl)}" alt="" width="520" height="160" style="display:block;width:100%;height:160px;object-fit:cover;border-radius:12px 12px 0 0">`
    : "";
  const raioTopo = capaUrl ? "0" : "12px";

  return `
  <div style="font-family:Arial,sans-serif;max-width:520px;margin:0 auto;color:#0f172a;background:${fundo};padding:16px">
    ${capa}
    <div style="background:${primaria};color:${onPrimary};padding:18px 20px;border-radius:${raioTopo} ${raioTopo} 0 0">
      <p style="margin:0;font-size:12px;opacity:.9">Faça a Festa</p>
      <p style="margin:6px 0 0;font-size:20px;font-weight:700">${escapeHtml(params.nomeEvento)}</p>
    </div>
    <div style="background:#ffffff;border:1px solid ${faixa};border-top:4px solid ${faixa};padding:20px;border-radius:0 0 12px 12px">
      <p>Olá, ${escapeHtml(params.nome)}!</p>
      <p>Você foi convidado(a) para <strong>${escapeHtml(params.nomeEvento)}</strong>.</p>
      ${detalhes.join("")}
      ${mensagem}
      <p style="margin:24px 0">
        <a href="${escapeHtml(params.link)}"
           style="background:${primaria};color:${onPrimary};padding:12px 20px;border-radius:10px;text-decoration:none;font-weight:700">
          Abrir convite
        </a>
      </p>
      <p style="font-size:12px;color:#64748b">Se o botão não abrir, copie este link:<br>${escapeHtml(params.link)}</p>
    </div>
  </div>`;
}
