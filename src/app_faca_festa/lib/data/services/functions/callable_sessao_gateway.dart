import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/core/conectividade/exigir_conexao.dart';
import 'package:app_faca_festa/data/local/cache_offline_store.dart';
import 'callable_https_client.dart';
import 'financeiro_callable_gateway.dart';

abstract interface class CallableSessaoGateway {
  String? get usuario;
  Stream<String?> get sessoes;
  Future<Map<String, dynamic>> chamar(
      String funcao, Map<String, dynamic> dados);
}

/// Transporte existente: HTTPS autenticado no Windows e SDK nas demais plataformas.
///
/// Consultas guardam a última resposta por usuário e parâmetros; sem internet
/// a tela reabre com ela e com [chaveAtualizadoEm]. Ações que mudam dados
/// precisam do servidor e falham na hora, sem esperar o timeout.
class FirebaseCallableSessaoGateway implements CallableSessaoGateway {
  FirebaseCallableSessaoGateway(
      {FirebaseAuth? auth,
      FirebaseFunctions? functions,
      CallableHttpsClient? httpsClient,
      FinanceiroCallableGateway? gateway,
      CacheOfflineStore? cache})
      : _auth = auth ?? FirebaseAuth.instance,
        _cache = cache ?? GetStorageCacheOffline(),
        _gateway = gateway ??
            FinanceiroCallableGateway(
                functions: functions ??
                    (Get.isRegistered<FirebaseFunctions>()
                        ? Get.find<FirebaseFunctions>()
                        : FirebaseFunctions.instanceFor(
                            region: 'southamerica-east1')),
                httpsClient: httpsClient ??
                    (Get.isRegistered<CallableHttpsClient>()
                        ? Get.find<CallableHttpsClient>()
                        : null));
  final FirebaseAuth _auth;
  final FinanceiroCallableGateway _gateway;
  final CacheOfflineStore _cache;

  /// Presente só na resposta vinda do aparelho: quando o servidor respondeu.
  static const chaveAtualizadoEm = '_offline_atualizado_em';

  static bool somenteLeitura(String funcao) =>
      funcao.startsWith('consultar') || funcao.startsWith('historico');

  @override
  String? get usuario => _auth.currentUser?.uid;
  @override
  Stream<String?> get sessoes =>
      _auth.authStateChanges().map((u) => u?.uid).distinct();
  @override
  Future<Map<String, dynamic>> chamar(
      String funcao, Map<String, dynamic> dados) async {
    final leitura = somenteLeitura(funcao);
    final chave = leitura ? _chave(funcao, dados) : null;
    if (ConectividadeService.offlineAgora) {
      if (chave == null) {
        throw FirebaseFunctionsException(
            code: 'unavailable',
            message: const SemConexaoException('Esta ação').mensagem);
      }
      return _doAparelho(chave);
    }
    try {
      final resposta = await _gateway.call(funcao, dados);
      if (chave != null) {
        await _cache.gravar(chave, {
          'em': DateTime.now().toIso8601String(),
          'resposta': resposta,
        });
      }
      return resposta;
    } on FinanceiroCallableException catch (e) {
      if (chave != null && erroDeRede(e)) return _doAparelho(chave);
      throw FirebaseFunctionsException(
          code: e.code,
          message: e.message ?? 'Falha ao processar a operação.',
          details: null);
    } catch (e) {
      if (chave != null && erroDeRede(e)) return _doAparelho(chave);
      rethrow;
    }
  }

  String? _chave(String funcao, Map<String, dynamic> dados) {
    final uid = usuario;
    if (uid == null) return null;
    String parametros;
    try {
      parametros = jsonEncode(dados);
    } catch (_) {
      parametros = dados.toString();
    }
    return 'callable_${chaveEstavel(uid)}_${funcao}_${chaveEstavel(parametros)}';
  }

  Map<String, dynamic> _doAparelho(String chave) {
    final salvo = _cache.ler(chave);
    final resposta = salvo?['resposta'];
    if (resposta is! Map) {
      throw FirebaseFunctionsException(
          code: 'unavailable',
          message: 'Sem internet. Estas informações aparecem aqui depois da '
              'primeira consulta com conexão.');
    }
    return {
      ...Map<String, dynamic>.from(resposta),
      chaveAtualizadoEm: salvo?['em'],
    };
  }
}
