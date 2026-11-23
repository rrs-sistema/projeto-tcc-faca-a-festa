function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export function montarHtmlConviteCoOrganizador(params: {
  nomeConvidado: string;
  nomeDono: string;
  nomeEvento: string;
  quando: string;
  link: string;
}): string {
  const saudacao = params.nomeConvidado
    ? `Olá, ${escapeHtml(params.nomeConvidado)}`
    : "Olá";
  const quando = params.quando
    ? `<p style="margin:8px 0;color:#475569">Quando: ${escapeHtml(params.quando)}</p>`
    : "";

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="utf-8"/><meta name="viewport" content="width=device-width"/></head>
<body style="margin:0;padding:0;background:#F8FAFC;font-family:Georgia,'Times New Roman',serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#F8FAFC;padding:32px 16px;">
    <tr><td align="center">
      <table role="presentation" width="560" cellspacing="0" cellpadding="0" style="max-width:560px;background:#FFFFFF;border-radius:16px;overflow:hidden;border:1px solid #E2E8F0;">
        <tr>
          <td style="padding:28px 28px 12px;background:linear-gradient(135deg,#0F766E,#134E4A);">
            <p style="margin:0;font-size:12px;letter-spacing:0.14em;text-transform:uppercase;color:#99F6E4;">Faça a Festa</p>
            <h1 style="margin:10px 0 0;font-size:26px;line-height:1.25;color:#FFFFFF;font-weight:700;">
              Convite para organizar juntos
            </h1>
          </td>
        </tr>
        <tr>
          <td style="padding:28px;">
            <p style="margin:0 0 14px;font-size:16px;color:#0F172A;line-height:1.5;">
              ${saudacao},
            </p>
            <p style="margin:0 0 14px;font-size:15px;color:#334155;line-height:1.55;">
              <strong>${escapeHtml(params.nomeDono || "Um organizador")}</strong>
              convidou você para ser co-organizador de
              <strong>${escapeHtml(params.nomeEvento || "um evento")}</strong>.
            </p>
            ${quando}
            <p style="margin:0 0 22px;font-size:14px;color:#64748B;line-height:1.5;">
              Com o aceite, você poderá planejar, cotar, contratar e autorizar pagamentos neste evento,
              com o mesmo poder operacional do organizador principal.
            </p>
            <a href="${escapeHtml(params.link)}"
               style="display:inline-block;padding:14px 22px;background:#0F766E;color:#FFFFFF;text-decoration:none;border-radius:999px;font-size:15px;font-weight:700;">
              Aceitar convite
            </a>
            <p style="margin:22px 0 0;font-size:12px;color:#94A3B8;line-height:1.45;">
              Se o botão não funcionar, abra este link:<br/>
              <span style="word-break:break-all;color:#0F766E;">${escapeHtml(params.link)}</span>
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;
}
