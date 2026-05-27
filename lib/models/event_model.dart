class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;    // дата начала
  final DateTime? endDate;     // ← НОВОЕ: дата завершения
  final String type;           // olympiad, contest, defense, trip, other
  final String? linkedProjectId;
  final String createdBy;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    this.endDate,              // ← НОВОЕ
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
      endDate: map['endDate'] != null          // ← НОВОЕ
          ? DateTime.parse(map['endDate'])
          : null,
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
      'endDate': endDate?.toIso8601String(),   // ← НОВОЕ
      'type': type,
      'linkedProjectId': linkedProjectId,
      'createdBy': createdBy,
    };
  }
}