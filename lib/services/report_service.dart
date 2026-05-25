import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------------------------------------------
  // Получить статистику по всем проектам
  // -------------------------------------------------------
  Future<Map<String, dynamic>> getGeneralStats() async {
    try {
      final snapshot = await _db.collection('projects').get();
      final projects = snapshot.docs
          .map((doc) => ProjectModel.fromMap(
        doc.data(),
        doc.id,
      ))
          .toList();

      // Считаем по статусам
      final Map<String, int> byStatus = {
        'idea': 0,
        'in_progress': 0,
        'completed': 0,
        'on_contest': 0,
        'archived': 0,
      };

      // Считаем по направлениям
      final Map<String, int> byDirection = {};

      // Считаем по школам
      final Map<String, int> bySchool = {};

      for (final p in projects) {
        // По статусу
        byStatus[p.status] = (byStatus[p.status] ?? 0) + 1;

        // По направлению
        if (p.direction.isNotEmpty) {
          byDirection[p.direction] =
              (byDirection[p.direction] ?? 0) + 1;
        }

        // По школе
        if (p.schoolName.isNotEmpty) {
          bySchool[p.schoolName] =
              (bySchool[p.schoolName] ?? 0) + 1;
        }
      }

      // Сортируем направления по количеству
      final sortedDirections = byDirection.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Сортируем школы по количеству
      final sortedSchools = bySchool.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'total': projects.length,
        'byStatus': byStatus,
        'byDirection': Map.fromEntries(sortedDirections),
        'bySchool': Map.fromEntries(sortedSchools),
      };
    } catch (e) {
      return {
        'total': 0,
        'byStatus': {},
        'byDirection': {},
        'bySchool': {},
      };
    }
  }

  // -------------------------------------------------------
  // Получить проекты с фильтрами для отчёта
  // -------------------------------------------------------
  Future<List<ProjectModel>> getFilteredProjects({
    String? status,
    String? direction,
    String? schoolName,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      Query query = _db
          .collection('projects')
          .orderBy('createdAt', descending: true);

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }
      if (direction != null && direction.isNotEmpty) {
        query = query.where('direction', isEqualTo: direction);
      }

      final snapshot = await query.get();
      List<ProjectModel> projects = snapshot.docs
          .map((doc) => ProjectModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();

      // Локальные фильтры
      if (schoolName != null && schoolName.isNotEmpty) {
        projects = projects
            .where((p) => p.schoolName
            .toLowerCase()
            .contains(schoolName.toLowerCase()))
            .toList();
      }
      if (dateFrom != null) {
        projects = projects
            .where((p) => p.createdAt.isAfter(dateFrom))
            .toList();
      }
      if (dateTo != null) {
        final endOfDay =
        DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59);
        projects = projects
            .where((p) => p.createdAt.isBefore(endOfDay))
            .toList();
      }

      return projects;
    } catch (e) {
      return [];
    }
  }
}