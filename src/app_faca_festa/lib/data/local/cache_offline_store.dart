import 'dart:convert';

import 'package:get_storage/get_storage.dart';

export 'package:app_faca_festa/core/conectividade/erro_de_rede.dart';

/// Respostas que só o servidor produz (convite aberto, painéis), guardadas
/// para reabrir a tela sem internet.
abstract class CacheOfflineStore {
  Map<String, dynamic>? ler(String chave);
  Future<void> gravar(String chave, Map<String, dynamic> valor);
  Future<void> remover(String chave);
}

class GetStorageCacheOffline implements CacheOfflineStore {
  GetStorageCacheOffline([GetStorage? storage]) : _storage = storage;

  static const _prefixo = 'cache_offline_v1_';
  GetStorage? _storage;

  // GetStorage sem `init()` lança; sem cache o app segue como antes.
  GetStorage? get _box {
    try {
      return _storage ??= GetStorage();
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? ler(String chave) {
    try {
      final valor = _box?.read(_prefixo + chave);
      if (valor is Map) return Map<String, dynamic>.from(valor);
      if (valor is String) {
        final decodificado = jsonDecode(valor);
        if (decodificado is Map) return Map<String, dynamic>.from(decodificado);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> gravar(String chave, Map<String, dynamic> valor) async {
    try {
      await _box?.write(_prefixo + chave, jsonEncode(valor));
    } catch (_) {}
  }

  @override
  Future<void> remover(String chave) async {
    try {
      await _box?.remove(_prefixo + chave);
    } catch (_) {}
  }
}

class MemoriaCacheOffline implements CacheOfflineStore {
  final valores = <String, String>{};

  @override
  Map<String, dynamic>? ler(String chave) {
    final valor = valores[chave];
    return valor == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(valor) as Map);
  }

  @override
  Future<void> gravar(String chave, Map<String, dynamic> valor) async {
    valores[chave] = jsonEncode(valor);
  }

  @override
  Future<void> remover(String chave) async {
    valores.remove(chave);
  }
}

/// Hash estável entre execuções (o `hashCode` de String não é).
String chaveEstavel(String texto) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(texto)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
