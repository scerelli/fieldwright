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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protocolVersionIdMeta = const VerificationMeta(
    'protocolVersionId',
  );
  @override
  late final GeneratedColumn<String> protocolVersionId =
      GeneratedColumn<String>(
        'protocol_version_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    siteId,
    surveyPeriodId,
    protocolVersionId,
    state,
    effortStartedAt,
    effortEndedAt,
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
    } else if (isInserting) {
      context.missing(_surveyPeriodIdMeta);
    }
    if (data.containsKey('protocol_version_id')) {
      context.handle(
        _protocolVersionIdMeta,
        protocolVersionId.isAcceptableOrUnknown(
          data['protocol_version_id']!,
          _protocolVersionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_protocolVersionIdMeta);
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
      )!,
      protocolVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protocol_version_id'],
      )!,
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
  final String surveyPeriodId;
  final String protocolVersionId;
  final VisitState state;
  final DateTime effortStartedAt;
  final DateTime? effortEndedAt;
  const VisitRow({
    required this.id,
    required this.siteId,
    required this.surveyPeriodId,
    required this.protocolVersionId,
    required this.state,
    required this.effortStartedAt,
    this.effortEndedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['site_id'] = Variable<String>(siteId);
    map['survey_period_id'] = Variable<String>(surveyPeriodId);
    map['protocol_version_id'] = Variable<String>(protocolVersionId);
    {
      map['state'] = Variable<String>(
        $VisitsTable.$converterstate.toSql(state),
      );
    }
    map['effort_started_at'] = Variable<DateTime>(effortStartedAt);
    if (!nullToAbsent || effortEndedAt != null) {
      map['effort_ended_at'] = Variable<DateTime>(effortEndedAt);
    }
    return map;
  }

  VisitsCompanion toCompanion(bool nullToAbsent) {
    return VisitsCompanion(
      id: Value(id),
      siteId: Value(siteId),
      surveyPeriodId: Value(surveyPeriodId),
      protocolVersionId: Value(protocolVersionId),
      state: Value(state),
      effortStartedAt: Value(effortStartedAt),
      effortEndedAt: effortEndedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(effortEndedAt),
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
      surveyPeriodId: serializer.fromJson<String>(json['surveyPeriodId']),
      protocolVersionId: serializer.fromJson<String>(json['protocolVersionId']),
      state: $VisitsTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      effortStartedAt: serializer.fromJson<DateTime>(json['effortStartedAt']),
      effortEndedAt: serializer.fromJson<DateTime?>(json['effortEndedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'siteId': serializer.toJson<String>(siteId),
      'surveyPeriodId': serializer.toJson<String>(surveyPeriodId),
      'protocolVersionId': serializer.toJson<String>(protocolVersionId),
      'state': serializer.toJson<String>(
        $VisitsTable.$converterstate.toJson(state),
      ),
      'effortStartedAt': serializer.toJson<DateTime>(effortStartedAt),
      'effortEndedAt': serializer.toJson<DateTime?>(effortEndedAt),
    };
  }

  VisitRow copyWith({
    String? id,
    String? siteId,
    String? surveyPeriodId,
    String? protocolVersionId,
    VisitState? state,
    DateTime? effortStartedAt,
    Value<DateTime?> effortEndedAt = const Value.absent(),
  }) => VisitRow(
    id: id ?? this.id,
    siteId: siteId ?? this.siteId,
    surveyPeriodId: surveyPeriodId ?? this.surveyPeriodId,
    protocolVersionId: protocolVersionId ?? this.protocolVersionId,
    state: state ?? this.state,
    effortStartedAt: effortStartedAt ?? this.effortStartedAt,
    effortEndedAt: effortEndedAt.present
        ? effortEndedAt.value
        : this.effortEndedAt,
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
          ..write('effortEndedAt: $effortEndedAt')
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
          other.effortEndedAt == this.effortEndedAt);
}

class VisitsCompanion extends UpdateCompanion<VisitRow> {
  final Value<String> id;
  final Value<String> siteId;
  final Value<String> surveyPeriodId;
  final Value<String> protocolVersionId;
  final Value<VisitState> state;
  final Value<DateTime> effortStartedAt;
  final Value<DateTime?> effortEndedAt;
  final Value<int> rowid;
  const VisitsCompanion({
    this.id = const Value.absent(),
    this.siteId = const Value.absent(),
    this.surveyPeriodId = const Value.absent(),
    this.protocolVersionId = const Value.absent(),
    this.state = const Value.absent(),
    this.effortStartedAt = const Value.absent(),
    this.effortEndedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitsCompanion.insert({
    required String id,
    required String siteId,
    required String surveyPeriodId,
    required String protocolVersionId,
    required VisitState state,
    required DateTime effortStartedAt,
    this.effortEndedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       siteId = Value(siteId),
       surveyPeriodId = Value(surveyPeriodId),
       protocolVersionId = Value(protocolVersionId),
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
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitsCompanion copyWith({
    Value<String>? id,
    Value<String>? siteId,
    Value<String>? surveyPeriodId,
    Value<String>? protocolVersionId,
    Value<VisitState>? state,
    Value<DateTime>? effortStartedAt,
    Value<DateTime?>? effortEndedAt,
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [sites, visits];
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
typedef $$VisitsTableCreateCompanionBuilder = VisitsCompanion Function({
  required String id,
  required String siteId,
  required String surveyPeriodId,
  required String protocolVersionId,
  required VisitState state,
  required DateTime effortStartedAt,
  Value<DateTime?> effortEndedAt,
  Value<int> rowid,
});
typedef $$VisitsTableUpdateCompanionBuilder = VisitsCompanion Function({
  Value<String> id,
  Value<String> siteId,
  Value<String> surveyPeriodId,
  Value<String> protocolVersionId,
  Value<VisitState> state,
  Value<DateTime> effortStartedAt,
  Value<DateTime?> effortEndedAt,
  Value<int> rowid,
});

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
          (VisitRow, BaseReferences<_$AppDatabase, $VisitsTable, VisitRow>),
          VisitRow,
          PrefetchHooks Function()
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
                Value<String> surveyPeriodId = const Value.absent(),
                Value<String> protocolVersionId = const Value.absent(),
                Value<VisitState> state = const Value.absent(),
                Value<DateTime> effortStartedAt = const Value.absent(),
                Value<DateTime?> effortEndedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitsCompanion(
                id: id,
                siteId: siteId,
                surveyPeriodId: surveyPeriodId,
                protocolVersionId: protocolVersionId,
                state: state,
                effortStartedAt: effortStartedAt,
                effortEndedAt: effortEndedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String siteId,
                required String surveyPeriodId,
                required String protocolVersionId,
                required VisitState state,
                required DateTime effortStartedAt,
                Value<DateTime?> effortEndedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitsCompanion.insert(
                id: id,
                siteId: siteId,
                surveyPeriodId: surveyPeriodId,
                protocolVersionId: protocolVersionId,
                state: state,
                effortStartedAt: effortStartedAt,
                effortEndedAt: effortEndedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VisitsTable, VisitRow>(table),
                  BaseReferences<_$AppDatabase, $VisitsTable, VisitRow>(
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
      (VisitRow, BaseReferences<_$AppDatabase, $VisitsTable, VisitRow>),
      VisitRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db, _db.sites);
  $$VisitsTableTableManager get visits =>
      $$VisitsTableTableManager(_db, _db.visits);
}
