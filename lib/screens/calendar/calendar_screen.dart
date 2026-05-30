import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/event_model.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../services/project_service.dart';
import '../../utils/constants.dart';
import '../projects/project_detail_screen.dart';

// ═══════════════════════════════════════════════════════
// КАРТОЧКА МЕРОПРИЯТИЯ
// ═══════════════════════════════════════════════════════

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  final bool isAdmin;
  // ── ИЗМЕНЕНО: canEdit / canDelete вместо isAdminOrTeacher ──
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.isAdmin,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final ProjectService _projectService = ProjectService();
  final EventService _eventService = EventService();

  late EventModel _event;
  List<ProjectModel> _linkedProjects = [];
  bool _isLoadingProjects = true;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _loadLinkedProjects();
  }

  Future<void> _loadLinkedProjects() async {
    setState(() => _isLoadingProjects = true);
    final List<ProjectModel> projects = [];
    for (final pid in _event.linkedProjectIds) {
      final p = await _projectService.getProjectById(pid);
      if (p != null) projects.add(p);
    }
    setState(() {
      _linkedProjects = projects;
      _isLoadingProjects = false;
    });
  }

  // ── Добавление проекта к мероприятию ──────────────────
  Future<void> _addProject() async {
    final allProjects = await _projectService.getProjects();
    final available = allProjects
        .where((p) => !_event.linkedProjectIds.contains(p.id))
        .toList();

    if (!mounted) return;

    final selected = await showDialog<ProjectModel>(
      context: context,
      builder: (context) {
        String search = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = available.where((p) {
              if (search.isEmpty) return true;
              final q = search.toLowerCase();
              return p.title.toLowerCase().contains(q) ||
                  p.schoolName.toLowerCase().contains(q) ||
                  p.supervisorName.toLowerCase().contains(q);
            }).toList();

            return AlertDialog(
              title: const Text('Добавить проект'),
              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Поиск проекта...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setDialogState(() => search = v),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                        child: Text(
                          'Нет доступных проектов',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                          : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final project = filtered[index];
                          return ListTile(
                            contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            title: Text(
                              project.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${project.direction} • ${project.schoolName}',
                              style:
                              const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(
                              Icons.add_circle_outline,
                              color: Color(0xFF1565C0),
                            ),
                            onTap: () =>
                                Navigator.pop(context, project),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      final updatedIds = [..._event.linkedProjectIds, selected.id];
      final updated = _event.copyWith(linkedProjectIds: updatedIds);
      await _eventService.updateEvent(updated);
      setState(() {
        _event = updated;
      });
      _loadLinkedProjects();
    }
  }

  // ── Удаление проекта из мероприятия ───────────────────
  Future<void> _removeProject(String projectId) async {
    final updatedIds =
    _event.linkedProjectIds.where((id) => id != projectId).toList();
    final updated = _event.copyWith(linkedProjectIds: updatedIds);
    await _eventService.updateEvent(updated);
    setState(() {
      _event = updated;
    });
    _loadLinkedProjects();
  }

  Color _eventColor(String type) {
    switch (type) {
      case AppConstants.eventTypeOlympiad:
        return Colors.purple;
      case AppConstants.eventTypeContest:
        return Colors.orange;
      case AppConstants.eventTypeDefense:
        return Colors.blue;
      case AppConstants.eventTypeTrip:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case AppConstants.eventTypeOlympiad:
        return Icons.emoji_events_outlined;
      case AppConstants.eventTypeContest:
        return Icons.workspace_premium_outlined;
      case AppConstants.eventTypeDefense:
        return Icons.school_outlined;
      case AppConstants.eventTypeTrip:
        return Icons.directions_bus_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(_event.type);
    final typeName = AppConstants.eventTypeNames[_event.type] ?? _event.type;
    final dateFormat = DateFormat('dd MMMM yyyy', 'ru');
    final dateFormatShort = DateFormat('dd.MM.yyyy');

    return Scaffold(
      // ── AppBar ──────────────────────────────────────────
      appBar: AppBar(
        title: const Text('Карточка мероприятия'),
        actions: [
          // ── ИЗМЕНЕНО: используем canEdit вместо isAdminOrTeacher ──
          if (widget.canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Редактировать',
              onPressed: () {
                Navigator.pop(context);
                widget.onEdit();
              },
            ),
          // ── ИЗМЕНЕНО: используем canDelete вместо isAdmin ──
          if (widget.canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Удалить',
              onPressed: () {
                Navigator.pop(context);
                widget.onDelete();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Цветная шапка с иконкой и типом ──────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withOpacity(0.75),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_eventIcon(_event.type),
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          typeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(_event.eventDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Тело карточки ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── НОВОЕ: Руководитель + Даты и время ────────
                  _infoCard([
                    // ── НОВОЕ: Руководитель перед «Начало» ──
                    if (_event.supervisorName.isNotEmpty) ...[
                      _infoRow(
                        Icons.person_outlined,
                        'Руководитель',
                        _event.supervisorName,
                      ),
                      _dividerThin(),
                    ],
                    _infoRow(
                      Icons.play_circle_outline,
                      'Начало',
                      dateFormatShort.format(_event.eventDate),
                    ),
                    if (_event.startTime != null &&
                        _event.startTime!.isNotEmpty) ...[
                      _dividerThin(),
                      _infoRow(
                        Icons.access_time_outlined,
                        'Время начала',
                        _event.startTime!,
                      ),
                    ],
                    if (_event.endDate != null) ...[
                      _dividerThin(),
                      _infoRow(
                        Icons.stop_circle_outlined,
                        'Завершение',
                        dateFormatShort.format(_event.endDate!),
                      ),
                    ],
                    if (_event.endTime != null &&
                        _event.endTime!.isNotEmpty) ...[
                      _dividerThin(),
                      _infoRow(
                        Icons.access_time_filled_outlined,
                        'Время завершения',
                        _event.endTime!,
                      ),
                    ],
                  ]),
                  const SizedBox(height: 20),

                  // ── Описание мероприятия ───────────────────────
                  if (_event.description.isNotEmpty) ...[
                    _sectionTitle('Описание мероприятия'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        _event.description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Привязанные проекты ─────────────────────
                  Row(
                    children: [
                      _sectionTitle(
                          'Проекты (${_linkedProjects.length})'),
                      const Spacer(),
                      // ── ИЗМЕНЕНО: canEdit вместо isAdminOrTeacher ──
                      if (widget.canEdit)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: Color(0xFF1565C0)),
                          tooltip: 'Добавить проект',
                          onPressed: _addProject,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_isLoadingProjects)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_linkedProjects.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Text(
                        'Проекты не привязаны',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
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
                        children: List.generate(
                            _linkedProjects.length, (i) {
                          final project = _linkedProjects[i];
                          final isLast =
                              i == _linkedProjects.length - 1;
                          final statusName =
                              AppConstants.statusNames[project.status] ??
                                  project.status;
                          return Column(
                            children: [
                              ListTile(
                                contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor:
                                  const Color(0xFF1565C0)
                                      .withOpacity(0.12),
                                  child: const Icon(
                                    Icons.assignment_outlined,
                                    color: Color(0xFF1565C0),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  project.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '$statusName • ${project.direction}',
                                  style:
                                  const TextStyle(fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ── ИЗМЕНЕНО: canEdit ──
                                    if (widget.canEdit)
                                      IconButton(
                                        icon: const Icon(
                                          Icons
                                              .remove_circle_outline,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        tooltip: 'Убрать проект',
                                        onPressed: () =>
                                            _removeProject(
                                                project.id),
                                      ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProjectDetailScreen(
                                            projectId: project.id,
                                          ),
                                    ),
                                  );
                                },
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

                  // ── Кнопка удаления ───────────────────────────
                  // ── ИЗМЕНЕНО: canDelete вместо isAdmin ──
                  if (widget.canDelete) ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onDelete();
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Удалить мероприятие'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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

// ═══════════════════════════════════════════════════════
// ЭКРАН КАЛЕНДАРЯ
// ═══════════════════════════════════════════════════════

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService(); // ← НОВОЕ: для выбора руководителя

  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDay;
  List<EventModel> _events = [];
  bool _isLoading = true;

  late DateFormat _dateFormat;
  late DateFormat _timeFormat;

  @override
  void initState() {
    super.initState();
    _dateFormat = DateFormat('dd.MM.yyyy');
    _timeFormat = DateFormat('dd MMMM', 'ru');
    _loadEvents();
  }

  static const List<String> _monthNames = [
    'ЯНВАРЬ', 'ФЕВРАЛЬ', 'МАРТ', 'АПРЕЛЬ',
    'МАЙ', 'ИЮНЬ', 'ИЮЛЬ', 'АВГУСТ',
    'СЕНТЯБРЬ', 'ОКТЯБРЬ', 'НОЯБРЬ', 'ДЕКАБРЬ',
  ];

  String _formatMonth(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.year}';
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final events = await _eventService.getEventsByMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    setState(() {
      _events = events;
      _isLoading = false;
    });
  }

  List<EventModel> _eventsForDay(DateTime day) {
    return _events.where((e) {
      return e.eventDate.year == day.year &&
          e.eventDate.month == day.month &&
          e.eventDate.day == day.day;
    }).toList();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDay = null;
    });
    _loadEvents();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDay = null;
    });
    _loadEvents();
  }

  // ── Вспомогательный метод для выбора времени ─────────
  Future<String?> _pickTime(
      BuildContext context, String? currentTime) async {
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    if (currentTime != null && currentTime.contains(':')) {
      final parts = currentTime.split(':');
      initial = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  // ══════════════════════════════════════════════════════
  // ДИАЛОГ СОЗДАНИЯ / РЕДАКТИРОВАНИЯ МЕРОПРИЯТИЯ
  // ══════════════════════════════════════════════════════
  void _showEventDialog({EventModel? existingEvent}) {
    final user = context.read<AppState>().currentUser;
    final isEditing = existingEvent != null;

    final titleController = TextEditingController(
      text: existingEvent?.title ?? '',
    );
    final descController = TextEditingController(
      text: existingEvent?.description ?? '',
    );

    DateTime startDate =
        existingEvent?.eventDate ?? (_selectedDay ?? DateTime.now());
    DateTime? endDate = existingEvent?.endDate;
    String? startTime = existingEvent?.startTime;
    String? endTime = existingEvent?.endTime;
    String selectedType =
        existingEvent?.type ?? AppConstants.eventTypeContest;

    // ── НОВОЕ: Руководитель мероприятия ────────────────
    String supervisorId = existingEvent?.supervisorId ?? user?.id ?? '';
    String supervisorName =
        existingEvent?.supervisorName ?? user?.displayName ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Редактировать' : 'Новое мероприятие',
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Название *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),

                      const Text(
                        'Тип мероприятия:',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: AppConstants.eventTypeNames.entries
                            .map((entry) {
                          final isSelected = selectedType == entry.key;
                          return GestureDetector(
                            onTap: () => setDialogState(
                                    () => selectedType = entry.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1565C0)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1565C0)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // ══════════════════════════════════════
                      // НОВОЕ: Руководитель мероприятия
                      // ══════════════════════════════════════
                      const Text(
                        'Руководитель:',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          // Загружаем всех пользователей
                          final allUsers =
                          await _authService.getAllUsers();
                          // Фильтруем — только руководители и админы
                          final teachers = allUsers
                              .where((u) =>
                          u.role == AppConstants.roleTeacher ||
                              u.role == AppConstants.roleAdmin)
                              .toList();

                          if (!context.mounted) return;

                          final selected =
                          await showDialog<UserModel>(
                            context: context,
                            builder: (ctx) {
                              String search = '';
                              return StatefulBuilder(
                                builder: (ctx, setDlgState) {
                                  final filtered =
                                  teachers.where((u) {
                                    if (search.isEmpty) return true;
                                    final q = search.toLowerCase();
                                    return u.displayName
                                        .toLowerCase()
                                        .contains(q) ||
                                        u.email
                                            .toLowerCase()
                                            .contains(q);
                                  }).toList();
                                  return AlertDialog(
                                    title: const Text(
                                        'Выбрать руководителя'),
                                    contentPadding:
                                    const EdgeInsets.fromLTRB(
                                        16, 12, 16, 0),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      height: 350,
                                      child: Column(
                                        children: [
                                          TextField(
                                            decoration:
                                            const InputDecoration(
                                              hintText:
                                              'Поиск...',
                                              prefixIcon: Icon(
                                                  Icons.search),
                                              border:
                                              OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            onChanged: (v) =>
                                                setDlgState(() =>
                                                search = v),
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: filtered.isEmpty
                                                ? const Center(
                                              child: Text(
                                                'Не найдено',
                                                style: TextStyle(
                                                    color: Colors
                                                        .grey),
                                              ),
                                            )
                                                : ListView.builder(
                                              itemCount:
                                              filtered
                                                  .length,
                                              itemBuilder:
                                                  (ctx,
                                                  idx) {
                                                final u =
                                                filtered[
                                                idx];
                                                return ListTile(
                                                  leading:
                                                  CircleAvatar(
                                                    backgroundColor: const Color(
                                                        0xFF1565C0)
                                                        .withOpacity(
                                                        0.15),
                                                    child:
                                                    Text(
                                                      u.displayName.isNotEmpty
                                                          ? u.displayName[0].toUpperCase()
                                                          : '?',
                                                      style:
                                                      const TextStyle(
                                                        color:
                                                        Color(0xFF1565C0),
                                                        fontWeight:
                                                        FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  title: Text(
                                                      u.displayName),
                                                  subtitle:
                                                  Text(
                                                    u.email,
                                                    style: const TextStyle(
                                                        fontSize:
                                                        11),
                                                  ),
                                                  onTap: () =>
                                                      Navigator.pop(
                                                          ctx,
                                                          u),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx),
                                        child:
                                        const Text('Отмена'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );

                          if (selected != null) {
                            setDialogState(() {
                              supervisorId = selected.id;
                              supervisorName = selected.displayName;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outlined,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  supervisorName.isNotEmpty
                                      ? supervisorName
                                      : 'Не выбран',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: supervisorName.isNotEmpty
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              if (supervisorName.isNotEmpty)
                                GestureDetector(
                                  onTap: () => setDialogState(() {
                                    supervisorId = '';
                                    supervisorName = '';
                                  }),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Дата начала
                      const Text(
                        'Дата начала:',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => startDate = picked);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border:
                            Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.play_circle_outline,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                _dateFormat.format(startDate),
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Время начала
                      const Text(
                        'Время начала (необязательно):',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final picked =
                          await _pickTime(context, startTime);
                          if (picked != null) {
                            setDialogState(() => startTime = picked);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border:
                            Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_outlined,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                startTime ?? 'Не указано',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: startTime != null
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                              if (startTime != null) ...[
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setDialogState(
                                          () => startTime = null),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Дата завершения
                      const Text(
                        'Дата завершения (необязательно):',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? startDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => endDate = picked);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border:
                            Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stop_circle_outlined,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                endDate != null
                                    ? _dateFormat.format(endDate!)
                                    : 'Не указана',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: endDate != null
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                              if (endDate != null) ...[
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setDialogState(
                                          () => endDate = null),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Время завершения
                      const Text(
                        'Время завершения (необязательно):',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final picked =
                          await _pickTime(context, endTime);
                          if (picked != null) {
                            setDialogState(() => endTime = picked);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border:
                            Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                  Icons.access_time_filled_outlined,
                                  size: 18,
                                  color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                endTime ?? 'Не указано',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: endTime != null
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                              if (endTime != null) ...[
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setDialogState(
                                          () => endTime = null),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Введите название'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (isEditing) {
                      final updated = EventModel(
                        id: existingEvent.id,
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        eventDate: startDate,
                        endDate: endDate,
                        startTime: startTime,
                        endTime: endTime,
                        type: selectedType,
                        linkedProjectIds:
                        existingEvent.linkedProjectIds,
                        createdBy: existingEvent.createdBy,
                        // ── НОВОЕ: руководитель ──
                        supervisorId: supervisorId,
                        supervisorName: supervisorName,
                      );
                      await _eventService.updateEvent(updated);
                    } else {
                      final event = EventModel(
                        id: '',
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        eventDate: startDate,
                        endDate: endDate,
                        startTime: startTime,
                        endTime: endTime,
                        type: selectedType,
                        createdBy: user?.id ?? '',
                        // ── НОВОЕ: руководитель ──
                        supervisorId: supervisorId,
                        supervisorName: supervisorName,
                      );
                      await _eventService.createEvent(event);
                    }

                    if (context.mounted) Navigator.pop(context);
                    _loadEvents();
                  },
                  child: Text(isEditing ? 'Сохранить' : 'Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteEvent(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить мероприятие?'),
        content: Text('«${event.title}» будет удалено.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _eventService.deleteEvent(event.id);
              _loadEvents();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // НОВОЕ: Вычисление прав canEdit / canDelete
  // Руководитель может редактировать / удалять только
  // СВОИ мероприятия (где он createdBy или supervisorId)
  // ══════════════════════════════════════════════════════
  bool _canEditEvent(EventModel event, String? userId, String? role) {
    if (role == AppConstants.roleAdmin) return true;
    if (role == AppConstants.roleTeacher) {
      return event.createdBy == userId || event.supervisorId == userId;
    }
    return false;
  }

  bool _canDeleteEvent(EventModel event, String? userId, String? role) {
    if (role == AppConstants.roleAdmin) return true;
    if (role == AppConstants.roleTeacher) {
      return event.createdBy == userId || event.supervisorId == userId;
    }
    return false;
  }

  void _openEventDetail(EventModel event, String? userId, String? role) {
    final isAdmin = role == AppConstants.roleAdmin;
    final canEdit = _canEditEvent(event, userId, role);
    final canDelete = _canDeleteEvent(event, userId, role);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          event: event,
          isAdmin: isAdmin,
          canEdit: canEdit,
          canDelete: canDelete,
          onEdit: () => _showEventDialog(existingEvent: event),
          onDelete: () => _deleteEvent(event),
        ),
      ),
    ).then((_) => _loadEvents());
  }

  Color _eventColor(String type) {
    switch (type) {
      case AppConstants.eventTypeOlympiad:
        return Colors.purple;
      case AppConstants.eventTypeContest:
        return Colors.orange;
      case AppConstants.eventTypeDefense:
        return Colors.blue;
      case AppConstants.eventTypeTrip:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case AppConstants.eventTypeOlympiad:
        return Icons.emoji_events_outlined;
      case AppConstants.eventTypeContest:
        return Icons.workspace_premium_outlined;
      case AppConstants.eventTypeDefense:
        return Icons.school_outlined;
      case AppConstants.eventTypeTrip:
        return Icons.directions_bus_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    final role = user?.role;
    final userId = user?.id;
    final isAdminOrTeacher = role == AppConstants.roleAdmin ||
        role == AppConstants.roleTeacher;

    return Scaffold(
      body: Column(
        children: [
          // Заголовок месяца
          Container(
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon:
                  const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: _previousMonth,
                ),
                Text(
                  _formatMonth(_currentMonth),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: Colors.white),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Сетка календаря
          Container(
            color: const Color(0xFF1565C0).withOpacity(0.05),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  child: Row(
                    children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
                        .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: (day == 'Сб' || day == 'Вс')
                                ? Colors.red.shade300
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ))
                        .toList(),
                  ),
                ),
                _buildCalendarGrid(),
              ],
            ),
          ),

          const Divider(height: 1),

          // Список мероприятий
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildEventsList(userId, role),
          ),
        ],
      ),
      floatingActionButton: isAdminOrTeacher
          ? FloatingActionButton.extended(
        onPressed: () => _showEventDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Мероприятие'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      )
          : null,
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    int startWeekday = firstDay.weekday - 1;
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    final today = DateTime.now();
    final List<Widget> dayCells = [];

    for (int i = 0; i < startWeekday; i++) {
      dayCells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date =
      DateTime(_currentMonth.year, _currentMonth.month, day);
      final dayEvents = _eventsForDay(date);
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isSelected = _selectedDay != null &&
          date.year == _selectedDay!.year &&
          date.month == _selectedDay!.month &&
          date.day == _selectedDay!.day;

      dayCells.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = isSelected ? null : date;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1565C0)
                  : isToday
                  ? const Color(0xFF1565C0).withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(
                  color: const Color(0xFF1565C0), width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                    isToday ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : isToday
                        ? const Color(0xFF1565C0)
                        : Colors.black87,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: dayEvents
                      .take(3)
                      .map((e) => Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(
                        top: 1, left: 1, right: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : _eventColor(e.type),
                      shape: BoxShape.circle,
                    ),
                  ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      children: dayCells,
    );
  }

  // ══════════════════════════════════════════════════════
  // СПИСОК МЕРОПРИЯТИЙ (ОБНОВЛЕНО для прав доступа)
  // ══════════════════════════════════════════════════════
  Widget _buildEventsList(String? userId, String? role) {
    final List<EventModel> displayEvents;
    String headerText;

    if (_selectedDay != null) {
      displayEvents = _eventsForDay(_selectedDay!);
      headerText =
      'Мероприятия на ${_timeFormat.format(_selectedDay!)}';
    } else {
      displayEvents = _events;
      headerText = 'Все мероприятия месяца';
    }

    final isAdmin = role == AppConstants.roleAdmin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  headerText,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              if (_selectedDay != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Все мероприятия месяца',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (displayEvents.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_outlined,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Мероприятий нет',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
              itemCount: displayEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final event = displayEvents[index];
                final color = _eventColor(event.type);
                final typeName =
                    AppConstants.eventTypeNames[event.type] ??
                        event.type;

                // ── ИЗМЕНЕНО: вычисляем права для каждого элемента ──
                final canDeleteThis =
                _canDeleteEvent(event, userId, role);

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        _openEventDetail(event, userId, role),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: CircleAvatar(
                              backgroundColor:
                              color.withOpacity(0.15),
                              radius: 20,
                              child: Icon(
                                _eventIcon(event.type),
                                color: color,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  typeName,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                        Icons.play_circle_outline,
                                        size: 12,
                                        color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      _dateFormat
                                          .format(event.eventDate),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey),
                                    ),
                                    if (event.startTime != null &&
                                        event.startTime!
                                            .isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                          Icons
                                              .access_time_outlined,
                                          size: 12,
                                          color: Colors.grey),
                                      const SizedBox(width: 2),
                                      Text(
                                        event.startTime!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ],
                                ),
                                if (event.endDate != null ||
                                    (event.endTime != null &&
                                        event.endTime!
                                            .isNotEmpty)) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (event.endDate !=
                                          null) ...[
                                        const Icon(
                                            Icons
                                                .stop_circle_outlined,
                                            size: 12,
                                            color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          _dateFormat.format(
                                              event.endDate!),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey),
                                        ),
                                      ],
                                      if (event.endTime != null &&
                                          event.endTime!
                                              .isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                            Icons
                                                .access_time_filled_outlined,
                                            size: 12,
                                            color: Colors.grey),
                                        const SizedBox(width: 2),
                                        Text(
                                          event.endTime!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                                if (event.description
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    event.description,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment:
                            MainAxisAlignment.start,
                            children: [
                              // ── ИЗМЕНЕНО: canDeleteThis ──
                              if (canDeleteThis)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  tooltip: 'Удалить',
                                  onPressed: () =>
                                      _deleteEvent(event),
                                  constraints:
                                  const BoxConstraints(),
                                  padding:
                                  const EdgeInsets.all(4),
                                ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
