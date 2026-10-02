import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_client.dart';
import '../auth/auth_provider.dart';

/// A Project the signed-in person can see, as the server returns it
/// (`ARCHITECTURE.md`, server `projects` module). Identity is server-assigned
/// on creation by the creator (`DOMAIN.md`).
class Project {
  const Project({
    required this.id,
    required this.name,
    required this.validationEnabled,
    required this.sensitiveTaxaObfuscation,
    required this.taxonomicReferenceId,
    required this.taxonomicReferenceVersion,
    this.description,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'];
    final map = settings is Map
        ? settings.cast<String, dynamic>()
        : const <String, dynamic>{};
    return Project(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      validationEnabled: map['validationEnabled'] as bool? ?? false,
      sensitiveTaxaObfuscation:
          map['sensitiveTaxaObfuscation'] as bool? ?? false,
      taxonomicReferenceId: json['taxonomicReferenceId'] as String? ?? '',
      taxonomicReferenceVersion:
          json['taxonomicReferenceVersion'] as String? ?? '',
    );
  }

  final String id;
  final String name;

  /// Short authored text describing the Project (`DOMAIN.md` Project aggregate,
  /// ADR-0016), or null when none was set.
  final String? description;

  final bool validationEnabled;
  final bool sensitiveTaxaObfuscation;
  final String taxonomicReferenceId;
  final String taxonomicReferenceVersion;
}

/// The settings a creator sets when defining a Project (`DOMAIN.md`): its
/// name, validation, sensitive-taxa obfuscation, and the pinned Taxonomic
/// reference version.
class CreateProjectInput {
  const CreateProjectInput({
    required this.name,
    required this.validationEnabled,
    required this.sensitiveTaxaObfuscation,
    required this.taxonomicReferenceId,
    required this.taxonomicReferenceVersion,
  });

  final String name;
  final bool validationEnabled;
  final bool sensitiveTaxaObfuscation;
  final String taxonomicReferenceId;
  final String taxonomicReferenceVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'validationEnabled': validationEnabled,
    'sensitiveTaxaObfuscation': sensitiveTaxaObfuscation,
    'taxonomicReferenceId': taxonomicReferenceId,
    'taxonomicReferenceVersion': taxonomicReferenceVersion,
  };
}

/// Raised when the server rejects a projects request.
class ProjectsException implements Exception {
  const ProjectsException(this.message);

  final String message;

  @override
  String toString() => 'ProjectsException: $message';
}

/// The client side of the server `projects` module's REST surface
/// (`ARCHITECTURE.md`), over the pinned HTTP client (dio, `TECH_STACK.md`).
///
/// Every call carries the Better Auth session from [AuthClient], so the
/// server resolves the creator from the request (`auth.guard.ts`).
class ProjectsClient {
  ProjectsClient({required String baseUrl, required this._auth, Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;
  final AuthClient _auth;

  static const String _projectsPath = '/projects';

  /// Creates a Project and its creator Membership; the server answers with the
  /// stored Project.
  Future<Project> create(CreateProjectInput input) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _projectsPath,
        data: input.toJson(),
        options: Options(headers: _auth.authHeaders),
      );
      final data = response.data;
      if (data == null) {
        throw const ProjectsException('Unexpected create-project response');
      }
      return Project.fromJson(data);
    } on DioException catch (error) {
      throw ProjectsException(_message(error));
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

final projectsClientProvider = Provider<ProjectsClient>(
  (ref) =>
      ProjectsClient(baseUrl: authBaseUrl, auth: ref.watch(authClientProvider)),
);
