import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'demo_view.dart';

void main() =>
    runApp(MaterialApp(theme: AppTheme.darkTheme, home: const InheritedDemo()));

class WatchlistScope extends InheritedWidget {
  const WatchlistScope({
    super.key,
    required this.selected,
    required this.toggle,
    required super.child,
  });
  final bool selected;
  final VoidCallback toggle;
  static WatchlistScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WatchlistScope>()!;
  @override
  bool updateShouldNotify(WatchlistScope oldWidget) =>
      selected != oldWidget.selected;
}

class InheritedDemo extends StatefulWidget {
  const InheritedDemo({super.key});
  @override
  State<InheritedDemo> createState() => _InheritedDemoState();
}

class _InheritedDemoState extends State<InheritedDemo> {
  bool selected = false;
  @override
  Widget build(BuildContext context) => WatchlistScope(
    selected: selected,
    toggle: () => setState(() => selected = !selected),
    child: const _InheritedContent(),
  );
}

class _InheritedContent extends StatelessWidget {
  const _InheritedContent();
  @override
  Widget build(BuildContext context) {
    final scope = WatchlistScope.of(context);
    return DemoView(selected: scope.selected, toggle: scope.toggle);
  }
}
