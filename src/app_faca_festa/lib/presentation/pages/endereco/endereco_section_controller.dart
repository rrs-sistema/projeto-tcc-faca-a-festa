import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../app/bootstrap/uf_cidade_bootstrap.dart';
import './../../../data/models/model.dart';
import './../../../data/services/endereco/buscar_cep_google_service.dart';

/// 🎯 Controller público da seção de endereço
class EnderecoSectionController {
  final cepController = TextEditingController();
  final logradouroController = TextEditingController();
  final numeroController = TextEditingController();
  final complementoController = TextEditingController();
  final bairroController = TextEditingController();
  final ufCidadeController = UfCidadeBootstrap.findController();
  final nomeCidadeController = TextEditingController();
  final ufController = TextEditingController();
  final numeroFocusNode = FocusNode();

  final consultandoCep = false.obs;
  final mensagemCep = ''.obs;

  final BuscarCepGoogleService _cepService;
  String _ultimoCepConsultado = '';

  EnderecoSectionController({BuscarCepGoogleService? cepService})
      : _cepService = cepService ?? BuscarCepGoogleService() {
    cepController.addListener(_onCepAlterado);
  }

  /// Retorna o modelo pronto para salvar
  EnderecoUsuarioModel toModel(String idUsuario) {
    return EnderecoUsuarioModel(
      id: UniqueKey().toString(),
      idUsuario: idUsuario,
      idCidade: ufCidadeController.idCidadeSelecionada ?? 0,
      cep: cepController.text.trim(),
      logradouro: logradouroController.text.trim(),
      numero: numeroController.text.trim(),
      complemento: complementoController.text.trim(),
      bairro: bairroController.text.trim(),
      nomeCidade: nomeCidadeController.text.trim(),
      uf: ufController.text.trim().toUpperCase(),
      principal: true,
    );
  }

  /// Retorna um Map pronto para salvar no Firestore
  Map<String, dynamic> toEnderecoMap({String? idUsuario, bool? principal}) {
    return {
      'id': UniqueKey().toString(),
      'id_usuario': idUsuario ?? '',
      'id_cidade': ufCidadeController.idCidadeSelecionada ?? 0,
      'cep': cepController.text.trim(),
      'logradouro': logradouroController.text.trim(),
      'numero': numeroController.text.trim(),
      'complemento': complementoController.text.trim(),
      'bairro': bairroController.text.trim(),
      'nome_cidade': nomeCidadeController.text.trim(),
      'uf': ufController.text.trim().toUpperCase(),
      'principal': principal ?? false,
      'data_cadastro': DateTime.now(),
    };
  }

  Future<void> buscarPorCep({
    String? cepInformado,
    bool forcar = false,
  }) async {
    final cep =
        (cepInformado ?? cepController.text).replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      mensagemCep.value = '';
      if (forcar) {
        _mostrarErroCep('Informe um CEP válido com 8 dígitos.');
      }
      return;
    }
    if (consultandoCep.value) return;
    if (!forcar && cep == _ultimoCepConsultado) return;

    consultandoCep.value = true;
    mensagemCep.value = '';
    _ultimoCepConsultado = cep;

    try {
      final resultado = await _cepService.buscar(cep: cep);
      _preencherCampos(resultado);
      mensagemCep.value = '';
      if (numeroController.text.trim().isEmpty) {
        numeroFocusNode.requestFocus();
      }
    } on BuscarCepException catch (e) {
      _ultimoCepConsultado = '';
      mensagemCep.value = e.mensagem;
      _mostrarErroCep(e.mensagem);
    } catch (e) {
      _ultimoCepConsultado = '';
      const mensagem = 'Não foi possível consultar o CEP. Tente novamente.';
      mensagemCep.value = mensagem;
      _mostrarErroCep(mensagem);
    } finally {
      consultandoCep.value = false;
    }
  }

  void limpar() {
    cepController.clear();
    logradouroController.clear();
    numeroController.clear();
    complementoController.clear();
    bairroController.clear();
    nomeCidadeController.clear();
    ufController.clear();
    _ultimoCepConsultado = '';
    mensagemCep.value = '';
    consultandoCep.value = false;

    ufCidadeController.limpar();
  }

  void dispose() {
    cepController.removeListener(_onCepAlterado);
    cepController.dispose();
    logradouroController.dispose();
    numeroController.dispose();
    complementoController.dispose();
    bairroController.dispose();
    nomeCidadeController.dispose();
    ufController.dispose();
    numeroFocusNode.dispose();
  }

  void _onCepAlterado() {
    final cep = cepController.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      if (cep.length < 8) {
        _ultimoCepConsultado = '';
        mensagemCep.value = '';
      }
      return;
    }
    buscarPorCep(cepInformado: cep);
  }

  void _preencherCampos(EnderecoCepResultado resultado) {
    if (resultado.logradouro.isNotEmpty) {
      logradouroController.text = resultado.logradouro;
    }
    if (resultado.bairro.isNotEmpty) {
      bairroController.text = resultado.bairro;
    }
    if (resultado.cidade.isNotEmpty) {
      nomeCidadeController.text = resultado.cidade;
    }
    if (resultado.uf.isNotEmpty) {
      ufController.text = resultado.uf.toUpperCase();
    }
  }

  void _mostrarErroCep(String mensagem) {
    Get.rawSnackbar(
      title: 'CEP',
      message: mensagem,
      titleText: const Text(
        'CEP',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      messageText: Text(
        mensagem,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.orange.shade800.withValues(alpha: 0.95),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      icon: const Icon(Icons.location_off_outlined, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }
}
