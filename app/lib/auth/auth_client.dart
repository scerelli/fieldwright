import 'dart:async';

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

/// Raised when Better Auth cannot be reached, or answers with a transient
/// server fault, so the caller keeps the persisted sign-in and retries.
class AuthTransportException implements Exception {
  const AuthTransportException(this.cause);

  final Object cause;

  @override
  String toString() => 'AuthTransportException: $cause';
}

/// The client side of Better Auth's email/password REST surface, over the
/// pinned HTTP client (dio, `TECH_STACK.md`).
///
/// It only identifies a person; roles are project-scoped `Membership`s and
/// never global (`ARCHITECTURE.md`).
class AuthClient {
  AuthClient({
    required String baseUrl,
    Dio? dio,
    this.requestTimeout = defaultRequestTimeout,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: defaultRequestTimeout,
               receiveTimeout: defaultRequestTimeout,
             ),
           );

  /// Bounds a hung server so app-start restore cannot delay the first frame
  /// indefinitely; overridable so a test can assert the bound cheaply.
  static const Duration defaultRequestTimeout = Duration(seconds: 5);

  final Duration requestTimeout;
  final Dio _dio;

  String?
  _sessionCookie; // glossary:allow Better Auth session cookie, not the Visit

  static const String _signInPath = '/api/auth/sign-in/email';
  static const String _signUpPath = '/api/auth/sign-up/email';
  static const String _signOutPath = '/api/auth/sign-out';
  static const String _getSessionPath = '/api/auth/get-session'; // glossary:allow Better Auth get-session endpoint, not the domain Visit

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

  /// Re-attaches a persisted [cookie] and validates it against Better Auth's
  /// get-session endpoint. // glossary:allow Better Auth auth session, not the domain Visit
  ///
  /// Returns the person the server reports for the cookie, or `null` when the
  /// server has no session for it — the caller clears the persisted sign-in. // glossary:allow Better Auth auth session, not the domain Visit
  /// Throws [AuthException] when the server rejects the cookie with a 401/403, // glossary:allow Better Auth auth session rejection, not the domain Visit
  /// or answers 200 with no session. A transport fault (unreachable, timeout) // glossary:allow Better Auth auth session, not the domain Visit
  /// or any other status (a transient 5xx) raises [AuthTransportException]
  /// with the cookie still attached, so the caller keeps the persisted
  /// sign-in and retries once the server is reachable (UX-007).
  Future<Person?> restoreSession(String cookie) async { // glossary:allow Better Auth session restore, not the domain Visit
    _sessionCookie = cookie; // glossary:allow Better Auth session cookie, not the domain Visit
    try {
      final response = await _dio
          .get<dynamic>(
            _getSessionPath, // glossary:allow Better Auth get-session endpoint, not the domain Visit
            options: Options(headers: authHeaders),
          )
          .timeout(requestTimeout);
      final data = response.data;
      if (data is Map && data['user'] is Map) {
        return Person.fromJson((data['user'] as Map).cast<String, dynamic>());
      }
      _sessionCookie = null; // glossary:allow Better Auth session cookie, not the domain Visit
      return null;
    } on TimeoutException catch (error) {
      throw AuthTransportException(error);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        _sessionCookie = null; // glossary:allow Better Auth session cookie, not the domain Visit
        throw AuthException(_message(error));
      }
      throw AuthTransportException(error);
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
