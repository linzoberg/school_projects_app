import 'package:flutter/material.dart';
import '../../models/project_model.dart';

class ProjectFormScreen extends StatelessWidget {
  final ProjectModel? project; // null = создание, не null = редактирование

  const ProjectFormScreen({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    final isEditing = project != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать проект' : 'Новый проект'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              isEditing
                  ? 'Форма редактирования\n(Модуль 4)'
                  : 'Форма создания проекта\n(Модуль 4)',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}