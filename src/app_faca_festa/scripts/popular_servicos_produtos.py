"""Grava o catálogo de serviços/produtos no Firestore.

Lê lib/data/seeds/servico_produto_seed.dart e faz merge na coleção
servico_produto. IDs existentes são preservados.
"""

from __future__ import annotations

import os
import re
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

ROOT = Path(__file__).resolve().parents[1]
SEED = ROOT / "lib" / "data" / "seeds" / "servico_produto_seed.dart"
SEED_CAT = ROOT / "lib" / "data" / "seeds" / "categoria_servico_seed.dart"
CREDENCIAIS = Path(__file__).resolve().parent / "credenciais.json"


def _texto(bloco: str, campo: str) -> str:
    padrao = rf"{campo}:\s*((?:'[^']*'\s*)+|\w+)"
    match = re.search(padrao, bloco)
    if not match:
        raise ValueError(f"Campo '{campo}' ausente no bloco:\n{bloco[:240]}")
    bruto = match.group(1).strip()
    if bruto.startswith("'"):
        return "".join(re.findall(r"'([^']*)'", bruto))
    return bruto


def carregar_produtos() -> list[dict]:
    fonte = SEED.read_text(encoding="utf-8")
    produtos = []
    for bloco in re.findall(r"_prod\(\s*id:(.*?)\),", fonte, flags=re.S):
        bloco = "id:" + bloco
        produtos.append(
            {
                "id": _texto(bloco, "id"),
                "id_subcategoria": _texto(bloco, "idSubcategoria"),
                "nome": _texto(bloco, "nome"),
                "descricao": _texto(bloco, "descricao"),
                "tipo_medida": _texto(bloco, "tipoMedida"),
                "ativo": True,
            }
        )
    return produtos


def ids_subcategorias_seed() -> set[str]:
    fonte = SEED_CAT.read_text(encoding="utf-8")
    return set(re.findall(r"_sub\(\s*id:\s*'([^']+)'", fonte))


def gravar(db, produtos: list[dict]) -> None:
    colecao = db.collection("servico_produto")
    existentes = {doc.id for doc in colecao.stream()}
    lote = db.batch()
    operacoes = 0

    def commit():
        nonlocal lote, operacoes
        if operacoes == 0:
            return
        lote.commit()
        lote = db.batch()
        operacoes = 0

    for item in produtos:
        if operacoes >= 400:
            commit()
        payload = dict(item)
        payload["data_atualizacao"] = firestore.SERVER_TIMESTAMP
        if item["id"] not in existentes:
            payload["data_cadastro"] = firestore.SERVER_TIMESTAMP
        lote.set(colecao.document(item["id"]), payload, merge=True)
        operacoes += 1
    commit()


def main() -> None:
    os.chdir(Path(__file__).resolve().parent)
    produtos = carregar_produtos()
    ids = [p["id"] for p in produtos]
    duplicados = sorted({i for i in ids if ids.count(i) > 1})
    if duplicados:
        raise SystemExit(f"IDs duplicados no seed: {duplicados}")

    subs_cat = ids_subcategorias_seed()
    subs_prod = {p["id_subcategoria"] for p in produtos}
    faltando = sorted(subs_cat - subs_prod)
    extras = sorted(subs_prod - subs_cat)
    print(f"Catálogo lido: {len(produtos)} serviços/produtos")
    if extras:
        print(f"Subcategorias no produto sem seed: {extras}")
    if faltando:
        print(f"Subcategorias sem produto ({len(faltando)}): {faltando}")

    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(str(CREDENCIAIS)))
    db = firestore.client()
    gravar(db, produtos)

    total = len(list(db.collection("servico_produto").stream()))
    print("Gravado com merge no projeto faca-a-festa.")
    print(f"Firestore agora: {total} serviços/produtos")

    por_sub: dict[str, int] = {}
    for p in produtos:
        por_sub[p["id_subcategoria"]] = por_sub.get(p["id_subcategoria"], 0) + 1
    print(f"Cobertura: {len(por_sub)} subcategorias com produto")


if __name__ == "__main__":
    main()
