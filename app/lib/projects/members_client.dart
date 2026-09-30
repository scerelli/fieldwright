import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_client.dart';
import '../auth/auth_provider.dart';

/// The role a person holds in a Project, as the server stores it
/// (`membership_role`; `DOMAIN.md`, `GLOSSARY.md` Membership). A Project's
/// creator is assigned at creation; collector and validator are grantable
/// afterwards.
enum MembershipRole {
  creator('creator'),
  collector('collector'),
  validator('validator');

  const MembershipRole(this.wire);

  /// The value the server stores and accepts.
  final String wire;

  /// The roles a creator may grant. The creator role is never granted after
  /// Project creation, so it is not in this list.
  static const List<MembershipRole> grantable = <MembershipRole>[
    collector,
    validator,
  ];

  static MembershipRole fromWire(Object? value) {
    for (final role in values) {
      if (role.wire == value) return role;
    }
    throw FormatException('Unknown Membership role: $value');
  }
}

/// A Membership as the server stores it (`ARCHITECTURE.md`, server `projects`
/// module): the link between a person and a Project, carrying the role they
/// hold there (`DOMAIN.md`, `GLOSSARY.md`). It references a person, so the
/// person's email travels with it for display.
class Membership {
  const Membership({
    required this.id,
    required this.personId,
    required this.role,
    this.email = '',
  });

  factory Membership.fromJson(Map<String, dynamic> json, {String? email}) {
    final serverEmail = json['email'] as String?;
    return Membership(
      id: json['id'] as String? ?? '',
      personId: json['personId'] as String? ?? '',
      role: MembershipRole.fromWire(json['role']),
      email: serverEmail == null || serverEmail.isEmpty
          ? (email ?? '')
          : serverEmail,
    );
  }

  final String id;
  final String personId;
  final MembershipRole role;

  /// The person's email; empty when the server does not echo it.
  final String email;
}

/// Raised when the server rejects a members request.
class MembersException implements Exception {
  const MembersException(this.message);

  final String message;

  @override
  String toString() => 'MembersException: $message';
}

/// The client side of the server `projects` module's Membership surface
/// (`ARCHITECTURE.md`), over the pinned HTTP client (dio, `TECH_STACK.md`).
///
/// Every call carries the Better Auth cookie from [AuthClient], so the server
/// resolves the person from the request (`auth.guard.ts`); only the Project's
/// creator may grant a role.
class MembersClient {
  MembersClient({required String baseUrl, required this._auth, Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;
  final AuthClient _auth;

  static String _path(String projectId) => '/projects/$projectId/members';

  /// Lists the Project's Memberships. A non-creator sees the same list, minus
  /// the ability to add.
  Future<List<Membership>> list(String projectId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        _path(projectId),
        options: Options(headers: _auth.authHeaders),
      );
      final data = response.data ?? const <dynamic>[];
      return <Membership>[
        for (final entry in data)
          Membership.fromJson((entry as Map).cast<String, dynamic>()),
      ];
    } on DioException catch (error) {
      throw MembersException(_message(error));
    }
  }

  /// Adds an existing person, resolved by email, to the Project with a
  /// grantable role. The server answers with the stored Membership, which does
  /// not echo the email, so the requested email is kept for display.
  Future<Membership> add({
    required String projectId,
    required String email,
    required MembershipRole role,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _path(projectId),
        data: <String, String>{'email': email, 'role': role.wire},
        options: Options(headers: _auth.authHeaders),
      );
      final data = response.data;
      if (data == null) {
        throw const MembersException('Unexpected add-member response');
      }
      return Membership.fromJson(data, email: email);
    } on DioException catch (error) {
      throw MembersException(_message(error));
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

final membersClientProvider = Provider<MembersClient>(
  (ref) =>
      MembersClient(baseUrl: authBaseUrl, auth: ref.watch(authClientProvider)),
);
