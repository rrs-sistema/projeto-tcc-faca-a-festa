import { HttpsError, onCall } from "firebase-functions/v2/https";

import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";
import { admin } from "../../shared/firebaseAdmin";

const REGION = "southamerica-east1";
const MAX_EVENTOS = 15;
const MAX_CONVIDADOS = 40;
const MAX_COTACOES = 20;

function texto(value: unknown): string {
  if (value == null) return "";
  return String(value).trim();
}

function dataTexto(value: unknown): string {
  if (value && typeof (value as { toDate?: () => Date }).toDate === "function") {
    const data = (value as { toDate: () => Date }).toDate();
    return data.toISOString();
  }
  return texto(value);
}

function linha(rotulo: string, valor: unknown): string {
  const limpo = texto(valor);
  return `${rotulo}: ${limpo || "-"}`;
}

export const exportarDossieTitular = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
    cors: true,
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const pedido = texto(data.idUsuario);
    const idUsuario = pedido || perfil.uid;
    if (idUsuario !== perfil.uid) {
      exigirTipo(perfil, ["A"]);
    }

    const db = admin.firestore();
    const usuarioSnap = await db.collection("usuarios").doc(idUsuario).get();
    if (!usuarioSnap.exists) {
      throw new HttpsError("not-found", "Conta não encontrada.");
    }

    const usuario = usuarioSnap.data() ?? {};
    const buffer: string[] = [];
    buffer.push("Faça a Festa — dossiê do titular");
    buffer.push(`Gerado em ${new Date().toISOString()}`);
    buffer.push(`Conta: ${idUsuario}`);
    buffer.push("");
    buffer.push("1. Conta");
    buffer.push(linha("Nome", usuario.nome));
    buffer.push(linha("E-mail", usuario.email));
    buffer.push(linha("CPF", usuario.cpf));
    buffer.push(linha("Papel", usuario.tipo));
    buffer.push(linha("Cidade", usuario.cidade));
    buffer.push(linha("UF", usuario.uf));
    buffer.push(linha("Telefone", usuario.telefone));
    buffer.push(linha("Versão da política", usuario.versao_politica_privacidade));
    buffer.push(linha("Aceite", dataTexto(usuario.aceite_privacidade_em)));
    const prefs = usuario.preferencias_notificacao;
    buffer.push(
      linha(
        "Avisos",
        prefs && typeof prefs === "object" ? JSON.stringify(prefs) : "padrão ligado",
      ),
    );
    if (usuario.tratamento_oposto === true) {
      buffer.push("Oposição a legítimo interesse: registrada");
    }

    buffer.push("");
    buffer.push("2. Endereços");
    const enderecos = await db
      .collection("usuarios")
      .doc(idUsuario)
      .collection("enderecos")
      .limit(10)
      .get();
    if (enderecos.empty) {
      buffer.push("Nenhum endereço cadastrado.");
    } else {
      for (const doc of enderecos.docs) {
        const end = doc.data();
        buffer.push(
          [
            texto(end.logradouro),
            texto(end.numero),
            texto(end.bairro),
            texto(end.cidade || end.nome_cidade),
            texto(end.uf),
            texto(end.cep),
          ]
            .filter((parte) => parte)
            .join(", ") || doc.id,
        );
      }
    }

    buffer.push("");
    buffer.push("3. Eventos e convidados");
    const eventos = await db
      .collection("evento")
      .where("id_usuario", "==", idUsuario)
      .limit(MAX_EVENTOS)
      .get();
    if (eventos.empty) {
      buffer.push("Nenhum evento como organizador.");
    }
    for (const evento of eventos.docs) {
      const ev = evento.data();
      buffer.push("");
      buffer.push(
        `Evento ${texto(ev.nome_evento) || texto(ev.nome) || evento.id}`,
      );
      buffer.push(linha("Data", dataTexto(ev.data)));
      buffer.push(linha("Cidade", ev.cidade));
      buffer.push(linha("Local", ev.local_evento || ev.logradouro));
      const convidados = await db
        .collection("convidado")
        .where("id_evento", "==", evento.id)
        .limit(MAX_CONVIDADOS)
        .get();
      buffer.push(`Convidados neste recorte: ${convidados.size}`);
      for (const convidado of convidados.docs) {
        const c = convidado.data();
        buffer.push(
          `- ${texto(c.nome) || "sem nome"} | ${texto(c.email) || texto(c.contato) || "sem contato"} | ${texto(c.tipo) || "adulto"}`,
        );
      }
    }

    buffer.push("");
    buffer.push("4. Cotações solicitadas");
    const cotacoes = await db
      .collection("cotacao")
      .where("id_usuario_solicitante", "==", idUsuario)
      .limit(MAX_COTACOES)
      .get();
    if (cotacoes.empty) {
      buffer.push("Nenhuma cotação.");
    }
    for (const cotacao of cotacoes.docs) {
      const c = cotacao.data();
      buffer.push(
        `- ${texto(c.categoria_nome) || cotacao.id} | ${texto(c.status) || "sem status"}`,
      );
    }

    const fornecedor = await db.collection("fornecedor").doc(idUsuario).get();
    if (fornecedor.exists) {
      const f = fornecedor.data() ?? {};
      buffer.push("");
      buffer.push("5. Cadastro de fornecedor");
      buffer.push(linha("Nome", f.nome_fantasia || f.nome || f.razao_social));
      buffer.push(linha("CNPJ", f.cnpj));
      buffer.push(linha("Telefone", f.telefone));
      buffer.push(linha("E-mail", f.email));
    }

    buffer.push("");
    buffer.push(
      "Recorte limitado a 15 eventos, 40 convidados por evento e 20 cotações.",
    );

    return { texto: buffer.join("\n") };
  },
);
