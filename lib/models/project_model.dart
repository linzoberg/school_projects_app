import 'project_file_model.dart';

class ProjectParticipant {
  final String userId;
  final String displayName;
  final String role; // author, member

  ProjectParticipant({
    required this.userId,
    required this.displayName,
    required this.role,
  });

  factory ProjectParticipant.fromMap(Map<String, dynamic> map) {
    return ProjectParticipant(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      role: map['role'] ?? 'member',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'role': role,
    };
  }
}

class ProjectModel {
  final String id;
  final String title;
  final String shortDescription;
  final String fullDescription;
  final String direction;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final String schoolId;
  final String schoolName;
  final String supervisorId;
  final String supervisorName;
  final List<ProjectParticipant> participants;
  // Список id участников — для быстрого поиска в Firestore
  final List<String> participantIds;
  final String results;
  final String awards;
  final DateTime createdAt;
  final DateTime updatedAt;
  List<ProjectFileModel> files;

  ProjectModel({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    required this.direction,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.schoolId,
    required this.schoolName,
    required this.supervisorId,
    required this.supervisorName,
    required this.participants,
    required this.participantIds,
    required this.results,
    required this.awards,
    required this.createdAt,
    required this.updatedAt,
    this.files = const [],
  });

  factory ProjectModel.fromMap(Map<String, dynamic> map, String id) {
    // Парсим участников
    List<ProjectParticipant> participants = [];
    if (map['participants'] != null) {
      for (var p in (map['participants'] as List)) {
        participants.add(ProjectParticipant.fromMap(p));
      }
    }

    // Парсим список id участников
    List<String> participantIds = [];
    if (map['participantIds'] != null) {
      participantIds = List<String>.from(map['participantIds']);
    }

    return ProjectModel(
      id: id,
      title: map['title'] ?? '',
      shortDescription: map['shortDescription'] ?? '',
      fullDescription: map['fullDescription'] ?? '',
      direction: map['direction'] ?? '',
      status: map['status'] ?? 'idea',
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'])
          : null,
      schoolId: map['schoolId'] ?? '',
      schoolName: map['schoolName'] ?? '',
      supervisorId: map['supervisorId'] ?? '',
      supervisorName: map['supervisorName'] ?? '',
      participants: participants,
      participantIds: participantIds,
      results: map['results'] ?? '',
      awards: map['awards'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'shortDescription': shortDescription,
      'fullDescription': fullDescription,
      'direction': direction,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'schoolId': schoolId,
      'schoolName': schoolName,
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'participants': participants.map((p) => p.toMap()).toList(),
      'participantIds': participantIds,
      'results': results,
      'awards': awards,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}