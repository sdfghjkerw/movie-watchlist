import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'demo_view.dart';

void main() =>
    runApp(MaterialApp(theme: AppTheme.darkTheme, home: const SetStateDemo()));

class SetStateDemo extends StatefulWidget {
  const SetStateDemo({super.key});
  @override
  State<SetStateDemo> createState() => _SetStateDemoState();
}

class _SetStateDemoState extends State<SetStateDemo> {
  bool selected = false;
  @override
  Widget build(BuildContext context) => DemoView(
    selected: selected,
    toggle: () => setState(() => selected = !selected),
  );
}
