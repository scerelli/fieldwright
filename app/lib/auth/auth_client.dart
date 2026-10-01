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

  String?
  _sessionCookie; // glossary:allow Better Auth session cookie, not the Visit

  static const String _signInPath = '/api/auth/sign-in/email';
  static const String _signUpPath = '/api/auth/sign-up/email';
  static const String _signOutPath = '/api/auth/sign-out';

  /// The Better Auth session cookie captured at sign-in, or `null` while signed
  /// out. // glossary:allow Better Auth session, not the domain Visit
  ///
  /// Better Auth identifies a request by cookie, so an authenticated call must
  /// carry this; `authHeaders` is the way to attach it.
  String? get sessionCookie =>
      _sessionCookie; // glossary:allow Better Auth session, not the Visit

  /// Headers that carry the current auth session on an authenticated request. // glossary:allow Better Auth auth session, not the domain Visit
  Map<String, String> get authHeaders => _sessionCookie == null
      ? const <String, String>{}
      : <String, String>{'cookie': _sessionCookie!};

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
      _captureSession(response.headers);
      final user = response.data?['user'];
      if (user is! Map<String, dynamic>) {
        throw const AuthException('Unexpected sign-in response');
      }
      return Person.fromJson(user);
    } on DioException catch (error) {
      throw AuthException(_message(error));
    }
  }

  /// Creates the person's account and signs them in in the same response
  /// (Better Auth `autoSignIn`), returning the new person. No email
  /// verification step is required.
  Future<Person> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _signUpPath,
        data: <String, String>{
          'name': name,
          'email': email,
          'password': password,
        },
      );
      _captureSession(response.headers); // glossary:allow auth session
      final user = response.data?['user'];
      if (user is! Map<String, dynamic>) {
        throw const AuthException('Unexpected sign-up response');
      }
      return Person.fromJson(user);
    } on DioException catch (error) {
      throw AuthException(_message(error));
    }
  }

  /// Ends the current auth session. // glossary:allow Better Auth auth session, not the domain Visit
  Future<void> signOut() async {
    try {
      await _dio.post<void>(
        _signOutPath,
        options: Options(headers: authHeaders),
      );
    } on DioException catch (error) {
      throw AuthException(_message(error));
    } finally {
      _sessionCookie = null;
    }
  }

  /// Keeps the `name=value` pairs Better Auth set at sign-in so later requests
  /// can send them back as a `Cookie` header. // glossary:allow Better Auth session cookie, not the domain Visit
  void _captureSession(Headers headers) {
    final setCookies = headers['set-cookie'];
    if (setCookies == null) return;
    final pairs = <String>[
      for (final cookie in setCookies)
        if (cookie.split(';').first.trim().isNotEmpty)
          cookie.split(';').first.trim(),
    ];
    if (pairs.isNotEmpty) {
      _sessionCookie = pairs.join('; ');
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
