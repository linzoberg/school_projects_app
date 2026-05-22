import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_file_model.dart';

class FileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------------------------------------------
  // Добавить ссылку на файл вручную
  // -------------------------------------------------------
  Future<ProjectFileModel?> addFileLink({
    required String projectId,
    required String uploadedBy,
    required String fileName,
    required String fileUrl,
  }) async {
    try {
      final fileType = _getFileType(fileName);

      final fileModel = ProjectFileModel(
        id: '',
        projectId: projectId,
        fileName: fileName,
        fileUrl: fileUrl,
        fileType: fileType,
        uploadedBy: uploadedBy,
        uploadedAt: DateTime.now(),
      );

      final docRef = await _db
          .collection('projects')
          .doc(projectId)
          .collection('files')
          .add(fileModel.toMap());

      return ProjectFileModel(
        id: docRef.id,
        projectId: projectId,
        fileName: fileName,
        fileUrl: fileUrl,
        fileType: fileType,
        uploadedBy: uploadedBy,
        uploadedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  // -------------------------------------------------------
  // Получить список файлов проекта
  // -------------------------------------------------------
  Future<List<ProjectFileModel>> getProjectFiles(String projectId) async {
    try {
      final snapshot = await _db
          .collection('projects')
          .doc(projectId)
          .collection('files')
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProjectFileModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // -------------------------------------------------------
  // Удалить ссылку на файл
  // -------------------------------------------------------
  Future<void> deleteFile({
    required String projectId,
    required String fileId,
    required String fileUrl,
  }) async {
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('files')
        .doc(fileId)
        .delete();
  }

  // -------------------------------------------------------
  // Определить тип файла по расширению
  // -------------------------------------------------------
  String _getFileType(String fileName) {
    if (!fileName.contains('.')) return 'other';
    final ext = fileName.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return 'image';
    if (ext == 'pdf') return 'pdf';
    if (['doc', 'docx', 'txt'].contains(ext)) return 'document';
    if (['ppt', 'pptx'].contains(ext)) return 'presentation';
    if (['xls', 'xlsx'].contains(ext)) return 'spreadsheet';
    if (['zip', 'rar'].contains(ext)) return 'archive';
    return 'other';
  }
}