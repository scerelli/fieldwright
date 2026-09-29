import 'package:flutter/material.dart';

class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sites')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sites count: $_count'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => setState(() => _count++),
              child: const Text('Increment Sites'),
            ),
          ],
        ),
      ),
    );
  }
}
