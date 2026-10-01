import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_client.dart';
import '../auth/auth_provider.dart';
import '../projects/projects_client.dart';
import '../projects/survey_periods_client.dart';
import '../protocol_versions/protocol_versions_client.dart';

/// A Site as the versioned config pull carries it (`ARCHITECTURE.md`'s sync
/// compatibility surface, ADR-0011).
///
/// It is the minimal sync row the server's `sync` module reads from the
/// `sites` module — identity, optional name, and geometry as GeoJSON text —
/// not the domain `Site`, whose planned/field origin and covariates the config
/// route does not yet serve. A pull tolerates the difference: a field the
/// client does not model is ignored (ADR-0011).
class ConfigSite {
  const ConfigSite({
    required this.id,
    required this.projectId,
    this.name,
    this.geom,
    this.createdAt,
  });

  factory ConfigSite.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return ConfigSite(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      name: json['name'] as String?,
      geom: json['geom'] as String?,
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    );
  }

  final String id;
  final String projectId;
  final String? name;

  /// The Site geometry as GeoJSON text, when the server has one.
  final String? geom;

  final DateTime? createdAt;
}

/// The changed Project configuration one pull returns (`ARCHITECTURE.md`,
/// ADR-0011).
///
/// `versionToken` is the opaque token to send as `since` on the next pull: it
/// advances whenever a Protocol version, Survey period or Site is created, so
/// a pull carrying the token from the immediately preceding pull is empty.
/// `project` and `protocolVersion` are present only when they changed — the
/// latest Protocol version carries the Target list in its `document` — while
/// `surveyPeriods` and `sites` are always lists, empty when nothing changed.
class ConfigPull {
  const ConfigPull({
    required this.versionToken,
    this.project,
    this.protocolVersion,
    this.surveyPeriods = const <SurveyPeriod>[],
    this.sites = const <ConfigSite>[],
  });

  factory ConfigPull.fromJson(Map<String, dynamic> json) {
    final project = json['project'];
    final protocolVersion = json['protocolVersion'];
    return ConfigPull(
      versionToken: json['versionToken'] as String? ?? '',
      project: project is Map
          ? Project.fromJson(project.cast<String, dynamic>())
          : null,
      protocolVersion: protocolVersion is Map
          ? ProtocolVersion.fromJson(protocolVersion.cast<String, dynamic>())
          : null,
      surveyPeriods: _parseList<SurveyPeriod>(
        json['surveyPeriods'],
        SurveyPeriod.fromJson,
      ),
      sites: _parseList<ConfigSite>(json['sites'], ConfigSite.fromJson),
    );
  }

  final String versionToken;
  final Project? project;
  final ProtocolVersion? protocolVersion;
  final List<SurveyPeriod> surveyPeriods;
  final List<ConfigSite> sites;
}

List<T> _parseList<T>(Object? value, T Function(Map<String, dynamic>) parse) {
  if (value is! List) {
    return <T>[];
  }
  return <T>[
    for (final entry in value)
      if (entry is Map) parse(entry.cast<String, dynamic>()),
  ];
}

/// Raised when a config pull fails, carrying the server's message when it
/// answered with one (`ARCHITECTURE.md`, ADR-0011).
class ConfigSyncException implements Exception {
  const ConfigSyncException(this.message);

  final String message;

  @override
  String toString() => 'ConfigSyncException: $message';
}

/// The client side of the versioned sync API's config pull (`ARCHITECTURE.md`,
/// ADR-0011): `GET /api/v1/projects/:projectId/config?since=` over the pinned
/// dio client (`TECH_STACK.md`).
///
/// `since` is the stored version token from the previous pull; the server
/// answers with only what changed after it plus the token for the next pull.
/// The route is auth-guarded, so every call carries the sign-in cookie from
/// [AuthClient].
class ConfigSyncClient {
  ConfigSyncClient({required String baseUrl, required this._auth, Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;
  final AuthClient _auth;

  /// Pulls the Project configuration changed since [since], or the whole
  /// configuration when [since] is null.
  Future<ConfigPull> pull({required String projectId, String? since}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/projects/$projectId/config',
        queryParameters: <String, String>{'since': ?since},
        options: Options(headers: _auth.authHeaders),
      );
      final data = response.data;
      if (data == null) {
        throw const ConfigSyncException('Unexpected config-pull response');
      }
      return ConfigPull.fromJson(data);
    } on DioException catch (error) {
      throw ConfigSyncException(_message(error));
    }
  }

  static String _message(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return error.message ?? 'Request failed';
  }
}

final configSyncClientProvider = Provider<ConfigSyncClient>(
  (ref) => ConfigSyncClient(
    baseUrl: authBaseUrl,
    auth: ref.watch(authClientProvider),
  ),
);
