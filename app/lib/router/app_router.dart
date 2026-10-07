import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/account_screen.dart';
import '../features/help/help_screen.dart';
import '../features/projects/members_screen.dart';
import '../features/projects/project_editor.dart';
import '../features/projects/projects_screen.dart';
import '../features/projects/protocol_version_screen.dart';
import '../features/projects/survey_periods_screen.dart';
import '../features/visits/visit_detail_screen.dart';
import '../features/visits/visits_client.dart';
import '../projects/members_client.dart';
import '../projects/projects_client.dart';
import '../projects/survey_periods_client.dart';
import '../protocol_versions/protocol_versions_client.dart';
import '../shell/app_shell.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/projects',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectsScreen(),
            routes: [
              GoRoute(
                path: ':projectId',
                builder: (context, state) {
                  final extra = state.extra;
                  return ProjectDetailScreen(
                    projectId: state.pathParameters['projectId']!,
                    project: extra is Project ? extra : null,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => ProjectSettingsScreen(
                      projectId: state.pathParameters['projectId']!,
                      initial: state.extra is Project
                          ? state.extra as Project
                          : null,
                    ),
                  ),
                  GoRoute(
                    path: 'protocol',
                    builder: (context, state) => ProtocolVersionScreen(
                      client: ref.read(protocolVersionsClientProvider),
                      projectId: state.pathParameters['projectId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'members',
                    builder: (context, state) => MembersScreen(
                      client: ref.read(membersClientProvider),
                      projectId: state.pathParameters['projectId']!,
                      isCreator: true,
                    ),
                  ),
                  GoRoute(
                    path: 'survey-periods',
                    builder: (context, state) => SurveyPeriodsScreen(
                      client: ref.read(surveyPeriodsClientProvider),
                      projectId: state.pathParameters['projectId']!,
                      isCreator: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/account',
            builder: (context, state) => const AccountScreen(),
          ),
          GoRoute(
            path: '/help',
            builder: (context, state) => const HelpScreen(),
          ),
          GoRoute(
            path: '/visits/:visitId',
            builder: (context, state) => VisitDetailScreen(
              visitId: state.pathParameters['visitId']!,
              client: ref.read(visitsClientProvider),
            ),
          ),
        ],
      ),
    ],
  );
});
