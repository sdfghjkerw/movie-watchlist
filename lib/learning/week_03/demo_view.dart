import 'package:flutter/material.dart';

// Общий UI позволяет сравнивать только способ передачи состояния.
class DemoView extends StatelessWidget {
  const DemoView({super.key, required this.selected, required this.toggle});
  final bool selected;
  final VoidCallback toggle;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Список просмотра: Interstellar')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('В списке: ${selected ? 1 : 0}'),
          FilledButton(
            onPressed: toggle,
            child: Text(selected ? 'Удалить' : 'Добавить'),
          ),
        ],
      ),
    ),
  );
}
