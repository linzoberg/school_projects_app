import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../utils/constants.dart';

class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  // Цвет статуса
  Color _statusColor(String status) {
    switch (status) {
      case AppConstants.statusIdea:
        return Colors.grey;
      case AppConstants.statusInProgress:
        return Colors.blue;
      case AppConstants.statusCompleted:
        return Colors.green;
      case AppConstants.statusOnContest:
        return Colors.orange;
      case AppConstants.statusArchived:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  // Иконка направления
  IconData _directionIcon(String direction) {
    switch (direction) {
      case 'Техническое':
        return Icons.computer;
      case 'Естественно-научное':
        return Icons.science;
      case 'Гуманитарное':
        return Icons.menu_book;
      case 'Социальное':
        return Icons.people;
      case 'Художественное':
        return Icons.palette;
      case 'Математическое':
        return Icons.calculate;
      case 'Экологическое':
        return Icons.eco;
      default:
        return Icons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusName =
        AppConstants.statusNames[project.status] ?? project.status;
    final statusColor = _statusColor(project.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верхняя строка: иконка направления + статус
              Row(
                children: [
                  Icon(
                    _directionIcon(project.direction),
                    color: const Color(0xFF1565C0),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      project.direction,
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Бейдж статуса
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      statusName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Название проекта
              Text(
                project.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Краткое описание
              if (project.shortDescription.isNotEmpty)
                Text(
                  project.shortDescription,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),

              // Нижняя строка: школа + руководитель + участники
              Row(
                children: [
                  const Icon(Icons.school_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project.schoolName.isNotEmpty
                          ? project.schoolName
                          : 'Школа не указана',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.group_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${project.participants.length} уч.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Руководитель
              Row(
                children: [
                  const Icon(Icons.person_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    project.supervisorName.isNotEmpty
                        ? project.supervisorName
                        : 'Руководитель не указан',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}