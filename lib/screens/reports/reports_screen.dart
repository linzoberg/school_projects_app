import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/project_model.dart';
import '../../services/report_service.dart';
import '../../utils/constants.dart';
import '../projects/project_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService();
  final _dateFormat = DateFormat('dd.MM.yyyy');

  // Статистика
  Map<String, dynamic> _stats = {};
  bool _isLoadingStats = true;

  // Фильтры для выборки
  String _filterStatus = '';
  String _filterDirection = '';
  final _filterSchoolController = TextEditingController();
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;

  // Результаты выборки
  List<ProjectModel> _filteredProjects = [];
  bool _isLoadingFilter = false;
  bool _filterApplied = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterSchoolController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    final stats = await _reportService.getGeneralStats();
    setState(() {
      _stats = stats;
      _isLoadingStats = false;
    });
  }

  Future<void> _applyFilter() async {
    setState(() {
      _isLoadingFilter = true;
      _filterApplied = true;
    });
    final projects = await _reportService.getFilteredProjects(
      status: _filterStatus,
      direction: _filterDirection,
      schoolName: _filterSchoolController.text.trim(),
      dateFrom: _filterDateFrom,
      dateTo: _filterDateTo,
    );
    setState(() {
      _filteredProjects = projects;
      _isLoadingFilter = false;
    });
  }

  void _resetFilter() {
    setState(() {
      _filterStatus = '';
      _filterDirection = '';
      _filterSchoolController.clear();
      _filterDateFrom = null;
      _filterDateTo = null;
      _filteredProjects = [];
      _filterApplied = false;
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _filterDateFrom = picked;
        } else {
          _filterDateTo = picked;
        }
      });
    }
  }

  // ── Показать список проектов по критерию (bottomSheet) ──────────────
  Future<void> _showProjectsByFilter({
    String? status,
    String? direction,
    String? schoolName,
    required String label,
  }) async {
    // Показываем индикатор загрузки
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LoadingSheet(),
    );

    final projects = await _reportService.getFilteredProjects(
      status: status ?? '',
      direction: direction ?? '',
      schoolName: schoolName ?? '',
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // закрываем индикатор загрузки

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProjectListSheet(
        label: label,
        projects: projects,
        dateFormat: _dateFormat,
        statusColor: _statusColor,
        onProjectTap: (projectId) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(projectId: projectId),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Вкладки
        Container(
          color: const Color(0xFF1565C0),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(icon: Icon(Icons.bar_chart), text: 'Статистика'),
              Tab(icon: Icon(Icons.search), text: 'Выборка'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStatsTab(),
              _buildFilterTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ── ВКЛАДКА СТАТИСТИКА ────────────────────────────────────────────────
  Widget _buildStatsTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    final total = _stats['total'] as int? ?? 0;
    final byStatus =
        _stats['byStatus'] as Map<String, dynamic>? ?? {};
    final byDirection =
        _stats['byDirection'] as Map<String, dynamic>? ?? {};
    final bySchool =
        _stats['bySchool'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Общий счётчик
            Card(
              color: const Color(0xFF1565C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.folder,
                        color: Colors.white, size: 48),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'проектов всего',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // По статусам
            _sectionTitle('По статусам'),
            const SizedBox(height: 4),
            _hintText('Нажмите на строку, чтобы увидеть проекты'),
            const SizedBox(height: 8),
            ...AppConstants.statusNames.entries.map((e) {
              final count = byStatus[e.key] as int? ?? 0;
              final percent = total > 0 ? count / total : 0.0;
              return _tappableStatRow(
                label: e.value,
                count: count,
                percent: percent,
                color: _statusColor(e.key),
                onTap: count > 0
                    ? () => _showProjectsByFilter(
                  status: e.key,
                  label:
                  'Статус: ${e.value} ($count)',
                )
                    : null,
              );
            }),
            const SizedBox(height: 20),

            // По направлениям
            if (byDirection.isNotEmpty) ...[
              _sectionTitle('По направлениям'),
              const SizedBox(height: 4),
              _hintText('Нажмите на строку, чтобы увидеть проекты'),
              const SizedBox(height: 8),
              ...byDirection.entries.take(6).map((e) {
                final count = e.value as int;
                final percent = total > 0 ? count / total : 0.0;
                return _tappableStatRow(
                  label: e.key,
                  count: count,
                  percent: percent,
                  color: const Color(0xFF1565C0),
                  onTap: count > 0
                      ? () => _showProjectsByFilter(
                    direction: e.key,
                    label:
                    'Направление: ${e.key} ($count)',
                  )
                      : null,
                );
              }),
              const SizedBox(height: 20),
            ],

            // По организациям
            if (bySchool.isNotEmpty) ...[
              _sectionTitle('По организациям'),
              const SizedBox(height: 4),
              _hintText('Нажмите на строку, чтобы увидеть проекты'),
              const SizedBox(height: 8),
              ...bySchool.entries.take(5).map((e) {
                final count = e.value as int;
                final percent = total > 0 ? count / total : 0.0;
                return _tappableStatRow(
                  label: e.key,
                  count: count,
                  percent: percent,
                  color: Colors.teal,
                  onTap: count > 0
                      ? () => _showProjectsByFilter(
                    schoolName: e.key,
                    label:
                    'Организация: ${e.key} ($count)',
                  )
                      : null,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // Строка статистики — кликабельная
  Widget _tappableStatRow({
    required String label,
    required int count,
    required double percent,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 6, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onTap != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 11,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── ВКЛАДКА ВЫБОРКА ───────────────────────────────────────────────────
  Widget _buildFilterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Параметры выборки'),
          const SizedBox(height: 12),

          // Статус
          DropdownButtonFormField<String>(
            value: _filterStatus.isEmpty ? null : _filterStatus,
            hint: const Text('Любой статус'),
            decoration: const InputDecoration(
              labelText: 'Статус',
              prefixIcon: Icon(Icons.flag_outlined),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                  value: '', child: Text('Любой')),
              ...AppConstants.statusNames.entries.map((e) =>
                  DropdownMenuItem(
                      value: e.key, child: Text(e.value))),
            ],
            onChanged: (v) =>
                setState(() => _filterStatus = v ?? ''),
          ),
          const SizedBox(height: 12),

          // Направление
          DropdownButtonFormField<String>(
            value:
            _filterDirection.isEmpty ? null : _filterDirection,
            hint: const Text('Любое направление'),
            decoration: const InputDecoration(
              labelText: 'Направление',
              prefixIcon: Icon(Icons.category_outlined),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                  value: '', child: Text('Любое')),
              ...AppConstants.directions.map((d) =>
                  DropdownMenuItem(value: d, child: Text(d))),
            ],
            onChanged: (v) =>
                setState(() => _filterDirection = v ?? ''),
          ),
          const SizedBox(height: 12),

          // Школа
          TextField(
            controller: _filterSchoolController,
            decoration: const InputDecoration(
              labelText: 'Организация (часть названия)',
              prefixIcon: Icon(Icons.school_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Даты
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(isFrom: true),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Дата от',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(
                          Icons.calendar_today_outlined),
                      suffixIcon: _filterDateFrom != null
                          ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 16),
                        onPressed: () => setState(
                                () => _filterDateFrom = null),
                      )
                          : null,
                    ),
                    child: Text(
                      _filterDateFrom != null
                          ? _dateFormat.format(_filterDateFrom!)
                          : 'Не задана',
                      style: TextStyle(
                        color: _filterDateFrom != null
                            ? Colors.black87
                            : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(isFrom: false),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Дата до',
                      border: const OutlineInputBorder(),
                      prefixIcon:
                      const Icon(Icons.event_outlined),
                      suffixIcon: _filterDateTo != null
                          ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 16),
                        onPressed: () => setState(
                                () => _filterDateTo = null),
                      )
                          : null,
                    ),
                    child: Text(
                      _filterDateTo != null
                          ? _dateFormat.format(_filterDateTo!)
                          : 'Не задана',
                      style: TextStyle(
                        color: _filterDateTo != null
                            ? Colors.black87
                            : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Кнопки
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetFilter,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Сбросить'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _applyFilter,
                  icon: const Icon(Icons.search),
                  label: const Text('Найти'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Результаты
          if (_isLoadingFilter)
            const Center(child: CircularProgressIndicator())
          else if (_filterApplied) ...[
            Row(
              children: [
                _sectionTitle(
                    'Результаты: ${_filteredProjects.length} проектов'),
              ],
            ),
            const SizedBox(height: 8),
            if (_filteredProjects.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Проекты не найдены',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._filteredProjects.map((p) => _projectReportCard(
                p,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ProjectDetailScreen(projectId: p.id),
                  ),
                ),
              )),
          ],
        ],
      ),
    );
  }

  // Карточка проекта в отчёте (с onTap)
  Widget _projectReportCard(ProjectModel p, {VoidCallback? onTap}) {
    final statusName =
        AppConstants.statusNames[p.status] ?? p.status;
    final statusColor = _statusColor(p.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      statusName,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                p.direction,
                style: const TextStyle(
                    color: Color(0xFF1565C0), fontSize: 12),
              ),
              if (p.schoolName.isNotEmpty)
                Text(
                  p.schoolName,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12),
                ),
              Text(
                'Создан: ${_dateFormat.format(p.createdAt)}  '
                    'Участников: ${p.participants.length}',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1565C0),
      ),
    );
  }

  Widget _hintText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey.shade500,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'idea':
        return Colors.grey;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'on_contest':
        return Colors.orange;
      case 'archived':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}

// ── Вспомогательный виджет: индикатор загрузки (bottomSheet) ─────────────
class _LoadingSheet extends StatelessWidget {
  const _LoadingSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(40),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Загружаем проекты...'),
        ],
      ),
    );
  }
}

// ── Вспомогательный виджет: список проектов в bottomSheet ────────────────
class _ProjectListSheet extends StatelessWidget {
  final String label;
  final List<ProjectModel> projects;
  final DateFormat dateFormat;
  final Color Function(String) statusColor;
  final void Function(String projectId) onProjectTap;

  const _ProjectListSheet({
    required this.label,
    required this.projects,
    required this.dateFormat,
    required this.statusColor,
    required this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Ручка
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Заголовок
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Найдено проектов: ${projects.length}',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
            const Divider(height: 16),
            // Список
            Expanded(
              child: projects.isEmpty
                  ? const Center(
                child: Text(
                  'Проекты не найдены',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                controller: controller,
                padding:
                const EdgeInsets.fromLTRB(12, 0, 12, 20),
                itemCount: projects.length,
                itemBuilder: (_, i) {
                  final p = projects[i];
                  final sName =
                      AppConstants.statusNames[p.status] ??
                          p.status;
                  final sColor = statusColor(p.status);
                  return Card(
                    elevation: 0,
                    margin:
                    const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                      side: BorderSide(
                          color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.of(context).pop();
                        onProjectTap(p.id);
                      },
                      title: Text(
                        p.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            p.direction,
                            style: const TextStyle(
                                color: Color(0xFF1565C0),
                                fontSize: 12),
                          ),
                          if (p.schoolName.isNotEmpty)
                            Text(
                              p.schoolName,
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12),
                            ),
                          Text(
                            'Создан: ${dateFormat.format(p.createdAt)}  '
                                'Участников: ${p.participants.length}',
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3),
                            decoration: BoxDecoration(
                              color:
                              sColor.withOpacity(0.1),
                              borderRadius:
                              BorderRadius.circular(10),
                              border: Border.all(
                                  color: sColor
                                      .withOpacity(0.4)),
                            ),
                            child: Text(
                              sName,
                              style: TextStyle(
                                  color: sColor,
                                  fontSize: 10,
                                  fontWeight:
                                  FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}