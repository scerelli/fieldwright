import 'package:flutter/material.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Projects count: $_count'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => setState(() => _count++),
              child: const Text('Increment Projects'),
            ),
          ],
        ),
      ),
    );
  }
}
