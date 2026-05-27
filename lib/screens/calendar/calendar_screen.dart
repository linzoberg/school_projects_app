import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../utils/constants.dart';

// ═══════════════════════════════════════════════════════
// КАРТОЧКА МЕРОПРИЯТИЯ
// ═══════════════════════════════════════════════════════
class EventDetailScreen extends StatelessWidget {
  final EventModel event;
  final bool isAdmin;
  final bool isAdminOrTeacher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.isAdmin,
    required this.isAdminOrTeacher,
    required this.onEdit,
    required this.onDelete,
  });

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
    final color = _eventColor(event.type);
    final typeName = AppConstants.eventTypeNames[event.type] ?? event.type;
    final dateFormat = DateFormat('dd MMMM yyyy', 'ru');
    final dateFormatShort = DateFormat('dd.MM.yyyy');

    return Scaffold(
      // ── AppBar ──────────────────────────────────────────
      appBar: AppBar(
        title: const Text('Карточка мероприятия'),
        actions: [
          // Кнопка редактирования в AppBar остаётся (для удобства)
          if (isAdminOrTeacher)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Редактировать',
              onPressed: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Удалить',
              onPressed: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Цветная шапка с иконкой и типом ────────────
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
                  // Тип мероприятия — чип
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
                        Icon(_eventIcon(event.type),
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
                  // Название
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Дата начала в шапке
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(event.eventDate),
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
                  // ────────────────────────────────────────────
                  // ПРАВКА 1: вместо «Дата», «Тип», «Создал»
                  //           теперь «Начало» и «Завершение»
                  //           (аналогично Карточке проекта)
                  // ────────────────────────────────────────────
                  _infoCard([
                    _infoRow(
                      Icons.play_circle_outline,
                      'Начало',
                      dateFormatShort.format(event.eventDate),
                    ),
                    if (event.endDate != null) ...[
                      _dividerThin(),
                      _infoRow(
                        Icons.stop_circle_outlined,
                        'Завершение',
                        dateFormatShort.format(event.endDate!),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 20),

                  // Описание
                  if (event.description.isNotEmpty) ...[
                    _sectionTitle('Описание'),
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
                        event.description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ────────────────────────────────────────────
                  // ПРАВКА 2: кнопка «Редактировать» внизу
                  //           УДАЛЕНА (блок if (isAdminOrTeacher)
                  //           с OutlinedButton.icon убран полностью)
                  // ────────────────────────────────────────────

                  // Только кнопка удаления остаётся (если Admin)
                  if (isAdmin) ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete();
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
            width: 80,
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
    'ЯНВАРЬ', 'ФЕВРАЛЬ', 'МАРТ', 'АПРЕЛЬ', 'МАЙ', 'ИЮНЬ',
    'ИЮЛЬ', 'АВГУСТ', 'СЕНТЯБРЬ', 'ОКТЯБРЬ', 'НОЯБРЬ', 'ДЕКАБРЬ',
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
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDay = null;
    });
    _loadEvents();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDay = null;
    });
    _loadEvents();
  }

  // ── ДИАЛОГ СОЗДАНИЯ / РЕДАКТИРОВАНИЯ ─────────────────
  void _showEventDialog({EventModel? existingEvent}) {
    final user = context.read<AppState>().currentUser;
    final isEditing = existingEvent != null;

    final titleController = TextEditingController(
      text: existingEvent?.title ?? '',
    );
    final descController = TextEditingController(
      text: existingEvent?.description ?? '',
    );

    // startDate — дата начала
    DateTime startDate =
        existingEvent?.eventDate ?? (_selectedDay ?? DateTime.now());
    // endDate — дата завершения (может быть null)
    DateTime? endDate = existingEvent?.endDate;

    String selectedType =
        existingEvent?.type ?? AppConstants.eventTypeContest;

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
                              const Icon(
                                Icons.play_circle_outline,
                                size: 18,
                                color: Colors.grey,
                              ),
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
                              const Icon(
                                Icons.stop_circle_outlined,
                                size: 18,
                                color: Colors.grey,
                              ),
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
                        endDate: endDate,       // ← НОВОЕ
                        type: selectedType,
                        createdBy: existingEvent.createdBy,
                      );
                      await _eventService.updateEvent(updated);
                    } else {
                      final event = EventModel(
                        id: '',
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        eventDate: startDate,
                        endDate: endDate,       // ← НОВОЕ
                        type: selectedType,
                        createdBy: user?.id ?? '',
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

  void _openEventDetail(
      EventModel event, bool isAdminOrTeacher, bool isAdmin) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          event: event,
          isAdmin: isAdmin,
          isAdminOrTeacher: isAdminOrTeacher,
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
    final isAdminOrTeacher = user?.role == AppConstants.roleAdmin ||
        user?.role == AppConstants.roleTeacher;
    final isAdmin = user?.role == AppConstants.roleAdmin;

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
                  icon: const Icon(Icons.chevron_left,
                      color: Colors.white),
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
                    children: [
                      'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'
                    ]
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
                : _buildEventsList(isAdminOrTeacher, isAdmin),
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
    final firstDay =
    DateTime(_currentMonth.year, _currentMonth.month, 1);
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
          _selectedDay!.year == date.year &&
          _selectedDay!.month == date.month &&
          _selectedDay!.day == date.day;
      final isWeekend = date.weekday == 6 || date.weekday == 7;

      dayCells.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay =
              isSelected ? null : date;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1565C0)
                  : isToday
                  ? const Color(0xFF1565C0).withOpacity(0.12)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday || isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : isWeekend
                        ? Colors.red.shade400
                        : Colors.black87,
                  ),
                ),
                if (dayEvents.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: dayEvents
                        .take(3)
                        .map((e) => Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(
                          top: 2, left: 1, right: 1),
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
      childAspectRatio: 1,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      children: dayCells,
    );
  }

  Widget _buildEventsList(bool isAdminOrTeacher, bool isAdmin) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            headerText,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14),
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
                    AppConstants.eventTypeNames[event.type] ?? event.type;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _openEventDetail(
                        event, isAdminOrTeacher, isAdmin),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.15),
                        child: Icon(
                          _eventIcon(event.type),
                          color: color,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        event.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            typeName,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.play_circle_outline,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _dateFormat.format(event.eventDate),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              // Показываем дату завершения, если она есть
                              if (event.endDate != null) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.stop_circle_outlined,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _dateFormat.format(event.endDate!),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                          if (event.description.isNotEmpty)
                            Text(
                              event.description,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      isThreeLine: true,
                      // ─────────────────────────────────────
                      // ПРАВКА 3: убрана иконка-карандаш
                      // редактирования из trailing.
                      // Остаётся только кнопка удаления (Admin)
                      // и стрелка вправо (для перехода в карточку)
                      // ─────────────────────────────────────
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAdmin)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              tooltip: 'Удалить',
                              onPressed: () => _deleteEvent(event),
                            ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                            size: 20,
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