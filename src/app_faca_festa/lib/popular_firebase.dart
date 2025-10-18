// ignore_for_file: unused_element

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import './data/models/model.dart';

final _uuid = Uuid();
final _db = FirebaseFirestore.instance;

/// Executa a carga de dados iniciais no Firestore
Future<void> popularFirebase() async {
  //await _inserirTiposDeEvento();
  //await _inserirEstadosECidades();
  //await _inserirInspiracoes();
  //await inserirPostsComunidade();
}

Future<void> _inserirTiposDeEvento() async {
  final tipos = [
    {'nome': 'Casamento', 'emoji': '💍', 'cor': Colors.pinkAccent},
    {'nome': 'Festa Infantil', 'emoji': '🎈', 'cor': Colors.orangeAccent},
    {'nome': 'Chá de Bebê', 'emoji': '🍼', 'cor': Colors.lightBlueAccent},
    {'nome': 'Aniversário', 'emoji': '🎂', 'cor': Colors.purpleAccent},
  ];

  for (var tipo in tipos) {
    final model = TipoEventoModel(
      idTipoEvento: _uuid.v4(),
      nome: '${tipo['emoji']} ${tipo['nome']}',
    );
    await _db.collection('tipo_evento').doc(model.idTipoEvento).set(model.toMap());
  }
}

Future<void> inserirPostsComunidade() async {
  final posts = [
    {
      'autor': 'Ana Lima',
      'texto':
          'Decoração rústica para casamento ao ar livre 🌿✨\nUsei tons de verde, madeira natural e flores do campo. Super romântico e econômico!',
      'imagem': 'https://images.unsplash.com/photo-1521334884684-d80222895322',
      'curtidas': 48,
      'data': Timestamp.now(),
    },
    {
      'autor': 'Pedro Santos',
      'texto':
          'Top 5 lembrancinhas sustentáveis 🎁🌱\n1️⃣ Suculentas em potinhos reciclados\n2️⃣ Velas artesanais naturais\n3️⃣ Docinhos orgânicos\n4️⃣ Sabonetes caseiros\n5️⃣ Mini temperos plantáveis',
      'imagem': 'https://images.unsplash.com/photo-1504208434309-cb69f4fe52b0',
      'curtidas': 76,
      'data': Timestamp.now(),
    },
    {
      'autor': 'Marina Costa',
      'texto':
          'Fiz meu chá de bebê com o tema “Ursinhos no Bosque” 🧸🌲💛\nA decoração foi toda feita à mão! As mães amaram as lembrancinhas personalizadas.',
      'imagem': 'https://images.unsplash.com/photo-1615461066841-6116e6f6d1b0',
      'curtidas': 63,
      'data': Timestamp.now(),
    },
    {
      'autor': 'Lucas Oliveira',
      'texto':
          '🎉 Dica de som para festas pequenas: uma playlist com batidas leves e pop nacional funciona super bem.\nEvite caixas muito potentes para não distorcer o som!',
      'imagem': 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91',
      'curtidas': 22,
      'data': Timestamp.now(),
    },
    {
      'autor': 'Carla Mendes',
      'texto':
          '💐 Arranjos simples e baratos para festas de aniversário!\nUse garrafas de vidro e flores secas — o resultado é lindo e minimalista.',
      'imagem': 'https://images.unsplash.com/photo-1587270613304-4f1b46e07c4e',
      'curtidas': 89,
      'data': Timestamp.now(),
    },
  ];

  final db = FirebaseFirestore.instance;
  final batch = db.batch();

  for (final p in posts) {
    final docRef = db.collection('posts').doc();
    batch.set(docRef, p);
  }

  await batch.commit();
}

Future<void> _inserirInspiracoes() async {
  final inspiracoes = [
    {
      'tipoEvento': 'casamento',
      'titulo': 'Casamento ao pôr do sol na praia',
      'descricao':
          'Cerimônia intimista em tons de areia e azul, com decoração rústica chique e trilha sonora acústica. Ideal para casais que buscam leveza e contato com a natureza.',
      'imagemUrl': 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e',
      'tags': ['praia', 'rústico', 'romântico', 'pôr do sol', 'boho']
    },
    {
      'tipoEvento': 'casamento',
      'titulo': 'Casamento clássico em salão',
      'descricao':
          'Decoração elegante com flores brancas, lustres e tons dourados. Indicado para cerimônias tradicionais e sofisticadas.',
      'imagemUrl': 'https://images.unsplash.com/photo-1524492412937-4961d66aa114',
      'tags': ['clássico', 'luxo', 'flores brancas', 'dourado']
    },
    {
      'tipoEvento': 'aniversario',
      'titulo': 'Festa infantil tema “Selva Encantada”',
      'descricao':
          'Festa colorida e cheia de bichinhos da floresta, ideal para crianças de 3 a 7 anos. Docinhos personalizados e área de recreação temática.',
      'imagemUrl': 'https://images.unsplash.com/photo-1565958011705-44e211c8e8c1',
      'tags': ['infantil', 'selva', 'animal', 'colorido', 'diversão']
    },
    {
      'tipoEvento': 'aniversario',
      'titulo': 'Aniversário adulto “Noite do Vinho”',
      'descricao':
          'Celebração sofisticada com mesa de frios, iluminação aconchegante e degustação de vinhos. Ideal para grupos pequenos.',
      'imagemUrl': 'https://images.unsplash.com/photo-1510626176961-4b37d6af9142',
      'tags': ['adulto', 'vinho', 'aconchegante', 'amigos']
    },
    {
      'tipoEvento': 'cha de bebe',
      'titulo': 'Chá de bebê tema “Ursinhos e Nuvens”',
      'descricao':
          'Decoração em tons de azul bebê e branco, com balões, ursos e docinhos personalizados. Ideal para recepções leves e delicadas.',
      'imagemUrl': 'https://images.unsplash.com/photo-1612197527762-9ff5e4d9a3d5',
      'tags': ['bebê', 'ursinho', 'azul', 'delicado']
    },
    {
      'tipoEvento': 'cha de bebe',
      'titulo': 'Chá revelação “Menino ou Menina?”',
      'descricao':
          'Decoração em rosa e azul, com suspense no momento da revelação. Pode ser feito em casa ou em espaço ao ar livre.',
      'imagemUrl': 'https://images.unsplash.com/photo-1601987077973-55f0b1f61d0f',
      'tags': ['revelação', 'rosa', 'azul', 'balões']
    },
    {
      'tipoEvento': 'natal',
      'titulo': 'Ceia de Natal rústica e acolhedora',
      'descricao':
          'Mesa de jantar com pinhas, velas e tons de vermelho e verde. Sugestão de cardápio simples e decoração DIY.',
      'imagemUrl': 'https://images.unsplash.com/photo-1607083201043-548c6d8a49c3',
      'tags': ['natal', 'rústico', 'velas', 'vermelho', 'verde']
    },
    {
      'tipoEvento': 'ano novo',
      'titulo': 'Réveillon branco e dourado',
      'descricao':
          'Decoração clean com luzes e glitter, ideal para celebrar a virada com estilo. Drinks tropicais e playlist animada.',
      'imagemUrl': 'https://images.unsplash.com/photo-1549923746-c502d488b3ea',
      'tags': ['ano novo', 'branco', 'dourado', 'festa']
    },
    {
      'tipoEvento': 'noivado',
      'titulo': 'Noivado romântico ao ar livre',
      'descricao':
          'Mesa de doces, letreiro luminoso “Love” e flores do campo. Perfeito para fotos incríveis e clima afetivo.',
      'imagemUrl': 'https://images.unsplash.com/photo-1526045612212-70caf35c14df',
      'tags': ['noivado', 'romântico', 'flores', 'ao ar livre']
    },
    {
      'tipoEvento': 'formatura',
      'titulo': 'Formatura estilo black & gold',
      'descricao':
          'Celebração com DJ, pista de dança e decoração moderna em preto e dourado. Ideal para festas jovens e cheias de energia.',
      'imagemUrl': 'https://images.unsplash.com/photo-1541417904950-b855846fe074',
      'tags': ['formatura', 'moderno', 'preto', 'dourado', 'festa']
    },
    {
      'tipoEvento': 'batizado',
      'titulo': 'Batizado em branco e verde oliva',
      'descricao':
          'Decoração minimalista e elegante, com flores brancas e folhagens. Mesa de doces suave e elegante.',
      'imagemUrl': 'https://images.unsplash.com/photo-1616628188935-2e8e3f40e091',
      'tags': ['batizado', 'branco', 'folhas', 'minimalista']
    },
    {
      'tipoEvento': 'cha de cozinha',
      'titulo': 'Chá de cozinha retrô',
      'descricao':
          'Decoração vintage com utensílios antigos, toalhas xadrez e docinhos caseiros. Ideal para eventos descontraídos e afetivos.',
      'imagemUrl': 'https://images.unsplash.com/photo-1600718379933-d14c61a1e27d',
      'tags': ['retrô', 'cozinha', 'vintage', 'afetivo']
    },
  ];

  for (var item in inspiracoes) {
    final model = InspiracaoModel(
      id: _uuid.v4(),
      tipoEvento: item['tipoEvento'] as String,
      titulo: item['titulo'] as String,
      descricao: item['descricao'] as String,
      imagemUrl: item['imagemUrl'] as String,
      tags: List<String>.from(item['tags'] as List),
    );

    await _db.collection('inspiracoes').doc(model.id).set(model.toFirestore());
  }

  debugPrint('✅ Inspirações inseridas com sucesso!');
}

Future<void> _inserirEstadosECidades() async {
  final estados = [
    {'uf': 'AC', 'nome': 'Acre'},
    {'uf': 'AL', 'nome': 'Alagoas'},
    {'uf': 'AP', 'nome': 'Amapá'},
    {'uf': 'AM', 'nome': 'Amazonas'},
    {'uf': 'BA', 'nome': 'Bahia'},
    {'uf': 'CE', 'nome': 'Ceará'},
    {'uf': 'DF', 'nome': 'Distrito Federal'},
    {'uf': 'ES', 'nome': 'Espírito Santo'},
    {'uf': 'GO', 'nome': 'Goiás'},
    {'uf': 'MA', 'nome': 'Maranhão'},
    {'uf': 'MT', 'nome': 'Mato Grosso'},
    {'uf': 'MS', 'nome': 'Mato Grosso do Sul'},
    {'uf': 'MG', 'nome': 'Minas Gerais'},
    {'uf': 'PA', 'nome': 'Pará'},
    {'uf': 'PB', 'nome': 'Paraíba'},
    {'uf': 'PR', 'nome': 'Paraná'},
    {'uf': 'PE', 'nome': 'Pernambuco'},
    {'uf': 'PI', 'nome': 'Piauí'},
    {'uf': 'RJ', 'nome': 'Rio de Janeiro'},
    {'uf': 'RN', 'nome': 'Rio Grande do Norte'},
    {'uf': 'RS', 'nome': 'Rio Grande do Sul'},
    {'uf': 'RO', 'nome': 'Rondônia'},
    {'uf': 'RR', 'nome': 'Roraima'},
    {'uf': 'SC', 'nome': 'Santa Catarina'},
    {'uf': 'SP', 'nome': 'São Paulo'},
    {'uf': 'SE', 'nome': 'Sergipe'},
    {'uf': 'TO', 'nome': 'Tocantins'},
  ];

  final cidadesPorEstado = {
    'AC': ['Rio Branco', 'Cruzeiro do Sul', 'Sena Madureira'],
    'AL': ['Maceió', 'Arapiraca', 'Palmeira dos Índios'],
    'AP': ['Macapá', 'Santana', 'Laranjal do Jari'],
    'AM': ['Manaus', 'Parintins', 'Itacoatiara', 'Manacapuru'],
    'BA': ['Salvador', 'Feira de Santana', 'Vitória da Conquista', 'Itabuna', 'Ilhéus'],
    'CE': ['Fortaleza', 'Caucaia', 'Juazeiro do Norte', 'Sobral', 'Maracanaú'],
    'DF': ['Brasília', 'Taguatinga', 'Ceilândia', 'Gama', 'Planaltina'],
    'ES': ['Vitória', 'Vila Velha', 'Serra', 'Cariacica', 'Linhares'],
    'GO': ['Goiânia', 'Aparecida de Goiânia', 'Anápolis', 'Rio Verde', 'Luziânia'],
    'MA': ['São Luís', 'Imperatriz', 'Caxias', 'Timon', 'Bacabal'],
    'MT': ['Cuiabá', 'Várzea Grande', 'Rondonópolis', 'Sinop', 'Tangará da Serra'],
    'MS': ['Campo Grande', 'Dourados', 'Três Lagoas', 'Corumbá', 'Ponta Porã'],
    'MG': ['Belo Horizonte', 'Uberlândia', 'Juiz de Fora', 'Montes Claros', 'Contagem'],
    'PA': ['Belém', 'Ananindeua', 'Santarém', 'Marabá', 'Castanhal'],
    'PB': ['João Pessoa', 'Campina Grande', 'Patos', 'Sousa', 'Cajazeiras'],
    'PR': ['Curitiba', 'Londrina', 'Maringá', 'Ponta Grossa', 'Cascavel', 'Foz do Iguaçu'],
    'PE': ['Recife', 'Olinda', 'Caruaru', 'Petrolina', 'Garanhuns', 'Jaboatão dos Guararapes'],
    'PI': ['Teresina', 'Parnaíba', 'Picos', 'Floriano'],
    'RJ': ['Rio de Janeiro', 'Niterói', 'Petrópolis', 'Volta Redonda', 'Campos dos Goytacazes'],
    'RN': ['Natal', 'Mossoró', 'Caicó', 'Parnamirim'],
    'RS': ['Porto Alegre', 'Caxias do Sul', 'Pelotas', 'Santa Maria', 'Passo Fundo'],
    'RO': ['Porto Velho', 'Ji-Paraná', 'Ariquemes', 'Vilhena', 'Cacoal'],
    'RR': ['Boa Vista', 'Rorainópolis', 'Caracaraí'],
    'SC': ['Florianópolis', 'Joinville', 'Blumenau', 'Chapecó', 'Criciúma'],
    'SP': ['São Paulo', 'Campinas', 'Santos', 'Sorocaba', 'Ribeirão Preto', 'São José dos Campos'],
    'SE': ['Aracaju', 'Nossa Senhora do Socorro', 'Lagarto', 'Itabaiana'],
    'TO': ['Palmas', 'Araguaína', 'Gurupi', 'Porto Nacional'],
  };

  for (var estado in estados) {
    final idUf = _uuid.v4();
    final estadoModel = EstadoModel(
      idUf: idUf,
      uf: estado['uf']!,
      nome: estado['nome']!,
    );

    // 🔹 Grava o estado
    await _db.collection('estado').doc(idUf).set(estadoModel.toMap());

    // 🔹 Insere cidades se existirem
    if (cidadesPorEstado.containsKey(estado['uf'])) {
      final cidades = cidadesPorEstado[estado['uf']]!;
      for (var i = 0; i < cidades.length; i++) {
        final cidadeModel = CidadeModel(
          idCidade: i + 1,
          uf: estado['uf']!,
          nome: cidades[i],
          estado: estadoModel,
        );

        await _db.collection('estado').doc(idUf).collection('cidades').add(cidadeModel.toMap());
      }
    }
  }

  debugPrint('✅ Estados e cidades inseridos com sucesso!');
}
