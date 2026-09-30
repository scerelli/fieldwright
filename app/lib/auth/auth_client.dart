import 'package:dio/dio.dart';

/// The person an auth session belongs to. // glossary:allow Better Auth auth session, not the domain Visit
///
/// Identity is out of the domain model — a `Membership` only references a
/// person (`DOMAIN.md`) — so this carries just what the app shows: who is
/// signed in. It is Better Auth's user, not a domain aggregate.
class Person {
  const Person({required this.id, required this.email, required this.name});

  factory Person.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String? ?? '';
    return Person(
      id: json['id'] as String? ?? '',
      email: email,
      name: json['name'] as String? ?? email,
    );
  }

  final String id;
  final String email;
  final String name;
}

/// Raised when Better Auth rejects a request, such as wrong credentials.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// The client side of Better Auth's email/password REST surface, over the
/// pinned HTTP client (dio, `TECH_STACK.md`).
///
/// It only identifies a person; roles are project-scoped `Membership`s and
/// never global (`ARCHITECTURE.md`).
class AuthClient {
  AuthClient({required String baseUrl, Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;

  static const String _signInPath = '/api/auth/sign-in/email';
  static const String _signOutPath = '/api/auth/sign-out';

  /// Starts an auth session and returns the current person. // glossary:allow Better Auth auth session, not the domain Visit
  Future<Person> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _signInPath,
        data: <String, String>{'email': email, 'password': password},
      );
      final user = response.data?['user'];
      if (user is! Map<String, dynamic>) {
        throw const AuthException('Unexpected sign-in response');
      }
      return Person.fromJson(user);
    } on DioException catch (error) {
      throw AuthException(_message(error));
    }
  }

  /// Ends the current auth session. // glossary:allow Better Auth auth session, not the domain Visit
  Future<void> signOut() async {
    try {
      await _dio.post<void>(_signOutPath);
    } on DioException catch (error) {
      throw AuthException(_message(error));
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
