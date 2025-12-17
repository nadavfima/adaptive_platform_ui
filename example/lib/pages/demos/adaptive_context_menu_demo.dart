import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

/// Demonstrates the AdaptiveContextMenu with dismiss detection
class AdaptiveContextMenuDemo extends StatefulWidget {
  const AdaptiveContextMenuDemo({super.key});

  @override
  State<AdaptiveContextMenuDemo> createState() => _AdaptiveContextMenuDemoState();
}

class _AdaptiveContextMenuDemoState extends State<AdaptiveContextMenuDemo> {
  String _lastAction = 'Long press the image';
  int _dismissCount = 0;
  int _openCount = 0;
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Context Menu Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _lastAction,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isMenuOpen ? Colors.green.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Menu Status: ${_isMenuOpen ? "OPEN" : "CLOSED"}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isMenuOpen ? Colors.green.shade900 : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Opened: $_openCount times',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Dismissed: $_dismissCount times',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            AdaptiveContextMenu(
              onOpened: () {
                setState(() {
                  _openCount++;
                  _isMenuOpen = true;
                  _lastAction = 'Menu opened!';
                });
                debugPrint('Context menu was opened');
              },
              onDismiss: () {
                setState(() {
                  _dismissCount++;
                  _isMenuOpen = false;
                  _lastAction = 'Menu dismissed without selection';
                });
                debugPrint('Context menu was dismissed');
              },
              actions: [
                AdaptiveContextMenuAction(
                  title: 'Share',
                  icon: Icons.share,
                  onPressed: () {
                    setState(() {
                      _isMenuOpen = false;
                      _lastAction = 'Share action pressed';
                    });
                  },
                ),
                AdaptiveContextMenuAction(
                  title: 'Edit',
                  icon: Icons.edit,
                  onPressed: () {
                    setState(() {
                      _isMenuOpen = false;
                      _lastAction = 'Edit action pressed';
                    });
                  },
                ),
                AdaptiveContextMenuAction(
                  title: 'Delete',
                  icon: Icons.delete,
                  isDestructive: true,
                  onPressed: () {
                    setState(() {
                      _isMenuOpen = false;
                      _lastAction = 'Delete action pressed';
                    });
                  },
                ),
              ],
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

