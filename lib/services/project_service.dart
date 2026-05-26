import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';

class ProjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Коллекция проектов в Firestore
  CollectionReference get _projects => _db.collection('projects');

  // -------------------------------------------------------
  // Создать новый проект
  // -------------------------------------------------------
  Future<String> createProject(ProjectModel project) async {
    final docRef = await _projects.add(project.toMap());
    return docRef.id;
  }

  // -------------------------------------------------------
  // Получить все проекты (с фильтрами)
  // -------------------------------------------------------
  Future<List<ProjectModel>> getProjects({
    String? direction,
    String? status,
    String? schoolId,
    String? supervisorId,
    String? searchQuery,
  }) async {
    Query query = _projects.orderBy('createdAt', descending: true);

    // Фильтр по направлению
    if (direction != null && direction.isNotEmpty) {
      query = query.where('direction', isEqualTo: direction);
    }

    // Фильтр по статусу
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    // Фильтр по школе
    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.where('schoolId', isEqualTo: schoolId);
    }

    // Фильтр по руководителю
    if (supervisorId != null && supervisorId.isNotEmpty) {
      query = query.where('supervisorId', isEqualTo: supervisorId);
    }

    final snapshot = await query.get();
    List<ProjectModel> projects = snapshot.docs
        .map((doc) => ProjectModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    ))
        .toList();

    // Поиск по названию (локально, после загрузки)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      projects = projects.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.shortDescription.toLowerCase().contains(q) ||
            p.supervisorName.toLowerCase().contains(q) ||
            p.schoolName.toLowerCase().contains(q);
      }).toList();
    }

    return projects;
  }

  // -------------------------------------------------------
  // Получить проект по id
  // -------------------------------------------------------
  Future<ProjectModel?> getProjectById(String id) async {
    final doc = await _projects.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return ProjectModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }
    return null;
  }

  // -------------------------------------------------------
  // Получить проекты конкретного пользователя
  // -------------------------------------------------------
  Future<List<ProjectModel>> getProjectsByUser(String userId) async {
    try {
      final List<ProjectModel> result = [];

      // Получаем ВСЕ проекты и фильтруем локально
      final snapshot = await _projects
          .orderBy('createdAt', descending: true)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final project = ProjectModel.fromMap(data, doc.id);

        // Проверяем является ли пользователь руководителем
        final isSupervisor = data['supervisorId'] == userId;

        // Проверяем является ли пользователь участником
        final participantIds = data['participantIds'];
        bool isParticipant = false;
        if (participantIds is List) {
          isParticipant = participantIds.contains(userId);
        }

        if (isSupervisor || isParticipant) {
          result.add(project);
        }
      }

      return result;
    } catch (e) {
      return [];
    }
  }

  // -------------------------------------------------------
  // Обновить проект
  // -------------------------------------------------------
  Future<void> updateProject(ProjectModel project) async {
    await _projects.doc(project.id).update(project.toMap());
  }

  // -------------------------------------------------------
  // Обновить только статус проекта
  // -------------------------------------------------------
  Future<void> updateProjectStatus(String projectId, String status) async {
    await _projects.doc(projectId).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // -------------------------------------------------------
  // Удалить проект
  // -------------------------------------------------------
  Future<void> deleteProject(String projectId) async {
    await _projects.doc(projectId).delete();
  }

  // -------------------------------------------------------
  // Получить статистику для отчётов
  // -------------------------------------------------------
  Future<Map<String, int>> getProjectsStats() async {
    final snapshot = await _projects.get();
    final Map<String, int> stats = {
      'total': 0,
      'idea': 0,
      'in_progress': 0,
      'completed': 0,
      'on_contest': 0,
      'archived': 0,
    };

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'idea';
      stats['total'] = (stats['total'] ?? 0) + 1;
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }
}