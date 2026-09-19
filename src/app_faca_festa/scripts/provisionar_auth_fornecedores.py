"""Cria contas no Firebase Authentication para os fornecedores de teste.

O seed `popular_fornecedores_festas.py` grava só Firestore (`usuarios` e
`fornecedor` com IDs curtos). O login do app autentica pelo Auth e depois
busca `usuarios/{uid}` — o UID precisa ser o mesmo ID do documento.

Este script:
  - lê os fornecedores do seed (não contas reais com `preservar_identidade`)
  - cria Auth com uid = id do Firestore e o e-mail já cadastrado
  - não grava nem altera `mfa_totp` (o 1º login com senha abre o setup)

Uso:
  python provisionar_auth_fornecedores.py
  python provisionar_auth_fornecedores.py --aplicar
  python provisionar_auth_fornecedores.py --aplicar --senha "SenhaTeste@2026"
  python provisionar_auth_fornecedores.py --aplicar --uid bar999666
  python provisionar_auth_fornecedores.py --aplicar --reset-senha

A senha padrão de teste é FacaFesta@2026 (ou AUTH_FORNECEDOR_SENHA).
No primeiro login o app pede MFA: escolha código por e-mail para testar
sem app autenticador.
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

import firebase_admin
from firebase_admin import auth, credentials, firestore
from firebase_admin.exceptions import FirebaseError

from popular_fornecedores_festas import CREDENCIAIS, FORNECEDORES

SENHA_PADRAO = os.environ.get("AUTH_FORNECEDOR_SENHA", "FacaFesta@2026")


def inicializar():
    os.chdir(Path(__file__).resolve().parent)
    if not CREDENCIAIS.exists():
        raise SystemExit(
            f"Arquivo de credenciais não encontrado: {CREDENCIAIS}\n"
            "Coloque o service account em scripts/credenciais.json."
        )
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(str(CREDENCIAIS)))
    return firestore.client()


def candidatos(somente_uid: str | None) -> list[dict]:
    lista = []
    for forn in FORNECEDORES:
        if forn.get("preservar_identidade"):
            continue
        if somente_uid and forn["id"] != somente_uid:
            continue
        lista.append(forn)
    if somente_uid and not lista:
        raise SystemExit(
            f"UID '{somente_uid}' não está no seed de teste "
            "(ou tem preservar_identidade)."
        )
    return lista


def buscar_auth_por_uid(uid: str):
    try:
        return auth.get_user(uid)
    except auth.UserNotFoundError:
        return None


def buscar_auth_por_email(email: str):
    try:
        return auth.get_user_by_email(email)
    except auth.UserNotFoundError:
        return None


def conferir_firestore(db, forn: dict) -> str | None:
    uid = forn["id"]
    email = (forn.get("email") or "").strip().lower()
    if not email or "@" not in email:
        return f"e-mail inválido no seed: {email!r}"

    usuario = db.collection("usuarios").document(uid).get()
    if not usuario.exists:
        return "não há usuarios/{uid} no Firestore — rode o seed antes"

    dados = usuario.to_dict() or {}
    tipo = str(dados.get("tipo") or "").strip().upper()
    if tipo != "F":
        return f"usuarios/{uid} não é tipo F (tipo={tipo or 'vazio'})"

    fornecedor = db.collection("fornecedor").document(uid).get()
    if not fornecedor.exists:
        return "não há fornecedor/{uid} no Firestore — rode o seed antes"

    email_firestore = str(dados.get("email") or "").strip().lower()
    if email_firestore and email_firestore != email:
        return (
            f"e-mail do seed ({email}) difere do Firestore ({email_firestore})"
        )
    return None


def provisionar_um(
    db,
    forn: dict,
    senha: str,
    aplicar: bool,
    reset_senha: bool,
) -> str:
    uid = forn["id"]
    email = forn["email"].strip().lower()
    nome = forn["nome"]

    conflito = conferir_firestore(db, forn)
    if conflito:
        print(f"  ! {uid} ({nome}): {conflito}")
        return "erro"

    atual_uid = buscar_auth_por_uid(uid)
    atual_email = buscar_auth_por_email(email)

    if atual_email and atual_email.uid != uid:
        print(
            f"  ! {uid} ({nome}): e-mail {email} já pertence ao Auth "
            f"uid={atual_email.uid}. Não cria para não duplicar."
        )
        return "conflito"

    if atual_uid and (atual_uid.email or "").strip().lower() not in ("", email):
        print(
            f"  ! {uid} ({nome}): Auth já existe com e-mail "
            f"{atual_uid.email}. Não altera."
        )
        return "conflito"

    if atual_uid:
        acao = "resetar senha" if reset_senha else "já existe"
        print(f"  = {uid}  {email}  [{acao}]  {nome}")
        if aplicar and reset_senha:
            auth.update_user(uid, password=senha, email_verified=True)
        return "reset" if reset_senha else "existe"

    print(f"  + {uid}  {email}  {nome}")
    if aplicar:
        auth.create_user(
            uid=uid,
            email=email,
            password=senha,
            display_name=nome,
            email_verified=True,
            disabled=False,
        )
    return "criar"


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Provisiona Firebase Auth para fornecedores de teste do seed. "
            "Não altera mfa_totp."
        )
    )
    parser.add_argument(
        "--aplicar",
        action="store_true",
        help="Cria/atualiza no Authentication. Sem esta flag só simula.",
    )
    parser.add_argument(
        "--senha",
        default=SENHA_PADRAO,
        help=f"Senha de teste (padrão: {SENHA_PADRAO})",
    )
    parser.add_argument(
        "--uid",
        default="",
        help="Provisiona só este ID (ex.: bar999666).",
    )
    parser.add_argument(
        "--reset-senha",
        action="store_true",
        help="Se o Auth já existir com o mesmo UID, redefine a senha.",
    )
    args = parser.parse_args()

    if len(args.senha) < 6:
        raise SystemExit("A senha precisa ter pelo menos 6 caracteres.")

    db = inicializar()
    lista = candidatos(args.uid.strip() or None)
    modo = "APLICAR" if args.aplicar else "SIMULAÇÃO"
    print(f"[{modo}] {len(lista)} fornecedor(es) de teste")
    print("mfa_totp: não será criado nem alterado")
    print()

    contagem = {
        "criar": 0,
        "existe": 0,
        "reset": 0,
        "conflito": 0,
        "erro": 0,
    }
    for forn in lista:
        try:
            resultado = provisionar_um(
                db,
                forn,
                senha=args.senha,
                aplicar=args.aplicar,
                reset_senha=args.reset_senha,
            )
        except FirebaseError as exc:
            print(f"  ! {forn['id']} ({forn['nome']}): {exc}")
            resultado = "erro"
        contagem[resultado] = contagem.get(resultado, 0) + 1

    print()
    print(
        "Resumo: "
        f"criar={contagem['criar']}  "
        f"já existia={contagem['existe']}  "
        f"senha redefinida={contagem['reset']}  "
        f"conflito={contagem['conflito']}  "
        f"erro={contagem['erro']}"
    )
    if not args.aplicar:
        print()
        print("Nada foi gravado. Para criar as contas:")
        extra = f" --uid {args.uid}" if args.uid.strip() else ""
        print(f"  python provisionar_auth_fornecedores.py --aplicar{extra}")
        print(f"Senha de teste: {args.senha}")
        print(
            "No 1º login com senha o app pede MFA "
            "(escolha código por e-mail)."
        )
        return

    print()
    print(f"Senha de teste: {args.senha}")
    print(
        "Login: e-mail do fornecedor + senha acima. "
        "No 1º acesso configure o MFA."
    )


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
