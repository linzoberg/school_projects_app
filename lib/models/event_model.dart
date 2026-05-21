class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String type; // olympiad, contest, defense, trip, other
  final String? linkedProjectId;
  final String createdBy;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
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
      'type': type,
      'linkedProjectId': linkedProjectId,
      'createdBy': createdBy,
    };
  }
}