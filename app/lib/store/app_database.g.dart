// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SitesTable extends Sites with TableInfo<$SitesTable, SiteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SitesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _geometryMeta = const VerificationMeta(
    'geometry',
  );
  @override
  late final GeneratedColumn<String> geometry = GeneratedColumn<String>(
    'geometry',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SiteOrigin, String> origin =
      GeneratedColumn<String>(
        'origin',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SiteOrigin>($SitesTable.$converterorigin);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationProvenanceMeta =
      const VerificationMeta('locationProvenance');
  @override
  late final GeneratedColumn<String> locationProvenance =
      GeneratedColumn<String>(
        'location_provenance',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _covariatesMeta = const VerificationMeta(
    'covariates',
  );
  @override
  late final GeneratedColumn<String> covariates = GeneratedColumn<String>(
    'covariates',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    geometry,
    origin,
    createdAt,
    locationProvenance,
    covariates,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sites';
  @override
  VerificationContext validateIntegrity(
    Insertable<SiteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('geometry')) {
      context.handle(
        _geometryMeta,
        geometry.isAcceptableOrUnknown(data['geometry']!, _geometryMeta),
      );
    } else if (isInserting) {
      context.missing(_geometryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('location_provenance')) {
      context.handle(
        _locationProvenanceMeta,
        locationProvenance.isAcceptableOrUnknown(
          data['location_provenance']!,
          _locationProvenanceMeta,
        ),
      );
    }
    if (data.containsKey('covariates')) {
      context.handle(
        _covariatesMeta,
        covariates.isAcceptableOrUnknown(data['covariates']!, _covariatesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SiteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SiteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      geometry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}geometry'],
      )!,
      origin: $SitesTable.$converterorigin.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}origin'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      locationProvenance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_provenance'],
      ),
      covariates: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}covariates'],
      ),
    );
  }

  @override
  $SitesTable createAlias(String alias) {
    return $SitesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SiteOrigin, String, String> $converterorigin =
      const EnumNameConverter<SiteOrigin>(SiteOrigin.values);
}

class SiteRow extends DataClass implements Insertable<SiteRow> {
  final String id;
  final String projectId;
  final String geometry;
  final SiteOrigin origin;
  final DateTime createdAt;
  final String? locationProvenance;
  final String? covariates;
  const SiteRow({
    required this.id,
    required this.projectId,
    required this.geometry,
    required this.origin,
    required this.createdAt,
    this.locationProvenance,
    this.covariates,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['geometry'] = Variable<String>(geometry);
    {
      map['origin'] = Variable<String>(
        $SitesTable.$converterorigin.toSql(origin),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || locationProvenance != null) {
      map['location_provenance'] = Variable<String>(locationProvenance);
    }
    if (!nullToAbsent || covariates != null) {
      map['covariates'] = Variable<String>(covariates);
    }
    return map;
  }

  SitesCompanion toCompanion(bool nullToAbsent) {
    return SitesCompanion(
      id: Value(id),
      projectId: Value(projectId),
      geometry: Value(geometry),
      origin: Value(origin),
      createdAt: Value(createdAt),
      locationProvenance: locationProvenance == null && nullToAbsent
          ? const Value.absent()
          : Value(locationProvenance),
      covariates: covariates == null && nullToAbsent
          ? const Value.absent()
          : Value(covariates),
    );
  }

  factory SiteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SiteRow(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      geometry: serializer.fromJson<String>(json['geometry']),
      origin: $SitesTable.$converterorigin.fromJson(
        serializer.fromJson<String>(json['origin']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      locationProvenance: serializer.fromJson<String?>(
        json['locationProvenance'],
      ),
      covariates: serializer.fromJson<String?>(json['covariates']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'geometry': serializer.toJson<String>(geometry),
      'origin': serializer.toJson<String>(
        $SitesTable.$converterorigin.toJson(origin),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'locationProvenance': serializer.toJson<String?>(locationProvenance),
      'covariates': serializer.toJson<String?>(covariates),
    };
  }

  SiteRow copyWith({
    String? id,
    String? projectId,
    String? geometry,
    SiteOrigin? origin,
    DateTime? createdAt,
    Value<String?> locationProvenance = const Value.absent(),
    Value<String?> covariates = const Value.absent(),
  }) => SiteRow(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    geometry: geometry ?? this.geometry,
    origin: origin ?? this.origin,
    createdAt: createdAt ?? this.createdAt,
    locationProvenance: locationProvenance.present
        ? locationProvenance.value
        : this.locationProvenance,
    covariates: covariates.present ? covariates.value : this.covariates,
  );
  SiteRow copyWithCompanion(SitesCompanion data) {
    return SiteRow(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      geometry: data.geometry.present ? data.geometry.value : this.geometry,
      origin: data.origin.present ? data.origin.value : this.origin,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      locationProvenance: data.locationProvenance.present
          ? data.locationProvenance.value
          : this.locationProvenance,
      covariates: data.covariates.present
          ? data.covariates.value
          : this.covariates,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SiteRow(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('geometry: $geometry, ')
          ..write('origin: $origin, ')
          ..write('createdAt: $createdAt, ')
          ..write('locationProvenance: $locationProvenance, ')
          ..write('covariates: $covariates')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    geometry,
    origin,
    createdAt,
    locationProvenance,
    covariates,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SiteRow &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.geometry == this.geometry &&
          other.origin == this.origin &&
          other.createdAt == this.createdAt &&
          other.locationProvenance == this.locationProvenance &&
          other.covariates == this.covariates);
}

class SitesCompanion extends UpdateCompanion<SiteRow> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> geometry;
  final Value<SiteOrigin> origin;
  final Value<DateTime> createdAt;
  final Value<String?> locationProvenance;
  final Value<String?> covariates;
  final Value<int> rowid;
  const SitesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.geometry = const Value.absent(),
    this.origin = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.locationProvenance = const Value.absent(),
    this.covariates = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SitesCompanion.insert({
    required String id,
    required String projectId,
    required String geometry,
    required SiteOrigin origin,
    required DateTime createdAt,
    this.locationProvenance = const Value.absent(),
    this.covariates = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       geometry = Value(geometry),
       origin = Value(origin),
       createdAt = Value(createdAt);
  static Insertable<SiteRow> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? geometry,
    Expression<String>? origin,
    Expression<DateTime>? createdAt,
    Expression<String>? locationProvenance,
    Expression<String>? covariates,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (geometry != null) 'geometry': geometry,
      if (origin != null) 'origin': origin,
      if (createdAt != null) 'created_at': createdAt,
      if (locationProvenance != null) 'location_provenance': locationProvenance,
      if (covariates != null) 'covariates': covariates,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SitesCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? geometry,
    Value<SiteOrigin>? origin,
    Value<DateTime>? createdAt,
    Value<String?>? locationProvenance,
    Value<String?>? covariates,
    Value<int>? rowid,
  }) {
    return SitesCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      geometry: geometry ?? this.geometry,
      origin: origin ?? this.origin,
      createdAt: createdAt ?? this.createdAt,
      locationProvenance: locationProvenance ?? this.locationProvenance,
      covariates: covariates ?? this.covariates,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (geometry.present) {
      map['geometry'] = Variable<String>(geometry.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(
        $SitesTable.$converterorigin.toSql(origin.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (locationProvenance.present) {
      map['location_provenance'] = Variable<String>(locationProvenance.value);
    }
    if (covariates.present) {
      map['covariates'] = Variable<String>(covariates.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SitesCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('geometry: $geometry, ')
          ..write('origin: $origin, ')
          ..write('createdAt: $createdAt, ')
          ..write('locationProvenance: $locationProvenance, ')
          ..write('covariates: $covariates, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SitesTable sites = $SitesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [sites];
}

typedef $$SitesTableCreateCompanionBuilder = SitesCompanion Function({
  required String id,
  required String projectId,
  required String geometry,
  required SiteOrigin origin,
  required DateTime createdAt,
  Value<String?> locationProvenance,
  Value<String?> covariates,
  Value<int> rowid,
});
typedef $$SitesTableUpdateCompanionBuilder = SitesCompanion Function({
  Value<String> id,
  Value<String> projectId,
  Value<String> geometry,
  Value<SiteOrigin> origin,
  Value<DateTime> createdAt,
  Value<String?> locationProvenance,
  Value<String?> covariates,
  Value<int> rowid,
});

class $$SitesTableFilterComposer extends Composer<_$AppDatabase, $SitesTable> {
  $$SitesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get geometry => $composableBuilder(
    column: $table.geometry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SiteOrigin, SiteOrigin, String> get origin =>
      $composableBuilder(
        column: $table.origin,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationProvenance => $composableBuilder(
    column: $table.locationProvenance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get covariates => $composableBuilder(
    column: $table.covariates,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SitesTableOrderingComposer
    extends Composer<_$AppDatabase, $SitesTable> {
  $$SitesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get geometry => $composableBuilder(
    column: $table.geometry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationProvenance => $composableBuilder(
    column: $table.locationProvenance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get covariates => $composableBuilder(
    column: $table.covariates,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SitesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SitesTable> {
  $$SitesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get geometry =>
      $composableBuilder(column: $table.geometry, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SiteOrigin, String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get locationProvenance => $composableBuilder(
    column: $table.locationProvenance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get covariates => $composableBuilder(
    column: $table.covariates,
    builder: (column) => column,
  );
}

class $$SitesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SitesTable,
          SiteRow,
          $$SitesTableFilterComposer,
          $$SitesTableOrderingComposer,
          $$SitesTableAnnotationComposer,
          $$SitesTableCreateCompanionBuilder,
          $$SitesTableUpdateCompanionBuilder,
          (SiteRow, BaseReferences<_$AppDatabase, $SitesTable, SiteRow>),
          SiteRow,
          PrefetchHooks Function()
        > {
  $$SitesTableTableManager(_$AppDatabase db, $SitesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SitesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SitesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SitesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> geometry = const Value.absent(),
                Value<SiteOrigin> origin = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> locationProvenance = const Value.absent(),
                Value<String?> covariates = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SitesCompanion(
                id: id,
                projectId: projectId,
                geometry: geometry,
                origin: origin,
                createdAt: createdAt,
                locationProvenance: locationProvenance,
                covariates: covariates,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String geometry,
                required SiteOrigin origin,
                required DateTime createdAt,
                Value<String?> locationProvenance = const Value.absent(),
                Value<String?> covariates = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SitesCompanion.insert(
                id: id,
                projectId: projectId,
                geometry: geometry,
                origin: origin,
                createdAt: createdAt,
                locationProvenance: locationProvenance,
                covariates: covariates,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SitesTable, SiteRow>(table),
                  BaseReferences<_$AppDatabase, $SitesTable, SiteRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SitesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SitesTable,
      SiteRow,
      $$SitesTableFilterComposer,
      $$SitesTableOrderingComposer,
      $$SitesTableAnnotationComposer,
      $$SitesTableCreateCompanionBuilder,
      $$SitesTableUpdateCompanionBuilder,
      (SiteRow, BaseReferences<_$AppDatabase, $SitesTable, SiteRow>),
      SiteRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db, _db.sites);
}
