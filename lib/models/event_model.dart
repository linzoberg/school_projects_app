class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;     // дата начала
  final DateTime? endDate;      // дата завершения
  final String? startTime;      // ← НОВОЕ: время начала (формат "HH:mm")
  final String? endTime;        // ← НОВОЕ: время завершения (формат "HH:mm")
  final String type;            // olympiad, contest, defense, trip, other
  final String? linkedProjectId;
  final String createdBy;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    this.endDate,
    this.startTime,              // ← НОВОЕ
    this.endTime,                // ← НОВОЕ
    required this.type,
    this.linkedProjectId,
    required this.createdBy,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      eventDate: map['eventDate'] != null
          ? DateTime.parse(map['eventDate'])
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'])
          : null,
      startTime: map['startTime'],   // ← НОВОЕ
      endTime: map['endTime'],       // ← НОВОЕ
      type: map['type'] ?? 'other',
      linkedProjectId: map['linkedProjectId'],
      createdBy: map['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'startTime': startTime,        // ← НОВОЕ
      'endTime': endTime,            // ← НОВОЕ
      'type': type,
      'linkedProjectId': linkedProjectId,
      'createdBy': createdBy,
    };
  }
}
