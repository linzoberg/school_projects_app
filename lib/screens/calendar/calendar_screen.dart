import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../utils/constants.dart';

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

  late DateFormat _monthFormat;
  late DateFormat _dateFormat;
  late DateFormat _timeFormat;

  @override
  void initState() {
    super.initState();
    _monthFormat = DateFormat('MMMM yyyy', 'ru');
    _dateFormat = DateFormat('dd.MM.yyyy');
    _timeFormat = DateFormat('dd MMMM', 'ru');
    _loadEvents();
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

  // ── ДИАЛОГ СОЗДАНИЯ / РЕДАКТИРОВАНИЯ ──────────────────
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
              // Убираем горизонтальный padding у content
              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Название *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Описание
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

                      // Тип — используем простой список вместо Dropdown
                      const Text(
                        'Тип мероприятия:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
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
                                horizontal: 10,
                                vertical: 6,
                              ),
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

                      // Дата
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _dateFormat.format(selectedDate),
                                style: const TextStyle(fontSize: 15),
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
                      // Редактирование
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
                      // Создание
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
    final isAdminOrTeacher =
        context.watch<AppState>().currentUser?.role != 'student';

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
                  _monthFormat.format(_currentMonth).toUpperCase(),
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
                // Дни недели
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      'Пн','Вт','Ср','Чт','Пт','Сб','Вс'
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
                : _buildEventsList(isAdminOrTeacher),
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
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isSelected = _selectedDay != null &&
          _selectedDay!.year == date.year &&
          _selectedDay!.month == date.month &&
          _selectedDay!.day == date.day;
      final dayEvents = _eventsForDay(date);
      final hasEvents = dayEvents.isNotEmpty;
      final isWeekend = date.weekday >= 6;

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
                    fontWeight: isToday
                        ? FontWeight.bold
                        : FontWeight.normal,
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

  Widget _buildEventsList(bool isAdminOrTeacher) {
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
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  side: BorderSide(color: Colors.grey.shade200),
                ),
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
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _dateFormat.format(event.eventDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
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
                  // Кнопки редактировать и удалить
                  trailing: isAdminOrTeacher
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF1565C0),
                          size: 20,
                        ),
                        tooltip: 'Редактировать',
                        onPressed: () => _showEventDialog(
                          existingEvent: event,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        tooltip: 'Удалить',
                        onPressed: () => _deleteEvent(event),
                      ),
                    ],
                  )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}