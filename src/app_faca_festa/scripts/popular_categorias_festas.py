"""Grava o catálogo de categorias/subcategorias no Firestore.

Lê lib/data/seeds/categoria_servico_seed.dart e faz merge nas coleções
categoria_servico e subcategoria_servico. IDs existentes são preservados.
"""

from __future__ import annotations

import os
import re
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

ROOT = Path(__file__).resolve().parents[1]
SEED = ROOT / "lib" / "data" / "seeds" / "categoria_servico_seed.dart"
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


def _int(bloco: str, campo: str) -> int:
    match = re.search(rf"{campo}:\s*(\d+)", bloco)
    if not match:
        raise ValueError(f"Campo '{campo}' ausente no bloco:\n{bloco[:240]}")
    return int(match.group(1))


def carregar_catalogo() -> tuple[list[dict], list[dict]]:
    fonte = SEED.read_text(encoding="utf-8")
    ids = {
        nome: valor
        for nome, valor in re.findall(r"static const (\w+) = '([^']+)';", fonte)
    }

    categorias = []
    for bloco in re.findall(r"_cat\(\s*id:(.*?)\),", fonte, flags=re.S):
        bloco = "id:" + bloco
        id_bruto = _texto(bloco, "id")
        categorias.append(
            {
                "id": ids.get(id_bruto, id_bruto),
                "nome": _texto(bloco, "nome"),
                "descricao": _texto(bloco, "descricao"),
                "ordem": _int(bloco, "ordem"),
                "icone": _texto(bloco, "icone"),
                "ativo": True,
            }
        )

    subcategorias = []
    for bloco in re.findall(r"_sub\(\s*id:(.*?)\),", fonte, flags=re.S):
        bloco = "id:" + bloco
        id_cat = _texto(bloco, "idCategoria")
        subcategorias.append(
            {
                "id": _texto(bloco, "id"),
                "id_categoria": ids.get(id_cat, id_cat),
                "nome": _texto(bloco, "nome"),
                "descricao": _texto(bloco, "descricao"),
                "ordem": _int(bloco, "ordem"),
                "icone": _texto(bloco, "icone"),
                "ativo": True,
            }
        )

    return categorias, subcategorias


def _ids_existentes(colecao) -> set[str]:
    return {doc.id for doc in colecao.stream()}


def gravar(db, categorias: list[dict], subcategorias: list[dict]) -> None:
    col_cat = db.collection("categoria_servico")
    col_sub = db.collection("subcategoria_servico")
    existentes_cat = _ids_existentes(col_cat)
    existentes_sub = _ids_existentes(col_sub)

    lote = db.batch()
    for item in categorias:
        payload = dict(item)
        payload["data_atualizacao"] = firestore.SERVER_TIMESTAMP
        if item["id"] not in existentes_cat:
            payload["data_cadastro"] = firestore.SERVER_TIMESTAMP
        lote.set(col_cat.document(item["id"]), payload, merge=True)

    for item in subcategorias:
        payload = dict(item)
        payload["data_atualizacao"] = firestore.SERVER_TIMESTAMP
        if item["id"] not in existentes_sub:
            payload["data_cadastro"] = firestore.SERVER_TIMESTAMP
        lote.set(col_sub.document(item["id"]), payload, merge=True)

    lote.commit()


def main() -> None:
    os.chdir(Path(__file__).resolve().parent)
    categorias, subcategorias = carregar_catalogo()
    print(f"Catálogo lido: {len(categorias)} categorias, {len(subcategorias)} subcategorias")

    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(str(CREDENCIAIS)))
    db = firestore.client()
    gravar(db, categorias, subcategorias)

    total_cat = len(list(db.collection("categoria_servico").stream()))
    total_sub = len(list(db.collection("subcategoria_servico").stream()))
    print("Gravado com merge no projeto faca-a-festa.")
    print(f"Firestore agora: {total_cat} categorias, {total_sub} subcategorias")
    for cat in sorted(categorias, key=lambda c: c["ordem"]):
        n = sum(1 for s in subcategorias if s["id_categoria"] == cat["id"])
        print(f"  - {cat['nome']} ({n})")


if __name__ == "__main__":
    main()
