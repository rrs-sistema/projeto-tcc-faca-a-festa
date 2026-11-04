from pathlib import Path
import re
from PIL import Image, ImageDraw, ImageFont
from docx import Document
from docx.shared import Cm, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT = Path(__file__).resolve().parent
ASSETS = ROOT / 'assets'
ASSETS.mkdir(exist_ok=True)

from diagramas_arquitetura import gerar_diagramas
gerar_diagramas(ASSETS)
from diagramas_fluxos import gerar_fluxos
gerar_fluxos(ASSETS)

doc=Document()
s=doc.sections[0]
s.page_width=Cm(21); s.page_height=Cm(29.7)
s.top_margin=Cm(2.2); s.bottom_margin=Cm(2.0)
s.left_margin=Cm(2.7); s.right_margin=Cm(2.3)
normal=doc.styles['Normal']; normal.font.name='Arial'; normal.font.size=Pt(11)
normal.paragraph_format.line_spacing=1.15
normal.paragraph_format.space_after=Pt(6)
lang=OxmlElement('w:lang');lang.set(qn('w:val'),'pt-BR');normal.element.get_or_add_rPr().append(lang)
for name,size in [('Title',26),('Subtitle',14),('Heading 1',17),('Heading 2',12)]:
    st=doc.styles[name]; st.font.name='Arial'; st.font.size=Pt(size); st.font.color.rgb=RGBColor(0,0,0)
    st.paragraph_format.space_after=Pt(9)
    st.paragraph_format.space_before=Pt(9)
    if name.startswith('Heading'): st.font.bold=True
for stname in ['Title','Subtitle','Heading 1','Heading 2']:
    pp=doc.styles[stname].element.find(qn('w:pPr'))
    if pp is not None:
        for x in list(pp):
            if x.tag==qn('w:pBdr'): pp.remove(x)
props=doc.core_properties
props.title='Documentação do Software Faça a Festa'
props.subject='Relatório técnico para apresentação do TCC'
props.author='Equipe Faça a Festa'
props.keywords='TCC, Faça a Festa, documentação de software'

for text in ['UNICESUMAR','Engenharia de Software']:
    p=doc.add_paragraph(text);p.alignment=WD_ALIGN_PARAGRAPH.CENTER
doc.add_paragraph('\n\n')
p=doc.add_paragraph('Documentação do Software',style='Title');p.alignment=WD_ALIGN_PARAGRAPH.CENTER
p=doc.add_paragraph('Faça a Festa',style='Title');p.alignment=WD_ALIGN_PARAGRAPH.CENTER
p=doc.add_paragraph('Relatório técnico para apresentação do TCC',style='Subtitle');p.alignment=WD_ALIGN_PARAGRAPH.CENTER
doc.add_paragraph('\n')
p=doc.add_paragraph('Nicolas Brayan\nJulia Acsa\nRivaldo Roberto');p.alignment=WD_ALIGN_PARAGRAPH.CENTER
p=doc.add_paragraph('Planejamento de eventos e acompanhamento operacional');p.alignment=WD_ALIGN_PARAGRAPH.CENTER
doc.add_paragraph('\n\n')
p=doc.add_paragraph('Curitiba\n2026');p.alignment=WD_ALIGN_PARAGRAPH.CENTER
p=doc.add_paragraph('Edição 4   •   29 de outubro de 2026');p.alignment=WD_ALIGN_PARAGRAPH.CENTER

foot=s.footer.paragraphs[0]; foot.alignment=WD_ALIGN_PARAGRAPH.RIGHT
r=foot.add_run(); r.font.size=Pt(9)
field=OxmlElement('w:fldSimple');field.set(qn('w:instr'),'PAGE');r._r.addnext(field)
doc.add_page_break();p=doc.add_paragraph('Sumário',style='Title')
p=doc.add_paragraph();field=OxmlElement('w:fldSimple');field.set(qn('w:instr'),'TOC \\o "1-1" \\h \\z \\u');p._p.append(field)

def runs(p,text):
    for i,part in enumerate(re.split(r'(\*\*.*?\*\*)',text)):
        r=p.add_run(part[2:-2] if part.startswith('**') else part)
        if part.startswith('**'):r.bold=True

def table(lines):
    rows=[[x.strip() for x in line.strip().strip('|').split('|')] for line in lines]
    rows=[r for r in rows if not all(re.fullmatch(r'[-: ]+',x) for x in r)]
    t=doc.add_table(rows=1,cols=len(rows[0]));t.style='Table Grid';t.autofit=False
    widths={2:[2.0,14.0],3:[3.3,6.2,6.5],4:[1.4,4.4,8.5,1.7]}.get(len(rows[0]))
    if rows[0][0] in ('Termo','Necessidade de consulta'): widths=[4.3,11.7] if len(rows[0])==2 else [4.3,5.7,6.0]
    if rows[0][0] in ('Campo ou grupo','Campo ou estrutura','Estrutura','Comando'): widths=[5.0,4.3,6.7]
    if rows[0][0]=='Fluxo': widths=[4.0,3.0,9.0]
    if rows[0][0]=='Informação': widths=[3.5,5.8,6.7]
    if rows[0][0]=='Caminho': widths=[4.6,5.6,5.8]
    if rows[0][0]=='Caminho ou família': widths=[5.8,5.1,5.1]
    if rows[0][0]=='Etapa': widths=[2.8,6.5,6.7] if len(rows[0])==3 else [2.8,13.2]
    if rows[0][0]=='Cenário': widths=[3.4,12.6]
    if rows[0][0]=='Tempo': widths=[2.0,5.0,9.0]
    # Wide narrative matrices need balanced columns instead of a narrow source column.
    if len(rows[0])==4 and rows[0][-1]!='Fonte': widths=[1.6,4.5,3.6,6.3]
    if widths:
        for col,width in zip(t.columns,widths): col.width=Cm(width)
    for rowdata_i,rowdata in enumerate(rows):
        cells=t.rows[0].cells if rowdata_i==0 else t.add_row().cells
        for j,text in enumerate(rowdata):
            cells[j].text=text
            if widths:cells[j].width=Cm(widths[j])
            for p in cells[j].paragraphs:
                p.paragraph_format.space_after=Pt(4);p.paragraph_format.space_before=Pt(3)
                p.paragraph_format.line_spacing=1.05
                for run in p.runs:run.font.size=Pt(9);run.bold=rowdata_i==0
        trpr=t.rows[rowdata_i]._tr.get_or_add_trPr()
        no=OxmlElement('w:cantSplit');trpr.append(no)
        if rowdata_i==0:
            rep=OxmlElement('w:tblHeader');trpr.append(rep)
            for cell in cells:
                sh=OxmlElement('w:shd');sh.set(qn('w:fill'),'E9EEF1');cell._tc.get_or_add_tcPr().append(sh)
    borders=OxmlElement('w:tblBorders')
    for side in ['top','left','bottom','right','insideH','insideV']:
        border=OxmlElement('w:'+side);border.set(qn('w:val'),'single');border.set(qn('w:sz'),'4');border.set(qn('w:color'),'D9D9D9');borders.append(border)
    t._tbl.tblPr.append(borders)
    doc.add_paragraph().paragraph_format.space_after=Pt(0)

lines=(ROOT/'documentacao-software-faca-a-festa.md').read_text(encoding='utf-8').splitlines()
i=0
while i<len(lines):
    text=lines[i].strip()
    if not text:i+=1;continue
    if text.startswith('# '):
        p=doc.add_heading(text[2:],level=1);p.paragraph_format.page_break_before=True
    elif text.startswith('## '):
        p=doc.add_heading(text[3:],level=2)
        if text.startswith(('## UC03','## UC06','## UC07','## UC08','## UC09','## UC10','## UC12','## UC13','## UC14',
            '## 5 2','## 5 3','## 5 4','## 8 2','## 8 3','## 8 5','## 2 4','## 2 6','## 4 1',
            '## 9 4','## 9 5','## 9 6','## 9 7','## 10 3','## 10 5','## 10 6','## 12 3','## 12 4','## 12 5','## 13 1','## 13 2','## 13 3')):
            p.paragraph_format.page_break_before=True
    elif text.startswith('|'):
        block=[]
        while i<len(lines) and lines[i].strip().startswith('|'):block.append(lines[i]);i+=1
        table(block);continue
    elif text.startswith('!['):
        path=re.search(r'\]\((.*)\)',text).group(1)
        p=doc.add_paragraph();p.paragraph_format.keep_with_next=True
        p.alignment=WD_ALIGN_PARAGRAPH.CENTER
        shape=p.add_run().add_picture(str((ROOT/path).resolve()),width=Cm(14.5 if ('1366' in path or 'atual-2026' in path) else 16))
        if 'reputacao-1366-falha' in path or 'agenda-1366-dados' in path:
            crop=.60 if 'reputacao' in path else .16
            rect=OxmlElement('a:srcRect');rect.set('b',str(int(crop*100000)))
            shape._inline.graphic.graphicData.pic.blipFill.insert(1,rect)
            shape.height=int(shape.height*(1-crop))
    elif text.startswith('- '):
        p=doc.add_paragraph(style='List Bullet');runs(p,text[2:])
        if text.startswith('- S'):
            p.paragraph_format.line_spacing=1.05
            for r in p.runs:r.font.size=Pt(9.5)
    elif re.match(r'^\d+\. ',text):
        p=doc.add_paragraph();p.paragraph_format.left_indent=Cm(.45);runs(p,text)
    else:
        p=doc.add_paragraph();runs(p,text)
        if len(text.split())<85:p.paragraph_format.keep_together=True
        if text.startswith('Figura '):
            p.paragraph_format.line_spacing=1.1
            for r in p.runs:r.font.size=Pt(9);r.italic=True
    i+=1
out=ROOT/'Documentacao_do_Software_Faca_a_Festa.docx'
doc.save(out)
print(out)
print('Palavras aproximadas:',len(' '.join(lines).split()))
