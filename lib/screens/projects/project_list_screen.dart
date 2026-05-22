import 'package:flutter/material.dart';
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

  // Контроллер строки поиска
  final _searchController = TextEditingController();

  // Текущие фильтры
  String _selectedDirection = '';
  String _selectedStatus = '';

  // Список проектов
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

  // Загрузка проектов с учётом фильтров
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

  // Открыть панель фильтров
  void _showFilters() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Фильтры',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Фильтр по направлению
                  const Text('Направление:',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedDirection.isEmpty
                        ? null
                        : _selectedDirection,
                    hint: const Text('Все направления'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Все направления'),
                      ),
                      ...AppConstants.directions.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(d),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setModalState(() =>
                      _selectedDirection = value ?? '');
                    },
                  ),
                  const SizedBox(height: 16),

                  // Фильтр по статусу
                  const Text('Статус:',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus.isEmpty
                        ? null
                        : _selectedStatus,
                    hint: const Text('Все статусы'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Все статусы'),
                      ),
                      ...AppConstants.statusNames.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setModalState(() =>
                      _selectedStatus = value ?? '');
                    },
                  ),
                  const SizedBox(height: 24),

                  // Кнопки
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedDirection = '';
                              _selectedStatus = '';
                            });
                          },
                          child: const Text('Сбросить'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
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
    return Scaffold(
      body: Column(
        children: [
          // Строка поиска
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
                  ),
                ),
                const SizedBox(width: 8),
                // Кнопка фильтров
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

          // Активные фильтры (чипы)
          if (_selectedDirection.isNotEmpty || _selectedStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_selectedDirection.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_selectedDirection),
                        selected: true,
                        onSelected: (_) {
                          setState(() => _selectedDirection = '');
                          _loadProjects();
                        },
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setState(() => _selectedDirection = '');
                          _loadProjects();
                        },
                      ),
                    ),
                  if (_selectedStatus.isNotEmpty)
                    FilterChip(
                      label: Text(
                          AppConstants.statusNames[_selectedStatus] ??
                              _selectedStatus),
                      selected: true,
                      onSelected: (_) {
                        setState(() => _selectedStatus = '');
                        _loadProjects();
                      },
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () {
                        setState(() => _selectedStatus = '');
                        _loadProjects();
                      },
                    ),
                ],
              ),
            ),

          // Счётчик результатов
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Text(
                  'Найдено: ${_projects.length}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Список проектов
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _projects.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Проекты не найдены',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
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
                    child: const Text('Создать первый проект'),
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
      // Кнопка создания проекта
      floatingActionButton: FloatingActionButton.extended(
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
      ),
    );
  }
}