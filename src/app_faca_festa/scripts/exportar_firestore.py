import firebase_admin
from firebase_admin import credentials, firestore
import json, os
from datetime import datetime

# Caminho do arquivo de credenciais do Firebase
cred = credentials.Certificate("credenciais.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# 🔹 Coleções que você quer exportar
colecoes = [
    "tipo_evento",
    "avaliacoes",
    "convidado",
    "evento",
    "fornecedor",
    "orcamento",
    "tarefa",
    "categoria_servico",
    "subcategoria_servico",
    "fornecedor_categoria",
    "servico_foto",
    "cotacao",
    "territorio",
    "servico_produto"
]

# Cria pasta de exportação
os.makedirs("export_firestore", exist_ok=True)

# Função para converter objetos especiais em tipos serializáveis
def convert_firestore_value(value):
    if isinstance(value, datetime):
        return value.strftime("%Y-%m-%d %H:%M:%S")
    elif hasattr(value, "isoformat"):  # garante compatibilidade com Timestamp
        try:
            return value.isoformat()
        except Exception:
            return str(value)
    return value

# Função para converter documentos Firestore em JSON puro
def serialize_document(doc):
    data = {}
    for key, value in doc.items():
        if isinstance(value, dict):
            data[key] = serialize_document(value)
        elif isinstance(value, list):
            data[key] = [serialize_document(v) if isinstance(v, dict) else convert_firestore_value(v) for v in value]
        else:
            data[key] = convert_firestore_value(value)
    return data

# Exporta as coleções
for col in colecoes:
    docs = db.collection(col).stream()
    data = [serialize_document(doc.to_dict()) for doc in docs]

    with open(f"export_firestore/{col}.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    print(f"✅ Exportado: {col} ({len(data)} documentos)")

print("\n🎉 Exportação concluída com sucesso! Arquivos salvos na pasta 'export_firestore'")
