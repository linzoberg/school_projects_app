import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../utils/constants.dart';

// ═══════════════════════════════════════════════════════
//  КАРТОЧКА МЕРОПРИЯТИЯ  (новый экран)
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
    final typeName =
        AppConstants.eventTypeNames[event.type] ?? event.type;
    final dateFormat = DateFormat('dd MMMM yyyy', 'ru');
    final dateFormatShort = DateFormat('dd.MM.yyyy');

    return Scaffold(
      // ── AppBar ────────────────────────────────────────
      appBar: AppBar(
        title: const Text('Карточка мероприятия'),
        actions: [
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
            // ── Цветная шапка с иконкой и типом ──────────
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
                  // Дата в шапке
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

            // ── Тело карточки ─────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Информационный блок
                  _infoCard([
                    _infoRow(
                      Icons.event_outlined,
                      'Дата',
                      dateFormatShort.format(event.eventDate),
                    ),
                    _dividerThin(),
                    _infoRow(
                      Icons.category_outlined,
                      'Тип',
                      typeName,
                    ),
                    if (event.createdBy.isNotEmpty) ...[
                      _dividerThin(),
                      _infoRow(
                        Icons.person_outlined,
                        'Создал',
                        event.createdBy,
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
                        border:
                        Border.all(color: Colors.grey.shade200),
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

                  // Кнопки действий
                  if (isAdminOrTeacher) ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onEdit();
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Редактировать'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                              const Color(0xFF1565C0),
                              side: const BorderSide(
                                  color: Color(0xFF1565C0)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                onDelete();
                              },
                              icon: const Icon(
                                  Icons.delete_outline),
                              label: const Text('Удалить'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(
                                    color: Colors.red),
                                padding:
                                const EdgeInsets.symmetric(
                                    vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
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

  // ── Вспомогательные виджеты ─────────────────────────
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
//  ЭКРАН КАЛЕНДАРЯ  (изменённый)
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

  // ── ДИАЛОГ СОЗДАНИЯ / РЕДАКТИРОВАНИЯ ────────────────
  void _showEventDialog({EventModel? existingEvent}) {
    final user = context.read<AppState>().currentUser;
    final isEditing = existingEvent != null;
    final titleController = TextEditingController(
      text: existingEvent?.title ?? '',
    );
    final descController = TextEditingController(
      text: existingEvent?.description ?? '',
    );
    DateTime selectedDate =
        existingEvent?.eventDate ?? (_selectedDay ?? DateTime.now());
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
              contentPadding:
              const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                        style:
                        TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: AppConstants.eventTypeNames.entries
                            .map((entry) {
                          final isSelected =
                              selectedType == entry.key;
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
                                borderRadius:
                                BorderRadius.circular(16),
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
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(
                                    () => selectedDate = picked);
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
                              const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                _dateFormat.format(selectedDate),
                                style:
                                const TextStyle(fontSize: 15),
                              ),
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
                        eventDate: selectedDate,
                        type: selectedType,
                        createdBy: existingEvent.createdBy,
                      );
                      await _eventService.updateEvent(updated);
                    } else {
                      final event = EventModel(
                        id: '',
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        eventDate: selectedDate,
                        type: selectedType,
                        createdBy: user?.id ?? '',
                      );
                      await _eventService.createEvent(event);
                    }
                    if (context.mounted) Navigator.pop(context);
                    _loadEvents();
                  },
                  child:
                  Text(isEditing ? 'Сохранить' : 'Создать'),
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
            style:
            TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  // ── Открыть карточку мероприятия ────────────────────
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
    // ↓ Патч 1: удалять может только Admin
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
                    ].map((day) => Expanded(
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
                    )).toList(),
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
      final hasEvents = dayEvents.isNotEmpty;
      final isSelected = _selectedDay != null &&
          _selectedDay!.year == date.year &&
          _selectedDay!.month == date.month &&
          _selectedDay!.day == date.day;
      final isToday = today.year == date.year &&
          today.month == date.month &&
          today.day == date.day;
      final isWeekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

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
                  ? const Color(0xFF1565C0).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
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
                        : isWeekend
                        ? Colors.red.shade400
                        : Colors.black87,
                  ),
                ),
                if (hasEvents)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : _eventColor(dayEvents.first.type),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.1,
        children: dayCells,
      ),
    );
  }

  // ↓ Патч 1 + Патч 2: isAdmin передаётся отдельно
  Widget _buildEventsList(bool isAdminOrTeacher, bool isAdmin) {
    final eventsToShow = _selectedDay != null
        ? _eventsForDay(_selectedDay!)
        : _events;
    final title = _selectedDay != null
        ? _timeFormat.format(_selectedDay!)
        : 'Все мероприятия месяца';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '$title (${eventsToShow.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1565C0),
            ),
          ),
        ),
        Expanded(
          child: eventsToShow.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  _selectedDay != null
                      ? 'В этот день нет мероприятий'
                      : 'В этом месяце нет мероприятий',
                  style:
                  const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding:
            const EdgeInsets.symmetric(horizontal: 12),
            itemCount: eventsToShow.length,
            itemBuilder: (context, index) {
              final event = eventsToShow[index];
              final color = _eventColor(event.type);
              final typeName =
                  AppConstants.eventTypeNames[event.type] ??
                      event.type;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: Colors.grey.shade200),
                ),
                // ↓ Патч 2: открывает Карточку мероприятия
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openEventDetail(
                      event, isAdminOrTeacher, isAdmin),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      color.withOpacity(0.15),
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
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                                Icons
                                    .calendar_today_outlined,
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
                          ],
                        ),
                        if (event.description.isNotEmpty)
                          Text(
                            event.description,
                            style: const TextStyle(
                                fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    // ↓ Патч 1+2: кнопки в списке теперь открывают
                    //   карточку (стрелка вправо) вместо иконок удаления
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAdminOrTeacher)
                          IconButton(
                            icon: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF1565C0),
                                size: 20),
                            tooltip: 'Редактировать',
                            onPressed: () =>
                                _showEventDialog(
                                    existingEvent: event),
                          ),
                        if (isAdmin)
                        // ↓ Патч 1: кнопка удаления только для Admin
                          IconButton(
                            icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20),
                            tooltip: 'Удалить',
                            onPressed: () =>
                                _deleteEvent(event),
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