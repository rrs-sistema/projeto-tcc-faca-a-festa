"""Cadastra fornecedores de festas e vincula aos produtos do catálogo.

Lê categorias, subcategorias e servico_produto no Firestore.
Grava (merge):
  - fornecedor
  - usuarios (tipo F)
  - usuarios/{id}/enderecos
  - territorio
  - fornecedor_categoria
  - fornecedor_servico (preço de mercado)
"""

from __future__ import annotations

import hashlib
import os
import re
import sys
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

CREDENCIAIS = Path(__file__).resolve().parent / "credenciais.json"


def img(photo_id: str, w: int = 1400) -> str:
    return f"https://images.unsplash.com/{photo_id}?auto=format&fit=crop&w={w}&q=80"

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

EV_CASAMENTO = ("302191a2-dbf3-4ac6-ba53-08273b384cab", "casamento", "Casamento")
EV_ANIVER = ("7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda", "aniversario", "Aniversário")
EV_INFANTIL = ("ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8", "festa-infantil", "Festa Infantil")
EV_FORMATURA = ("WlLdfdmu4Chvw2p8daUm", "formatura", "Formatura")
EV_CORP = ("lXf0M5vMNvyRn52yQ2fY", "evento-corporativo", "Evento Corporativo")
EV_CHA = ("1eab2c53-a7d3-4a97-b473-02572464e779", "cha-de-bebe", "Chá de Bebê")

CURITIBA = {
    "cidade": "Curitiba",
    "uf": "PR",
    "id_cidade": 4106902,
    "cep": "80010-000",
    "lat": -25.4284,
    "lng": -49.2733,
    "bairro": "Centro",
}
SJP = {
    "cidade": "São José dos Pinhais",
    "uf": "PR",
    "id_cidade": 4125506,
    "cep": "83005-040",
    "lat": -25.5317,
    "lng": -49.2031,
    "bairro": "Centro",
}
MARINGA = {
    "cidade": "Maringá",
    "uf": "PR",
    "id_cidade": 4115200,
    "cep": "87013-050",
    "lat": -23.4205,
    "lng": -51.9333,
    "bairro": "Zona 07",
}
LONDRINA = {
    "cidade": "Londrina",
    "uf": "PR",
    "id_cidade": 4113700,
    "cep": "86010-190",
    "lat": -23.3045,
    "lng": -51.1696,
    "bairro": "Centro",
}
PONTA_GROSSA = {
    "cidade": "Ponta Grossa",
    "uf": "PR",
    "id_cidade": 4119905,
    "cep": "84010-010",
    "lat": -25.0916,
    "lng": -50.1668,
    "bairro": "Centro",
}

BASE_PRECO = {
    (CAT_ESPACO, "D"): 2800,
    (CAT_ESPACO, "U"): 22,
    (CAT_ESPACO, "P"): 1900,
    (CAT_ESPACO, "H"): 180,
    (CAT_BUFFET, "P"): 135,
    (CAT_BUFFET, "U"): 98,
    (CAT_BUFFET, "D"): 890,
    (CAT_BUFFET, "H"): 190,
    (CAT_DECOR, "P"): 3200,
    (CAT_DECOR, "U"): 240,
    (CAT_DECOR, "D"): 780,
    (CAT_DECOR, "H"): 160,
    (CAT_MODA, "P"): 1600,
    (CAT_MODA, "U"): 420,
    (CAT_MODA, "D"): 350,
    (CAT_MODA, "H"): 90,
    (CAT_BELEZA, "P"): 980,
    (CAT_BELEZA, "U"): 280,
    (CAT_BELEZA, "H"): 180,
    (CAT_BELEZA, "D"): 650,
    (CAT_FOTO, "P"): 2800,
    (CAT_FOTO, "H"): 320,
    (CAT_FOTO, "D"): 1500,
    (CAT_FOTO, "U"): 450,
    (CAT_MUSICA, "P"): 2200,
    (CAT_MUSICA, "H"): 380,
    (CAT_MUSICA, "D"): 1600,
    (CAT_MUSICA, "U"): 350,
    (CAT_RECREACAO, "P"): 650,
    (CAT_RECREACAO, "H"): 180,
    (CAT_RECREACAO, "D"): 480,
    (CAT_RECREACAO, "U"): 320,
    (CAT_TRANSPORTE, "D"): 890,
    (CAT_TRANSPORTE, "H"): 160,
    (CAT_TRANSPORTE, "P"): 1400,
    (CAT_TRANSPORTE, "U"): 280,
    (CAT_PAPELARIA, "U"): 12.9,
    (CAT_PAPELARIA, "P"): 890,
    (CAT_PAPELARIA, "D"): 250,
    (CAT_PAPELARIA, "H"): 120,
    (CAT_ASSESSORIA, "P"): 3500,
    (CAT_ASSESSORIA, "H"): 220,
    (CAT_ASSESSORIA, "D"): 1800,
    (CAT_ASSESSORIA, "U"): 400,
    (CAT_CORP, "D"): 2400,
    (CAT_CORP, "P"): 89,
    (CAT_CORP, "U"): 35,
    (CAT_CORP, "H"): 210,
    (CAT_SEGURANCA, "H"): 38,
    (CAT_SEGURANCA, "D"): 420,
    (CAT_SEGURANCA, "P"): 980,
    (CAT_SEGURANCA, "U"): 55,
}


def _eventos(*itens):
    return {
        "ids": [i[0] for i in itens],
        "slugs": [i[1] for i in itens],
        "nomes": [i[2] for i in itens],
    }


FORNECEDORES = [
    {
        "id": "esp555888",
        "nome": "Espaço Viva Eventos",
        "email": "vivaeventos@gmail.com",
        "telefone": "(41) 98433-9876",
        "cnpj": "17.345.224/0001-90",
        "descricao": "Locação de salões e espaços para casamentos, aniversários e eventos corporativos.",
        "categorias": [CAT_ESPACO],
        "local": CURITIBA,
        "raio_km": 40,
        "fator": 1.05,
        "eventos": _eventos(EV_CASAMENTO, EV_ANIVER, EV_FORMATURA, EV_CORP),
        "logradouro": "Rua das Araucárias",
        "numero": "1200",
    },
    {
        "id": "forn_chacara_recanto",
        "nome": "Chácara Recanto das Águas",
        "email": "contato@recantodasaguas.com.br",
        "telefone": "(41) 98811-2040",
        "cnpj": "28.441.902/0001-33",
        "descricao": "Chácara com piscina, campo, salão gourmet e área verde para festas de até 250 pessoas.",
        "categorias": [CAT_ESPACO],
        "local": SJP,
        "raio_km": 55,
        "fator": 1.12,
        "eventos": _eventos(EV_CASAMENTO, EV_ANIVER, EV_INFANTIL, EV_CHA),
        "logradouro": "Estrada da Graciosa",
        "numero": "km 18",
        "subs_filtro": [
            "1761673211096",
            "1761673175394",
            "sub_espaco_casamento",
            "sub_buffet_infantil_espaco",
        ],
    },
    {
        "id": "forn_tendas_parana",
        "nome": "Tendas & Palcos Paraná",
        "email": "comercial@tendasparana.com.br",
        "telefone": "(41) 99720-4411",
        "cnpj": "32.109.776/0001-81",
        "descricao": "Locação de tendas cristal, palcos, pista de dança, geradores e climatização.",
        "categorias": [CAT_ESPACO],
        "local": CURITIBA,
        "raio_km": 80,
        "fator": 0.98,
        "eventos": _eventos(EV_CASAMENTO, EV_FORMATURA, EV_CORP, EV_ANIVER),
        "logradouro": "Avenida das Indústrias",
        "numero": "450",
        "subs_filtro": [
            "1761673195296",
            "1761673224551",
            "1761673231215",
            "sub_pista_danca",
            "1761673202507",
            "sub_climatizacao",
            "sub_banheiros_quimicos",
            "sub_freezer_chopp",
            "1761673186978",
            "1761673218130",
        ],
    },
    {
        "id": "mov555444",
        "nome": "Móveis & Estilo Locadora",
        "email": "locadora@moveisestilo.com",
        "telefone": "(41) 99211-7744",
        "cnpj": "18.900.113/0001-02",
        "descricao": "Mesas, cadeiras Tiffany, louças, lounge e mobiliário decorativo para eventos.",
        "categorias": [CAT_ESPACO, CAT_DECOR],
        "local": CURITIBA,
        "raio_km": 60,
        "fator": 1.0,
        "eventos": _eventos(EV_CASAMENTO, EV_ANIVER, EV_FORMATURA, EV_CORP),
        "logradouro": "Rua Mateus Leme",
        "numero": "890",
        "subs_filtro": [
            "1761673186978",
            "1761673218130",
            "4f8f9e9a-7f67-45ca-91f6-4ad6c2885389",
            "1761672923479",
            "1761673418508",
        ],
    },
    {
        "id": "paZJsxinFMbfesof3wIpkkRuk823",
        "nome": "Fornecedor Buffet",
        "email": "buffet@fornecedor.com",
        "telefone": "(41) 98949-4646",
        "cnpj": "12.434.555/0001-52",
        "descricao": "Buffet completo para eventos corporativos e sociais, com serviço de bar e sobremesas.",
        "categorias": [CAT_BUFFET],
        "local": MARINGA,
        "raio_km": 70,
        "fator": 1.08,
        "eventos": _eventos(EV_CASAMENTO, EV_ANIVER, EV_FORMATURA, EV_CORP),
        "logradouro": "Avenida Brasil",
        "numero": "2100",
        "preservar_identidade": True,
    },
    {
        "id": "doc226677",
        "nome": "Doces da Jú",
        "email": "contato@docesdaju.com",
        "telefone": "(41) 99945-9999",
        "cnpj": "09.443.777/0001-45",
        "descricao": "Doces finos, brigadeiros gourmet, bolos artísticos e mesa de sobremesas.",
        "categorias": [CAT_BUFFET],
        "local": CURITIBA,
        "raio_km": 35,
        "fator": 1.15,
        "eventos": _eventos(EV_CASAMENTO, EV_ANIVER, EV_INFANTIL, EV_CHA),
        "logradouro": "Rua Chile",
        "numero": "312",
        "subs_filtro": [
            "1761673021428",
            "sub_doces_brigadeiros",
            "1761673028470",
            "sub_confeitaria",
            "sub_sorvete",
        ],
    },
    {
        "id": "bar999666",
        "nome": "Bar e Drinks Tropical",
        "email": "bartropical@gmail.com",
        "telefone": "(41) 98522-5566",
        "cnpj": "77.432.118/0001-77",
        "descricao": "Open bar, bartender, chopp e estações de drinks para festas e casamentos.",
        "categorias": [CAT_BUFFET],
        "local": CURITIBA,
        "raio_km": 50,
        "fator": 1.1,
        "eventos": _eventos(EV_CASAMENTO, EV_ANIVER, EV_FORMATURA, EV_CORP),
        "logradouro": "Rua XV de Novembro",
        "numero": "745",
        "subs_filtro": [
            "1761673040023",
            "sub_bar_open",
            "1761673081975",
            "sub_coffee_break",
            "sub_sorvete",
        ],
    },
    {
        "id": "forn_buffet_sabor",
        "nome": "Buffet Sabor & Festa",
        "email": "contato@saborefesta.com.br",
        "telefone": "(43) 99120-3344",
        "cnpj": "41.220.198/0001-06",
        "descricao": "Buffet de casamento, churrasco, food truck e coffee break para todo o Norte do Paraná.",
        "categorias": [CAT_BUFFET],
        "local": LONDRINA,
        "raio_km": 90,
        "fator": 0.94,
        "eventos": _eventos(EV_CASAMENTO, EV_ANIVER, EV_FORMATURA, EV_CORP, EV_INFANTIL),
        "logradouro": "Rua Sergipe",
        "numero": "1550",
    },
    {
        "id": "dec123456",
        "nome": "Decora Festas Curitiba",
        "email": "decorafestas@gmail.com",
        "telefone": "(41) 99888-1212",
        "cnpj": "45.982.113/0001-88",
        "descricao": "Decoração temática, painéis, balões e ambientação para festas e casamentos.",
        "categorias": [CAT_DECOR],
        "local": CURITIBA,
        "raio_km": 45,
        "fator": 1.02,
        "eventos": _eventos(EV_CASAMENTO, EV_ANIVER, EV_INFANTIL, EV_CHA, EV_FORMATURA),
        "logradouro": "Rua Comendador Araújo",
        "numero": "528",
    },
    {
        "id": "flo777111",
        "nome": "Floricultura BellaFlor",
        "email": "bellaflor@gmail.com",
        "telefone": "(41) 98812-2323",
        "cnpj": "88.112.544/0001-21",
        "descricao": "Buquês, arranjos de mesa, arco floral e flores para cerimônia.",
        "categorias": [CAT_DECOR],
        "local": CURITIBA,
        "raio_km": 40,
        "fator": 1.18,
        "eventos": _eventos(EV_CASAMENTO, EV_CHA, EV_ANIVER, EV_FORMATURA),
        "logradouro": "Rua das Flores",
        "numero": "90",
        "subs_filtro": [
            "3bc4092c-435f-4bc6-be39-de0e94ef8e50",
            "1761673407907",
            "sub_iluminacao_decorativa",
        ],
    },
    {
        "id": "forn_noivas_atelier",
        "nome": "Ateliê Noivas & Trajes",
        "email": "atelier@noivasetrajes.com.br",
        "telefone": "(41) 99601-7788",
        "cnpj": "53.771.004/0001-19",
        "descricao": "Aluguel e venda de vestido de noiva, 15 anos, ternos, pajens e daminhas.",
        "categorias": [CAT_MODA],
        "local": CURITIBA,
        "raio_km": 30,
        "fator": 1.2,
        "eventos": _eventos(EV_CASAMENTO, EV_FORMATURA, EV_ANIVER),
        "logradouro": "Rua 24 Horas",
        "numero": "18",
    },
    {
        "id": "sal999222",
        "nome": "Salão Glamour",
        "email": "salaoglamour@gmail.com",
        "telefone": "(41) 98444-7771",
        "cnpj": "11.223.987/0001-12",
        "descricao": "Penteados, maquiagem de noiva, barbearia e pacote dia da noiva.",
        "categorias": [CAT_BELEZA],
        "local": CURITIBA,
        "raio_km": 25,
        "fator": 1.07,
        "eventos": _eventos(EV_CASAMENTO, EV_ANIVER, EV_FORMATURA, EV_CHA),
        "logradouro": "Rua Visconde de Nácar",
        "numero": "1410",
    },
    {
        "id": "est000888",
        "nome": "Beleza & Estética",
        "email": "belezaestetica@gmail.com",
        "telefone": "(41) 98212-3434",
        "cnpj": "10.334.889/0001-62",
        "descricao": "Maquiagem social, unhas, sobrancelha e estética pré-evento.",
        "categorias": [CAT_BELEZA],
        "local": PONTA_GROSSA,
        "raio_km": 50,
        "fator": 0.92,
        "eventos": _eventos(EV_CASAMENTO, EV_ANIVER, EV_FORMATURA),
        "logradouro": "Rua Balduíno Taques",
        "numero": "670",
    },
    {
        "id": "cli995512",
        "nome": "Click Perfeito",
        "email": "clickperfeito@gmail.com",
        "telefone": "(41) 97542-3321",
        "cnpj": "22.541.883/0001-33",
        "descricao": "Fotografia, filmagem, drone, cabine de fotos e ensaio pré-evento.",
        "categorias": [CAT_FOTO],
        "local": CURITIBA,
        "raio_km": 70,
        "fator": 1.14,
        "eventos": _eventos(EV_CASAMENTO, EV_ANIVER, EV_INFANTIL, EV_FORMATURA, EV_CHA),
        "logradouro": "Rua Augusto Stresser",
        "numero": "344",
    },
    {
        "id": "som442177",
        "nome": "Som e Luz MegaMix",
        "email": "megamix@someluz.com.br",
        "telefone": "(41) 98888-4322",
        "cnpj": "33.667.229/0001-14",
        "descricao": "DJ, som, iluminação cênica, painel de LED e efeitos especiais.",
        "categorias": [CAT_MUSICA, CAT_CORP],
        "local": CURITIBA,
        "raio_km": 80,
        "fator": 1.0,
        "eventos": _eventos(EV_CASAMENTO, EV_ANIVER, EV_FORMATURA, EV_CORP),
        "logradouro": "Rua Presidente Faria",
        "numero": "102",
    },
    {
        "id": "ban222333",
        "nome": "Banda Som do Momento",
        "email": "somdomomento@gmail.com",
        "telefone": "(41) 98766-8822",
        "cnpj": "66.889.554/0001-09",
        "descricao": "Banda ao vivo, voz e violão, músicos para cerimônia e animação de pista.",
        "categorias": [CAT_MUSICA],
        "local": MARINGA,
        "raio_km": 85,
        "fator": 1.06,
        "eventos": _eventos(EV_CASAMENTO, EV_ANIVER, EV_FORMATURA),
        "logradouro": "Avenida Colombo",
        "numero": "5790",
        "subs_filtro": [
            "1761673760258",
            "sub_voz_violao",
            "sub_animacao_pista",
            "sub_karaoke",
        ],
    },
    {
        "id": "forn_kids_fun",
        "nome": "Kids Fun Recreação",
        "email": "contato@kidsfunrecreacao.com.br",
        "telefone": "(41) 99970-1122",
        "cnpj": "14.880.331/0001-57",
        "descricao": "Recreação infantil, personagens, infláveis, mágico e oficinas para festa kids.",
        "categorias": [CAT_RECREACAO],
        "local": CURITIBA,
        "raio_km": 40,
        "fator": 1.0,
        "eventos": _eventos(EV_INFANTIL, EV_ANIVER, EV_CHA),
        "logradouro": "Rua Itupava",
        "numero": "1408",
    },
    {
        "id": "forn_transluxe",
        "nome": "Transluxe Carros e Vans",
        "email": "reservas@transluxe.com.br",
        "telefone": "(41) 99155-9090",
        "cnpj": "36.554.210/0001-40",
        "descricao": "Carro da noiva, carros de luxo, vans, limousine e transfer de convidados.",
        "categorias": [CAT_TRANSPORTE],
        "local": SJP,
        "raio_km": 90,
        "fator": 1.16,
        "eventos": _eventos(EV_CASAMENTO, EV_FORMATURA, EV_CORP, EV_ANIVER),
        "logradouro": "Avenida Rui Barbosa",
        "numero": "2500",
    },
    {
        "id": "mim983344",
        "nome": "Mimos & Arte",
        "email": "mimosarte@hotmail.com",
        "telefone": "(41) 99932-8787",
        "cnpj": "19.203.871/0001-98",
        "descricao": "Convites, lembrancinhas, tags, identidade visual e kits para padrinhos.",
        "categorias": [CAT_PAPELARIA],
        "local": CURITIBA,
        "raio_km": 35,
        "fator": 0.96,
        "eventos": _eventos(EV_CASAMENTO, EV_ANIVER, EV_INFANTIL, EV_CHA, EV_FORMATURA),
        "logradouro": "Rua São Francisco",
        "numero": "77",
    },
    {
        "id": "cer111333",
        "nome": "Cerimonial Premium",
        "email": "contato@cerimonialpremium.com",
        "telefone": "(41) 99123-5566",
        "cnpj": "55.741.310/0001-44",
        "descricao": "Cerimonial, wedding planner, produção e coordenação do dia do evento.",
        "categorias": [CAT_ASSESSORIA],
        "local": CURITIBA,
        "raio_km": 60,
        "fator": 1.22,
        "eventos": _eventos(EV_CASAMENTO, EV_FORMATURA, EV_ANIVER, EV_CORP),
        "logradouro": "Alameda Dr. Carlos de Carvalho",
        "numero": "555",
    },
    {
        "id": "forn_led_stage",
        "nome": "LED Stage Eventos Corporativos",
        "email": "comercial@ledstage.com.br",
        "telefone": "(43) 98840-2200",
        "cnpj": "48.102.665/0001-72",
        "descricao": "Palco, painel de LED, audiovisual, credenciamento e coffee break corporativo.",
        "categorias": [CAT_CORP],
        "local": LONDRINA,
        "raio_km": 100,
        "fator": 1.04,
        "eventos": _eventos(EV_CORP, EV_FORMATURA),
        "logradouro": "Avenida Ayrton Senna",
        "numero": "300",
    },
    {
        "id": "forn_apoio_total",
        "nome": "Apoio Total Eventos",
        "email": "operacao@apoioeventos.com.br",
        "telefone": "(41) 98701-3344",
        "cnpj": "21.667.908/0001-11",
        "descricao": "Segurança, garçons, valet, recepcionistas, brigada e limpeza pré e pós-festa.",
        "categorias": [CAT_SEGURANCA],
        "local": CURITIBA,
        "raio_km": 70,
        "fator": 0.97,
        "eventos": _eventos(EV_CASAMENTO, EV_FORMATURA, EV_CORP, EV_ANIVER),
        "logradouro": "Rua Marechal Deodoro",
        "numero": "2330",
    },
]

BANNERS = {
    "esp555888": img("photo-1414235077428-338989a2e8c0"),
    "forn_chacara_recanto": img("photo-1464207687429-7505649dae38"),
    "forn_tendas_parana": img("photo-1533174072545-7a4b6ad7a6c3"),
    "mov555444": img("photo-1414235077428-338989a2e8c0"),
    "paZJsxinFMbfesof3wIpkkRuk823": img("photo-1555244162-803834f70033"),
    "doc226677": img("photo-1478144592103-25e218a04891"),
    "bar999666": img("photo-1514933651103-005eec06c04b"),
    "forn_buffet_sabor": img("photo-1414235077428-338989a2e8c0"),
    "dec123456": img("photo-1478144592103-25e218a04891"),
    "flo777111": img("photo-1465495976277-4387d4b0b4c6"),
    "forn_noivas_atelier": img("photo-1594552072238-b8a33785b261"),
    "sal999222": img("photo-1560066984-138dadb4c035"),
    "est000888": img("photo-1487412947147-5cebf100ffc2"),
    "cli995512": img("photo-1516035069371-29a1b244cc32"),
    "som442177": img("photo-1506157786151-b8491531f063"),
    "ban222333": img("photo-1511671782779-c97d3d27a1d4"),
    "forn_kids_fun": img("photo-1527526029430-319f10814151"),
    "forn_transluxe": img("photo-1492144534655-ae79c964c9d7"),
    "mim983344": img("photo-1511795409834-ef04bbd61622"),
    "cer111333": img("photo-1519741497674-611481863552"),
    "forn_led_stage": img("photo-1540575467063-178a50c2df87"),
    "forn_apoio_total": img("photo-1511578314322-379afb476865"),
}


def _hash_int(texto: str, modulo: int) -> int:
    digest = hashlib.md5(texto.encode("utf-8")).hexdigest()
    return int(digest[:8], 16) % modulo


def preco_produto(produto: dict, id_categoria: str, fator: float) -> tuple[float, float | None]:
    nome = (produto.get("nome") or "").lower()
    medida = produto.get("tipo_medida") or "U"
    base = BASE_PRECO.get((id_categoria, medida), 200)

    if "cento" in nome:
        base = 95
    elif "chácara" in nome or "chacara" in nome:
        base = 3800
    elif "salão para até 200" in nome or "salao para ate 200" in nome:
        base = 4200
    elif "salão para até 100" in nome:
        base = 2500
    elif "open bar" in nome:
        base = 99
    elif "buffet completo" in nome or "buffet de casamento" in nome:
        base = 149
    elif "dj 4 horas" in nome:
        base = 1800
    elif nome.startswith("dj "):
        base = 350
    elif "cobertura fotográfica" in nome or "cobertura fotografica" in nome:
        base = 3200
    elif "filme do evento" in nome:
        base = 2900
    elif "vestido de noiva" in nome:
        base = 2200
    elif "wedding planner" in nome:
        base = 6500
    elif "cerimonial completo" in nome:
        base = 2800
    elif "painel de led" in nome:
        base = 3200
    elif "limousine" in nome:
        base = 1400
    elif "party bus" in nome or "ônibus de festa" in nome:
        base = 2100
    elif "carrinho" in nome:
        base = 650
    elif "pula-pula" in nome or "tobogã" in nome or "toboga" in nome:
        base = 420

    preco = round(base * fator, 2)
    promocao = None
    if _hash_int(produto.get("id", "") + str(fator), 10) >= 7:
        promocao = round(preco * 0.9, 2)
    return preco, promocao


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
            self.batch.commit()
            self.batch = self.db.batch()
            self.ops = 0

    def commit(self):
        if self.ops:
            self.batch.commit()
            self.ops = 0


def carregar_catalogo(db):
    cats = {d.id: {"id": d.id, **d.to_dict()} for d in db.collection("categoria_servico").stream()}
    subs = {d.id: {"id": d.id, **d.to_dict()} for d in db.collection("subcategoria_servico").stream()}
    prods = []
    for d in db.collection("servico_produto").stream():
        data = d.to_dict() or {}
        data["id"] = data.get("id") or d.id
        prods.append(data)
    return cats, subs, prods


def produtos_do_fornecedor(fornecedor, cats, subs, prods):
    filtro = set(fornecedor.get("subs_filtro") or [])
    escolhidos = []
    por_sub: dict[str, int] = {}
    for prod in sorted(prods, key=lambda p: p.get("nome") or ""):
        id_sub = prod.get("id_subcategoria") or ""
        sub = subs.get(id_sub)
        if not sub:
            continue
        id_cat = sub.get("id_categoria")
        if id_cat not in fornecedor["categorias"]:
            continue
        if filtro and id_sub not in filtro:
            continue
        if por_sub.get(id_sub, 0) >= 2:
            continue
        por_sub[id_sub] = por_sub.get(id_sub, 0) + 1
        escolhidos.append((prod, id_cat, id_sub, sub.get("nome") or ""))
        if len(escolhidos) >= 16:
            break
    return escolhidos


def montar_categorias(fornecedor, escolhidos, cats, subs):
    agrupado: dict[str, list[dict]] = {}
    for _prod, id_cat, id_sub, nome_sub in escolhidos:
        agrupado.setdefault(id_cat, [])
        if not any(s["idSubcategoria"] == id_sub for s in agrupado[id_cat]):
            agrupado[id_cat].append({"idSubcategoria": id_sub, "nomeSubcategoria": nome_sub})
    resultado = []
    for id_cat in fornecedor["categorias"]:
        resultado.append(
            {
                "idCategoria": id_cat,
                "nomeCategoria": (cats.get(id_cat) or {}).get("nome") or "",
                "subcategorias": agrupado.get(id_cat, []),
            }
        )
    return resultado


def parece_auth(id_fornecedor: str) -> bool:
    return bool(re.fullmatch(r"[A-Za-z0-9]{20,}", id_fornecedor)) and not id_fornecedor.startswith("forn_")


def gravar_fornecedor(db, lote: Lote, fornecedor, cats, subs, prods, existentes_forn: set[str]):
    fid = fornecedor["id"]
    local = fornecedor["local"]
    escolhidos = produtos_do_fornecedor(fornecedor, cats, subs, prods)
    if not escolhidos:
        print(f"  ! {fornecedor['nome']}: nenhum produto encontrado")
        return 0

    categorias_doc = montar_categorias(fornecedor, escolhidos, cats, subs)
    precos = [preco_produto(p, id_cat, fornecedor["fator"])[0] for p, id_cat, *_ in escolhidos]
    ev = fornecedor["eventos"]
    agora = firestore.SERVER_TIMESTAMP
    preservar = fornecedor.get("preservar_identidade") or (parece_auth(fid) and fid in existentes_forn)

    forn_payload = {
        "id_fornecedor": fid,
        "id_usuario": fid,
        "razao_social": fornecedor["nome"],
        "telefone": fornecedor["telefone"],
        "email": fornecedor["email"],
        "cnpj": fornecedor["cnpj"],
        "descricao": fornecedor["descricao"],
        "apto_para_operar": True,
        "ativo": True,
        "categorias": categorias_doc,
        "tipoEventoIds": ev["ids"],
        "tipoEventoSlugs": ev["slugs"],
        "tipoEventoNomes": ev["nomes"],
        "tipo_evento_ids": ev["ids"],
        "tipo_evento_slugs": ev["slugs"],
        "tipo_evento_nomes": ev["nomes"],
        "precoMinimo": min(precos),
        "precoMaximo": max(precos),
        "precoMedio": round(sum(precos) / len(precos), 2),
        "preco_minimo": min(precos),
        "preco_maximo": max(precos),
        "preco_medio": round(sum(precos) / len(precos), 2),
        "media_avaliacoes": round(4.3 + _hash_int(fid, 7) / 10, 1),
        "total_avaliacoes": 8 + _hash_int(fid + "av", 40),
        "totalContratacoes": 5 + _hash_int(fid + "ct", 28),
        "total_contratacoes": 5 + _hash_int(fid + "ct", 28),
        "tempoMedioRespostaHoras": 1 + _hash_int(fid + "t", 6),
        "tempo_medio_resposta_horas": 1 + _hash_int(fid + "t", 6),
        "is_top_categoria": _hash_int(fid, 4) == 0,
        "data_atualizacao": agora,
    }
    banner = (fornecedor.get("banner") or BANNERS.get(fid) or "").strip()
    if banner:
        forn_payload["banner_url"] = banner
        forn_payload["bannerUrl"] = banner
    if fid not in existentes_forn:
        forn_payload["data_cadastro"] = agora
    if preservar:
        for chave in ("razao_social", "telefone", "email", "cnpj", "descricao"):
            forn_payload.pop(chave, None)

    lote.set(db.collection("fornecedor").document(fid), forn_payload)

    usuario = {
        "id_usuario": fid,
        "nome": fornecedor["nome"],
        "email": fornecedor["email"],
        "tipo": "F",
        "ativo": True,
        "cidade": local["cidade"],
        "uf": local["uf"],
        "email_normalizado": fornecedor["email"].strip().lower(),
        "data_atualizacao": agora,
    }
    if banner:
        usuario["foto_perfil_url"] = banner
    if not preservar:
        lote.set(db.collection("usuarios").document(fid), usuario)
        endereco = {
            "id": f"end_{fid}",
            "id_usuario": fid,
            "id_cidade": local["id_cidade"],
            "nome_cidade": local["cidade"],
            "uf": local["uf"],
            "cep": local["cep"],
            "logradouro": fornecedor["logradouro"],
            "numero": fornecedor["numero"],
            "bairro": local["bairro"],
            "principal": True,
            "data_cadastro": agora,
        }
        lote.set(
            db.collection("usuarios").document(fid).collection("enderecos").document(endereco["id"]),
            endereco,
        )

    territorio = {
        "id_territorio": f"ter_{fid}",
        "id_fornecedor": fid,
        "latitude": local["lat"],
        "longitude": local["lng"],
        "raio_km": fornecedor["raio_km"],
        "descricao": f"Atende {local['cidade']} e região",
        "ativo": True,
        "tipo_cobertura": "raio",
        "regioes": [local["cidade"]],
    }
    lote.set(db.collection("territorio").document(territorio["id_territorio"]), territorio)

    for bloco in categorias_doc:
        cat_id = f"{fid}_{bloco['idCategoria']}"
        lote.set(
            db.collection("fornecedor_categoria").document(cat_id),
            {
                "id_fornecedor": fid,
                "id_categoria": bloco["idCategoria"],
                "nome_categoria": bloco["nomeCategoria"],
                "subcategorias": bloco["subcategorias"],
                "data_cadastro": agora,
            },
        )

    for prod, id_cat, id_sub, _nome_sub in escolhidos:
        preco, promo = preco_produto(prod, id_cat, fornecedor["fator"])
        vinculo_id = f"{fid}_{prod['id']}"
        lote.set(
            db.collection("fornecedor_servico").document(vinculo_id),
            {
                "id_fornecedor_servico": vinculo_id,
                "id_produto_servico": prod["id"],
                "id_fornecedor": fid,
                "id_subcategoria": id_sub,
                "preco": preco,
                "preco_promocao": promo,
                "ativo": True,
                "data_cadastro": agora,
                "data_atualizacao": agora,
            },
        )
    return len(escolhidos)


def gravar_banners(db) -> int:
    lote = db.batch()
    atualizados = 0
    for forn in FORNECEDORES:
        fid = forn["id"]
        url = (forn.get("banner") or BANNERS.get(fid) or "").strip()
        if not url:
            continue
        lote.set(
            db.collection("fornecedor").document(fid),
            {"banner_url": url, "bannerUrl": url},
            merge=True,
        )
        if not forn.get("preservar_identidade"):
            lote.set(
                db.collection("usuarios").document(fid),
                {"foto_perfil_url": url},
                merge=True,
            )
        atualizados += 1
        print(f"  - {forn['nome']}")
    lote.commit()
    return atualizados


def main() -> None:
    os.chdir(Path(__file__).resolve().parent)
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(str(CREDENCIAIS)))
    db = firestore.client()

    if "--banners" in sys.argv:
        n = gravar_banners(db)
        print(f"Banners gravados em {n} fornecedores")
        return

    cats, subs, prods = carregar_catalogo(db)
    print(f"Catálogo: {len(cats)} categorias, {len(subs)} subcategorias, {len(prods)} produtos")

    existentes = {d.id for d in db.collection("fornecedor").stream()}
    lote = Lote(db)
    total_vinculos = 0
    for forn in FORNECEDORES:
        n = gravar_fornecedor(db, lote, forn, cats, subs, prods, existentes)
        total_vinculos += n
        print(f"  - {forn['nome']}: {n} produtos")
    lote.commit()

    n_forn = len(list(db.collection("fornecedor").stream()))
    n_vinc = len(list(db.collection("fornecedor_servico").stream()))
    n_cat = len(list(db.collection("fornecedor_categoria").stream()))
    print("Gravado com merge no projeto faca-a-festa.")
    print(f"Fornecedores no seed: {len(FORNECEDORES)} ({total_vinculos} vínculos novos/atualizados)")
    print(f"Firestore agora: {n_forn} fornecedores, {n_cat} categorias vinculadas, {n_vinc} serviços vinculados")


if __name__ == "__main__":
    main()
