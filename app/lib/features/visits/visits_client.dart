import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_client.dart';
import '../../auth/auth_provider.dart';
import 'correction.dart';
import 'visit_status.dart';

/// Raised when the server rejects a visits request.
class VisitsException implements Exception {
  const VisitsException(this.message);

  final String message;

  @override
  String toString() => 'VisitsException: $message';
}

/// The client side of the server `visits` module's read surface
/// (`ARCHITECTURE.md`, server `visits` module): a stored Visit's Validation
/// state and its Corrections, over the pinned HTTP client (dio,
/// `TECH_STACK.md`).
///
/// Both routes are on the auth-guarded `/api/v1` surface, so every call sends
/// the sign-in headers from [AuthClient]; the server resolves the person from
/// the request (`auth.guard.ts`).
class VisitsClient {
  VisitsClient({required String baseUrl, required this._auth, Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;
  final AuthClient _auth;

  static String _visitPath(String visitId) => '/api/v1/visits/$visitId';

  /// Reads a stored Visit's Validation state (GLOSSARY.md Visit, Validation;
  /// INV-013): its `state`, `validatorId` and `validatedAt`. A `submitted`
  /// Visit with no Validation carries a null `validatorId` and `validatedAt`.
  Future<VisitStatus> readStatus(String visitId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _visitPath(visitId),
        options: Options(headers: _auth.authHeaders),
      );
      final data = response.data;
      if (data == null) {
        throw const VisitsException('Unexpected visit-status response');
      }
      return VisitStatus.fromJson(data);
    } on DioException catch (error) {
      throw VisitsException(_message(error));
    }
  }

  /// Lists a stored Visit's Corrections (GLOSSARY.md Correction; INV-001) in
  /// the server's order, oldest first.
  Future<List<Correction>> listCorrections(String visitId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${_visitPath(visitId)}/corrections',
        options: Options(headers: _auth.authHeaders),
      );
      final data = response.data ?? const <dynamic>[];
      return <Correction>[
        for (final entry in data)
          Correction.fromJson((entry as Map).cast<String, dynamic>()),
      ];
    } on DioException catch (error) {
      throw VisitsException(_message(error));
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

final visitsClientProvider = Provider<VisitsClient>(
  (ref) =>
      VisitsClient(baseUrl: authBaseUrl, auth: ref.watch(authClientProvider)),
);
