// ignore_for_file: unused_element

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import './data/models/model.dart';
import 'data/models/cardapio/cardapio_item_model.dart';
import 'data/models/cardapio/cardapio_model.dart';
import 'data/models/convidado/grupo_convidado_model.dart';
import 'data/models/servico_produto/categoria_servico_model.dart';
import 'data/models/servico_produto/fornecedor_categoria_model.dart';
import 'data/models/servico_produto/servico_foto.dart';
import 'data/models/servico_produto/subcategoria_servico_model.dart';

final _uuid = Uuid();
final _db = FirebaseFirestore.instance;

/// Executa a carga de dados iniciais no Firestore
Future<void> popularFirebase() async {
  //await _inserirTiposDeEvento();
  //await _inserirEstadosECidades();
  //await _inserirInspiracoes();
  //await inserirPostsComunidade();
  //await inserirDadosFornecedorTeste();
  //await inserirOrcamentosTeste();
  //await inserirDadosComRelacionamentos();

  //await resetarEDepoisInserir();
  //await _inserirFornecedoresPorCategoria();
  await inserirConvidadosComRelacionamentos();
}

Future<void> resetarEDepoisInserir() async {
  /*
  await limparColecoesFacaAFesta();
  await _inserirTiposDeEvento();
  await inserirDadosComRelacionamentos();
  */
}

Future<void> inserirConvidadosComRelacionamentos() async {
  try {
    const String idEvento = "cbc35769-d700-4a7d-bb13-c42f1eb1c8dc";

    // ===========================================
    // 🔹 1. Grupos de Convidados (Famílias e Amigos)
    // ===========================================
    final grupos = [
      GrupoConvidadoModel(
        idGrupo: _uuid.v4(),
        idEvento: idEvento,
        nome: "Família Schor",
        descricao: "Parentes próximos da organizadora",
        icone: "family_restroom_rounded",
        corHex: "#009688",
      ),
      GrupoConvidadoModel(
        idGrupo: _uuid.v4(),
        idEvento: idEvento,
        nome: "Amigos da Faculdade",
        descricao: "Colegas de Engenharia de Software",
        icone: "group_rounded",
        corHex: "#FF9800",
      ),
      GrupoConvidadoModel(
        idGrupo: _uuid.v4(),
        idEvento: idEvento,
        nome: "Equipe RRS Sistemas",
        descricao: "Colegas de trabalho e equipe técnica",
        icone: "computer_rounded",
        corHex: "#3F51B5",
      ),
      GrupoConvidadoModel(
        idGrupo: _uuid.v4(),
        idEvento: idEvento,
        nome: "Família Marques",
        descricao: "Convidados do lado paterno",
        icone: "favorite_rounded",
        corHex: "#E91E63",
      ),
    ];

    for (var grupo in grupos) {
      await _db.collection('grupos_convidado').doc(grupo.idGrupo).set(grupo.toMap());
    }

    // ===========================================
    // 🔹 2. Cardápios do Evento
    // ===========================================
    final cardapios = [
      CardapioModel(
        idCardapio: _uuid.v4(),
        idEvento: idEvento,
        titulo: "Adultos",
        icone: Icons.local_dining_rounded,
        cor: const Color(0xFF8B0000),
        itens: [
          const CardapioItemModel(
              idItem: "1",
              nome: "Prato principal: Risoto de camarão",
              confirmado: true,
              tipo: "comida"),
          const CardapioItemModel(
              idItem: "2", nome: "Bebida: Vinho tinto seco", confirmado: true, tipo: "bebida"),
          const CardapioItemModel(
              idItem: "3", nome: "Sobremesa: Petit gâteau", confirmado: true, tipo: "sobremesa"),
        ],
      ),
      CardapioModel(
        idCardapio: _uuid.v4(),
        idEvento: idEvento,
        titulo: "Crianças",
        icone: Icons.icecream_outlined,
        cor: const Color(0xFFFFA000),
        itens: [
          const CardapioItemModel(
              idItem: "4", nome: "Mini hambúrguer", confirmado: true, tipo: "comida"),
          const CardapioItemModel(
              idItem: "5", nome: "Suco natural", confirmado: true, tipo: "bebida"),
          const CardapioItemModel(
              idItem: "6", nome: "Picolé de chocolate", confirmado: true, tipo: "sobremesa"),
        ],
      ),
      CardapioModel(
        idCardapio: _uuid.v4(),
        idEvento: idEvento,
        titulo: "Livre",
        icone: Icons.restaurant_menu_rounded,
        cor: Colors.teal,
        itens: [
          const CardapioItemModel(
              idItem: "7", nome: "Buffet completo", confirmado: true, tipo: "comida"),
          const CardapioItemModel(
              idItem: "8", nome: "Sobremesas variadas", confirmado: true, tipo: "sobremesa"),
        ],
      ),
    ];

    for (final c in cardapios) {
      final docRef = _db.collection('cardapios').doc(c.idCardapio);
      await docRef.set(c.toMap());

      for (final item in c.itens) {
        await docRef.collection('itens').doc(item.idItem).set(item.toMap());
      }
    }

    // ===========================================
    // 🔹 3. Convidados (20 pessoas)
    // ===========================================
    final convidados = [
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Stephanie Schor",
        contato: "(41) 99999-1111",
        email: "stephanie@facaafesta.com",
        status: StatusConvidado.confirmado,
        adulto: true,
        grupoMesa: "Família Schor",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Murillo Pereira",
        contato: "(41) 98888-2222",
        email: "murillo@rrs.com",
        status: StatusConvidado.confirmado,
        adulto: true,
        grupoMesa: "Equipe RRS Sistemas",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Jullia Acsa",
        contato: "(41) 98765-3333",
        email: "jullia.acsa@facaafesta.com",
        status: StatusConvidado.confirmado,
        adulto: true,
        grupoMesa: "Amigos da Faculdade",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Rivaldo Roberto",
        contato: "(41) 98654-4444",
        email: "rivaldo@rrs.com",
        status: StatusConvidado.confirmado,
        adulto: true,
        grupoMesa: "Equipe RRS Sistemas",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Carlos Marques",
        contato: "(41) 98543-5555",
        email: "carlos.marques@email.com",
        status: StatusConvidado.pendente,
        adulto: true,
        grupoMesa: "Família Marques",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Marta Marques",
        contato: "(41) 98432-6666",
        email: "marta.marques@email.com",
        status: StatusConvidado.confirmado,
        adulto: true,
        grupoMesa: "Família Marques",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Lucas e Amanda",
        contato: "(41) 98321-7777",
        email: "lucas.amanda@email.com",
        status: StatusConvidado.confirmado,
        adulto: true,
        grupoMesa: "Amigos da Faculdade",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "João Silva",
        contato: "(41) 98210-8888",
        email: "joao.silva@email.com",
        status: StatusConvidado.pendente,
        adulto: true,
        grupoMesa: "Amigos da Faculdade",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Gabriela Torres",
        contato: "(41) 98123-9999",
        email: "gabriela.torres@email.com",
        status: StatusConvidado.confirmado,
        adulto: true,
        grupoMesa: "Amigos da Faculdade",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Victor Marques",
        contato: "(41) 98011-0001",
        email: "victor.marques@email.com",
        status: StatusConvidado.confirmado,
        adulto: false,
        grupoMesa: "Família Marques",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Larissa Schor",
        contato: "(41) 97999-0002",
        email: "larissa.schor@email.com",
        status: StatusConvidado.confirmado,
        adulto: false,
        grupoMesa: "Família Schor",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Pedro Henrique",
        contato: "(41) 97888-0003",
        email: "pedro.henrique@email.com",
        status: StatusConvidado.pendente,
        adulto: false,
        grupoMesa: "Família Schor",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Marina Lopes",
        contato: "(41) 97777-0004",
        email: "marina.lopes@email.com",
        status: StatusConvidado.confirmado,
        adulto: true,
        grupoMesa: "Amigos da Faculdade",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Caio Souza",
        contato: "(41) 97666-0005",
        email: "caio.souza@email.com",
        status: StatusConvidado.recusado,
        adulto: true,
        grupoMesa: "Equipe RRS Sistemas",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Eduarda Lima",
        contato: "(41) 97555-0006",
        email: "eduarda.lima@email.com",
        status: StatusConvidado.confirmado,
        adulto: false,
        grupoMesa: "Família Schor",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Renato Torres",
        contato: "(41) 97444-0007",
        email: "renato.torres@email.com",
        status: StatusConvidado.confirmado,
        adulto: true,
        grupoMesa: "Equipe RRS Sistemas",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Camila Ribeiro",
        contato: "(41) 97333-0008",
        email: "camila.ribeiro@email.com",
        status: StatusConvidado.pendente,
        adulto: true,
        grupoMesa: "Amigos da Faculdade",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Sofia Ribeiro",
        contato: "(41) 97222-0009",
        email: "sofia.ribeiro@email.com",
        status: StatusConvidado.pendente,
        adulto: false,
        grupoMesa: "Amigos da Faculdade",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Helena Marques",
        contato: "(41) 97111-0010",
        email: "helena.marques@email.com",
        status: StatusConvidado.confirmado,
        adulto: false,
        grupoMesa: "Família Marques",
      ),
      ConvidadoModel(
        idConvidado: _uuid.v4(),
        idEvento: idEvento,
        nome: "Arthur Schor",
        contato: "(41) 97000-0011",
        email: "arthur.schor@email.com",
        status: StatusConvidado.pendente,
        adulto: false,
        grupoMesa: "Família Schor",
      ),
    ];

    for (final convidado in convidados) {
      await _db.collection('convidado').doc(convidado.idConvidado).set(convidado.toMap());
    }

    debugPrint('🎉 20 convidados e relacionamentos inseridos com sucesso!');
  } catch (e, s) {
    debugPrint('❌ Erro ao inserir convidados: $e\n$s');
  }
}

Future<void> _inserirFornecedoresPorCategoria() async {
  final uuid = const Uuid();
  final db = FirebaseFirestore.instance;

  // ===========================================================
  // 🔹 1. Lista de Categorias
  // ===========================================================
  final List<Map<String, dynamic>> categorias = [
    {
      'id': '3cbc7cb4-5538-4ce0-9313-36e35bb2834a',
      'nome': 'Buffet',
      'fornecedores': [
        {
          'razao': 'Sabor & Arte Buffet',
          'email': 'contato@saborearte.com',
          'tel': '(41) 99888-0001',
          'desc':
              'Buffet completo para casamentos e aniversários, com menu personalizado e equipe treinada.',
          'banner': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5'
        },
        {
          'razao': 'Bella Festa Gastronomia',
          'email': 'eventos@bellafesta.com',
          'tel': '(41) 99991-4432',
          'desc': 'Gastronomia fina e moderna com opções gourmet e finger food.',
          'banner': 'https://images.unsplash.com/photo-1551218808-94e220e084d2'
        },
        {
          'razao': 'Delícias do Chef',
          'email': 'contato@deliciasdochef.com',
          'tel': '(41) 99123-8834',
          'desc': 'Pratos sofisticados e atendimento de alto padrão.',
          'banner': 'https://images.unsplash.com/photo-1565958011705-44e211b4a31f'
        },
        {
          'razao': 'Buffet Tropical',
          'email': 'atendimento@buffettropical.com',
          'tel': '(41) 99771-2211',
          'desc': 'Especialista em buffets tropicais e coquetéis refrescantes.',
          'banner': 'https://images.unsplash.com/photo-1525610553991-2bede1a236e2'
        },
        {
          'razao': 'Estilo & Sabor Eventos',
          'email': 'contato@estilosabor.com',
          'tel': '(41) 99666-5511',
          'desc': 'Buffet contemporâneo com foco em experiência gastronômica.',
          'banner': 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092'
        },
      ],
    },
    {
      'id': '5fd47622-8e80-4477-a86c-f4d9c4422164',
      'nome': 'Confeitaria',
      'fornecedores': [
        {
          'razao': 'Doce Encanto',
          'email': 'contato@doceencanto.com',
          'tel': '(41) 99944-7766',
          'desc': 'Bolos artísticos e doces finos sob medida.',
          'banner': 'https://images.unsplash.com/photo-1589308078053-f85d32b6e4a8'
        },
        {
          'razao': 'Atelier dos Doces',
          'email': 'pedidos@atelierdodoces.com',
          'tel': '(41) 99551-8822',
          'desc': 'Doces personalizados e mesas temáticas de festa.',
          'banner': 'https://images.unsplash.com/photo-1612197527762-9b3db9e7e6a2'
        },
        {
          'razao': 'Confeitaria Pura Magia',
          'email': 'contato@puramagia.com',
          'tel': '(41) 99773-4455',
          'desc': 'Especialista em bolos cenográficos e cupcakes decorados.',
          'banner': 'https://images.unsplash.com/photo-1551782450-a2132b4ba21d'
        },
        {
          'razao': 'Dona Brigadeiro',
          'email': 'atendimento@donabrigadeiro.com',
          'tel': '(41) 99888-1144',
          'desc': 'Brigadeiros gourmet e lembranças doces.',
          'banner': 'https://images.unsplash.com/photo-1551024709-8f23befc6cf7'
        },
        {
          'razao': 'Sweet Moment',
          'email': 'contato@sweetmoment.com',
          'tel': '(41) 99922-1133',
          'desc': 'Doces finos e sobremesas de casamento.',
          'banner': 'https://images.unsplash.com/photo-1505253716362-afaea1b526b1'
        },
      ],
    },
    {
      'id': 'd59ec1ca-2267-4cd1-89c8-5ad0712d450c',
      'nome': 'Decoração',
      'fornecedores': [
        {
          'razao': 'Studio Flor & Luz',
          'email': 'contato@floreeluz.com',
          'tel': '(41) 99433-6677',
          'desc': 'Decoração floral para eventos com design contemporâneo.',
          'banner': 'https://images.unsplash.com/photo-1504196606672-aef5c9cefc92'
        },
        {
          'razao': 'Maison Decor',
          'email': 'contato@maisondecor.com',
          'tel': '(41) 99771-9088',
          'desc': 'Locação de mobiliário e ambientação temática.',
          'banner': 'https://images.unsplash.com/photo-1578301978693-85fa9c0320d3'
        },
        {
          'razao': 'Glamour Eventos',
          'email': 'eventos@glamour.com',
          'tel': '(41) 99911-1212',
          'desc': 'Decoração personalizada com foco em casamentos e debutantes.',
          'banner': 'https://images.unsplash.com/photo-1519861531473-9200262188bf'
        },
        {
          'razao': 'Natureza & Arte',
          'email': 'contato@naturezaearte.com',
          'tel': '(41) 99333-8899',
          'desc': 'Decoração sustentável com flores naturais e materiais ecológicos.',
          'banner': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb'
        },
        {
          'razao': 'Espaço Criativo',
          'email': 'criativo@espacocriativo.com',
          'tel': '(41) 99111-2323',
          'desc': 'Produção visual e cenográfica para eventos.',
          'banner': 'https://images.unsplash.com/photo-1499951360447-b19be8fe80f5'
        },
      ],
    },
    {
      'id': '50d5aac7-8831-4fca-bfe3-cc2c1f94b509',
      'nome': 'Fotografia e Filmagem',
      'fornecedores': [
        {
          'razao': 'Studio Lumina',
          'email': 'contato@lumina.com',
          'tel': '(41) 99881-5511',
          'desc': 'Fotografia artística e filmagem em 4K.',
          'banner': 'https://images.unsplash.com/photo-1504208434309-cb69f4fe52b0'
        },
        {
          'razao': 'Click & Love',
          'email': 'atendimento@clicklove.com',
          'tel': '(41) 99988-7711',
          'desc': 'Ensaio pré-evento e cobertura completa.',
          'banner': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32'
        },
        {
          'razao': 'Fotografia Em Cena',
          'email': 'contato@emcena.com',
          'tel': '(41) 99773-8822',
          'desc': 'Produção de vídeos emocionais e making-of.',
          'banner': 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f'
        },
        {
          'razao': 'Olhar Sensível',
          'email': 'olhar@fotostudio.com',
          'tel': '(41) 99444-7788',
          'desc': 'Cobertura documental e naturalista.',
          'banner': 'https://images.unsplash.com/photo-1504208434309-cb69f4fe52b0'
        },
        {
          'razao': 'Frame Story',
          'email': 'frame@story.com',
          'tel': '(41) 99111-0009',
          'desc': 'Narrativas visuais com drones e cinema.',
          'banner': 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f'
        },
      ],
    },
    {
      'id': '0b5c0fee-2f33-4ae7-8b96-2bb25aedd669',
      'nome': 'Música e Iluminação',
      'fornecedores': [
        {
          'razao': 'DJ Sound Mix',
          'email': 'contato@soundmix.com',
          'tel': '(41) 99966-8833',
          'desc': 'DJ profissional com som e luzes sincronizadas.',
          'banner': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819'
        },
        {
          'razao': 'Banda Solaris',
          'email': 'contato@solarisbanda.com',
          'tel': '(41) 99771-3344',
          'desc': 'Banda ao vivo com repertório personalizado.',
          'banner': 'https://images.unsplash.com/photo-1507874457470-272b3c8d8ee2'
        },
        {
          'razao': 'Light & Beats',
          'email': 'contato@lightbeats.com',
          'tel': '(41) 99551-2277',
          'desc': 'Iluminação e sonorização profissional.',
          'banner': 'https://images.unsplash.com/photo-1511379938547-c1f69419868d'
        },
        {
          'razao': 'Festa Som & Luz',
          'email': 'contato@festasomeluz.com',
          'tel': '(41) 99112-7766',
          'desc': 'Locação de equipamentos de som, luz e palco.',
          'banner': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4'
        },
        {
          'razao': 'Ritmo Perfeito',
          'email': 'contato@ritmoperfeito.com',
          'tel': '(41) 99321-1122',
          'desc': 'Música ao vivo, DJs e pista interativa.',
          'banner': 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f'
        },
      ],
    },
  ];

  // ===========================================================
  // 🔹 2. Inserção no Firestore
  // ===========================================================
  for (final cat in categorias) {
    for (final f in cat['fornecedores']) {
      final idFornecedor = uuid.v4();

      final model = FornecedorModel(
        idFornecedor: idFornecedor,
        idUsuario: 'u_teste_admin',
        razaoSocial: f['razao']!,
        telefone: f['tel']!,
        email: f['email']!,
        descricao: f['desc'],
        bannerUrl: f['banner'],
        aptoParaOperar: true,
        ativo: true,
      );

      await db.collection('fornecedor').doc(model.idFornecedor).set(model.toMap());

      final categoriaModel = FornecedorCategoriaModel(
        idFornecedor: idFornecedor,
        idCategoria: cat['id']!,
      );
      await db.collection('fornecedor_categoria').add(categoriaModel.toMap());

      final territorioModel = TerritorioModel(
        idTerritorio: uuid.v4(),
        idFornecedor: idFornecedor,
        descricao: 'Atendimento em Curitiba e Região Metropolitana',
        raioKm: 50,
        ativo: true,
      );
      await db
          .collection('territorio')
          .doc(territorioModel.idTerritorio)
          .set(territorioModel.toMap());
    }
  }

  debugPrint('✅ Fornecedores inseridos com sucesso!');
}

/// 🔥 Limpa todas as coleções principais do domínio antes de popular o banco.
Future<void> limparColecoesFacaAFesta() async {
  final colecoes = [
    'categoria_servico',
    'subcategoria_servico',
    'fornecedor',
    'fornecedor_categoria',
    'fornecedor_servico',
    'servico_produto',
    'servico_foto',
    'territorio',
    'orcamento',
    'tipo_evento',
  ];

  debugPrint('⚠️ Iniciando limpeza das coleções Firestore...');
  for (final c in colecoes) {
    await deletarColecao(c);
  }
  debugPrint('✅ Todas as coleções foram limpas com sucesso!');
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

Future<void> inserirDadosComRelacionamentos() async {
  try {
    // ======================================
    // 🔹 1. Categorias e Subcategorias base
    // ======================================
    final categorias = [
      CategoriaServicoModel(
        id: _uuid.v4(),
        nome: 'Decoração',
        descricao: 'Flores, locação e design de ambientes',
      ),
      CategoriaServicoModel(
        id: _uuid.v4(),
        nome: 'Buffet',
        descricao: 'Comidas, bebidas e atendimento',
      ),
      CategoriaServicoModel(
        id: _uuid.v4(),
        nome: 'Fotografia e Filmagem',
        descricao: 'Cobertura visual do evento',
      ),
      CategoriaServicoModel(
        id: _uuid.v4(),
        nome: 'Música e Iluminação',
        descricao: 'Som, luzes e entretenimento',
      ),
      CategoriaServicoModel(
        id: _uuid.v4(),
        nome: 'Confeitaria',
        descricao: 'Bolos e doces personalizados',
      ),
    ];

    for (var cat in categorias) {
      await _db.collection('categoria_servico').doc(cat.id).set(cat.toMap());
    }

    final subcategorias = [
      SubcategoriaServicoModel(
        id: _uuid.v4(),
        idCategoria: categorias[0].id,
        nome: 'Flores e Arranjos',
      ),
      SubcategoriaServicoModel(
        id: _uuid.v4(),
        idCategoria: categorias[0].id,
        nome: 'Locação de Móveis',
      ),
      SubcategoriaServicoModel(
        id: _uuid.v4(),
        idCategoria: categorias[1].id,
        nome: 'Buffet Completo',
      ),
      SubcategoriaServicoModel(
        id: _uuid.v4(),
        idCategoria: categorias[2].id,
        nome: 'Fotografia',
      ),
      SubcategoriaServicoModel(
        id: _uuid.v4(),
        idCategoria: categorias[3].id,
        nome: 'DJ e Iluminação',
      ),
      SubcategoriaServicoModel(
        id: _uuid.v4(),
        idCategoria: categorias[4].id,
        nome: 'Bolos e Doces',
      ),
    ];

    for (var sub in subcategorias) {
      await _db.collection('subcategoria_servico').doc(sub.id).set(sub.toMap());
    }

    // ======================================
    // 🔹 2. Fornecedores e Categorias
    // ======================================
    final List<Map<String, dynamic>> fornecedores = [
      {
        'razao': 'Stephanie Schor Eventos',
        'email': 'contato@schoreventos.com',
        'telefone': '(41) 99999-0000',
        'cnpj': '12.345.678/0001-99',
        'descricao': 'Especialista em casamentos e festas de alto padrão 💐',
        'latitude': -25.4411,
        'longitude': -49.2768,
        'raio': 30.0,
        'categorias': [categorias[0].id, categorias[2].id, categorias[3].id],
      },
      {
        'razao': 'Buffet Encanto Infantil',
        'email': 'buffet@encantoinfantil.com',
        'telefone': '(41) 98888-4444',
        'cnpj': '98.765.432/0001-11',
        'descricao': 'Buffet especializado em festas infantis com recreação 🎈',
        'latitude': -25.494,
        'longitude': -49.291,
        'raio': 25.0,
        'categorias': [categorias[1].id, categorias[4].id],
      },
      {
        'razao': 'Bolo & Arte Confeitaria',
        'email': 'contato@boloearte.com',
        'telefone': '(41) 99900-5566',
        'cnpj': '45.678.910/0001-77',
        'descricao': 'Bolos artísticos e doces personalizados para eventos 🎂',
        'latitude': -25.390,
        'longitude': -49.265,
        'raio': 20.0,
        'categorias': [categorias[4].id],
      },
    ];

    // 🔹 Mapeia os IDs dos fornecedores criados
    final Map<String, String> fornecedorIds = {};

    for (final f in fornecedores) {
      final idFornecedor = _uuid.v4();
      fornecedorIds[f['razao']] = idFornecedor;

      // Fornecedor principal
      final fornecedor = FornecedorModel(
        idFornecedor: idFornecedor,
        idUsuario: 'user_${f['razao']!.split(' ').first.toLowerCase()}',
        razaoSocial: f['razao']!,
        telefone: f['telefone']!,
        email: f['email']!,
        cnpj: f['cnpj']!,
        descricao: f['descricao']!,
        aptoParaOperar: true,
      );

      await _db.collection('fornecedor').doc(idFornecedor).set(fornecedor.toMap());

      // Relacionamento fornecedor <-> categorias
      for (final idCat in f['categorias']) {
        final vinculo = FornecedorCategoriaModel(
          idFornecedor: idFornecedor,
          idCategoria: idCat,
        );
        await _db.collection('fornecedor_categoria').add(vinculo.toMap());
      }

      // Território
      final territorio = TerritorioModel(
        idTerritorio: _uuid.v4(),
        idFornecedor: idFornecedor,
        latitude: f['latitude'],
        longitude: f['longitude'],
        raioKm: f['raio'],
        descricao: 'Atendimento local e regional',
      );
      await _db.collection('territorio').doc(territorio.idTerritorio).set(territorio.toMap());
    }

    // ======================================
    // 🔹 3. Serviços vinculados a subcategorias
    // ======================================
    final servicosBase = [
      ServicoProdutoModel(
          id: _uuid.v4(),
          nome: 'Decoração Completa',
          tipoMedida: 'Pacote',
          descricao: 'Flores, iluminação e ambientação.',
          ativo: true),
      ServicoProdutoModel(
          id: _uuid.v4(),
          nome: 'Buffet Completo',
          tipoMedida: 'Pacote',
          descricao: 'Comidas e bebidas inclusas.',
          ativo: true),
      ServicoProdutoModel(
          id: _uuid.v4(),
          nome: 'Cobertura Fotográfica',
          tipoMedida: 'Hora',
          descricao: 'Fotografia profissional para eventos.',
          ativo: true),
      ServicoProdutoModel(
          id: _uuid.v4(),
          nome: 'DJ e Iluminação',
          tipoMedida: 'Hora',
          descricao: 'Música e iluminação ambiente.',
          ativo: true),
      ServicoProdutoModel(
          id: _uuid.v4(),
          nome: 'Bolos e Doces',
          tipoMedida: 'Unidade',
          descricao: 'Confeitaria artística.',
          ativo: true),
    ];

    for (var s in servicosBase) {
      await _db.collection('servico_produto').doc(s.id).set(s.toMap());
    }

    // ======================================
    // 🔹 4. Vincular produtos aos fornecedores
    // ======================================
    for (final f in fornecedores) {
      final idFornecedor = fornecedorIds[f['razao']]!;
      List<ServicoProdutoModel> servicosFornecedor = [];

      // vincular com base no tipo de categoria
      if (f['categorias'].contains(categorias[0].id)) {
        servicosFornecedor.add(servicosBase[0]); // Decoração
      }
      if (f['categorias'].contains(categorias[1].id)) {
        servicosFornecedor.add(servicosBase[1]); // Buffet
      }
      if (f['categorias'].contains(categorias[2].id)) {
        servicosFornecedor.add(servicosBase[2]); // Fotografia
      }
      if (f['categorias'].contains(categorias[3].id)) {
        servicosFornecedor.add(servicosBase[3]); // DJ e Iluminação
      }
      if (f['categorias'].contains(categorias[4].id)) {
        servicosFornecedor.add(servicosBase[4]); // Bolos e Doces
      }

      for (var servico in servicosFornecedor) {
        final vinculo = FornecedorProdutoServicoModel(
          id: _uuid.v4(),
          idProdutoServico: servico.id,
          idFornecedor: idFornecedor,
          preco: 1000 + (500 * (servicosFornecedor.indexOf(servico) + 1)),
          precoPromocao: 900,
        );
        await _db.collection('fornecedor_servico').doc(vinculo.id).set(vinculo.toMap());
      }
    }

    debugPrint('🛠️ Serviços vinculados aos fornecedores com sucesso!');

    // ======================================
    // 🔹 5. Inserir fotos para cada serviço
    // ======================================
    final fotosServicos = [
      'https://images.unsplash.com/photo-1623428454614-abaf00244e52?fm=jpg&q=80&w=1600', // Bolos
      'https://images.unsplash.com/photo-1486427944299-d1955d23e34d?fm=jpg&q=80&w=1600', // Bolos
      'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?fm=jpg&q=80&w=1600', // Bolos
      'https://images.unsplash.com/photo-1576618148400-f54bed99fcfd?fm=jpg&q=80&w=1600', // Bolos
      'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?fm=jpg&q=80&w=1600', // Tipo tapioca
      'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=800', // 🍾 Buffet de drinks e coquetéis
      'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=800', // 🍝 Mesa de jantar elegante com pratos servidos
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800', // 🥂 Buffet de casamento com taças e flores
      'https://images.unsplash.com/photo-1555243896-c709bfa0b564?w=800', // 🥗 Buffet self-service com variedade de saladas
      'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=800', // 🍽️ Pratos sendo servidos por garçom
      'https://images.unsplash.com/photo-1520880867055-1e30d1cb001c?w=800',
    ];

    for (final servico in servicosBase) {
      for (final entry in fornecedorIds.entries) {
        for (int i = 0; i < 2; i++) {
          final foto = ServicoFotoModel(
            id: _uuid.v4(),
            idProdutoServico: servico.id,
            idFornecedor: entry.value,
            url: fotosServicos[(i + servicosBase.indexOf(servico)) % fotosServicos.length],
          );
          await _db.collection('servico_foto').doc(foto.id).set(foto.toMap());
        }
      }
    }

    debugPrint('📸 Fotos adicionadas aos serviços com sucesso!');

    // ======================================
    // 🔹 6. Orçamentos de teste
    // ======================================
    const String idEvento = "cbc35769-d700-4a7d-bb13-c42f1eb1c8dc";

    final List<Map<String, dynamic>> orcamentosTeste = [
      {
        'idProdutoServico': servicosBase[0].id,
        'idCategoria': categorias[0].id,
        'descricao': 'Decoração completa com flores e iluminação ambiente',
        'valor': 1200.0
      },
      {
        'idProdutoServico': servicosBase[1].id,
        'idCategoria': categorias[1].id,
        'descricao': 'Buffet completo para até 100 convidados',
        'valor': 2500.0
      },
      {
        'idProdutoServico': servicosBase[2].id,
        'idCategoria': categorias[2].id,
        'descricao': 'Cobertura fotográfica + álbum digital',
        'valor': 900.0
      },
    ];

    for (final o in orcamentosTeste) {
      final orcamento = OrcamentoModel(
        idOrcamento: _uuid.v4(),
        idEvento: idEvento,
        idServicoFornecido: o['idProdutoServico']!,
        idCategoria: o['idCategoria'],
        custoEstimado: o['valor'],
        orcamentoFechado: false,
        anotacoes: o['descricao'],
        status: StatusOrcamento.pendente,
      );
      await _db.collection('orcamento').doc(orcamento.idOrcamento).set(orcamento.toMap());
    }

    debugPrint(
        '✅ Inserção completa — Categorias, fornecedores, serviços, fotos e orçamentos criados!');
  } catch (e, s) {
    debugPrint('❌ Erro ao inserir dados: $e\n$s');
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

/// 🔥 Deleta todos os documentos de uma coleção do Firestore.
///
/// [collectionPath] é o nome da coleção (ex: 'fornecedor').
/// A função usa lotes (batches) de 500 docs para evitar limites do Firestore.
Future<void> deletarColecao(String collectionPath) async {
  const int batchSize = 500;
  WriteBatch batch = _db.batch();

  try {
    final QuerySnapshot snapshot = await _db.collection(collectionPath).limit(batchSize).get();

    if (snapshot.docs.isEmpty) {
      if (kDebugMode) print('✅ Coleção "$collectionPath" já está vazia.');
      return;
    }

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    if (kDebugMode) {
      print('🗑️ Coleção "$collectionPath": ${snapshot.size} documentos deletados.');
    }

    // Chama novamente até apagar tudo (recursivo)
    if (snapshot.size == batchSize) {
      await Future.delayed(const Duration(milliseconds: 300));
      await deletarColecao(collectionPath);
    }
  } catch (e, s) {
    debugPrint('❌ Erro ao deletar coleção "$collectionPath": $e\n$s');
  }
}
