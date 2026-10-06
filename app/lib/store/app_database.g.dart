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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    name,
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
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
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
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

  /// The name the config pull carries for a Site, or null for a Site created
  /// on the device or one the server never named.
  final String? name;
  final String geometry;
  final SiteOrigin origin;
  final DateTime createdAt;
  final String? locationProvenance;
  final String? covariates;
  const SiteRow({
    required this.id,
    required this.projectId,
    this.name,
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
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
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
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
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
      name: serializer.fromJson<String?>(json['name']),
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
      'name': serializer.toJson<String?>(name),
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
    Value<String?> name = const Value.absent(),
    String? geometry,
    SiteOrigin? origin,
    DateTime? createdAt,
    Value<String?> locationProvenance = const Value.absent(),
    Value<String?> covariates = const Value.absent(),
  }) => SiteRow(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    name: name.present ? name.value : this.name,
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
      name: data.name.present ? data.name.value : this.name,
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
          ..write('name: $name, ')
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
    name,
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
          other.name == this.name &&
          other.geometry == this.geometry &&
          other.origin == this.origin &&
          other.createdAt == this.createdAt &&
          other.locationProvenance == this.locationProvenance &&
          other.covariates == this.covariates);
}

class SitesCompanion extends UpdateCompanion<SiteRow> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String?> name;
  final Value<String> geometry;
  final Value<SiteOrigin> origin;
  final Value<DateTime> createdAt;
  final Value<String?> locationProvenance;
  final Value<String?> covariates;
  final Value<int> rowid;
  const SitesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
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
    this.name = const Value.absent(),
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
    Expression<String>? name,
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
      if (name != null) 'name': name,
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
    Value<String?>? name,
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
      name: name ?? this.name,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
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
          ..write('name: $name, ')
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

class $VisitsTable extends Visits with TableInfo<$VisitsTable, VisitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<String> siteId = GeneratedColumn<String>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surveyPeriodIdMeta = const VerificationMeta(
    'surveyPeriodId',
  );
  @override
  late final GeneratedColumn<String> surveyPeriodId = GeneratedColumn<String>(
    'survey_period_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _protocolVersionIdMeta = const VerificationMeta(
    'protocolVersionId',
  );
  @override
  late final GeneratedColumn<String> protocolVersionId =
      GeneratedColumn<String>(
        'protocol_version_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<VisitState, String> state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<VisitState>($VisitsTable.$converterstate);
  static const VerificationMeta _effortStartedAtMeta = const VerificationMeta(
    'effortStartedAt',
  );
  @override
  late final GeneratedColumn<DateTime> effortStartedAt =
      GeneratedColumn<DateTime>(
        'effort_started_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _effortEndedAtMeta = const VerificationMeta(
    'effortEndedAt',
  );
  @override
  late final GeneratedColumn<DateTime> effortEndedAt =
      GeneratedColumn<DateTime>(
        'effort_ended_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _effortObserversMeta = const VerificationMeta(
    'effortObservers',
  );
  @override
  late final GeneratedColumn<String> effortObservers = GeneratedColumn<String>(
    'effort_observers',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    siteId,
    surveyPeriodId,
    protocolVersionId,
    state,
    effortStartedAt,
    effortEndedAt,
    effortObservers,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visits';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('survey_period_id')) {
      context.handle(
        _surveyPeriodIdMeta,
        surveyPeriodId.isAcceptableOrUnknown(
          data['survey_period_id']!,
          _surveyPeriodIdMeta,
        ),
      );
    }
    if (data.containsKey('protocol_version_id')) {
      context.handle(
        _protocolVersionIdMeta,
        protocolVersionId.isAcceptableOrUnknown(
          data['protocol_version_id']!,
          _protocolVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('effort_started_at')) {
      context.handle(
        _effortStartedAtMeta,
        effortStartedAt.isAcceptableOrUnknown(
          data['effort_started_at']!,
          _effortStartedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effortStartedAtMeta);
    }
    if (data.containsKey('effort_ended_at')) {
      context.handle(
        _effortEndedAtMeta,
        effortEndedAt.isAcceptableOrUnknown(
          data['effort_ended_at']!,
          _effortEndedAtMeta,
        ),
      );
    }
    if (data.containsKey('effort_observers')) {
      context.handle(
        _effortObserversMeta,
        effortObservers.isAcceptableOrUnknown(
          data['effort_observers']!,
          _effortObserversMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VisitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_id'],
      )!,
      surveyPeriodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}survey_period_id'],
      ),
      protocolVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protocol_version_id'],
      ),
      state: $VisitsTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      effortStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}effort_started_at'],
      )!,
      effortEndedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}effort_ended_at'],
      ),
      effortObservers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effort_observers'],
      ),
    );
  }

  @override
  $VisitsTable createAlias(String alias) {
    return $VisitsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<VisitState, String, String> $converterstate =
      const EnumNameConverter<VisitState>(VisitState.values);
}

class VisitRow extends DataClass implements Insertable<VisitRow> {
  final String id;
  final String siteId;

  /// The Survey period attached to the Visit, or null while a Visit starts and
  /// is captured with only a Site (INV-020).
  final String? surveyPeriodId;

  /// The Protocol version attached to the Visit, or null while a Visit starts
  /// and is captured with only a Site (INV-020).
  final String? protocolVersionId;
  final VisitState state;
  final DateTime effortStartedAt;
  final DateTime? effortEndedAt;

  /// The Visit's recorded observers, the `observers` Sampling-effort field the
  /// Protocol version may require, as a JSON-encoded list of names (INV-005).
  /// Null for a Visit captured before the client schema recorded them.
  final String? effortObservers;
  const VisitRow({
    required this.id,
    required this.siteId,
    this.surveyPeriodId,
    this.protocolVersionId,
    required this.state,
    required this.effortStartedAt,
    this.effortEndedAt,
    this.effortObservers,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['site_id'] = Variable<String>(siteId);
    if (!nullToAbsent || surveyPeriodId != null) {
      map['survey_period_id'] = Variable<String>(surveyPeriodId);
    }
    if (!nullToAbsent || protocolVersionId != null) {
      map['protocol_version_id'] = Variable<String>(protocolVersionId);
    }
    {
      map['state'] = Variable<String>(
        $VisitsTable.$converterstate.toSql(state),
      );
    }
    map['effort_started_at'] = Variable<DateTime>(effortStartedAt);
    if (!nullToAbsent || effortEndedAt != null) {
      map['effort_ended_at'] = Variable<DateTime>(effortEndedAt);
    }
    if (!nullToAbsent || effortObservers != null) {
      map['effort_observers'] = Variable<String>(effortObservers);
    }
    return map;
  }

  VisitsCompanion toCompanion(bool nullToAbsent) {
    return VisitsCompanion(
      id: Value(id),
      siteId: Value(siteId),
      surveyPeriodId: surveyPeriodId == null && nullToAbsent
          ? const Value.absent()
          : Value(surveyPeriodId),
      protocolVersionId: protocolVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(protocolVersionId),
      state: Value(state),
      effortStartedAt: Value(effortStartedAt),
      effortEndedAt: effortEndedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(effortEndedAt),
      effortObservers: effortObservers == null && nullToAbsent
          ? const Value.absent()
          : Value(effortObservers),
    );
  }

  factory VisitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitRow(
      id: serializer.fromJson<String>(json['id']),
      siteId: serializer.fromJson<String>(json['siteId']),
      surveyPeriodId: serializer.fromJson<String?>(json['surveyPeriodId']),
      protocolVersionId: serializer.fromJson<String?>(
        json['protocolVersionId'],
      ),
      state: $VisitsTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      effortStartedAt: serializer.fromJson<DateTime>(json['effortStartedAt']),
      effortEndedAt: serializer.fromJson<DateTime?>(json['effortEndedAt']),
      effortObservers: serializer.fromJson<String?>(json['effortObservers']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'siteId': serializer.toJson<String>(siteId),
      'surveyPeriodId': serializer.toJson<String?>(surveyPeriodId),
      'protocolVersionId': serializer.toJson<String?>(protocolVersionId),
      'state': serializer.toJson<String>(
        $VisitsTable.$converterstate.toJson(state),
      ),
      'effortStartedAt': serializer.toJson<DateTime>(effortStartedAt),
      'effortEndedAt': serializer.toJson<DateTime?>(effortEndedAt),
      'effortObservers': serializer.toJson<String?>(effortObservers),
    };
  }

  VisitRow copyWith({
    String? id,
    String? siteId,
    Value<String?> surveyPeriodId = const Value.absent(),
    Value<String?> protocolVersionId = const Value.absent(),
    VisitState? state,
    DateTime? effortStartedAt,
    Value<DateTime?> effortEndedAt = const Value.absent(),
    Value<String?> effortObservers = const Value.absent(),
  }) => VisitRow(
    id: id ?? this.id,
    siteId: siteId ?? this.siteId,
    surveyPeriodId: surveyPeriodId.present
        ? surveyPeriodId.value
        : this.surveyPeriodId,
    protocolVersionId: protocolVersionId.present
        ? protocolVersionId.value
        : this.protocolVersionId,
    state: state ?? this.state,
    effortStartedAt: effortStartedAt ?? this.effortStartedAt,
    effortEndedAt: effortEndedAt.present
        ? effortEndedAt.value
        : this.effortEndedAt,
    effortObservers: effortObservers.present
        ? effortObservers.value
        : this.effortObservers,
  );
  VisitRow copyWithCompanion(VisitsCompanion data) {
    return VisitRow(
      id: data.id.present ? data.id.value : this.id,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      surveyPeriodId: data.surveyPeriodId.present
          ? data.surveyPeriodId.value
          : this.surveyPeriodId,
      protocolVersionId: data.protocolVersionId.present
          ? data.protocolVersionId.value
          : this.protocolVersionId,
      state: data.state.present ? data.state.value : this.state,
      effortStartedAt: data.effortStartedAt.present
          ? data.effortStartedAt.value
          : this.effortStartedAt,
      effortEndedAt: data.effortEndedAt.present
          ? data.effortEndedAt.value
          : this.effortEndedAt,
      effortObservers: data.effortObservers.present
          ? data.effortObservers.value
          : this.effortObservers,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitRow(')
          ..write('id: $id, ')
          ..write('siteId: $siteId, ')
          ..write('surveyPeriodId: $surveyPeriodId, ')
          ..write('protocolVersionId: $protocolVersionId, ')
          ..write('state: $state, ')
          ..write('effortStartedAt: $effortStartedAt, ')
          ..write('effortEndedAt: $effortEndedAt, ')
          ..write('effortObservers: $effortObservers')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    siteId,
    surveyPeriodId,
    protocolVersionId,
    state,
    effortStartedAt,
    effortEndedAt,
    effortObservers,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitRow &&
          other.id == this.id &&
          other.siteId == this.siteId &&
          other.surveyPeriodId == this.surveyPeriodId &&
          other.protocolVersionId == this.protocolVersionId &&
          other.state == this.state &&
          other.effortStartedAt == this.effortStartedAt &&
          other.effortEndedAt == this.effortEndedAt &&
          other.effortObservers == this.effortObservers);
}

class VisitsCompanion extends UpdateCompanion<VisitRow> {
  final Value<String> id;
  final Value<String> siteId;
  final Value<String?> surveyPeriodId;
  final Value<String?> protocolVersionId;
  final Value<VisitState> state;
  final Value<DateTime> effortStartedAt;
  final Value<DateTime?> effortEndedAt;
  final Value<String?> effortObservers;
  final Value<int> rowid;
  const VisitsCompanion({
    this.id = const Value.absent(),
    this.siteId = const Value.absent(),
    this.surveyPeriodId = const Value.absent(),
    this.protocolVersionId = const Value.absent(),
    this.state = const Value.absent(),
    this.effortStartedAt = const Value.absent(),
    this.effortEndedAt = const Value.absent(),
    this.effortObservers = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitsCompanion.insert({
    required String id,
    required String siteId,
    this.surveyPeriodId = const Value.absent(),
    this.protocolVersionId = const Value.absent(),
    required VisitState state,
    required DateTime effortStartedAt,
    this.effortEndedAt = const Value.absent(),
    this.effortObservers = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       siteId = Value(siteId),
       state = Value(state),
       effortStartedAt = Value(effortStartedAt);
  static Insertable<VisitRow> custom({
    Expression<String>? id,
    Expression<String>? siteId,
    Expression<String>? surveyPeriodId,
    Expression<String>? protocolVersionId,
    Expression<String>? state,
    Expression<DateTime>? effortStartedAt,
    Expression<DateTime>? effortEndedAt,
    Expression<String>? effortObservers,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (siteId != null) 'site_id': siteId,
      if (surveyPeriodId != null) 'survey_period_id': surveyPeriodId,
      if (protocolVersionId != null) 'protocol_version_id': protocolVersionId,
      if (state != null) 'state': state,
      if (effortStartedAt != null) 'effort_started_at': effortStartedAt,
      if (effortEndedAt != null) 'effort_ended_at': effortEndedAt,
      if (effortObservers != null) 'effort_observers': effortObservers,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitsCompanion copyWith({
    Value<String>? id,
    Value<String>? siteId,
    Value<String?>? surveyPeriodId,
    Value<String?>? protocolVersionId,
    Value<VisitState>? state,
    Value<DateTime>? effortStartedAt,
    Value<DateTime?>? effortEndedAt,
    Value<String?>? effortObservers,
    Value<int>? rowid,
  }) {
    return VisitsCompanion(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      surveyPeriodId: surveyPeriodId ?? this.surveyPeriodId,
      protocolVersionId: protocolVersionId ?? this.protocolVersionId,
      state: state ?? this.state,
      effortStartedAt: effortStartedAt ?? this.effortStartedAt,
      effortEndedAt: effortEndedAt ?? this.effortEndedAt,
      effortObservers: effortObservers ?? this.effortObservers,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<String>(siteId.value);
    }
    if (surveyPeriodId.present) {
      map['survey_period_id'] = Variable<String>(surveyPeriodId.value);
    }
    if (protocolVersionId.present) {
      map['protocol_version_id'] = Variable<String>(protocolVersionId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $VisitsTable.$converterstate.toSql(state.value),
      );
    }
    if (effortStartedAt.present) {
      map['effort_started_at'] = Variable<DateTime>(effortStartedAt.value);
    }
    if (effortEndedAt.present) {
      map['effort_ended_at'] = Variable<DateTime>(effortEndedAt.value);
    }
    if (effortObservers.present) {
      map['effort_observers'] = Variable<String>(effortObservers.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitsCompanion(')
          ..write('id: $id, ')
          ..write('siteId: $siteId, ')
          ..write('surveyPeriodId: $surveyPeriodId, ')
          ..write('protocolVersionId: $protocolVersionId, ')
          ..write('state: $state, ')
          ..write('effortStartedAt: $effortStartedAt, ')
          ..write('effortEndedAt: $effortEndedAt, ')
          ..write('effortObservers: $effortObservers, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DetectionsTable extends Detections
    with TableInfo<$DetectionsTable, DetectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DetectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES visits (id)',
    ),
  );
  static const VerificationMeta _taxonRefMeta = const VerificationMeta(
    'taxonRef',
  );
  @override
  late final GeneratedColumn<String> taxonRef = GeneratedColumn<String>(
    'taxon_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detectedMeta = const VerificationMeta(
    'detected',
  );
  @override
  late final GeneratedColumn<bool> detected = GeneratedColumn<bool>(
    'detected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("detected" IN (0, 1))',
    ),
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _opportunisticMeta = const VerificationMeta(
    'opportunistic',
  );
  @override
  late final GeneratedColumn<bool> opportunistic = GeneratedColumn<bool>(
    'opportunistic',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("opportunistic" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    visitId,
    taxonRef,
    detected,
    method,
    count,
    opportunistic,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'detections';
  @override
  VerificationContext validateIntegrity(
    Insertable<DetectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('taxon_ref')) {
      context.handle(
        _taxonRefMeta,
        taxonRef.isAcceptableOrUnknown(data['taxon_ref']!, _taxonRefMeta),
      );
    } else if (isInserting) {
      context.missing(_taxonRefMeta);
    }
    if (data.containsKey('detected')) {
      context.handle(
        _detectedMeta,
        detected.isAcceptableOrUnknown(data['detected']!, _detectedMeta),
      );
    } else if (isInserting) {
      context.missing(_detectedMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('opportunistic')) {
      context.handle(
        _opportunisticMeta,
        opportunistic.isAcceptableOrUnknown(
          data['opportunistic']!,
          _opportunisticMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {visitId, taxonRef};
  @override
  DetectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DetectionRow(
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      taxonRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taxon_ref'],
      )!,
      detected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}detected'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      ),
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      ),
      opportunistic: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}opportunistic'],
      )!,
    );
  }

  @override
  $DetectionsTable createAlias(String alias) {
    return $DetectionsTable(attachedDatabase, alias);
  }
}

class DetectionRow extends DataClass implements Insertable<DetectionRow> {
  final String visitId;
  final String taxonRef;
  final bool detected;
  final String? method;
  final int? count;
  final bool opportunistic;
  const DetectionRow({
    required this.visitId,
    required this.taxonRef,
    required this.detected,
    this.method,
    this.count,
    required this.opportunistic,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['visit_id'] = Variable<String>(visitId);
    map['taxon_ref'] = Variable<String>(taxonRef);
    map['detected'] = Variable<bool>(detected);
    if (!nullToAbsent || method != null) {
      map['method'] = Variable<String>(method);
    }
    if (!nullToAbsent || count != null) {
      map['count'] = Variable<int>(count);
    }
    map['opportunistic'] = Variable<bool>(opportunistic);
    return map;
  }

  DetectionsCompanion toCompanion(bool nullToAbsent) {
    return DetectionsCompanion(
      visitId: Value(visitId),
      taxonRef: Value(taxonRef),
      detected: Value(detected),
      method: method == null && nullToAbsent
          ? const Value.absent()
          : Value(method),
      count: count == null && nullToAbsent
          ? const Value.absent()
          : Value(count),
      opportunistic: Value(opportunistic),
    );
  }

  factory DetectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DetectionRow(
      visitId: serializer.fromJson<String>(json['visitId']),
      taxonRef: serializer.fromJson<String>(json['taxonRef']),
      detected: serializer.fromJson<bool>(json['detected']),
      method: serializer.fromJson<String?>(json['method']),
      count: serializer.fromJson<int?>(json['count']),
      opportunistic: serializer.fromJson<bool>(json['opportunistic']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'visitId': serializer.toJson<String>(visitId),
      'taxonRef': serializer.toJson<String>(taxonRef),
      'detected': serializer.toJson<bool>(detected),
      'method': serializer.toJson<String?>(method),
      'count': serializer.toJson<int?>(count),
      'opportunistic': serializer.toJson<bool>(opportunistic),
    };
  }

  DetectionRow copyWith({
    String? visitId,
    String? taxonRef,
    bool? detected,
    Value<String?> method = const Value.absent(),
    Value<int?> count = const Value.absent(),
    bool? opportunistic,
  }) => DetectionRow(
    visitId: visitId ?? this.visitId,
    taxonRef: taxonRef ?? this.taxonRef,
    detected: detected ?? this.detected,
    method: method.present ? method.value : this.method,
    count: count.present ? count.value : this.count,
    opportunistic: opportunistic ?? this.opportunistic,
  );
  DetectionRow copyWithCompanion(DetectionsCompanion data) {
    return DetectionRow(
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      taxonRef: data.taxonRef.present ? data.taxonRef.value : this.taxonRef,
      detected: data.detected.present ? data.detected.value : this.detected,
      method: data.method.present ? data.method.value : this.method,
      count: data.count.present ? data.count.value : this.count,
      opportunistic: data.opportunistic.present
          ? data.opportunistic.value
          : this.opportunistic,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DetectionRow(')
          ..write('visitId: $visitId, ')
          ..write('taxonRef: $taxonRef, ')
          ..write('detected: $detected, ')
          ..write('method: $method, ')
          ..write('count: $count, ')
          ..write('opportunistic: $opportunistic')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(visitId, taxonRef, detected, method, count, opportunistic);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DetectionRow &&
          other.visitId == this.visitId &&
          other.taxonRef == this.taxonRef &&
          other.detected == this.detected &&
          other.method == this.method &&
          other.count == this.count &&
          other.opportunistic == this.opportunistic);
}

class DetectionsCompanion extends UpdateCompanion<DetectionRow> {
  final Value<String> visitId;
  final Value<String> taxonRef;
  final Value<bool> detected;
  final Value<String?> method;
  final Value<int?> count;
  final Value<bool> opportunistic;
  final Value<int> rowid;
  const DetectionsCompanion({
    this.visitId = const Value.absent(),
    this.taxonRef = const Value.absent(),
    this.detected = const Value.absent(),
    this.method = const Value.absent(),
    this.count = const Value.absent(),
    this.opportunistic = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DetectionsCompanion.insert({
    required String visitId,
    required String taxonRef,
    required bool detected,
    this.method = const Value.absent(),
    this.count = const Value.absent(),
    this.opportunistic = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : visitId = Value(visitId),
       taxonRef = Value(taxonRef),
       detected = Value(detected);
  static Insertable<DetectionRow> custom({
    Expression<String>? visitId,
    Expression<String>? taxonRef,
    Expression<bool>? detected,
    Expression<String>? method,
    Expression<int>? count,
    Expression<bool>? opportunistic,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (visitId != null) 'visit_id': visitId,
      if (taxonRef != null) 'taxon_ref': taxonRef,
      if (detected != null) 'detected': detected,
      if (method != null) 'method': method,
      if (count != null) 'count': count,
      if (opportunistic != null) 'opportunistic': opportunistic,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DetectionsCompanion copyWith({
    Value<String>? visitId,
    Value<String>? taxonRef,
    Value<bool>? detected,
    Value<String?>? method,
    Value<int?>? count,
    Value<bool>? opportunistic,
    Value<int>? rowid,
  }) {
    return DetectionsCompanion(
      visitId: visitId ?? this.visitId,
      taxonRef: taxonRef ?? this.taxonRef,
      detected: detected ?? this.detected,
      method: method ?? this.method,
      count: count ?? this.count,
      opportunistic: opportunistic ?? this.opportunistic,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (taxonRef.present) {
      map['taxon_ref'] = Variable<String>(taxonRef.value);
    }
    if (detected.present) {
      map['detected'] = Variable<bool>(detected.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (opportunistic.present) {
      map['opportunistic'] = Variable<bool>(opportunistic.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DetectionsCompanion(')
          ..write('visitId: $visitId, ')
          ..write('taxonRef: $taxonRef, ')
          ..write('detected: $detected, ')
          ..write('method: $method, ')
          ..write('count: $count, ')
          ..write('opportunistic: $opportunistic, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EvidencesTable extends Evidences
    with TableInfo<$EvidencesTable, EvidenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EvidencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES visits (id)',
    ),
  );
  static const VerificationMeta _taxonRefMeta = const VerificationMeta(
    'taxonRef',
  );
  @override
  late final GeneratedColumn<String> taxonRef = GeneratedColumn<String>(
    'taxon_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EvidenceKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EvidenceKind>($EvidencesTable.$converterkind);
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storageKeyMeta = const VerificationMeta(
    'storageKey',
  );
  @override
  late final GeneratedColumn<String> storageKey = GeneratedColumn<String>(
    'storage_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitId,
    taxonRef,
    kind,
    filePath,
    capturedAt,
    contentHash,
    storageKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'evidences';
  @override
  VerificationContext validateIntegrity(
    Insertable<EvidenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('taxon_ref')) {
      context.handle(
        _taxonRefMeta,
        taxonRef.isAcceptableOrUnknown(data['taxon_ref']!, _taxonRefMeta),
      );
    } else if (isInserting) {
      context.missing(_taxonRefMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('storage_key')) {
      context.handle(
        _storageKeyMeta,
        storageKey.isAcceptableOrUnknown(data['storage_key']!, _storageKeyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EvidenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EvidenceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      taxonRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taxon_ref'],
      )!,
      kind: $EvidencesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      storageKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_key'],
      ),
    );
  }

  @override
  $EvidencesTable createAlias(String alias) {
    return $EvidencesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EvidenceKind, String, String> $converterkind =
      const EnumNameConverter<EvidenceKind>(EvidenceKind.values);
}

class EvidenceRow extends DataClass implements Insertable<EvidenceRow> {
  final String id;
  final String visitId;
  final String taxonRef;
  final EvidenceKind kind;
  final String filePath;
  final DateTime capturedAt;
  final String contentHash;

  /// The content-addressed key the media API returned when this Evidence was
  /// uploaded, or null while it has never been uploaded. It is the transport
  /// reference the submission's evidence manifest carries.
  final String? storageKey;
  const EvidenceRow({
    required this.id,
    required this.visitId,
    required this.taxonRef,
    required this.kind,
    required this.filePath,
    required this.capturedAt,
    required this.contentHash,
    this.storageKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visit_id'] = Variable<String>(visitId);
    map['taxon_ref'] = Variable<String>(taxonRef);
    {
      map['kind'] = Variable<String>(
        $EvidencesTable.$converterkind.toSql(kind),
      );
    }
    map['file_path'] = Variable<String>(filePath);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['content_hash'] = Variable<String>(contentHash);
    if (!nullToAbsent || storageKey != null) {
      map['storage_key'] = Variable<String>(storageKey);
    }
    return map;
  }

  EvidencesCompanion toCompanion(bool nullToAbsent) {
    return EvidencesCompanion(
      id: Value(id),
      visitId: Value(visitId),
      taxonRef: Value(taxonRef),
      kind: Value(kind),
      filePath: Value(filePath),
      capturedAt: Value(capturedAt),
      contentHash: Value(contentHash),
      storageKey: storageKey == null && nullToAbsent
          ? const Value.absent()
          : Value(storageKey),
    );
  }

  factory EvidenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EvidenceRow(
      id: serializer.fromJson<String>(json['id']),
      visitId: serializer.fromJson<String>(json['visitId']),
      taxonRef: serializer.fromJson<String>(json['taxonRef']),
      kind: $EvidencesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      filePath: serializer.fromJson<String>(json['filePath']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      storageKey: serializer.fromJson<String?>(json['storageKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitId': serializer.toJson<String>(visitId),
      'taxonRef': serializer.toJson<String>(taxonRef),
      'kind': serializer.toJson<String>(
        $EvidencesTable.$converterkind.toJson(kind),
      ),
      'filePath': serializer.toJson<String>(filePath),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'contentHash': serializer.toJson<String>(contentHash),
      'storageKey': serializer.toJson<String?>(storageKey),
    };
  }

  EvidenceRow copyWith({
    String? id,
    String? visitId,
    String? taxonRef,
    EvidenceKind? kind,
    String? filePath,
    DateTime? capturedAt,
    String? contentHash,
    Value<String?> storageKey = const Value.absent(),
  }) => EvidenceRow(
    id: id ?? this.id,
    visitId: visitId ?? this.visitId,
    taxonRef: taxonRef ?? this.taxonRef,
    kind: kind ?? this.kind,
    filePath: filePath ?? this.filePath,
    capturedAt: capturedAt ?? this.capturedAt,
    contentHash: contentHash ?? this.contentHash,
    storageKey: storageKey.present ? storageKey.value : this.storageKey,
  );
  EvidenceRow copyWithCompanion(EvidencesCompanion data) {
    return EvidenceRow(
      id: data.id.present ? data.id.value : this.id,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      taxonRef: data.taxonRef.present ? data.taxonRef.value : this.taxonRef,
      kind: data.kind.present ? data.kind.value : this.kind,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      storageKey: data.storageKey.present
          ? data.storageKey.value
          : this.storageKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EvidenceRow(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('taxonRef: $taxonRef, ')
          ..write('kind: $kind, ')
          ..write('filePath: $filePath, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('contentHash: $contentHash, ')
          ..write('storageKey: $storageKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    visitId,
    taxonRef,
    kind,
    filePath,
    capturedAt,
    contentHash,
    storageKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EvidenceRow &&
          other.id == this.id &&
          other.visitId == this.visitId &&
          other.taxonRef == this.taxonRef &&
          other.kind == this.kind &&
          other.filePath == this.filePath &&
          other.capturedAt == this.capturedAt &&
          other.contentHash == this.contentHash &&
          other.storageKey == this.storageKey);
}

class EvidencesCompanion extends UpdateCompanion<EvidenceRow> {
  final Value<String> id;
  final Value<String> visitId;
  final Value<String> taxonRef;
  final Value<EvidenceKind> kind;
  final Value<String> filePath;
  final Value<DateTime> capturedAt;
  final Value<String> contentHash;
  final Value<String?> storageKey;
  final Value<int> rowid;
  const EvidencesCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.taxonRef = const Value.absent(),
    this.kind = const Value.absent(),
    this.filePath = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.storageKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EvidencesCompanion.insert({
    required String id,
    required String visitId,
    required String taxonRef,
    required EvidenceKind kind,
    required String filePath,
    required DateTime capturedAt,
    required String contentHash,
    this.storageKey = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitId = Value(visitId),
       taxonRef = Value(taxonRef),
       kind = Value(kind),
       filePath = Value(filePath),
       capturedAt = Value(capturedAt),
       contentHash = Value(contentHash);
  static Insertable<EvidenceRow> custom({
    Expression<String>? id,
    Expression<String>? visitId,
    Expression<String>? taxonRef,
    Expression<String>? kind,
    Expression<String>? filePath,
    Expression<DateTime>? capturedAt,
    Expression<String>? contentHash,
    Expression<String>? storageKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitId != null) 'visit_id': visitId,
      if (taxonRef != null) 'taxon_ref': taxonRef,
      if (kind != null) 'kind': kind,
      if (filePath != null) 'file_path': filePath,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (contentHash != null) 'content_hash': contentHash,
      if (storageKey != null) 'storage_key': storageKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EvidencesCompanion copyWith({
    Value<String>? id,
    Value<String>? visitId,
    Value<String>? taxonRef,
    Value<EvidenceKind>? kind,
    Value<String>? filePath,
    Value<DateTime>? capturedAt,
    Value<String>? contentHash,
    Value<String?>? storageKey,
    Value<int>? rowid,
  }) {
    return EvidencesCompanion(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      taxonRef: taxonRef ?? this.taxonRef,
      kind: kind ?? this.kind,
      filePath: filePath ?? this.filePath,
      capturedAt: capturedAt ?? this.capturedAt,
      contentHash: contentHash ?? this.contentHash,
      storageKey: storageKey ?? this.storageKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (taxonRef.present) {
      map['taxon_ref'] = Variable<String>(taxonRef.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $EvidencesTable.$converterkind.toSql(kind.value),
      );
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (storageKey.present) {
      map['storage_key'] = Variable<String>(storageKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EvidencesCompanion(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('taxonRef: $taxonRef, ')
          ..write('kind: $kind, ')
          ..write('filePath: $filePath, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('contentHash: $contentHash, ')
          ..write('storageKey: $storageKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeterminationsTable extends Determinations
    with TableInfo<$DeterminationsTable, DeterminationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeterminationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES visits (id)',
    ),
  );
  static const VerificationMeta _taxonRefMeta = const VerificationMeta(
    'taxonRef',
  );
  @override
  late final GeneratedColumn<String> taxonRef = GeneratedColumn<String>(
    'taxon_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxonMeta = const VerificationMeta('taxon');
  @override
  late final GeneratedColumn<String> taxon = GeneratedColumn<String>(
    'taxon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DeterminationQualifier?, String>
  qualifier =
      GeneratedColumn<String>(
        'qualifier',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DeterminationQualifier?>(
        $DeterminationsTable.$converterqualifiern,
      );
  static const VerificationMeta _specimenCodeMeta = const VerificationMeta(
    'specimenCode',
  );
  @override
  late final GeneratedColumn<String> specimenCode = GeneratedColumn<String>(
    'specimen_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _determinerMeta = const VerificationMeta(
    'determiner',
  );
  @override
  late final GeneratedColumn<String> determiner = GeneratedColumn<String>(
    'determiner',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _replacesIdMeta = const VerificationMeta(
    'replacesId',
  );
  @override
  late final GeneratedColumn<String> replacesId = GeneratedColumn<String>(
    'replaces_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitId,
    taxonRef,
    taxon,
    qualifier,
    specimenCode,
    determiner,
    date,
    replacesId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'determinations';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeterminationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('taxon_ref')) {
      context.handle(
        _taxonRefMeta,
        taxonRef.isAcceptableOrUnknown(data['taxon_ref']!, _taxonRefMeta),
      );
    } else if (isInserting) {
      context.missing(_taxonRefMeta);
    }
    if (data.containsKey('taxon')) {
      context.handle(
        _taxonMeta,
        taxon.isAcceptableOrUnknown(data['taxon']!, _taxonMeta),
      );
    } else if (isInserting) {
      context.missing(_taxonMeta);
    }
    if (data.containsKey('specimen_code')) {
      context.handle(
        _specimenCodeMeta,
        specimenCode.isAcceptableOrUnknown(
          data['specimen_code']!,
          _specimenCodeMeta,
        ),
      );
    }
    if (data.containsKey('determiner')) {
      context.handle(
        _determinerMeta,
        determiner.isAcceptableOrUnknown(data['determiner']!, _determinerMeta),
      );
    } else if (isInserting) {
      context.missing(_determinerMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('replaces_id')) {
      context.handle(
        _replacesIdMeta,
        replacesId.isAcceptableOrUnknown(data['replaces_id']!, _replacesIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeterminationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeterminationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      taxonRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taxon_ref'],
      )!,
      taxon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taxon'],
      )!,
      qualifier: $DeterminationsTable.$converterqualifiern.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}qualifier'],
        ),
      ),
      specimenCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}specimen_code'],
      ),
      determiner: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}determiner'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      replacesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}replaces_id'],
      ),
    );
  }

  @override
  $DeterminationsTable createAlias(String alias) {
    return $DeterminationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DeterminationQualifier, String, String>
  $converterqualifier = const EnumNameConverter<DeterminationQualifier>(
    DeterminationQualifier.values,
  );
  static JsonTypeConverter2<DeterminationQualifier?, String?, String?>
  $converterqualifiern = JsonTypeConverter2.asNullable($converterqualifier);
}

class DeterminationRow extends DataClass
    implements Insertable<DeterminationRow> {
  final String id;
  final String visitId;
  final String taxonRef;
  final String taxon;
  final DeterminationQualifier? qualifier;
  final String? specimenCode;
  final String determiner;
  final DateTime date;
  final String? replacesId;
  const DeterminationRow({
    required this.id,
    required this.visitId,
    required this.taxonRef,
    required this.taxon,
    this.qualifier,
    this.specimenCode,
    required this.determiner,
    required this.date,
    this.replacesId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visit_id'] = Variable<String>(visitId);
    map['taxon_ref'] = Variable<String>(taxonRef);
    map['taxon'] = Variable<String>(taxon);
    if (!nullToAbsent || qualifier != null) {
      map['qualifier'] = Variable<String>(
        $DeterminationsTable.$converterqualifiern.toSql(qualifier),
      );
    }
    if (!nullToAbsent || specimenCode != null) {
      map['specimen_code'] = Variable<String>(specimenCode);
    }
    map['determiner'] = Variable<String>(determiner);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || replacesId != null) {
      map['replaces_id'] = Variable<String>(replacesId);
    }
    return map;
  }

  DeterminationsCompanion toCompanion(bool nullToAbsent) {
    return DeterminationsCompanion(
      id: Value(id),
      visitId: Value(visitId),
      taxonRef: Value(taxonRef),
      taxon: Value(taxon),
      qualifier: qualifier == null && nullToAbsent
          ? const Value.absent()
          : Value(qualifier),
      specimenCode: specimenCode == null && nullToAbsent
          ? const Value.absent()
          : Value(specimenCode),
      determiner: Value(determiner),
      date: Value(date),
      replacesId: replacesId == null && nullToAbsent
          ? const Value.absent()
          : Value(replacesId),
    );
  }

  factory DeterminationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeterminationRow(
      id: serializer.fromJson<String>(json['id']),
      visitId: serializer.fromJson<String>(json['visitId']),
      taxonRef: serializer.fromJson<String>(json['taxonRef']),
      taxon: serializer.fromJson<String>(json['taxon']),
      qualifier: $DeterminationsTable.$converterqualifiern.fromJson(
        serializer.fromJson<String?>(json['qualifier']),
      ),
      specimenCode: serializer.fromJson<String?>(json['specimenCode']),
      determiner: serializer.fromJson<String>(json['determiner']),
      date: serializer.fromJson<DateTime>(json['date']),
      replacesId: serializer.fromJson<String?>(json['replacesId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitId': serializer.toJson<String>(visitId),
      'taxonRef': serializer.toJson<String>(taxonRef),
      'taxon': serializer.toJson<String>(taxon),
      'qualifier': serializer.toJson<String?>(
        $DeterminationsTable.$converterqualifiern.toJson(qualifier),
      ),
      'specimenCode': serializer.toJson<String?>(specimenCode),
      'determiner': serializer.toJson<String>(determiner),
      'date': serializer.toJson<DateTime>(date),
      'replacesId': serializer.toJson<String?>(replacesId),
    };
  }

  DeterminationRow copyWith({
    String? id,
    String? visitId,
    String? taxonRef,
    String? taxon,
    Value<DeterminationQualifier?> qualifier = const Value.absent(),
    Value<String?> specimenCode = const Value.absent(),
    String? determiner,
    DateTime? date,
    Value<String?> replacesId = const Value.absent(),
  }) => DeterminationRow(
    id: id ?? this.id,
    visitId: visitId ?? this.visitId,
    taxonRef: taxonRef ?? this.taxonRef,
    taxon: taxon ?? this.taxon,
    qualifier: qualifier.present ? qualifier.value : this.qualifier,
    specimenCode: specimenCode.present ? specimenCode.value : this.specimenCode,
    determiner: determiner ?? this.determiner,
    date: date ?? this.date,
    replacesId: replacesId.present ? replacesId.value : this.replacesId,
  );
  DeterminationRow copyWithCompanion(DeterminationsCompanion data) {
    return DeterminationRow(
      id: data.id.present ? data.id.value : this.id,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      taxonRef: data.taxonRef.present ? data.taxonRef.value : this.taxonRef,
      taxon: data.taxon.present ? data.taxon.value : this.taxon,
      qualifier: data.qualifier.present ? data.qualifier.value : this.qualifier,
      specimenCode: data.specimenCode.present
          ? data.specimenCode.value
          : this.specimenCode,
      determiner: data.determiner.present
          ? data.determiner.value
          : this.determiner,
      date: data.date.present ? data.date.value : this.date,
      replacesId: data.replacesId.present
          ? data.replacesId.value
          : this.replacesId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeterminationRow(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('taxonRef: $taxonRef, ')
          ..write('taxon: $taxon, ')
          ..write('qualifier: $qualifier, ')
          ..write('specimenCode: $specimenCode, ')
          ..write('determiner: $determiner, ')
          ..write('date: $date, ')
          ..write('replacesId: $replacesId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    visitId,
    taxonRef,
    taxon,
    qualifier,
    specimenCode,
    determiner,
    date,
    replacesId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeterminationRow &&
          other.id == this.id &&
          other.visitId == this.visitId &&
          other.taxonRef == this.taxonRef &&
          other.taxon == this.taxon &&
          other.qualifier == this.qualifier &&
          other.specimenCode == this.specimenCode &&
          other.determiner == this.determiner &&
          other.date == this.date &&
          other.replacesId == this.replacesId);
}

class DeterminationsCompanion extends UpdateCompanion<DeterminationRow> {
  final Value<String> id;
  final Value<String> visitId;
  final Value<String> taxonRef;
  final Value<String> taxon;
  final Value<DeterminationQualifier?> qualifier;
  final Value<String?> specimenCode;
  final Value<String> determiner;
  final Value<DateTime> date;
  final Value<String?> replacesId;
  final Value<int> rowid;
  const DeterminationsCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.taxonRef = const Value.absent(),
    this.taxon = const Value.absent(),
    this.qualifier = const Value.absent(),
    this.specimenCode = const Value.absent(),
    this.determiner = const Value.absent(),
    this.date = const Value.absent(),
    this.replacesId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeterminationsCompanion.insert({
    required String id,
    required String visitId,
    required String taxonRef,
    required String taxon,
    this.qualifier = const Value.absent(),
    this.specimenCode = const Value.absent(),
    required String determiner,
    required DateTime date,
    this.replacesId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitId = Value(visitId),
       taxonRef = Value(taxonRef),
       taxon = Value(taxon),
       determiner = Value(determiner),
       date = Value(date);
  static Insertable<DeterminationRow> custom({
    Expression<String>? id,
    Expression<String>? visitId,
    Expression<String>? taxonRef,
    Expression<String>? taxon,
    Expression<String>? qualifier,
    Expression<String>? specimenCode,
    Expression<String>? determiner,
    Expression<DateTime>? date,
    Expression<String>? replacesId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitId != null) 'visit_id': visitId,
      if (taxonRef != null) 'taxon_ref': taxonRef,
      if (taxon != null) 'taxon': taxon,
      if (qualifier != null) 'qualifier': qualifier,
      if (specimenCode != null) 'specimen_code': specimenCode,
      if (determiner != null) 'determiner': determiner,
      if (date != null) 'date': date,
      if (replacesId != null) 'replaces_id': replacesId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeterminationsCompanion copyWith({
    Value<String>? id,
    Value<String>? visitId,
    Value<String>? taxonRef,
    Value<String>? taxon,
    Value<DeterminationQualifier?>? qualifier,
    Value<String?>? specimenCode,
    Value<String>? determiner,
    Value<DateTime>? date,
    Value<String?>? replacesId,
    Value<int>? rowid,
  }) {
    return DeterminationsCompanion(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      taxonRef: taxonRef ?? this.taxonRef,
      taxon: taxon ?? this.taxon,
      qualifier: qualifier ?? this.qualifier,
      specimenCode: specimenCode ?? this.specimenCode,
      determiner: determiner ?? this.determiner,
      date: date ?? this.date,
      replacesId: replacesId ?? this.replacesId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (taxonRef.present) {
      map['taxon_ref'] = Variable<String>(taxonRef.value);
    }
    if (taxon.present) {
      map['taxon'] = Variable<String>(taxon.value);
    }
    if (qualifier.present) {
      map['qualifier'] = Variable<String>(
        $DeterminationsTable.$converterqualifiern.toSql(qualifier.value),
      );
    }
    if (specimenCode.present) {
      map['specimen_code'] = Variable<String>(specimenCode.value);
    }
    if (determiner.present) {
      map['determiner'] = Variable<String>(determiner.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (replacesId.present) {
      map['replaces_id'] = Variable<String>(replacesId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeterminationsCompanion(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('taxonRef: $taxonRef, ')
          ..write('taxon: $taxon, ')
          ..write('qualifier: $qualifier, ')
          ..write('specimenCode: $specimenCode, ')
          ..write('determiner: $determiner, ')
          ..write('date: $date, ')
          ..write('replacesId: $replacesId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeasurementsTable extends Measurements
    with TableInfo<$MeasurementsTable, MeasurementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES visits (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _provenanceMeta = const VerificationMeta(
    'provenance',
  );
  @override
  late final GeneratedColumn<String> provenance = GeneratedColumn<String>(
    'provenance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitId,
    name,
    value,
    unit,
    provenance,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurements';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeasurementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('provenance')) {
      context.handle(
        _provenanceMeta,
        provenance.isAcceptableOrUnknown(data['provenance']!, _provenanceMeta),
      );
    } else if (isInserting) {
      context.missing(_provenanceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeasurementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeasurementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      provenance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance'],
      )!,
    );
  }

  @override
  $MeasurementsTable createAlias(String alias) {
    return $MeasurementsTable(attachedDatabase, alias);
  }
}

class MeasurementRow extends DataClass implements Insertable<MeasurementRow> {
  final String id;
  final String visitId;
  final String name;
  final String value;
  final String? unit;
  final String provenance;
  const MeasurementRow({
    required this.id,
    required this.visitId,
    required this.name,
    required this.value,
    this.unit,
    required this.provenance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visit_id'] = Variable<String>(visitId);
    map['name'] = Variable<String>(name);
    map['value'] = Variable<String>(value);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['provenance'] = Variable<String>(provenance);
    return map;
  }

  MeasurementsCompanion toCompanion(bool nullToAbsent) {
    return MeasurementsCompanion(
      id: Value(id),
      visitId: Value(visitId),
      name: Value(name),
      value: Value(value),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      provenance: Value(provenance),
    );
  }

  factory MeasurementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeasurementRow(
      id: serializer.fromJson<String>(json['id']),
      visitId: serializer.fromJson<String>(json['visitId']),
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<String>(json['value']),
      unit: serializer.fromJson<String?>(json['unit']),
      provenance: serializer.fromJson<String>(json['provenance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitId': serializer.toJson<String>(visitId),
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<String>(value),
      'unit': serializer.toJson<String?>(unit),
      'provenance': serializer.toJson<String>(provenance),
    };
  }

  MeasurementRow copyWith({
    String? id,
    String? visitId,
    String? name,
    String? value,
    Value<String?> unit = const Value.absent(),
    String? provenance,
  }) => MeasurementRow(
    id: id ?? this.id,
    visitId: visitId ?? this.visitId,
    name: name ?? this.name,
    value: value ?? this.value,
    unit: unit.present ? unit.value : this.unit,
    provenance: provenance ?? this.provenance,
  );
  MeasurementRow copyWithCompanion(MeasurementsCompanion data) {
    return MeasurementRow(
      id: data.id.present ? data.id.value : this.id,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      provenance: data.provenance.present
          ? data.provenance.value
          : this.provenance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementRow(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('provenance: $provenance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, visitId, name, value, unit, provenance);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeasurementRow &&
          other.id == this.id &&
          other.visitId == this.visitId &&
          other.name == this.name &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.provenance == this.provenance);
}

class MeasurementsCompanion extends UpdateCompanion<MeasurementRow> {
  final Value<String> id;
  final Value<String> visitId;
  final Value<String> name;
  final Value<String> value;
  final Value<String?> unit;
  final Value<String> provenance;
  final Value<int> rowid;
  const MeasurementsCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.provenance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeasurementsCompanion.insert({
    required String id,
    required String visitId,
    required String name,
    required String value,
    this.unit = const Value.absent(),
    required String provenance,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitId = Value(visitId),
       name = Value(name),
       value = Value(value),
       provenance = Value(provenance);
  static Insertable<MeasurementRow> custom({
    Expression<String>? id,
    Expression<String>? visitId,
    Expression<String>? name,
    Expression<String>? value,
    Expression<String>? unit,
    Expression<String>? provenance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitId != null) 'visit_id': visitId,
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (provenance != null) 'provenance': provenance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeasurementsCompanion copyWith({
    Value<String>? id,
    Value<String>? visitId,
    Value<String>? name,
    Value<String>? value,
    Value<String?>? unit,
    Value<String>? provenance,
    Value<int>? rowid,
  }) {
    return MeasurementsCompanion(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      name: name ?? this.name,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      provenance: provenance ?? this.provenance,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (provenance.present) {
      map['provenance'] = Variable<String>(provenance.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('provenance: $provenance, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects
    with TableInfo<$ProjectsTable, ProjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _validationEnabledMeta = const VerificationMeta(
    'validationEnabled',
  );
  @override
  late final GeneratedColumn<bool> validationEnabled = GeneratedColumn<bool>(
    'validation_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("validation_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _sensitiveTaxaObfuscationMeta =
      const VerificationMeta('sensitiveTaxaObfuscation');
  @override
  late final GeneratedColumn<bool> sensitiveTaxaObfuscation =
      GeneratedColumn<bool>(
        'sensitive_taxa_obfuscation',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("sensitive_taxa_obfuscation" IN (0, 1))',
        ),
      );
  static const VerificationMeta _taxonomicReferenceIdMeta =
      const VerificationMeta('taxonomicReferenceId');
  @override
  late final GeneratedColumn<String> taxonomicReferenceId =
      GeneratedColumn<String>(
        'taxonomic_reference_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _taxonomicReferenceVersionMeta =
      const VerificationMeta('taxonomicReferenceVersion');
  @override
  late final GeneratedColumn<String> taxonomicReferenceVersion =
      GeneratedColumn<String>(
        'taxonomic_reference_version',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    validationEnabled,
    sensitiveTaxaObfuscation,
    taxonomicReferenceId,
    taxonomicReferenceVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('validation_enabled')) {
      context.handle(
        _validationEnabledMeta,
        validationEnabled.isAcceptableOrUnknown(
          data['validation_enabled']!,
          _validationEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_validationEnabledMeta);
    }
    if (data.containsKey('sensitive_taxa_obfuscation')) {
      context.handle(
        _sensitiveTaxaObfuscationMeta,
        sensitiveTaxaObfuscation.isAcceptableOrUnknown(
          data['sensitive_taxa_obfuscation']!,
          _sensitiveTaxaObfuscationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sensitiveTaxaObfuscationMeta);
    }
    if (data.containsKey('taxonomic_reference_id')) {
      context.handle(
        _taxonomicReferenceIdMeta,
        taxonomicReferenceId.isAcceptableOrUnknown(
          data['taxonomic_reference_id']!,
          _taxonomicReferenceIdMeta,
        ),
      );
    }
    if (data.containsKey('taxonomic_reference_version')) {
      context.handle(
        _taxonomicReferenceVersionMeta,
        taxonomicReferenceVersion.isAcceptableOrUnknown(
          data['taxonomic_reference_version']!,
          _taxonomicReferenceVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      validationEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}validation_enabled'],
      )!,
      sensitiveTaxaObfuscation: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sensitive_taxa_obfuscation'],
      )!,
      taxonomicReferenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taxonomic_reference_id'],
      ),
      taxonomicReferenceVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taxonomic_reference_version'],
      ),
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class ProjectRow extends DataClass implements Insertable<ProjectRow> {
  final String id;
  final String name;

  /// Short authored text describing the Project (`DOMAIN.md` Project
  /// aggregate, ADR-0016), or null when none was set. The config pull carries
  /// the server's `project.description` into this column.
  final String? description;
  final bool validationEnabled;
  final bool sensitiveTaxaObfuscation;

  /// The pinned Taxonomic reference is chosen after the Project is created
  /// (`DOMAIN.md` Project aggregate), so both columns are null until one is set.
  final String? taxonomicReferenceId;
  final String? taxonomicReferenceVersion;
  const ProjectRow({
    required this.id,
    required this.name,
    this.description,
    required this.validationEnabled,
    required this.sensitiveTaxaObfuscation,
    this.taxonomicReferenceId,
    this.taxonomicReferenceVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['validation_enabled'] = Variable<bool>(validationEnabled);
    map['sensitive_taxa_obfuscation'] = Variable<bool>(
      sensitiveTaxaObfuscation,
    );
    if (!nullToAbsent || taxonomicReferenceId != null) {
      map['taxonomic_reference_id'] = Variable<String>(taxonomicReferenceId);
    }
    if (!nullToAbsent || taxonomicReferenceVersion != null) {
      map['taxonomic_reference_version'] = Variable<String>(
        taxonomicReferenceVersion,
      );
    }
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      validationEnabled: Value(validationEnabled),
      sensitiveTaxaObfuscation: Value(sensitiveTaxaObfuscation),
      taxonomicReferenceId: taxonomicReferenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(taxonomicReferenceId),
      taxonomicReferenceVersion:
          taxonomicReferenceVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(taxonomicReferenceVersion),
    );
  }

  factory ProjectRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      validationEnabled: serializer.fromJson<bool>(json['validationEnabled']),
      sensitiveTaxaObfuscation: serializer.fromJson<bool>(
        json['sensitiveTaxaObfuscation'],
      ),
      taxonomicReferenceId: serializer.fromJson<String?>(
        json['taxonomicReferenceId'],
      ),
      taxonomicReferenceVersion: serializer.fromJson<String?>(
        json['taxonomicReferenceVersion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'validationEnabled': serializer.toJson<bool>(validationEnabled),
      'sensitiveTaxaObfuscation': serializer.toJson<bool>(
        sensitiveTaxaObfuscation,
      ),
      'taxonomicReferenceId': serializer.toJson<String?>(taxonomicReferenceId),
      'taxonomicReferenceVersion': serializer.toJson<String?>(
        taxonomicReferenceVersion,
      ),
    };
  }

  ProjectRow copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    bool? validationEnabled,
    bool? sensitiveTaxaObfuscation,
    Value<String?> taxonomicReferenceId = const Value.absent(),
    Value<String?> taxonomicReferenceVersion = const Value.absent(),
  }) => ProjectRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    validationEnabled: validationEnabled ?? this.validationEnabled,
    sensitiveTaxaObfuscation:
        sensitiveTaxaObfuscation ?? this.sensitiveTaxaObfuscation,
    taxonomicReferenceId: taxonomicReferenceId.present
        ? taxonomicReferenceId.value
        : this.taxonomicReferenceId,
    taxonomicReferenceVersion: taxonomicReferenceVersion.present
        ? taxonomicReferenceVersion.value
        : this.taxonomicReferenceVersion,
  );
  ProjectRow copyWithCompanion(ProjectsCompanion data) {
    return ProjectRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      validationEnabled: data.validationEnabled.present
          ? data.validationEnabled.value
          : this.validationEnabled,
      sensitiveTaxaObfuscation: data.sensitiveTaxaObfuscation.present
          ? data.sensitiveTaxaObfuscation.value
          : this.sensitiveTaxaObfuscation,
      taxonomicReferenceId: data.taxonomicReferenceId.present
          ? data.taxonomicReferenceId.value
          : this.taxonomicReferenceId,
      taxonomicReferenceVersion: data.taxonomicReferenceVersion.present
          ? data.taxonomicReferenceVersion.value
          : this.taxonomicReferenceVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('validationEnabled: $validationEnabled, ')
          ..write('sensitiveTaxaObfuscation: $sensitiveTaxaObfuscation, ')
          ..write('taxonomicReferenceId: $taxonomicReferenceId, ')
          ..write('taxonomicReferenceVersion: $taxonomicReferenceVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    validationEnabled,
    sensitiveTaxaObfuscation,
    taxonomicReferenceId,
    taxonomicReferenceVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.validationEnabled == this.validationEnabled &&
          other.sensitiveTaxaObfuscation == this.sensitiveTaxaObfuscation &&
          other.taxonomicReferenceId == this.taxonomicReferenceId &&
          other.taxonomicReferenceVersion == this.taxonomicReferenceVersion);
}

class ProjectsCompanion extends UpdateCompanion<ProjectRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<bool> validationEnabled;
  final Value<bool> sensitiveTaxaObfuscation;
  final Value<String?> taxonomicReferenceId;
  final Value<String?> taxonomicReferenceVersion;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.validationEnabled = const Value.absent(),
    this.sensitiveTaxaObfuscation = const Value.absent(),
    this.taxonomicReferenceId = const Value.absent(),
    this.taxonomicReferenceVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required bool validationEnabled,
    required bool sensitiveTaxaObfuscation,
    this.taxonomicReferenceId = const Value.absent(),
    this.taxonomicReferenceVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       validationEnabled = Value(validationEnabled),
       sensitiveTaxaObfuscation = Value(sensitiveTaxaObfuscation);
  static Insertable<ProjectRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? validationEnabled,
    Expression<bool>? sensitiveTaxaObfuscation,
    Expression<String>? taxonomicReferenceId,
    Expression<String>? taxonomicReferenceVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (validationEnabled != null) 'validation_enabled': validationEnabled,
      if (sensitiveTaxaObfuscation != null)
        'sensitive_taxa_obfuscation': sensitiveTaxaObfuscation,
      if (taxonomicReferenceId != null)
        'taxonomic_reference_id': taxonomicReferenceId,
      if (taxonomicReferenceVersion != null)
        'taxonomic_reference_version': taxonomicReferenceVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<bool>? validationEnabled,
    Value<bool>? sensitiveTaxaObfuscation,
    Value<String?>? taxonomicReferenceId,
    Value<String?>? taxonomicReferenceVersion,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      validationEnabled: validationEnabled ?? this.validationEnabled,
      sensitiveTaxaObfuscation:
          sensitiveTaxaObfuscation ?? this.sensitiveTaxaObfuscation,
      taxonomicReferenceId: taxonomicReferenceId ?? this.taxonomicReferenceId,
      taxonomicReferenceVersion:
          taxonomicReferenceVersion ?? this.taxonomicReferenceVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (validationEnabled.present) {
      map['validation_enabled'] = Variable<bool>(validationEnabled.value);
    }
    if (sensitiveTaxaObfuscation.present) {
      map['sensitive_taxa_obfuscation'] = Variable<bool>(
        sensitiveTaxaObfuscation.value,
      );
    }
    if (taxonomicReferenceId.present) {
      map['taxonomic_reference_id'] = Variable<String>(
        taxonomicReferenceId.value,
      );
    }
    if (taxonomicReferenceVersion.present) {
      map['taxonomic_reference_version'] = Variable<String>(
        taxonomicReferenceVersion.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('validationEnabled: $validationEnabled, ')
          ..write('sensitiveTaxaObfuscation: $sensitiveTaxaObfuscation, ')
          ..write('taxonomicReferenceId: $taxonomicReferenceId, ')
          ..write('taxonomicReferenceVersion: $taxonomicReferenceVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProtocolVersionsTable extends ProtocolVersions
    with TableInfo<$ProtocolVersionsTable, ProtocolVersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProtocolVersionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _protocolIdMeta = const VerificationMeta(
    'protocolId',
  );
  @override
  late final GeneratedColumn<String> protocolId = GeneratedColumn<String>(
    'protocol_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentMeta = const VerificationMeta(
    'document',
  );
  @override
  late final GeneratedColumn<String> document = GeneratedColumn<String>(
    'document',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frozenAtMeta = const VerificationMeta(
    'frozenAt',
  );
  @override
  late final GeneratedColumn<DateTime> frozenAt = GeneratedColumn<DateTime>(
    'frozen_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    protocolId,
    version,
    document,
    frozenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'protocol_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProtocolVersionRow> instance, {
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
    if (data.containsKey('protocol_id')) {
      context.handle(
        _protocolIdMeta,
        protocolId.isAcceptableOrUnknown(data['protocol_id']!, _protocolIdMeta),
      );
    } else if (isInserting) {
      context.missing(_protocolIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('document')) {
      context.handle(
        _documentMeta,
        document.isAcceptableOrUnknown(data['document']!, _documentMeta),
      );
    } else if (isInserting) {
      context.missing(_documentMeta);
    }
    if (data.containsKey('frozen_at')) {
      context.handle(
        _frozenAtMeta,
        frozenAt.isAcceptableOrUnknown(data['frozen_at']!, _frozenAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProtocolVersionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProtocolVersionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      protocolId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protocol_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      document: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document'],
      )!,
      frozenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}frozen_at'],
      ),
    );
  }

  @override
  $ProtocolVersionsTable createAlias(String alias) {
    return $ProtocolVersionsTable(attachedDatabase, alias);
  }
}

class ProtocolVersionRow extends DataClass
    implements Insertable<ProtocolVersionRow> {
  final String id;
  final String projectId;
  final String protocolId;
  final int version;
  final String document;
  final DateTime? frozenAt;
  const ProtocolVersionRow({
    required this.id,
    required this.projectId,
    required this.protocolId,
    required this.version,
    required this.document,
    this.frozenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['protocol_id'] = Variable<String>(protocolId);
    map['version'] = Variable<int>(version);
    map['document'] = Variable<String>(document);
    if (!nullToAbsent || frozenAt != null) {
      map['frozen_at'] = Variable<DateTime>(frozenAt);
    }
    return map;
  }

  ProtocolVersionsCompanion toCompanion(bool nullToAbsent) {
    return ProtocolVersionsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      protocolId: Value(protocolId),
      version: Value(version),
      document: Value(document),
      frozenAt: frozenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(frozenAt),
    );
  }

  factory ProtocolVersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProtocolVersionRow(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      protocolId: serializer.fromJson<String>(json['protocolId']),
      version: serializer.fromJson<int>(json['version']),
      document: serializer.fromJson<String>(json['document']),
      frozenAt: serializer.fromJson<DateTime?>(json['frozenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'protocolId': serializer.toJson<String>(protocolId),
      'version': serializer.toJson<int>(version),
      'document': serializer.toJson<String>(document),
      'frozenAt': serializer.toJson<DateTime?>(frozenAt),
    };
  }

  ProtocolVersionRow copyWith({
    String? id,
    String? projectId,
    String? protocolId,
    int? version,
    String? document,
    Value<DateTime?> frozenAt = const Value.absent(),
  }) => ProtocolVersionRow(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    protocolId: protocolId ?? this.protocolId,
    version: version ?? this.version,
    document: document ?? this.document,
    frozenAt: frozenAt.present ? frozenAt.value : this.frozenAt,
  );
  ProtocolVersionRow copyWithCompanion(ProtocolVersionsCompanion data) {
    return ProtocolVersionRow(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      protocolId: data.protocolId.present
          ? data.protocolId.value
          : this.protocolId,
      version: data.version.present ? data.version.value : this.version,
      document: data.document.present ? data.document.value : this.document,
      frozenAt: data.frozenAt.present ? data.frozenAt.value : this.frozenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProtocolVersionRow(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('protocolId: $protocolId, ')
          ..write('version: $version, ')
          ..write('document: $document, ')
          ..write('frozenAt: $frozenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, projectId, protocolId, version, document, frozenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProtocolVersionRow &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.protocolId == this.protocolId &&
          other.version == this.version &&
          other.document == this.document &&
          other.frozenAt == this.frozenAt);
}

class ProtocolVersionsCompanion extends UpdateCompanion<ProtocolVersionRow> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> protocolId;
  final Value<int> version;
  final Value<String> document;
  final Value<DateTime?> frozenAt;
  final Value<int> rowid;
  const ProtocolVersionsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.protocolId = const Value.absent(),
    this.version = const Value.absent(),
    this.document = const Value.absent(),
    this.frozenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProtocolVersionsCompanion.insert({
    required String id,
    required String projectId,
    required String protocolId,
    required int version,
    required String document,
    this.frozenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       protocolId = Value(protocolId),
       version = Value(version),
       document = Value(document);
  static Insertable<ProtocolVersionRow> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? protocolId,
    Expression<int>? version,
    Expression<String>? document,
    Expression<DateTime>? frozenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (protocolId != null) 'protocol_id': protocolId,
      if (version != null) 'version': version,
      if (document != null) 'document': document,
      if (frozenAt != null) 'frozen_at': frozenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProtocolVersionsCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? protocolId,
    Value<int>? version,
    Value<String>? document,
    Value<DateTime?>? frozenAt,
    Value<int>? rowid,
  }) {
    return ProtocolVersionsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      protocolId: protocolId ?? this.protocolId,
      version: version ?? this.version,
      document: document ?? this.document,
      frozenAt: frozenAt ?? this.frozenAt,
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
    if (protocolId.present) {
      map['protocol_id'] = Variable<String>(protocolId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (document.present) {
      map['document'] = Variable<String>(document.value);
    }
    if (frozenAt.present) {
      map['frozen_at'] = Variable<DateTime>(frozenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProtocolVersionsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('protocolId: $protocolId, ')
          ..write('version: $version, ')
          ..write('document: $document, ')
          ..write('frozenAt: $frozenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SurveyPeriodsTable extends SurveyPeriods
    with TableInfo<$SurveyPeriodsTable, SurveyPeriodRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurveyPeriodsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    name,
    startDate,
    endDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'survey_periods';
  @override
  VerificationContext validateIntegrity(
    Insertable<SurveyPeriodRow> instance, {
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SurveyPeriodRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurveyPeriodRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      )!,
    );
  }

  @override
  $SurveyPeriodsTable createAlias(String alias) {
    return $SurveyPeriodsTable(attachedDatabase, alias);
  }
}

class SurveyPeriodRow extends DataClass implements Insertable<SurveyPeriodRow> {
  final String id;
  final String projectId;
  final String name;
  final String startDate;
  final String endDate;
  const SurveyPeriodRow({
    required this.id,
    required this.projectId,
    required this.name,
    required this.startDate,
    required this.endDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['name'] = Variable<String>(name);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    return map;
  }

  SurveyPeriodsCompanion toCompanion(bool nullToAbsent) {
    return SurveyPeriodsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      name: Value(name),
      startDate: Value(startDate),
      endDate: Value(endDate),
    );
  }

  factory SurveyPeriodRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurveyPeriodRow(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'name': serializer.toJson<String>(name),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
    };
  }

  SurveyPeriodRow copyWith({
    String? id,
    String? projectId,
    String? name,
    String? startDate,
    String? endDate,
  }) => SurveyPeriodRow(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
  );
  SurveyPeriodRow copyWithCompanion(SurveyPeriodsCompanion data) {
    return SurveyPeriodRow(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurveyPeriodRow(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, name, startDate, endDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurveyPeriodRow &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate);
}

class SurveyPeriodsCompanion extends UpdateCompanion<SurveyPeriodRow> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> name;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<int> rowid;
  const SurveyPeriodsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurveyPeriodsCompanion.insert({
    required String id,
    required String projectId,
    required String name,
    required String startDate,
    required String endDate,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       name = Value(name),
       startDate = Value(startDate),
       endDate = Value(endDate);
  static Insertable<SurveyPeriodRow> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? name,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurveyPeriodsCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? name,
    Value<String>? startDate,
    Value<String>? endDate,
    Value<int>? rowid,
  }) {
    return SurveyPeriodsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurveyPeriodsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConfigStatesTable extends ConfigStates
    with TableInfo<$ConfigStatesTable, ConfigStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfigStatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _versionTokenMeta = const VerificationMeta(
    'versionToken',
  );
  @override
  late final GeneratedColumn<String> versionToken = GeneratedColumn<String>(
    'version_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [projectId, versionToken];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'config_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConfigStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('version_token')) {
      context.handle(
        _versionTokenMeta,
        versionToken.isAcceptableOrUnknown(
          data['version_token']!,
          _versionTokenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionTokenMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {projectId};
  @override
  ConfigStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfigStateRow(
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      versionToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version_token'],
      )!,
    );
  }

  @override
  $ConfigStatesTable createAlias(String alias) {
    return $ConfigStatesTable(attachedDatabase, alias);
  }
}

class ConfigStateRow extends DataClass implements Insertable<ConfigStateRow> {
  final String projectId;
  final String versionToken;
  const ConfigStateRow({required this.projectId, required this.versionToken});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['project_id'] = Variable<String>(projectId);
    map['version_token'] = Variable<String>(versionToken);
    return map;
  }

  ConfigStatesCompanion toCompanion(bool nullToAbsent) {
    return ConfigStatesCompanion(
      projectId: Value(projectId),
      versionToken: Value(versionToken),
    );
  }

  factory ConfigStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfigStateRow(
      projectId: serializer.fromJson<String>(json['projectId']),
      versionToken: serializer.fromJson<String>(json['versionToken']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'projectId': serializer.toJson<String>(projectId),
      'versionToken': serializer.toJson<String>(versionToken),
    };
  }

  ConfigStateRow copyWith({String? projectId, String? versionToken}) =>
      ConfigStateRow(
        projectId: projectId ?? this.projectId,
        versionToken: versionToken ?? this.versionToken,
      );
  ConfigStateRow copyWithCompanion(ConfigStatesCompanion data) {
    return ConfigStateRow(
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      versionToken: data.versionToken.present
          ? data.versionToken.value
          : this.versionToken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfigStateRow(')
          ..write('projectId: $projectId, ')
          ..write('versionToken: $versionToken')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(projectId, versionToken);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfigStateRow &&
          other.projectId == this.projectId &&
          other.versionToken == this.versionToken);
}

class ConfigStatesCompanion extends UpdateCompanion<ConfigStateRow> {
  final Value<String> projectId;
  final Value<String> versionToken;
  final Value<int> rowid;
  const ConfigStatesCompanion({
    this.projectId = const Value.absent(),
    this.versionToken = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConfigStatesCompanion.insert({
    required String projectId,
    required String versionToken,
    this.rowid = const Value.absent(),
  }) : projectId = Value(projectId),
       versionToken = Value(versionToken);
  static Insertable<ConfigStateRow> custom({
    Expression<String>? projectId,
    Expression<String>? versionToken,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (projectId != null) 'project_id': projectId,
      if (versionToken != null) 'version_token': versionToken,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConfigStatesCompanion copyWith({
    Value<String>? projectId,
    Value<String>? versionToken,
    Value<int>? rowid,
  }) {
    return ConfigStatesCompanion(
      projectId: projectId ?? this.projectId,
      versionToken: versionToken ?? this.versionToken,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (versionToken.present) {
      map['version_token'] = Variable<String>(versionToken.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfigStatesCompanion(')
          ..write('projectId: $projectId, ')
          ..write('versionToken: $versionToken, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuthSessionsTable extends AuthSessions
    with TableInfo<$AuthSessionsTable, AuthSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuthSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cookieMeta = const VerificationMeta('cookie');
  @override
  late final GeneratedColumn<String> cookie = GeneratedColumn<String>(
    'cookie',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, personId, email, name, cookie];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'auth_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuthSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cookie')) {
      context.handle(
        _cookieMeta,
        cookie.isAcceptableOrUnknown(data['cookie']!, _cookieMeta),
      );
    } else if (isInserting) {
      context.missing(_cookieMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuthSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuthSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      cookie: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cookie'],
      )!,
    );
  }

  @override
  $AuthSessionsTable createAlias(String alias) {
    return $AuthSessionsTable(attachedDatabase, alias);
  }
}

class AuthSessionRow extends DataClass implements Insertable<AuthSessionRow> {
  /// The fixed key of the single persisted sign-in.
  final String id;
  final String personId;
  final String email;
  final String name;
  final String cookie;
  const AuthSessionRow({
    required this.id,
    required this.personId,
    required this.email,
    required this.name,
    required this.cookie,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['person_id'] = Variable<String>(personId);
    map['email'] = Variable<String>(email);
    map['name'] = Variable<String>(name);
    map['cookie'] = Variable<String>(cookie);
    return map;
  }

  AuthSessionsCompanion toCompanion(bool nullToAbsent) {
    return AuthSessionsCompanion(
      id: Value(id),
      personId: Value(personId),
      email: Value(email),
      name: Value(name),
      cookie: Value(cookie),
    );
  }

  factory AuthSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuthSessionRow(
      id: serializer.fromJson<String>(json['id']),
      personId: serializer.fromJson<String>(json['personId']),
      email: serializer.fromJson<String>(json['email']),
      name: serializer.fromJson<String>(json['name']),
      cookie: serializer.fromJson<String>(json['cookie']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'personId': serializer.toJson<String>(personId),
      'email': serializer.toJson<String>(email),
      'name': serializer.toJson<String>(name),
      'cookie': serializer.toJson<String>(cookie),
    };
  }

  AuthSessionRow copyWith({
    String? id,
    String? personId,
    String? email,
    String? name,
    String? cookie,
  }) => AuthSessionRow(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    email: email ?? this.email,
    name: name ?? this.name,
    cookie: cookie ?? this.cookie,
  );
  AuthSessionRow copyWithCompanion(AuthSessionsCompanion data) {
    return AuthSessionRow(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      email: data.email.present ? data.email.value : this.email,
      name: data.name.present ? data.name.value : this.name,
      cookie: data.cookie.present ? data.cookie.value : this.cookie,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuthSessionRow(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('email: $email, ')
          ..write('name: $name, ')
          ..write('cookie: $cookie')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, personId, email, name, cookie);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthSessionRow &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.email == this.email &&
          other.name == this.name &&
          other.cookie == this.cookie);
}

class AuthSessionsCompanion extends UpdateCompanion<AuthSessionRow> {
  final Value<String> id;
  final Value<String> personId;
  final Value<String> email;
  final Value<String> name;
  final Value<String> cookie;
  final Value<int> rowid;
  const AuthSessionsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.email = const Value.absent(),
    this.name = const Value.absent(),
    this.cookie = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuthSessionsCompanion.insert({
    required String id,
    required String personId,
    required String email,
    required String name,
    required String cookie,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       personId = Value(personId),
       email = Value(email),
       name = Value(name),
       cookie = Value(cookie);
  static Insertable<AuthSessionRow> custom({
    Expression<String>? id,
    Expression<String>? personId,
    Expression<String>? email,
    Expression<String>? name,
    Expression<String>? cookie,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (cookie != null) 'cookie': cookie,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuthSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? personId,
    Value<String>? email,
    Value<String>? name,
    Value<String>? cookie,
    Value<int>? rowid,
  }) {
    return AuthSessionsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      email: email ?? this.email,
      name: name ?? this.name,
      cookie: cookie ?? this.cookie,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cookie.present) {
      map['cookie'] = Variable<String>(cookie.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuthSessionsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('email: $email, ')
          ..write('name: $name, ')
          ..write('cookie: $cookie, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxEntriesTable extends OutboxEntries
    with TableInfo<$OutboxEntriesTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES visits (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncState>($OutboxEntriesTable.$convertersyncState);
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [visitId, syncState, queuedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_queuedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {visitId};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      syncState: $OutboxEntriesTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
    );
  }

  @override
  $OutboxEntriesTable createAlias(String alias) {
    return $OutboxEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final String visitId;
  final SyncState syncState;
  final DateTime queuedAt;
  const OutboxRow({
    required this.visitId,
    required this.syncState,
    required this.queuedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['visit_id'] = Variable<String>(visitId);
    {
      map['sync_state'] = Variable<String>(
        $OutboxEntriesTable.$convertersyncState.toSql(syncState),
      );
    }
    map['queued_at'] = Variable<DateTime>(queuedAt);
    return map;
  }

  OutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboxEntriesCompanion(
      visitId: Value(visitId),
      syncState: Value(syncState),
      queuedAt: Value(queuedAt),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      visitId: serializer.fromJson<String>(json['visitId']),
      syncState: $OutboxEntriesTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'visitId': serializer.toJson<String>(visitId),
      'syncState': serializer.toJson<String>(
        $OutboxEntriesTable.$convertersyncState.toJson(syncState),
      ),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
    };
  }

  OutboxRow copyWith({
    String? visitId,
    SyncState? syncState,
    DateTime? queuedAt,
  }) => OutboxRow(
    visitId: visitId ?? this.visitId,
    syncState: syncState ?? this.syncState,
    queuedAt: queuedAt ?? this.queuedAt,
  );
  OutboxRow copyWithCompanion(OutboxEntriesCompanion data) {
    return OutboxRow(
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('visitId: $visitId, ')
          ..write('syncState: $syncState, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(visitId, syncState, queuedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.visitId == this.visitId &&
          other.syncState == this.syncState &&
          other.queuedAt == this.queuedAt);
}

class OutboxEntriesCompanion extends UpdateCompanion<OutboxRow> {
  final Value<String> visitId;
  final Value<SyncState> syncState;
  final Value<DateTime> queuedAt;
  final Value<int> rowid;
  const OutboxEntriesCompanion({
    this.visitId = const Value.absent(),
    this.syncState = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxEntriesCompanion.insert({
    required String visitId,
    required SyncState syncState,
    required DateTime queuedAt,
    this.rowid = const Value.absent(),
  }) : visitId = Value(visitId),
       syncState = Value(syncState),
       queuedAt = Value(queuedAt);
  static Insertable<OutboxRow> custom({
    Expression<String>? visitId,
    Expression<String>? syncState,
    Expression<DateTime>? queuedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (visitId != null) 'visit_id': visitId,
      if (syncState != null) 'sync_state': syncState,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxEntriesCompanion copyWith({
    Value<String>? visitId,
    Value<SyncState>? syncState,
    Value<DateTime>? queuedAt,
    Value<int>? rowid,
  }) {
    return OutboxEntriesCompanion(
      visitId: visitId ?? this.visitId,
      syncState: syncState ?? this.syncState,
      queuedAt: queuedAt ?? this.queuedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $OutboxEntriesTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntriesCompanion(')
          ..write('visitId: $visitId, ')
          ..write('syncState: $syncState, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SitesTable sites = $SitesTable(this);
  late final $VisitsTable visits = $VisitsTable(this);
  late final $DetectionsTable detections = $DetectionsTable(this);
  late final $EvidencesTable evidences = $EvidencesTable(this);
  late final $DeterminationsTable determinations = $DeterminationsTable(this);
  late final $MeasurementsTable measurements = $MeasurementsTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $ProtocolVersionsTable protocolVersions = $ProtocolVersionsTable(
    this,
  );
  late final $SurveyPeriodsTable surveyPeriods = $SurveyPeriodsTable(this);
  late final $ConfigStatesTable configStates = $ConfigStatesTable(this);
  late final $AuthSessionsTable authSessions = $AuthSessionsTable(this);
  late final $OutboxEntriesTable outboxEntries = $OutboxEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sites,
    visits,
    detections,
    evidences,
    determinations,
    measurements,
    projects,
    protocolVersions,
    surveyPeriods,
    configStates,
    authSessions,
    outboxEntries,
  ];
}

typedef $$SitesTableCreateCompanionBuilder = SitesCompanion Function({
  required String id,
  required String projectId,
  Value<String?> name,
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
  Value<String?> name,
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

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
                Value<String?> name = const Value.absent(),
                Value<String> geometry = const Value.absent(),
                Value<SiteOrigin> origin = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> locationProvenance = const Value.absent(),
                Value<String?> covariates = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SitesCompanion(
                id: id,
                projectId: projectId,
                name: name,
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
                Value<String?> name = const Value.absent(),
                required String geometry,
                required SiteOrigin origin,
                required DateTime createdAt,
                Value<String?> locationProvenance = const Value.absent(),
                Value<String?> covariates = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SitesCompanion.insert(
                id: id,
                projectId: projectId,
                name: name,
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
typedef $$VisitsTableCreateCompanionBuilder = VisitsCompanion Function({
  required String id,
  required String siteId,
  Value<String?> surveyPeriodId,
  Value<String?> protocolVersionId,
  required VisitState state,
  required DateTime effortStartedAt,
  Value<DateTime?> effortEndedAt,
  Value<String?> effortObservers,
  Value<int> rowid,
});
typedef $$VisitsTableUpdateCompanionBuilder = VisitsCompanion Function({
  Value<String> id,
  Value<String> siteId,
  Value<String?> surveyPeriodId,
  Value<String?> protocolVersionId,
  Value<VisitState> state,
  Value<DateTime> effortStartedAt,
  Value<DateTime?> effortEndedAt,
  Value<String?> effortObservers,
  Value<int> rowid,
});

final class $$VisitsTableReferences
    extends BaseReferences<_$AppDatabase, $VisitsTable, VisitRow> {
  $$VisitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DetectionsTable, List<DetectionRow>>
  _detectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.detections,
    aliasName: 'visits__id__detections__visit_id',
  );

  $$DetectionsTableProcessedTableManager get detectionsRefs {
    final manager = $$DetectionsTableTableManager(
      $_db,
      $_db.detections,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_detectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EvidencesTable, List<EvidenceRow>>
  _evidencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.evidences,
    aliasName: 'visits__id__evidences__visit_id',
  );

  $$EvidencesTableProcessedTableManager get evidencesRefs {
    final manager = $$EvidencesTableTableManager(
      $_db,
      $_db.evidences,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_evidencesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DeterminationsTable, List<DeterminationRow>>
  _determinationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.determinations,
    aliasName: 'visits__id__determinations__visit_id',
  );

  $$DeterminationsTableProcessedTableManager get determinationsRefs {
    final manager = $$DeterminationsTableTableManager(
      $_db,
      $_db.determinations,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_determinationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MeasurementsTable, List<MeasurementRow>>
  _measurementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.measurements,
    aliasName: 'visits__id__measurements__visit_id',
  );

  $$MeasurementsTableProcessedTableManager get measurementsRefs {
    final manager = $$MeasurementsTableTableManager(
      $_db,
      $_db.measurements,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_measurementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OutboxEntriesTable, List<OutboxRow>>
  _outboxEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.outboxEntries,
    aliasName: 'visits__id__outbox_entries__visit_id',
  );

  $$OutboxEntriesTableProcessedTableManager get outboxEntriesRefs {
    final manager = $$OutboxEntriesTableTableManager(
      $_db,
      $_db.outboxEntries,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_outboxEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VisitsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableFilterComposer({
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

  ColumnFilters<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surveyPeriodId => $composableBuilder(
    column: $table.surveyPeriodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get protocolVersionId => $composableBuilder(
    column: $table.protocolVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<VisitState, VisitState, String> get state =>
      $composableBuilder(
        column: $table.state,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get effortStartedAt => $composableBuilder(
    column: $table.effortStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get effortEndedAt => $composableBuilder(
    column: $table.effortEndedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get effortObservers => $composableBuilder(
    column: $table.effortObservers,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> detectionsRefs(
    Expression<bool> Function($$DetectionsTableFilterComposer f) f,
  ) {
    final $$DetectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.detections,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DetectionsTableFilterComposer(
            $db: $db,
            $table: $db.detections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> evidencesRefs(
    Expression<bool> Function($$EvidencesTableFilterComposer f) f,
  ) {
    final $$EvidencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.evidences,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidencesTableFilterComposer(
            $db: $db,
            $table: $db.evidences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> determinationsRefs(
    Expression<bool> Function($$DeterminationsTableFilterComposer f) f,
  ) {
    final $$DeterminationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.determinations,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeterminationsTableFilterComposer(
            $db: $db,
            $table: $db.determinations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> measurementsRefs(
    Expression<bool> Function($$MeasurementsTableFilterComposer f) f,
  ) {
    final $$MeasurementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.measurements,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurementsTableFilterComposer(
            $db: $db,
            $table: $db.measurements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> outboxEntriesRefs(
    Expression<bool> Function($$OutboxEntriesTableFilterComposer f) f,
  ) {
    final $$OutboxEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.outboxEntries,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutboxEntriesTableFilterComposer(
            $db: $db,
            $table: $db.outboxEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VisitsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableOrderingComposer({
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

  ColumnOrderings<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surveyPeriodId => $composableBuilder(
    column: $table.surveyPeriodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get protocolVersionId => $composableBuilder(
    column: $table.protocolVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get effortStartedAt => $composableBuilder(
    column: $table.effortStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get effortEndedAt => $composableBuilder(
    column: $table.effortEndedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effortObservers => $composableBuilder(
    column: $table.effortObservers,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VisitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<String> get surveyPeriodId => $composableBuilder(
    column: $table.surveyPeriodId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get protocolVersionId => $composableBuilder(
    column: $table.protocolVersionId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<VisitState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get effortStartedAt => $composableBuilder(
    column: $table.effortStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get effortEndedAt => $composableBuilder(
    column: $table.effortEndedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get effortObservers => $composableBuilder(
    column: $table.effortObservers,
    builder: (column) => column,
  );

  Expression<T> detectionsRefs<T extends Object>(
    Expression<T> Function($$DetectionsTableAnnotationComposer a) f,
  ) {
    final $$DetectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.detections,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DetectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.detections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> evidencesRefs<T extends Object>(
    Expression<T> Function($$EvidencesTableAnnotationComposer a) f,
  ) {
    final $$EvidencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.evidences,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidencesTableAnnotationComposer(
            $db: $db,
            $table: $db.evidences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> determinationsRefs<T extends Object>(
    Expression<T> Function($$DeterminationsTableAnnotationComposer a) f,
  ) {
    final $$DeterminationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.determinations,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeterminationsTableAnnotationComposer(
            $db: $db,
            $table: $db.determinations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> measurementsRefs<T extends Object>(
    Expression<T> Function($$MeasurementsTableAnnotationComposer a) f,
  ) {
    final $$MeasurementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.measurements,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurementsTableAnnotationComposer(
            $db: $db,
            $table: $db.measurements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> outboxEntriesRefs<T extends Object>(
    Expression<T> Function($$OutboxEntriesTableAnnotationComposer a) f,
  ) {
    final $$OutboxEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.outboxEntries,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutboxEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.outboxEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VisitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitsTable,
          VisitRow,
          $$VisitsTableFilterComposer,
          $$VisitsTableOrderingComposer,
          $$VisitsTableAnnotationComposer,
          $$VisitsTableCreateCompanionBuilder,
          $$VisitsTableUpdateCompanionBuilder,
          (VisitRow, $$VisitsTableReferences),
          VisitRow,
          PrefetchHooks Function({
            bool detectionsRefs,
            bool evidencesRefs,
            bool determinationsRefs,
            bool measurementsRefs,
            bool outboxEntriesRefs,
          })
        > {
  $$VisitsTableTableManager(_$AppDatabase db, $VisitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> siteId = const Value.absent(),
                Value<String?> surveyPeriodId = const Value.absent(),
                Value<String?> protocolVersionId = const Value.absent(),
                Value<VisitState> state = const Value.absent(),
                Value<DateTime> effortStartedAt = const Value.absent(),
                Value<DateTime?> effortEndedAt = const Value.absent(),
                Value<String?> effortObservers = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitsCompanion(
                id: id,
                siteId: siteId,
                surveyPeriodId: surveyPeriodId,
                protocolVersionId: protocolVersionId,
                state: state,
                effortStartedAt: effortStartedAt,
                effortEndedAt: effortEndedAt,
                effortObservers: effortObservers,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String siteId,
                Value<String?> surveyPeriodId = const Value.absent(),
                Value<String?> protocolVersionId = const Value.absent(),
                required VisitState state,
                required DateTime effortStartedAt,
                Value<DateTime?> effortEndedAt = const Value.absent(),
                Value<String?> effortObservers = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitsCompanion.insert(
                id: id,
                siteId: siteId,
                surveyPeriodId: surveyPeriodId,
                protocolVersionId: protocolVersionId,
                state: state,
                effortStartedAt: effortStartedAt,
                effortEndedAt: effortEndedAt,
                effortObservers: effortObservers,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VisitsTable, VisitRow>(table),
                  $$VisitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                detectionsRefs = false,
                evidencesRefs = false,
                determinationsRefs = false,
                measurementsRefs = false,
                outboxEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (detectionsRefs) db.detections,
                    if (evidencesRefs) db.evidences,
                    if (determinationsRefs) db.determinations,
                    if (measurementsRefs) db.measurements,
                    if (outboxEntriesRefs) db.outboxEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (detectionsRefs)
                        await $_getPrefetchedData<
                          VisitRow,
                          $VisitsTable,
                          DetectionRow
                        >(
                          currentTable: table,
                          referencedTable: $$VisitsTableReferences
                              ._detectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitsTableReferences(
                                db,
                                table,
                                p0,
                              ).detectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (evidencesRefs)
                        await $_getPrefetchedData<
                          VisitRow,
                          $VisitsTable,
                          EvidenceRow
                        >(
                          currentTable: table,
                          referencedTable: $$VisitsTableReferences
                              ._evidencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitsTableReferences(
                                db,
                                table,
                                p0,
                              ).evidencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (determinationsRefs)
                        await $_getPrefetchedData<
                          VisitRow,
                          $VisitsTable,
                          DeterminationRow
                        >(
                          currentTable: table,
                          referencedTable: $$VisitsTableReferences
                              ._determinationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitsTableReferences(
                                db,
                                table,
                                p0,
                              ).determinationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (measurementsRefs)
                        await $_getPrefetchedData<
                          VisitRow,
                          $VisitsTable,
                          MeasurementRow
                        >(
                          currentTable: table,
                          referencedTable: $$VisitsTableReferences
                              ._measurementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitsTableReferences(
                                db,
                                table,
                                p0,
                              ).measurementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (outboxEntriesRefs)
                        await $_getPrefetchedData<
                          VisitRow,
                          $VisitsTable,
                          OutboxRow
                        >(
                          currentTable: table,
                          referencedTable: $$VisitsTableReferences
                              ._outboxEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitsTableReferences(
                                db,
                                table,
                                p0,
                              ).outboxEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VisitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitsTable,
      VisitRow,
      $$VisitsTableFilterComposer,
      $$VisitsTableOrderingComposer,
      $$VisitsTableAnnotationComposer,
      $$VisitsTableCreateCompanionBuilder,
      $$VisitsTableUpdateCompanionBuilder,
      (VisitRow, $$VisitsTableReferences),
      VisitRow,
      PrefetchHooks Function({
        bool detectionsRefs,
        bool evidencesRefs,
        bool determinationsRefs,
        bool measurementsRefs,
        bool outboxEntriesRefs,
      })
    >;
typedef $$DetectionsTableCreateCompanionBuilder = DetectionsCompanion Function({
  required String visitId,
  required String taxonRef,
  required bool detected,
  Value<String?> method,
  Value<int?> count,
  Value<bool> opportunistic,
  Value<int> rowid,
});
typedef $$DetectionsTableUpdateCompanionBuilder = DetectionsCompanion Function({
  Value<String> visitId,
  Value<String> taxonRef,
  Value<bool> detected,
  Value<String?> method,
  Value<int?> count,
  Value<bool> opportunistic,
  Value<int> rowid,
});

final class $$DetectionsTableReferences
    extends BaseReferences<_$AppDatabase, $DetectionsTable, DetectionRow> {
  $$DetectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VisitsTable _visitIdTable(_$AppDatabase db) =>
      db.visits.createAlias('detections__visit_id__visits__id');

  $$VisitsTableProcessedTableManager get visitId {
    final $_column = $_itemColumn<String>('visit_id')!;

    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DetectionsTableFilterComposer
    extends Composer<_$AppDatabase, $DetectionsTable> {
  $$DetectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get taxonRef => $composableBuilder(
    column: $table.taxonRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get detected => $composableBuilder(
    column: $table.detected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get opportunistic => $composableBuilder(
    column: $table.opportunistic,
    builder: (column) => ColumnFilters(column),
  );

  $$VisitsTableFilterComposer get visitId {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DetectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DetectionsTable> {
  $$DetectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get taxonRef => $composableBuilder(
    column: $table.taxonRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get detected => $composableBuilder(
    column: $table.detected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get opportunistic => $composableBuilder(
    column: $table.opportunistic,
    builder: (column) => ColumnOrderings(column),
  );

  $$VisitsTableOrderingComposer get visitId {
    final $$VisitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableOrderingComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DetectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DetectionsTable> {
  $$DetectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get taxonRef =>
      $composableBuilder(column: $table.taxonRef, builder: (column) => column);

  GeneratedColumn<bool> get detected =>
      $composableBuilder(column: $table.detected, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<bool> get opportunistic => $composableBuilder(
    column: $table.opportunistic,
    builder: (column) => column,
  );

  $$VisitsTableAnnotationComposer get visitId {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DetectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DetectionsTable,
          DetectionRow,
          $$DetectionsTableFilterComposer,
          $$DetectionsTableOrderingComposer,
          $$DetectionsTableAnnotationComposer,
          $$DetectionsTableCreateCompanionBuilder,
          $$DetectionsTableUpdateCompanionBuilder,
          (DetectionRow, $$DetectionsTableReferences),
          DetectionRow,
          PrefetchHooks Function({bool visitId})
        > {
  $$DetectionsTableTableManager(_$AppDatabase db, $DetectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DetectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DetectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DetectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> visitId = const Value.absent(),
                Value<String> taxonRef = const Value.absent(),
                Value<bool> detected = const Value.absent(),
                Value<String?> method = const Value.absent(),
                Value<int?> count = const Value.absent(),
                Value<bool> opportunistic = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DetectionsCompanion(
                visitId: visitId,
                taxonRef: taxonRef,
                detected: detected,
                method: method,
                count: count,
                opportunistic: opportunistic,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String visitId,
                required String taxonRef,
                required bool detected,
                Value<String?> method = const Value.absent(),
                Value<int?> count = const Value.absent(),
                Value<bool> opportunistic = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DetectionsCompanion.insert(
                visitId: visitId,
                taxonRef: taxonRef,
                detected: detected,
                method: method,
                count: count,
                opportunistic: opportunistic,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DetectionsTable, DetectionRow>(table),
                  $$DetectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (visitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.visitId,
                        referencedTable: $$DetectionsTableReferences
                            ._visitIdTable(db),
                        referencedColumn: $$DetectionsTableReferences
                            ._visitIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DetectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DetectionsTable,
      DetectionRow,
      $$DetectionsTableFilterComposer,
      $$DetectionsTableOrderingComposer,
      $$DetectionsTableAnnotationComposer,
      $$DetectionsTableCreateCompanionBuilder,
      $$DetectionsTableUpdateCompanionBuilder,
      (DetectionRow, $$DetectionsTableReferences),
      DetectionRow,
      PrefetchHooks Function({bool visitId})
    >;
typedef $$EvidencesTableCreateCompanionBuilder = EvidencesCompanion Function({
  required String id,
  required String visitId,
  required String taxonRef,
  required EvidenceKind kind,
  required String filePath,
  required DateTime capturedAt,
  required String contentHash,
  Value<String?> storageKey,
  Value<int> rowid,
});
typedef $$EvidencesTableUpdateCompanionBuilder = EvidencesCompanion Function({
  Value<String> id,
  Value<String> visitId,
  Value<String> taxonRef,
  Value<EvidenceKind> kind,
  Value<String> filePath,
  Value<DateTime> capturedAt,
  Value<String> contentHash,
  Value<String?> storageKey,
  Value<int> rowid,
});

final class $$EvidencesTableReferences
    extends BaseReferences<_$AppDatabase, $EvidencesTable, EvidenceRow> {
  $$EvidencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VisitsTable _visitIdTable(_$AppDatabase db) =>
      db.visits.createAlias('evidences__visit_id__visits__id');

  $$VisitsTableProcessedTableManager get visitId {
    final $_column = $_itemColumn<String>('visit_id')!;

    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EvidencesTableFilterComposer
    extends Composer<_$AppDatabase, $EvidencesTable> {
  $$EvidencesTableFilterComposer({
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

  ColumnFilters<String> get taxonRef => $composableBuilder(
    column: $table.taxonRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EvidenceKind, EvidenceKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storageKey => $composableBuilder(
    column: $table.storageKey,
    builder: (column) => ColumnFilters(column),
  );

  $$VisitsTableFilterComposer get visitId {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidencesTableOrderingComposer
    extends Composer<_$AppDatabase, $EvidencesTable> {
  $$EvidencesTableOrderingComposer({
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

  ColumnOrderings<String> get taxonRef => $composableBuilder(
    column: $table.taxonRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storageKey => $composableBuilder(
    column: $table.storageKey,
    builder: (column) => ColumnOrderings(column),
  );

  $$VisitsTableOrderingComposer get visitId {
    final $$VisitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableOrderingComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EvidencesTable> {
  $$EvidencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taxonRef =>
      $composableBuilder(column: $table.taxonRef, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EvidenceKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storageKey => $composableBuilder(
    column: $table.storageKey,
    builder: (column) => column,
  );

  $$VisitsTableAnnotationComposer get visitId {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EvidencesTable,
          EvidenceRow,
          $$EvidencesTableFilterComposer,
          $$EvidencesTableOrderingComposer,
          $$EvidencesTableAnnotationComposer,
          $$EvidencesTableCreateCompanionBuilder,
          $$EvidencesTableUpdateCompanionBuilder,
          (EvidenceRow, $$EvidencesTableReferences),
          EvidenceRow,
          PrefetchHooks Function({bool visitId})
        > {
  $$EvidencesTableTableManager(_$AppDatabase db, $EvidencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EvidencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EvidencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EvidencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitId = const Value.absent(),
                Value<String> taxonRef = const Value.absent(),
                Value<EvidenceKind> kind = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<String?> storageKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EvidencesCompanion(
                id: id,
                visitId: visitId,
                taxonRef: taxonRef,
                kind: kind,
                filePath: filePath,
                capturedAt: capturedAt,
                contentHash: contentHash,
                storageKey: storageKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitId,
                required String taxonRef,
                required EvidenceKind kind,
                required String filePath,
                required DateTime capturedAt,
                required String contentHash,
                Value<String?> storageKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EvidencesCompanion.insert(
                id: id,
                visitId: visitId,
                taxonRef: taxonRef,
                kind: kind,
                filePath: filePath,
                capturedAt: capturedAt,
                contentHash: contentHash,
                storageKey: storageKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EvidencesTable, EvidenceRow>(table),
                  $$EvidencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (visitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.visitId,
                        referencedTable: $$EvidencesTableReferences
                            ._visitIdTable(db),
                        referencedColumn: $$EvidencesTableReferences
                            ._visitIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EvidencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EvidencesTable,
      EvidenceRow,
      $$EvidencesTableFilterComposer,
      $$EvidencesTableOrderingComposer,
      $$EvidencesTableAnnotationComposer,
      $$EvidencesTableCreateCompanionBuilder,
      $$EvidencesTableUpdateCompanionBuilder,
      (EvidenceRow, $$EvidencesTableReferences),
      EvidenceRow,
      PrefetchHooks Function({bool visitId})
    >;
typedef $$DeterminationsTableCreateCompanionBuilder =
    DeterminationsCompanion Function({
      required String id,
      required String visitId,
      required String taxonRef,
      required String taxon,
      Value<DeterminationQualifier?> qualifier,
      Value<String?> specimenCode,
      required String determiner,
      required DateTime date,
      Value<String?> replacesId,
      Value<int> rowid,
    });
typedef $$DeterminationsTableUpdateCompanionBuilder =
    DeterminationsCompanion Function({
      Value<String> id,
      Value<String> visitId,
      Value<String> taxonRef,
      Value<String> taxon,
      Value<DeterminationQualifier?> qualifier,
      Value<String?> specimenCode,
      Value<String> determiner,
      Value<DateTime> date,
      Value<String?> replacesId,
      Value<int> rowid,
    });

final class $$DeterminationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $DeterminationsTable, DeterminationRow> {
  $$DeterminationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VisitsTable _visitIdTable(_$AppDatabase db) =>
      db.visits.createAlias('determinations__visit_id__visits__id');

  $$VisitsTableProcessedTableManager get visitId {
    final $_column = $_itemColumn<String>('visit_id')!;

    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DeterminationsTableFilterComposer
    extends Composer<_$AppDatabase, $DeterminationsTable> {
  $$DeterminationsTableFilterComposer({
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

  ColumnFilters<String> get taxonRef => $composableBuilder(
    column: $table.taxonRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxon => $composableBuilder(
    column: $table.taxon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    DeterminationQualifier?,
    DeterminationQualifier,
    String
  >
  get qualifier => $composableBuilder(
    column: $table.qualifier,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get specimenCode => $composableBuilder(
    column: $table.specimenCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get determiner => $composableBuilder(
    column: $table.determiner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replacesId => $composableBuilder(
    column: $table.replacesId,
    builder: (column) => ColumnFilters(column),
  );

  $$VisitsTableFilterComposer get visitId {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeterminationsTableOrderingComposer
    extends Composer<_$AppDatabase, $DeterminationsTable> {
  $$DeterminationsTableOrderingComposer({
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

  ColumnOrderings<String> get taxonRef => $composableBuilder(
    column: $table.taxonRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxon => $composableBuilder(
    column: $table.taxon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualifier => $composableBuilder(
    column: $table.qualifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specimenCode => $composableBuilder(
    column: $table.specimenCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get determiner => $composableBuilder(
    column: $table.determiner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replacesId => $composableBuilder(
    column: $table.replacesId,
    builder: (column) => ColumnOrderings(column),
  );

  $$VisitsTableOrderingComposer get visitId {
    final $$VisitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableOrderingComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeterminationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeterminationsTable> {
  $$DeterminationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taxonRef =>
      $composableBuilder(column: $table.taxonRef, builder: (column) => column);

  GeneratedColumn<String> get taxon =>
      $composableBuilder(column: $table.taxon, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DeterminationQualifier?, String>
  get qualifier =>
      $composableBuilder(column: $table.qualifier, builder: (column) => column);

  GeneratedColumn<String> get specimenCode => $composableBuilder(
    column: $table.specimenCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get determiner => $composableBuilder(
    column: $table.determiner,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get replacesId => $composableBuilder(
    column: $table.replacesId,
    builder: (column) => column,
  );

  $$VisitsTableAnnotationComposer get visitId {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeterminationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeterminationsTable,
          DeterminationRow,
          $$DeterminationsTableFilterComposer,
          $$DeterminationsTableOrderingComposer,
          $$DeterminationsTableAnnotationComposer,
          $$DeterminationsTableCreateCompanionBuilder,
          $$DeterminationsTableUpdateCompanionBuilder,
          (DeterminationRow, $$DeterminationsTableReferences),
          DeterminationRow,
          PrefetchHooks Function({bool visitId})
        > {
  $$DeterminationsTableTableManager(
    _$AppDatabase db,
    $DeterminationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeterminationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeterminationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeterminationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitId = const Value.absent(),
                Value<String> taxonRef = const Value.absent(),
                Value<String> taxon = const Value.absent(),
                Value<DeterminationQualifier?> qualifier = const Value.absent(),
                Value<String?> specimenCode = const Value.absent(),
                Value<String> determiner = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> replacesId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeterminationsCompanion(
                id: id,
                visitId: visitId,
                taxonRef: taxonRef,
                taxon: taxon,
                qualifier: qualifier,
                specimenCode: specimenCode,
                determiner: determiner,
                date: date,
                replacesId: replacesId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitId,
                required String taxonRef,
                required String taxon,
                Value<DeterminationQualifier?> qualifier = const Value.absent(),
                Value<String?> specimenCode = const Value.absent(),
                required String determiner,
                required DateTime date,
                Value<String?> replacesId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeterminationsCompanion.insert(
                id: id,
                visitId: visitId,
                taxonRef: taxonRef,
                taxon: taxon,
                qualifier: qualifier,
                specimenCode: specimenCode,
                determiner: determiner,
                date: date,
                replacesId: replacesId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DeterminationsTable, DeterminationRow>(table),
                  $$DeterminationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (visitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.visitId,
                        referencedTable: $$DeterminationsTableReferences
                            ._visitIdTable(db),
                        referencedColumn: $$DeterminationsTableReferences
                            ._visitIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DeterminationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeterminationsTable,
      DeterminationRow,
      $$DeterminationsTableFilterComposer,
      $$DeterminationsTableOrderingComposer,
      $$DeterminationsTableAnnotationComposer,
      $$DeterminationsTableCreateCompanionBuilder,
      $$DeterminationsTableUpdateCompanionBuilder,
      (DeterminationRow, $$DeterminationsTableReferences),
      DeterminationRow,
      PrefetchHooks Function({bool visitId})
    >;
typedef $$MeasurementsTableCreateCompanionBuilder =
    MeasurementsCompanion Function({
      required String id,
      required String visitId,
      required String name,
      required String value,
      Value<String?> unit,
      required String provenance,
      Value<int> rowid,
    });
typedef $$MeasurementsTableUpdateCompanionBuilder =
    MeasurementsCompanion Function({
      Value<String> id,
      Value<String> visitId,
      Value<String> name,
      Value<String> value,
      Value<String?> unit,
      Value<String> provenance,
      Value<int> rowid,
    });

final class $$MeasurementsTableReferences
    extends BaseReferences<_$AppDatabase, $MeasurementsTable, MeasurementRow> {
  $$MeasurementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VisitsTable _visitIdTable(_$AppDatabase db) =>
      db.visits.createAlias('measurements__visit_id__visits__id');

  $$VisitsTableProcessedTableManager get visitId {
    final $_column = $_itemColumn<String>('visit_id')!;

    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnFilters(column),
  );

  $$VisitsTableFilterComposer get visitId {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnOrderings(column),
  );

  $$VisitsTableOrderingComposer get visitId {
    final $$VisitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableOrderingComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => column,
  );

  $$VisitsTableAnnotationComposer get visitId {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeasurementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MeasurementsTable,
          MeasurementRow,
          $$MeasurementsTableFilterComposer,
          $$MeasurementsTableOrderingComposer,
          $$MeasurementsTableAnnotationComposer,
          $$MeasurementsTableCreateCompanionBuilder,
          $$MeasurementsTableUpdateCompanionBuilder,
          (MeasurementRow, $$MeasurementsTableReferences),
          MeasurementRow,
          PrefetchHooks Function({bool visitId})
        > {
  $$MeasurementsTableTableManager(_$AppDatabase db, $MeasurementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String> provenance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeasurementsCompanion(
                id: id,
                visitId: visitId,
                name: name,
                value: value,
                unit: unit,
                provenance: provenance,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitId,
                required String name,
                required String value,
                Value<String?> unit = const Value.absent(),
                required String provenance,
                Value<int> rowid = const Value.absent(),
              }) => MeasurementsCompanion.insert(
                id: id,
                visitId: visitId,
                name: name,
                value: value,
                unit: unit,
                provenance: provenance,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MeasurementsTable, MeasurementRow>(table),
                  $$MeasurementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (visitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.visitId,
                        referencedTable: $$MeasurementsTableReferences
                            ._visitIdTable(db),
                        referencedColumn: $$MeasurementsTableReferences
                            ._visitIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MeasurementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MeasurementsTable,
      MeasurementRow,
      $$MeasurementsTableFilterComposer,
      $$MeasurementsTableOrderingComposer,
      $$MeasurementsTableAnnotationComposer,
      $$MeasurementsTableCreateCompanionBuilder,
      $$MeasurementsTableUpdateCompanionBuilder,
      (MeasurementRow, $$MeasurementsTableReferences),
      MeasurementRow,
      PrefetchHooks Function({bool visitId})
    >;
typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  required bool validationEnabled,
  required bool sensitiveTaxaObfuscation,
  Value<String?> taxonomicReferenceId,
  Value<String?> taxonomicReferenceVersion,
  Value<int> rowid,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<bool> validationEnabled,
  Value<bool> sensitiveTaxaObfuscation,
  Value<String?> taxonomicReferenceId,
  Value<String?> taxonomicReferenceVersion,
  Value<int> rowid,
});

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get validationEnabled => $composableBuilder(
    column: $table.validationEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sensitiveTaxaObfuscation => $composableBuilder(
    column: $table.sensitiveTaxaObfuscation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxonomicReferenceId => $composableBuilder(
    column: $table.taxonomicReferenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxonomicReferenceVersion => $composableBuilder(
    column: $table.taxonomicReferenceVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get validationEnabled => $composableBuilder(
    column: $table.validationEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sensitiveTaxaObfuscation => $composableBuilder(
    column: $table.sensitiveTaxaObfuscation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxonomicReferenceId => $composableBuilder(
    column: $table.taxonomicReferenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxonomicReferenceVersion => $composableBuilder(
    column: $table.taxonomicReferenceVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get validationEnabled => $composableBuilder(
    column: $table.validationEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sensitiveTaxaObfuscation => $composableBuilder(
    column: $table.sensitiveTaxaObfuscation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxonomicReferenceId => $composableBuilder(
    column: $table.taxonomicReferenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxonomicReferenceVersion => $composableBuilder(
    column: $table.taxonomicReferenceVersion,
    builder: (column) => column,
  );
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          ProjectRow,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (
            ProjectRow,
            BaseReferences<_$AppDatabase, $ProjectsTable, ProjectRow>,
          ),
          ProjectRow,
          PrefetchHooks Function()
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> validationEnabled = const Value.absent(),
                Value<bool> sensitiveTaxaObfuscation = const Value.absent(),
                Value<String?> taxonomicReferenceId = const Value.absent(),
                Value<String?> taxonomicReferenceVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                name: name,
                description: description,
                validationEnabled: validationEnabled,
                sensitiveTaxaObfuscation: sensitiveTaxaObfuscation,
                taxonomicReferenceId: taxonomicReferenceId,
                taxonomicReferenceVersion: taxonomicReferenceVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required bool validationEnabled,
                required bool sensitiveTaxaObfuscation,
                Value<String?> taxonomicReferenceId = const Value.absent(),
                Value<String?> taxonomicReferenceVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                name: name,
                description: description,
                validationEnabled: validationEnabled,
                sensitiveTaxaObfuscation: sensitiveTaxaObfuscation,
                taxonomicReferenceId: taxonomicReferenceId,
                taxonomicReferenceVersion: taxonomicReferenceVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectsTable, ProjectRow>(table),
                  BaseReferences<_$AppDatabase, $ProjectsTable, ProjectRow>(
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

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      ProjectRow,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (ProjectRow, BaseReferences<_$AppDatabase, $ProjectsTable, ProjectRow>),
      ProjectRow,
      PrefetchHooks Function()
    >;
typedef $$ProtocolVersionsTableCreateCompanionBuilder =
    ProtocolVersionsCompanion Function({
      required String id,
      required String projectId,
      required String protocolId,
      required int version,
      required String document,
      Value<DateTime?> frozenAt,
      Value<int> rowid,
    });
typedef $$ProtocolVersionsTableUpdateCompanionBuilder =
    ProtocolVersionsCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> protocolId,
      Value<int> version,
      Value<String> document,
      Value<DateTime?> frozenAt,
      Value<int> rowid,
    });

class $$ProtocolVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $ProtocolVersionsTable> {
  $$ProtocolVersionsTableFilterComposer({
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

  ColumnFilters<String> get protocolId => $composableBuilder(
    column: $table.protocolId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get document => $composableBuilder(
    column: $table.document,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get frozenAt => $composableBuilder(
    column: $table.frozenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProtocolVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProtocolVersionsTable> {
  $$ProtocolVersionsTableOrderingComposer({
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

  ColumnOrderings<String> get protocolId => $composableBuilder(
    column: $table.protocolId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get document => $composableBuilder(
    column: $table.document,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get frozenAt => $composableBuilder(
    column: $table.frozenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProtocolVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProtocolVersionsTable> {
  $$ProtocolVersionsTableAnnotationComposer({
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

  GeneratedColumn<String> get protocolId => $composableBuilder(
    column: $table.protocolId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get document =>
      $composableBuilder(column: $table.document, builder: (column) => column);

  GeneratedColumn<DateTime> get frozenAt =>
      $composableBuilder(column: $table.frozenAt, builder: (column) => column);
}

class $$ProtocolVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProtocolVersionsTable,
          ProtocolVersionRow,
          $$ProtocolVersionsTableFilterComposer,
          $$ProtocolVersionsTableOrderingComposer,
          $$ProtocolVersionsTableAnnotationComposer,
          $$ProtocolVersionsTableCreateCompanionBuilder,
          $$ProtocolVersionsTableUpdateCompanionBuilder,
          (
            ProtocolVersionRow,
            BaseReferences<
              _$AppDatabase,
              $ProtocolVersionsTable,
              ProtocolVersionRow
            >,
          ),
          ProtocolVersionRow,
          PrefetchHooks Function()
        > {
  $$ProtocolVersionsTableTableManager(
    _$AppDatabase db,
    $ProtocolVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProtocolVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProtocolVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProtocolVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> protocolId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> document = const Value.absent(),
                Value<DateTime?> frozenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProtocolVersionsCompanion(
                id: id,
                projectId: projectId,
                protocolId: protocolId,
                version: version,
                document: document,
                frozenAt: frozenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String protocolId,
                required int version,
                required String document,
                Value<DateTime?> frozenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProtocolVersionsCompanion.insert(
                id: id,
                projectId: projectId,
                protocolId: protocolId,
                version: version,
                document: document,
                frozenAt: frozenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProtocolVersionsTable, ProtocolVersionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ProtocolVersionsTable,
                    ProtocolVersionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProtocolVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProtocolVersionsTable,
      ProtocolVersionRow,
      $$ProtocolVersionsTableFilterComposer,
      $$ProtocolVersionsTableOrderingComposer,
      $$ProtocolVersionsTableAnnotationComposer,
      $$ProtocolVersionsTableCreateCompanionBuilder,
      $$ProtocolVersionsTableUpdateCompanionBuilder,
      (
        ProtocolVersionRow,
        BaseReferences<
          _$AppDatabase,
          $ProtocolVersionsTable,
          ProtocolVersionRow
        >,
      ),
      ProtocolVersionRow,
      PrefetchHooks Function()
    >;
typedef $$SurveyPeriodsTableCreateCompanionBuilder =
    SurveyPeriodsCompanion Function({
      required String id,
      required String projectId,
      required String name,
      required String startDate,
      required String endDate,
      Value<int> rowid,
    });
typedef $$SurveyPeriodsTableUpdateCompanionBuilder =
    SurveyPeriodsCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> name,
      Value<String> startDate,
      Value<String> endDate,
      Value<int> rowid,
    });

class $$SurveyPeriodsTableFilterComposer
    extends Composer<_$AppDatabase, $SurveyPeriodsTable> {
  $$SurveyPeriodsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SurveyPeriodsTableOrderingComposer
    extends Composer<_$AppDatabase, $SurveyPeriodsTable> {
  $$SurveyPeriodsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SurveyPeriodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurveyPeriodsTable> {
  $$SurveyPeriodsTableAnnotationComposer({
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);
}

class $$SurveyPeriodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SurveyPeriodsTable,
          SurveyPeriodRow,
          $$SurveyPeriodsTableFilterComposer,
          $$SurveyPeriodsTableOrderingComposer,
          $$SurveyPeriodsTableAnnotationComposer,
          $$SurveyPeriodsTableCreateCompanionBuilder,
          $$SurveyPeriodsTableUpdateCompanionBuilder,
          (
            SurveyPeriodRow,
            BaseReferences<_$AppDatabase, $SurveyPeriodsTable, SurveyPeriodRow>,
          ),
          SurveyPeriodRow,
          PrefetchHooks Function()
        > {
  $$SurveyPeriodsTableTableManager(_$AppDatabase db, $SurveyPeriodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurveyPeriodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurveyPeriodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurveyPeriodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> endDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SurveyPeriodsCompanion(
                id: id,
                projectId: projectId,
                name: name,
                startDate: startDate,
                endDate: endDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String name,
                required String startDate,
                required String endDate,
                Value<int> rowid = const Value.absent(),
              }) => SurveyPeriodsCompanion.insert(
                id: id,
                projectId: projectId,
                name: name,
                startDate: startDate,
                endDate: endDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SurveyPeriodsTable, SurveyPeriodRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SurveyPeriodsTable,
                    SurveyPeriodRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SurveyPeriodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SurveyPeriodsTable,
      SurveyPeriodRow,
      $$SurveyPeriodsTableFilterComposer,
      $$SurveyPeriodsTableOrderingComposer,
      $$SurveyPeriodsTableAnnotationComposer,
      $$SurveyPeriodsTableCreateCompanionBuilder,
      $$SurveyPeriodsTableUpdateCompanionBuilder,
      (
        SurveyPeriodRow,
        BaseReferences<_$AppDatabase, $SurveyPeriodsTable, SurveyPeriodRow>,
      ),
      SurveyPeriodRow,
      PrefetchHooks Function()
    >;
typedef $$ConfigStatesTableCreateCompanionBuilder =
    ConfigStatesCompanion Function({
      required String projectId,
      required String versionToken,
      Value<int> rowid,
    });
typedef $$ConfigStatesTableUpdateCompanionBuilder =
    ConfigStatesCompanion Function({
      Value<String> projectId,
      Value<String> versionToken,
      Value<int> rowid,
    });

class $$ConfigStatesTableFilterComposer
    extends Composer<_$AppDatabase, $ConfigStatesTable> {
  $$ConfigStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get versionToken => $composableBuilder(
    column: $table.versionToken,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConfigStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfigStatesTable> {
  $$ConfigStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get versionToken => $composableBuilder(
    column: $table.versionToken,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConfigStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfigStatesTable> {
  $$ConfigStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get versionToken => $composableBuilder(
    column: $table.versionToken,
    builder: (column) => column,
  );
}

class $$ConfigStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfigStatesTable,
          ConfigStateRow,
          $$ConfigStatesTableFilterComposer,
          $$ConfigStatesTableOrderingComposer,
          $$ConfigStatesTableAnnotationComposer,
          $$ConfigStatesTableCreateCompanionBuilder,
          $$ConfigStatesTableUpdateCompanionBuilder,
          (
            ConfigStateRow,
            BaseReferences<_$AppDatabase, $ConfigStatesTable, ConfigStateRow>,
          ),
          ConfigStateRow,
          PrefetchHooks Function()
        > {
  $$ConfigStatesTableTableManager(_$AppDatabase db, $ConfigStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfigStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfigStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfigStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> projectId = const Value.absent(),
                Value<String> versionToken = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConfigStatesCompanion(
                projectId: projectId,
                versionToken: versionToken,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String projectId,
                required String versionToken,
                Value<int> rowid = const Value.absent(),
              }) => ConfigStatesCompanion.insert(
                projectId: projectId,
                versionToken: versionToken,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConfigStatesTable, ConfigStateRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ConfigStatesTable,
                    ConfigStateRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConfigStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConfigStatesTable,
      ConfigStateRow,
      $$ConfigStatesTableFilterComposer,
      $$ConfigStatesTableOrderingComposer,
      $$ConfigStatesTableAnnotationComposer,
      $$ConfigStatesTableCreateCompanionBuilder,
      $$ConfigStatesTableUpdateCompanionBuilder,
      (
        ConfigStateRow,
        BaseReferences<_$AppDatabase, $ConfigStatesTable, ConfigStateRow>,
      ),
      ConfigStateRow,
      PrefetchHooks Function()
    >;
typedef $$AuthSessionsTableCreateCompanionBuilder =
    AuthSessionsCompanion Function({
      required String id,
      required String personId,
      required String email,
      required String name,
      required String cookie,
      Value<int> rowid,
    });
typedef $$AuthSessionsTableUpdateCompanionBuilder =
    AuthSessionsCompanion Function({
      Value<String> id,
      Value<String> personId,
      Value<String> email,
      Value<String> name,
      Value<String> cookie,
      Value<int> rowid,
    });

class $$AuthSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $AuthSessionsTable> {
  $$AuthSessionsTableFilterComposer({
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

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cookie => $composableBuilder(
    column: $table.cookie,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuthSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuthSessionsTable> {
  $$AuthSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cookie => $composableBuilder(
    column: $table.cookie,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuthSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuthSessionsTable> {
  $$AuthSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get cookie =>
      $composableBuilder(column: $table.cookie, builder: (column) => column);
}

class $$AuthSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuthSessionsTable,
          AuthSessionRow,
          $$AuthSessionsTableFilterComposer,
          $$AuthSessionsTableOrderingComposer,
          $$AuthSessionsTableAnnotationComposer,
          $$AuthSessionsTableCreateCompanionBuilder,
          $$AuthSessionsTableUpdateCompanionBuilder,
          (
            AuthSessionRow,
            BaseReferences<_$AppDatabase, $AuthSessionsTable, AuthSessionRow>,
          ),
          AuthSessionRow,
          PrefetchHooks Function()
        > {
  $$AuthSessionsTableTableManager(_$AppDatabase db, $AuthSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuthSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuthSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuthSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> cookie = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuthSessionsCompanion(
                id: id,
                personId: personId,
                email: email,
                name: name,
                cookie: cookie,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String personId,
                required String email,
                required String name,
                required String cookie,
                Value<int> rowid = const Value.absent(),
              }) => AuthSessionsCompanion.insert(
                id: id,
                personId: personId,
                email: email,
                name: name,
                cookie: cookie,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AuthSessionsTable, AuthSessionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AuthSessionsTable,
                    AuthSessionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuthSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuthSessionsTable,
      AuthSessionRow,
      $$AuthSessionsTableFilterComposer,
      $$AuthSessionsTableOrderingComposer,
      $$AuthSessionsTableAnnotationComposer,
      $$AuthSessionsTableCreateCompanionBuilder,
      $$AuthSessionsTableUpdateCompanionBuilder,
      (
        AuthSessionRow,
        BaseReferences<_$AppDatabase, $AuthSessionsTable, AuthSessionRow>,
      ),
      AuthSessionRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxEntriesTableCreateCompanionBuilder =
    OutboxEntriesCompanion Function({
      required String visitId,
      required SyncState syncState,
      required DateTime queuedAt,
      Value<int> rowid,
    });
typedef $$OutboxEntriesTableUpdateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<String> visitId,
      Value<SyncState> syncState,
      Value<DateTime> queuedAt,
      Value<int> rowid,
    });

final class $$OutboxEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $OutboxEntriesTable, OutboxRow> {
  $$OutboxEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VisitsTable _visitIdTable(_$AppDatabase db) =>
      db.visits.createAlias('outbox_entries__visit_id__visits__id');

  $$VisitsTableProcessedTableManager get visitId {
    final $_column = $_itemColumn<String>('visit_id')!;

    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OutboxEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VisitsTableFilterComposer get visitId {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutboxEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VisitsTableOrderingComposer get visitId {
    final $$VisitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableOrderingComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutboxEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);

  $$VisitsTableAnnotationComposer get visitId {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutboxEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxEntriesTable,
          OutboxRow,
          $$OutboxEntriesTableFilterComposer,
          $$OutboxEntriesTableOrderingComposer,
          $$OutboxEntriesTableAnnotationComposer,
          $$OutboxEntriesTableCreateCompanionBuilder,
          $$OutboxEntriesTableUpdateCompanionBuilder,
          (OutboxRow, $$OutboxEntriesTableReferences),
          OutboxRow,
          PrefetchHooks Function({bool visitId})
        > {
  $$OutboxEntriesTableTableManager(_$AppDatabase db, $OutboxEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> visitId = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxEntriesCompanion(
                visitId: visitId,
                syncState: syncState,
                queuedAt: queuedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String visitId,
                required SyncState syncState,
                required DateTime queuedAt,
                Value<int> rowid = const Value.absent(),
              }) => OutboxEntriesCompanion.insert(
                visitId: visitId,
                syncState: syncState,
                queuedAt: queuedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxEntriesTable, OutboxRow>(table),
                  $$OutboxEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (visitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.visitId,
                        referencedTable: $$OutboxEntriesTableReferences
                            ._visitIdTable(db),
                        referencedColumn: $$OutboxEntriesTableReferences
                            ._visitIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OutboxEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxEntriesTable,
      OutboxRow,
      $$OutboxEntriesTableFilterComposer,
      $$OutboxEntriesTableOrderingComposer,
      $$OutboxEntriesTableAnnotationComposer,
      $$OutboxEntriesTableCreateCompanionBuilder,
      $$OutboxEntriesTableUpdateCompanionBuilder,
      (OutboxRow, $$OutboxEntriesTableReferences),
      OutboxRow,
      PrefetchHooks Function({bool visitId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db, _db.sites);
  $$VisitsTableTableManager get visits =>
      $$VisitsTableTableManager(_db, _db.visits);
  $$DetectionsTableTableManager get detections =>
      $$DetectionsTableTableManager(_db, _db.detections);
  $$EvidencesTableTableManager get evidences =>
      $$EvidencesTableTableManager(_db, _db.evidences);
  $$DeterminationsTableTableManager get determinations =>
      $$DeterminationsTableTableManager(_db, _db.determinations);
  $$MeasurementsTableTableManager get measurements =>
      $$MeasurementsTableTableManager(_db, _db.measurements);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$ProtocolVersionsTableTableManager get protocolVersions =>
      $$ProtocolVersionsTableTableManager(_db, _db.protocolVersions);
  $$SurveyPeriodsTableTableManager get surveyPeriods =>
      $$SurveyPeriodsTableTableManager(_db, _db.surveyPeriods);
  $$ConfigStatesTableTableManager get configStates =>
      $$ConfigStatesTableTableManager(_db, _db.configStates);
  $$AuthSessionsTableTableManager get authSessions =>
      $$AuthSessionsTableTableManager(_db, _db.authSessions);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db, _db.outboxEntries);
}
