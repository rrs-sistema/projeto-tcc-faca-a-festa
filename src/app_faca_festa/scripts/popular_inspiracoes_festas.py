"""Grava inspirações públicas com base no catálogo já existente.

Usa tipos de evento, categorias de serviço, temas de festa e fornecedores
já cadastrados. Merge na coleção `inspiracoes` com IDs estáveis `insp_*`.
Documentos extras já existentes não são apagados.

publicado=true e ativo=true para aparecer na tela do usuário.
"""

from __future__ import annotations

import os
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

NOME_CAT = {
    CAT_ESPACO: "Espaço e Estrutura",
    CAT_BUFFET: "Buffet e Gastronomia",
    CAT_DECOR: "Decoração",
    CAT_MODA: "Moda, Vestidos e Trajes",
    CAT_BELEZA: "Beleza e Estética",
    CAT_FOTO: "Fotografia e Filmagem",
    CAT_MUSICA: "Música e Iluminação",
    CAT_RECREACAO: "Recreação e Entretenimento",
    CAT_TRANSPORTE: "Transporte",
    CAT_PAPELARIA: "Papelaria e Lembranças",
    CAT_ASSESSORIA: "Assessoria e Produção de Eventos",
    CAT_CORP: "Formaturas e Eventos Corporativos",
    CAT_SEGURANCA: "Segurança e Apoio",
}

EV_CASAMENTO = ("302191a2-dbf3-4ac6-ba53-08273b384cab", "casamento", "Casamento")
EV_ANIVER = ("7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda", "aniversario", "Aniversário")
EV_INFANTIL = ("ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8", "festa_infantil", "Festa Infantil")
EV_FORMATURA = ("WlLdfdmu4Chvw2p8daUm", "formatura", "Formatura")
EV_CORP = ("lXf0M5vMNvyRn52yQ2fY", "evento_corporativo", "Evento Corporativo")
EV_CHA = ("1eab2c53-a7d3-4a97-b473-02572464e779", "cha_de_bebe", "Chá de Bebê")


def img(photo_id: str, w: int = 1400) -> str:
    return f"https://images.unsplash.com/{photo_id}?auto=format&fit=crop&w={w}&q=80"


def tipos(*eventos: tuple[str, str, str]) -> dict:
    ids = [e[0] for e in eventos]
    nomes = [e[2] for e in eventos]
    slugs: list[str] = []
    for _id, slug, _nome in eventos:
        underscore = slug.replace("-", "_")
        hyphen = slug.replace("_", "-")
        for extra in (slug, underscore, hyphen):
            if extra not in slugs:
                slugs.append(extra)
    primario = eventos[0]
    return {
        "tipoEventoId": primario[0],
        "tipoEvento": primario[2],
        "tipoEventoNormalizado": primario[1].replace("-", "_"),
        "tipoEventoSlug": primario[1].replace("-", "_"),
        "tipoEventoNome": primario[2],
        "tipoEventoIds": ids,
        "tipoEventoSlugs": slugs,
        "tipoEventoNomes": nomes,
    }


def tarefa(
    titulo: str,
    descricao: str,
    categoria: str,
    dias: int,
    prioridade: str = "media",
    obrigatoria: bool = False,
    ordem: int = 1,
) -> dict:
    return {
        "titulo": titulo,
        "nome": titulo,
        "descricao": descricao,
        "categoria": categoria,
        "diasAntesEvento": dias,
        "prioridade": prioridade,
        "obrigatoria": obrigatoria,
        "ordem": ordem,
        "status": "pendente",
        "origem": "inspiracao_seed",
    }


def item(
    categoria: str,
    nome: str,
    custo: float,
    descricao: str = "",
    minimo: float = 0,
    maximo: float = 0,
    unidade: str = "unidade",
    quantidade: float = 1,
    por_convidado: float = 0,
    obrigatorio: bool = False,
    ordem: int = 1,
) -> dict:
    minimo = minimo or round(custo * 0.8, 2)
    maximo = maximo or round(custo * 1.25, 2)
    return {
        "categoria": categoria,
        "item": nome,
        "nome": nome,
        "descricao": descricao,
        "custoEstimado": custo,
        "valorEstimado": custo,
        "custoMinimo": minimo,
        "custoMaximo": maximo,
        "unidade": unidade,
        "quantidadeBase": quantidade,
        "custoPorConvidado": por_convidado,
        "obrigatorio": obrigatorio,
        "ordem": ordem,
        "custoReal": 0.0,
        "statusPagamento": "pendente",
        "origem": "inspiracao_seed",
    }


def insp(
    *,
    id_: str,
    titulo: str,
    descricao: str,
    imagem: str,
    galeria: list[str],
    tags: list[str],
    paleta: list[str],
    categoria: str,
    categoria_id: str,
    eventos: tuple[tuple[str, str, str], ...],
    estilo: str,
    faixa: str,
    dificuldade: str,
    fornecedores: list[str],
    cats_fornecedor: list[str],
    tarefas: list[dict],
    orcamento: list[dict],
    destaque: bool = False,
    ordem: int = 100,
) -> dict:
    payload = {
        "id": id_,
        "titulo": titulo,
        "descricao": descricao,
        "imagemUrl": imagem,
        "galeriaUrls": galeria,
        "tags": tags,
        "paletaCores": paleta,
        "categoria": categoria,
        "categoriaId": categoria_id,
        "estilo": estilo,
        "faixaCusto": faixa,
        "nivelDificuldade": dificuldade,
        "fornecedoresRelacionados": fornecedores,
        "categoriasFornecedorSugeridas": cats_fornecedor,
        "tarefasSugeridas": tarefas,
        "itensOrcamentoSugeridos": orcamento,
        "destaque": destaque,
        "ativo": True,
        "publicado": True,
        "deletado": False,
        "favorito": False,
        "ordem": ordem,
        "origem": "catalogo_festas",
    }
    payload.update(tipos(*eventos))
    return payload


CATALOGO: list[dict] = [
    insp(
        id_="insp_casamento_rustico_chacara",
        titulo="Casamento rústico na chácara",
        descricao=(
            "Cerimônia ao ar livre, mesa de madeira, flores do campo e recepção "
            "sob luzes amarelas. Combina chácara, decoração campestre e buffet informal."
        ),
        imagem=img("photo-1464207687429-7505649dae38"),
        galeria=[
            img("photo-1519741497674-611481863552"),
            img("photo-1414235077428-338989a2e8c0"),
            img("photo-1533174072545-7a4b6ad7a6c3"),
        ],
        tags=["rustico", "chacara", "casamento", "Decoração", "Espaço e Estrutura"],
        paleta=["#8D6E63", "#A1887F", "#EFEBE9", "#5D4037"],
        categoria="Rústico",
        categoria_id=CAT_ESPACO,
        eventos=(EV_CASAMENTO,),
        estilo="Rústico",
        faixa="Intermediário",
        dificuldade="Médio",
        fornecedores=["forn_chacara_recanto", "dec123456", "flo777111", "mov555444"],
        cats_fornecedor=[NOME_CAT[CAT_ESPACO], NOME_CAT[CAT_DECOR]],
        tarefas=[
            tarefa("Reservar a chácara", "Confirmar data, capacidade e o que está incluso na diária.", NOME_CAT[CAT_ESPACO], 180, "alta", True, 1),
            tarefa("Fechar decoração campestre", "Painel de madeira, arranjos do campo e iluminação fria/quente.", NOME_CAT[CAT_DECOR], 120, "alta", True, 2),
            tarefa("Definir buffet e open bar", "Menu rústico, churrasco ou finger food para o número de convidados.", NOME_CAT[CAT_BUFFET], 90, "alta", True, 3),
            tarefa("Contratar foto e filme", "Cobertura da cerimônia no jardim e da festa à noite.", NOME_CAT[CAT_FOTO], 90, "media", True, 4),
            tarefa("Montar checklist do dia", "Horários de cerimonial, troca de roupa e corte do bolo.", NOME_CAT[CAT_ASSESSORIA], 30, "media", False, 5),
        ],
        orcamento=[
            item(NOME_CAT[CAT_ESPACO], "Diária de chácara com jardim", 3800, "Espaço com área gourmet e cerimônia ao ar livre.", obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_DECOR], "Decoração rústica completa", 4200, "Painel, mesas, arranjos e luzes.", ordem=2),
            item(NOME_CAT[CAT_BUFFET], "Buffet por convidado", 149, "Prato principal + entradas.", unidade="convidado", por_convidado=149, quantidade=80, ordem=3),
            item(NOME_CAT[CAT_FOTO], "Cobertura fotográfica", 3200, "Ensaio, cerimônia e festa.", obrigatorio=True, ordem=4),
            item(NOME_CAT[CAT_MUSICA], "DJ 4 horas", 1800, "Som para cerimônia e pista.", ordem=5),
        ],
        destaque=True,
        ordem=10,
    ),
    insp(
        id_="insp_casamento_classico_floral",
        titulo="Casamento clássico com flores",
        descricao=(
            "Paleta off-white e dourado, arco floral, mesas longas e cerimonial tradicional. "
            "Ideal para salão ou igreja com recepção elegante."
        ),
        imagem=img("photo-1519741497674-611481863552"),
        galeria=[
            img("photo-1465495976277-4387d4b0b4c6"),
            img("photo-1465495976277-4387d4b0b4c6"),
            img("photo-1519741497674-611481863552"),
        ],
        tags=["classico", "floral", "casamento", "Decoração", "flores"],
        paleta=["#FAFAFA", "#C9A227", "#B71C1C", "#3E2723"],
        categoria="Clássico",
        categoria_id=CAT_DECOR,
        eventos=(EV_CASAMENTO,),
        estilo="Clássico",
        faixa="Premium",
        dificuldade="Elaborado",
        fornecedores=["flo777111", "dec123456", "cer111333", "cli995512"],
        cats_fornecedor=[NOME_CAT[CAT_DECOR], NOME_CAT[CAT_ASSESSORIA], NOME_CAT[CAT_FOTO]],
        tarefas=[
            tarefa("Escolher o tema floral", "Definir flores da estação, buquê e arco da cerimônia.", NOME_CAT[CAT_DECOR], 150, "alta", True, 1),
            tarefa("Contratar cerimonial", "Wedding planner para cronograma e fornecedores.", NOME_CAT[CAT_ASSESSORIA], 150, "alta", True, 2),
            tarefa("Prova de vestido e terno", "Ateliê, ajustes e sapatos com 90 dias de antecedência.", NOME_CAT[CAT_MODA], 90, "alta", True, 3),
            tarefa("Ensaio fotográfico", "Pré-wedding e briefing da cobertura do dia.", NOME_CAT[CAT_FOTO], 60, "media", True, 4),
            tarefa("Confirmar cardápio e bolo", "Degustação do buffet e desenho do bolo clássico.", NOME_CAT[CAT_BUFFET], 45, "media", True, 5),
        ],
        orcamento=[
            item(NOME_CAT[CAT_DECOR], "Arco e arranjos florais", 5800, "Cerimônia + mesas da recepção.", obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_ASSESSORIA], "Wedding planner", 6500, "Produção completa até o dia.", obrigatorio=True, ordem=2),
            item(NOME_CAT[CAT_MODA], "Aluguel de vestido de noiva", 2200, "Vestido + véu + prova.", ordem=3),
            item(NOME_CAT[CAT_FOTO], "Foto e filme do evento", 6100, "Cobertura fotográfica + filme.", ordem=4),
            item(NOME_CAT[CAT_BUFFET], "Buffet de casamento", 149, unidade="convidado", por_convidado=149, quantidade=120, ordem=5),
            item(NOME_CAT[CAT_BELEZA], "Dia da noiva", 890, "Cabelo, maquiagem e prova.", ordem=6),
        ],
        destaque=True,
        ordem=20,
    ),
    insp(
        id_="insp_casamento_tropical_chique",
        titulo="Tropical chique para casar",
        descricao=(
            "Folhagens, dourado e clima de resort. Costela-de-adão, frutas na decoração "
            "e iluminação quente para uma festa sofisticada sem ser rígida."
        ),
        imagem=img("photo-1501004318641-b39e6451bec6"),
        galeria=[
            img("photo-1507525428034-b723cf961d3e"),
            img("photo-1478144592103-25e218a04891"),
            img("photo-1519741497674-611481863552"),
        ],
        tags=["tropical", "chique", "folhagem", "casamento", "aniversario"],
        paleta=["#2E7D32", "#F9A825", "#FFFDE7", "#1B5E20"],
        categoria="Tropical chique",
        categoria_id=CAT_DECOR,
        eventos=(EV_CASAMENTO, EV_ANIVER, EV_FORMATURA),
        estilo="Tropical",
        faixa="Intermediário",
        dificuldade="Médio",
        fornecedores=["dec123456", "flo777111", "esp555888", "bar999666"],
        cats_fornecedor=[NOME_CAT[CAT_DECOR], NOME_CAT[CAT_ESPACO], NOME_CAT[CAT_BUFFET]],
        tarefas=[
            tarefa("Fechar o espaço com jardim", "Salão com área externa ou varanda para fotos.", NOME_CAT[CAT_ESPACO], 150, "alta", True, 1),
            tarefa("Decoração com folhagens", "Painel tropical, arranjos altos e toque dourado.", NOME_CAT[CAT_DECOR], 90, "alta", True, 2),
            tarefa("Bar de drinks autorais", "Carta tropical e bartender para a recepção.", NOME_CAT[CAT_BUFFET], 60, "media", False, 3),
            tarefa("Trilha e iluminação quente", "Playlist lounge + LED âmbar na pista.", NOME_CAT[CAT_MUSICA], 45, "media", False, 4),
        ],
        orcamento=[
            item(NOME_CAT[CAT_ESPACO], "Salão para até 200 convidados", 4200, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_DECOR], "Decoração tropical chique", 4800, "Folhagens, dourado e painel.", ordem=2),
            item(NOME_CAT[CAT_BUFFET], "Open bar tropical", 99, unidade="convidado", por_convidado=99, quantidade=100, ordem=3),
            item(NOME_CAT[CAT_MUSICA], "DJ 4 horas", 1800, ordem=4),
        ],
        destaque=True,
        ordem=30,
    ),
    insp(
        id_="insp_baile_mascaras",
        titulo="Baile de máscaras elegante",
        descricao=(
            "Veludo, dourado e mistério. Máscaras na entrada, iluminação cênica e "
            "dress code de gala. Funciona em casamento temático ou formatura."
        ),
        imagem=img("photo-1514525253161-7a46d19cd819"),
        galeria=[
            img("photo-1470225620780-dba8ba36b745"),
            img("photo-1506157786151-b8491531f063"),
            img("photo-1414235077428-338989a2e8c0"),
        ],
        tags=["mascaras", "baile", "gala", "casamento", "formatura"],
        paleta=["#4A148C", "#C9A227", "#1A1A2E", "#F5F5F5"],
        categoria="Baile de máscaras",
        categoria_id=CAT_MUSICA,
        eventos=(EV_CASAMENTO, EV_FORMATURA, EV_ANIVER),
        estilo="Criativo",
        faixa="Premium",
        dificuldade="Elaborado",
        fornecedores=["forn_noivas_atelier", "som442177", "forn_led_stage", "dec123456"],
        cats_fornecedor=[NOME_CAT[CAT_MODA], NOME_CAT[CAT_MUSICA], NOME_CAT[CAT_DECOR]],
        tarefas=[
            tarefa("Definir o dress code", "Convite com máscara e orientação de traje a rigor.", NOME_CAT[CAT_PAPELARIA], 90, "alta", True, 1),
            tarefa("Aluguel de trajes e máscaras", "Ternos, vestidos longos e kit de máscaras.", NOME_CAT[CAT_MODA], 60, "alta", True, 2),
            tarefa("Iluminação cênica e LED", "Canhões, gobos e painel para a pista.", NOME_CAT[CAT_MUSICA], 45, "alta", True, 3),
            tarefa("Recepção com ficha de máscara", "Welcome drink e foto na entrada temática.", NOME_CAT[CAT_DECOR], 30, "media", False, 4),
        ],
        orcamento=[
            item(NOME_CAT[CAT_DECOR], "Ambientação de baile", 3900, "Cortinas, velas e máscaras.", ordem=1),
            item(NOME_CAT[CAT_MUSICA], "Banda ou DJ + iluminação", 4500, "Pista com efeito cênico.", obrigatorio=True, ordem=2),
            item(NOME_CAT[CAT_MODA], "Aluguel de trajes de gala", 1800, "Noivos ou formandos + padrinhos.", ordem=3),
            item("Música e Iluminação", "Painel de LED", 3200, ordem=4),
        ],
        ordem=40,
    ),
    insp(
        id_="insp_casamento_trajes_atelier",
        titulo="Look da noiva, noivo e cortejo",
        descricao=(
            "Referência de vestido, terno, pajens e daminhas. Use para alinhar provas, "
            "aluguel e o carro da noiva com o ateliê e o salão de beleza."
        ),
        imagem=img("photo-1594552072238-b8a33785b261"),
        galeria=[
            img("photo-1515934751635-c81c6bc9a2d8"),
            img("photo-1606216794074-735e91aa2c92"),
            img("photo-1606216794074-735e91aa2c92"),
        ],
        tags=["vestido", "terno", "noiva", "Moda, Vestidos e Trajes"],
        paleta=["#FAFAFA", "#F8BBD0", "#C9A227", "#3E2723"],
        categoria="Moda e trajes",
        categoria_id=CAT_MODA,
        eventos=(EV_CASAMENTO, EV_FORMATURA, EV_ANIVER),
        estilo="Clássico",
        faixa="Intermediário",
        dificuldade="Médio",
        fornecedores=["forn_noivas_atelier", "sal999222", "forn_transluxe"],
        cats_fornecedor=[NOME_CAT[CAT_MODA], NOME_CAT[CAT_BELEZA], NOME_CAT[CAT_TRANSPORTE]],
        tarefas=[
            tarefa("Agendar prova de vestido", "Levar referências e definir modelo com 4 meses.", NOME_CAT[CAT_MODA], 120, "alta", True, 1),
            tarefa("Aluguel dos ternos", "Noivo, padrinhos e pajens no mesmo tom.", NOME_CAT[CAT_MODA], 60, "alta", True, 2),
            tarefa("Dia da noiva", "Teste de penteado e maquiagem 30 dias antes.", NOME_CAT[CAT_BELEZA], 30, "alta", True, 3),
            tarefa("Reservar o carro", "Chegada clássica ou vintage até o local.", NOME_CAT[CAT_TRANSPORTE], 20, "media", False, 4),
        ],
        orcamento=[
            item(NOME_CAT[CAT_MODA], "Aluguel de vestido de noiva", 2200, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_MODA], "Aluguel de ternos", 980, "Noivo + 4 padrinhos.", ordem=2),
            item(NOME_CAT[CAT_BELEZA], "Pacote dia da noiva", 890, obrigatorio=True, ordem=3),
            item(NOME_CAT[CAT_TRANSPORTE], "Carro da noiva", 1400, "Ida e volta no horário da cerimônia.", ordem=4),
        ],
        ordem=50,
    ),
    insp(
        id_="insp_vintage_retro",
        titulo="Festa com estética vintage",
        descricao=(
            "Sépia, louças antigas, jazz ou MPB e móveis de época. Combina casamento "
            "intimista, aniversário adulto e formatura retrô."
        ),
        imagem=img("photo-1464047736614-af63643285bf"),
        galeria=[
            img("photo-1414235077428-338989a2e8c0"),
            img("photo-1514933651103-005eec06c04b"),
            img("photo-1535254973040-607b474cb50d"),
        ],
        tags=["vintage", "retro", "classico", "casamento", "aniversario"],
        paleta=["#6D4C41", "#D7CCC8", "#EFEBE9", "#3E2723"],
        categoria="Vintage",
        categoria_id=CAT_DECOR,
        eventos=(EV_CASAMENTO, EV_ANIVER, EV_FORMATURA),
        estilo="Vintage",
        faixa="Intermediário",
        dificuldade="Médio",
        fornecedores=["dec123456", "mov555444", "ban222333", "mim983344"],
        cats_fornecedor=[NOME_CAT[CAT_DECOR], NOME_CAT[CAT_ESPACO], NOME_CAT[CAT_MUSICA]],
        tarefas=[
            tarefa("Locar móveis de época", "Mesas, cadeiras e louças com cara de antiquário.", NOME_CAT[CAT_ESPACO], 90, "alta", True, 1),
            tarefa("Identidade visual retrô", "Convite, menu e placas em serifada clássica.", NOME_CAT[CAT_PAPELARIA], 75, "media", False, 2),
            tarefa("Música ao vivo intimista", "Voz e violão ou jazz no coquetel.", NOME_CAT[CAT_MUSICA], 45, "media", True, 3),
            tarefa("Bolo e doces clássicos", "Naked cake, macarons e mesa de chá.", NOME_CAT[CAT_BUFFET], 30, "media", False, 4),
        ],
        orcamento=[
            item(NOME_CAT[CAT_DECOR], "Decoração vintage", 3600, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_ESPACO], "Locação de móveis e louças", 1800, ordem=2),
            item(NOME_CAT[CAT_MUSICA], "Voz e violão 3 horas", 1600, ordem=3),
            item(NOME_CAT[CAT_PAPELARIA], "Convites e papelaria", 890, ordem=4),
        ],
        ordem=60,
    ),
    insp(
        id_="insp_infantil_safari",
        titulo="Festa infantil Safári",
        descricao=(
            "Selva, animais e paleta terra/verde. Painel de folhagens, recreação com "
            "personagens da floresta e mesa de doces em jute e madeira."
        ),
        imagem=img("photo-1469474968028-56623f02e42e"),
        galeria=[
            img("photo-1418065460487-3e41a6c84dc5"),
            img("photo-1502082553048-f009c37129b9"),
            img("photo-1527526029430-319f10814151"),
        ],
        tags=["safari", "selva", "infantil", "cha de bebe", "Decoração"],
        paleta=["#8D6E63", "#C5E1A5", "#FFF8E1", "#4E342E"],
        categoria="Safári",
        categoria_id=CAT_DECOR,
        eventos=(EV_INFANTIL, EV_CHA),
        estilo="Infantil",
        faixa="Intermediário",
        dificuldade="Médio",
        fornecedores=["dec123456", "forn_kids_fun", "doc226677", "forn_chacara_recanto"],
        cats_fornecedor=[NOME_CAT[CAT_DECOR], NOME_CAT[CAT_RECREACAO], NOME_CAT[CAT_BUFFET]],
        tarefas=[
            tarefa("Fechar painel e mini selva", "Folhagens, bichos de pelúcia e arco de balões terra.", NOME_CAT[CAT_DECOR], 60, "alta", True, 1),
            tarefa("Contratar recreação", "Monitores fantasiados e oficinas de máscaras de animais.", NOME_CAT[CAT_RECREACAO], 45, "alta", True, 2),
            tarefa("Mesa de doces safári", "Cupcakes, bolo e lembrancinhas em juta.", NOME_CAT[CAT_BUFFET], 30, "media", True, 3),
            tarefa("Definir o espaço kids", "Chácara ou salão com área externa para infláveis.", NOME_CAT[CAT_ESPACO], 90, "alta", True, 4),
        ],
        orcamento=[
            item(NOME_CAT[CAT_DECOR], "Decoração tema safári", 2800, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_RECREACAO], "Recreação 4 horas", 950, "Monitores + oficinas.", obrigatorio=True, ordem=2),
            item(NOME_CAT[CAT_BUFFET], "Mesa de doces e bolo", 1600, ordem=3),
            item(NOME_CAT[CAT_RECREACAO], "Pula-pula e piscina de bolinhas", 420, ordem=4),
            item(NOME_CAT[CAT_PAPELARIA], "Convites e lembrancinhas", 480, ordem=5),
        ],
        destaque=True,
        ordem=70,
    ),
    insp(
        id_="insp_infantil_super_herois",
        titulo="Aniversário super-heróis",
        descricao=(
            "Capas, máscaras e paleta de HQ. Painel em azul e vermelho, foto com "
            "personagens e pista animada para a criançada."
        ),
        imagem=img("photo-1527526029430-319f10814151"),
        galeria=[
            img("photo-1478144592103-25e218a04891"),
            img("photo-1478144592103-25e218a04891"),
            img("photo-1429962714451-bb934ecdc4ec"),
        ],
        tags=["herois", "fantasia", "infantil", "hq"],
        paleta=["#1565C0", "#EF5350", "#FFD54F", "#212121"],
        categoria="Super-heróis",
        categoria_id=CAT_DECOR,
        eventos=(EV_INFANTIL,),
        estilo="Infantil",
        faixa="Econômico",
        dificuldade="Fácil",
        fornecedores=["dec123456", "forn_kids_fun", "som442177"],
        cats_fornecedor=[NOME_CAT[CAT_DECOR], NOME_CAT[CAT_RECREACAO], NOME_CAT[CAT_MUSICA]],
        tarefas=[
            tarefa("Painel e arco de balões HQ", "Cores primárias, cidade e símbolo do aniversariante.", NOME_CAT[CAT_DECOR], 40, "alta", True, 1),
            tarefa("Personagens e recreação", "Heróis para foto e brincadeiras de salvamento.", NOME_CAT[CAT_RECREACAO], 30, "alta", True, 2),
            tarefa("Kit capa e máscara", "Lembrancinha que as crianças usam na festa.", NOME_CAT[CAT_PAPELARIA], 20, "media", False, 3),
            tarefa("Som e animação da pista", "DJ kids ou recreador com microfone.", NOME_CAT[CAT_MUSICA], 20, "media", False, 4),
        ],
        orcamento=[
            item(NOME_CAT[CAT_DECOR], "Decoração super-heróis", 1900, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_RECREACAO], "Personagens e recreação", 1100, obrigatorio=True, ordem=2),
            item(NOME_CAT[CAT_BUFFET], "Salgados, doces e bolo", 1400, ordem=3),
            item(NOME_CAT[CAT_MUSICA], "Som e animação kids", 650, ordem=4),
        ],
        ordem=80,
    ),
    insp(
        id_="insp_infantil_fundo_mar",
        titulo="Festa fundo do mar",
        descricao=(
            "Azul, areia e vida marinha. Balões transparentes, conchas e um clima de "
            "praia que também funciona em chá de bebê."
        ),
        imagem=img("photo-1507525428034-b723cf961d3e"),
        galeria=[
            img("photo-1507525428034-b723cf961d3e"),
            img("photo-1527526029430-319f10814151"),
            img("photo-1478144592103-25e218a04891"),
        ],
        tags=["mar", "peixes", "infantil", "cha de bebe"],
        paleta=["#0288D1", "#4DD0E1", "#FFF8E1", "#01579B"],
        categoria="Fundo do mar",
        categoria_id=CAT_DECOR,
        eventos=(EV_INFANTIL, EV_CHA),
        estilo="Infantil",
        faixa="Intermediário",
        dificuldade="Médio",
        fornecedores=["dec123456", "forn_kids_fun", "doc226677"],
        cats_fornecedor=[NOME_CAT[CAT_DECOR], NOME_CAT[CAT_RECREACAO], NOME_CAT[CAT_BUFFET]],
        tarefas=[
            tarefa("Decoração aquática", "Painel onda, balões azul/transparente e areia decorativa.", NOME_CAT[CAT_DECOR], 45, "alta", True, 1),
            tarefa("Oficina de conchas", "Recreação com pulseiras e máscaras de peixe.", NOME_CAT[CAT_RECREACAO], 30, "media", True, 2),
            tarefa("Mesa candy azul", "Bolo drip, suspiros e docinhos na paleta do mar.", NOME_CAT[CAT_BUFFET], 20, "media", True, 3),
        ],
        orcamento=[
            item(NOME_CAT[CAT_DECOR], "Decoração fundo do mar", 2400, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_RECREACAO], "Recreação temática", 900, ordem=2),
            item(NOME_CAT[CAT_BUFFET], "Mesa de doces e bolo", 1500, ordem=3),
            item(NOME_CAT[CAT_PAPELARIA], "Convites e tags", 320, ordem=4),
        ],
        ordem=90,
    ),
    insp(
        id_="insp_infantil_desenhos",
        titulo="Festa com desenhos atuais",
        descricao=(
            "Personagens e cores em alta, sem amarrar a um desenho só. Painel colorido, "
            "lembranças personalizadas e recreação com oficinas criativas."
        ),
        imagem=img("photo-1478144592103-25e218a04891"),
        galeria=[
            img("photo-1478144592103-25e218a04891"),
            img("photo-1527526029430-319f10814151"),
            img("photo-1558637845-c8b7ead71a3e"),
        ],
        tags=["desenho", "personagem", "infantil", "colorido"],
        paleta=["#FF7043", "#FFD54F", "#81D4FA", "#FFFFFF"],
        categoria="Desenhos atuais",
        categoria_id=CAT_DECOR,
        eventos=(EV_INFANTIL,),
        estilo="Infantil",
        faixa="Econômico",
        dificuldade="Fácil",
        fornecedores=["dec123456", "forn_kids_fun", "mim983344", "doc226677"],
        cats_fornecedor=[NOME_CAT[CAT_DECOR], NOME_CAT[CAT_RECREACAO], NOME_CAT[CAT_PAPELARIA]],
        tarefas=[
            tarefa("Escolher a paleta do desenho", "2 cores principais + 1 cor de destaque no painel.", NOME_CAT[CAT_DECOR], 40, "alta", True, 1),
            tarefa("Papelaria combinando", "Convite, topper e lembrancinha com o mesmo traço.", NOME_CAT[CAT_PAPELARIA], 30, "media", True, 2),
            tarefa("Oficinas criativas", "Pintura, slime ou pulseiras na recreação.", NOME_CAT[CAT_RECREACAO], 20, "media", False, 3),
        ],
        orcamento=[
            item(NOME_CAT[CAT_DECOR], "Painel e balões coloridos", 1600, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_PAPELARIA], "Kit papelaria personalizada", 540, ordem=2),
            item(NOME_CAT[CAT_RECREACAO], "Recreação e oficinas", 880, ordem=3),
            item(NOME_CAT[CAT_BUFFET], "Salgados, sucos e bolo", 1200, ordem=4),
        ],
        ordem=100,
    ),
    insp(
        id_="insp_aniver_boteco",
        titulo="Aniversário no clima de boteco",
        descricao=(
            "Petiscos, chope e clima descontraído. Caixotes, bandeirinhas, cardápio de "
            "lousa e playlist de pagode ou sertanejo raiz."
        ),
        imagem=img("photo-1514933651103-005eec06c04b"),
        galeria=[
            img("photo-1572116469696-31de0f17cc34"),
            img("photo-1551024709-8f23befc6f87"),
            img("photo-1535254973040-607b474cb50d"),
        ],
        tags=["boteco", "bar", "adulto", "aniversario", "Buffet e Gastronomia"],
        paleta=["#5D4037", "#FFB300", "#EFEBE9", "#212121"],
        categoria="Boteco",
        categoria_id=CAT_BUFFET,
        eventos=(EV_ANIVER, EV_CORP),
        estilo="Descontraído",
        faixa="Econômico",
        dificuldade="Fácil",
        fornecedores=["bar999666", "forn_buffet_sabor", "som442177", "esp555888"],
        cats_fornecedor=[NOME_CAT[CAT_BUFFET], NOME_CAT[CAT_ESPACO], NOME_CAT[CAT_MUSICA]],
        tarefas=[
            tarefa("Montar o cardápio de petiscos", "Isca, linguiça, torresmo e opções vegetarianas.", NOME_CAT[CAT_BUFFET], 40, "alta", True, 1),
            tarefa("Chope e drinks", "Barril, freezer ou bartender por hora.", NOME_CAT[CAT_BUFFET], 30, "alta", True, 2),
            tarefa("Decoração de boteco", "Bandeirinhas, caixotes, luminárias e plaquinhas.", NOME_CAT[CAT_DECOR], 25, "media", False, 3),
            tarefa("Som ambiente e karaokê", "Playlist + microfone para os parabéns.", NOME_CAT[CAT_MUSICA], 15, "baixa", False, 4),
        ],
        orcamento=[
            item(NOME_CAT[CAT_BUFFET], "Petiscos e porções", 85, unidade="convidado", por_convidado=85, quantidade=60, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_BUFFET], "Chope e bar", 2200, "Barril + bartender 4h.", ordem=2),
            item(NOME_CAT[CAT_DECOR], "Ambientação de boteco", 980, ordem=3),
            item(NOME_CAT[CAT_MUSICA], "Som e karaokê", 750, ordem=4),
            item(NOME_CAT[CAT_ESPACO], "Salão para até 100 convidados", 2500, ordem=5),
        ],
        destaque=True,
        ordem=110,
    ),
    insp(
        id_="insp_aniver_neon",
        titulo="Balada neon / glow party",
        descricao=(
            "Luz negra, neon e pista de dança. Roupas claras, pulseiras fluorescentes "
            "e painel de LED. Perfeita para 15 anos, formatura e aniversário adulto."
        ),
        imagem=img("photo-1470225620780-dba8ba36b745"),
        galeria=[
            img("photo-1429962714451-bb934ecdc4ec"),
            img("photo-1470225620780-dba8ba36b745"),
            img("photo-1506157786151-b8491531f063"),
        ],
        tags=["neon", "glow", "15anos", "formatura", "balada"],
        paleta=["#7B1FA2", "#00B8D4", "#111111", "#FF4081"],
        categoria="Neon",
        categoria_id=CAT_MUSICA,
        eventos=(EV_ANIVER, EV_FORMATURA, EV_CORP),
        estilo="Moderno",
        faixa="Intermediário",
        dificuldade="Médio",
        fornecedores=["som442177", "forn_led_stage", "bar999666", "cli995512"],
        cats_fornecedor=[NOME_CAT[CAT_MUSICA], NOME_CAT[CAT_FOTO], NOME_CAT[CAT_BUFFET]],
        tarefas=[
            tarefa("Fechar DJ e iluminação", "Luz negra, strobo e playlist da pista.", NOME_CAT[CAT_MUSICA], 60, "alta", True, 1),
            tarefa("Painel de LED e fundo neon", "Hashtag da festa e fotos no glow.", "Música e Iluminação", 45, "alta", True, 2),
            tarefa("Open bar ou drinks neon", "Receitas com gelo seco ou corante comestível.", NOME_CAT[CAT_BUFFET], 30, "media", False, 3),
            tarefa("Cabine de fotos", "Filtro neon e props fluorescentes.", NOME_CAT[CAT_FOTO], 20, "media", False, 4),
        ],
        orcamento=[
            item(NOME_CAT[CAT_MUSICA], "DJ 4 horas + iluminação", 2800, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_MUSICA], "Painel de LED", 3200, ordem=2),
            item(NOME_CAT[CAT_BUFFET], "Open bar", 99, unidade="convidado", por_convidado=99, quantidade=80, ordem=3),
            item(NOME_CAT[CAT_FOTO], "Cabine de fotos", 890, ordem=4),
        ],
        destaque=True,
        ordem=120,
    ),
    insp(
        id_="insp_aniver_cinema",
        titulo="Festa clima cinema",
        descricao=(
            "Pipoca, claquete e tapete vermelho. Sessão temática, wall de fotos e "
            "dress code Hollywood — serve aniversário, kids e confraternização."
        ),
        imagem=img("photo-1517604931442-7e0c8ed2963c"),
        galeria=[
            img("photo-1517604931442-7e0c8ed2963c"),
            img("photo-1527526029430-319f10814151"),
            img("photo-1478144592103-25e218a04891"),
        ],
        tags=["cinema", "filme", "hollywood", "aniversario"],
        paleta=["#B71C1C", "#F9A825", "#212121", "#FAFAFA"],
        categoria="Cinema",
        categoria_id=CAT_DECOR,
        eventos=(EV_ANIVER, EV_INFANTIL, EV_CORP),
        estilo="Criativo",
        faixa="Intermediário",
        dificuldade="Médio",
        fornecedores=["dec123456", "forn_kids_fun", "som442177", "cli995512"],
        cats_fornecedor=[NOME_CAT[CAT_DECOR], NOME_CAT[CAT_RECREACAO], NOME_CAT[CAT_FOTO]],
        tarefas=[
            tarefa("Tapete vermelho e claquete", "Entrada com step and repeat da festa.", NOME_CAT[CAT_DECOR], 35, "alta", True, 1),
            tarefa("Carrinho de pipoca", "Pipoca doce/salgada e refrigerante em copo de cinema.", NOME_CAT[CAT_BUFFET], 20, "media", True, 2),
            tarefa("Projeção ou LED", "Trailer personalizado ou clipe do aniversariante.", NOME_CAT[CAT_MUSICA], 20, "media", False, 3),
            tarefa("Fotógrafo no tapete", "Poses de premiere na chegada dos convidados.", NOME_CAT[CAT_FOTO], 15, "baixa", False, 4),
        ],
        orcamento=[
            item(NOME_CAT[CAT_DECOR], "Decoração Hollywood", 2200, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_BUFFET], "Carrinho de pipoca", 650, ordem=2),
            item(NOME_CAT[CAT_MUSICA], "Projeção / painel", 1800, ordem=3),
            item(NOME_CAT[CAT_FOTO], "Cobertura da premiere", 1600, ordem=4),
        ],
        ordem=130,
    ),
    insp(
        id_="insp_festa_fantasia",
        titulo="Festa a fantasia",
        descricao=(
            "Cada convidado vem caracterizado. Defina um universo (décadas, filmes, "
            "carnaval fora de época) e ofereça uma estação de maquiagem artística."
        ),
        imagem=img("photo-1429962714451-bb934ecdc4ec"),
        galeria=[
            img("photo-1514525253161-7a46d19cd819"),
            img("photo-1558637845-c8b7ead71a3e"),
            img("photo-1514525253161-7a46d19cd819"),
        ],
        tags=["fantasia", "cosplay", "carnaval", "aniversario"],
        paleta=["#6A1B9A", "#FF6F00", "#F3E5F5", "#212121"],
        categoria="Fantasia",
        categoria_id=CAT_MODA,
        eventos=(EV_ANIVER, EV_INFANTIL),
        estilo="Criativo",
        faixa="Econômico",
        dificuldade="Fácil",
        fornecedores=["forn_noivas_atelier", "dec123456", "forn_kids_fun", "est000888"],
        cats_fornecedor=[NOME_CAT[CAT_MODA], NOME_CAT[CAT_DECOR], NOME_CAT[CAT_BELEZA]],
        tarefas=[
            tarefa("Combinar o tema da fantasia", "Texto claro no convite: obrigatória ou livre.", NOME_CAT[CAT_PAPELARIA], 40, "alta", True, 1),
            tarefa("Estação de maquiagem", "Pintura facial kids ou glitter para adultos.", NOME_CAT[CAT_BELEZA], 20, "media", False, 2),
            tarefa("Concurso de fantasia", "Recreação ou DJ conduz o desfile e o prêmio.", NOME_CAT[CAT_RECREACAO], 10, "baixa", False, 3),
        ],
        orcamento=[
            item(NOME_CAT[CAT_DECOR], "Ambientação do universo", 1400, ordem=1),
            item(NOME_CAT[CAT_MODA], "Aluguel de fantasias (opcional)", 900, ordem=2),
            item(NOME_CAT[CAT_BELEZA], "Maquiagem artística", 650, ordem=3),
            item(NOME_CAT[CAT_MUSICA], "DJ 4 horas", 1800, ordem=4),
        ],
        ordem=140,
    ),
    insp(
        id_="insp_formatura_led",
        titulo="Formatura com palco e LED",
        descricao=(
            "Colação moderna: palco, painel com os nomes da turma, laser e after party. "
            "Encaixa formatura, 15 anos e evento corporativo de premiação."
        ),
        imagem=img("photo-1540575467063-178a50c2df87"),
        galeria=[
            img("photo-1470225620780-dba8ba36b745"),
            img("photo-1511578314322-379afb476865"),
            img("photo-1627556704290-2b1f5853ff78"),
        ],
        tags=["formatura", "led", "palco", "neon"],
        paleta=["#0D47A1", "#00B8D4", "#212121", "#FFFFFF"],
        categoria="LED e palco",
        categoria_id=CAT_MUSICA,
        eventos=(EV_FORMATURA, EV_CORP, EV_ANIVER),
        estilo="Moderno",
        faixa="Premium",
        dificuldade="Elaborado",
        fornecedores=["forn_led_stage", "som442177", "forn_tendas_parana", "cli995512"],
        cats_fornecedor=[NOME_CAT[CAT_MUSICA], NOME_CAT[CAT_ESPACO], NOME_CAT[CAT_FOTO]],
        tarefas=[
            tarefa("Contratar palco e LED", "Painel com arte da turma e nomes na chamada.", NOME_CAT[CAT_MUSICA], 90, "alta", True, 1),
            tarefa("Ensaiar a entrada", "Ordem dos formandos, hino e discurso.", NOME_CAT[CAT_ASSESSORIA], 30, "alta", True, 2),
            tarefa("Foto oficial e filme", "Registro da colação e da festa.", NOME_CAT[CAT_FOTO], 45, "alta", True, 3),
            tarefa("After com DJ", "Pista depois da cerimônia formal.", NOME_CAT[CAT_MUSICA], 20, "media", False, 4),
        ],
        orcamento=[
            item(NOME_CAT[CAT_MUSICA], "Palco, som e painel de LED", 7200, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_ESPACO], "Tenda ou salão amplo", 4200, ordem=2),
            item(NOME_CAT[CAT_FOTO], "Foto e filme da formatura", 3900, obrigatorio=True, ordem=3),
            item(NOME_CAT[CAT_BUFFET], "Coquetel e open bar", 99, unidade="convidado", por_convidado=99, quantidade=150, ordem=4),
            item(NOME_CAT[CAT_SEGURANCA], "Equipe de apoio", 780, ordem=5),
        ],
        destaque=True,
        ordem=150,
    ),
    insp(
        id_="insp_formatura_classica",
        titulo="Formatura clássica no salão",
        descricao=(
            "Cerimônia formal, mesa de honra, buffet completo e valsa. Um caminho "
            "seguro para turmas que querem tradição sem virar balada o tempo todo."
        ),
        imagem=img("photo-1627556704290-2b1f5853ff78"),
        galeria=[
            img("photo-1414235077428-338989a2e8c0"),
            img("photo-1414235077428-338989a2e8c0"),
            img("photo-1535254973040-607b474cb50d"),
        ],
        tags=["formatura", "classico", "salao", "valsa"],
        paleta=["#0D47A1", "#C9A227", "#FAFAFA", "#212121"],
        categoria="Clássico",
        categoria_id=CAT_ESPACO,
        eventos=(EV_FORMATURA,),
        estilo="Clássico",
        faixa="Intermediário",
        dificuldade="Médio",
        fornecedores=["esp555888", "forn_buffet_sabor", "cer111333", "cli995512"],
        cats_fornecedor=[NOME_CAT[CAT_ESPACO], NOME_CAT[CAT_BUFFET], NOME_CAT[CAT_ASSESSORIA], NOME_CAT[CAT_FOTO]],
        tarefas=[
            tarefa("Reservar o salão", "Palco para colação, mesas e pista para valsa.", NOME_CAT[CAT_ESPACO], 180, "alta", True, 1),
            tarefa("Cerimonial da turma", "Roteiro, mestre de cerimônia e ensaio.", NOME_CAT[CAT_ASSESSORIA], 60, "alta", True, 2),
            tarefa("Buffet sentado ou coquetel", "Definir o serviço conforme o número de mesas.", NOME_CAT[CAT_BUFFET], 50, "alta", True, 3),
            tarefa("Beca, canudo e lembranças", "Papelaria da turma e kit dos formandos.", NOME_CAT[CAT_PAPELARIA], 40, "media", False, 4),
        ],
        orcamento=[
            item(NOME_CAT[CAT_ESPACO], "Salão para até 200 convidados", 4200, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_BUFFET], "Buffet completo", 129, unidade="convidado", por_convidado=129, quantidade=150, obrigatorio=True, ordem=2),
            item(NOME_CAT[CAT_ASSESSORIA], "Cerimonial da formatura", 2800, ordem=3),
            item(NOME_CAT[CAT_FOTO], "Cobertura fotográfica", 3200, ordem=4),
            item(NOME_CAT[CAT_MUSICA], "DJ para valsa e pista", 1800, ordem=5),
        ],
        ordem=160,
    ),
    insp(
        id_="insp_corp_coquetel",
        titulo="Coquetel corporativo",
        descricao=(
            "Networking com finger food, open bar controlado, branding discreto e "
            "som lounge. Serve lançamento, confraternização e happy hour da empresa."
        ),
        imagem=img("photo-1511578314322-379afb476865"),
        galeria=[
            img("photo-1414235077428-338989a2e8c0"),
            img("photo-1572116469696-31de0f17cc34"),
            img("photo-1540575467063-178a50c2df87"),
        ],
        tags=["corporativo", "coquetel", "networking", "lounge"],
        paleta=["#1565C0", "#ECEFF1", "#FFB300", "#263238"],
        categoria="Corporativo",
        categoria_id=CAT_CORP,
        eventos=(EV_CORP,),
        estilo="Corporativo",
        faixa="Intermediário",
        dificuldade="Médio",
        fornecedores=["forn_buffet_sabor", "bar999666", "forn_led_stage", "forn_apoio_total"],
        cats_fornecedor=[NOME_CAT[CAT_BUFFET], NOME_CAT[CAT_CORP], NOME_CAT[CAT_SEGURANCA]],
        tarefas=[
            tarefa("Briefing de marca", "Cores, logo e recado do patrocinador no LED.", NOME_CAT[CAT_CORP], 40, "alta", True, 1),
            tarefa("Menu finger food", "Opções quentes/frias e restrições alimentares.", NOME_CAT[CAT_BUFFET], 30, "alta", True, 2),
            tarefa("Credenciamento e apoio", "Recepção, crachás e segurança na porta.", NOME_CAT[CAT_SEGURANCA], 20, "media", True, 3),
            tarefa("Som lounge", "Volume baixo no networking, microfone para o speech.", NOME_CAT[CAT_MUSICA], 15, "media", False, 4),
        ],
        orcamento=[
            item(NOME_CAT[CAT_BUFFET], "Coquetel por convidado", 119, unidade="convidado", por_convidado=119, quantidade=80, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_BUFFET], "Bar controlado 3 horas", 1800, ordem=2),
            item(NOME_CAT[CAT_MUSICA], "Som e microfone", 950, ordem=3),
            item(NOME_CAT[CAT_SEGURANCA], "Recepção e apoio", 780, ordem=4),
            item(NOME_CAT[CAT_FOTO], "Cobertura institucional", 1600, ordem=5),
        ],
        ordem=170,
    ),
    insp(
        id_="insp_corp_convencao",
        titulo="Convenção com palco e tenda",
        descricao=(
            "Auditório ou tenda climatizada, palco, tradução opcional e coffee break. "
            "Estrutura completa para convenção, workshop e premiação anual."
        ),
        imagem=img("photo-1540575467063-178a50c2df87"),
        galeria=[
            img("photo-1511578314322-379afb476865"),
            img("photo-1533174072545-7a4b6ad7a6c3"),
            img("photo-1470225620780-dba8ba36b745"),
        ],
        tags=["corporativo", "convencao", "palco", "tenda"],
        paleta=["#263238", "#90A4AE", "#1565C0", "#FFFFFF"],
        categoria="Corporativo",
        categoria_id=CAT_ESPACO,
        eventos=(EV_CORP,),
        estilo="Corporativo",
        faixa="Premium",
        dificuldade="Elaborado",
        fornecedores=["forn_tendas_parana", "forn_led_stage", "forn_apoio_total", "cli995512"],
        cats_fornecedor=[NOME_CAT[CAT_ESPACO], NOME_CAT[CAT_MUSICA], NOME_CAT[CAT_SEGURANCA]],
        tarefas=[
            tarefa("Tenda, palco e clima", "Metragem, gerador e ar-condicionado.", NOME_CAT[CAT_ESPACO], 90, "alta", True, 1),
            tarefa("LED, som e operadora", "Palco, retorno e operador durante as palestras.", NOME_CAT[CAT_MUSICA], 60, "alta", True, 2),
            tarefa("Coffee e almoço", "Coffee manhã/tarde e opções para restrições.", NOME_CAT[CAT_BUFFET], 40, "alta", True, 3),
            tarefa("Apoio e credenciamento", "Equipe de hall, rádio e segurança.", NOME_CAT[CAT_SEGURANCA], 30, "media", True, 4),
        ],
        orcamento=[
            item(NOME_CAT[CAT_ESPACO], "Tenda climatizada + palco", 8900, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_MUSICA], "Painel de LED e sonorização", 6400, obrigatorio=True, ordem=2),
            item(NOME_CAT[CAT_BUFFET], "Coffee break completo", 69, unidade="convidado", por_convidado=69, quantidade=200, ordem=3),
            item(NOME_CAT[CAT_SEGURANCA], "Equipe de apoio no evento", 1450, ordem=4),
            item(NOME_CAT[CAT_FOTO], "Cobertura e making of", 2900, ordem=5),
        ],
        ordem=180,
    ),
    insp(
        id_="insp_cha_bebe_bosque",
        titulo="Chá de bebê no bosque",
        descricao=(
            "Mesmo universo do safári, em versão mais delicada: tons terra, pinheiros, "
            "guirlanda e jogos para a família descobrir o nome ou o sexo."
        ),
        imagem=img("photo-1418065460487-3e41a6c84dc5"),
        galeria=[
            img("photo-1515488042361-ee00e0ddd4e4"),
            img("photo-1558637845-c8b7ead71a3e"),
            img("photo-1469474968028-56623f02e42e"),
        ],
        tags=["cha de bebe", "bosque", "safari", "neutro"],
        paleta=["#8D6E63", "#C5E1A5", "#FFF8E1", "#F8BBD0"],
        categoria="Safári",
        categoria_id=CAT_DECOR,
        eventos=(EV_CHA, EV_INFANTIL),
        estilo="Delicado",
        faixa="Econômico",
        dificuldade="Fácil",
        fornecedores=["dec123456", "doc226677", "forn_kids_fun", "mim983344"],
        cats_fornecedor=[NOME_CAT[CAT_DECOR], NOME_CAT[CAT_BUFFET], NOME_CAT[CAT_PAPELARIA]],
        tarefas=[
            tarefa("Painel bosque / safari baby", "Folhagens, bichinhos e arco em tons terra.", NOME_CAT[CAT_DECOR], 35, "alta", True, 1),
            tarefa("Brincadeiras do chá", "Quiz dos pais, palpite de data e mural de recados.", NOME_CAT[CAT_RECREACAO], 20, "media", True, 2),
            tarefa("Doces e bolo naked", "Mesa pequena, sucos e um bolo de 2 andares.", NOME_CAT[CAT_BUFFET], 15, "alta", True, 3),
            tarefa("Lembrancinhas e livro do bebê", "Sementes, velas ou kit higiene mini.", NOME_CAT[CAT_PAPELARIA], 15, "baixa", False, 4),
        ],
        orcamento=[
            item(NOME_CAT[CAT_DECOR], "Decoração chá bosque", 1600, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_BUFFET], "Bolo, doces e salgados", 980, obrigatorio=True, ordem=2),
            item(NOME_CAT[CAT_PAPELARIA], "Convites e lembrancinhas", 420, ordem=3),
            item(NOME_CAT[CAT_RECREACAO], "Jogos e recreação leve", 450, ordem=4),
        ],
        ordem=190,
    ),
    insp(
        id_="insp_cha_bebe_pastel",
        titulo="Chá de bebê em tons pastel",
        descricao=(
            "Rosa, azul ou paleta neutra com flores delicadas, balões candy e mesa "
            "de bem-nascidos. Um chá clássico, fácil de montar em salão ou casa."
        ),
        imagem=img("photo-1515488042361-ee00e0ddd4e4"),
        galeria=[
            img("photo-1465495976277-4387d4b0b4c6"),
            img("photo-1558637845-c8b7ead71a3e"),
            img("photo-1478144592103-25e218a04891"),
        ],
        tags=["cha de bebe", "pastel", "flores", "neutro"],
        paleta=["#F8BBD0", "#B3E5FC", "#FFF9C4", "#FFFFFF"],
        categoria="Chá de bebê",
        categoria_id=CAT_DECOR,
        eventos=(EV_CHA,),
        estilo="Delicado",
        faixa="Econômico",
        dificuldade="Fácil",
        fornecedores=["dec123456", "flo777111", "doc226677", "mim983344"],
        cats_fornecedor=[NOME_CAT[CAT_DECOR], NOME_CAT[CAT_BUFFET], NOME_CAT[CAT_PAPELARIA]],
        tarefas=[
            tarefa("Definir paleta e revelação", "Rosa, azul ou neutro — e se haverá chá revelação.", NOME_CAT[CAT_DECOR], 40, "alta", True, 1),
            tarefa("Flores e balões candy", "Arranjo baixo + arco pequeno para fotos.", NOME_CAT[CAT_DECOR], 25, "alta", True, 2),
            tarefa("Bem-nascidos e bolo", "Docinhos, sucos e um bolo com topper do nome.", NOME_CAT[CAT_BUFFET], 15, "alta", True, 3),
            tarefa("Lista de presentes", "QR code no convite apontando para a lista.", NOME_CAT[CAT_PAPELARIA], 20, "media", False, 4),
        ],
        orcamento=[
            item(NOME_CAT[CAT_DECOR], "Decoração pastel com flores", 1800, obrigatorio=True, ordem=1),
            item(NOME_CAT[CAT_BUFFET], "Mesa de bem-nascidos e bolo", 1100, obrigatorio=True, ordem=2),
            item(NOME_CAT[CAT_PAPELARIA], "Convites e tags", 280, ordem=3),
            item(NOME_CAT[CAT_FOTO], "Ensaio curto do chá", 650, ordem=4),
        ],
        destaque=True,
        ordem=200,
    ),
]


def gravar(db) -> tuple[int, int]:
    col = db.collection("inspiracoes")
    existentes = {doc.id for doc in col.stream()}
    lote = db.batch()
    novos = 0
    for item_insp in CATALOGO:
        payload = dict(item_insp)
        payload["atualizadoEm"] = firestore.SERVER_TIMESTAMP
        payload["atualizadoPor"] = "seed_catalogo_festas"
        if item_insp["id"] not in existentes:
            payload["criadoEm"] = firestore.SERVER_TIMESTAMP
            payload["criadoPor"] = "seed_catalogo_festas"
            novos += 1
        lote.set(col.document(item_insp["id"]), payload, merge=True)
    lote.commit()
    total = len(list(col.stream()))
    return len(CATALOGO), total


def main() -> None:
    os.chdir(Path(__file__).resolve().parent)
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(str(CREDENCIAIS)))
    db = firestore.client()
    gravados, total = gravar(db)
    publicados = 0
    por_tipo: dict[str, int] = {}
    for doc in db.collection("inspiracoes").stream():
        data = doc.to_dict() or {}
        if data.get("publicado") is not False and data.get("ativo") is not False:
            publicados += 1
        for nome in data.get("tipoEventoNomes") or []:
            por_tipo[nome] = por_tipo.get(nome, 0) + 1
    print(f"Seed gravado: {gravados} inspirações (merge)")
    print(f"Coleção inspiracoes: {total} documentos, {publicados} visíveis na tela")
    for nome, qtd in sorted(por_tipo.items()):
        print(f"  - {nome}: {qtd}")


if __name__ == "__main__":
    main()
