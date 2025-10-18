import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'dart:math';

class FornecedorLocalizacaoController extends GetxController {
  var userLatitude = 0.0.obs;
  var userLongitude = 0.0.obs;
  var raio = 10.0.obs; // km
  var avaliacaoMinima = 0.0.obs;
  var fornecedores = <FornecedorModel>[].obs;
  var fornecedoresFiltrados = <FornecedorModel>[].obs;
  var categorias = <String>[].obs;
  var carregando = true.obs;

  @override
  void onInit() {
    super.onInit();
    _obterLocalizacaoUsuario();
  }

  // ==========================================================
  // === LOCALIZAÇÃO DO USUÁRIO
  // ==========================================================
  Future<void> _obterLocalizacaoUsuario() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final pos = await Geolocator.getCurrentPosition();
    userLatitude.value = pos.latitude;
    userLongitude.value = pos.longitude;

    await carregarFornecedores();
  }

  // ==========================================================
  // === CARGA SIMULADA DE FORNECEDORES (mock para testes)
  // ==========================================================
  Future<void> carregarFornecedores() async {
    carregando.value = true;

    final lat = userLatitude.value;
    final lon = userLongitude.value;

    // 🔹 Simulação de fornecedores em categorias diferentes
    fornecedores.value = [
      FornecedorModel(
        id: '01',
        nome: 'Buffet Sabor & Arte',
        categoria: 'Buffet',
        imagem: 'assets/images/fornecedor_buffet.jpeg',
        latitude: lat + 0.01,
        longitude: lon + 0.02,
        avaliacao: 4.8,
        distanciaKm: 0,
      ),
      FornecedorModel(
        id: '02',
        nome: 'Delícias da Ana',
        categoria: 'Buffet',
        imagem: 'assets/images/fornecedor_recepcao.jpeg',
        latitude: lat + 0.015,
        longitude: lon - 0.01,
        avaliacao: 4.6,
        distanciaKm: 0,
      ),
      FornecedorModel(
        id: '03',
        nome: 'Florarte Decorações',
        categoria: 'Decoração',
        imagem: 'assets/images/fornecedor_decoracao.jpg',
        latitude: lat + 0.03,
        longitude: lon + 0.015,
        avaliacao: 4.9,
        distanciaKm: 0,
      ),
      FornecedorModel(
        id: '04',
        nome: 'Flash Studio',
        categoria: 'Fotografia',
        imagem: 'assets/images/fornecedor_fotografia.jpeg',
        latitude: lat + 0.025,
        longitude: lon - 0.02,
        avaliacao: 4.7,
        distanciaKm: 0,
      ),
      FornecedorModel(
        id: '05',
        nome: 'Som & Luz Eventos',
        categoria: 'Música',
        imagem: 'assets/images/fornecedor_musica_1.jpg',
        latitude: lat - 0.015,
        longitude: lon + 0.01,
        avaliacao: 4.6,
        distanciaKm: 0,
      ),
      FornecedorModel(
        id: '06',
        nome: 'Convite Criativo',
        categoria: 'Convites',
        imagem: 'assets/images/fornecedor_convite_1.jpg',
        latitude: lat + 0.02,
        longitude: lon - 0.015,
        avaliacao: 4.5,
        distanciaKm: 0,
      ),
    ];

    _filtrarPorRaio();

    // 🔹 Extrai categorias únicas para o menu
    categorias.value = fornecedores.map((f) => f.categoria).toSet().toList()..sort();

    carregando.value = false;
  }

  // ==========================================================
  // === FILTRO POR RAIO DE DISTÂNCIA
  // ==========================================================
  void _filtrarPorRaio() {
    fornecedoresFiltrados.value = fornecedores.where((f) {
      final dist = _calcularDistancia(
        userLatitude.value,
        userLongitude.value,
        f.latitude,
        f.longitude,
      );
      f.distanciaKm = dist;
      return dist <= raio.value;
    }).toList();
  }

  // ==========================================================
  // === FUNÇÕES AUXILIARES
  // ==========================================================
  double _calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371;
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  void atualizarRaio(double novoRaio) {
    raio.value = novoRaio;
    _filtrarPorRaio();
  }

  // 🔹 Novo: retorna fornecedores de uma categoria específica
  List<FornecedorModel> fornecedoresPorCategoria(String categoria) {
    return fornecedoresFiltrados
        .where((f) => f.categoria.toLowerCase() == categoria.toLowerCase())
        .toList();
  }
}

// ==========================================================
// === MODELO DE DADOS
// ==========================================================
class FornecedorModel {
  String id;
  String nome;
  String categoria;
  double latitude;
  double longitude;
  double avaliacao;
  double distanciaKm;
  String? imagem;

  // 🏢 Dados complementares
  String? cnpj;
  String? email;
  String? telefone;
  String? uf;
  String? cidade;
  String? bairro;
  String? endereco;
  String? descricao;

  // 🛒 Produtos oferecidos (lista dinâmica)
  List<Map<String, dynamic>>? produtos;

  FornecedorModel({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.latitude,
    required this.longitude,
    required this.avaliacao,
    required this.distanciaKm,
    this.imagem,
    this.cnpj,
    this.email,
    this.telefone,
    this.uf,
    this.cidade,
    this.bairro,
    this.endereco,
    this.descricao,
    this.produtos,
  });

  // === Conversão para JSON (para Firestore ou API) ===
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'categoria': categoria,
      'latitude': latitude,
      'longitude': longitude,
      'avaliacao': avaliacao,
      'distanciaKm': distanciaKm,
      'imagem': imagem,
      'cnpj': cnpj,
      'email': email,
      'telefone': telefone,
      'uf': uf,
      'cidade': cidade,
      'bairro': bairro,
      'endereco': endereco,
      'descricao': descricao,
      'produtos': produtos,
    };
  }

  // === Conversão a partir de JSON ===
  factory FornecedorModel.fromJson(Map<String, dynamic> json) {
    return FornecedorModel(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      categoria: json['categoria'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      avaliacao: (json['avaliacao'] ?? 0).toDouble(),
      distanciaKm: (json['distanciaKm'] ?? 0).toDouble(),
      imagem: json['imagem'],
      cnpj: json['cnpj'],
      email: json['email'],
      telefone: json['telefone'],
      uf: json['uf'],
      cidade: json['cidade'],
      bairro: json['bairro'],
      endereco: json['endereco'],
      descricao: json['descricao'],
      produtos:
          (json['produtos'] != null) ? List<Map<String, dynamic>>.from(json['produtos']) : null,
    );
  }
}
