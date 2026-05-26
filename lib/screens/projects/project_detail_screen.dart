import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/project_model.dart';
import '../../services/project_service.dart';
import '../../utils/constants.dart';
import '../../widgets/project_files_widget.dart';
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

  final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    setState(() => _isLoading = true);
    final project =
    await _projectService.getProjectById(widget.projectId);
    setState(() {
      _project = project;
      _isLoading = false;
    });
  }

  void _changeStatus() {
    if (_project == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Изменить статус',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              ...AppConstants.statusNames.entries.map((entry) {
                final isSelected = entry.key == _project!.status;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF1565C0)
                        : Colors.grey,
                  ),
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF1565C0)
                          : Colors.black87,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _projectService.updateProjectStatus(
                      _project!.id,
                      entry.key,
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

  void _deleteProject() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить проект?'),
        content: const Text(
          'Это действие нельзя отменить.\n'
              'Проект и все связанные данные будут удалены.',
        ),
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

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final currentUser = appState.currentUser;
    final role = currentUser?.role ?? 'student';

    // Права доступа
    final canEdit = role == AppConstants.roleTeacher ||
        role == AppConstants.roleAdmin;
    final canDelete = role == AppConstants.roleAdmin;
    final canUploadFiles = canEdit;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Проект')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Проект не найден',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final p = _project!;
    final statusColor = _statusColor(p.status);
    final statusName =
        AppConstants.statusNames[p.status] ?? p.status;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка проекта'),
        actions: [
          if (canEdit)
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
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Удалить',
              onPressed: _deleteProject,
            ),
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

              // ── СТАТУС + НАПРАВЛЕНИЕ ─────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: canEdit ? _changeStatus : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            statusName,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (canEdit) ...[
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_drop_down,
                                color: statusColor, size: 18),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.direction,
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── НАЗВАНИЕ ─────────────────────────────
              Text(
                p.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),

              if (p.shortDescription.isNotEmpty)
                Text(
                  p.shortDescription,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 20),

              // ── ИНФОРМАЦИОННЫЙ БЛОК ───────────────────
              _infoCard([
                _infoRow(
                  Icons.school_outlined,
                  'Организация',
                  p.schoolName.isNotEmpty
                      ? p.schoolName
                      : 'Не указана',
                ),
                _dividerThin(),
                _infoRow(
                  Icons.person_outlined,
                  'Руководитель',
                  p.supervisorName.isNotEmpty
                      ? p.supervisorName
                      : 'Не указан',
                ),
                _dividerThin(),
                _infoRow(
                  Icons.calendar_today_outlined,
                  'Начало',
                  _dateFormat.format(p.startDate),
                ),
                if (p.endDate != null) ...[
                  _dividerThin(),
                  _infoRow(
                    Icons.event_outlined,
                    'Завершение',
                    _dateFormat.format(p.endDate!),
                  ),
                ],
              ]),
              const SizedBox(height: 20),

              // ── ПОЛНОЕ ОПИСАНИЕ ───────────────────────
              if (p.fullDescription.isNotEmpty) ...[
                _sectionTitle('Описание проекта'),
                const SizedBox(height: 8),
                Text(
                  p.fullDescription,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── УЧАСТНИКИ ─────────────────────────────
              _sectionTitle(
                  'Участники (${p.participants.length})'),
              const SizedBox(height: 8),
              if (p.participants.isEmpty)
                const Text(
                  'Участники не указаны',
                  style: TextStyle(color: Colors.grey),
                )
              else
                Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children:
                    List.generate(p.participants.length, (i) {
                      final participant = p.participants[i];
                      final isLast = i == p.participants.length - 1;
                      return Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1565C0)
                                  .withOpacity(0.12),
                              child: Text(
                                participant.displayName.isNotEmpty
                                    ? participant.displayName[0]
                                    .toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(participant.displayName),
                            subtitle: Text(
                              participant.role == 'author'
                                  ? 'Автор проекта'
                                  : 'Участник',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: participant.role == 'author'
                                ? const Icon(Icons.star,
                                color: Colors.amber, size: 20)
                                : null,
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: Colors.grey.shade200,
                            ),
                        ],
                      );
                    }),
                  ),
                ),
              const SizedBox(height: 20),

              // ── РЕЗУЛЬТАТЫ ────────────────────────────
              if (p.results.isNotEmpty) ...[
                _sectionTitle('Результаты'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Text(
                    p.results,
                    style: const TextStyle(
                        fontSize: 14, height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── НАГРАДЫ ───────────────────────────────
              if (p.awards.isNotEmpty) ...[
                _sectionTitle('Достижения и награды'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Colors.amber, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.awards,
                          style: const TextStyle(
                              fontSize: 14, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── ФАЙЛЫ ─────────────────────────────────
              ProjectFilesWidget(
                projectId: p.id,
                currentUserId: currentUser?.id ?? '',
                canUpload: canUploadFiles,
              ),
              const SizedBox(height: 20),

              // ── МЕТАДАННЫЕ ────────────────────────────
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Создан: ${_dateFormat.format(p.createdAt)}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.update,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Обновлён: ${_dateFormat.format(p.updatedAt)}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Вспомогательные виджеты ───────────────────────────

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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dividerThin() {
    return Divider(height: 1, color: Colors.grey.shade200);
  }
}