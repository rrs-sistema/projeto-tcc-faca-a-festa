import * as nodemailer from "nodemailer";
import { defineSecret } from "firebase-functions/params";

export const SMTP_HOST = defineSecret("SMTP_HOST");
export const SMTP_PORT = defineSecret("SMTP_PORT");
export const SMTP_USER = defineSecret("SMTP_USER");
export const SMTP_PASS = defineSecret("SMTP_PASS");
export const SMTP_FROM = defineSecret("SMTP_FROM");

export const SECRETS_SMTP = [
  SMTP_HOST,
  SMTP_PORT,
  SMTP_USER,
  SMTP_PASS,
  SMTP_FROM,
];

type EnviarEmailCodigoParams = {
  para: string;
  assunto: string;
  texto: string;
  html: string;
};

export async function enviarEmailCodigo(
  params: EnviarEmailCodigoParams,
): Promise<void> {
  const host = SMTP_HOST.value().trim();
  const port = Number(SMTP_PORT.value().trim() || "587");
  const user = SMTP_USER.value().trim();
  const pass = SMTP_PASS.value().replace(/\s/g, "");
  const from = (SMTP_FROM.value() || user).trim();

  if (!host || !user || !pass || !from) {
    throw new Error(
      "SMTP não configurado. Defina SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS e SMTP_FROM.",
    );
  }

  const transporter = nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user, pass },
  });

  await transporter.sendMail({
    from,
    to: params.para,
    subject: params.assunto,
    text: params.texto,
    html: params.html,
  });
}

export function isSmtpNaoConfigurado(error: unknown): boolean {
  return (
    error instanceof Error && error.message.includes("SMTP não configurado")
  );
}
