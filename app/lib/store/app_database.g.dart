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
  final bool opportunistic;
  const DetectionRow({
    required this.visitId,
    required this.taxonRef,
    required this.detected,
    required this.opportunistic,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['visit_id'] = Variable<String>(visitId);
    map['taxon_ref'] = Variable<String>(taxonRef);
    map['detected'] = Variable<bool>(detected);
    map['opportunistic'] = Variable<bool>(opportunistic);
    return map;
  }

  DetectionsCompanion toCompanion(bool nullToAbsent) {
    return DetectionsCompanion(
      visitId: Value(visitId),
      taxonRef: Value(taxonRef),
      detected: Value(detected),
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
      'opportunistic': serializer.toJson<bool>(opportunistic),
    };
  }

  DetectionRow copyWith({
    String? visitId,
    String? taxonRef,
    bool? detected,
    bool? opportunistic,
  }) => DetectionRow(
    visitId: visitId ?? this.visitId,
    taxonRef: taxonRef ?? this.taxonRef,
    detected: detected ?? this.detected,
    opportunistic: opportunistic ?? this.opportunistic,
  );
  DetectionRow copyWithCompanion(DetectionsCompanion data) {
    return DetectionRow(
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      taxonRef: data.taxonRef.present ? data.taxonRef.value : this.taxonRef,
      detected: data.detected.present ? data.detected.value : this.detected,
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
          ..write('opportunistic: $opportunistic')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(visitId, taxonRef, detected, opportunistic);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DetectionRow &&
          other.visitId == this.visitId &&
          other.taxonRef == this.taxonRef &&
          other.detected == this.detected &&
          other.opportunistic == this.opportunistic);
}

class DetectionsCompanion extends UpdateCompanion<DetectionRow> {
  final Value<String> visitId;
  final Value<String> taxonRef;
  final Value<bool> detected;
  final Value<bool> opportunistic;
  final Value<int> rowid;
  const DetectionsCompanion({
    this.visitId = const Value.absent(),
    this.taxonRef = const Value.absent(),
    this.detected = const Value.absent(),
    this.opportunistic = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DetectionsCompanion.insert({
    required String visitId,
    required String taxonRef,
    required bool detected,
    this.opportunistic = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : visitId = Value(visitId),
       taxonRef = Value(taxonRef),
       detected = Value(detected);
  static Insertable<DetectionRow> custom({
    Expression<String>? visitId,
    Expression<String>? taxonRef,
    Expression<bool>? detected,
    Expression<bool>? opportunistic,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (visitId != null) 'visit_id': visitId,
      if (taxonRef != null) 'taxon_ref': taxonRef,
      if (detected != null) 'detected': detected,
      if (opportunistic != null) 'opportunistic': opportunistic,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DetectionsCompanion copyWith({
    Value<String>? visitId,
    Value<String>? taxonRef,
    Value<bool>? detected,
    Value<bool>? opportunistic,
    Value<int>? rowid,
  }) {
    return DetectionsCompanion(
      visitId: visitId ?? this.visitId,
      taxonRef: taxonRef ?? this.taxonRef,
      detected: detected ?? this.detected,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitId,
    taxonRef,
    kind,
    filePath,
    capturedAt,
    contentHash,
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
  const EvidenceRow({
    required this.id,
    required this.visitId,
    required this.taxonRef,
    required this.kind,
    required this.filePath,
    required this.capturedAt,
    required this.contentHash,
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
  }) => EvidenceRow(
    id: id ?? this.id,
    visitId: visitId ?? this.visitId,
    taxonRef: taxonRef ?? this.taxonRef,
    kind: kind ?? this.kind,
    filePath: filePath ?? this.filePath,
    capturedAt: capturedAt ?? this.capturedAt,
    contentHash: contentHash ?? this.contentHash,
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
          ..write('contentHash: $contentHash')
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
          other.contentHash == this.contentHash);
}

class EvidencesCompanion extends UpdateCompanion<EvidenceRow> {
  final Value<String> id;
  final Value<String> visitId;
  final Value<String> taxonRef;
  final Value<EvidenceKind> kind;
  final Value<String> filePath;
  final Value<DateTime> capturedAt;
  final Value<String> contentHash;
  final Value<int> rowid;
  const EvidencesCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.taxonRef = const Value.absent(),
    this.kind = const Value.absent(),
    this.filePath = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.contentHash = const Value.absent(),
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sites,
    visits,
    detections,
    evidences,
  ];
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
          PrefetchHooks Function({bool detectionsRefs, bool evidencesRefs})
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
                  $$VisitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({detectionsRefs = false, evidencesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (detectionsRefs) db.detections,
                    if (evidencesRefs) db.evidences,
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
      PrefetchHooks Function({bool detectionsRefs, bool evidencesRefs})
    >;
typedef $$DetectionsTableCreateCompanionBuilder = DetectionsCompanion Function({
  required String visitId,
  required String taxonRef,
  required bool detected,
  Value<bool> opportunistic,
  Value<int> rowid,
});
typedef $$DetectionsTableUpdateCompanionBuilder = DetectionsCompanion Function({
  Value<String> visitId,
  Value<String> taxonRef,
  Value<bool> detected,
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
                Value<bool> opportunistic = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DetectionsCompanion(
                visitId: visitId,
                taxonRef: taxonRef,
                detected: detected,
                opportunistic: opportunistic,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String visitId,
                required String taxonRef,
                required bool detected,
                Value<bool> opportunistic = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DetectionsCompanion.insert(
                visitId: visitId,
                taxonRef: taxonRef,
                detected: detected,
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
                Value<int> rowid = const Value.absent(),
              }) => EvidencesCompanion(
                id: id,
                visitId: visitId,
                taxonRef: taxonRef,
                kind: kind,
                filePath: filePath,
                capturedAt: capturedAt,
                contentHash: contentHash,
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
                Value<int> rowid = const Value.absent(),
              }) => EvidencesCompanion.insert(
                id: id,
                visitId: visitId,
                taxonRef: taxonRef,
                kind: kind,
                filePath: filePath,
                capturedAt: capturedAt,
                contentHash: contentHash,
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
}
