import * as crypto from "crypto";

const ALFABETO_BASE32 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
const PERIODO_SEGUNDOS = 30;
const DIGITOS = 6;

export function gerarSecretTotp(): string {
  return base32Encode(crypto.randomBytes(20));
}

export function montarOtpauthUrl(params: {
  secret: string;
  email: string;
  issuer?: string;
}): string {
  const issuer = params.issuer ?? "Faça a Festa";
  const label = encodeURIComponent(`${issuer}:${params.email}`);
  const issuerQuery = encodeURIComponent(issuer);
  return (
    `otpauth://totp/${label}` +
    `?secret=${params.secret}` +
    `&issuer=${issuerQuery}` +
    `&algorithm=SHA1&digits=${DIGITOS}&period=${PERIODO_SEGUNDOS}`
  );
}

export function verificarTotp(
  secretBase32: string,
  codigo: string,
  janela = 1,
): boolean {
  const informado = codigo.replace(/\D/g, "");
  if (informado.length !== DIGITOS) return false;

  const secret = base32Decode(secretBase32);
  const contadorAtual = Math.floor(Date.now() / 1000 / PERIODO_SEGUNDOS);

  for (let offset = -janela; offset <= janela; offset += 1) {
    if (gerarHotp(secret, contadorAtual + offset) === informado) {
      return true;
    }
  }
  return false;
}

export function cifrarTexto(texto: string, chaveMestra: string): string {
  const chave = crypto.createHash("sha256").update(chaveMestra).digest();
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv("aes-256-gcm", chave, iv);
  const criptografado = Buffer.concat([
    cipher.update(texto, "utf8"),
    cipher.final(),
  ]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, tag, criptografado]).toString("base64");
}

export function decifrarTexto(payload: string, chaveMestra: string): string {
  const buffer = Buffer.from(payload, "base64");
  const iv = buffer.subarray(0, 12);
  const tag = buffer.subarray(12, 28);
  const dados = buffer.subarray(28);
  const chave = crypto.createHash("sha256").update(chaveMestra).digest();
  const decipher = crypto.createDecipheriv("aes-256-gcm", chave, iv);
  decipher.setAuthTag(tag);
  return Buffer.concat([decipher.update(dados), decipher.final()]).toString(
    "utf8",
  );
}

function gerarHotp(secret: Buffer, contador: number): string {
  const mensagem = Buffer.alloc(8);
  mensagem.writeUInt32BE(Math.floor(contador / 0x100000000), 0);
  mensagem.writeUInt32BE(contador >>> 0, 4);
  const hmac = crypto.createHmac("sha1", secret).update(mensagem).digest();
  const offset = hmac[hmac.length - 1] & 0x0f;
  const binario =
    ((hmac[offset] & 0x7f) << 24) |
    ((hmac[offset + 1] & 0xff) << 16) |
    ((hmac[offset + 2] & 0xff) << 8) |
    (hmac[offset + 3] & 0xff);
  const otp = binario % 10 ** DIGITOS;
  return otp.toString().padStart(DIGITOS, "0");
}

function base32Encode(bytes: Buffer): string {
  let bits = 0;
  let valor = 0;
  let saida = "";
  for (const byte of bytes) {
    valor = (valor << 8) | byte;
    bits += 8;
    while (bits >= 5) {
      saida += ALFABETO_BASE32[(valor >>> (bits - 5)) & 31];
      bits -= 5;
    }
  }
  if (bits > 0) {
    saida += ALFABETO_BASE32[(valor << (5 - bits)) & 31];
  }
  return saida;
}

function base32Decode(secret: string): Buffer {
  const limpo = secret.toUpperCase().replace(/=+$/g, "").replace(/\s+/g, "");
  let bits = 0;
  let valor = 0;
  const bytes: number[] = [];
  for (const char of limpo) {
    const indice = ALFABETO_BASE32.indexOf(char);
    if (indice < 0) continue;
    valor = (valor << 5) | indice;
    bits += 5;
    if (bits >= 8) {
      bytes.push((valor >>> (bits - 8)) & 255);
      bits -= 8;
    }
  }
  return Buffer.from(bytes);
}
