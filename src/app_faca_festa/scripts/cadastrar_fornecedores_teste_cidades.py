"""Cria somente os sete cadastros de teste solicitados, sem aprová-los.

Municípios/coordenadas/DDD reais; empresas e contatos explicitamente fictícios.
Não sobrescreve contas nem documentos existentes. Não envia e-mail/SMS.
"""
from __future__ import annotations

import argparse
import csv
import io
import json
import os
import secrets
from pathlib import Path
from urllib.request import Request, urlopen

import firebase_admin
from firebase_admin import auth, credentials, firestore

ROOT = Path(__file__).resolve().parents[1]
LOTE = "fornecedores_cidades_20261117"
FONTE = "https://raw.githubusercontent.com/kelvins/municipios-brasileiros/main/csv/municipios.csv"
CIDADES = [
    (4209102, "SC", "Aurora Eventos Joinville", "1761673162365"),
    (4109401, "PR", "Sabores da Serra Buffet Guarapuava", "3cbc7cb4-5538-4ce0-9313-36e35bb2834a"),
    (4104808, "PR", "Oeste Festas Decoração Cascavel", "d59ec1ca-2267-4cd1-89c8-5ad0712d450c"),
    (4104303, "PR", "Luz do Campo Fotografia", "50d5aac7-8831-4fca-bfe3-cc2c1f94b509"),
    (4128104, "PR", "Harmonia Eventos Umuarama", "0b5c0fee-2f33-4ae7-8b96-2bb25aedd669"),
    (3534708, "SP", "Doce Encontro Ourinhos", "3cbc7cb4-5538-4ce0-9313-36e35bb2834a"),
    (3507506, "SP", "Horizonte Cerimonial Botucatu", "1761674055649"),
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--aplicar", action="store_true")
    args = parser.parse_args()
    if os.environ.get("FIRESTORE_EMULATOR_HOST") or os.environ.get("FIREBASE_AUTH_EMULATOR_HOST"):
        raise SystemExit("Este cadastro se destina ao projeto exibido no app, não a emuladores.")
    cred = credentials.Certificate(str(ROOT / "scripts/credenciais.json"))
    if cred.project_id != "faca-a-festa":
        raise SystemExit("Projeto de credencial inesperado.")
    firebase_admin.initialize_app(cred, {"projectId": "faca-a-festa"})
    db = firestore.client()
    req = Request(FONTE, headers={"User-Agent": "FacaFesta-CadastroTeste/1.0"})
    with urlopen(req, timeout=30) as resposta:
        municipios = {int(r["codigo_ibge"]): r for r in csv.DictReader(io.StringIO(resposta.read().decode("utf-8-sig")))}
    categorias = {d.id: d.to_dict() for d in db.collection("categoria_servico").stream()}
    plano = []
    for numero, (ibge, uf, nome, categoria) in enumerate(CIDADES, 1):
        m = municipios[ibge]
        assert int(m["codigo_uf"]) == {"SC": 42, "PR": 41, "SP": 35}[uf]
        if categoria not in categorias or categorias[categoria].get("ativo") is False:
            raise SystemExit(f"Categoria indisponível: {categoria}")
        uid = f"forn_teste_cidade_{ibge}_20261117"
        email = f"fornecedor.{ibge}.teste@example.test"
        refs = [f"fornecedor/{uid}", f"usuarios/{uid}", f"territorio/ter_{uid}",
                f"usuarios/{uid}/enderecos/end_{uid}", f"fornecedor_categoria/{uid}_{categoria}"]
        if any(d.exists for d in db.get_all([db.document(p) for p in refs])):
            raise SystemExit(f"Cadastro já existe; nenhum dado foi sobrescrito: {uid}")
        for buscar, argumento in [(auth.get_user, uid), (auth.get_user_by_email, email)]:
            try:
                buscar(argumento)
            except auth.UserNotFoundError:
                pass
            else:
                raise SystemExit(f"Conta já existe; não será alterada: {uid}")
        plano.append({"uid": uid, "nome": f"{nome} (Teste)", "email": email,
                      "telefone": f"({m['ddd']}) 0000-{numero:04d}",
                      "cidade": m["nome"], "uf": uf, "id_cidade": ibge,
                      "latitude": float(m["latitude"]), "longitude": float(m["longitude"]),
                      "raio_km": 50, "categoria": categoria,
                      "nome_categoria": categorias[categoria]["nome"]})
    pasta = ROOT / ".dart_tool" / LOTE
    pasta.mkdir(parents=True, exist_ok=True)
    (pasta / "plano.json").write_text(json.dumps({"projeto": "faca-a-festa", "fonte": FONTE, "fornecedores": plano}, ensure_ascii=False, indent=2), encoding="utf-8")
    for p in plano:
        print(f"{p['nome']} | {p['cidade']}/{p['uf']} | {p['latitude']}, {p['longitude']} | aguardando aprovação")
    if not args.aplicar:
        print("Prévia somente: nenhuma conta ou documento foi criado.")
        return
    lote = db.batch()
    contas_criadas = []
    acesso = []
    try:
        for p in plano:
            uid = p["uid"]
            senha = secrets.token_urlsafe(24)
            auth.create_user(uid=uid, email=p["email"], password=senha, display_name=p["nome"], email_verified=False)
            contas_criadas.append(uid)
            acesso.append({"uid": uid, "email": p["email"], "senha": senha})
            comum = {"dados_teste": True, "lote_teste": LOTE, "data_cadastro": firestore.SERVER_TIMESTAMP}
            descricao = f"Fornecedor fictício para testes em {p['cidade']}/{p['uf']}. Localização de referência da sede municipal; não representa endereço comercial. Contatos de teste sem atendimento."
            lote.create(db.document(f"fornecedor/{uid}"), {
                **comum, "id_fornecedor": uid, "id_usuario": uid, "razao_social": p["nome"],
                "email": p["email"], "telefone": p["telefone"], "cnpj": None,
                "descricao": descricao, "ativo": True, "apto_para_operar": False,
                "categorias": [{"idCategoria": p["categoria"], "nomeCategoria": p["nome_categoria"], "subcategorias": []}],
                "tipoEventoIds": [], "tipoEventoSlugs": [], "tipoEventoNomes": [],
                "media_avaliacoes": 0, "total_avaliacoes": 0, "total_contratacoes": 0,
                "is_top_categoria": False, "banner_url": None})
            lote.create(db.document(f"usuarios/{uid}"), {
                **comum, "id_usuario": uid, "nome": p["nome"], "email": p["email"],
                "email_normalizado": p["email"], "telefone": p["telefone"], "tipo": "F", "ativo": True,
                "cidade": p["cidade"], "uf": p["uf"]})
            lote.create(db.document(f"usuarios/{uid}/enderecos/end_{uid}"), {
                **comum, "id": f"end_{uid}", "id_usuario": uid, "id_cidade": p["id_cidade"],
                "nome_cidade": p["cidade"], "uf": p["uf"], "principal": True,
                "cep": "", "logradouro": "", "numero": "", "bairro": "",
                "complemento": "Localização municipal para testes; sem endereço comercial."})
            lote.create(db.document(f"territorio/ter_{uid}"), {
                **comum, "id_territorio": f"ter_{uid}", "id_fornecedor": uid,
                "latitude": p["latitude"], "longitude": p["longitude"], "raio_km": p["raio_km"],
                "descricao": f"Atende {p['cidade']}/{p['uf']} e região — cadastro de teste",
                "regioes": [p["cidade"]], "tipo_cobertura": "raio", "ativo": True,
                "fonte_localizacao": FONTE})
            lote.create(db.document(f"fornecedor_categoria/{uid}_{p['categoria']}"), {
                **comum, "id_fornecedor": uid, "id_categoria": p["categoria"],
                "nome_categoria": p["nome_categoria"], "subcategorias": []})
        lote.commit()
    except Exception:
        # Só compensa contas criadas por esta execução se nenhum fornecedor foi persistido.
        if contas_criadas and not any(d.exists for d in db.get_all([db.document(f"fornecedor/{uid}") for uid in contas_criadas])):
            for uid in contas_criadas:
                auth.delete_user(uid)
        raise
    (pasta / "acessos_locais.json").write_text(json.dumps(acesso, ensure_ascii=False, indent=2), encoding="utf-8")
    resultado = []
    for p in plano:
        uid = p["uid"]
        fornecedor = db.document(f"fornecedor/{uid}").get().to_dict()
        territorio = db.document(f"territorio/ter_{uid}").get().to_dict()
        usuario = db.document(f"usuarios/{uid}").get().to_dict()
        conta = auth.get_user(uid)
        assert fornecedor["ativo"] is True and fornecedor["apto_para_operar"] is False
        assert territorio["ativo"] is True and territorio["id_fornecedor"] == uid
        assert (territorio["latitude"], territorio["longitude"]) == (p["latitude"], p["longitude"])
        assert usuario["tipo"] == "F" and conta.email == p["email"]
        resultado.append({**p, "apto_para_operar": False, "verificado": True})
    (pasta / "resultado.json").write_text(json.dumps(resultado, ensure_ascii=False, indent=2), encoding="utf-8")
    print("Verificados: 7 contas, 7 fornecedores pendentes e 7 territórios ativos. Nenhum cadastro anterior alterado.")


if __name__ == "__main__":
    main()
