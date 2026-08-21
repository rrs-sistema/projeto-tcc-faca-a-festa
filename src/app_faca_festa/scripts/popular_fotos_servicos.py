"""Grava fotos de produtos/serviços na coleção servico_foto.

Uma imagem por vínculo fornecedor_servico, escolhida pelo nome do produto
e pela categoria. IDs estáveis `foto_{fornecedor}_{produto}`. Merge; extras
não são apagados.
"""

from __future__ import annotations

import hashlib
import os
import unicodedata
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

CREDENCIAIS = Path(__file__).resolve().parent / "credenciais.json"

CAT_ESPACO = "1761673162365"
CAT_BUFFET = "3cbc7cb4-5538-4ce0-9313-36e35bb2834a"
CAT_DECOR = "d59ec1ca-2267-4cd1-89c8-5ad0712d450c"
CAT_MODA = "cat_moda_trajes"
CAT_BELEZA = "1760923921063"
CAT_FOTO = "50d5aac7-8831-4fca-bfe3-cc2c1f94b509"
CAT_MUSICA = "0b5c0fee-2f33-4ae7-8b96-2bb25aedd669"
CAT_RECREACAO = "cat_recreacao_entretenimento"
CAT_TRANSPORTE = "1761673265007"
CAT_PAPELARIA = "1761673435226"
CAT_ASSESSORIA = "1761674055649"
CAT_CORP = "5fd47622-8e80-4477-a86c-f4d9c4422164"
CAT_SEGURANCA = "cat_seguranca_apoio"


def img(photo_id: str) -> str:
    return f"https://images.unsplash.com/{photo_id}?auto=format&fit=crop&w=1400&q=80"


HALL = img("photo-1540575467063-178a50c2df87")
OUTDOOR = img("photo-1464207687429-7505649dae38")
TENT = img("photo-1533174072545-7a4b6ad7a6c3")
DINING = img("photo-1414235077428-338989a2e8c0")
VINTAGE = img("photo-1464047736614-af63643285bf")
CATERING = img("photo-1555244162-803834f70033")
CAKE = img("photo-1535254973040-607b474cb50d")
CAKE2 = img("photo-1578985545062-69928b1d9587")
DESSERT = img("photo-1478144592103-25e218a04891")
BAR = img("photo-1514933651103-005eec06c04b")
BAR2 = img("photo-1572116469696-31de0f17cc34")
COCKTAIL = img("photo-1551024709-8f23befc6f87")
FOOD = img("photo-1464305795204-6f5bbfc7fb81")
BOUQUET = img("photo-1465495976277-4387d4b0b4c6")
PLANTS = img("photo-1501004318641-b39e6451bec6")
PARTY = img("photo-1527526029430-319f10814151")
COLOR = img("photo-1558637845-c8b7ead71a3e")
DRESS = img("photo-1594552072238-b8a33785b261")
RINGS = img("photo-1606216794074-735e91aa2c92")
RINGS2 = img("photo-1515934751635-c81c6bc9a2d8")
MAKEUP = img("photo-1487412947147-5cebf100ffc2")
SALON = img("photo-1560066984-138dadb4c035")
CAMERA = img("photo-1516035069371-29a1b244cc32")
PHOTOGRAPHER = img("photo-1492691527719-9d1e07e534b4")
STUDIO = img("photo-1471341971476-ae15ff5dd4ea")
CAMERA2 = img("photo-1542038784456-1ea8e935640e")
CONCERT = img("photo-1470225620780-dba8ba36b745")
CONCERT2 = img("photo-1506157786151-b8491531f063")
BAND = img("photo-1511671782779-c97d3d27a1d4")
MUSICIAN = img("photo-1493225457124-a3eb161ffa5f")
CROWD = img("photo-1429962714451-bb934ecdc4ec")
STAGE = img("photo-1514525253161-7a46d19cd819")
BABY = img("photo-1515488042361-ee00e0ddd4e4")
CAR = img("photo-1492144534655-ae79c964c9d7")
TABLE = img("photo-1511795409834-ef04bbd61622")
WEDDING = img("photo-1519741497674-611481863552")
CONF = img("photo-1511578314322-379afb476865")
GRAD = img("photo-1627556704290-2b1f5853ff78")
CONF2 = img("photo-1523580494863-6f3031224c94")
BEACH = img("photo-1507525428034-b723cf961d3e")
JUNGLE = img("photo-1502082553048-f009c37129b9")
FOREST = img("photo-1418065460487-3e41a6c84dc5")
CINEMA = img("photo-1517604931442-7e0c8ed2963c")

POR_CATEGORIA = {
    CAT_ESPACO: [HALL, OUTDOOR, TENT, DINING, VINTAGE],
    CAT_BUFFET: [CATERING, CAKE, DESSERT, BAR, COCKTAIL, FOOD, CAKE2],
    CAT_DECOR: [BOUQUET, PLANTS, DESSERT, PARTY, COLOR, TENT],
    CAT_MODA: [DRESS, RINGS, RINGS2, WEDDING],
    CAT_BELEZA: [MAKEUP, SALON],
    CAT_FOTO: [CAMERA, PHOTOGRAPHER, STUDIO, CAMERA2],
    CAT_MUSICA: [CONCERT, CONCERT2, BAND, MUSICIAN, CROWD, STAGE],
    CAT_RECREACAO: [PARTY, COLOR, BABY, CINEMA],
    CAT_TRANSPORTE: [CAR],
    CAT_PAPELARIA: [TABLE, DESSERT, COLOR],
    CAT_ASSESSORIA: [WEDDING, RINGS, TABLE, CONF],
    CAT_CORP: [CONF, HALL, GRAD, CONF2, STAGE],
    CAT_SEGURANCA: [CONF, HALL, CONF2],
}

KEYWORDS = [
    (("chacara", "sitio", "piscina", "campo", "casa de campo"), OUTDOOR),
    (("salao", "cerimonia e recepcao"), HALL),
    (("tenda", "cristal", "cobertura", "passarela"), TENT),
    (("palco", "tablado", "pista de danca", "led"), STAGE),
    (("mesa redonda", "cadeira", "tiffany", "toalha", "jantar", "tacas", "louca", "lounge", "sofa"), DINING),
    (("bolo", "fake cake", "cupcake", "torta"), CAKE),
    (("doce", "brigadeiro", "bem-casado", "sobremesa"), DESSERT),
    (("chopp", "choppeira", "open bar", "bartender", "drinks", "barril"), BAR),
    (("bebida", "refri", "suco"), COCKTAIL),
    (("buffet", "jantar", "coquetel", "churrasco", "espetinho", "massas", "pizza", "food truck"), CATERING),
    (("salgado", "cento"), FOOD),
    (("pipoca", "algodao", "churros", "hot dog", "acai", "sorvete", "carrinho"), DESSERT),
    (("coffee", "brunch", "frios"), CONF2),
    (("buque", "floral", "arco floral", "petala", "arranjo"), BOUQUET),
    (("balao", "painel", "arco organico", "decoracao"), PARTY),
    (("neon", "letreiro", "cordao de luz", "luminaria"), TENT),
    (("vestido", "terno", "smoking", "noiva", "madrinha", "15 anos"), DRESS),
    (("penteado", "maquiagem", "cabelo", "unha", "barbearia", "dia da noiva"), MAKEUP),
    (("foto", "film", "drone", "cabine", "ensaio", "plataforma 360"), CAMERA),
    (("dj", "som", "iluminacao", "karaoke", "painel de led"), CONCERT),
    (("banda", "violao", "musico", "voz e"), BAND),
    (("recreacao", "personagem", "inflavel", "pula-pula", "magico", "oficina", "kids", "brinquedoteca"), PARTY),
    (("carro", "van", "limousine", "transfer", "onibus"), CAR),
    (("convite", "lembrancinha", "tag", "papelaria", "identidade"), TABLE),
    (("cerimonial", "wedding", "planner", "coordenacao"), WEDDING),
    (("formatura", "beca"), GRAD),
    (("corporativo", "credenciamento", "convencao", "palestra"), CONF),
    (("seguranca", "garcom", "valet", "recepcionista", "brigada", "limpeza"), CONF),
    (("gerador", "energia", "ar-condicionado", "climatizador", "banheiro"), TENT),
    (("freezer", "gelo"), BAR2),
    (("safari", "selva", "bosque"), JUNGLE),
    (("mar", "praia"), BEACH),
    (("cinema", "pipoca"), CINEMA),
    (("bebe", "cha de"), BABY),
]


def _norm(texto: str) -> str:
    nfd = unicodedata.normalize("NFD", texto.lower())
    return "".join(ch for ch in nfd if unicodedata.category(ch) != "Mn")


def _hash_int(texto: str, modulo: int) -> int:
    if modulo <= 0:
        return 0
    digest = hashlib.md5(texto.encode("utf-8")).hexdigest()
    return int(digest[:8], 16) % modulo


def escolher_foto(nome: str, id_categoria: str, chave: str) -> str:
    nome_n = _norm(nome)
    for palavras, url in KEYWORDS:
        if any(p in nome_n for p in palavras):
            return url
    pool = POR_CATEGORIA.get(id_categoria) or [HALL, PARTY, CONF]
    return pool[_hash_int(chave, len(pool))]


class Lote:
    def __init__(self, db, limite: int = 400):
        self.db = db
        self.limite = limite
        self.batch = db.batch()
        self.ops = 0
        self.total = 0

    def set(self, ref, data, merge=True):
        self.batch.set(ref, data, merge=merge)
        self.ops += 1
        self.total += 1
        if self.ops >= self.limite:
            self.commit()

    def commit(self):
        if self.ops == 0:
            return
        self.batch.commit()
        self.batch = self.db.batch()
        self.ops = 0


def carregar_mapas(db):
    produtos = {}
    for doc in db.collection("servico_produto").stream():
        data = doc.to_dict() or {}
        produtos[doc.id] = {
            "id": doc.id,
            "nome": data.get("nome") or "",
            "id_subcategoria": data.get("id_subcategoria") or "",
        }

    sub_para_cat = {}
    for doc in db.collection("subcategoria_servico").stream():
        data = doc.to_dict() or {}
        sub_para_cat[doc.id] = data.get("id_categoria") or data.get("idCategoria") or ""

    return produtos, sub_para_cat


def main() -> None:
    os.chdir(Path(__file__).resolve().parent)
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(str(CREDENCIAIS)))
    db = firestore.client()

    produtos, sub_para_cat = carregar_mapas(db)
    vinculos = list(db.collection("fornecedor_servico").stream())
    print(f"Vínculos fornecedor_servico: {len(vinculos)}")
    print(f"Produtos no catálogo: {len(produtos)}")

    lote = Lote(db)
    gravados = 0
    sem_produto = 0

    for doc in vinculos:
        data = doc.to_dict() or {}
        id_forn = (data.get("id_fornecedor") or "").strip()
        id_prod = (data.get("id_produto_servico") or "").strip()
        if not id_forn or not id_prod:
            continue
        produto = produtos.get(id_prod)
        if not produto:
            sem_produto += 1
            continue
        id_cat = sub_para_cat.get(produto["id_subcategoria"], "")
        url = escolher_foto(produto["nome"], id_cat, f"{id_forn}_{id_prod}")
        foto_id = f"foto_{id_forn}_{id_prod}"[:1400]
        lote.set(
            db.collection("servico_foto").document(foto_id),
            {
                "id": foto_id,
                "id_produto_servico": id_prod,
                "id_fornecedor": id_forn,
                "url": url,
                "data_upload": firestore.SERVER_TIMESTAMP,
            },
        )
        gravados += 1

    lote.commit()
    total = len(list(db.collection("servico_foto").stream()))
    print(f"Fotos gravadas/atualizadas: {gravados}")
    if sem_produto:
        print(f"Vínculos sem produto no catálogo: {sem_produto}")
    print(f"Coleção servico_foto: {total} documentos")


if __name__ == "__main__":
    main()
