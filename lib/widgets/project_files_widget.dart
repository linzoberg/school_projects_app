import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project_file_model.dart';
import '../services/file_service.dart';

class ProjectFilesWidget extends StatefulWidget {
  final String projectId;
  final String currentUserId;
  final bool canUpload;

  const ProjectFilesWidget({
    super.key,
    required this.projectId,
    required this.currentUserId,
    required this.canUpload,
  });

  @override
  State<ProjectFilesWidget> createState() => _ProjectFilesWidgetState();
}

class _ProjectFilesWidgetState extends State<ProjectFilesWidget> {
  final FileService _fileService = FileService();
  List<ProjectFileModel> _files = [];
  bool _isLoading = true;

  // Контроллеры для диалога добавления ссылки
  final _fileNameController = TextEditingController();
  final _fileUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _fileUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    final files = await _fileService.getProjectFiles(widget.projectId);
    setState(() {
      _files = files;
      _isLoading = false;
    });
  }

  // Диалог добавления ссылки на файл
  void _showAddLinkDialog() {
    _fileNameController.clear();
    _fileUrlController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить файл'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Укажите название файла и ссылку на него '
                  '(Google Drive, Яндекс.Диск и др.)',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fileNameController,
              decoration: const InputDecoration(
                labelText: 'Название файла *',
                hintText: 'Отчёт_проекта.pdf',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.insert_drive_file_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fileUrlController,
              decoration: const InputDecoration(
                labelText: 'Ссылка на файл *',
                hintText: 'https://drive.google.com/...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _fileNameController.text.trim();
              final url = _fileUrlController.text.trim();

              if (name.isEmpty || url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Заполните все поля'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Простая проверка URL
              if (!url.startsWith('http')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ссылка должна начинаться с http://'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              final result = await _fileService.addFileLink(
                projectId: widget.projectId,
                uploadedBy: widget.currentUserId,
                fileName: name,
                fileUrl: url,
              );

              if (result != null) {
                _loadFiles();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Файл добавлен'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  // Открыть ссылку
  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть ссылку')),
        );
      }
    }
  }

  // Удалить файл
  void _deleteFile(ProjectFileModel file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить файл?'),
        content: Text('«${file.fileName}» будет удалён из списка.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _fileService.deleteFile(
                projectId: widget.projectId,
                fileId: file.id,
                fileUrl: file.fileUrl,
              );
              _loadFiles();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String fileType) {
    switch (fileType) {
      case 'image': return Icons.image_outlined;
      case 'pdf': return Icons.picture_as_pdf_outlined;
      case 'document': return Icons.description_outlined;
      case 'presentation': return Icons.slideshow_outlined;
      case 'spreadsheet': return Icons.table_chart_outlined;
      case 'archive': return Icons.folder_zip_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  Color _fileColor(String fileType) {
    switch (fileType) {
      case 'image': return Colors.green;
      case 'pdf': return Colors.red;
      case 'document': return Colors.blue;
      case 'presentation': return Colors.orange;
      case 'spreadsheet': return Colors.teal;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Файлы и материалы (${_files.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            if (widget.canUpload)
              TextButton.icon(
                onPressed: _showAddLinkDialog,
                icon: const Icon(Icons.add_link),
                label: const Text('Добавить'),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Список файлов
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_files.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Column(
              children: [
                Icon(Icons.folder_open, color: Colors.grey, size: 36),
                SizedBox(height: 8),
                Text(
                  'Файлы не прикреплены',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ...List.generate(_files.length, (index) {
            final file = _files[index];
            return Card(
              elevation: 0,
              color: Colors.grey.shade50,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                  _fileColor(file.fileType).withOpacity(0.12),
                  child: Icon(
                    _fileIcon(file.fileType),
                    color: _fileColor(file.fileType),
                    size: 20,
                  ),
                ),
                title: Text(
                  file.fileName,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Добавлен: ${_formatDate(file.uploadedAt)}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Открыть
                    IconButton(
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 20,
                        color: Color(0xFF1565C0),
                      ),
                      tooltip: 'Открыть',
                      onPressed: () => _openFile(file.fileUrl),
                    ),
                    // Удалить
                    if (widget.canUpload)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                        tooltip: 'Удалить',
                        onPressed: () => _deleteFile(file),
                      ),
                  ],
                ),
              ),
            );
          }),

        // Подсказка о форматах
        if (widget.canUpload && _files.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Добавляйте ссылки на файлы из Google Drive, '
                  'Яндекс.Диска или других облачных хранилищ.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}