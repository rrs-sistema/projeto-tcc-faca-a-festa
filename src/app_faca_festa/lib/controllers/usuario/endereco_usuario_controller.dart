import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/endereco/endereco.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';

class EnderecoUsuarioController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final enderecoPrincipal = Rxn<EnderecoUsuarioModel>();
  final carregando = false.obs;

  // 🔹 Carrega o endereço principal do usuário
  Future<void> carregarEnderecoPrincipal(String idUsuario) async {
    try {
      carregando.value = true;

      final snap = await _db
          .collection('usuarios')
          .doc(idUsuario)
          .collection('enderecos')
          .where('principal', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        enderecoPrincipal.value = null;
        return;
      }

      enderecoPrincipal.value = EnderecoUsuarioModel.fromMap(snap.docs.first.data());
    } catch (e) {
      debugPrint('❌ Erro ao carregar endereço principal: $e');
    } finally {
      carregando.value = false;
    }
  }

  // 🔹 Salvar OU atualizar o endereço principal
  Future<void> salvarEnderecoPrincipal({
    required String idUsuario,
    required String cep,
    required String logradouro,
    required String numero,
    required String? complemento,
    required String bairro,
    required String nomeCidade,
    required String uf,
  }) async {
    try {
      carregando.value = true;

      // Constrói modelo
      final novo = EnderecoUsuarioModel(
        id: enderecoPrincipal.value?.id ?? _db.collection('x').doc().id,
        idUsuario: idUsuario,
        idCidade: 0,
        cep: cep,
        logradouro: logradouro,
        numero: numero,
        complemento: complemento,
        bairro: bairro,
        nomeCidade: nomeCidade,
        uf: uf,
        principal: true,
        dataCadastro: DateTime.now(),
      );

      final ref = _db.collection('usuarios').doc(idUsuario).collection('enderecos').doc(novo.id);

      await ref.set(novo.toMap());

      enderecoPrincipal.value = novo;

      // 🔹 Atualiza cidade/UF no documento principal do usuário
      await _db.collection('usuarios').doc(idUsuario).update({
        'cidade': nomeCidade,
        'uf': uf,
      });

      Get.snackbar(
        'Endereço atualizado',
        'Seu endereço principal foi salvo com sucesso.',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('❌ Erro ao salvar endereço principal: $e');
      Get.snackbar(
        'Erro',
        'Falha ao salvar endereço.',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } finally {
      carregando.value = false;
    }
  }

  // 🔹 Busca dados do CEP usando ViaCEP
  Future<Map<String, dynamic>?> buscarCep(String cep) async {
    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
      final response = await http.get(url);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);

      if (data['erro'] == true) return null;

      return data;
    } catch (e) {
      debugPrint('❌ Erro ao buscar CEP: $e');
      return null;
    }
  }
}
