"""Inventário estático reproduzível para a comparação documental.

Não interpreta chamadas dinâmicas nem comprova publicação ou execução.
"""
from pathlib import Path
from collections import Counter
import json, re, hashlib

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent/'analise-aplicativo-2026-10-29'
OUT.mkdir(exist_ok=True)
def read(p):return p.read_text(encoding='utf-8-sig',errors='replace')
files=list((ROOT/'lib').rglob('*.dart'))
areas=Counter(p.relative_to(ROOT/'lib').parts[0] for p in files)
modules={p.name:len(list(p.rglob('*.dart'))) for p in sorted((ROOT/'lib/presentation/modules').iterdir()) if p.is_dir()}
imports=[]
for p in files:
 for imp in re.finditer(r"^\s*(?:import|export)\s+['\"]([^'\"]+)['\"]",read(p),re.M):
  target=imp.group(1)
  if target.startswith('package:app_faca_festa/'):
   target=target.split('package:app_faca_festa/',1)[1].split('/')[0]
  elif not target.startswith(('package:','dart:')):
   targetpath=(p.parent/target).resolve()
   try:target=targetpath.relative_to(ROOT/'lib').parts[0]
   except ValueError:continue
  imports.append({'arquivo':p.relative_to(ROOT).as_posix(),'linha':read(p)[:imp.start()].count('\n')+1,'destino':target})
exception=[r for r in imports if
 (r['arquivo'].startswith('lib/presentation/') and (r['destino']=='data' or re.search('firebase|cloud_firestore|cloud_functions',r['destino']))) or
 (r['arquivo'].startswith('lib/data/') and r['destino']=='package:get/get.dart') or
 (r['arquivo'].startswith('lib/domain/') and (r['destino']=='core' or 'flutter' in r['destino'] or 'firebase' in r['destino']))]
routes=re.findall(r"\bname\s*:\s*['\"]([^'\"]+)['\"]",read(ROOT/'lib/app/routes/app_routes.dart'))
exports=[]
for block in re.findall(r'export\s*\{(.*?)\}\s*from\s*["\']([^"\']+)',read(ROOT/'functions/src/index.ts'),re.S):
 for entry in block[0].split(','):
  entry=entry.strip()
  if entry:exports.append({'nome':entry.split(' as ')[-1].strip(),'modulo':block[1]})
collections={}
for p in files+list((ROOT/'functions/src').rglob('*.ts')):
 for name in re.findall(r"\.collection\(\s*['\"]([^'\"]+)['\"]",read(p)):
  collections.setdefault(name,[]).append(p.relative_to(ROOT).as_posix())
tests=list((ROOT/'test').rglob('*_test.dart'))
integration=list((ROOT/'integration_test').glob('*_test.dart'))
all_sources=files+list((ROOT/'functions/src').rglob('*.ts'))+[ROOT/'firestore.rules',ROOT/'firestore.indexes.json',ROOT/'firebase.json',ROOT/'pubspec.yaml']
manifest={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in all_sources}
inventory={'data':'2026-10-29','metodo':'Contagens estáticas; gerados Dart incluídos; exports não equivalem a Functions publicadas; nomes literais de collection misturam raiz e subcoleções e não cobrem referências dinâmicas.','areas_dart':dict(areas),'modulos_ui':modules,'rotas_nomeadas':routes,'exports_backend':exports,'colecoes_literais':collections,'imports_excecoes':exception,'arquivos_testes_dart':len(tests),'arquivos_integration_test':len(integration),'testes_por_pasta':dict(Counter('/'.join(p.relative_to(ROOT/'test').parts[:-1]) for p in tests)),'sha256_fontes':manifest}
(OUT/'inventario.json').write_text(json.dumps(inventory,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in inventory.items() if k in ['areas_dart','modulos_ui','arquivos_testes_dart','arquivos_integration_test']},ensure_ascii=False,indent=2))
print('Rotas',len(routes),'Exports',len(exports),'Nomes literais de coleções',len(collections),'Imports de exceção',len(exception))
