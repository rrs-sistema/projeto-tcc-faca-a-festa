"""Extrai paginação e cria imagens locais para revisão visual do Word exportado."""
from pathlib import Path
import os, re, json, hashlib
from pypdf import PdfReader
from pdf2image import convert_from_path
from PIL import Image, ImageDraw

out=Path(os.environ['TEMP'])/'faca-festa-tcc-edicao4'
pdf=out/'documentacao.pdf'
pages=PdfReader(pdf).pages
summary=[]
for i,p in enumerate(pages,1):
    t=p.extract_text() or ''
    summary.append({'pagina':i,'palavras':len(t.split()),'inicio':t[:140].replace('\n',' '),'fim':t[-100:].replace('\n',' ')})
(out/'paginacao.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
images=out/'paginas';images.mkdir(exist_ok=True)
before={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in images.glob('page-*.png')}
paths=convert_from_path(str(pdf),dpi=115,output_folder=str(images),fmt='png',thread_count=4,paths_only=True,
    output_file='pagina',poppler_path=r'C:\Users\User\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\poppler\Library\bin')
for i,p in enumerate(paths,1):
    target=images/f'page-{i}.png'
    Path(p).replace(target)
contacts=out/'contatos';contacts.mkdir(exist_ok=True)
for start in range(1,len(paths)+1,3):
    ims=[Image.open(images/f'page-{i}.png') for i in range(start,min(start+3,len(paths)+1))]
    w,h=ims[0].size
    sheet=Image.new('RGB',(w*len(ims),h+35),'#dddddd')
    draw=ImageDraw.Draw(sheet)
    for j,im in enumerate(ims):
        sheet.paste(im,(j*w,35));draw.text((j*w+20,10),f'Pagina {start+j}',fill='black')
    sheet.save(contacts/f'pages-{start}-{start+len(ims)-1}.png')
after={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in images.glob('page-*.png')}
print(json.dumps({'paginas':len(pages),'paginas_alteradas':[p for p in after if before.get(p)!=after[p]],'paginas_sem_texto':[s['pagina'] for s in summary if s['palavras']<5]}))
