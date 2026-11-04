"""Diagramas de recortes verificados da implementação para o relatório."""
from PIL import Image, ImageDraw, ImageFont
from math import atan2, sin, cos

def gerar_fluxos(destino):
    ink='#223b4a'; edge='#637987'; pale='#f1f5f7'
    def canvas(h):
        im=Image.new('RGB',(1600,h),'white')
        return im,ImageDraw.Draw(im)
    def txt(d,x,y,s,n=30,b=False):
        f=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf' if b else 'C:/Windows/Fonts/arial.ttf',n)
        d.multiline_text((x,y),s,font=f,fill=ink,spacing=9)
    def box(d,x,y,w,h,title,body='',n=30):
        d.rounded_rectangle((x,y,x+w,y+h),radius=12,outline=edge,width=3,fill=pale)
        txt(d,x+18,y+14,title,n,True)
        if body:txt(d,x+18,y+59,body,28)
    def arrow(d,a,b):
        d.line([a,b],fill=edge,width=4)
        t=atan2(b[1]-a[1],b[0]-a[0]);l=18
        d.polygon([b,(b[0]-l*cos(t-.5),b[1]-l*sin(t-.5)),(b[0]-l*cos(t+.5),b[1]-l*sin(t+.5))],fill=edge)

    im,d=canvas(1050)
    txt(d,25,15,'ESTADO COMERCIAL DO ATENDIMENTO',33,True)
    nodes=[(25,'Nova solicitação'),(430,'Proposta enviada'),(835,'Negociação'),(1240,'Ganho')]
    for x,label in nodes:box(d,x,90,330,100,label,n=29)
    for a,b in [(355,430),(760,835),(1165,1240)]:arrow(d,(a,140),(b,140))
    txt(d,455,215,'Revisões de proposta preservam versões e condições',29)
    box(d,280,290,1040,100,'Encerramentos comerciais','Recusado · Perdido · Cancelado',29)
    txt(d,25,445,'ESTADO DE EXECUÇÃO DO CONTRATO',33,True)
    labels=['Não iniciado','Agendado','Em execução','Entrega informada']
    for i,label in enumerate(labels):box(d,25+i*405,520,330,100,label,n=29)
    for a,b in [(355,430),(760,835),(1165,1240)]:arrow(d,(a,570),(b,570))
    d.line([(1405,620),(1405,700),(965,700)],fill=edge,width=4)
    arrow(d,(965,700),(965,770));box(d,800,770,330,100,'Aceito',n=30)
    d.line([(1405,700),(1405,770)],fill=edge,width=4)
    arrow(d,(1405,700),(1405,770));box(d,1240,770,330,100,'Contestado',n=30)
    box(d,25,770,680,100,'Cancelado na execução','Consultar histórico e mediação',29)
    txt(d,25,945,'Execução e situação financeira são dimensões independentes.',30,True)
    im.save(destino/'estados-atendimento.png')

    im,d=canvas(1180)
    txt(d,25,15,'CONFIRMAÇÃO DO PLANEJADOR',34,True)
    xs=[200,770,1360]
    for x,title in zip(xs,['Cliente Flutter','Cloud Function','Firestore']):
        box(d,x-170,90,340,100,title,n=30)
        for y in range(205,1100,25):d.line([(x,y),(x,y+12)],fill='#a6b0b6',width=2)
    events=[(0,1,270,'1  Pedido, revisão, fontes e regras'),
            (1,2,390,'2  Relê fontes e recibo em transação'),
            (2,1,510,'3  Estado atual e recibo existente'),
            (1,2,750,'5  Grava estado e recibo compatíveis'),
            (1,0,970,'6  Retorna estado confirmado')]
    for a,b,y,label in events:
        arrow(d,(xs[a],y),(xs[b],y))
        txt(d,min(xs[a],xs[b])+15,y-48,label,27)
    box(d,585,580,980,105,'4  Valida revisão, fontes, itens e contexto',
        'Mesma identidade + assinatura: recupera resultado',28)
    txt(d,40,1045,'Fontes alteradas ou pedido com outros dados: exige revisão.',29,True)
    txt(d,40,1100,'As respostas rejeitadas não seguem a gravação de nova confirmação.',28)
    im.save(destino/'sequencia-planejador.png')

    im,d=canvas(1080)
    txt(d,25,15,'RELAÇÕES LÓGICAS DO NÚCLEO',34,True)
    box(d,25,100,400,130,'usuarios/{uid}','Identidade e perfil')
    box(d,595,100,400,130,'evento/{id}','Proprietário: id_usuario')
    arrow(d,(425,165),(595,165))
    box(d,25,330,400,150,'convidado/{id}','Vínculo: id_evento\nPresença e classificação')
    box(d,595,330,400,150,'cardapios/{id}','Vínculo: id_evento\nSubcoleção: itens')
    box(d,1165,330,410,150,'calculadora_operacao','Documento por evento\nRevisão e confirmações',28)
    arrow(d,(680,230),(225,330));arrow(d,(795,230),(795,330));arrow(d,(925,230),(1365,330))
    box(d,25,590,400,155,'cotacao/{id}','Vínculo: id_evento\nParticipantes por fornecedor')
    box(d,595,590,400,155,'orcamento/{id}','Evento, fornecedor\ne contrato financeiro')
    box(d,1165,590,410,155,'Mediações','Vínculo: id_orcamento')
    d.line([(625,230),(520,275),(520,550),(225,550)],fill=edge,width=4)
    arrow(d,(225,550),(225,590))
    arrow(d,(425,665),(595,665));arrow(d,(995,665),(1165,665))
    box(d,25,875,400,135,'Recebimentos','Entrada registrada')
    box(d,595,875,400,135,'Alocações','Recebimento e contrato')
    box(d,1165,875,410,135,'Repasses','Contrato e fornecedor')
    arrow(d,(425,940),(595,940));arrow(d,(995,940),(1165,940))
    arrow(d,(795,745),(795,875));arrow(d,(955,745),(1290,875))
    txt(d,25,1030,'Linhas indicam vínculos lógicos; integridade é conferida pelos serviços.',27)
    im.save(destino/'relacionamentos-dados.png')
