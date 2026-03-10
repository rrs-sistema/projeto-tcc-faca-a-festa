// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gift_contribution_local.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetGiftContributionLocalCollection on Isar {
  IsarCollection<GiftContributionLocal> get giftContributionLocals =>
      this.collection();
}

const GiftContributionLocalSchema = CollectionSchema(
  name: r'ContributionLocal',
  id: 86681716491,
  properties: {
    r'contributionId': PropertySchema(
      id: 0,
      name: r'contributionId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'eventoId': PropertySchema(
      id: 2,
      name: r'eventoId',
      type: IsarType.string,
    ),
    r'giftId': PropertySchema(
      id: 3,
      name: r'giftId',
      type: IsarType.string,
    ),
    r'mensagem': PropertySchema(
      id: 4,
      name: r'mensagem',
      type: IsarType.string,
    ),
    r'nome': PropertySchema(
      id: 5,
      name: r'nome',
      type: IsarType.string,
    ),
    r'synced': PropertySchema(
      id: 6,
      name: r'synced',
      type: IsarType.bool,
    ),
    r'uid': PropertySchema(
      id: 7,
      name: r'uid',
      type: IsarType.string,
    ),
    r'valor': PropertySchema(
      id: 8,
      name: r'valor',
      type: IsarType.double,
    )
  },
  estimateSize: _giftContributionLocalEstimateSize,
  serialize: _giftContributionLocalSerialize,
  deserialize: _giftContributionLocalDeserialize,
  deserializeProp: _giftContributionLocalDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _giftContributionLocalGetId,
  getLinks: _giftContributionLocalGetLinks,
  attach: _giftContributionLocalAttach,
  version: '3.0.5',
);

int _giftContributionLocalEstimateSize(
  GiftContributionLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.contributionId.length * 3;
  bytesCount += 3 + object.eventoId.length * 3;
  bytesCount += 3 + object.giftId.length * 3;
  {
    final value = object.mensagem;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.nome.length * 3;
  {
    final value = object.uid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _giftContributionLocalSerialize(
  GiftContributionLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.contributionId);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.eventoId);
  writer.writeString(offsets[3], object.giftId);
  writer.writeString(offsets[4], object.mensagem);
  writer.writeString(offsets[5], object.nome);
  writer.writeBool(offsets[6], object.synced);
  writer.writeString(offsets[7], object.uid);
  writer.writeDouble(offsets[8], object.valor);
}

GiftContributionLocal _giftContributionLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = GiftContributionLocal();
  object.contributionId = reader.readString(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.eventoId = reader.readString(offsets[2]);
  object.giftId = reader.readString(offsets[3]);
  object.id = id;
  object.mensagem = reader.readStringOrNull(offsets[4]);
  object.nome = reader.readString(offsets[5]);
  object.synced = reader.readBool(offsets[6]);
  object.uid = reader.readStringOrNull(offsets[7]);
  object.valor = reader.readDouble(offsets[8]);
  return object;
}

P _giftContributionLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _giftContributionLocalGetId(GiftContributionLocal object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _giftContributionLocalGetLinks(
    GiftContributionLocal object) {
  return [];
}

void _giftContributionLocalAttach(
    IsarCollection<dynamic> col, Id id, GiftContributionLocal object) {
  object.id = id;
}

extension GiftContributionLocalQueryWhereSort
    on QueryBuilder<GiftContributionLocal, GiftContributionLocal, QWhere> {
  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension GiftContributionLocalQueryWhere on QueryBuilder<GiftContributionLocal,
    GiftContributionLocal, QWhereClause> {
  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterWhereClause>
      idBetween(
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
}

extension GiftContributionLocalQueryFilter on QueryBuilder<
    GiftContributionLocal, GiftContributionLocal, QFilterCondition> {
  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> contributionIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contributionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> contributionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contributionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> contributionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contributionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> contributionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contributionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> contributionIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contributionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> contributionIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contributionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
          QAfterFilterCondition>
      contributionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contributionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
          QAfterFilterCondition>
      contributionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contributionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> contributionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contributionId',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> contributionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contributionId',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> eventoIdEqualTo(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> eventoIdGreaterThan(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> eventoIdLessThan(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> eventoIdBetween(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> eventoIdStartsWith(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> eventoIdEndsWith(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
          QAfterFilterCondition>
      eventoIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventoId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
          QAfterFilterCondition>
      eventoIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventoId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> eventoIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventoId',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> eventoIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventoId',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> giftIdEqualTo(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> giftIdGreaterThan(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> giftIdLessThan(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> giftIdBetween(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> giftIdStartsWith(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> giftIdEndsWith(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
          QAfterFilterCondition>
      giftIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'giftId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
          QAfterFilterCondition>
      giftIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'giftId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> giftIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'giftId',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> giftIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'giftId',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> mensagemIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mensagem',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> mensagemIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mensagem',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> mensagemEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mensagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> mensagemGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mensagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> mensagemLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mensagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> mensagemBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mensagem',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> mensagemStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mensagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> mensagemEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mensagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
          QAfterFilterCondition>
      mensagemContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mensagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
          QAfterFilterCondition>
      mensagemMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mensagem',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> mensagemIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mensagem',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> mensagemIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mensagem',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> nomeEqualTo(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> nomeGreaterThan(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> nomeLessThan(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> nomeBetween(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> nomeStartsWith(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> nomeEndsWith(
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
          QAfterFilterCondition>
      nomeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nome',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
          QAfterFilterCondition>
      nomeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nome',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> nomeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nome',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> nomeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nome',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> syncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'synced',
        value: value,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> uidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uid',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> uidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uid',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> uidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> uidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> uidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> uidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> uidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> uidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
          QAfterFilterCondition>
      uidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
          QAfterFilterCondition>
      uidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> valorEqualTo(
    double value, {
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> valorGreaterThan(
    double value, {
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> valorLessThan(
    double value, {
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

  QueryBuilder<GiftContributionLocal, GiftContributionLocal,
      QAfterFilterCondition> valorBetween(
    double lower,
    double upper, {
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
}

extension GiftContributionLocalQueryObject on QueryBuilder<
    GiftContributionLocal, GiftContributionLocal, QFilterCondition> {}

extension GiftContributionLocalQueryLinks on QueryBuilder<GiftContributionLocal,
    GiftContributionLocal, QFilterCondition> {}

extension GiftContributionLocalQuerySortBy
    on QueryBuilder<GiftContributionLocal, GiftContributionLocal, QSortBy> {
  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByContributionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contributionId', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByContributionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contributionId', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByEventoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventoId', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByEventoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventoId', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByGiftId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'giftId', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByGiftIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'giftId', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByMensagem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mensagem', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByMensagemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mensagem', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByNome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByNomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByValor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valor', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      sortByValorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valor', Sort.desc);
    });
  }
}

extension GiftContributionLocalQuerySortThenBy
    on QueryBuilder<GiftContributionLocal, GiftContributionLocal, QSortThenBy> {
  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByContributionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contributionId', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByContributionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contributionId', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByEventoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventoId', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByEventoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventoId', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByGiftId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'giftId', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByGiftIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'giftId', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByMensagem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mensagem', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByMensagemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mensagem', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByNome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByNomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nome', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByValor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valor', Sort.asc);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QAfterSortBy>
      thenByValorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valor', Sort.desc);
    });
  }
}

extension GiftContributionLocalQueryWhereDistinct
    on QueryBuilder<GiftContributionLocal, GiftContributionLocal, QDistinct> {
  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QDistinct>
      distinctByContributionId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contributionId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QDistinct>
      distinctByEventoId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventoId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QDistinct>
      distinctByGiftId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'giftId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QDistinct>
      distinctByMensagem({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mensagem', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QDistinct>
      distinctByNome({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nome', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QDistinct>
      distinctBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'synced');
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QDistinct>
      distinctByUid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GiftContributionLocal, GiftContributionLocal, QDistinct>
      distinctByValor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'valor');
    });
  }
}

extension GiftContributionLocalQueryProperty on QueryBuilder<
    GiftContributionLocal, GiftContributionLocal, QQueryProperty> {
  QueryBuilder<GiftContributionLocal, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<GiftContributionLocal, String, QQueryOperations>
      contributionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contributionId');
    });
  }

  QueryBuilder<GiftContributionLocal, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<GiftContributionLocal, String, QQueryOperations>
      eventoIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventoId');
    });
  }

  QueryBuilder<GiftContributionLocal, String, QQueryOperations>
      giftIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'giftId');
    });
  }

  QueryBuilder<GiftContributionLocal, String?, QQueryOperations>
      mensagemProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mensagem');
    });
  }

  QueryBuilder<GiftContributionLocal, String, QQueryOperations> nomeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nome');
    });
  }

  QueryBuilder<GiftContributionLocal, bool, QQueryOperations> syncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'synced');
    });
  }

  QueryBuilder<GiftContributionLocal, String?, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }

  QueryBuilder<GiftContributionLocal, double, QQueryOperations>
      valorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'valor');
    });
  }
}
