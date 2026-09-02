import '../models/servico_produto/servico_produto_model.dart';

/// Catálogo inicial de serviços e produtos do mercado de festas.
///
/// IDs já existentes no Firestore são preservados para não quebrar
/// vínculos de fornecedores, fotos e cotações.
class CatalogoServicoProduto {
  CatalogoServicoProduto._();

  static List<ServicoProdutoModel> get itens => [
        // Espaço e Estrutura
        _prod(
          id: '1761875536019',
          idSubcategoria: '1761673211096',
          nome: 'Diária de salão, sítio ou chácara',
          descricao:
              'Locação do espaço por diária, com área gourmet, jardim ou salão.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_chacara_piscina',
          idSubcategoria: '1761673211096',
          nome: 'Chácara com piscina e campo',
          descricao:
              'Espaço rural com piscina, campo, churrasqueira e estacionamento.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_salao_100',
          idSubcategoria: '1761673175394',
          nome: 'Salão para até 100 convidados',
          descricao:
              'Locação de salão climatizado com mesas, cadeiras e cozinha de apoio.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_salao_200',
          idSubcategoria: '1761673175394',
          nome: 'Salão para até 200 convidados',
          descricao:
              'Espaço amplo para recepção, formatura ou festa com palco e pista.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_espaco_casamento',
          idSubcategoria: 'sub_espaco_casamento',
          nome: 'Espaço para cerimônia e recepção',
          descricao:
              'Local com jardim ou capela para cerimônia e salão para o jantar.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_casa_fazenda',
          idSubcategoria: 'sub_espaco_casamento',
          nome: 'Casa de campo para casamento',
          descricao:
              'Propriedade com hospedagem dos noivos, cerimônia ao ar livre e festa.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_buffet_infantil',
          idSubcategoria: 'sub_buffet_infantil_espaco',
          nome: 'Buffet infantil com brinquedoteca',
          descricao:
              'Espaço com playground, monitoria e salão para aniversário infantil.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_espaco_kids',
          idSubcategoria: 'sub_buffet_infantil_espaco',
          nome: 'Espaço kids com infláveis',
          descricao:
              'Salão infantil com cama elástica, piscina de bolinhas e recreação.',
          tipoMedida: 'D',
        ),
        _prod(
          id: '1761875593018',
          idSubcategoria: '1761673186978',
          nome: 'Locação de mesa redonda com cadeiras',
          descricao:
              'Mesa para 8 lugares com cadeiras, entrega e recolhimento.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_cadeira_tiffany',
          idSubcategoria: '1761673186978',
          nome: 'Cadeira Tiffany ou medalhão',
          descricao:
              'Cadeira decorativa para cerimônia, jantar ou mesa de bolo.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_jogo_americano',
          idSubcategoria: '1761673218130',
          nome: 'Jogo de toalha, sousplat e guardanapo',
          descricao:
              'Kit de mesa com toalha, sousplat, guardanapo e porta-guardanapo.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_jogo_jantar',
          idSubcategoria: '1761673218130',
          nome: 'Jogo de jantar, taças e talheres',
          descricao:
              'Prato raso, sobremesa, talher completo e taça de vinho por pessoa.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_tenda_10x10',
          idSubcategoria: '1761673195296',
          nome: 'Tenda 10x10 com calha',
          descricao:
              'Tenda piramidal ou chapéu de bruxa com montagem e desmontagem.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_tenda_alongada',
          idSubcategoria: '1761673195296',
          nome: 'Tenda alongada para recepção',
          descricao:
              'Cobertura contínua para buffet, pista ou área de convívio.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_tenda_cristal',
          idSubcategoria: '1761673224551',
          nome: 'Tenda cristal para cerimônia',
          descricao:
              'Tenda transparente para altar, jantar ou cocktail ao ar livre.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_cobertura_passarela',
          idSubcategoria: '1761673224551',
          nome: 'Cobertura de passarela e altar',
          descricao:
              'Estrutura leve para proteger cerimônia em jardim ou praia.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_palco_6x4',
          idSubcategoria: '1761673231215',
          nome: 'Palco 6x4 m para banda ou DJ',
          descricao: 'Palco modular com piso, guarda-corpo e rampa de acesso.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_tablado_cerimonia',
          idSubcategoria: '1761673231215',
          nome: 'Tablado e passarela de cerimônia',
          descricao:
              'Piso elevado para altar, passarela de noiva ou formatura.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_pista_led',
          idSubcategoria: 'sub_pista_danca',
          nome: 'Pista de dança com LED',
          descricao:
              'Pista iluminada com painel de LED no piso, a partir de 4x4 m.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_pista_madeira',
          idSubcategoria: 'sub_pista_danca',
          nome: 'Pista de dança em taco ou vinílico',
          descricao:
              'Piso elevado para pista, com fita e acabamento nas bordas.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_gerador_45',
          idSubcategoria: '1761673202507',
          nome: 'Gerador 45 kVA silenciado',
          descricao:
              'Gerador com operador, cabo e proteção para som e iluminação.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_quadro_energia',
          idSubcategoria: '1761673202507',
          nome: 'Quadro de energia e distribuição',
          descricao:
              'Distribuição elétrica temporária para tendas, palco e buffet.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_ar_split',
          idSubcategoria: 'sub_climatizacao',
          nome: 'Ar-condicionado split para salão',
          descricao:
              'Locação e instalação de splits para climatizar o espaço da festa.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_climatizador',
          idSubcategoria: 'sub_climatizacao',
          nome: 'Climatizador evaporativo',
          descricao: 'Climatizador de grande porte para área externa ou tenda.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_banheiro_luxo',
          idSubcategoria: 'sub_banheiros_quimicos',
          nome: 'Banheiro químico luxo',
          descricao:
              'Cabine com pia, espelho, papel e reposição durante o evento.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_banheiro_duplo',
          idSubcategoria: 'sub_banheiros_quimicos',
          nome: 'Banheiro químico duplo (feminino e masculino)',
          descricao:
              'Conjunto de cabines identificadas, com higienização no local.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_choppeira',
          idSubcategoria: 'sub_freezer_chopp',
          nome: 'Choppeira 2 torneiras com barril',
          descricao:
              'Choppeira gelada, extração e cilindro de CO2 para a festa.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_freezer_bebida',
          idSubcategoria: 'sub_freezer_chopp',
          nome: 'Freezer e máquina de gelo',
          descricao:
              'Freezer horizontal, refrigerador e máquina de gelo para o bar.',
          tipoMedida: 'D',
        ),

        // Buffet e Gastronomia
        _prod(
          id: '1761927003652',
          idSubcategoria: 'd53c30bf-e790-4849-b40f-40358e90af68',
          nome: 'Buffet completo jantar ou coquetel',
          descricao:
              'Entrada, prato principal, sobremesa e serviço de garçons por pessoa.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_buffet_casamento',
          idSubcategoria: 'd53c30bf-e790-4849-b40f-40358e90af68',
          nome: 'Buffet de casamento com estação',
          descricao: 'Menu degustação, estações ao vivo e serviço à francesa.',
          tipoMedida: 'P',
        ),
        _prod(
          id: '1761927027883',
          idSubcategoria: '1761673021428',
          nome: 'Kit cento de salgados e doces',
          descricao:
              'Cento misto de salgados fritos/assados e docinhos tradicionais.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_kit_festa_infantil',
          idSubcategoria: '1761673021428',
          nome: 'Kit festa infantil (salgado, doce e bolo)',
          descricao:
              'Pacote para aniversário com salgados, docinhos e bolo simples.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_cento_fritos',
          idSubcategoria: 'sub_salgados',
          nome: 'Cento de salgados fritos',
          descricao:
              'Coxinha, bolinha de queijo, risoles e similares, fritos na hora ou congelados.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_cento_assados',
          idSubcategoria: 'sub_salgados',
          nome: 'Cento de salgados assados',
          descricao: 'Empada, esfirra, mini pizza, quiche e folhados.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_cento_brigadeiro',
          idSubcategoria: 'sub_doces_brigadeiros',
          nome: 'Cento de brigadeiros gourmet',
          descricao:
              'Brigadeiro, beijinho, casadinho e sabores especiais em forminha.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_bem_casado',
          idSubcategoria: 'sub_doces_brigadeiros',
          nome: 'Bem-casados e mesa de doces',
          descricao:
              'Bem-casado, camafeu, macaron e montagem da mesa de doces.',
          tipoMedida: 'U',
        ),
        _prod(
          id: '1761928125187',
          idSubcategoria: '1761673028470',
          nome: 'Bolo de festa em andares',
          descricao:
              'Bolo recheado com pasta americana ou chantininho, cobrado por kg.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_mesa_bolo',
          idSubcategoria: '1761673028470',
          nome: 'Mesa de bolo, tortas e sobremesas',
          descricao:
              'Bolo principal, mini tortas, pavê e sobremesas individuais.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_bolo_cenografico',
          idSubcategoria: 'sub_confeitaria',
          nome: 'Bolo cenográfico e fake cake',
          descricao:
              'Bolo cenográfico para fotos, com fatia real para o corte.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_cupcake',
          idSubcategoria: 'sub_confeitaria',
          nome: 'Cupcakes e cake pops personalizados',
          descricao:
              'Doces modelados no tema da festa, com toppers e cores combinando.',
          tipoMedida: 'U',
        ),
        _prod(
          id: '1761928156729',
          idSubcategoria: '1761673040023',
          nome: 'Kit bebidas (refri, suco e água)',
          descricao:
              'Pacote de refrigerante, suco, água e gelo por quantidade de convidados.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_chopp_barril',
          idSubcategoria: '1761673040023',
          nome: 'Barril de chopp com extração',
          descricao:
              'Barril, choppeira e copos para self-service durante a festa.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_open_bar',
          idSubcategoria: 'sub_bar_open',
          nome: 'Open bar 4 horas',
          descricao:
              'Drinks clássicos, destilados, refrigerante e bartender por pessoa.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_bartender',
          idSubcategoria: 'sub_bar_open',
          nome: 'Estação de drinks com bartender',
          descricao:
              'Bar temático, coquetéis autorais e garnitura para o evento.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_churrasco_pessoa',
          idSubcategoria: 'sub_churrasco',
          nome: 'Churrasco completo por pessoa',
          descricao:
              'Carnes, acompanhamentos, farofa, vinagrete e churrasqueiro.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_espetinho',
          idSubcategoria: 'sub_churrasco',
          nome: 'Estação de espetinhos',
          descricao: 'Espetinho de carne, frango e queijo grelhado na hora.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_foodtruck_4h',
          idSubcategoria: 'sub_food_truck',
          nome: 'Food truck por 4 horas',
          descricao:
              'Hambúrguer, hot dog ou massas no caminhão, com equipe e energia.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_estacao_massa',
          idSubcategoria: 'sub_food_truck',
          nome: 'Estação de massas ou pizza',
          descricao:
              'Pasta ou pizza na pedra preparada ao vivo para os convidados.',
          tipoMedida: 'P',
        ),
        _prod(
          id: '1761928171481',
          idSubcategoria: '1761673081975',
          nome: 'Carrinho de pipoca, algodão-doce e churros',
          descricao:
              'Carrinhos temáticos com operador, embalagem e insumos da festa.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_carrinho_crepe',
          idSubcategoria: '1761673081975',
          nome: 'Carrinho de crepe ou hot dog',
          descricao:
              'Estação itinerante com cardápio curto e atendimento contínuo.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_coffee_pessoa',
          idSubcategoria: 'sub_coffee_break',
          nome: 'Coffee break por pessoa',
          descricao:
              'Café, suco, mini sanduíche, bolo e frutas para intervalo ou manhã.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_brunch',
          idSubcategoria: 'sub_coffee_break',
          nome: 'Brunch e mesa de frios',
          descricao: 'Queijos, frios, pães, iogurte, granola e sucos naturais.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_carrinho_acai',
          idSubcategoria: 'sub_sorvete',
          nome: 'Carrinho de açaí e complementos',
          descricao: 'Açaí, granola, leite condensado, frutas e embalagens.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_carrinho_sorvete',
          idSubcategoria: 'sub_sorvete',
          nome: 'Carrinho de sorvete e paletas',
          descricao:
              'Sorvete de massa, paleta mexicana ou gelato para a festa.',
          tipoMedida: 'D',
        ),

        // Decoração
        _prod(
          id: '1761884685166',
          idSubcategoria: '1761673391822',
          nome: 'Decoração temática completa',
          descricao:
              'Projeto de ambientação infantil, casamento, 15 anos ou corporativo.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_decor_mesa_principal',
          idSubcategoria: '1761673391822',
          nome: 'Decoração de mesa principal e bolo',
          descricao:
              'Mesa do bolo, doces e lembranças com tecido, flores e iluminação.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_projeto_exclusivo',
          idSubcategoria: '1761672773772',
          nome: 'Projeto exclusivo de ambientação',
          descricao:
              'Moodboard, paleta, planta baixa e execução personalizada do espaço.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_decor_cerimonia',
          idSubcategoria: '1761672773772',
          nome: 'Ambientação de cerimônia personalizada',
          descricao:
              'Altar, cadeiras, caminho e detalhes no estilo dos noivos.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_buque_noiva',
          idSubcategoria: '3bc4092c-435f-4bc6-be39-de0e94ef8e50',
          nome: 'Buquê da noiva e corsage',
          descricao: 'Buquê, réplica, boutonniere do noivo e flores de lapela.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_arranjo_mesa',
          idSubcategoria: '3bc4092c-435f-4bc6-be39-de0e94ef8e50',
          nome: 'Arranjo floral de centro de mesa',
          descricao: 'Arranjo baixo ou alto em vaso, com flores da estação.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_arco_floral',
          idSubcategoria: '1761673407907',
          nome: 'Arco floral para altar',
          descricao:
              'Arco ou painel de flores naturais para cerimônia e fotos.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_caminho_petalas',
          idSubcategoria: '1761673407907',
          nome: 'Caminho de pétalas e arranjos de entrada',
          descricao: 'Pétalas, lanternas e arranjos laterais da passarela.',
          tipoMedida: 'P',
        ),
        _prod(
          id: '1761675100047',
          idSubcategoria: '1761673400239',
          nome: 'Montagem de painel e arco de balões',
          descricao:
              'Painel de festa com nome, idade ou monograma e arco orgânico.',
          tipoMedida: 'P',
        ),
        _prod(
          id: '1761884716982',
          idSubcategoria: '1761673400239',
          nome: 'Painel 3D com balões',
          descricao: 'Backdrop 3D, números gigantes e coluna de balões.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_arco_organico',
          idSubcategoria: 'sub_balao_arco',
          nome: 'Arco orgânico de balões',
          descricao:
              'Arco irregular com cores do tema, para entrada ou mesa do bolo.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_numero_balao',
          idSubcategoria: 'sub_balao_arco',
          nome: 'Número ou letra gigante de balões',
          descricao:
              'Idade, iniciais dos noivos ou sigla da empresa em balloon mosaic.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_locacao_pecas',
          idSubcategoria: '1761672923479',
          nome: 'Locação de peças decorativas',
          descricao: 'Vasos, bandejas, lanternas, livros e objetos de cena.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_luminaria_decor',
          idSubcategoria: '1761672923479',
          nome: 'Luminárias e lanternas decorativas',
          descricao: 'Conjunto de luminárias de chão, pendentes e lanternas.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_lounge',
          idSubcategoria: '4f8f9e9a-7f67-45ca-91f6-4ad6c2885389',
          nome: 'Lounge com sofás e puffs',
          descricao: 'Ambiente de estar com sofá, puff, mesa lateral e tapete.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_mobilia_cerimonia',
          idSubcategoria: '4f8f9e9a-7f67-45ca-91f6-4ad6c2885389',
          nome: 'Mobiliário de cerimônia',
          descricao:
              'Banquetas, bancos, aparador e poltronas para altar e cocktail.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_arco_metal',
          idSubcategoria: '1761673418508',
          nome: 'Arco, pedestal e vaso de cenografia',
          descricao:
              'Estruturas metálicas, pedestais e vasos para composição floral.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_backdrops',
          idSubcategoria: '1761673418508',
          nome: 'Backdrop e cenário para fotos',
          descricao: 'Painel de madeira, tecido ou neon para canto de fotos.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_cordao_luz',
          idSubcategoria: 'sub_iluminacao_decorativa',
          nome: 'Cordão de luz e varal de lâmpadas',
          descricao: 'Iluminação quente para jardim, tenda e área gourmet.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_neon',
          idSubcategoria: 'sub_iluminacao_decorativa',
          nome: 'Letreiro neon personalizado',
          descricao:
              'Frase ou nomes dos noivos em neon para parede ou cavalete.',
          tipoMedida: 'U',
        ),

        // Moda, Vestidos e Trajes
        _prod(
          id: 'prod_aluguel_vestido_noiva',
          idSubcategoria: 'sub_vestido_noiva',
          nome: 'Aluguel de vestido de noiva',
          descricao:
              'Vestido com provas, ajuste básico e retirada na semana do evento.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_venda_vestido_noiva',
          idSubcategoria: 'sub_vestido_noiva',
          nome: 'Venda de vestido de noiva sob medida',
          descricao:
              'Modelagem, tecido, provas e entrega do vestido exclusivo.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_vestido_15',
          idSubcategoria: 'sub_vestido_festa',
          nome: 'Aluguel de vestido de 15 anos',
          descricao: 'Vestido de debutante com anágua, ajuste e prova.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_vestido_madrinha',
          idSubcategoria: 'sub_vestido_festa',
          nome: 'Vestido de festa, formatura ou madrinha',
          descricao:
              'Aluguel ou venda de vestido longo ou midi para ocasião formal.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_terno_noivo',
          idSubcategoria: 'sub_aluguel_terno',
          nome: 'Aluguel de terno ou smoking do noivo',
          descricao:
              'Terno, camisa, gravata, cinto e ajuste da calça e paletó.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_terno_padrinho',
          idSubcategoria: 'sub_aluguel_terno',
          nome: 'Aluguel de terno para padrinhos',
          descricao:
              'Traje social padronizado para padrinhos, pais e pajens adultos.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_roupa_pajem',
          idSubcategoria: 'sub_pajem_daminha',
          nome: 'Traje de pajem',
          descricao: 'Terno infantil, suspensório ou smoking para o cortejo.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_vestido_daminha',
          idSubcategoria: 'sub_pajem_daminha',
          nome: 'Vestido de daminha e florista',
          descricao:
              'Vestido infantil, cinto e acessório combinando com as madrinhas.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_fantasia_tema',
          idSubcategoria: 'sub_fantasia',
          nome: 'Aluguel de fantasia temática',
          descricao: 'Fantasia de personagem, super-herói ou tema da festa.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_caracterizacao',
          idSubcategoria: 'sub_fantasia',
          nome: 'Caracterização e figurino',
          descricao:
              'Figurino completo com maquiagem básica para animação ou teatro.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_veu_tiara',
          idSubcategoria: 'sub_acessorios_moda',
          nome: 'Véu, tiara e joias da noiva',
          descricao: 'Véu, arranjo de cabelo, brinco, colar e clutch.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_sapato_festa',
          idSubcategoria: 'sub_acessorios_moda',
          nome: 'Sapato e acessórios de festa',
          descricao:
              'Sapato, cinto, gravata, abotoadura e bolsa para o evento.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_barra_vestido',
          idSubcategoria: 'sub_costura_ajustes',
          nome: 'Ajuste e barra de vestido',
          descricao:
              'Prova, barra, tomada e reforço de costura no vestido ou terno.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_customizacao',
          idSubcategoria: 'sub_costura_ajustes',
          nome: 'Customização de vestido ou terno',
          descricao: 'Aplicação de renda, bordado, decote ou modelagem extra.',
          tipoMedida: 'U',
        ),

        // Beleza e Estética
        _prod(
          id: '1761875269254',
          idSubcategoria: '1760932672539',
          nome: 'Penteado e produção de cabelo',
          descricao:
              'Penteado de noiva, debutante ou madrinha, com teste prévio.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_penteado_teste',
          idSubcategoria: '1760932672539',
          nome: 'Teste de penteado',
          descricao:
              'Ensaio do penteado antes do evento, com registro em foto.',
          tipoMedida: 'U',
        ),
        _prod(
          id: '1761875398061',
          idSubcategoria: '1761672969508',
          nome: 'Maquiagem social',
          descricao:
              'Make para festa, formatura ou madrinha, com pele e olhos duradouros.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_make_noiva',
          idSubcategoria: '1761672969508',
          nome: 'Maquiagem de noiva com teste',
          descricao: 'Teste + make do dia, incluindo retoque e cílios.',
          tipoMedida: 'P',
        ),
        _prod(
          id: '1761875365937',
          idSubcategoria: '1761672987404',
          nome: 'Corte e barba para noivo e padrinhos',
          descricao:
              'Corte masculino, barba alinhada e finalização no dia do evento.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_barba_noivo',
          idSubcategoria: '1761672987404',
          nome: 'Pacote barbearia do noivo',
          descricao:
              'Corte, barba, sobrancelha e toalha quente no camarim ou salão.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_limpeza_pele',
          idSubcategoria: '1761672978643',
          nome: 'Limpeza de pele pré-evento',
          descricao:
              'Limpeza, hidratação e protocolo para a pele no dia da festa.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_massagem_relax',
          idSubcategoria: '1761672978643',
          nome: 'Massagem relaxante pré-festa',
          descricao:
              'Sessão de massagem para noiva, debutante ou aniversariante.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_manicure_noiva',
          idSubcategoria: 'sub_unhas',
          nome: 'Manicure e pedicure da noiva',
          descricao: 'Esmaltação em gel, nail art e spa dos pés para o evento.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_nail_art',
          idSubcategoria: 'sub_unhas',
          nome: 'Nail art e alongamento',
          descricao: 'Alongamento, fibra ou gel com desenho no tema da festa.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_dia_noiva',
          idSubcategoria: 'sub_dia_noiva',
          nome: 'Pacote dia da noiva',
          descricao:
              'Cabelo, make, unhas, café da manhã e camarim no local do evento.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_spa_noiva',
          idSubcategoria: 'sub_dia_noiva',
          nome: 'Spa da noiva com acompanhantes',
          descricao:
              'Produção da noiva mais madrinhas ou mãe, no salão ou hotel.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_design_sobrancelha',
          idSubcategoria: 'sub_sobrancelha',
          nome: 'Design de sobrancelha',
          descricao: 'Alinhamento, henna ou tintura para o dia da festa.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_henna',
          idSubcategoria: 'sub_sobrancelha',
          nome: 'Henna e micropigmentação',
          descricao:
              'Preenchimento temporário ou semipermanente das sobrancelhas.',
          tipoMedida: 'U',
        ),

        // Fotografia e Filmagem
        _prod(
          id: 'prod_cobertura_foto',
          idSubcategoria: '8847a156-8823-4733-9c0e-69d94531d92a',
          nome: 'Cobertura fotográfica completa',
          descricao:
              'Making of, cerimônia, festa e galeria digital com tratamento.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_foto_hora',
          idSubcategoria: '8847a156-8823-4733-9c0e-69d94531d92a',
          nome: 'Fotógrafo por hora',
          descricao:
              'Cobertura avulsa para aniversário, chá de bebê ou corporativo.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_filme_evento',
          idSubcategoria: '1761673592400',
          nome: 'Filme do evento e trailer',
          descricao:
              'Captação, edição, trailer e filme longo em Full HD ou 4K.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_same_day',
          idSubcategoria: '1761673592400',
          nome: 'Same day edit',
          descricao: 'Clipe editado e exibido ainda durante a festa.',
          tipoMedida: 'P',
        ),
        _prod(
          id: '1761675196036',
          idSubcategoria: '1761673598981',
          nome: 'Cabine de fotos com moldura personalizada',
          descricao:
              'Cabine, recorte instantâneo, atendente e fundo personalizado.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_totem_fotos',
          idSubcategoria: '1761673598981',
          nome: 'Totem de fotos instantâneas',
          descricao: 'Totem touch, impressão 10x15 e GIFs para redes sociais.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_drone_cerimonia',
          idSubcategoria: 'sub_drone',
          nome: 'Filmagem aérea com drone',
          descricao:
              'Sobrevoo da cerimônia, espaço e convidados, com piloto credenciado.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_drone_making',
          idSubcategoria: 'sub_drone',
          nome: 'Pacote drone making of + festa',
          descricao: 'Imagens aéreas do making of, chegada e final da festa.',
          tipoMedida: 'P',
        ),
        _prod(
          id: '9d95c062-dc90-45e3-a2e6-cc620842059f',
          idSubcategoria: 'sub_ensaio',
          nome: 'Ensaio pré-evento',
          descricao:
              'Pre-wedding, smash the cake, gestante ou ensaio da família.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_smash_cake',
          idSubcategoria: 'sub_ensaio',
          nome: 'Smash the cake',
          descricao: 'Ensaio de 1 ano com bolo, cenário e galeria tratada.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_plataforma_360',
          idSubcategoria: 'sub_plataforma_360',
          nome: 'Plataforma 360',
          descricao:
              'Vídeo em 360 graus, slow motion e compartilhamento no celular.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_slow_motion',
          idSubcategoria: 'sub_plataforma_360',
          nome: 'Cabine slow motion',
          descricao:
              'Vídeo em câmera lenta com props e música escolhida pelos noivos.',
          tipoMedida: 'D',
        ),

        // Música e Iluminação
        _prod(
          id: 'bac73f82-319d-44b5-9359-7b5e7674cc1c',
          idSubcategoria: 'sub_dj',
          nome: 'DJ para festa e casamento',
          descricao:
              'DJ com notebook, controlador e playlist alinhada ao evento.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_dj_4h',
          idSubcategoria: 'sub_dj',
          nome: 'DJ 4 horas com cerimônia e festa',
          descricao: 'Som da cerimônia, cocktail e pista até o encerramento.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_banda_4h',
          idSubcategoria: '1761673760258',
          nome: 'Banda ao vivo 4 horas',
          descricao: 'Banda completa com repertório pop, sertanejo ou axé.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_orquestra',
          idSubcategoria: '1761673760258',
          nome: 'Músicos para cerimônia',
          descricao: 'Quarteto de cordas, harpa, sax ou coral para a entrada.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_voz_violao',
          idSubcategoria: 'sub_voz_violao',
          nome: 'Voz e violão para cocktail',
          descricao: 'Música ambiente no coquetel, jantar ou cerimônia íntima.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_sertanejo_mpb',
          idSubcategoria: 'sub_voz_violao',
          nome: 'Duo MPB ou sertanejo',
          descricao: 'Dois músicos com repertório brasileiro para recepção.',
          tipoMedida: 'H',
        ),
        _prod(
          id: '1761675638299',
          idSubcategoria: '1761673777692',
          nome: 'Locação de caixas de som e microfones',
          descricao: 'PA, microfone sem fio, mesa e técnico de som.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_som_cerimonia',
          idSubcategoria: '1761673777692',
          nome: 'Som para cerimônia',
          descricao:
              'Caixas discretas, microfone de lapela e playlist da entrada.',
          tipoMedida: 'D',
        ),
        _prod(
          id: '1761675661136',
          idSubcategoria: '1761673797647',
          nome: 'Iluminação de pista e ambientação',
          descricao:
              'Moving light, par LED, mini laser e operação durante a festa.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_luz_arquitetural',
          idSubcategoria: '1761673797647',
          nome: 'Iluminação arquitetural do espaço',
          descricao: 'Wash de parede, jardim, fachada e mesa dos noivos.',
          tipoMedida: 'D',
        ),
        _prod(
          id: '1761675682833',
          idSubcategoria: 'sub_efeitos_especiais',
          nome: 'Máquina de fumaça e laser',
          descricao: 'Fumaça baixa ou alta, laser e efeitos de pista.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_sparkle',
          idSubcategoria: 'sub_efeitos_especiais',
          nome: 'Sparkle e chuva de prata',
          descricao:
              'Efeito de faísca fria para entrada, brinde ou última música.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_karaoke',
          idSubcategoria: 'sub_karaoke',
          nome: 'Karaokê com telão e microfones',
          descricao: 'Aparelho, repertório, dois microfones e operador.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_karaoke_animado',
          idSubcategoria: 'sub_karaoke',
          nome: 'Karaokê com animador',
          descricao: 'Equipamento mais animador para puxar o público.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_animador_pista',
          idSubcategoria: 'sub_animacao_pista',
          nome: 'Animador de pista',
          descricao:
              'Mestre de pista, brincadeiras e interação com os convidados.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_atração_pista',
          idSubcategoria: 'sub_animacao_pista',
          nome: 'Atração para agitar a pista',
          descricao: 'Sax na pista, percussionista ou dançarinos temáticos.',
          tipoMedida: 'H',
        ),

        // Recreação e Entretenimento
        _prod(
          id: 'prod_recreacao_2h',
          idSubcategoria: 'sub_recreacao_infantil',
          nome: 'Recreação infantil 2 horas',
          descricao: 'Dupla de recreadores, brincadeiras e kit lúdico.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_monitoria',
          idSubcategoria: 'sub_recreacao_infantil',
          nome: 'Monitoria kids durante a festa',
          descricao:
              'Monitores para espaço kids, com seguro e lista de presença.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_personagem_vivo',
          idSubcategoria: 'sub_personagens_vivos',
          nome: 'Personagem vivo 1 hora',
          descricao: 'Princesa, herói ou mascote com interação e fotos.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_personagem_pacote',
          idSubcategoria: 'sub_personagens_vivos',
          nome: 'Pacote 2 personagens',
          descricao: 'Dois personagens no tema da festa, com troca e fotos.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_magico',
          idSubcategoria: 'sub_magico_palhaco',
          nome: 'Show de mágica 40 minutos',
          descricao:
              'Mágico close-up ou palco, adequado para crianças e adultos.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_palhaco',
          idSubcategoria: 'sub_magico_palhaco',
          nome: 'Palhaço e pintura facial',
          descricao:
              'Animação, balões palhaço e pintura no rosto das crianças.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_pula_pula',
          idSubcategoria: 'sub_inflaveis',
          nome: 'Cama elástica / pula-pula',
          descricao: 'Inflável com motor, tapete e monitor durante o uso.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_toboga',
          idSubcategoria: 'sub_inflaveis',
          nome: 'Tobogã inflável',
          descricao: 'Tobogã de escorrega com montagem, energia e operador.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_piscina_bolinhas',
          idSubcategoria: 'sub_piscina_bolinhas',
          nome: 'Piscina de bolinhas',
          descricao: 'Piscina com bolinhas higienizadas e cerca de proteção.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_touro_mecanico',
          idSubcategoria: 'sub_piscina_bolinhas',
          nome: 'Touro mecânico ou futebol de sabão',
          descricao:
              'Atração inflável para adolescentes e adultos, com operador.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_oficina_slime',
          idSubcategoria: 'sub_oficina_festas',
          nome: 'Oficina de slime',
          descricao:
              'Atividade supervisionada com material incluso e lembrancinha.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_oficina_pintura',
          idSubcategoria: 'sub_oficina_festas',
          nome: 'Oficina de pintura e biscuit',
          descricao: 'Mesa de atividades com tinta, avental e peça para levar.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_fliperama',
          idSubcategoria: 'sub_fliperama',
          nome: 'Fliperama e videogame',
          descricao: 'Máquinas arcade, pebolim ou consoles para o salão.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_mesa_jogos',
          idSubcategoria: 'sub_fliperama',
          nome: 'Mesa de jogos e karaokê recreativo',
          descricao: 'Jogos de tabuleiro gigante, pebolim e karaokê kids.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_cassino',
          idSubcategoria: 'sub_atracoes_adultas',
          nome: 'Cassino de premiação',
          descricao:
              'Mesas de blackjack, roleta e fichas para animação adulta.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_photobooth',
          idSubcategoria: 'sub_atracoes_adultas',
          nome: 'Photobooth e experiências',
          descricao: 'Cabine, props e ativação de marca ou festa adulta.',
          tipoMedida: 'D',
        ),

        // Transporte
        _prod(
          id: 'prod_carro_noiva',
          idSubcategoria: '1761673306202',
          nome: 'Carro clássico para a noiva',
          descricao:
              'Carro vintage ou conversível, motorista fardado e decoração simples.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_carro_noiva_ida_volta',
          idSubcategoria: '1761673306202',
          nome: 'Carro da noiva ida e volta',
          descricao: 'Busca no making of, cerimônia e traslado até a festa.',
          tipoMedida: 'P',
        ),
        _prod(
          id: '1761875667928',
          idSubcategoria: '1761673288334',
          nome: 'Carro de luxo com decoração',
          descricao:
              'Sedan ou SUV premium, motorista e arranjo floral no capô.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_carro_importado',
          idSubcategoria: '1761673288334',
          nome: 'Carro importado para ensaio ou festa',
          descricao: 'Modelo esportivo ou de luxo para fotos e cortejo.',
          tipoMedida: 'D',
        ),
        _prod(
          id: '1761875630569',
          idSubcategoria: '1761673280167',
          nome: 'Motorista particular / executivo',
          descricao:
              'Motorista de terno, veículo executivo e horas à disposição.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_executivo_hora',
          idSubcategoria: '1761673280167',
          nome: 'Traslado executivo por hora',
          descricao: 'Deslocamento pontual de noivos, padrinhos ou executivos.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_traslado_convidados',
          idSubcategoria: '1761673318403',
          nome: 'Traslado de convidados',
          descricao: 'Ida e volta entre hotel, igreja e salão, com auxiliar.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_shuttle_festa',
          idSubcategoria: '1761673318403',
          nome: 'Shuttle contínuo da festa',
          descricao: 'Van circulando em horários fixos até o fim do evento.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_van_15',
          idSubcategoria: '1761673297233',
          nome: 'Van 15 lugares',
          descricao: 'Van executiva com ar, motorista e água para o grupo.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_microonibus',
          idSubcategoria: '1761673297233',
          nome: 'Micro-ônibus 28 lugares',
          descricao:
              'Micro-ônibus para padrinhos, família ou turma da formatura.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_van_corporativa',
          idSubcategoria: '1761673325402',
          nome: 'Van para evento corporativo',
          descricao:
              'Traslado de equipes entre hotel, centro de convenções e jantar.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_fretamento_congresso',
          idSubcategoria: '1761673325402',
          nome: 'Fretamento para congresso',
          descricao:
              'Frota com coordenador de embarque e identificação dos grupos.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_limousine',
          idSubcategoria: 'sub_limousine',
          nome: 'Limousine para noivos ou debutante',
          descricao: 'Limousine stretch, som, iluminação e motorista.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_limousine_despedida',
          idSubcategoria: 'sub_limousine',
          nome: 'Limousine para despedida de solteiro',
          descricao: 'Percurso noturno com gelo, som e itinerário combinado.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_party_bus',
          idSubcategoria: 'sub_party_bus',
          nome: 'Ônibus de festa / party bus',
          descricao: 'Ônibus com som, luz, bar e pista para o cortejo.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_onibus_formatura',
          idSubcategoria: 'sub_party_bus',
          nome: 'Ônibus da formatura',
          descricao: 'Fretamento temático da turma, com playlist e iluminação.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_transfer_aeroporto',
          idSubcategoria: 'sub_transfer_aeroporto',
          nome: 'Transfer aeroporto / hotel',
          descricao: 'Receptivo com plaquinha, água e veículo executivo.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_receptivo_padrinhos',
          idSubcategoria: 'sub_transfer_aeroporto',
          nome: 'Receptivo de padrinhos e família',
          descricao:
              'Vários embarques no aeroporto com coordenação de horários.',
          tipoMedida: 'P',
        ),

        // Papelaria e Lembranças
        _prod(
          id: '1761884436433',
          idSubcategoria: '1761673447533',
          nome: 'Convite impresso com acabamento especial',
          descricao:
              'Convite em papel especial, envelope, lacre e impressão offset ou letterpress.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_kit_papelaria',
          idSubcategoria: '1761673447533',
          nome: 'Kit papelaria do convite',
          descricao: 'Convite, save the date, mapa e tag de agradecimento.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_convite_digital',
          idSubcategoria: '1761673499234',
          nome: 'Convite digital animado',
          descricao: 'Vídeo ou card interativo com RSVP para WhatsApp.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_site_evento',
          idSubcategoria: '1761673499234',
          nome: 'Site do evento com RSVP',
          descricao:
              'Página com história, lista de presentes, mapa e confirmação.',
          tipoMedida: 'P',
        ),
        _prod(
          id: '1761884482694',
          idSubcategoria: '1761673454745',
          nome: 'Tags e toppers personalizados',
          descricao:
              'Topper de doce, tag de lembrança, menu e plaquinha de mesa.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_menu_mesa',
          idSubcategoria: '1761673454745',
          nome: 'Menu, número de mesa e plaquinhas',
          descricao: 'Papelaria de mesa com identidade visual do evento.',
          tipoMedida: 'U',
        ),
        _prod(
          id: '1761884500077',
          idSubcategoria: '1761673463610',
          nome: 'Lembrancinha temática',
          descricao:
              'Sachê, vela, suculenta, doce ou item sustentável personalizado.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_lembranca_kids',
          idSubcategoria: '1761673463610',
          nome: 'Lembrancinha infantil',
          descricao: 'Kit massinha, giz de cera, slime ou brinquedo no tema.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_kit_padrinho',
          idSubcategoria: 'sub_lembranca_padrinhos',
          nome: 'Kit padrinhos e madrinhas',
          descricao: 'Caixa, taça, robe, gravata ou joia com cartão de pedido.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_presente_pais',
          idSubcategoria: 'sub_lembranca_padrinhos',
          nome: 'Presente para pais e avós',
          descricao: 'Quadro, toalha bordada ou caixa de memórias.',
          tipoMedida: 'U',
        ),
        _prod(
          id: '1761884518309',
          idSubcategoria: '1761673472809',
          nome: 'Álbum e livro de assinaturas',
          descricao:
              'Álbum encadernado, polaroids e livro para recados dos convidados.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_fotolivro',
          idSubcategoria: '1761673472809',
          nome: 'Fotolivro do evento',
          descricao:
              'Livro fotográfico capa dura com diagramação profissional.',
          tipoMedida: 'U',
        ),
        _prod(
          id: 'prod_logo_festa',
          idSubcategoria: 'sub_identidade_visual',
          nome: 'Logo e identidade visual da festa',
          descricao: 'Monograma, paleta, tipografia e aplicações básicas.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_kit_identidade',
          idSubcategoria: 'sub_identidade_visual',
          nome: 'Kit identidade completa',
          descricao: 'Logo, convite, menu, tag, hashtag e guia de uso.',
          tipoMedida: 'P',
        ),

        // Assessoria e Produção
        _prod(
          id: '1761676002265',
          idSubcategoria: '1761674078610',
          nome: 'Cerimonial completo',
          descricao:
              'Equipe no dia, checklist, briefing de fornecedores e condução da cerimônia.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_cerimonial_hora',
          idSubcategoria: '1761674078610',
          nome: 'Cerimonial por hora',
          descricao:
              'Cerimonialista avulsa para eventos menores ou complementares.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_assessoria_completa',
          idSubcategoria: '1761674113077',
          nome: 'Assessoria completa de festa',
          descricao:
              'Planejamento, cotação de fornecedores, visitas e dia do evento.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_assessoria_parcial',
          idSubcategoria: '1761674113077',
          nome: 'Assessoria parcial / últimos 30 dias',
          descricao: 'Organização do trâmite final, confirmações e cerimonial.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_producao_evento',
          idSubcategoria: '1761674096559',
          nome: 'Produção e organização do evento',
          descricao:
              'Cronograma, planta, equipe de apoio e acompanhamento de montagem.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_gestao_fornecedores',
          idSubcategoria: '1761674096559',
          nome: 'Gestão de fornecedores',
          descricao:
              'Contratos, prazos, briefing técnico e conferência no dia.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_wedding_planner',
          idSubcategoria: 'sub_wedding_planner',
          nome: 'Wedding planner completo',
          descricao:
              'Conceito, orçamento, fornecedores, ensaios e coordenação do casamento.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_consultoria_casamento',
          idSubcategoria: 'sub_wedding_planner',
          nome: 'Consultoria de casamento',
          descricao:
              'Pacote de reuniões para orientar decisões sem execução total.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_mestre_cerimonias',
          idSubcategoria: 'sub_mestre_cerimonias',
          nome: 'Mestre de cerimônias',
          descricao: 'Condução das falas, brinde, valsa e anúncios oficiais.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_apresentador_festa',
          idSubcategoria: 'sub_mestre_cerimonias',
          nome: 'Apresentador da festa',
          descricao:
              'Apresentação da debutante, formatura ou premiação corporativa.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_coordenacao_dia',
          idSubcategoria: 'sub_coordenacao_dia',
          nome: 'Coordenação apenas no dia',
          descricao:
              'Equipe no local para executar o roteiro já definido pelos noivos.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_coordenacao_montagem',
          idSubcategoria: 'sub_coordenacao_dia',
          nome: 'Coordenação de montagem e desmontagem',
          descricao:
              'Acompanhamento de fornecedores na montagem e no encerramento.',
          tipoMedida: 'D',
        ),

        // Formaturas e Eventos Corporativos
        _prod(
          id: '1761884805538',
          idSubcategoria: '1761674254303',
          nome: 'Kit audiovisual (som, luz e projeção)',
          descricao:
              'PA, microfone, projetor ou TV e operador para palestra ou formatura.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_traducao_simultanea',
          idSubcategoria: '1761674254303',
          nome: 'Tradução e apoio de palco',
          descricao: 'Cabine, receptores, técnico e apoio ao palestrante.',
          tipoMedida: 'D',
        ),
        _prod(
          id: '1761884839631',
          idSubcategoria: 'd3c555da-6491-424c-8d57-4db07188cc9e',
          nome: 'Palco e estrutura para formatura',
          descricao: 'Palco, backdrop, púlpito, tapete e guarda-corpo.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_camarim_palco',
          idSubcategoria: 'd3c555da-6491-424c-8d57-4db07188cc9e',
          nome: 'Camarim e apoio de palco',
          descricao: 'Camarim montado, água, ferro de passar e staff de palco.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_painel_led',
          idSubcategoria: 'sub_painel_led',
          nome: 'Painel de LED P3',
          descricao: 'Painel indoor, processador, conteúdo e técnico.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_telao',
          idSubcategoria: 'sub_painel_led',
          nome: 'Telão e projetor',
          descricao: 'Projeção em telão com notebook e operador de conteúdo.',
          tipoMedida: 'D',
        ),
        _prod(
          id: '1761884862181',
          idSubcategoria: '1761674269687',
          nome: 'Buffet corporativo e coquetel',
          descricao:
              'Finger food, canapés, bebidas e serviço para convenção ou formatura.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_jantar_executivo',
          idSubcategoria: '1761674269687',
          nome: 'Jantar executivo',
          descricao:
              'Menu empratado ou buffet premium para diretoria e convidados.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_coffee_corporativo',
          idSubcategoria: 'sub_coffee_corporativo',
          nome: 'Coffee break corporativo',
          descricao:
              'Duas estações (manhã e tarde) com salgados, bolo e bebidas quentes.',
          tipoMedida: 'P',
        ),
        _prod(
          id: 'prod_station_cafe',
          idSubcategoria: 'sub_coffee_corporativo',
          nome: 'Station de café e networking',
          descricao:
              'Barista, espresso, cappuccino e mini doces para intervalo.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_credenciamento',
          idSubcategoria: 'sub_credenciamento',
          nome: 'Credenciamento e crachá',
          descricao: 'Balcão, impressão de crachá, fila e equipe de recepção.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_kit_participante',
          idSubcategoria: 'sub_credenciamento',
          nome: 'Kit do participante',
          descricao: 'Sacola, bloco, caneta, crachá e material do evento.',
          tipoMedida: 'U',
        ),

        // Segurança e Apoio
        _prod(
          id: 'prod_seguranca_evento',
          idSubcategoria: 'sub_seguranca',
          nome: 'Segurança patrimonial do evento',
          descricao:
              'Agentes uniformizados, controle de acesso e ronda no espaço.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_portaria',
          idSubcategoria: 'sub_seguranca',
          nome: 'Controle de portaria e lista',
          descricao: 'Conferência de lista, pulseira e apoio na entrada.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_brigada',
          idSubcategoria: 'sub_brigada',
          nome: 'Brigadista e primeiros socorros',
          descricao: 'Profissional com kit de emergência e plano de abandono.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_ambulancia',
          idSubcategoria: 'sub_brigada',
          nome: 'Apoio médico no evento',
          descricao: 'Técnico de enfermagem ou ambulância de standby.',
          tipoMedida: 'D',
        ),
        _prod(
          id: 'prod_recepcionista',
          idSubcategoria: 'sub_recepcionistas',
          nome: 'Recepcionista / hostess',
          descricao: 'Recepção, lista de convidados e indicação de mesa.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_cerimonial_entrada',
          idSubcategoria: 'sub_recepcionistas',
          nome: 'Equipe de boas-vindas',
          descricao:
              'Hostess na entrada, guarda-volumes e orientação de fluxo.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_garcom',
          idSubcategoria: 'sub_garcons',
          nome: 'Garçom para serviço de mesa',
          descricao:
              'Serviço de jantar, coquetel ou champagne, uniforme incluso.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_copeira',
          idSubcategoria: 'sub_garcons',
          nome: 'Copeira e apoio de copa',
          descricao:
              'Organização de copa, reposição e lavagem de louça no evento.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_valet',
          idSubcategoria: 'sub_manobrista',
          nome: 'Manobrista / valet',
          descricao: 'Equipe de valet, ticket e organização do estacionamento.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_estacionamento',
          idSubcategoria: 'sub_manobrista',
          nome: 'Organização de estacionamento',
          descricao: 'Orientadores de vaga, cones e fluxo de entrada e saída.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_limpeza_durante',
          idSubcategoria: 'sub_limpeza',
          nome: 'Limpeza durante o evento',
          descricao: 'Equipe para banheiros, salão e reposição de insumos.',
          tipoMedida: 'H',
        ),
        _prod(
          id: 'prod_limpeza_pos',
          idSubcategoria: 'sub_limpeza',
          nome: 'Limpeza pré e pós-festa',
          descricao: 'Faxina completa antes da montagem e após a desmontagem.',
          tipoMedida: 'D',
        ),
      ];
}

ServicoProdutoModel _prod({
  required String id,
  required String idSubcategoria,
  required String nome,
  required String descricao,
  required String tipoMedida,
}) {
  return ServicoProdutoModel(
    id: id,
    nome: nome,
    descricao: descricao,
    idSubcategoria: idSubcategoria,
    tipoMedida: tipoMedida,
    ativo: true,
  );
}
