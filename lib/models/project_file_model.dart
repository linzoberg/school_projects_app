class ProjectFileModel {
  final String id;
  final String projectId;
  final String fileName;
  final String fileUrl;
  final String fileType; // pdf, doc, ppt, image, other
  final String uploadedBy; // userId
  final DateTime uploadedAt;

  ProjectFileModel({
    required this.id,
    required this.projectId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory ProjectFileModel.fromMap(Map<String, dynamic> map, String id) {
    return ProjectFileModel(
      id: id,
      projectId: map['projectId'] ?? '',
      fileName: map['fileName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileType: map['fileType'] ?? 'other',
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedAt: map['uploadedAt'] != null
          ? DateTime.parse(map['uploadedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}