import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../models/auditoria/auditoria_evento_model.dart';
import '../../services/functions/callable_https_client.dart';
import '../../../domain/entities/auditoria_evento.dart';

class AuditoriaRemoteDatasource {
  AuditoriaRemoteDatasource({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
    required CallableHttpsClient httpsClient,
  })  : _db = firestore,
        _functions = functions,
        _https = httpsClient;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final CallableHttpsClient _https;

  Future<String> registrar(RegistroAuditoria registro) async {
    final payload = <String, dynamic>{
      'acao': registro.acao,
      'resumo': registro.resumo,
      'entidadeTipo': registro.entidadeTipo,
      'entidadeId': registro.entidadeId,
      'entidadeNome': registro.entidadeNome,
      'idFornecedor': registro.idFornecedor,
      'idEvento': registro.idEvento,
      'idServico': registro.idServico,
      'idCotacao': registro.idCotacao,
      'idOrcamento': registro.idOrcamento,
      'mudancas': registro.mudancas.map((m) => m.toMap()).toList(),
      'detalhe': registro.detalhe,
      'plataforma': registro.plataforma ?? _plataformaAtual(),
      'rota': registro.rota,
      'criadoEmLocal': DateTime.now().toUtc().toIso8601String(),
    };

    final data = await _chamarFunction('registrarAuditoria', payload);
    return (data['id'] ?? '').toString();
  }

  Future<void> registrarFalhaLogin(RegistroFalhaLogin registro) async {
    final payload = <String, dynamic>{
      'email': registro.email,
      'codigo': registro.codigo,
      'metodo': registro.metodo,
      'plataforma': registro.plataforma ?? _plataformaAtual(),
      'rota': registro.rota,
      'criadoEmLocal': DateTime.now().toUtc().toIso8601String(),
    };

    await _chamarFunctionPublica('registrarFalhaLogin', payload);
  }

  Future<List<AuditoriaEventoModel>> listar(AuditoriaConsulta consulta) async {
    final pagina = await listarPagina(consulta);
    return pagina.eventos.cast<AuditoriaEventoModel>();
  }

  Future<AuditoriaPagina> listarPagina(AuditoriaConsulta consulta) async {
    Query<Map<String, dynamic>> query = _db.collection('auditoria_eventos');

    if (!consulta.escopoAdmin) {
      final idFornecedor = (consulta.idFornecedor ?? '').trim();
      if (idFornecedor.isEmpty) {
        return const AuditoriaPagina(eventos: []);
      }
      query = query
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .where('visivel_fornecedor', isEqualTo: true);
    }

    query = _aplicarFiltrosAuditTrail(query, consulta);

    final eventos = <AuditoriaEventoModel>[];
    DateTime? proximoCursorCriadoEm;
    var temMais = false;

    if (consulta.origem != 'snapshot') {
      var queryOrdenada = query.orderBy('criado_em', descending: true);
      final cursor = consulta.cursorCriadoEm;
      if (cursor != null) {
        queryOrdenada = queryOrdenada.startAfter([Timestamp.fromDate(cursor)]);
      }

      final auditoriaSnapshot =
          await queryOrdenada.limit(consulta.limite + 1).get();

      temMais = auditoriaSnapshot.docs.length > consulta.limite;

      eventos.addAll(
        auditoriaSnapshot.docs
            .take(consulta.limite)
            .map((doc) => AuditoriaEventoModel.fromMap(doc.data(), id: doc.id)),
      );

      if (eventos.isNotEmpty) {
        proximoCursorCriadoEm = eventos.last.criadoEm;
      }
    }

    if (consulta.escopoAdmin &&
        consulta.incluirSnapshots &&
        consulta.cursorCriadoEm == null) {
      if (consulta.origem != null && consulta.origem != 'snapshot') {
        eventos.sort(_ordenarMaisRecentesPrimeiro);
        return AuditoriaPagina(
          eventos: eventos.take(consulta.limite).toList(),
          proximoCursorCriadoEm: proximoCursorCriadoEm,
          temMais: temMais,
        );
      }

      final snapshots = await _listarRegistrosImportantesDoSistema(
        limitePorColecao: consulta.limite.clamp(50, 300).toInt(),
      );
      eventos.addAll(snapshots.where((e) => _atendeFiltrosLocais(e, consulta)));
      eventos.sort(_ordenarMaisRecentesPrimeiro);
      if (eventos.length > consulta.limite) {
        return AuditoriaPagina(
          eventos: eventos.take(consulta.limite).toList(),
          proximoCursorCriadoEm: proximoCursorCriadoEm,
          temMais: temMais,
        );
      }
    }

    return AuditoriaPagina(
      eventos: eventos,
      proximoCursorCriadoEm: proximoCursorCriadoEm,
      temMais: temMais,
    );
  }

  Query<Map<String, dynamic>> _aplicarFiltrosAuditTrail(
    Query<Map<String, dynamic>> query,
    AuditoriaConsulta consulta,
  ) {
    if ((consulta.area ?? '').isNotEmpty) {
      query = query.where('area', isEqualTo: consulta.area);
    }
    if ((consulta.acao ?? '').isNotEmpty) {
      query = query.where('acao', isEqualTo: consulta.acao);
    }
    if ((consulta.nivel ?? '').isNotEmpty) {
      query = query.where('nivel', isEqualTo: consulta.nivel);
    }
    if ((consulta.origem ?? '').isNotEmpty && consulta.origem != 'audit') {
      query = query.where('origem', isEqualTo: consulta.origem);
    }
    if (consulta.criadoDe != null) {
      query = query.where(
        'criado_em',
        isGreaterThanOrEqualTo: Timestamp.fromDate(consulta.criadoDe!),
      );
    }
    if (consulta.criadoAte != null) {
      query = query.where(
        'criado_em',
        isLessThanOrEqualTo: Timestamp.fromDate(consulta.criadoAte!),
      );
    }
    return query;
  }

  bool _atendeFiltrosLocais(
    AuditoriaEventoModel evento,
    AuditoriaConsulta consulta,
  ) {
    if ((consulta.area ?? '').isNotEmpty && evento.area != consulta.area) {
      return false;
    }
    if ((consulta.acao ?? '').isNotEmpty && evento.acao != consulta.acao) {
      return false;
    }
    if ((consulta.nivel ?? '').isNotEmpty && evento.nivel != consulta.nivel) {
      return false;
    }
    if ((consulta.origem ?? '').isNotEmpty) {
      final origem = evento.origem == 'snapshot' ? 'snapshot' : 'audit';
      if (origem != consulta.origem) return false;
    }
    final criadoEm = evento.criadoEm;
    if (consulta.criadoDe != null &&
        (criadoEm == null || criadoEm.isBefore(consulta.criadoDe!))) {
      return false;
    }
    if (consulta.criadoAte != null &&
        (criadoEm == null || criadoEm.isAfter(consulta.criadoAte!))) {
      return false;
    }
    return true;
  }

  Future<List<AuditoriaEventoModel>> _listarRegistrosImportantesDoSistema({
    required int limitePorColecao,
  }) async {
    final snapshots = await Future.wait([
      _db.collection('usuarios').limit(limitePorColecao).get(),
      _db.collection('fornecedor').limit(limitePorColecao).get(),
      _db.collection('fornecedor_servico').limit(limitePorColecao).get(),
      _db.collection('servico_produto').limit(limitePorColecao).get(),
      _db.collection('categoria_servico').limit(limitePorColecao).get(),
      _db.collection('evento').limit(limitePorColecao).get(),
      _db.collection('orcamento').limit(limitePorColecao).get(),
      _db.collection('cotacao').limit(limitePorColecao).get(),
      _db.collection('territorio').limit(limitePorColecao).get(),
    ]);

    final eventos = [
      ..._eventosDeColecao(
        snapshots[0],
        acao: 'USUARIO_REGISTRADO',
        area: 'USUARIO',
        nivel: 'INFO',
        entidadeTipo: 'usuario',
        resumo: (data) => 'Usuário cadastrado na plataforma.',
        nome: (data) => _primeiroTexto(data, ['nome', 'email']),
      ),
      ..._eventosDeColecao(
        snapshots[1],
        acao: 'FORNECEDOR_REGISTRADO',
        area: 'FORNECEDOR',
        nivel: 'INFO',
        entidadeTipo: 'fornecedor',
        resumo: (data) {
          final status = _statusFornecedor(data);
          return status.isEmpty
              ? 'Fornecedor cadastrado na plataforma.'
              : 'Fornecedor cadastrado na plataforma ($status).';
        },
        nome: (data) => _primeiroTexto(
          data,
          ['nome_fantasia', 'nomeFantasia', 'razao_social', 'razaoSocial'],
        ),
        idFornecedor: (doc, data) => _primeiroTexto(
          data,
          ['id_fornecedor', 'idFornecedor', 'id_usuario', 'idUsuario'],
          fallback: doc.id,
        ),
      ),
      ..._eventosDeColecao(
        snapshots[2],
        acao: 'SERVICO_FORNECEDOR_REGISTRADO',
        area: 'SERVICO',
        nivel: 'INFO',
        entidadeTipo: 'fornecedor_servico',
        resumo: (data) => 'Serviço de fornecedor disponível para contratação.',
        nome: (data) => _primeiroTexto(
          data,
          ['nome', 'nome_servico', 'nomeServico', 'titulo'],
        ),
        idFornecedor: (_, data) => _primeiroTexto(
          data,
          ['id_fornecedor', 'idFornecedor'],
        ),
        idServico: (doc, data) => _primeiroTexto(
          data,
          ['id_servico', 'idServico', 'id'],
          fallback: doc.id,
        ),
      ),
      ..._eventosDeColecao(
        snapshots[3],
        acao: 'SERVICO_CATALOGO_REGISTRADO',
        area: 'CATALOGO',
        nivel: 'INFO',
        entidadeTipo: 'servico_produto',
        resumo: (data) => 'Serviço ou produto registrado no catálogo.',
        nome: (data) => _primeiroTexto(data, ['nome', 'titulo']),
        idServico: (doc, data) => _primeiroTexto(
          data,
          ['id_servico_produto', 'idServicoProduto', 'id'],
          fallback: doc.id,
        ),
      ),
      ..._eventosDeColecao(
        snapshots[4],
        acao: 'CATEGORIA_REGISTRADA',
        area: 'CATALOGO',
        nivel: 'INFO',
        entidadeTipo: 'categoria_servico',
        resumo: (data) => 'Categoria de serviço registrada no catálogo.',
        nome: (data) => _primeiroTexto(data, ['nome', 'descricao']),
      ),
      ..._eventosDeColecao(
        snapshots[5],
        acao: 'EVENTO_REGISTRADO',
        area: 'EVENTO',
        nivel: 'INFO',
        entidadeTipo: 'evento',
        resumo: (data) {
          final status = _primeiroTexto(data, ['status']);
          return status.isEmpty
              ? 'Evento cadastrado no sistema.'
              : 'Evento cadastrado no sistema ($status).';
        },
        nome: (data) => _primeiroTexto(
          data,
          ['nome_evento', 'nomeEvento', 'nome', 'titulo'],
        ),
        idEvento: (doc, data) => _primeiroTexto(
          data,
          ['id_evento', 'idEvento', 'id'],
          fallback: doc.id,
        ),
      ),
      ..._eventosDeColecao(
        snapshots[6],
        acao: 'ORCAMENTO_REGISTRADO',
        area: 'ORCAMENTO',
        nivel: 'INFO',
        entidadeTipo: 'orcamento',
        resumo: (data) {
          final status = _primeiroTexto(data, ['status']);
          return status.isEmpty
              ? 'Orçamento registrado no sistema.'
              : 'Orçamento registrado no sistema ($status).';
        },
        nome: (data) => _primeiroTexto(
          data,
          ['nome', 'anotacoes', 'categoria_nome', 'categoriaNome'],
        ),
        idEvento: (_, data) => _primeiroTexto(data, ['id_evento', 'idEvento']),
        idFornecedor: (_, data) => _primeiroTexto(
          data,
          ['id_fornecedor', 'idFornecedor'],
        ),
        idOrcamento: (doc, data) => _primeiroTexto(
          data,
          ['id_orcamento', 'idOrcamento', 'id'],
          fallback: doc.id,
        ),
      ),
      ..._eventosDeColecao(
        snapshots[7],
        acao: 'COTACAO_REGISTRADA',
        area: 'COTACAO',
        nivel: 'INFO',
        entidadeTipo: 'cotacao',
        resumo: (data) {
          final status = _primeiroTexto(data, ['status']);
          return status.isEmpty
              ? 'Cotação registrada no sistema.'
              : 'Cotação registrada no sistema ($status).';
        },
        nome: (data) => _primeiroTexto(
          data,
          ['categoria_nome', 'categoriaNome', 'observacao', 'descricao'],
        ),
        idEvento: (_, data) => _primeiroTexto(data, ['id_evento', 'idEvento']),
        idCotacao: (doc, data) => _primeiroTexto(
          data,
          ['id_cotacao', 'idCotacao', 'id'],
          fallback: doc.id,
        ),
      ),
      ..._eventosDeColecao(
        snapshots[8],
        acao: 'TERRITORIO_REGISTRADO',
        area: 'FORNECEDOR',
        nivel: 'INFO',
        entidadeTipo: 'territorio',
        resumo: (data) {
          final raio = _primeiroTexto(data, ['raio_km', 'raioKm']);
          return raio.isEmpty
              ? 'Território de atendimento registrado.'
              : 'Território de atendimento registrado (${raio}km).';
        },
        nome: (data) => _primeiroTexto(
          data,
          ['descricao', 'tipo_cobertura', 'tipoCobertura'],
        ),
        idFornecedor: (_, data) => _primeiroTexto(
          data,
          ['id_fornecedor', 'idFornecedor'],
        ),
      ),
    ];

    return _enriquecerAutoresDosSnapshots(eventos);
  }

  Future<List<AuditoriaEventoModel>> _enriquecerAutoresDosSnapshots(
    List<AuditoriaEventoModel> eventos,
  ) async {
    final ids = eventos
        .map((e) => (e.atorUid ?? '').trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return eventos;

    final usuariosPorId = <String, Map<String, dynamic>>{};
    for (var inicio = 0; inicio < ids.length; inicio += 30) {
      final fim = (inicio + 30).clamp(0, ids.length);
      final lote = ids.sublist(inicio, fim);
      final snapshot = await _db
          .collection('usuarios')
          .where(FieldPath.documentId, whereIn: lote)
          .get();
      for (final doc in snapshot.docs) {
        usuariosPorId[doc.id] = doc.data();
      }
    }

    return eventos.map((evento) {
      final uid = (evento.atorUid ?? '').trim();
      final usuario = usuariosPorId[uid];
      if (usuario == null) return evento;

      final nome = (evento.atorNome ?? '').trim().isNotEmpty
          ? evento.atorNome
          : _primeiroTexto(usuario, const [
              'nome',
              'nome_completo',
              'nomeCompleto',
              'display_name',
              'displayName',
            ]);
      final email = (evento.atorEmail ?? '').trim().isNotEmpty
          ? evento.atorEmail
          : _primeiroTexto(usuario, const ['email']);
      final tipo = _tipoUsuarioNormalizado(
            _primeiroTexto(usuario, const ['tipo', 'tipo_usuario']),
          ) ??
          evento.atorTipo;

      return AuditoriaEventoModel(
        id: evento.id,
        acao: evento.acao,
        area: evento.area,
        nivel: evento.nivel,
        resumo: evento.resumo,
        entidadeTipo: evento.entidadeTipo,
        entidadeId: evento.entidadeId,
        entidadeNome: evento.entidadeNome,
        idFornecedor: evento.idFornecedor,
        idEvento: evento.idEvento,
        idServico: evento.idServico,
        idCotacao: evento.idCotacao,
        idOrcamento: evento.idOrcamento,
        atorUid: evento.atorUid,
        atorNome: _nullSeVazio(nome),
        atorEmail: _nullSeVazio(email),
        atorTipo: tipo,
        atorAuthType: evento.atorAuthType,
        mudancas: evento.mudancas,
        detalhe: evento.detalhe,
        visivelFornecedor: evento.visivelFornecedor,
        plataforma: evento.plataforma,
        rota: evento.rota,
        origem: evento.origem,
        operacao: evento.operacao,
        documentPath: evento.documentPath,
        sourceEventId: evento.sourceEventId,
        criadoEm: evento.criadoEm,
      );
    }).toList();
  }

  List<AuditoriaEventoModel> _eventosDeColecao(
    QuerySnapshot<Map<String, dynamic>> snapshot, {
    required String acao,
    required String area,
    required String nivel,
    required String entidadeTipo,
    required String Function(Map<String, dynamic> data) resumo,
    required String Function(Map<String, dynamic> data) nome,
    String Function(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      Map<String, dynamic> data,
    )? idFornecedor,
    String Function(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      Map<String, dynamic> data,
    )? idEvento,
    String Function(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      Map<String, dynamic> data,
    )? idServico,
    String Function(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      Map<String, dynamic> data,
    )? idCotacao,
    String Function(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      Map<String, dynamic> data,
    )? idOrcamento,
  }) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final entidadeNome = nome(data);
      return AuditoriaEventoModel(
        id: '${entidadeTipo}_${doc.id}',
        acao: acao,
        area: area,
        nivel: nivel,
        resumo: resumo(data),
        entidadeTipo: entidadeTipo,
        entidadeId: doc.id,
        entidadeNome: entidadeNome.isEmpty ? null : entidadeNome,
        idFornecedor: _nullSeVazio(idFornecedor?.call(doc, data)),
        idEvento: _nullSeVazio(idEvento?.call(doc, data)),
        idServico: _nullSeVazio(idServico?.call(doc, data)),
        idCotacao: _nullSeVazio(idCotacao?.call(doc, data)),
        idOrcamento: _nullSeVazio(idOrcamento?.call(doc, data)),
        atorUid: _nullSeVazio(_atorUidDoRegistro(data)),
        atorNome: _nullSeVazio(_atorNomeDoRegistro(data)),
        atorEmail: _nullSeVazio(_atorEmailDoRegistro(data)),
        atorTipo: _atorTipoDoRegistro(data),
        detalhe: _detalheSnapshot(doc, data),
        origem: 'snapshot',
        documentPath: '${doc.reference.parent.path}/${doc.id}',
        criadoEm: _dataDoRegistro(data),
      );
    }).toList();
  }

  Map<String, dynamic> _detalheSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, dynamic> data,
  ) {
    return {
      'tipo': 'snapshot',
      'document_path': '${doc.reference.parent.path}/${doc.id}',
      'dados': _sanitizarDadosSnapshot(data),
    };
  }

  Map<String, dynamic> _sanitizarDadosSnapshot(Map<String, dynamic> data) {
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {
      for (final entry in entries.take(80))
        entry.key: _campoSensivel(entry.key)
            ? '[redigido]'
            : _valorSeguroSnapshot(entry.value),
    };
  }

  bool _campoSensivel(String campo) {
    final normalizado = campo.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9_]'),
          '',
        );
    return const [
      'senha',
      'password',
      'passwd',
      'token',
      'secret',
      'segredo',
      'codigo',
      'code',
      'otp',
      'totp',
      'mfa',
      'pin',
      'apikey',
      'api_key',
      'authorization',
      'auth',
    ].any(normalizado.contains);
  }

  dynamic _valorSeguroSnapshot(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is GeoPoint) {
      return {
        'latitude': value.latitude,
        'longitude': value.longitude,
      };
    }
    if (value is DocumentReference) return value.path;
    if (value is Iterable) {
      return value.map(_valorSeguroSnapshot).toList();
    }
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _valorSeguroSnapshot(item)),
      );
    }
    return value.toString();
  }

  int _ordenarMaisRecentesPrimeiro(
    AuditoriaEventoModel a,
    AuditoriaEventoModel b,
  ) {
    final dataA = a.criadoEm;
    final dataB = b.criadoEm;
    if (dataA == null && dataB == null) {
      return a.resumo.compareTo(b.resumo);
    }
    if (dataA == null) return 1;
    if (dataB == null) return -1;
    return dataB.compareTo(dataA);
  }

  DateTime? _dataDoRegistro(Map<String, dynamic> data) {
    for (final campo in const [
      'criado_em',
      'criadoEm',
      'created_at',
      'createdAt',
      'data_cadastro',
      'dataCadastro',
      'data_criacao',
      'dataCriacao',
      'data_envio',
      'dataEnvio',
      'updated_at',
      'updatedAt',
      'atualizado_em',
      'atualizadoEm',
      'data',
    ]) {
      final dataCampo = _toDate(data[campo]);
      if (dataCampo != null) return dataCampo;
    }
    return null;
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _primeiroTexto(
    Map<String, dynamic> data,
    List<String> campos, {
    String fallback = '',
  }) {
    for (final campo in campos) {
      final texto = (data[campo] ?? '').toString().trim();
      if (texto.isNotEmpty) return texto;
    }
    return fallback;
  }

  String _statusFornecedor(Map<String, dynamic> data) {
    final ativo = data['ativo'];
    final apto = data['apto_para_operar'] ?? data['aptoParaOperar'];
    if (ativo == false) return 'inativo';
    if (apto == true) return 'apto para operar';
    return 'pendente';
  }

  String _atorUidDoRegistro(Map<String, dynamic> data) {
    return _primeiroTexto(data, const [
      'ator_uid',
      'atorUid',
      'id_usuario_solicitante',
      'idUsuarioSolicitante',
      'id_usuario',
      'idUsuario',
      'criado_por',
      'criadoPor',
      'atualizado_por',
      'atualizadoPor',
      'created_by',
      'createdBy',
      'updated_by',
      'updatedBy',
    ]);
  }

  String _atorNomeDoRegistro(Map<String, dynamic> data) {
    return _primeiroTexto(data, const [
      'ator_nome',
      'atorNome',
      'nome_usuario_solicitante',
      'nomeUsuarioSolicitante',
      'nome_usuario',
      'nomeUsuario',
      'usuario_nome',
      'usuarioNome',
    ]);
  }

  String _atorEmailDoRegistro(Map<String, dynamic> data) {
    return _primeiroTexto(data, const [
      'ator_email',
      'atorEmail',
      'email_usuario',
      'emailUsuario',
      'usuario_email',
      'usuarioEmail',
      'email',
    ]);
  }

  String? _atorTipoDoRegistro(Map<String, dynamic> data) {
    final tipo = _tipoUsuarioNormalizado(_primeiroTexto(data, const [
      'ator_tipo',
      'atorTipo',
      'tipo_usuario',
      'tipoUsuario',
      'tipo',
    ]));
    if (tipo != null) return tipo;
    if (_atorUidDoRegistro(data).isNotEmpty) return 'O';
    return 'S';
  }

  String? _tipoUsuarioNormalizado(String? value) {
    final tipo = (value ?? '').trim().toUpperCase();
    if (const ['A', 'ADMIN', 'ADMINISTRADOR'].contains(tipo)) return 'A';
    if (const ['F', 'FORNECEDOR'].contains(tipo)) return 'F';
    if (const ['O', 'ORGANIZADOR', 'USUARIO', 'USUÁRIO'].contains(tipo)) {
      return 'O';
    }
    if (const ['S', 'SISTEMA'].contains(tipo)) return 'S';
    return null;
  }

  String? _nullSeVazio(String? value) {
    final texto = (value ?? '').trim();
    return texto.isEmpty ? null : texto;
  }

  Future<Map<String, dynamic>> _chamarFunction(
    String nome,
    Map<String, dynamic> data,
  ) async {
    if (CallableHttpsClient.necessarioNaPlataformaAtual) {
      return _https.call(nome, data);
    }

    final callable = _functions.httpsCallable(
      nome,
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final resultado = await callable.call(data);
    final payload = resultado.data;
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  Future<Map<String, dynamic>> _chamarFunctionPublica(
    String nome,
    Map<String, dynamic> data,
  ) async {
    if (CallableHttpsClient.necessarioNaPlataformaAtual) {
      return _https.callPublic(nome, data);
    }

    final callable = _functions.httpsCallable(
      nome,
      options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
    );
    final resultado = await callable.call(data);
    final payload = resultado.data;
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  String _plataformaAtual() {
    if (kIsWeb) return 'WEB';
    return defaultTargetPlatform.name.toUpperCase();
  }
}
