from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.colors import HexColor
from reportlab.lib.utils import simpleSplit
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from pathlib import Path

out = Path('output/pdf/roteiro_tcc_administrador.pdf').resolve()
pdfmetrics.registerFont(TTFont('Arial', 'C:/Windows/Fonts/arial.ttf'))
pdfmetrics.registerFont(TTFont('ArialBold', 'C:/Windows/Fonts/arialbd.ttf'))
W,H=595.28,841.89
c=canvas.Canvas(str(out),pagesize=(W,H))
c.setTitle('Roteiro de apresentação do TCC - Administração do Faça a Festa')
c.setAuthor('Faça a Festa')
teal=HexColor('#145852')
body=ParagraphStyle('body',fontName='Arial',fontSize=11.5,leading=17,textColor=HexColor('#1E293B'))
action=ParagraphStyle('action',fontName='Arial',fontSize=9.5,leading=13,textColor=HexColor('#526475'))

def p(text,y,style=body):
    para=Paragraph(text,style)
    _,h=para.wrap(W-88,H)
    para.drawOn(c,44,y-h)
    return y-h

def page(n):
    c.setFillColor(teal); c.rect(0,H-12,W,12,fill=1,stroke=0)
    c.setFont('ArialBold',10); c.drawString(44,H-42,'FAÇA A FESTA  /  APRESENTAÇÃO DO TCC')
    c.setStrokeColor(HexColor('#D8E3E2')); c.line(44,44,W-44,44)
    c.setFillColor(HexColor('#637282')); c.setFont('Arial',8)
    c.drawString(44,30,'Roteiro de apoio • Falas e ações na tela')
    c.drawRightString(W-44,30,f'{n} / 2')

def section(title,timing,actions,speech,y):
    c.setFillColor(teal); c.setFont('ArialBold',13); c.drawString(44,y,title)
    c.setFont('Arial',9); c.drawRightString(W-44,y,timing)
    y=p(actions,y-12,action)-10
    y=p(speech,y)-25
    return y

page(1)
c.setFillColor(HexColor('#142D32')); c.setFont('ArialBold',24)
c.drawString(44, H-84, 'Administração da plataforma')
y=p('Tempo estimado de até 4 minutos, incluindo pausas curtas para os cliques.',H-101,action)-25

y=section('Visão geral do painel','0:00 - 0:30',
'Mantenha o painel inicial aberto e aponte os módulos enquanto apresenta.',
'“O painel administrativo reúne a gestão da operação do Faça a Festa. Por aqui, o administrador acompanha o catálogo, os usuários, os fornecedores, os eventos e os orçamentos. Ele também controla as aprovações, as áreas de atendimento e as regras comerciais. Vou demonstrar cinco pontos dessa gestão, acompanhando a jornada do fornecedor desde a aprovação do perfil até a contratação e a auditoria das ações.”',y)

y=section('1. Gestão de fornecedores','0:30 - 1:00',
'No painel, abra Aprovar fornecedores. Mostre um perfil em análise e a opção Aprovar para operar.',
'“Começando pela entrada do fornecedor, o cadastro precisa passar pela aprovação do administrador. Aqui, localizamos os perfis em análise, conferimos as informações e aprovamos o cadastro para que o fornecedor possa atuar. Essa etapa permite controlar quem está autorizado a oferecer serviços aos clientes.”',y)

y=section('2. Territórios e abrangência','1:00 - 1:45',
'Abra Territórios, aponte as coberturas no mapa e acesse Faixas de abrangência na barra superior.',
'“Depois, administramos onde cada fornecedor pode atender. A cobertura padrão gratuita é de até 20 quilômetros a partir do endereço cadastrado. Para ampliar esse alcance, o modelo Premium de Abrangência prevê faixas adicionais de 5 quilômetros. Aqui, o administrador define o valor de cada faixa e a data de vigência da tabela. A mensalidade resulta da soma das faixas escolhidas. Isso permite organizar a cobertura e estruturar uma fonte de receita recorrente para a plataforma.”',y)

assert y>55,y
c.showPage()
page(2)
y=H-83

y=section('3. Financeiro e comissões','1:45 - 2:40',
'Abra Financeiro e mostre os totais. Depois, abra Comissões e aponte a política e o simulador.',
'“No financeiro, acompanhamos o valor dos contratos, as comissões geradas, o que foi recebido e o saldo a receber. Neste recorte, os contratos somam 3.337 reais e as comissões recebidas totalizam 166 reais e 85 centavos. Para ilustrar a divisão, em um contrato de mil reais com taxa de 5%, a comissão da plataforma seria de 50 reais. Se essa taxa for descontada do fornecedor, o líquido seria de 950 reais, considerando apenas essa dedução. Na tela de Comissões, podemos consultar a política e simular os valores.”',y)
y=section('4. Contratações e mediação','2:40 - 3:20',
'Abra Contratações e mediação. Selecione Contratos, abra um registro e mostre Mediação e histórico.',
'“Nesta área, acompanhamos as oportunidades e os contratos confirmados. Ao abrir um contrato, o administrador consegue identificar o cliente, o fornecedor e acompanhar a execução do serviço. Se ocorrer uma divergência, como um atraso na entrega, é possível abrir um caso de mediação vinculado à contratação e registrar a decisão. Esse acompanhamento dá à administração informações para conduzir o caso e consultar o histórico das providências tomadas.”',y)

y=section('5. Auditoria da plataforma','3:20 - 4:00',
'Abra Auditoria, mostre os indicadores e clique em Investigar. Aponte responsável, horário e alteração em um registro.',
'“Por fim, a auditoria permite acompanhar as ações realizadas na plataforma. O painel reúne alertas, falhas de acesso e atividades administrativas. No histórico, podemos verificar quem realizou uma ação, em qual horário e o que foi alterado. Neste exemplo, a verificação por e-mail passou de pendente para verificada. Assim, a administração tem rastreabilidade para investigar ocorrências e conferir as decisões tomadas durante a operação.”',y)

c.setStrokeColor(HexColor('#D8E3E2')); c.line(44,y+5,W-44,y+5)
y=p('Notas para o ensaio',y-13,ParagraphStyle('notehead',parent=body,fontName='ArialBold',fontSize=10))-9
y=p('A contratação do Premium de Abrangência ainda aparece como indisponível na tela do fornecedor. Apresente a configuração das faixas e o modelo previsto. Os preços dependem da tabela publicada pelo administrador.',y,action)-10
y=p('O exemplo de mil reais é ilustrativo. Os totais financeiros foram retirados das telas enviadas e podem mudar com a atualização dos dados. O tempo indicado é uma estimativa de leitura e navegação.',y,action)
assert y>55,y
c.save()
print(out)
print('PDF gerado em duas páginas.')
