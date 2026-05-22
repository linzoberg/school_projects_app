import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/project_model.dart';
import '../../services/project_service.dart';
import '../../utils/constants.dart';
import 'project_form_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectService _projectService = ProjectService();
  ProjectModel? _project;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    setState(() => _isLoading = true);
    final project = await _projectService.getProjectById(widget.projectId);
    setState(() {
      _project = project;
      _isLoading = false;
    });
  }

  // Изменить статус проекта
  void _changeStatus() {
    if (_project == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Изменить статус',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...AppConstants.statusNames.entries.map((e) {
                final isSelected = e.key == _project!.status;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF1565C0)
                        : Colors.grey,
                  ),
                  title: Text(e.value),
                  onTap: () async {
                    Navigator.pop(context);
                    await _projectService.updateProjectStatus(
                      _project!.id,
                      e.key,
                    );
                    _loadProject();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Удалить проект
  void _deleteProject() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить проект?'),
        content: const Text(
            'Это действие нельзя отменить. Проект будет удалён безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _projectService.deleteProject(_project!.id);
              if (mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  // Цвет статуса
  Color _statusColor(String status) {
    switch (status) {
      case 'idea': return Colors.grey;
      case 'in_progress': return Colors.blue;
      case 'completed': return Colors.green;
      case 'on_contest': return Colors.orange;
      case 'archived': return Colors.brown;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AppState>().currentUser;
    final isAdminOrTeacher = currentUser?.role == 'admin' ||
        currentUser?.role == 'teacher';

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Проект')),
        body: const Center(child: Text('Проект не найден')),
      );
    }

    final p = _project!;
    final dateFormat = DateFormat('dd.MM.yyyy');
    final statusColor = _statusColor(p.status);
    final statusName =
        AppConstants.statusNames[p.status] ?? p.status;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка проекта'),
        actions: [
          if (isAdminOrTeacher) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Редактировать',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectFormScreen(project: p),
                  ),
                );
                _loadProject();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Удалить',
              onPressed: _deleteProject,
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProject,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Статус + направление
              Row(
                children: [
                  GestureDetector(
                    onTap: isAdminOrTeacher ? _changeStatus : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: statusColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            statusName,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isAdminOrTeacher) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down,
                                color: statusColor, size: 18),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.direction,
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Название
              Text(
                p.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Краткое описание
              if (p.shortDescription.isNotEmpty)
                Text(
                  p.shortDescription,
                  style: const TextStyle(
                      fontSize: 15, color: Colors.black87),
                ),
              const SizedBox(height: 16),

              // Блок информации
              _infoCard([
                _infoRow(Icons.school_outlined, 'Организация',
                    p.schoolName.isEmpty ? 'Не указана' : p.schoolName),
                _infoRow(Icons.person_outlined, 'Руководитель',
                    p.supervisorName.isEmpty
                        ? 'Не указан'
                        : p.supervisorName),
                _infoRow(
                  Icons.calendar_today_outlined,
                  'Начало работы',
                  dateFormat.format(p.startDate),
                ),
                if (p.endDate != null)
                  _infoRow(
                    Icons.event_outlined,
                    'Дата завершения',
                    dateFormat.format(p.endDate!),
                  ),
              ]),
              const SizedBox(height: 16),

              // Полное описание
              if (p.fullDescription.isNotEmpty) ...[
                _sectionTitle('Описание проекта'),
                const SizedBox(height: 8),
                Text(p.fullDescription,
                    style: const TextStyle(fontSize: 14, height: 1.5)),
                const SizedBox(height: 16),
              ],

              // Участники
              _sectionTitle(
                  'Участники (${p.participants.length})'),
              const SizedBox(height: 8),
              if (p.participants.isEmpty)
                const Text('Участники не указаны',
                    style: TextStyle(color: Colors.grey))
              else
                ...p.participants.map((participant) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                      const Color(0xFF1565C0).withOpacity(0.1),
                      child: Text(
                        participant.displayName.isNotEmpty
                            ? participant.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Color(0xFF1565C0)),
                      ),
                    ),
                    title: Text(participant.displayName),
                    subtitle: Text(
                      participant.role == 'author'
                          ? 'Автор'
                          : 'Участник',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
              const SizedBox(height: 16),

              // Результаты
              if (p.results.isNotEmpty) ...[
                _sectionTitle('Результаты'),
                const SizedBox(height: 8),
                Text(p.results,
                    style: const TextStyle(fontSize: 14, height: 1.5)),
                const SizedBox(height: 16),
              ],

              // Награды
              if (p.awards.isNotEmpty) ...[
                _sectionTitle('Достижения и награды'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(p.awards,
                            style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Дата создания
              Text(
                'Создан: ${dateFormat.format(p.createdAt)}',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Вспомогательные виджеты
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1565C0),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: children),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}