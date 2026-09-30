import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'router/app_router.dart';

final appTitleProvider = Provider<String>((ref) => 'IBIS');

class IbisApp extends ConsumerWidget {
  const IbisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(appTitleProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(title: title, routerConfig: router);
  }
}
