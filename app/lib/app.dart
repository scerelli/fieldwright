import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appTitleProvider = Provider<String>((ref) => 'IBIS');

class IbisApp extends ConsumerWidget {
  const IbisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(appTitleProvider);

    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: Text('IBIS')),
      ),
    );
  }
}
