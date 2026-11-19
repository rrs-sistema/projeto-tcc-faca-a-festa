import { DocumentSnapshot, FieldValue } from "firebase-admin/firestore";
import { onCall } from "../../shared/callableComMfa";
import { HttpsError } from "firebase-functions/v2/https";
import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";
import { admin } from "../../shared/firebaseAdmin";

const opcoes = { region: "southamerica-east1" };
const raioGratuitoKm = 20;
const incrementoKm = 5;
const tabelas = () => admin.firestore().collection("abrangencia_tabelas");
const diaSaoPaulo = new Intl.DateTimeFormat("en-CA", {
  timeZone: "America/Sao_Paulo", year: "numeric", month: "2-digit", day: "2-digit",
});

function hojeEmSaoPaulo(): string {
  const partes = diaSaoPaulo.formatToParts(new Date());
  const obter = (tipo: string) => partes.find(parte => parte.type === tipo)?.value;
  return `${obter("year")}-${obter("month")}-${obter("day")}`;
}

function validarTabela(vigencia: unknown, valores: unknown) {
  const data = typeof vigencia === "string" ? vigencia : "";
  const interpretada = new Date(`${data}T00:00:00Z`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(data)
      || !Number.isFinite(interpretada.getTime())
      || interpretada.toISOString().slice(0, 10) !== data) {
    throw new HttpsError("invalid-argument", "Informe uma data de vigência válida.");
  }
  if (!Array.isArray(valores) || valores.length === 0) {
    throw new HttpsError("invalid-argument", "Cadastre pelo menos uma faixa de 5 km.");
  }
  let total = 0;
  const faixas = valores.map((valor, indice) => {
    if (typeof valor !== "number" || !Number.isSafeInteger(valor) || valor <= 0) {
      throw new HttpsError("invalid-argument", "Cada faixa deve ter um valor positivo em centavos.");
    }
    total += valor;
    if (!Number.isSafeInteger(total)) {
      throw new HttpsError("invalid-argument", "O valor mensal acumulado excede o limite suportado.");
    }
    return {
      ateKm: raioGratuitoKm + incrementoKm * (indice + 1),
      adicionalCentavos: valor,
      mensalidadeCentavos: total,
    };
  });
  return { vigencia: data, faixas };
}

async function tabelaVigente(hoje: string) {
  const consulta = await tabelas().orderBy("chaveOrdenacao", "desc")
    .startAt(`${hoje}_\uf8ff`).limit(1).get();
  const doc = consulta.docs[0];
  if (!doc) return null;
  const { vigencia, faixas } = doc.data();
  return { id: doc.id, vigencia, faixas };
}

export const consultarAbrangenciaFornecedor = onCall(opcoes, async request => {
  const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
  exigirTipo(perfil, ["F"]);
  const [tabela, territorios] = await Promise.all([
    tabelaVigente(hojeEmSaoPaulo()),
    admin.firestore().collection("territorio").where("id_fornecedor", "==", perfil.uid).get(),
  ]);
  return {
    raioGratuitoKm,
    incrementoKm,
    tabela,
    territorios: territorios.docs.map(doc => doc.data())
      .filter(dados => dados.ativo !== false)
      .map(dados => ({
        tipo: dados.tipo_cobertura ?? dados.tipoCobertura ?? "raio",
        raioKm: dados.raio_km ?? dados.raioKm ?? null,
        descricao: dados.descricao ?? null,
      })),
  };
});

export const consultarTabelasAbrangenciaAdmin = onCall(opcoes, async request => {
  const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
  exigirTipo(perfil, ["A"]);
  const hoje = hojeEmSaoPaulo();
  const [vigente, historico] = await Promise.all([
    tabelaVigente(hoje),
    tabelas().orderBy("chaveOrdenacao", "desc").limit(30).get(),
  ]);
  const publicacoes: DocumentSnapshot[] = [...historico.docs];
  if (vigente && !publicacoes.some(doc => doc.id === vigente.id)) {
    publicacoes.push(await tabelas().doc(vigente.id).get());
  }
  const autorIds = [...new Set(publicacoes.map(doc => doc.data()?.autorId))]
    .filter((id): id is string => typeof id === "string" && id.length > 0 && !id.includes("/"));
  const usuarios = autorIds.length > 0
    ? await admin.firestore().getAll(...autorIds.map(id => admin.firestore().collection("usuarios").doc(id)))
    : [];
  const nomes = new Map(usuarios.map(doc => {
    const nome = doc.data()?.nome;
    return [doc.id, typeof nome === "string" ? nome.trim() || null : null];
  }));
  const tabelasAdmin = new Map(publicacoes.map(doc => {
    const { vigencia, faixas, autorId, publicadaEm } = doc.data() ?? {};
    return [doc.id, {
      id: doc.id, vigencia, faixas, autorId: autorId ?? null,
      autorNome: nomes.get(autorId) ?? null,
      publicadaEm: publicadaEm?.toDate().toISOString() ?? null,
    }];
  }));
  return {
    hoje, raioGratuitoKm, incrementoKm,
    vigente: vigente ? tabelasAdmin.get(vigente.id) : null,
    historico: historico.docs.map(doc => tabelasAdmin.get(doc.id)),
  };
});

export const publicarTabelaAbrangenciaAdmin = onCall(opcoes, async request => {
  const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
  exigirTipo(perfil, ["A"]);
  const { vigencia, faixas } = validarTabela(
    request.data?.vigencia, request.data?.valoresCentavos,
  );
  const pedidoId = request.data?.pedidoId;
  if (typeof pedidoId !== "string" || !/^[\da-f]{8}-(?:[\da-f]{4}-){3}[\da-f]{12}$/i.test(pedidoId)) {
    throw new HttpsError("invalid-argument", "Identificador da publicação inválido.");
  }
  const db = admin.firestore();
  const controle = db.collection("abrangencia_publicacoes_por_data").doc(vigencia);
  const pedido = controle.collection("pedidos").doc(pedidoId);
  const valores = faixas.map(faixa => faixa.adicionalCentavos);
  return db.runTransaction(async tx => {
    const [publicacao, versaoAtual] = await tx.getAll(pedido, controle);
    const existente = publicacao.data();
    if (existente) {
      if (existente.autorId !== perfil.uid
          || JSON.stringify(existente.valoresCentavos) !== JSON.stringify(valores)) {
        throw new HttpsError("already-exists", "Este pedido pertence a outra publicação.");
      }
      return { id: existente.id };
    }
    if (vigencia < hojeEmSaoPaulo()) {
      throw new HttpsError("invalid-argument", "Informe uma vigência a partir de hoje, no horário de Brasília.");
    }
    const revisao = (versaoAtual.data()?.revisao ?? 0) + 1;
    const id = `${vigencia}_${String(revisao).padStart(12, "0")}`;
    tx.create(tabelas().doc(id), {
      vigencia, faixas, chaveOrdenacao: id,
      autorId: perfil.uid, publicadaEm: FieldValue.serverTimestamp(),
    });
    tx.set(controle, { revisao });
    tx.create(pedido, { id, autorId: perfil.uid, valoresCentavos: valores });
    return { id };
  });
});
