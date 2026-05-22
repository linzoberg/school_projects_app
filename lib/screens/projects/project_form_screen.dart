import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/project_model.dart';
import '../../services/project_service.dart';
import '../../utils/constants.dart';

class ProjectFormScreen extends StatefulWidget {
  final ProjectModel? project;

  const ProjectFormScreen({super.key, this.project});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProjectService _projectService = ProjectService();

  // Контроллеры полей
  final _titleController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _fullDescController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _resultsController = TextEditingController();
  final _awardsController = TextEditingController();

  // Выбранные значения
  String _selectedDirection = AppConstants.directions.first;
  String _selectedStatus = AppConstants.statusIdea;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  // Участники
  final List<ProjectParticipant> _participants = [];
  final _participantNameController = TextEditingController();

  bool _isLoading = false;
  bool get _isEditing => widget.project != null;

  final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _fillFormIfEditing();
  }

  // Заполняем форму при редактировании
  void _fillFormIfEditing() {
    final p = widget.project;
    if (p == null) {
      // При создании — добавляем текущего пользователя как автора
      final user = context.read<AppState>().currentUser;
      if (user != null) {
        _participants.add(ProjectParticipant(
          userId: user.id,
          displayName: user.displayName,
          role: 'author',
        ));
      }
      return;
    }

    _titleController.text = p.title;
    _shortDescController.text = p.shortDescription;
    _fullDescController.text = p.fullDescription;
    _schoolNameController.text = p.schoolName;
    _resultsController.text = p.results;
    _awardsController.text = p.awards;
    _selectedDirection = p.direction;
    _selectedStatus = p.status;
    _startDate = p.startDate;
    _endDate = p.endDate;
    _participants.addAll(p.participants);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescController.dispose();
    _fullDescController.dispose();
    _schoolNameController.dispose();
    _resultsController.dispose();
    _awardsController.dispose();
    _participantNameController.dispose();
    super.dispose();
  }

  // Выбор даты
  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ru'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Добавить участника
  void _addParticipant() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить участника'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _participantNameController,
              decoration: const InputDecoration(
                labelText: 'Имя участника',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _participantNameController.clear();
              Navigator.pop(context);
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _participantNameController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _participants.add(ProjectParticipant(
                    userId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                    displayName: name,
                    role: 'member',
                  ));
                });
                _participantNameController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  // Удалить участника
  void _removeParticipant(int index) {
    setState(() => _participants.removeAt(index));
  }

  // Сохранить проект
  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = context.read<AppState>().currentUser;

    // Список id участников для быстрого поиска
    final participantIds = _participants.map((p) => p.userId).toList();

    try {
      if (_isEditing) {
        // Редактирование
        final updated = ProjectModel(
          id: widget.project!.id,
          title: _titleController.text.trim(),
          shortDescription: _shortDescController.text.trim(),
          fullDescription: _fullDescController.text.trim(),
          direction: _selectedDirection,
          status: _selectedStatus,
          startDate: _startDate,
          endDate: _endDate,
          schoolId: widget.project!.schoolId,
          schoolName: _schoolNameController.text.trim(),
          supervisorId: widget.project!.supervisorId,
          supervisorName: widget.project!.supervisorName,
          participants: _participants,
          participantIds: participantIds,
          results: _resultsController.text.trim(),
          awards: _awardsController.text.trim(),
          createdAt: widget.project!.createdAt,
          updatedAt: DateTime.now(),
        );
        await _projectService.updateProject(updated);
      } else {
        // Создание
        final newProject = ProjectModel(
          id: '',
          title: _titleController.text.trim(),
          shortDescription: _shortDescController.text.trim(),
          fullDescription: _fullDescController.text.trim(),
          direction: _selectedDirection,
          status: _selectedStatus,
          startDate: _startDate,
          endDate: _endDate,
          schoolId: '',
          schoolName: _schoolNameController.text.trim(),
          supervisorId: user?.id ?? '',
          supervisorName: user?.displayName ?? '',
          participants: _participants,
          participantIds: participantIds,
          results: _resultsController.text.trim(),
          awards: _awardsController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _projectService.createProject(newProject);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать проект' : 'Новый проект'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProject,
              child: const Text(
                'Сохранить',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Сохранение...'),
          ],
        ),
      )
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── ОСНОВНАЯ ИНФОРМАЦИЯ ──────────────────
              _sectionHeader('Основная информация'),
              const SizedBox(height: 12),

              // Название
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название проекта *',
                  prefixIcon: Icon(Icons.title),
                ),
                maxLength: 120,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Введите название проекта';
                  }
                  if (v.trim().length < 3) {
                    return 'Название слишком короткое';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Краткое описание
              TextFormField(
                controller: _shortDescController,
                decoration: const InputDecoration(
                  labelText: 'Краткое описание *',
                  prefixIcon: Icon(Icons.short_text),
                  hintText: '1-2 предложения о сути проекта',
                ),
                maxLines: 2,
                maxLength: 200,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Введите краткое описание';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Направление
              DropdownButtonFormField<String>(
                value: _selectedDirection,
                decoration: const InputDecoration(
                  labelText: 'Направление *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: AppConstants.directions.map((d) {
                  return DropdownMenuItem(
                    value: d,
                    child: Text(d),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => _selectedDirection = v!),
              ),
              const SizedBox(height: 12),

              // Статус
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Статус',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: AppConstants.statusNames.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => _selectedStatus = v!),
              ),
              const SizedBox(height: 24),

              // ── ОРГАНИЗАЦИЯ И СРОКИ ──────────────────
              _sectionHeader('Организация и сроки'),
              const SizedBox(height: 12),

              // Школа/организация
              TextFormField(
                controller: _schoolNameController,
                decoration: const InputDecoration(
                  labelText: 'Образовательная организация',
                  prefixIcon: Icon(Icons.school_outlined),
                  hintText: 'МАОУ СОШ №...',
                ),
              ),
              const SizedBox(height: 12),

              // Даты
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isStart: true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Дата начала',
                          prefixIcon:
                          Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _dateFormat.format(_startDate),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isStart: false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Дата завершения',
                          prefixIcon:
                          const Icon(Icons.event_outlined),
                          suffixIcon: _endDate != null
                              ? IconButton(
                            icon: const Icon(Icons.clear,
                                size: 18),
                            onPressed: () => setState(
                                    () => _endDate = null),
                          )
                              : null,
                        ),
                        child: Text(
                          _endDate != null
                              ? _dateFormat.format(_endDate!)
                              : 'Не указана',
                          style: TextStyle(
                            fontSize: 15,
                            color: _endDate != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── ОПИСАНИЕ ─────────────────────────────
              _sectionHeader('Подробное описание'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _fullDescController,
                decoration: const InputDecoration(
                  labelText: 'Полное описание проекта',
                  hintText:
                  'Цели, задачи, методы исследования, актуальность...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
                maxLength: 2000,
              ),
              const SizedBox(height: 24),

              // ── УЧАСТНИКИ ────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionHeader(
                      'Участники (${_participants.length})'),
                  TextButton.icon(
                    onPressed: _addParticipant,
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Добавить'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_participants.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Участники не добавлены',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...List.generate(_participants.length, (index) {
                  final p = _participants[index];
                  return Card(
                    elevation: 0,
                    color: Colors.grey.shade50,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1565C0)
                            .withOpacity(0.15),
                        child: Text(
                          p.displayName.isNotEmpty
                              ? p.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Color(0xFF1565C0)),
                        ),
                      ),
                      title: Text(p.displayName),
                      subtitle: Text(
                        p.role == 'author' ? 'Автор' : 'Участник',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: p.role != 'author'
                          ? IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.red),
                        onPressed: () =>
                            _removeParticipant(index),
                      )
                          : const Icon(Icons.star,
                          color: Colors.amber, size: 18),
                    ),
                  );
                }),
              const SizedBox(height: 24),

              // ── РЕЗУЛЬТАТЫ И НАГРАДЫ ─────────────────
              _sectionHeader('Результаты и достижения'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _resultsController,
                decoration: const InputDecoration(
                  labelText: 'Результаты работы',
                  prefixIcon: Icon(Icons.assignment_turned_in_outlined),
                  hintText: 'Что было достигнуто, выводы...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _awardsController,
                decoration: const InputDecoration(
                  labelText: 'Награды и призовые места',
                  prefixIcon: Icon(Icons.emoji_events_outlined),
                  hintText:
                  'Например: 1 место на региональной олимпиаде',
                ),
              ),
              const SizedBox(height: 32),

              // Кнопка сохранения
              ElevatedButton.icon(
                onPressed: _saveProject,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _isEditing
                      ? 'Сохранить изменения'
                      : 'Создать проект',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1565C0),
      ),
    );
  }
}