// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gift_local.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetGiftLocalCollection on Isar {
  IsarCollection<GiftLocal> get giftLocals => this.collection();
}

const GiftLocalSchema = CollectionSchema(
  name: r'GiftLocal',
  id: 344891647891,
  properties: {
    r'categoria': PropertySchema(
      id: 0,
      name: r'categoria',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'dataReserva': PropertySchema(
      id: 2,
      name: r'dataReserva',
      type: IsarType.dateTime,
    ),
    r'deleted': PropertySchema(
      id: 3,
      name: r'deleted',
      type: IsarType.bool,
    ),
    r'descricao': PropertySchema(
      id: 4,
      name: r'descricao',
      type: IsarType.string,
    ),
    r'eventoId': PropertySchema(
      id: 5,
      name: r'eventoId',
      type: IsarType.string,
    ),
    r'giftId': PropertySchema(
      id: 6,
      name: r'giftId',
      type: IsarType.string,
    ),
    r'imagem': PropertySchema(
      id: 7,
      name: r'imagem',
      type: IsarType.string,
    ),
    r'link': PropertySchema(
      id: 8,
      name: r'link',
      type: IsarType.string,
    ),
    r'loja': PropertySchema(
      id: 9,
      name: r'loja',
      type: IsarType.string,
    ),
    r'metaValor': PropertySchema(
      id: 10,
      name: r'metaValor',
      type: IsarType.double,
    ),
    r'nome': PropertySchema(
      id: 11,
      name: r'nome',
      type: IsarType.string,
    ),
    r'pix': PropertySchema(
      id: 12,
      name: r'pix',
      type: IsarType.string,
    ),
    r'reservadoPor': PropertySchema(
      id: 13,
      name: r'reservadoPor',
      type: IsarType.string,
    ),
    r'reservadoUid': PropertySchema(
      id: 14,
      name: r'reservadoUid',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 15,
      name: r'status',
      type: IsarType.string,
    ),
    r'synced': PropertySchema(
      id: 16,
      name: r'synced',
      type: IsarType.bool,
    ),
    r'tipo': PropertySchema(
      id: 17,
      name: r'tipo',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 18,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'valor': PropertySchema(
      id: 19,
      name: r'valor',
      type: IsarType.double,
    ),
    r'valorArrecadado': PropertySchema(
      id: 20,
      name: r'valorArrecadado',
      type: IsarType.double,
    )
  },
  estimateSize: _giftLocalEstimateSize,
  serialize: _giftLocalSerialize,
  deserialize: _giftLocalDeserialize,
  deserializeProp: _giftLocalDeserializeProp,
  idName: r'id',
  indexes: {
    r'fb_gift_id': IndexSchema(
      id: 404681998536,
      name: r'fb_gift_id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'giftId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _giftLocalGetId,
  getLinks: _giftLocalGetLinks,
  attach: _giftLocalAttach,
  version: '3.0.5',
);

int _giftLocalEstimateSize(
  GiftLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.categoria;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.descricao;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.eventoId.length * 3;
  bytesCount += 3 + object.giftId.length * 3;
  {
    final value = object.imagem;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.link;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.loja;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.nome.length * 3;
  {
    final value = object.pix;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.reservadoPor;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.reservadoUid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.tipo.length * 3;
  return bytesCount;
}

void _giftLocalSerialize(
  GiftLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.categoria);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDateTime(offsets[2], object.dataReserva);
  writer.writeBool(offsets[3], object.deleted);
  writer.writeString(offsets[4], object.descricao);
  writer.writeString(offsets[5], object.eventoId);
  writer.writeString(offsets[6], object.giftId);
  writer.writeString(offsets[7], object.imagem);
  writer.writeString(offsets[8], object.link);
  writer.writeString(offsets[9], object.loja);
  writer.writeDouble(offsets[10], object.metaValor);
  writer.writeString(offsets[11], object.nome);
  writer.writeString(offsets[12], object.pix);
  writer.writeString(offsets[13], object.reservadoPor);
  writer.writeString(offsets[14], object.reservadoUid);
  writer.writeString(offsets[15], object.status);
  writer.writeBool(offsets[16], object.synced);
  writer.writeString(offsets[17], object.tipo);
  writer.writeDateTime(offsets[18], object.updatedAt);
  writer.writeDouble(offsets[19], object.valor);
  writer.writeDouble(offsets[20], object.valorArrecadado);
}

GiftLocal _giftLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = GiftLocal();
  object.categoria = reader.readStringOrNull(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.dataReserva = reader.readDateTimeOrNull(offsets[2]);
  object.deleted = reader.readBool(offsets[3]);
  object.descricao = reader.readStringOrNull(offsets[4]);
  object.eventoId = reader.readString(offsets[5]);
  object.giftId = reader.readString(offsets[6]);
  object.id = id;
  object.imagem = reader.readStringOrNull(offsets[7]);
  object.link = reader.readStringOrNull(offsets[8]);
  object.loja = reader.readStringOrNull(offsets[9]);
  object.metaValor = reader.readDoubleOrNull(offsets[10]);
  object.nome = reader.readString(offsets[11]);
  object.pix = reader.readStringOrNull(offsets[12]);
  object.reservadoPor = reader.readStringOrNull(offsets[13]);
  object.reservadoUid = reader.readStringOrNull(offsets[14]);
  object.status = reader.readString(offsets[15]);
  object.synced = reader.readBool(offsets[16]);
  object.tipo = reader.readString(offsets[17]);
  object.updatedAt = reader.readDateTime(offsets[18]);
  object.valor = reader.readDoubleOrNull(offsets[19]);
  object.valorArrecadado = reader.readDouble(offsets[20]);
  return object;
}

P _giftLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readDoubleOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readBool(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readDateTime(offset)) as P;
    case 19:
      return (reader.readDoubleOrNull(offset)) as P;
    case 20:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _giftLocalGetId(GiftLocal object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _giftLocalGetLinks(GiftLocal object) {
  return [];
}

void _giftLocalAttach(IsarCollection<dynamic> col, Id id, GiftLocal object) {
  object.id = id;
}

extension GiftLocalByIndex on IsarCollection<GiftLocal> {
  Future<GiftLocal?> getByGiftId(String giftId) {
    return getByIndex(r'fb_gift_id', [giftId]);
  }

  GiftLocal? getByGiftIdSync(String giftId) {
    return getByIndexSync(r'fb_gift_id', [giftId]);
  }

  Future<bool> deleteByGiftId(String giftId) {
    return deleteByIndex(r'fb_gift_id', [giftId]);
  }

  bool deleteByGiftIdSync(String giftId) {
    return deleteByIndexSync(r'fb_gift_id', [giftId]);
  }

  Future<List<GiftLocal?>> getAllByGiftId(List<String> giftIdValues) {
    final values = giftIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'fb_gift_id', values);
  }

  List<GiftLocal?> getAllByGiftIdSync(List<String> giftIdValues) {
    final values = giftIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'fb_gift_id', values);
  }

  Future<int> deleteAllByGiftId(List<String> giftIdValues) {
    final values = giftIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'fb_gift_id', values);
  }

  int deleteAllByGiftIdSync(List<String> giftIdValues) {
    final values = giftIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'fb_gift_id', values);
  }

  Future<Id> putByGiftId(GiftLocal object) {
    return putByIndex(r'fb_gift_id', object);
  }

  Id putByGiftIdSync(GiftLocal object, {bool saveLinks = true}) {
    return putByIndexSync(r'fb_gift_id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByGiftId(List<GiftLocal> objects) {
    return putAllByIndex(r'fb_gift_id', objects);
  }

  List<Id> putAllByGiftIdSync(List<GiftLocal> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'fb_gift_id', objects, saveLinks: saveLinks);
  }
}

extension GiftLocalQueryWhereSort
    on QueryBuilder<GiftLocal, GiftLocal, QWhere> {
  QueryBuilder<GiftLocal, GiftLocal, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension GiftLocalQueryWhere
    on QueryBuilder<GiftLocal, GiftLocal, QWhereClause> {
  QueryBuilder<GiftLocal, GiftLocal, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterWhereClause> giftIdEqualTo(
      String giftId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'fb_gift_id',
        value: [giftId],
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterWhereClause> giftIdNotEqualTo(
      String giftId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fb_gift_id',
              lower: [],
              upper: [giftId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fb_gift_id',
              lower: [giftId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fb_gift_id',
              lower: [giftId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fb_gift_id',
              lower: [],
              upper: [giftId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension GiftLocalQueryFilter
    on QueryBuilder<GiftLocal, GiftLocal, QFilterCondition> {
  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> categoriaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'categoria',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      categoriaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'categoria',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> categoriaEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoria',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      categoriaGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoria',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> categoriaLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoria',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> categoriaBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoria',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> categoriaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoria',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> categoriaEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoria',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> categoriaContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoria',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> categoriaMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoria',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> categoriaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoria',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      categoriaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoria',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      dataReservaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dataReserva',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      dataReservaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dataReserva',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> dataReservaEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dataReserva',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      dataReservaGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dataReserva',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> dataReservaLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dataReserva',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> dataReservaBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dataReserva',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> deletedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deleted',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> descricaoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'descricao',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      descricaoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'descricao',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> descricaoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descricao',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      descricaoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'descricao',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> descricaoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'descricao',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> descricaoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'descricao',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> descricaoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'descricao',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> descricaoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'descricao',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> descricaoContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'descricao',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> descricaoMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'descricao',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> descricaoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descricao',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      descricaoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'descricao',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> eventoIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> eventoIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> eventoIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> eventoIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventoId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> eventoIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'eventoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> eventoIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'eventoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> eventoIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> eventoIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventoId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> eventoIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventoId',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      eventoIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventoId',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> giftIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'giftId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> giftIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'giftId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> giftIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'giftId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> giftIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'giftId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> giftIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'giftId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> giftIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'giftId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> giftIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'giftId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> giftIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'giftId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> giftIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'giftId',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> giftIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'giftId',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> imagemIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imagem',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> imagemIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imagem',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> imagemEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> imagemGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> imagemLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> imagemBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imagem',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> imagemStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> imagemEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> imagemContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> imagemMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imagem',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> imagemIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagem',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> imagemIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imagem',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> linkIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'link',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> linkIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'link',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> linkEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'link',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> linkGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'link',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> linkLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'link',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> linkBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'link',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> linkStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'link',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> linkEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'link',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> linkContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'link',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> linkMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'link',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> linkIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'link',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> linkIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'link',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> lojaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'loja',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> lojaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'loja',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> lojaEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loja',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> lojaGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'loja',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> lojaLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'loja',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> lojaBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'loja',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> lojaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'loja',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> lojaEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'loja',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> lojaContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'loja',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> lojaMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'loja',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> lojaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loja',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> lojaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'loja',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> metaValorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'metaValor',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      metaValorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'metaValor',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> metaValorEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metaValor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      metaValorGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'metaValor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> metaValorLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'metaValor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> metaValorBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'metaValor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> nomeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nome',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> nomeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nome',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> nomeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nome',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> nomeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nome',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> nomeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nome',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> nomeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nome',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> nomeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nome',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> nomeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nome',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> nomeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nome',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> nomeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nome',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> pixIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pix',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> pixIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pix',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> pixEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> pixGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> pixLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> pixBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pix',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> pixStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> pixEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> pixContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pix',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> pixMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pix',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> pixIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pix',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> pixIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pix',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoPorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reservadoPor',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoPorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reservadoPor',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> reservadoPorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reservadoPor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoPorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reservadoPor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoPorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reservadoPor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> reservadoPorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reservadoPor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoPorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reservadoPor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoPorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reservadoPor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoPorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reservadoPor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> reservadoPorMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reservadoPor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoPorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reservadoPor',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoPorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reservadoPor',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoUidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reservadoUid',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoUidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reservadoUid',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> reservadoUidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reservadoUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoUidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reservadoUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoUidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reservadoUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> reservadoUidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reservadoUid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoUidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reservadoUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoUidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reservadoUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoUidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reservadoUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> reservadoUidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reservadoUid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reservadoUid',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      reservadoUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reservadoUid',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> statusContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> statusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> syncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'synced',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> tipoEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> tipoGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tipo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> tipoLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tipo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> tipoBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tipo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> tipoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tipo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> tipoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tipo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> tipoContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tipo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> tipoMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tipo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> tipoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipo',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> tipoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tipo',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> valorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'valor',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> valorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'valor',
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> valorEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'valor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> valorGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'valor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> valorLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'valor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition> valorBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'valor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      valorArrecadadoEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'valorArrecadado',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      valorArrecadadoGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'valorArrecadado',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      valorArrecadadoLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'valorArrecadado',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterFilterCondition>
      valorArrecadadoBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'valorArrecadado',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension GiftLocalQueryObject
    on QueryBuilder<GiftLocal, GiftLocal, QFilterCondition> {}

extension GiftLocalQueryLinks
    on QueryBuilder<GiftLocal, GiftLocal, QFilterCondition> {}

extension GiftLocalQuerySortBy on QueryBuilder<GiftLocal, GiftLocal, QSortBy> {
  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByCategoria() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoria', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByCategoriaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoria', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByDataReserva() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataReserva', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByDataReservaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataReserva', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByDescricao() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descricao', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByDescricaoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descricao', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByEventoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventoId', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByEventoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventoId', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByGiftId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'giftId', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByGiftIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'giftId', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByImagem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagem', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByImagemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagem', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByLink() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'link', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByLinkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'link', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByLoja() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loja', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByLojaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loja', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByMetaValor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metaValor', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByMetaValorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metaValor', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByNome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByNomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByPix() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pix', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByPixDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pix', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByReservadoPor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservadoPor', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByReservadoPorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservadoPor', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByReservadoUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservadoUid', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByReservadoUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservadoUid', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByTipo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipo', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByTipoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipo', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByValor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valor', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByValorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valor', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByValorArrecadado() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valorArrecadado', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> sortByValorArrecadadoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valorArrecadado', Sort.desc);
    });
  }
}

extension GiftLocalQuerySortThenBy
    on QueryBuilder<GiftLocal, GiftLocal, QSortThenBy> {
  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByCategoria() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoria', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByCategoriaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoria', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByDataReserva() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataReserva', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByDataReservaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataReserva', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByDescricao() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descricao', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByDescricaoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descricao', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByEventoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventoId', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByEventoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventoId', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByGiftId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'giftId', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByGiftIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'giftId', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByImagem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagem', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByImagemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagem', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByLink() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'link', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByLinkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'link', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByLoja() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loja', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByLojaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loja', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByMetaValor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metaValor', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByMetaValorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metaValor', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByNome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByNomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByPix() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pix', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByPixDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pix', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByReservadoPor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservadoPor', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByReservadoPorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservadoPor', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByReservadoUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservadoUid', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByReservadoUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservadoUid', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByTipo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipo', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByTipoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipo', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByValor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valor', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByValorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valor', Sort.desc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByValorArrecadado() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valorArrecadado', Sort.asc);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QAfterSortBy> thenByValorArrecadadoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valorArrecadado', Sort.desc);
    });
  }
}

extension GiftLocalQueryWhereDistinct
    on QueryBuilder<GiftLocal, GiftLocal, QDistinct> {
  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByCategoria(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoria', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByDataReserva() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dataReserva');
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deleted');
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByDescricao(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'descricao', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByEventoId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventoId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByGiftId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'giftId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByImagem(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imagem', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByLink(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'link', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByLoja(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'loja', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByMetaValor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'metaValor');
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByNome(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nome', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByPix(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pix', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByReservadoPor(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reservadoPor', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByReservadoUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reservadoUid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'synced');
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByTipo(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tipo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByValor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'valor');
    });
  }

  QueryBuilder<GiftLocal, GiftLocal, QDistinct> distinctByValorArrecadado() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'valorArrecadado');
    });
  }
}

extension GiftLocalQueryProperty
    on QueryBuilder<GiftLocal, GiftLocal, QQueryProperty> {
  QueryBuilder<GiftLocal, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<GiftLocal, String?, QQueryOperations> categoriaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoria');
    });
  }

  QueryBuilder<GiftLocal, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<GiftLocal, DateTime?, QQueryOperations> dataReservaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dataReserva');
    });
  }

  QueryBuilder<GiftLocal, bool, QQueryOperations> deletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deleted');
    });
  }

  QueryBuilder<GiftLocal, String?, QQueryOperations> descricaoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'descricao');
    });
  }

  QueryBuilder<GiftLocal, String, QQueryOperations> eventoIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventoId');
    });
  }

  QueryBuilder<GiftLocal, String, QQueryOperations> giftIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'giftId');
    });
  }

  QueryBuilder<GiftLocal, String?, QQueryOperations> imagemProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imagem');
    });
  }

  QueryBuilder<GiftLocal, String?, QQueryOperations> linkProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'link');
    });
  }

  QueryBuilder<GiftLocal, String?, QQueryOperations> lojaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'loja');
    });
  }

  QueryBuilder<GiftLocal, double?, QQueryOperations> metaValorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metaValor');
    });
  }

  QueryBuilder<GiftLocal, String, QQueryOperations> nomeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nome');
    });
  }

  QueryBuilder<GiftLocal, String?, QQueryOperations> pixProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pix');
    });
  }

  QueryBuilder<GiftLocal, String?, QQueryOperations> reservadoPorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reservadoPor');
    });
  }

  QueryBuilder<GiftLocal, String?, QQueryOperations> reservadoUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reservadoUid');
    });
  }

  QueryBuilder<GiftLocal, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<GiftLocal, bool, QQueryOperations> syncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'synced');
    });
  }

  QueryBuilder<GiftLocal, String, QQueryOperations> tipoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tipo');
    });
  }

  QueryBuilder<GiftLocal, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<GiftLocal, double?, QQueryOperations> valorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'valor');
    });
  }

  QueryBuilder<GiftLocal, double, QQueryOperations> valorArrecadadoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'valorArrecadado');
    });
  }
}
