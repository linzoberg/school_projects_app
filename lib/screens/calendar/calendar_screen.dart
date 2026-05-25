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

  // Текущий отображаемый месяц
  DateTime _currentMonth = DateTime.now();
  // Выбранный день
  DateTime? _selectedDay;
  // Все мероприятия текущего месяца
  List<EventModel> _events = [];
  bool _isLoading = true;

  final _monthFormat = DateFormat('MMMM yyyy', 'ru');
  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _timeFormat = DateFormat('dd MMMM', 'ru');

  @override
  void initState() {
    super.initState();
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

  // Получить мероприятия выбранного дня
  List<EventModel> _eventsForDay(DateTime day) {
    return _events.where((e) {
      return e.eventDate.year == day.year &&
          e.eventDate.month == day.month &&
          e.eventDate.day == day.day;
    }).toList();
  }

  // Предыдущий месяц
  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month - 1,
      );
      _selectedDay = null;
    });
    _loadEvents();
  }

  // Следующий месяц
  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + 1,
      );
      _selectedDay = null;
    });
    _loadEvents();
  }

  // Показать форму добавления мероприятия
  void _showAddEventDialog() {
    final user = context.read<AppState>().currentUser;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    String selectedType = AppConstants.eventTypeContest;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Новое мероприятие'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Название
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Название *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Описание
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    // Тип мероприятия
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Тип',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: AppConstants.eventTypeNames.entries
                          .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedType = v!),
                    ),
                    const SizedBox(height: 12),

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
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Дата',
                          border: OutlineInputBorder(),
                          prefixIcon:
                          Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _dateFormat.format(selectedDate),
                          style: const TextStyle(fontSize: 15),
                        ),
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
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      return;
                    }
                    final event = EventModel(
                      id: '',
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      eventDate: selectedDate,
                      type: selectedType,
                      createdBy: user?.id ?? '',
                    );
                    await _eventService.createEvent(event);
                    if (context.mounted) Navigator.pop(context);
                    _loadEvents();
                  },
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Удалить мероприятие
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

  // Цвет типа мероприятия
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

  // Иконка типа мероприятия
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
          // ── ЗАГОЛОВОК МЕСЯЦА ─────────────────────────
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

          // ── СЕТКА КАЛЕНДАРЯ ──────────────────────────
          Container(
            color: const Color(0xFF1565C0).withOpacity(0.05),
            child: Column(
              children: [
                // Дни недели
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

                // Дни месяца
                _buildCalendarGrid(),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── СПИСОК МЕРОПРИЯТИЙ ───────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildEventsList(),
          ),
        ],
      ),
      floatingActionButton: isAdminOrTeacher
          ? FloatingActionButton.extended(
        onPressed: _showAddEventDialog,
        icon: const Icon(Icons.add),
        label: const Text('Мероприятие'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      )
          : null,
    );
  }

  // Построить сетку дней
  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // Сдвиг: понедельник = 0
    int startWeekday = firstDay.weekday - 1;
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final today = DateTime.now();

    final List<Widget> dayCells = [];

    // Пустые ячейки в начале
    for (int i = 0; i < startWeekday; i++) {
      dayCells.add(const SizedBox());
    }

    // Дни месяца
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
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

  // Список мероприятий
  Widget _buildEventsList() {
    final isAdminOrTeacher =
        context.read<AppState>().currentUser?.role != 'student';

    // Если выбран день — показываем его мероприятия
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
              final typeName = AppConstants
                  .eventTypeNames[event.type] ??
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
                              color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _dateFormat.format(event.eventDate),
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey),
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
                  trailing: isAdminOrTeacher
                      ? IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    onPressed: () => _deleteEvent(event),
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