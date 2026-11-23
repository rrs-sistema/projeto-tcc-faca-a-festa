import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';

class MembroOrganizacao {
  const MembroOrganizacao({
    required this.uid,
    required this.papel,
    required this.nome,
    required this.email,
  });

  final String uid;
  final String papel;
  final String nome;
  final String email;

  bool get ehDono => papel == 'dono';
}

class ConviteCoOrganizadorPendente {
  const ConviteCoOrganizadorPendente({
    required this.token,
    required this.email,
    required this.nome,
    this.expiraEm,
  });

  final String token;
  final String email;
  final String nome;
  final String? expiraEm;
}

class ResumoCoOrganizadores {
  const ResumoCoOrganizadores({
    required this.idEvento,
    required this.souDono,
    required this.maxCoOrganizadores,
    required this.membros,
    required this.convitesPendentes,
  });

  final String idEvento;
  final bool souDono;
  final int maxCoOrganizadores;
  final List<MembroOrganizacao> membros;
  final List<ConviteCoOrganizadorPendente> convitesPendentes;

  int get totalCoOrganizadores =>
      membros.where((m) => !m.ehDono).length;
}

class DetalheConviteCoOrganizador {
  const DetalheConviteCoOrganizador({
    required this.token,
    required this.status,
    required this.email,
    required this.nomeEvento,
    required this.idEvento,
    this.expiraEm,
  });

  final String token;
  final String status;
  final String email;
  final String nomeEvento;
  final String idEvento;
  final String? expiraEm;

  bool get pendente => status == 'pendente';
}

class CoOrganizadorService {
  CoOrganizadorService({FinanceiroCallableGateway? gateway})
      : _gateway = gateway ??
            FinanceiroCallableGateway(
              functions: Get.find<FirebaseFunctions>(),
              httpsClient: Get.isRegistered<CallableHttpsClient>()
                  ? Get.find<CallableHttpsClient>()
                  : null,
            );

  final FinanceiroCallableGateway _gateway;

  Future<ResumoCoOrganizadores> listar(String idEvento) async {
    final data = await _gateway.call('listarCoOrganizadores', {
      'idEvento': idEvento,
    });
    return ResumoCoOrganizadores(
      idEvento: data['idEvento']?.toString() ?? idEvento,
      souDono: data['souDono'] == true,
      maxCoOrganizadores: (data['maxCoOrganizadores'] as num?)?.toInt() ?? 3,
      membros: _membros(data['membros']),
      convitesPendentes: _convites(data['convitesPendentes']),
    );
  }

  Future<void> convidar({
    required String idEvento,
    required String email,
    String? nome,
  }) async {
    await _gateway.call('convidarCoOrganizador', {
      'idEvento': idEvento,
      'email': email.trim(),
      if (nome != null && nome.trim().isNotEmpty) 'nome': nome.trim(),
    });
  }

  Future<String> aceitar(String token) async {
    final data = await _gateway.call('aceitarConviteCoOrganizador', {
      'token': token.trim(),
    });
    return data['idEvento']?.toString() ?? '';
  }

  Future<void> remover({
    required String idEvento,
    required String uid,
  }) async {
    await _gateway.call('removerCoOrganizador', {
      'idEvento': idEvento,
      'uid': uid,
    });
  }

  Future<DetalheConviteCoOrganizador> consultar(String token) async {
    final data = await _gateway.call('consultarConviteCoOrganizador', {
      'token': token.trim(),
    });
    return DetalheConviteCoOrganizador(
      token: data['token']?.toString() ?? token,
      status: data['status']?.toString() ?? 'pendente',
      email: data['email']?.toString() ?? '',
      nomeEvento: data['nomeEvento']?.toString() ?? '',
      idEvento: data['idEvento']?.toString() ?? '',
      expiraEm: data['expiraEm']?.toString(),
    );
  }

  List<MembroOrganizacao> _membros(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          MembroOrganizacao(
            uid: item['uid']?.toString() ?? '',
            papel: item['papel']?.toString() ?? 'co_organizador',
            nome: item['nome']?.toString() ?? 'Organizador',
            email: item['email']?.toString() ?? '',
          ),
    ].where((m) => m.uid.isNotEmpty).toList();
  }

  List<ConviteCoOrganizadorPendente> _convites(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          ConviteCoOrganizadorPendente(
            token: item['token']?.toString() ?? '',
            email: item['email']?.toString() ?? '',
            nome: item['nome']?.toString() ?? '',
            expiraEm: item['expiraEm']?.toString(),
          ),
    ].where((c) => c.email.isNotEmpty).toList();
  }
}
