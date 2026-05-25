import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/project_model.dart';
import '../../services/project_service.dart';
import '../../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProjectService _projectService = ProjectService();
  List<ProjectModel> _myProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyProjects();
  }

  Future<void> _loadMyProjects() async {
    final user = context.read<AppState>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    final projects = await _projectService.getProjectsByUser(user.id);
    setState(() {
      _myProjects = projects;
      _isLoading = false;
    });
  }

  // Диалог редактирования имени
  void _editDisplayName() {
    final appState = context.read<AppState>();
    final controller = TextEditingController(
      text: appState.currentUser?.displayName ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить имя'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Имя и фамилия',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(context);

              final user = appState.currentUser;
              if (user == null) return;
              final updated = user.copyWith(displayName: newName);
              await context
                  .read<AppState>()
                  .updateCurrentUserProfile(updated);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

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
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final roleName = AppConstants.roleNames[user.role] ?? user.role;

    return RefreshIndicator(
      onRefresh: _loadMyProjects,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── КАРТОЧКА ПРОФИЛЯ ─────────────────────
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Аватар
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                      const Color(0xFF1565C0).withOpacity(0.15),
                      child: Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Имя
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: Colors.grey),
                          onPressed: _editDisplayName,
                          tooltip: 'Изменить имя',
                        ),
                      ],
                    ),

                    // Email
                    Text(
                      user.email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),

                    // Роль
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        roleName,
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── МОИ ПРОЕКТЫ ──────────────────────────
            Row(
              children: [
                const Text(
                  'Мои проекты',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 8),
                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_myProjects.length}',
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoading)
              const CircularProgressIndicator()
            else if (_myProjects.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.folder_open,
                        size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Проектов пока нет',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ..._myProjects.map((p) {
                final statusName =
                    AppConstants.statusNames[p.status] ?? p.status;
                final statusColor = _statusColor(p.status);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      statusColor.withOpacity(0.15),
                      child: Icon(Icons.folder,
                          color: statusColor, size: 20),
                    ),
                    title: Text(
                      p.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '$statusName • ${p.direction}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: Colors.grey),
                  ),
                );
              }),

            const SizedBox(height: 24),

            // ── КНОПКА ВЫЙТИ ─────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => appState.logout(),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Выйти из аккаунта',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}