import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_client.dart';
import '../auth/auth_provider.dart';

/// A Survey period as the server stores it (`ARCHITECTURE.md`, server
/// `survey-periods` module; `DOMAIN.md`, `GLOSSARY.md` SurveyPeriod): a named
/// date range in which Visits are expected, defined by a Project's creator.
/// Dates travel as ISO `YYYY-MM-DD` strings, matching the server's `date`
/// columns.
class SurveyPeriod {
  const SurveyPeriod({
    required this.id,
    required this.projectId,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  factory SurveyPeriod.fromJson(Map<String, dynamic> json) => SurveyPeriod(
    id: json['id'] as String? ?? '',
    projectId: json['projectId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    startDate: json['startDate'] as String? ?? '',
    endDate: json['endDate'] as String? ?? '',
  );

  final String id;
  final String projectId;
  final String name;

  /// The inclusive start date, as an ISO `YYYY-MM-DD` string.
  final String startDate;

  /// The inclusive end date, as an ISO `YYYY-MM-DD` string.
  final String endDate;
}

/// Raised when the server rejects a survey-periods request.
class SurveyPeriodsException implements Exception {
  const SurveyPeriodsException(this.message);

  final String message;

  @override
  String toString() => 'SurveyPeriodsException: $message';
}

/// The client side of the server `survey-periods` module's REST surface
/// (`ARCHITECTURE.md`), over the pinned HTTP client (dio, `TECH_STACK.md`).
///
/// Every call carries the Better Auth cookie from [AuthClient], so the server
/// resolves the person from the request (`auth.guard.ts`); only the Project's
/// creator may define a Survey period, and any member may list them.
class SurveyPeriodsClient {
  SurveyPeriodsClient({required String baseUrl, required this._auth, Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;
  final AuthClient _auth;

  static const String _basePath = '/survey-periods';

  /// Lists the Survey periods of one Project. The list is scoped to the
  /// Project by the `projectId` query parameter, so only that Project's
  /// schedule is returned.
  Future<List<SurveyPeriod>> list(String projectId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        _basePath,
        queryParameters: <String, String>{'projectId': projectId},
        options: Options(headers: _auth.authHeaders),
      );
      final data = response.data ?? const <dynamic>[];
      return <SurveyPeriod>[
        for (final entry in data)
          SurveyPeriod.fromJson((entry as Map).cast<String, dynamic>()),
      ];
    } on DioException catch (error) {
      throw SurveyPeriodsException(_message(error));
    }
  }

  /// Defines a Survey period for a Project. The server answers with the stored
  /// Survey period; an end date preceding the start date is the caller's to
  /// reject before this is called.
  Future<SurveyPeriod> create({
    required String projectId,
    required String name,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _basePath,
        data: <String, String>{
          'projectId': projectId,
          'name': name,
          'startDate': startDate,
          'endDate': endDate,
        },
        options: Options(headers: _auth.authHeaders),
      );
      final data = response.data;
      if (data == null) {
        throw const SurveyPeriodsException('Unexpected survey-period response');
      }
      return SurveyPeriod.fromJson(data);
    } on DioException catch (error) {
      throw SurveyPeriodsException(_message(error));
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

final surveyPeriodsClientProvider = Provider<SurveyPeriodsClient>(
  (ref) => SurveyPeriodsClient(
    baseUrl: authBaseUrl,
    auth: ref.watch(authClientProvider),
  ),
);
