import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';

class FaixaAbrangencia {
  FaixaAbrangencia._(Map<String, dynamic> dados)
      : ateKm = dados['ateKm'] as int,
        adicionalCentavos = dados['adicionalCentavos'] as int,
        mensalidadeCentavos = dados['mensalidadeCentavos'] as int;

  final int ateKm;
  final int adicionalCentavos;
  final int mensalidadeCentavos;
}

class TabelaAbrangencia {
  TabelaAbrangencia._(Map<String, dynamic> dados)
      : id = dados['id'] as String,
        vigencia = DateTime.parse(dados['vigencia'] as String),
        autorId = dados['autorId'] as String?,
        autorNome = dados['autorNome'] as String?,
        publicadaEm = DateTime.tryParse(dados['publicadaEm']?.toString() ?? ''),
        faixas = (dados['faixas'] as List)
            .map((item) =>
                FaixaAbrangencia._(Map<String, dynamic>.from(item as Map)))
            .toList(growable: false);

  final String id;
  final DateTime vigencia;
  final String? autorId;
  final String? autorNome;
  final DateTime? publicadaEm;
  final List<FaixaAbrangencia> faixas;
}

class CoberturaCadastrada {
  CoberturaCadastrada._(Map dados)
      : tipo = dados['tipo']?.toString() ?? '',
        raioKm = num.tryParse(dados['raioKm']?.toString() ?? ''),
        descricao = dados['descricao']?.toString().trim() ?? '';

  final String tipo;
  final num? raioKm;
  final String descricao;
}

typedef AbrangenciaFornecedor = ({
  int raioGratuitoKm,
  TabelaAbrangencia? tabela,
  List<CoberturaCadastrada> territorios,
});

typedef AbrangenciaAdmin = ({
  DateTime hoje,
  int raioGratuitoKm,
  int incrementoKm,
  TabelaAbrangencia? vigente,
  List<TabelaAbrangencia> historico,
});

class AbrangenciaRemoteDatasource {
  AbrangenciaRemoteDatasource({CallableSessaoGateway? gateway})
      : _gateway = gateway ?? FirebaseCallableSessaoGateway();

  final CallableSessaoGateway _gateway;

  Future<AbrangenciaFornecedor> consultarFornecedor() async {
    final dados = await _gateway.chamar('consultarAbrangenciaFornecedor', {});
    return (
      raioGratuitoKm: dados['raioGratuitoKm'] as int,
      tabela: _tabela(dados['tabela']),
      territorios: (dados['territorios'] as List)
          .map((item) => CoberturaCadastrada._(item as Map))
          .toList(growable: false),
    );
  }

  Future<AbrangenciaAdmin> consultarAdmin() async {
    final dados = await _gateway.chamar('consultarTabelasAbrangenciaAdmin', {});
    return (
      hoje: DateTime.parse(dados['hoje'] as String),
      raioGratuitoKm: dados['raioGratuitoKm'] as int,
      incrementoKm: dados['incrementoKm'] as int,
      vigente: _tabela(dados['vigente']),
      historico: (dados['historico'] as List)
          .map((item) => TabelaAbrangencia._(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
    );
  }

  Future<void> publicar({
    required DateTime vigencia,
    required List<int> valoresCentavos,
    required String pedidoId,
  }) async {
    await _gateway.chamar('publicarTabelaAbrangenciaAdmin', {
      'vigencia': vigencia.toIso8601String().split('T').first,
      'valoresCentavos': valoresCentavos,
      'pedidoId': pedidoId,
    });
  }

  TabelaAbrangencia? _tabela(Object? dados) => dados == null
      ? null
      : TabelaAbrangencia._(Map<String, dynamic>.from(dados as Map));
}
