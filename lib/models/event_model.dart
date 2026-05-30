class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;       // дата начала
  final DateTime? endDate;        // дата завершения
  final String? startTime;        // время начала (формат "HH:mm")
  final String? endTime;          // время завершение (формат "HH:mm")
  final String type;              // olympiad, contest, defense, trip, other
  final String? linkedProjectId;  // (оставлено для обратной совместимости)
  final List<String> linkedProjectIds; // ← НОВОЕ: список привязанных проектов
  final String createdBy;
  // ── НОВОЕ: Руководитель мероприятия ──────────────────
  final String supervisorId;
  final String supervisorName;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    this.endDate,
    this.startTime,
    this.endTime,
    required this.type,
    this.linkedProjectId,
    this.linkedProjectIds = const [],
    required this.createdBy,
    this.supervisorId = '',
    this.supervisorName = '',
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    // Обратная совместимость: если есть старое поле linkedProjectId,
    // но нет нового linkedProjectIds — берём из старого
    List<String> projectIds = [];
    if (map['linkedProjectIds'] != null) {
      projectIds = List<String>.from(map['linkedProjectIds']);
    } else if (map['linkedProjectId'] != null &&
        (map['linkedProjectId'] as String).isNotEmpty) {
      projectIds = [map['linkedProjectId']];
    }

    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      eventDate: map['eventDate'] != null
          ? DateTime.parse(map['eventDate'])
          : DateTime.now(),
      endDate:
      map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      startTime: map['startTime'],
      endTime: map['endTime'],
      type: map['type'] ?? 'other',
      linkedProjectId: map['linkedProjectId'],
      linkedProjectIds: projectIds,
      createdBy: map['createdBy'] ?? '',
      // ── НОВОЕ: читаем руководителя ──
      supervisorId: map['supervisorId'] ?? '',
      supervisorName: map['supervisorName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'type': type,
      'linkedProjectId': linkedProjectId,
      'linkedProjectIds': linkedProjectIds,
      'createdBy': createdBy,
      // ── НОВОЕ: сохраняем руководителя ──
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
    };
  }

  /// Создать копию с изменёнными полями
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? eventDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    String? type,
    String? linkedProjectId,
    List<String>? linkedProjectIds,
    String? createdBy,
    String? supervisorId,
    String? supervisorName,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      linkedProjectId: linkedProjectId ?? this.linkedProjectId,
      linkedProjectIds: linkedProjectIds ?? this.linkedProjectIds,
      createdBy: createdBy ?? this.createdBy,
      supervisorId: supervisorId ?? this.supervisorId,
      supervisorName: supervisorName ?? this.supervisorName,
    );
  }
}
