import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/project_model.dart';
import '../../services/project_service.dart';
import '../../utils/constants.dart';
import '../../widgets/project_card.dart';
import 'project_detail_screen.dart';
import 'project_form_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final ProjectService _projectService = ProjectService();
  final _searchController = TextEditingController();

  String _selectedDirection = '';
  String _selectedStatus = '';

  List<ProjectModel> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final projects = await _projectService.getProjects(
        direction: _selectedDirection,
        status: _selectedStatus,
        searchQuery: _searchController.text,
      );
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  void _showFilters() {
    // Временные переменные для фильтров внутри диалога
    String tempDirection = _selectedDirection;
    String tempStatus = _selectedStatus;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  Row(
                    children: [
                      const Text(
                        'Фильтры',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
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

                  // Фильтр по направлению
                  const Text(
                    'Направление:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempDirection.isEmpty ? '' : tempDirection,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Все направления'),
                      ),
                      ...AppConstants.directions.map((d) =>
                          DropdownMenuItem(value: d, child: Text(d))),
                    ],
                    onChanged: (v) =>
                        setModalState(() => tempDirection = v ?? ''),
                  ),
                  const SizedBox(height: 16),

                  // Фильтр по статусу
                  const Text(
                    'Статус:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempStatus.isEmpty ? '' : tempStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Все статусы'),
                      ),
                      ...AppConstants.statusNames.entries.map((e) =>
                          DropdownMenuItem(
                              value: e.key, child: Text(e.value))),
                    ],
                    onChanged: (v) =>
                        setModalState(() => tempStatus = v ?? ''),
                  ),
                  const SizedBox(height: 24),

                  // Кнопки
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempDirection = '';
                              tempStatus = '';
                            });
                          },
                          child: const Text('Сбросить'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedDirection = tempDirection;
                              _selectedStatus = tempStatus;
                            });
                            Navigator.pop(context);
                            _loadProjects();
                          },
                          child: const Text('Применить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final role =
        context.watch<AppState>().currentUser?.role ?? 'student';
    final canCreate = role == AppConstants.roleTeacher ||
        role == AppConstants.roleAdmin;

    return Scaffold(
      body: Column(
        children: [
          // ── СТРОКА ПОИСКА ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск проектов...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadProjects();
                        },
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onSubmitted: (_) => _loadProjects(),
                    onChanged: (v) {
                      if (v.isEmpty) _loadProjects();
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Кнопка фильтров с индикатором
                Badge(
                  isLabelVisible: _selectedDirection.isNotEmpty ||
                      _selectedStatus.isNotEmpty,
                  child: IconButton(
                    onPressed: _showFilters,
                    icon: const Icon(Icons.tune),
                    tooltip: 'Фильтры',
                  ),
                ),
              ],
            ),
          ),

          // ── АКТИВНЫЕ ФИЛЬТРЫ (ЧИПЫ) ──────────────────
          if (_selectedDirection.isNotEmpty ||
              _selectedStatus.isNotEmpty)
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                  const Text(
                    'Фильтры: ',
                    style:
                    TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (_selectedDirection.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text(
                          _selectedDirection,
                          style: const TextStyle(fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setState(() => _selectedDirection = '');
                          _loadProjects();
                        },
                        visualDensity: VisualDensity.compact,
                        backgroundColor:
                        const Color(0xFF1565C0).withOpacity(0.1),
                      ),
                    ),
                  if (_selectedStatus.isNotEmpty)
                    Chip(
                      label: Text(
                        AppConstants.statusNames[_selectedStatus] ??
                            _selectedStatus,
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () {
                        setState(() => _selectedStatus = '');
                        _loadProjects();
                      },
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                      const Color(0xFF1565C0).withOpacity(0.1),
                    ),
                ],
              ),
            ),

          // ── СЧЁТЧИК ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
            child: Row(
              children: [
                Text(
                  _isLoading
                      ? 'Загрузка...'
                      : 'Найдено: ${_projects.length}',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13),
                ),
                const Spacer(),
                // Кнопка обновить
                if (!_isLoading)
                  GestureDetector(
                    onTap: _loadProjects,
                    child: const Row(
                      children: [
                        Icon(Icons.refresh,
                            size: 14, color: Colors.grey),
                        SizedBox(width: 2),
                        Text(
                          'Обновить',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── СПИСОК ПРОЕКТОВ ───────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _projects.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open,
                      size: 64,
                      color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _selectedDirection.isNotEmpty ||
                        _selectedStatus.isNotEmpty ||
                        _searchController.text.isNotEmpty
                        ? 'Проекты не найдены'
                        : 'Проектов пока нет',
                    style: const TextStyle(
                        fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedDirection.isNotEmpty ||
                      _selectedStatus.isNotEmpty ||
                      _searchController.text.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedDirection = '';
                          _selectedStatus = '';
                          _searchController.clear();
                        });
                        _loadProjects();
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Сбросить фильтры'),
                    )
                  else if (canCreate)
                    TextButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ProjectFormScreen(),
                          ),
                        );
                        _loadProjects();
                      },
                      icon: const Icon(Icons.add),
                      label:
                      const Text('Создать первый проект'),
                    ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadProjects,
              child: ListView.builder(
                itemCount: _projects.length,
                itemBuilder: (context, index) {
                  final project = _projects[index];
                  return ProjectCard(
                    project: project,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailScreen(
                            projectId: project.id,
                          ),
                        ),
                      );
                      _loadProjects();
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // ── КНОПКА СОЗДАНИЯ (только teacher и admin) ──────
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProjectFormScreen(),
            ),
          );
          _loadProjects();
        },
        icon: const Icon(Icons.add),
        label: const Text('Новый проект'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      )
          : null,
    );
  }
}