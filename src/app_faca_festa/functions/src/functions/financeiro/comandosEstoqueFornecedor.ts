import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { randomUUID } from "crypto";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado } from "../../shared/auth";
import { exigirAcessoFinanceiroFornecedor } from "../../services/financeiro/autorizacaoFornecedorFinanceiro";
import { dinheiro } from "../../services/financeiro/dinheiro";
import {
  ItemEstoque,
  ReservaEstoque,
  cancelarReserva,
  capacidadeNoIntervalo,
  consumir,
  custoMedioAposEntrada,
  devolverReserva,
  intervaloEfetivo,
  NaturezaItem,
  ofereceDisponibilidade,
  reservar,
  retirarDeReserva,
  StatusFisico,
} from "../../services/financeiro/estoqueFornecedorService";

const REGION = "southamerica-east1";

function texto(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

function inteiro(v: unknown, nome: string): number {
  if (typeof v !== "number" || !Number.isInteger(v) || v < 0) {
    throw new HttpsError("invalid-argument", `Informe ${nome} inteiro válido.`);
  }
  return v;
}

function mapItem(id: string, data: FirebaseFirestore.DocumentData): ItemEstoque {
  const medio = data.custo_medio_unitario?.centavos ?? 0;
  return {
    idItem: id,
    idFornecedor: String(data.id_fornecedor ?? ""),
    nome: String(data.nome ?? ""),
    natureza: (data.natureza as NaturezaItem) || "consumivel",
    quantidadeTotal: Number(data.quantidade_total ?? 0),
    quantidadeReservada: Number(data.quantidade_reservada ?? 0),
    quantidadeEmUso: Number(data.quantidade_em_uso ?? 0),
    status: (data.status as StatusFisico) || "disponivel",
    custoMedioUnitarioCentavos: Number(medio),
    custoUsoCentavos: Number(data.custo_uso?.centavos ?? 0),
    custoLocacaoCentavos: Number(data.custo_locacao?.centavos ?? 0),
    montagemMinutos: Number(data.montagem_minutos ?? 0),
    transporteMinutos: Number(data.transporte_minutos ?? 0),
    desmontagemMinutos: Number(data.desmontagem_minutos ?? 0),
    custoAusente: data.custo_ausente === true,
  };
}

function mapReserva(
  id: string,
  data: FirebaseFirestore.DocumentData,
): ReservaEstoque {
  return {
    idReserva: id,
    idItem: String(data.id_item ?? ""),
    idFornecedor: String(data.id_fornecedor ?? ""),
    idEvento: String(data.id_evento ?? ""),
    quantidade: Number(data.quantidade ?? 0),
    status: data.status,
    intervaloEfetivo: {
      inicio: new Date(String(data.intervalo_inicio)),
      fim: new Date(String(data.intervalo_fim)),
    },
    chaveIdempotencia: data.chave_idempotencia
      ? String(data.chave_idempotencia)
      : undefined,
  };
}

function persistItem(item: ItemEstoque): FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> {
  return {
    quantidade_total: item.quantidadeTotal,
    quantidade_reservada: item.quantidadeReservada,
    quantidade_em_uso: item.quantidadeEmUso,
    custo_medio_unitario: dinheiro(item.custoMedioUnitarioCentavos),
    custo_ausente: item.custoAusente === true,
    atualizado_em: FieldValue.serverTimestamp(),
  };
}

function wrapErr(e: unknown): never {
  const err = e as { code?: string; message?: string };
  if (err?.code === "failed-precondition") {
    throw new HttpsError("failed-precondition", err.message || "Operação inválida.");
  }
  if (e instanceof HttpsError) throw e;
  throw new HttpsError("invalid-argument", err?.message || "Falha no estoque.");
}

export const cadastrarItemEstoqueFornecedor = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idFornecedor = texto(data.idFornecedor ?? data.id_fornecedor);
    await exigirAcessoFinanceiroFornecedor(
      admin.firestore(),
      perfil,
      idFornecedor,
    );

    const nome = texto(data.nome);
    if (!nome) throw new HttpsError("invalid-argument", "Informe o nome do item.");
    const natureza = (texto(data.natureza) || "consumivel") as NaturezaItem;
    const quantidade = inteiro(data.quantidadeTotal ?? data.quantidade_total ?? 0, "quantidade");
    const custoUnit = inteiro(
      data.custoUnitarioCentavos ?? data.custo_unitario_centavos ?? 0,
      "custo unitário",
    );
    const idItem = texto(data.idItem ?? data.id_item) || randomUUID();
    const ref = admin
      .firestore()
      .collection("fornecedor")
      .doc(idFornecedor)
      .collection("estoque_itens")
      .doc(idItem);

    const existente = await ref.get();
    if (existente.exists) {
      return { ok: true, idItem, idempotente: true };
    }

    const status = (texto(data.status) || "disponivel") as StatusFisico;
    await ref.set({
      schema: 1,
      id_item: idItem,
      id_fornecedor: idFornecedor,
      nome,
      natureza,
      unidade: texto(data.unidade) || "un",
      quantidade_total: quantidade,
      quantidade_reservada: 0,
      quantidade_em_uso: 0,
      status,
      metodo_valorizacao:
        natureza === "consumivel"
          ? "custo_medio_movel"
          : natureza === "locado_terceiro"
            ? "custo_locacao"
            : "custo_uso_configurado",
      custo_medio_unitario: dinheiro(custoUnit),
      custo_uso: dinheiro(
        inteiro(data.custoUsoCentavos ?? data.custo_uso_centavos ?? 0, "custo uso"),
      ),
      custo_locacao: dinheiro(
        inteiro(
          data.custoLocacaoCentavos ?? data.custo_locacao_centavos ?? 0,
          "custo locação",
        ),
      ),
      localizacao: texto(data.localizacao) || null,
      lote: texto(data.lote) || null,
      validade: texto(data.validade) || null,
      conservacao: texto(data.conservacao) || null,
      proprietario: texto(data.proprietario) || "proprio",
      montagem_minutos: inteiro(data.montagemMinutos ?? data.montagem_minutos ?? 0, "montagem"),
      transporte_minutos: inteiro(
        data.transporteMinutos ?? data.transporte_minutos ?? 0,
        "transporte",
      ),
      desmontagem_minutos: inteiro(
        data.desmontagemMinutos ?? data.desmontagem_minutos ?? 0,
        "desmontagem",
      ),
      custo_ausente: custoUnit <= 0 && natureza === "consumivel" && quantidade > 0,
      perspectiva: "fornecedor_privado",
      criado_em: FieldValue.serverTimestamp(),
    });

    return { ok: true, idItem, idempotente: false };
  },
);

export const registrarEntradaEstoqueFornecedor = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idFornecedor = texto(data.idFornecedor ?? data.id_fornecedor);
    const idItem = texto(data.idItem ?? data.id_item);
    await exigirAcessoFinanceiroFornecedor(
      admin.firestore(),
      perfil,
      idFornecedor,
    );
    const quantidade = inteiro(data.quantidade, "quantidade");
    const custoUnit = inteiro(
      data.custoUnitarioCentavos ?? data.custo_unitario_centavos ?? 0,
      "custo",
    );
    const chave =
      texto(data.chaveIdempotencia ?? data.chave_idempotencia) || randomUUID();

    const db = admin.firestore();
    const itemRef = db
      .collection("fornecedor")
      .doc(idFornecedor)
      .collection("estoque_itens")
      .doc(idItem);
    const movRef = db
      .collection("fornecedor")
      .doc(idFornecedor)
      .collection("estoque_movimentos")
      .doc(chave);

    try {
      return await db.runTransaction(async (tx) => {
        const movSnap = await tx.get(movRef);
        if (movSnap.exists) {
          return { ok: true, idMovimento: chave, idempotente: true };
        }
        const itemSnap = await tx.get(itemRef);
        if (!itemSnap.exists) {
          throw new HttpsError("not-found", "Item de estoque não encontrado.");
        }
        const item = mapItem(itemSnap.id, itemSnap.data()!);
        const cmp = custoMedioAposEntrada(
          item.quantidadeTotal,
          item.custoMedioUnitarioCentavos,
          quantidade,
          custoUnit,
        );
        const atualizado: ItemEstoque = {
          ...item,
          quantidadeTotal: item.quantidadeTotal + quantidade,
          custoMedioUnitarioCentavos: cmp,
          custoAusente: false,
        };
        tx.update(itemRef, persistItem(atualizado));
        tx.set(movRef, {
          schema: 1,
          id_movimento: chave,
          id_item: idItem,
          id_fornecedor: idFornecedor,
          tipo: "entrada",
          quantidade,
          custo_unitario: dinheiro(custoUnit),
          gera_obrigacao: data.geraObrigacao !== false,
          gera_desembolso: false,
          chave_idempotencia: chave,
          perspectiva: "fornecedor_privado",
          autor_id: perfil.uid,
          criado_em: FieldValue.serverTimestamp(),
        });
        // Compra pode gerar obrigação (conta a pagar), sem custo de evento.
        if (data.geraObrigacao !== false && custoUnit * quantidade > 0) {
          const obrRef = db
            .collection("fornecedor")
            .doc(idFornecedor)
            .collection("contas_pagar")
            .doc(chave);
          tx.set(obrRef, {
            schema: 1,
            id_obrigacao: chave,
            id_fornecedor: idFornecedor,
            id_item: idItem,
            valor: dinheiro(custoUnit * quantidade),
            origem: "compra_estoque",
            status: "aberta",
            perspectiva: "fornecedor_privado",
            criado_em: FieldValue.serverTimestamp(),
          });
        }
        return { ok: true, idMovimento: chave, idempotente: false, cmp };
      });
    } catch (e) {
      wrapErr(e);
    }
  },
);

export const reservarEstoqueFornecedor = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idFornecedor = texto(data.idFornecedor ?? data.id_fornecedor);
    const idItem = texto(data.idItem ?? data.id_item);
    const idEvento = texto(data.idEvento ?? data.id_evento);
    await exigirAcessoFinanceiroFornecedor(
      admin.firestore(),
      perfil,
      idFornecedor,
    );
    if (!idEvento) throw new HttpsError("invalid-argument", "Informe o evento.");
    const quantidade = inteiro(data.quantidade, "quantidade");
    const inicio = new Date(texto(data.inicio));
    const fim = new Date(texto(data.fim));
    if (Number.isNaN(inicio.getTime()) || Number.isNaN(fim.getTime())) {
      throw new HttpsError("invalid-argument", "Informe início e fim válidos.");
    }
    const chave =
      texto(data.chaveIdempotencia ?? data.chave_idempotencia) || randomUUID();

    const db = admin.firestore();
    const itemRef = db
      .collection("fornecedor")
      .doc(idFornecedor)
      .collection("estoque_itens")
      .doc(idItem);
    const reservaRef = db
      .collection("fornecedor")
      .doc(idFornecedor)
      .collection("estoque_reservas")
      .doc(chave);

    try {
      return await db.runTransaction(async (tx) => {
        const existente = await tx.get(reservaRef);
        if (existente.exists) {
          return { ok: true, idReserva: chave, idempotente: true };
        }
        const itemSnap = await tx.get(itemRef);
        if (!itemSnap.exists) {
          throw new HttpsError("not-found", "Item não encontrado.");
        }
        const item = mapItem(itemSnap.id, itemSnap.data()!);
        if (!ofereceDisponibilidade(item.status)) {
          throw new HttpsError(
            "failed-precondition",
            "Item vencido ou em manutenção não é oferecido como disponível.",
          );
        }
        // Lê reservas do item (transação: concorrência atômica).
        const reservasSnap = await tx.get(
          db
            .collection("fornecedor")
            .doc(idFornecedor)
            .collection("estoque_reservas")
            .where("id_item", "==", idItem),
        );
        const reservas = reservasSnap.docs
          .map((d) => mapReserva(d.id, d.data()))
          .filter((r) => r.status === "ativa" || r.status === "retirada");
        const intervalo = intervaloEfetivo(inicio, fim, item);
        const resultado = reservar({
          item,
          idReserva: chave,
          idEvento,
          quantidade,
          intervalo,
          reservasAtivas: reservas,
          chaveIdempotencia: chave,
        });
        tx.update(itemRef, persistItem(resultado.item));
        tx.set(reservaRef, {
          schema: 1,
          id_reserva: chave,
          id_item: idItem,
          id_fornecedor: idFornecedor,
          id_evento: idEvento,
          quantidade,
          status: "ativa",
          intervalo_inicio: intervalo.inicio.toISOString(),
          intervalo_fim: intervalo.fim.toISOString(),
          inicio_solicitado: inicio.toISOString(),
          fim_solicitado: fim.toISOString(),
          chave_idempotencia: chave,
          perspectiva: "fornecedor_privado",
          autor_id: perfil.uid,
          criado_em: FieldValue.serverTimestamp(),
        });
        // Movimento histórico
        const movRef = db
          .collection("fornecedor")
          .doc(idFornecedor)
          .collection("estoque_movimentos")
          .doc(`res-${chave}`);
        tx.set(movRef, {
          schema: 1,
          id_movimento: `res-${chave}`,
          id_item: idItem,
          id_reserva: chave,
          id_evento: idEvento,
          id_fornecedor: idFornecedor,
          tipo: "reserva",
          quantidade,
          perspectiva: "fornecedor_privado",
          chave_idempotencia: `res-${chave}`,
          criado_em: FieldValue.serverTimestamp(),
        });
        return {
          ok: true,
          idReserva: chave,
          disponivelRestante: capacidadeNoIntervalo(
            resultado.item,
            intervalo,
            [...reservas, resultado.reserva],
          ),
        };
      });
    } catch (e) {
      wrapErr(e);
    }
  },
);

export const retirarEstoqueFornecedor = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idFornecedor = texto(data.idFornecedor ?? data.id_fornecedor);
    const idReserva = texto(data.idReserva ?? data.id_reserva);
    await exigirAcessoFinanceiroFornecedor(
      admin.firestore(),
      perfil,
      idFornecedor,
    );
    const chave =
      texto(data.chaveIdempotencia ?? data.chave_idempotencia) ||
      `ret-${idReserva}`;

    const db = admin.firestore();
    try {
      return await db.runTransaction(async (tx) => {
        const movRef = db
          .collection("fornecedor")
          .doc(idFornecedor)
          .collection("estoque_movimentos")
          .doc(chave);
        const movSnap = await tx.get(movRef);
        if (movSnap.exists) {
          return { ok: true, idempotente: true };
        }
        const resRef = db
          .collection("fornecedor")
          .doc(idFornecedor)
          .collection("estoque_reservas")
          .doc(idReserva);
        const resSnap = await tx.get(resRef);
        if (!resSnap.exists) {
          throw new HttpsError("not-found", "Reserva não encontrada.");
        }
        const reserva = mapReserva(resSnap.id, resSnap.data()!);
        const itemRef = db
          .collection("fornecedor")
          .doc(idFornecedor)
          .collection("estoque_itens")
          .doc(reserva.idItem);
        const itemSnap = await tx.get(itemRef);
        if (!itemSnap.exists) {
          throw new HttpsError("not-found", "Item não encontrado.");
        }
        const resultado = retirarDeReserva(
          mapItem(itemSnap.id, itemSnap.data()!),
          reserva,
        );
        tx.update(itemRef, persistItem(resultado.item));
        tx.update(resRef, { status: resultado.reserva.status });
        tx.set(movRef, {
          schema: 1,
          id_movimento: chave,
          tipo: "retirada",
          id_item: reserva.idItem,
          id_reserva: idReserva,
          id_fornecedor: idFornecedor,
          quantidade: reserva.quantidade,
          chave_idempotencia: chave,
          perspectiva: "fornecedor_privado",
          criado_em: FieldValue.serverTimestamp(),
        });
        return { ok: true, idempotente: !!resultado.idempotente };
      });
    } catch (e) {
      wrapErr(e);
    }
  },
);

export const consumirEstoqueFornecedor = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idFornecedor = texto(data.idFornecedor ?? data.id_fornecedor);
    const idItem = texto(data.idItem ?? data.id_item);
    const idEvento = texto(data.idEvento ?? data.id_evento);
    const idReserva = texto(data.idReserva ?? data.id_reserva);
    await exigirAcessoFinanceiroFornecedor(
      admin.firestore(),
      perfil,
      idFornecedor,
    );
    if (!idEvento) throw new HttpsError("invalid-argument", "Informe o evento.");
    const quantidade = inteiro(data.quantidade, "quantidade");
    const chave =
      texto(data.chaveIdempotencia ?? data.chave_idempotencia) || randomUUID();

    const db = admin.firestore();
    try {
      return await db.runTransaction(async (tx) => {
        const movRef = db
          .collection("fornecedor")
          .doc(idFornecedor)
          .collection("estoque_movimentos")
          .doc(chave);
        const movSnap = await tx.get(movRef);
        if (movSnap.exists) {
          return {
            ok: true,
            idMovimento: chave,
            idempotente: true,
            custoAtribuidoCentavos: movSnap.data()?.custo_atribuido?.centavos ?? 0,
          };
        }
        const itemRef = db
          .collection("fornecedor")
          .doc(idFornecedor)
          .collection("estoque_itens")
          .doc(idItem);
        const itemSnap = await tx.get(itemRef);
        if (!itemSnap.exists) {
          throw new HttpsError("not-found", "Item não encontrado.");
        }
        let reserva: ReservaEstoque | null = null;
        let resRef: FirebaseFirestore.DocumentReference | null = null;
        if (idReserva) {
          resRef = db
            .collection("fornecedor")
            .doc(idFornecedor)
            .collection("estoque_reservas")
            .doc(idReserva);
          const resSnap = await tx.get(resRef);
          if (!resSnap.exists) {
            throw new HttpsError("not-found", "Reserva não encontrada.");
          }
          reserva = mapReserva(resSnap.id, resSnap.data()!);
        }
        const resultado = consumir({
          item: mapItem(itemSnap.id, itemSnap.data()!),
          quantidade,
          reserva,
        });
        tx.update(itemRef, persistItem(resultado.item));
        if (resRef && resultado.reserva) {
          tx.update(resRef, { status: resultado.reserva.status });
        }
        tx.set(movRef, {
          schema: 1,
          id_movimento: chave,
          tipo: "consumo",
          id_item: idItem,
          id_evento: idEvento,
          id_reserva: idReserva || null,
          id_fornecedor: idFornecedor,
          quantidade,
          custo_atribuido: dinheiro(resultado.custoAtribuidoCentavos),
          gera_desembolso: false,
          origem_custo: "estoque_consumo",
          chave_idempotencia: chave,
          perspectiva: "fornecedor_privado",
          autor_id: perfil.uid,
          criado_em: FieldValue.serverTimestamp(),
        });
        // Origem única: custo privado do evento sem desembolso.
        if (resultado.custoAtribuidoCentavos > 0) {
          const custoRef = db
            .collection("fornecedor")
            .doc(idFornecedor)
            .collection("custos_internos")
            .doc(chave);
          tx.set(custoRef, {
            schema: 1,
            id_custo: chave,
            id_fornecedor: idFornecedor,
            id_evento: idEvento,
            id_item: idItem,
            id_movimento_estoque: chave,
            tipo: "material",
            valor_incorrido: dinheiro(resultado.custoAtribuidoCentavos),
            valor_obrigacao: dinheiro(0),
            valor_desembolso: dinheiro(0),
            previsto_restante: dinheiro(0),
            origem: "estoque_consumo",
            reutilizavel: false,
            descricao: `Consumo estoque item ${idItem}`,
            autor_id: perfil.uid,
            perspectiva: "fornecedor_privado",
            chave_idempotencia: chave,
            criado_em: FieldValue.serverTimestamp(),
          });
        }
        return {
          ok: true,
          idMovimento: chave,
          custoAtribuidoCentavos: resultado.custoAtribuidoCentavos,
          geraDesembolso: false,
          origemCusto: "estoque_consumo",
        };
      });
    } catch (e) {
      wrapErr(e);
    }
  },
);

export const cancelarReservaEstoqueFornecedor = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idFornecedor = texto(data.idFornecedor ?? data.id_fornecedor);
    const idReserva = texto(data.idReserva ?? data.id_reserva);
    await exigirAcessoFinanceiroFornecedor(
      admin.firestore(),
      perfil,
      idFornecedor,
    );
    const chave =
      texto(data.chaveIdempotencia ?? data.chave_idempotencia) ||
      `can-${idReserva}`;
    const db = admin.firestore();
    try {
      return await db.runTransaction(async (tx) => {
        const movRef = db
          .collection("fornecedor")
          .doc(idFornecedor)
          .collection("estoque_movimentos")
          .doc(chave);
        if ((await tx.get(movRef)).exists) {
          return { ok: true, idempotente: true };
        }
        const resRef = db
          .collection("fornecedor")
          .doc(idFornecedor)
          .collection("estoque_reservas")
          .doc(idReserva);
        const resSnap = await tx.get(resRef);
        if (!resSnap.exists) {
          throw new HttpsError("not-found", "Reserva não encontrada.");
        }
        const reserva = mapReserva(resSnap.id, resSnap.data()!);
        const itemRef = db
          .collection("fornecedor")
          .doc(idFornecedor)
          .collection("estoque_itens")
          .doc(reserva.idItem);
        const itemSnap = await tx.get(itemRef);
        if (!itemSnap.exists) {
          throw new HttpsError("not-found", "Item não encontrado.");
        }
        const resultado = cancelarReserva(
          mapItem(itemSnap.id, itemSnap.data()!),
          reserva,
        );
        tx.update(itemRef, persistItem(resultado.item));
        tx.update(resRef, { status: "cancelada" });
        tx.set(movRef, {
          schema: 1,
          id_movimento: chave,
          tipo: "cancelamento",
          id_reserva: idReserva,
          id_item: reserva.idItem,
          id_fornecedor: idFornecedor,
          quantidade: reserva.quantidade,
          chave_idempotencia: chave,
          perspectiva: "fornecedor_privado",
          criado_em: FieldValue.serverTimestamp(),
        });
        return { ok: true };
      });
    } catch (e) {
      wrapErr(e);
    }
  },
);

export const devolverEstoqueFornecedor = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idFornecedor = texto(data.idFornecedor ?? data.id_fornecedor);
    const idReserva = texto(data.idReserva ?? data.id_reserva);
    await exigirAcessoFinanceiroFornecedor(
      admin.firestore(),
      perfil,
      idFornecedor,
    );
    const chave =
      texto(data.chaveIdempotencia ?? data.chave_idempotencia) ||
      `dev-${idReserva}`;
    const db = admin.firestore();
    try {
      return await db.runTransaction(async (tx) => {
        const movRef = db
          .collection("fornecedor")
          .doc(idFornecedor)
          .collection("estoque_movimentos")
          .doc(chave);
        if ((await tx.get(movRef)).exists) {
          return { ok: true, idempotente: true };
        }
        const resRef = db
          .collection("fornecedor")
          .doc(idFornecedor)
          .collection("estoque_reservas")
          .doc(idReserva);
        const resSnap = await tx.get(resRef);
        if (!resSnap.exists) {
          throw new HttpsError("not-found", "Reserva não encontrada.");
        }
        const reserva = mapReserva(resSnap.id, resSnap.data()!);
        const itemRef = db
          .collection("fornecedor")
          .doc(idFornecedor)
          .collection("estoque_itens")
          .doc(reserva.idItem);
        const itemSnap = await tx.get(itemRef);
        if (!itemSnap.exists) {
          throw new HttpsError("not-found", "Item não encontrado.");
        }
        const resultado = devolverReserva(
          mapItem(itemSnap.id, itemSnap.data()!),
          reserva,
        );
        tx.update(itemRef, persistItem(resultado.item));
        tx.update(resRef, { status: "devolvida" });
        tx.set(movRef, {
          schema: 1,
          id_movimento: chave,
          tipo: "devolucao",
          id_reserva: idReserva,
          id_item: reserva.idItem,
          id_fornecedor: idFornecedor,
          quantidade: reserva.quantidade,
          chave_idempotencia: chave,
          perspectiva: "fornecedor_privado",
          criado_em: FieldValue.serverTimestamp(),
        });
        return { ok: true, idempotente: !!resultado.idempotente };
      });
    } catch (e) {
      wrapErr(e);
    }
  },
);

export const consultarEstoqueFornecedor = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idFornecedor = texto(data.idFornecedor ?? data.id_fornecedor);
    await exigirAcessoFinanceiroFornecedor(
      admin.firestore(),
      perfil,
      idFornecedor,
    );
    const base = admin.firestore().collection("fornecedor").doc(idFornecedor);
    const [itensSnap, reservasSnap, movSnap] = await Promise.all([
      base.collection("estoque_itens").get(),
      base.collection("estoque_reservas").limit(200).get(),
      base
        .collection("estoque_movimentos")
        .orderBy("criado_em", "desc")
        .limit(50)
        .get()
        .catch(() => null),
    ]);
    return {
      ok: true,
      itens: itensSnap.docs.map((d) => ({ id: d.id, ...d.data() })),
      reservas: reservasSnap.docs.map((d) => ({ id: d.id, ...d.data() })),
      movimentos: movSnap
        ? movSnap.docs.map((d) => ({ id: d.id, ...d.data() }))
        : [],
    };
  },
);
