// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GiftLocalsTable extends GiftLocals
    with TableInfo<$GiftLocalsTable, GiftLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GiftLocalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _giftIdMeta = const VerificationMeta('giftId');
  @override
  late final GeneratedColumn<String> giftId = GeneratedColumn<String>(
      'gift_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _eventoIdMeta =
      const VerificationMeta('eventoId');
  @override
  late final GeneratedColumn<String> eventoId = GeneratedColumn<String>(
      'evento_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descricaoMeta =
      const VerificationMeta('descricao');
  @override
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
      'descricao', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoriaMeta =
      const VerificationMeta('categoria');
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
      'categoria', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
      'tipo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<double> valor = GeneratedColumn<double>(
      'valor', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _valorArrecadadoMeta =
      const VerificationMeta('valorArrecadado');
  @override
  late final GeneratedColumn<double> valorArrecadado = GeneratedColumn<double>(
      'valor_arrecadado', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _metaValorMeta =
      const VerificationMeta('metaValor');
  @override
  late final GeneratedColumn<double> metaValor = GeneratedColumn<double>(
      'meta_valor', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _lojaMeta = const VerificationMeta('loja');
  @override
  late final GeneratedColumn<String> loja = GeneratedColumn<String>(
      'loja', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _linkMeta = const VerificationMeta('link');
  @override
  late final GeneratedColumn<String> link = GeneratedColumn<String>(
      'link', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pixMeta = const VerificationMeta('pix');
  @override
  late final GeneratedColumn<String> pix = GeneratedColumn<String>(
      'pix', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imagemMeta = const VerificationMeta('imagem');
  @override
  late final GeneratedColumn<String> imagem = GeneratedColumn<String>(
      'imagem', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('disponivel'));
  static const VerificationMeta _reservadoPorMeta =
      const VerificationMeta('reservadoPor');
  @override
  late final GeneratedColumn<String> reservadoPor = GeneratedColumn<String>(
      'reservado_por', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reservadoUidMeta =
      const VerificationMeta('reservadoUid');
  @override
  late final GeneratedColumn<String> reservadoUid = GeneratedColumn<String>(
      'reservado_uid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dataReservaMeta =
      const VerificationMeta('dataReserva');
  @override
  late final GeneratedColumn<DateTime> dataReserva = GeneratedColumn<DateTime>(
      'data_reserva', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        giftId,
        eventoId,
        nome,
        descricao,
        categoria,
        tipo,
        valor,
        valorArrecadado,
        metaValor,
        loja,
        link,
        pix,
        imagem,
        status,
        reservadoPor,
        reservadoUid,
        dataReserva,
        deleted,
        synced,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gift_locals';
  @override
  VerificationContext validateIntegrity(Insertable<GiftLocal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('gift_id')) {
      context.handle(_giftIdMeta,
          giftId.isAcceptableOrUnknown(data['gift_id']!, _giftIdMeta));
    } else if (isInserting) {
      context.missing(_giftIdMeta);
    }
    if (data.containsKey('evento_id')) {
      context.handle(_eventoIdMeta,
          eventoId.isAcceptableOrUnknown(data['evento_id']!, _eventoIdMeta));
    } else if (isInserting) {
      context.missing(_eventoIdMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('descricao')) {
      context.handle(_descricaoMeta,
          descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta));
    }
    if (data.containsKey('categoria')) {
      context.handle(_categoriaMeta,
          categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta));
    }
    if (data.containsKey('tipo')) {
      context.handle(
          _tipoMeta, tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta));
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
          _valorMeta, valor.isAcceptableOrUnknown(data['valor']!, _valorMeta));
    }
    if (data.containsKey('valor_arrecadado')) {
      context.handle(
          _valorArrecadadoMeta,
          valorArrecadado.isAcceptableOrUnknown(
              data['valor_arrecadado']!, _valorArrecadadoMeta));
    }
    if (data.containsKey('meta_valor')) {
      context.handle(_metaValorMeta,
          metaValor.isAcceptableOrUnknown(data['meta_valor']!, _metaValorMeta));
    }
    if (data.containsKey('loja')) {
      context.handle(
          _lojaMeta, loja.isAcceptableOrUnknown(data['loja']!, _lojaMeta));
    }
    if (data.containsKey('link')) {
      context.handle(
          _linkMeta, link.isAcceptableOrUnknown(data['link']!, _linkMeta));
    }
    if (data.containsKey('pix')) {
      context.handle(
          _pixMeta, pix.isAcceptableOrUnknown(data['pix']!, _pixMeta));
    }
    if (data.containsKey('imagem')) {
      context.handle(_imagemMeta,
          imagem.isAcceptableOrUnknown(data['imagem']!, _imagemMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('reservado_por')) {
      context.handle(
          _reservadoPorMeta,
          reservadoPor.isAcceptableOrUnknown(
              data['reservado_por']!, _reservadoPorMeta));
    }
    if (data.containsKey('reservado_uid')) {
      context.handle(
          _reservadoUidMeta,
          reservadoUid.isAcceptableOrUnknown(
              data['reservado_uid']!, _reservadoUidMeta));
    }
    if (data.containsKey('data_reserva')) {
      context.handle(
          _dataReservaMeta,
          dataReserva.isAcceptableOrUnknown(
              data['data_reserva']!, _dataReservaMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GiftLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GiftLocal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      giftId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gift_id'])!,
      eventoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}evento_id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      descricao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}descricao']),
      categoria: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}categoria']),
      tipo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo'])!,
      valor: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}valor']),
      valorArrecadado: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}valor_arrecadado'])!,
      metaValor: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}meta_valor']),
      loja: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}loja']),
      link: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}link']),
      pix: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pix']),
      imagem: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}imagem']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      reservadoPor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reservado_por']),
      reservadoUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reservado_uid']),
      dataReserva: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}data_reserva']),
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $GiftLocalsTable createAlias(String alias) {
    return $GiftLocalsTable(attachedDatabase, alias);
  }
}

class GiftLocal extends DataClass implements Insertable<GiftLocal> {
  final int id;
  final String giftId;
  final String eventoId;
  final String nome;
  final String? descricao;
  final String? categoria;
  final String tipo;
  final double? valor;
  final double valorArrecadado;
  final double? metaValor;
  final String? loja;
  final String? link;
  final String? pix;
  final String? imagem;
  final String status;
  final String? reservadoPor;
  final String? reservadoUid;
  final DateTime? dataReserva;
  final bool deleted;
  final bool synced;
  final DateTime createdAt;
  final DateTime updatedAt;
  const GiftLocal(
      {required this.id,
      required this.giftId,
      required this.eventoId,
      required this.nome,
      this.descricao,
      this.categoria,
      required this.tipo,
      this.valor,
      required this.valorArrecadado,
      this.metaValor,
      this.loja,
      this.link,
      this.pix,
      this.imagem,
      required this.status,
      this.reservadoPor,
      this.reservadoUid,
      this.dataReserva,
      required this.deleted,
      required this.synced,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['gift_id'] = Variable<String>(giftId);
    map['evento_id'] = Variable<String>(eventoId);
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || descricao != null) {
      map['descricao'] = Variable<String>(descricao);
    }
    if (!nullToAbsent || categoria != null) {
      map['categoria'] = Variable<String>(categoria);
    }
    map['tipo'] = Variable<String>(tipo);
    if (!nullToAbsent || valor != null) {
      map['valor'] = Variable<double>(valor);
    }
    map['valor_arrecadado'] = Variable<double>(valorArrecadado);
    if (!nullToAbsent || metaValor != null) {
      map['meta_valor'] = Variable<double>(metaValor);
    }
    if (!nullToAbsent || loja != null) {
      map['loja'] = Variable<String>(loja);
    }
    if (!nullToAbsent || link != null) {
      map['link'] = Variable<String>(link);
    }
    if (!nullToAbsent || pix != null) {
      map['pix'] = Variable<String>(pix);
    }
    if (!nullToAbsent || imagem != null) {
      map['imagem'] = Variable<String>(imagem);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || reservadoPor != null) {
      map['reservado_por'] = Variable<String>(reservadoPor);
    }
    if (!nullToAbsent || reservadoUid != null) {
      map['reservado_uid'] = Variable<String>(reservadoUid);
    }
    if (!nullToAbsent || dataReserva != null) {
      map['data_reserva'] = Variable<DateTime>(dataReserva);
    }
    map['deleted'] = Variable<bool>(deleted);
    map['synced'] = Variable<bool>(synced);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GiftLocalsCompanion toCompanion(bool nullToAbsent) {
    return GiftLocalsCompanion(
      id: Value(id),
      giftId: Value(giftId),
      eventoId: Value(eventoId),
      nome: Value(nome),
      descricao: descricao == null && nullToAbsent
          ? const Value.absent()
          : Value(descricao),
      categoria: categoria == null && nullToAbsent
          ? const Value.absent()
          : Value(categoria),
      tipo: Value(tipo),
      valor:
          valor == null && nullToAbsent ? const Value.absent() : Value(valor),
      valorArrecadado: Value(valorArrecadado),
      metaValor: metaValor == null && nullToAbsent
          ? const Value.absent()
          : Value(metaValor),
      loja: loja == null && nullToAbsent ? const Value.absent() : Value(loja),
      link: link == null && nullToAbsent ? const Value.absent() : Value(link),
      pix: pix == null && nullToAbsent ? const Value.absent() : Value(pix),
      imagem:
          imagem == null && nullToAbsent ? const Value.absent() : Value(imagem),
      status: Value(status),
      reservadoPor: reservadoPor == null && nullToAbsent
          ? const Value.absent()
          : Value(reservadoPor),
      reservadoUid: reservadoUid == null && nullToAbsent
          ? const Value.absent()
          : Value(reservadoUid),
      dataReserva: dataReserva == null && nullToAbsent
          ? const Value.absent()
          : Value(dataReserva),
      deleted: Value(deleted),
      synced: Value(synced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GiftLocal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GiftLocal(
      id: serializer.fromJson<int>(json['id']),
      giftId: serializer.fromJson<String>(json['giftId']),
      eventoId: serializer.fromJson<String>(json['eventoId']),
      nome: serializer.fromJson<String>(json['nome']),
      descricao: serializer.fromJson<String?>(json['descricao']),
      categoria: serializer.fromJson<String?>(json['categoria']),
      tipo: serializer.fromJson<String>(json['tipo']),
      valor: serializer.fromJson<double?>(json['valor']),
      valorArrecadado: serializer.fromJson<double>(json['valorArrecadado']),
      metaValor: serializer.fromJson<double?>(json['metaValor']),
      loja: serializer.fromJson<String?>(json['loja']),
      link: serializer.fromJson<String?>(json['link']),
      pix: serializer.fromJson<String?>(json['pix']),
      imagem: serializer.fromJson<String?>(json['imagem']),
      status: serializer.fromJson<String>(json['status']),
      reservadoPor: serializer.fromJson<String?>(json['reservadoPor']),
      reservadoUid: serializer.fromJson<String?>(json['reservadoUid']),
      dataReserva: serializer.fromJson<DateTime?>(json['dataReserva']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      synced: serializer.fromJson<bool>(json['synced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'giftId': serializer.toJson<String>(giftId),
      'eventoId': serializer.toJson<String>(eventoId),
      'nome': serializer.toJson<String>(nome),
      'descricao': serializer.toJson<String?>(descricao),
      'categoria': serializer.toJson<String?>(categoria),
      'tipo': serializer.toJson<String>(tipo),
      'valor': serializer.toJson<double?>(valor),
      'valorArrecadado': serializer.toJson<double>(valorArrecadado),
      'metaValor': serializer.toJson<double?>(metaValor),
      'loja': serializer.toJson<String?>(loja),
      'link': serializer.toJson<String?>(link),
      'pix': serializer.toJson<String?>(pix),
      'imagem': serializer.toJson<String?>(imagem),
      'status': serializer.toJson<String>(status),
      'reservadoPor': serializer.toJson<String?>(reservadoPor),
      'reservadoUid': serializer.toJson<String?>(reservadoUid),
      'dataReserva': serializer.toJson<DateTime?>(dataReserva),
      'deleted': serializer.toJson<bool>(deleted),
      'synced': serializer.toJson<bool>(synced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GiftLocal copyWith(
          {int? id,
          String? giftId,
          String? eventoId,
          String? nome,
          Value<String?> descricao = const Value.absent(),
          Value<String?> categoria = const Value.absent(),
          String? tipo,
          Value<double?> valor = const Value.absent(),
          double? valorArrecadado,
          Value<double?> metaValor = const Value.absent(),
          Value<String?> loja = const Value.absent(),
          Value<String?> link = const Value.absent(),
          Value<String?> pix = const Value.absent(),
          Value<String?> imagem = const Value.absent(),
          String? status,
          Value<String?> reservadoPor = const Value.absent(),
          Value<String?> reservadoUid = const Value.absent(),
          Value<DateTime?> dataReserva = const Value.absent(),
          bool? deleted,
          bool? synced,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      GiftLocal(
        id: id ?? this.id,
        giftId: giftId ?? this.giftId,
        eventoId: eventoId ?? this.eventoId,
        nome: nome ?? this.nome,
        descricao: descricao.present ? descricao.value : this.descricao,
        categoria: categoria.present ? categoria.value : this.categoria,
        tipo: tipo ?? this.tipo,
        valor: valor.present ? valor.value : this.valor,
        valorArrecadado: valorArrecadado ?? this.valorArrecadado,
        metaValor: metaValor.present ? metaValor.value : this.metaValor,
        loja: loja.present ? loja.value : this.loja,
        link: link.present ? link.value : this.link,
        pix: pix.present ? pix.value : this.pix,
        imagem: imagem.present ? imagem.value : this.imagem,
        status: status ?? this.status,
        reservadoPor:
            reservadoPor.present ? reservadoPor.value : this.reservadoPor,
        reservadoUid:
            reservadoUid.present ? reservadoUid.value : this.reservadoUid,
        dataReserva: dataReserva.present ? dataReserva.value : this.dataReserva,
        deleted: deleted ?? this.deleted,
        synced: synced ?? this.synced,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  GiftLocal copyWithCompanion(GiftLocalsCompanion data) {
    return GiftLocal(
      id: data.id.present ? data.id.value : this.id,
      giftId: data.giftId.present ? data.giftId.value : this.giftId,
      eventoId: data.eventoId.present ? data.eventoId.value : this.eventoId,
      nome: data.nome.present ? data.nome.value : this.nome,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      valor: data.valor.present ? data.valor.value : this.valor,
      valorArrecadado: data.valorArrecadado.present
          ? data.valorArrecadado.value
          : this.valorArrecadado,
      metaValor: data.metaValor.present ? data.metaValor.value : this.metaValor,
      loja: data.loja.present ? data.loja.value : this.loja,
      link: data.link.present ? data.link.value : this.link,
      pix: data.pix.present ? data.pix.value : this.pix,
      imagem: data.imagem.present ? data.imagem.value : this.imagem,
      status: data.status.present ? data.status.value : this.status,
      reservadoPor: data.reservadoPor.present
          ? data.reservadoPor.value
          : this.reservadoPor,
      reservadoUid: data.reservadoUid.present
          ? data.reservadoUid.value
          : this.reservadoUid,
      dataReserva:
          data.dataReserva.present ? data.dataReserva.value : this.dataReserva,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      synced: data.synced.present ? data.synced.value : this.synced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GiftLocal(')
          ..write('id: $id, ')
          ..write('giftId: $giftId, ')
          ..write('eventoId: $eventoId, ')
          ..write('nome: $nome, ')
          ..write('descricao: $descricao, ')
          ..write('categoria: $categoria, ')
          ..write('tipo: $tipo, ')
          ..write('valor: $valor, ')
          ..write('valorArrecadado: $valorArrecadado, ')
          ..write('metaValor: $metaValor, ')
          ..write('loja: $loja, ')
          ..write('link: $link, ')
          ..write('pix: $pix, ')
          ..write('imagem: $imagem, ')
          ..write('status: $status, ')
          ..write('reservadoPor: $reservadoPor, ')
          ..write('reservadoUid: $reservadoUid, ')
          ..write('dataReserva: $dataReserva, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        giftId,
        eventoId,
        nome,
        descricao,
        categoria,
        tipo,
        valor,
        valorArrecadado,
        metaValor,
        loja,
        link,
        pix,
        imagem,
        status,
        reservadoPor,
        reservadoUid,
        dataReserva,
        deleted,
        synced,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GiftLocal &&
          other.id == this.id &&
          other.giftId == this.giftId &&
          other.eventoId == this.eventoId &&
          other.nome == this.nome &&
          other.descricao == this.descricao &&
          other.categoria == this.categoria &&
          other.tipo == this.tipo &&
          other.valor == this.valor &&
          other.valorArrecadado == this.valorArrecadado &&
          other.metaValor == this.metaValor &&
          other.loja == this.loja &&
          other.link == this.link &&
          other.pix == this.pix &&
          other.imagem == this.imagem &&
          other.status == this.status &&
          other.reservadoPor == this.reservadoPor &&
          other.reservadoUid == this.reservadoUid &&
          other.dataReserva == this.dataReserva &&
          other.deleted == this.deleted &&
          other.synced == this.synced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GiftLocalsCompanion extends UpdateCompanion<GiftLocal> {
  final Value<int> id;
  final Value<String> giftId;
  final Value<String> eventoId;
  final Value<String> nome;
  final Value<String?> descricao;
  final Value<String?> categoria;
  final Value<String> tipo;
  final Value<double?> valor;
  final Value<double> valorArrecadado;
  final Value<double?> metaValor;
  final Value<String?> loja;
  final Value<String?> link;
  final Value<String?> pix;
  final Value<String?> imagem;
  final Value<String> status;
  final Value<String?> reservadoPor;
  final Value<String?> reservadoUid;
  final Value<DateTime?> dataReserva;
  final Value<bool> deleted;
  final Value<bool> synced;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const GiftLocalsCompanion({
    this.id = const Value.absent(),
    this.giftId = const Value.absent(),
    this.eventoId = const Value.absent(),
    this.nome = const Value.absent(),
    this.descricao = const Value.absent(),
    this.categoria = const Value.absent(),
    this.tipo = const Value.absent(),
    this.valor = const Value.absent(),
    this.valorArrecadado = const Value.absent(),
    this.metaValor = const Value.absent(),
    this.loja = const Value.absent(),
    this.link = const Value.absent(),
    this.pix = const Value.absent(),
    this.imagem = const Value.absent(),
    this.status = const Value.absent(),
    this.reservadoPor = const Value.absent(),
    this.reservadoUid = const Value.absent(),
    this.dataReserva = const Value.absent(),
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  GiftLocalsCompanion.insert({
    this.id = const Value.absent(),
    required String giftId,
    required String eventoId,
    required String nome,
    this.descricao = const Value.absent(),
    this.categoria = const Value.absent(),
    required String tipo,
    this.valor = const Value.absent(),
    this.valorArrecadado = const Value.absent(),
    this.metaValor = const Value.absent(),
    this.loja = const Value.absent(),
    this.link = const Value.absent(),
    this.pix = const Value.absent(),
    this.imagem = const Value.absent(),
    this.status = const Value.absent(),
    this.reservadoPor = const Value.absent(),
    this.reservadoUid = const Value.absent(),
    this.dataReserva = const Value.absent(),
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : giftId = Value(giftId),
        eventoId = Value(eventoId),
        nome = Value(nome),
        tipo = Value(tipo),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<GiftLocal> custom({
    Expression<int>? id,
    Expression<String>? giftId,
    Expression<String>? eventoId,
    Expression<String>? nome,
    Expression<String>? descricao,
    Expression<String>? categoria,
    Expression<String>? tipo,
    Expression<double>? valor,
    Expression<double>? valorArrecadado,
    Expression<double>? metaValor,
    Expression<String>? loja,
    Expression<String>? link,
    Expression<String>? pix,
    Expression<String>? imagem,
    Expression<String>? status,
    Expression<String>? reservadoPor,
    Expression<String>? reservadoUid,
    Expression<DateTime>? dataReserva,
    Expression<bool>? deleted,
    Expression<bool>? synced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (giftId != null) 'gift_id': giftId,
      if (eventoId != null) 'evento_id': eventoId,
      if (nome != null) 'nome': nome,
      if (descricao != null) 'descricao': descricao,
      if (categoria != null) 'categoria': categoria,
      if (tipo != null) 'tipo': tipo,
      if (valor != null) 'valor': valor,
      if (valorArrecadado != null) 'valor_arrecadado': valorArrecadado,
      if (metaValor != null) 'meta_valor': metaValor,
      if (loja != null) 'loja': loja,
      if (link != null) 'link': link,
      if (pix != null) 'pix': pix,
      if (imagem != null) 'imagem': imagem,
      if (status != null) 'status': status,
      if (reservadoPor != null) 'reservado_por': reservadoPor,
      if (reservadoUid != null) 'reservado_uid': reservadoUid,
      if (dataReserva != null) 'data_reserva': dataReserva,
      if (deleted != null) 'deleted': deleted,
      if (synced != null) 'synced': synced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  GiftLocalsCompanion copyWith(
      {Value<int>? id,
      Value<String>? giftId,
      Value<String>? eventoId,
      Value<String>? nome,
      Value<String?>? descricao,
      Value<String?>? categoria,
      Value<String>? tipo,
      Value<double?>? valor,
      Value<double>? valorArrecadado,
      Value<double?>? metaValor,
      Value<String?>? loja,
      Value<String?>? link,
      Value<String?>? pix,
      Value<String?>? imagem,
      Value<String>? status,
      Value<String?>? reservadoPor,
      Value<String?>? reservadoUid,
      Value<DateTime?>? dataReserva,
      Value<bool>? deleted,
      Value<bool>? synced,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return GiftLocalsCompanion(
      id: id ?? this.id,
      giftId: giftId ?? this.giftId,
      eventoId: eventoId ?? this.eventoId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      tipo: tipo ?? this.tipo,
      valor: valor ?? this.valor,
      valorArrecadado: valorArrecadado ?? this.valorArrecadado,
      metaValor: metaValor ?? this.metaValor,
      loja: loja ?? this.loja,
      link: link ?? this.link,
      pix: pix ?? this.pix,
      imagem: imagem ?? this.imagem,
      status: status ?? this.status,
      reservadoPor: reservadoPor ?? this.reservadoPor,
      reservadoUid: reservadoUid ?? this.reservadoUid,
      dataReserva: dataReserva ?? this.dataReserva,
      deleted: deleted ?? this.deleted,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (giftId.present) {
      map['gift_id'] = Variable<String>(giftId.value);
    }
    if (eventoId.present) {
      map['evento_id'] = Variable<String>(eventoId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (valor.present) {
      map['valor'] = Variable<double>(valor.value);
    }
    if (valorArrecadado.present) {
      map['valor_arrecadado'] = Variable<double>(valorArrecadado.value);
    }
    if (metaValor.present) {
      map['meta_valor'] = Variable<double>(metaValor.value);
    }
    if (loja.present) {
      map['loja'] = Variable<String>(loja.value);
    }
    if (link.present) {
      map['link'] = Variable<String>(link.value);
    }
    if (pix.present) {
      map['pix'] = Variable<String>(pix.value);
    }
    if (imagem.present) {
      map['imagem'] = Variable<String>(imagem.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (reservadoPor.present) {
      map['reservado_por'] = Variable<String>(reservadoPor.value);
    }
    if (reservadoUid.present) {
      map['reservado_uid'] = Variable<String>(reservadoUid.value);
    }
    if (dataReserva.present) {
      map['data_reserva'] = Variable<DateTime>(dataReserva.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GiftLocalsCompanion(')
          ..write('id: $id, ')
          ..write('giftId: $giftId, ')
          ..write('eventoId: $eventoId, ')
          ..write('nome: $nome, ')
          ..write('descricao: $descricao, ')
          ..write('categoria: $categoria, ')
          ..write('tipo: $tipo, ')
          ..write('valor: $valor, ')
          ..write('valorArrecadado: $valorArrecadado, ')
          ..write('metaValor: $metaValor, ')
          ..write('loja: $loja, ')
          ..write('link: $link, ')
          ..write('pix: $pix, ')
          ..write('imagem: $imagem, ')
          ..write('status: $status, ')
          ..write('reservadoPor: $reservadoPor, ')
          ..write('reservadoUid: $reservadoUid, ')
          ..write('dataReserva: $dataReserva, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $GiftContributionLocalsTable extends GiftContributionLocals
    with TableInfo<$GiftContributionLocalsTable, GiftContributionLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GiftContributionLocalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _contributionIdMeta =
      const VerificationMeta('contributionId');
  @override
  late final GeneratedColumn<String> contributionId = GeneratedColumn<String>(
      'contribution_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _eventoIdMeta =
      const VerificationMeta('eventoId');
  @override
  late final GeneratedColumn<String> eventoId = GeneratedColumn<String>(
      'evento_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _giftIdMeta = const VerificationMeta('giftId');
  @override
  late final GeneratedColumn<String> giftId = GeneratedColumn<String>(
      'gift_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<double> valor = GeneratedColumn<double>(
      'valor', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _mensagemMeta =
      const VerificationMeta('mensagem');
  @override
  late final GeneratedColumn<String> mensagem = GeneratedColumn<String>(
      'mensagem', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        contributionId,
        eventoId,
        giftId,
        nome,
        uid,
        valor,
        mensagem,
        createdAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gift_contribution_locals';
  @override
  VerificationContext validateIntegrity(
      Insertable<GiftContributionLocal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('contribution_id')) {
      context.handle(
          _contributionIdMeta,
          contributionId.isAcceptableOrUnknown(
              data['contribution_id']!, _contributionIdMeta));
    } else if (isInserting) {
      context.missing(_contributionIdMeta);
    }
    if (data.containsKey('evento_id')) {
      context.handle(_eventoIdMeta,
          eventoId.isAcceptableOrUnknown(data['evento_id']!, _eventoIdMeta));
    } else if (isInserting) {
      context.missing(_eventoIdMeta);
    }
    if (data.containsKey('gift_id')) {
      context.handle(_giftIdMeta,
          giftId.isAcceptableOrUnknown(data['gift_id']!, _giftIdMeta));
    } else if (isInserting) {
      context.missing(_giftIdMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    }
    if (data.containsKey('valor')) {
      context.handle(
          _valorMeta, valor.isAcceptableOrUnknown(data['valor']!, _valorMeta));
    }
    if (data.containsKey('mensagem')) {
      context.handle(_mensagemMeta,
          mensagem.isAcceptableOrUnknown(data['mensagem']!, _mensagemMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GiftContributionLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GiftContributionLocal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      contributionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}contribution_id'])!,
      eventoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}evento_id'])!,
      giftId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gift_id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid']),
      valor: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}valor'])!,
      mensagem: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mensagem']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $GiftContributionLocalsTable createAlias(String alias) {
    return $GiftContributionLocalsTable(attachedDatabase, alias);
  }
}

class GiftContributionLocal extends DataClass
    implements Insertable<GiftContributionLocal> {
  final int id;
  final String contributionId;
  final String eventoId;
  final String giftId;
  final String nome;
  final String? uid;
  final double valor;
  final String? mensagem;
  final DateTime createdAt;
  final bool synced;
  const GiftContributionLocal(
      {required this.id,
      required this.contributionId,
      required this.eventoId,
      required this.giftId,
      required this.nome,
      this.uid,
      required this.valor,
      this.mensagem,
      required this.createdAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['contribution_id'] = Variable<String>(contributionId);
    map['evento_id'] = Variable<String>(eventoId);
    map['gift_id'] = Variable<String>(giftId);
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || uid != null) {
      map['uid'] = Variable<String>(uid);
    }
    map['valor'] = Variable<double>(valor);
    if (!nullToAbsent || mensagem != null) {
      map['mensagem'] = Variable<String>(mensagem);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  GiftContributionLocalsCompanion toCompanion(bool nullToAbsent) {
    return GiftContributionLocalsCompanion(
      id: Value(id),
      contributionId: Value(contributionId),
      eventoId: Value(eventoId),
      giftId: Value(giftId),
      nome: Value(nome),
      uid: uid == null && nullToAbsent ? const Value.absent() : Value(uid),
      valor: Value(valor),
      mensagem: mensagem == null && nullToAbsent
          ? const Value.absent()
          : Value(mensagem),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory GiftContributionLocal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GiftContributionLocal(
      id: serializer.fromJson<int>(json['id']),
      contributionId: serializer.fromJson<String>(json['contributionId']),
      eventoId: serializer.fromJson<String>(json['eventoId']),
      giftId: serializer.fromJson<String>(json['giftId']),
      nome: serializer.fromJson<String>(json['nome']),
      uid: serializer.fromJson<String?>(json['uid']),
      valor: serializer.fromJson<double>(json['valor']),
      mensagem: serializer.fromJson<String?>(json['mensagem']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'contributionId': serializer.toJson<String>(contributionId),
      'eventoId': serializer.toJson<String>(eventoId),
      'giftId': serializer.toJson<String>(giftId),
      'nome': serializer.toJson<String>(nome),
      'uid': serializer.toJson<String?>(uid),
      'valor': serializer.toJson<double>(valor),
      'mensagem': serializer.toJson<String?>(mensagem),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  GiftContributionLocal copyWith(
          {int? id,
          String? contributionId,
          String? eventoId,
          String? giftId,
          String? nome,
          Value<String?> uid = const Value.absent(),
          double? valor,
          Value<String?> mensagem = const Value.absent(),
          DateTime? createdAt,
          bool? synced}) =>
      GiftContributionLocal(
        id: id ?? this.id,
        contributionId: contributionId ?? this.contributionId,
        eventoId: eventoId ?? this.eventoId,
        giftId: giftId ?? this.giftId,
        nome: nome ?? this.nome,
        uid: uid.present ? uid.value : this.uid,
        valor: valor ?? this.valor,
        mensagem: mensagem.present ? mensagem.value : this.mensagem,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );
  GiftContributionLocal copyWithCompanion(
      GiftContributionLocalsCompanion data) {
    return GiftContributionLocal(
      id: data.id.present ? data.id.value : this.id,
      contributionId: data.contributionId.present
          ? data.contributionId.value
          : this.contributionId,
      eventoId: data.eventoId.present ? data.eventoId.value : this.eventoId,
      giftId: data.giftId.present ? data.giftId.value : this.giftId,
      nome: data.nome.present ? data.nome.value : this.nome,
      uid: data.uid.present ? data.uid.value : this.uid,
      valor: data.valor.present ? data.valor.value : this.valor,
      mensagem: data.mensagem.present ? data.mensagem.value : this.mensagem,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GiftContributionLocal(')
          ..write('id: $id, ')
          ..write('contributionId: $contributionId, ')
          ..write('eventoId: $eventoId, ')
          ..write('giftId: $giftId, ')
          ..write('nome: $nome, ')
          ..write('uid: $uid, ')
          ..write('valor: $valor, ')
          ..write('mensagem: $mensagem, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, contributionId, eventoId, giftId, nome,
      uid, valor, mensagem, createdAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GiftContributionLocal &&
          other.id == this.id &&
          other.contributionId == this.contributionId &&
          other.eventoId == this.eventoId &&
          other.giftId == this.giftId &&
          other.nome == this.nome &&
          other.uid == this.uid &&
          other.valor == this.valor &&
          other.mensagem == this.mensagem &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class GiftContributionLocalsCompanion
    extends UpdateCompanion<GiftContributionLocal> {
  final Value<int> id;
  final Value<String> contributionId;
  final Value<String> eventoId;
  final Value<String> giftId;
  final Value<String> nome;
  final Value<String?> uid;
  final Value<double> valor;
  final Value<String?> mensagem;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  const GiftContributionLocalsCompanion({
    this.id = const Value.absent(),
    this.contributionId = const Value.absent(),
    this.eventoId = const Value.absent(),
    this.giftId = const Value.absent(),
    this.nome = const Value.absent(),
    this.uid = const Value.absent(),
    this.valor = const Value.absent(),
    this.mensagem = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  GiftContributionLocalsCompanion.insert({
    this.id = const Value.absent(),
    required String contributionId,
    required String eventoId,
    required String giftId,
    required String nome,
    this.uid = const Value.absent(),
    this.valor = const Value.absent(),
    this.mensagem = const Value.absent(),
    required DateTime createdAt,
    this.synced = const Value.absent(),
  })  : contributionId = Value(contributionId),
        eventoId = Value(eventoId),
        giftId = Value(giftId),
        nome = Value(nome),
        createdAt = Value(createdAt);
  static Insertable<GiftContributionLocal> custom({
    Expression<int>? id,
    Expression<String>? contributionId,
    Expression<String>? eventoId,
    Expression<String>? giftId,
    Expression<String>? nome,
    Expression<String>? uid,
    Expression<double>? valor,
    Expression<String>? mensagem,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contributionId != null) 'contribution_id': contributionId,
      if (eventoId != null) 'evento_id': eventoId,
      if (giftId != null) 'gift_id': giftId,
      if (nome != null) 'nome': nome,
      if (uid != null) 'uid': uid,
      if (valor != null) 'valor': valor,
      if (mensagem != null) 'mensagem': mensagem,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
    });
  }

  GiftContributionLocalsCompanion copyWith(
      {Value<int>? id,
      Value<String>? contributionId,
      Value<String>? eventoId,
      Value<String>? giftId,
      Value<String>? nome,
      Value<String?>? uid,
      Value<double>? valor,
      Value<String?>? mensagem,
      Value<DateTime>? createdAt,
      Value<bool>? synced}) {
    return GiftContributionLocalsCompanion(
      id: id ?? this.id,
      contributionId: contributionId ?? this.contributionId,
      eventoId: eventoId ?? this.eventoId,
      giftId: giftId ?? this.giftId,
      nome: nome ?? this.nome,
      uid: uid ?? this.uid,
      valor: valor ?? this.valor,
      mensagem: mensagem ?? this.mensagem,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (contributionId.present) {
      map['contribution_id'] = Variable<String>(contributionId.value);
    }
    if (eventoId.present) {
      map['evento_id'] = Variable<String>(eventoId.value);
    }
    if (giftId.present) {
      map['gift_id'] = Variable<String>(giftId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (valor.present) {
      map['valor'] = Variable<double>(valor.value);
    }
    if (mensagem.present) {
      map['mensagem'] = Variable<String>(mensagem.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GiftContributionLocalsCompanion(')
          ..write('id: $id, ')
          ..write('contributionId: $contributionId, ')
          ..write('eventoId: $eventoId, ')
          ..write('giftId: $giftId, ')
          ..write('nome: $nome, ')
          ..write('uid: $uid, ')
          ..write('valor: $valor, ')
          ..write('mensagem: $mensagem, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GiftLocalsTable giftLocals = $GiftLocalsTable(this);
  late final $GiftContributionLocalsTable giftContributionLocals =
      $GiftContributionLocalsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [giftLocals, giftContributionLocals];
}

typedef $$GiftLocalsTableCreateCompanionBuilder = GiftLocalsCompanion Function({
  Value<int> id,
  required String giftId,
  required String eventoId,
  required String nome,
  Value<String?> descricao,
  Value<String?> categoria,
  required String tipo,
  Value<double?> valor,
  Value<double> valorArrecadado,
  Value<double?> metaValor,
  Value<String?> loja,
  Value<String?> link,
  Value<String?> pix,
  Value<String?> imagem,
  Value<String> status,
  Value<String?> reservadoPor,
  Value<String?> reservadoUid,
  Value<DateTime?> dataReserva,
  Value<bool> deleted,
  Value<bool> synced,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$GiftLocalsTableUpdateCompanionBuilder = GiftLocalsCompanion Function({
  Value<int> id,
  Value<String> giftId,
  Value<String> eventoId,
  Value<String> nome,
  Value<String?> descricao,
  Value<String?> categoria,
  Value<String> tipo,
  Value<double?> valor,
  Value<double> valorArrecadado,
  Value<double?> metaValor,
  Value<String?> loja,
  Value<String?> link,
  Value<String?> pix,
  Value<String?> imagem,
  Value<String> status,
  Value<String?> reservadoPor,
  Value<String?> reservadoUid,
  Value<DateTime?> dataReserva,
  Value<bool> deleted,
  Value<bool> synced,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$GiftLocalsTableFilterComposer
    extends Composer<_$AppDatabase, $GiftLocalsTable> {
  $$GiftLocalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get giftId => $composableBuilder(
      column: $table.giftId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventoId => $composableBuilder(
      column: $table.eventoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descricao => $composableBuilder(
      column: $table.descricao, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoria => $composableBuilder(
      column: $table.categoria, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get valor => $composableBuilder(
      column: $table.valor, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get valorArrecadado => $composableBuilder(
      column: $table.valorArrecadado,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get metaValor => $composableBuilder(
      column: $table.metaValor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get loja => $composableBuilder(
      column: $table.loja, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get link => $composableBuilder(
      column: $table.link, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pix => $composableBuilder(
      column: $table.pix, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagem => $composableBuilder(
      column: $table.imagem, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reservadoPor => $composableBuilder(
      column: $table.reservadoPor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reservadoUid => $composableBuilder(
      column: $table.reservadoUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dataReserva => $composableBuilder(
      column: $table.dataReserva, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$GiftLocalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GiftLocalsTable> {
  $$GiftLocalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get giftId => $composableBuilder(
      column: $table.giftId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventoId => $composableBuilder(
      column: $table.eventoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descricao => $composableBuilder(
      column: $table.descricao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoria => $composableBuilder(
      column: $table.categoria, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get valor => $composableBuilder(
      column: $table.valor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get valorArrecadado => $composableBuilder(
      column: $table.valorArrecadado,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get metaValor => $composableBuilder(
      column: $table.metaValor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get loja => $composableBuilder(
      column: $table.loja, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get link => $composableBuilder(
      column: $table.link, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pix => $composableBuilder(
      column: $table.pix, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagem => $composableBuilder(
      column: $table.imagem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reservadoPor => $composableBuilder(
      column: $table.reservadoPor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reservadoUid => $composableBuilder(
      column: $table.reservadoUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dataReserva => $composableBuilder(
      column: $table.dataReserva, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$GiftLocalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GiftLocalsTable> {
  $$GiftLocalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get giftId =>
      $composableBuilder(column: $table.giftId, builder: (column) => column);

  GeneratedColumn<String> get eventoId =>
      $composableBuilder(column: $table.eventoId, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<double> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);

  GeneratedColumn<double> get valorArrecadado => $composableBuilder(
      column: $table.valorArrecadado, builder: (column) => column);

  GeneratedColumn<double> get metaValor =>
      $composableBuilder(column: $table.metaValor, builder: (column) => column);

  GeneratedColumn<String> get loja =>
      $composableBuilder(column: $table.loja, builder: (column) => column);

  GeneratedColumn<String> get link =>
      $composableBuilder(column: $table.link, builder: (column) => column);

  GeneratedColumn<String> get pix =>
      $composableBuilder(column: $table.pix, builder: (column) => column);

  GeneratedColumn<String> get imagem =>
      $composableBuilder(column: $table.imagem, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get reservadoPor => $composableBuilder(
      column: $table.reservadoPor, builder: (column) => column);

  GeneratedColumn<String> get reservadoUid => $composableBuilder(
      column: $table.reservadoUid, builder: (column) => column);

  GeneratedColumn<DateTime> get dataReserva => $composableBuilder(
      column: $table.dataReserva, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GiftLocalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GiftLocalsTable,
    GiftLocal,
    $$GiftLocalsTableFilterComposer,
    $$GiftLocalsTableOrderingComposer,
    $$GiftLocalsTableAnnotationComposer,
    $$GiftLocalsTableCreateCompanionBuilder,
    $$GiftLocalsTableUpdateCompanionBuilder,
    (GiftLocal, BaseReferences<_$AppDatabase, $GiftLocalsTable, GiftLocal>),
    GiftLocal,
    PrefetchHooks Function()> {
  $$GiftLocalsTableTableManager(_$AppDatabase db, $GiftLocalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GiftLocalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GiftLocalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GiftLocalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> giftId = const Value.absent(),
            Value<String> eventoId = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String?> descricao = const Value.absent(),
            Value<String?> categoria = const Value.absent(),
            Value<String> tipo = const Value.absent(),
            Value<double?> valor = const Value.absent(),
            Value<double> valorArrecadado = const Value.absent(),
            Value<double?> metaValor = const Value.absent(),
            Value<String?> loja = const Value.absent(),
            Value<String?> link = const Value.absent(),
            Value<String?> pix = const Value.absent(),
            Value<String?> imagem = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> reservadoPor = const Value.absent(),
            Value<String?> reservadoUid = const Value.absent(),
            Value<DateTime?> dataReserva = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              GiftLocalsCompanion(
            id: id,
            giftId: giftId,
            eventoId: eventoId,
            nome: nome,
            descricao: descricao,
            categoria: categoria,
            tipo: tipo,
            valor: valor,
            valorArrecadado: valorArrecadado,
            metaValor: metaValor,
            loja: loja,
            link: link,
            pix: pix,
            imagem: imagem,
            status: status,
            reservadoPor: reservadoPor,
            reservadoUid: reservadoUid,
            dataReserva: dataReserva,
            deleted: deleted,
            synced: synced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String giftId,
            required String eventoId,
            required String nome,
            Value<String?> descricao = const Value.absent(),
            Value<String?> categoria = const Value.absent(),
            required String tipo,
            Value<double?> valor = const Value.absent(),
            Value<double> valorArrecadado = const Value.absent(),
            Value<double?> metaValor = const Value.absent(),
            Value<String?> loja = const Value.absent(),
            Value<String?> link = const Value.absent(),
            Value<String?> pix = const Value.absent(),
            Value<String?> imagem = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> reservadoPor = const Value.absent(),
            Value<String?> reservadoUid = const Value.absent(),
            Value<DateTime?> dataReserva = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              GiftLocalsCompanion.insert(
            id: id,
            giftId: giftId,
            eventoId: eventoId,
            nome: nome,
            descricao: descricao,
            categoria: categoria,
            tipo: tipo,
            valor: valor,
            valorArrecadado: valorArrecadado,
            metaValor: metaValor,
            loja: loja,
            link: link,
            pix: pix,
            imagem: imagem,
            status: status,
            reservadoPor: reservadoPor,
            reservadoUid: reservadoUid,
            dataReserva: dataReserva,
            deleted: deleted,
            synced: synced,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GiftLocalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GiftLocalsTable,
    GiftLocal,
    $$GiftLocalsTableFilterComposer,
    $$GiftLocalsTableOrderingComposer,
    $$GiftLocalsTableAnnotationComposer,
    $$GiftLocalsTableCreateCompanionBuilder,
    $$GiftLocalsTableUpdateCompanionBuilder,
    (GiftLocal, BaseReferences<_$AppDatabase, $GiftLocalsTable, GiftLocal>),
    GiftLocal,
    PrefetchHooks Function()>;
typedef $$GiftContributionLocalsTableCreateCompanionBuilder
    = GiftContributionLocalsCompanion Function({
  Value<int> id,
  required String contributionId,
  required String eventoId,
  required String giftId,
  required String nome,
  Value<String?> uid,
  Value<double> valor,
  Value<String?> mensagem,
  required DateTime createdAt,
  Value<bool> synced,
});
typedef $$GiftContributionLocalsTableUpdateCompanionBuilder
    = GiftContributionLocalsCompanion Function({
  Value<int> id,
  Value<String> contributionId,
  Value<String> eventoId,
  Value<String> giftId,
  Value<String> nome,
  Value<String?> uid,
  Value<double> valor,
  Value<String?> mensagem,
  Value<DateTime> createdAt,
  Value<bool> synced,
});

class $$GiftContributionLocalsTableFilterComposer
    extends Composer<_$AppDatabase, $GiftContributionLocalsTable> {
  $$GiftContributionLocalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contributionId => $composableBuilder(
      column: $table.contributionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventoId => $composableBuilder(
      column: $table.eventoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get giftId => $composableBuilder(
      column: $table.giftId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get valor => $composableBuilder(
      column: $table.valor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mensagem => $composableBuilder(
      column: $table.mensagem, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$GiftContributionLocalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GiftContributionLocalsTable> {
  $$GiftContributionLocalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contributionId => $composableBuilder(
      column: $table.contributionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventoId => $composableBuilder(
      column: $table.eventoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get giftId => $composableBuilder(
      column: $table.giftId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get valor => $composableBuilder(
      column: $table.valor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mensagem => $composableBuilder(
      column: $table.mensagem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$GiftContributionLocalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GiftContributionLocalsTable> {
  $$GiftContributionLocalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contributionId => $composableBuilder(
      column: $table.contributionId, builder: (column) => column);

  GeneratedColumn<String> get eventoId =>
      $composableBuilder(column: $table.eventoId, builder: (column) => column);

  GeneratedColumn<String> get giftId =>
      $composableBuilder(column: $table.giftId, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<double> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);

  GeneratedColumn<String> get mensagem =>
      $composableBuilder(column: $table.mensagem, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$GiftContributionLocalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GiftContributionLocalsTable,
    GiftContributionLocal,
    $$GiftContributionLocalsTableFilterComposer,
    $$GiftContributionLocalsTableOrderingComposer,
    $$GiftContributionLocalsTableAnnotationComposer,
    $$GiftContributionLocalsTableCreateCompanionBuilder,
    $$GiftContributionLocalsTableUpdateCompanionBuilder,
    (
      GiftContributionLocal,
      BaseReferences<_$AppDatabase, $GiftContributionLocalsTable,
          GiftContributionLocal>
    ),
    GiftContributionLocal,
    PrefetchHooks Function()> {
  $$GiftContributionLocalsTableTableManager(
      _$AppDatabase db, $GiftContributionLocalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GiftContributionLocalsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$GiftContributionLocalsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GiftContributionLocalsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> contributionId = const Value.absent(),
            Value<String> eventoId = const Value.absent(),
            Value<String> giftId = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String?> uid = const Value.absent(),
            Value<double> valor = const Value.absent(),
            Value<String?> mensagem = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              GiftContributionLocalsCompanion(
            id: id,
            contributionId: contributionId,
            eventoId: eventoId,
            giftId: giftId,
            nome: nome,
            uid: uid,
            valor: valor,
            mensagem: mensagem,
            createdAt: createdAt,
            synced: synced,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String contributionId,
            required String eventoId,
            required String giftId,
            required String nome,
            Value<String?> uid = const Value.absent(),
            Value<double> valor = const Value.absent(),
            Value<String?> mensagem = const Value.absent(),
            required DateTime createdAt,
            Value<bool> synced = const Value.absent(),
          }) =>
              GiftContributionLocalsCompanion.insert(
            id: id,
            contributionId: contributionId,
            eventoId: eventoId,
            giftId: giftId,
            nome: nome,
            uid: uid,
            valor: valor,
            mensagem: mensagem,
            createdAt: createdAt,
            synced: synced,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GiftContributionLocalsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $GiftContributionLocalsTable,
        GiftContributionLocal,
        $$GiftContributionLocalsTableFilterComposer,
        $$GiftContributionLocalsTableOrderingComposer,
        $$GiftContributionLocalsTableAnnotationComposer,
        $$GiftContributionLocalsTableCreateCompanionBuilder,
        $$GiftContributionLocalsTableUpdateCompanionBuilder,
        (
          GiftContributionLocal,
          BaseReferences<_$AppDatabase, $GiftContributionLocalsTable,
              GiftContributionLocal>
        ),
        GiftContributionLocal,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GiftLocalsTableTableManager get giftLocals =>
      $$GiftLocalsTableTableManager(_db, _db.giftLocals);
  $$GiftContributionLocalsTableTableManager get giftContributionLocals =>
      $$GiftContributionLocalsTableTableManager(
          _db, _db.giftContributionLocals);
}
