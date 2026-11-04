import { FieldValue } from "firebase-admin/firestore";
import { dinheiro } from "./dinheiro";
import { ItemEstoque, ReservaEstoque, NaturezaItem, StatusFisico } from "./estoqueFornecedorService";
export function mapItem(id: string, data: FirebaseFirestore.DocumentData): ItemEstoque {
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

export function mapReserva(
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

export function persistItem(item: ItemEstoque): FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> {
  return {
    quantidade_total: item.quantidadeTotal,
    quantidade_reservada: item.quantidadeReservada,
    quantidade_em_uso: item.quantidadeEmUso,
    custo_medio_unitario: dinheiro(item.custoMedioUnitarioCentavos),
    custo_ausente: item.custoAusente === true,
    atualizado_em: FieldValue.serverTimestamp(),
  };
}
