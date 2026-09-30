import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_client.dart';
import '../auth/auth_provider.dart';
import '../protocol/protocol.dart';

/// A Protocol version as the server stores it (`ARCHITECTURE.md`, server
/// `protocol-versions` module; `DOMAIN.md`): a Project-scoped snapshot of a
/// `Protocol`. Its `document` is the shared protocol format; the server assigns
/// the monotonic `version` and validates the document against the schema
/// (ADR-0009). A version referenced by any Visit is frozen and immutable
/// (INV-007).
class ProtocolVersion {
  const ProtocolVersion({
    required this.id,
    required this.projectId,
    required this.document,
    this.frozenAt,
  });

  factory ProtocolVersion.fromJson(Map<String, dynamic> json) {
    final document = json['document'];
    if (document is! Map) {
      throw const FormatException('Expected the protocol document');
    }
    final frozenAt = json['frozenAt'];
    return ProtocolVersion(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      document: ProtocolDocument.fromJson(document.cast<String, dynamic>()),
      frozenAt: frozenAt is String ? DateTime.tryParse(frozenAt) : null,
    );
  }

  final String id;
  final String projectId;
  final ProtocolDocument document;
  final DateTime? frozenAt;

  /// Whether a Visit has referenced this version, freezing it (INV-007).
  /// A frozen version is never updated; a change creates a new version.
  bool get isFrozen => frozenAt != null;
}

/// Raised when the server rejects a protocol-versions request.
class ProtocolVersionsException implements Exception {
  const ProtocolVersionsException(this.message);

  final String message;

  @override
  String toString() => 'ProtocolVersionsException: $message';
}

/// The client side of the server `protocol-versions` module's REST surface
/// (`ARCHITECTURE.md`), over the pinned HTTP client (dio, `TECH_STACK.md`).
///
/// Every call sends the Better Auth cookie from [AuthClient], so the server
/// resolves the creator from the request (`auth.guard.ts`). There is
/// deliberately no update method: a frozen version is immutable (INV-007), so a
/// change is submitted as a new version through [create].
class ProtocolVersionsClient {
  ProtocolVersionsClient({
    required String baseUrl,
    required this._auth,
    Dio? dio,
  }) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;
  final AuthClient _auth;

  static const String _basePath = '/protocol-versions';

  /// Defines a new Protocol version for a Project. The server assigns the
  /// monotonic version number, validates the document against the shared
  /// schema, and answers with the stored version.
  Future<ProtocolVersion> create({
    required String projectId,
    required ProtocolDocument document,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _basePath,
        data: <String, dynamic>{
          'projectId': projectId,
          'document': document.toJson(),
        },
        options: Options(headers: _auth.authHeaders),
      );
      final data = response.data;
      if (data == null) {
        throw const ProtocolVersionsException(
          'Unexpected protocol-version response',
        );
      }
      return ProtocolVersion.fromJson(data);
    } on DioException catch (error) {
      throw ProtocolVersionsException(_message(error));
    }
  }

  /// Freezes a Protocol version (INV-007). A frozen version is never updated;
  /// a change is submitted as a new version through [create].
  Future<ProtocolVersion> freeze(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_basePath/$id/freeze',
        options: Options(headers: _auth.authHeaders),
      );
      final data = response.data;
      if (data == null) {
        throw const ProtocolVersionsException(
          'Unexpected protocol-version response',
        );
      }
      return ProtocolVersion.fromJson(data);
    } on DioException catch (error) {
      throw ProtocolVersionsException(_message(error));
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

final protocolVersionsClientProvider = Provider<ProtocolVersionsClient>(
  (ref) => ProtocolVersionsClient(
    baseUrl: authBaseUrl,
    auth: ref.watch(authClientProvider),
  ),
);
