from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.colors import HexColor
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from pypdf import PdfReader

sections = [
('Visão geral do painel', '0:00 - 0:30', 'Mostre o painel inicial e aponte os módulos.',
'O administrador acompanha toda a operação do Faça a Festa. Neste painel, ele gerencia o catálogo e os usuários, aprova fornecedores, define áreas de atendimento e acompanha eventos e orçamentos. Também controla as regras comerciais e consulta a auditoria das ações. Vou destacar como essa gestão funciona no financeiro e no acompanhamento das contratações.'),
('Financeiro e comissões', '0:30 - 1:30', 'Abra Financeiro. Mostre os valores e as condições do repasse de um contrato.',
'Quando o organizador faz um pagamento, o valor fica sob gestão da plataforma até que o repasse ao fornecedor seja liberado. A regra é liberar após a finalização do evento, mas o organizador pode autorizar um pagamento antecipado. Antes do repasse, a administração confere o recebimento, o saldo disponível e possíveis bloqueios. Aqui, acompanhamos quanto entrou, a comissão da plataforma e o valor devido ao fornecedor. Por exemplo, em um contrato de mil reais, com comissão de 5% descontada do fornecedor, a plataforma fica com 50 reais e o fornecedor recebe 950 reais, considerando apenas essa dedução.'),
('Contratações e mediação', '1:30 - 2:20', 'Abra Contratações e mediação, selecione Contratos e mostre Mediação e histórico.',
'Nesta tela, o administrador acompanha cada contratação, identifica o organizador e o fornecedor e consulta a execução do serviço e os valores envolvidos. Se houver uma divergência, como um serviço que não foi entregue, é possível abrir um caso de mediação e registrar a análise e a decisão. Enquanto o caso estiver aberto, o repasse fica bloqueado. Depois da resolução, a administração confere novamente as condições para liberar o pagamento. Esse controle permite tratar o problema com base no histórico do contrato.'),
('Encerramento', '2:20 - 2:25', 'Finalize na tela do contrato.',
'Assim, a administração acompanha o serviço, controla os repasses e mantém as decisões registradas.'),
]
pdfmetrics.registerFont(TTFont('Arial','C:/Windows/Fonts/arial.ttf'))
pdfmetrics.registerFont(TTFont('ArialBold','C:/Windows/Fonts/arialbd.ttf'))
out=Path('output/pdf/roteiro_tcc_administrador_2min30.pdf').resolve()
c=canvas.Canvas(str(out),pagesize=(595.28,841.89))
c.setTitle('Faça a Festa - Roteiro administrativo de até 2min30')
c.setAuthor('Faça a Festa')
body=ParagraphStyle('body',fontName='Arial',fontSize=10.7,leading=15,textColor=HexColor('#1E293B'))
small=ParagraphStyle('small',parent=body,fontSize=8.8,leading=12,textColor=HexColor('#536575'))

def para(text,y,style):
    p=Paragraph(text,style)
    _,h=p.wrap(507,800)
    p.drawOn(c,44,y-h)
    return y-h

c.setFillColor(HexColor('#145852'));c.rect(0,830,596,12,fill=1,stroke=0)
c.setFont('ArialBold',10);c.drawString(44,800,'FAÇA A FESTA / APRESENTAÇÃO DO TCC')
c.setFont('ArialBold',23);c.drawString(44,766,'Administração da plataforma')
y=para('Até 2min30 • Meta de ensaio: 2min25, com pausas curtas para os cliques.',749,small)-23
for title,timing,action,speech in sections:
    c.setFillColor(HexColor('#145852'));c.setFont('ArialBold',12)
    c.drawString(44,y,title);c.setFont('Arial',9);c.drawRightString(551,y,timing)
    y=para(action,y-10,small)-8
    y=para('“'+speech+'”',y,body)-19
c.setStrokeColor(HexColor('#D8E3E2'));c.line(44,y+4,551,y+4)
y=para('Apoio ao ensaio: o exemplo de comissão é ilustrativo. A transferência bancária é manual, com conferência e registro pela equipe. O tempo depende do ritmo de fala e da navegação.',y-5,small)
assert y>35,y
c.save()
r=PdfReader(str(out))
assert len(r.pages)==1
print(out)
print('Palavras na fala:',sum(len(s[3].split()) for s in sections))
