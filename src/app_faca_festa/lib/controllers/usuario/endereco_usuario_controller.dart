import '../../data/models/endereco/endereco.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/repositories/cep_repository.dart';
import '../../domain/repositories/perfil_usuario_repository.dart';

class EnderecoUsuarioController extends GetxController {
  EnderecoUsuarioController({
    required PerfilUsuarioRepository perfilRepository,
    required CepRepository cepRepository,
  })  : _perfilRepository = perfilRepository,
        _cepRepository = cepRepository;

  final PerfilUsuarioRepository _perfilRepository;
  final CepRepository _cepRepository;

  final enderecoPrincipal = Rxn<EnderecoUsuarioModel>();
  final carregando = false.obs;

  // 🔹 Carrega o endereço principal do usuário
  Future<void> carregarEnderecoPrincipal(String idUsuario) async {
    try {
      carregando.value = true;

      final endereco =
          await _perfilRepository.buscarEnderecoPrincipal(idUsuario);
      if (endereco == null) {
        enderecoPrincipal.value = null;
        return;
      }

      enderecoPrincipal.value = EnderecoUsuarioModel.fromEntity(endereco);
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
        id: enderecoPrincipal.value?.id ?? _perfilRepository.criarIdEndereco(),
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

      await _perfilRepository.salvarEndereco(novo);

      enderecoPrincipal.value = novo;

      // 🔹 Atualiza cidade/UF no documento principal do usuário
      await _perfilRepository.atualizarLocalizacaoUsuario(
        idUsuario: idUsuario,
        cidade: nomeCidade,
        uf: uf,
      );

      if (!Get.testMode) {
        Get.snackbar(
          'Endereço atualizado',
          'Seu endereço principal foi salvo com sucesso.',
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar endereço principal: $e');
      if (!Get.testMode) {
        Get.snackbar(
          'Erro',
          'Falha ao salvar endereço.',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
      }
    } finally {
      carregando.value = false;
    }
  }

  // 🔹 Busca dados do CEP usando ViaCEP
  Future<Map<String, dynamic>?> buscarCep(String cep) async {
    try {
      return _cepRepository.buscarCep(cep);
    } catch (e) {
      debugPrint('❌ Erro ao buscar CEP: $e');
      return null;
    }
  }
}
