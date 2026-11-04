"""Diagramas documentais com significado explícito para cada tipo de seta."""
from PIL import Image, ImageDraw, ImageFont
from math import atan2, sin, cos

FONT='C:/Windows/Fonts/arial.ttf'
BOLD='C:/Windows/Fonts/arialbd.ttf'

def gerar_diagramas(destino):
    def canvas(size):
        im=Image.new('RGB',size,'white')
        return im,ImageDraw.Draw(im)
    def text(d,xy,label,size=30,bold=False):
        d.text(xy,label,font=ImageFont.truetype(BOLD if bold else FONT,size),fill='#213b4a')
    def box(d,r,title,lines):
        d.rounded_rectangle(r,radius=13,fill='#f1f5f7',outline='#395665',width=3)
        text(d,(r[0]+20,r[1]+15),title,34,True)
        for i,line in enumerate(lines):text(d,(r[0]+20,r[1]+65+i*39),line,30)
    def arrow(d,a,b,dashed=False):
        if dashed:
            length=((b[0]-a[0])**2+(b[1]-a[1])**2)**.5
            for k in range(0,int(length),24):
                u=k/length;v=min((k+13)/length,1)
                d.line([(a[0]+u*(b[0]-a[0]),a[1]+u*(b[1]-a[1])),(a[0]+v*(b[0]-a[0]),a[1]+v*(b[1]-a[1]))],fill='#9a542d',width=4)
        else:d.line([a,b],fill='#395665',width=4)
        t=atan2(b[1]-a[1],b[0]-a[0]);L=19
        d.polygon([b,(b[0]-L*cos(t-.5),b[1]-L*sin(t-.5)),(b[0]-L*cos(t+.5),b[1]-L*sin(t+.5))],fill='#9a542d' if dashed else '#395665')
    im,d=canvas((1600,980))
    text(d,(30,15),'CLIENTE FLUTTER',32,True)
    box(d,(530,75,1070,235),'app',['Bootstrap, rotas e composição'])
    box(d,(30,370,495,570),'presentation',['Páginas e controllers','Estado e interação'])
    box(d,(570,370,1035,570),'domain',['Entidades e contratos','Casos de uso e serviços'])
    box(d,(1110,370,1570,570),'data',['Models, repositórios','Datasources e gateways'])
    arrow(d,(620,235),(260,370));arrow(d,(800,235),(800,370));arrow(d,(980,235),(1340,370))
    arrow(d,(495,470),(570,470));arrow(d,(1110,470),(1035,470))
    arrow(d,(260,570),(260,670),True);arrow(d,(260,670),(1340,670),True);arrow(d,(1340,670),(1340,570),True)
    text(d,(400,688),'presentation → data observado em alguns módulos',29)
    box(d,(330,770,1270,900),'core',['Banco local, plataforma e utilitários transversais'])
    text(d,(30,930),'Contínua: referência de dependência   |   Tracejada: acoplamento adicional observado',28)
    im.save(destino/'arquitetura.png')

    im,d=canvas((1600,810))
    d.rounded_rectangle((15,20,545,785),radius=15,outline='#8b9ca5',width=3)
    text(d,(40,40),'DISPOSITIVO OU NAVEGADOR',29,True)
    box(d,(40,135,520,330),'Cliente Flutter',['Interface e infraestrutura','de acesso aos serviços'])
    box(d,(40,560,520,735),'Persistência local',['Drift e SQLite em presentes'])
    arrow(d,(280,330),(280,560));text(d,(300,405),'local',28)
    d.rounded_rectangle((625,20,1585,785),radius=15,outline='#8b9ca5',width=3)
    text(d,(650,40),'SERVIÇOS REMOTOS',29,True)
    box(d,(660,135,1550,290),'Firebase',['Authentication, Firestore e Storage'])
    box(d,(660,400,1550,555),'Cloud Functions',['Validação, comandos e integração generativa'])
    box(d,(660,640,1550,755),'Provedor de IA',['Chamada protegida pelo backend'])
    arrow(d,(520,210),(660,210));text(d,(550,155),'SDK',27)
    d.line([(520,285),(575,285),(575,475)],fill='#395665',width=4)
    arrow(d,(575,475),(660,475));text(d,(595,350),'HTTPS',25)
    arrow(d,(1110,400),(1110,290));text(d,(1130,330),'acesso administrativo',27)
    arrow(d,(1110,555),(1110,640));text(d,(1140,585),'API',27)
    im.save(destino/'arquitetura-servicos.png')
