import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../projects/project_list_screen.dart';
import '../calendar/calendar_screen.dart';
import '../reports/reports_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  final List<String> _titles = [
    'Главная',
    'Проекты',
    'Календарь',
    'Отчёты',
    'Профиль',
  ];

  @override
  Widget build(BuildContext context) {
    // Экраны собираем здесь, передавая колбэк переключения
    final screens = [
      _HomeTab(onSwitchTab: _switchTab),
      const ProjectListScreen(),
      const CalendarScreen(),
      const ReportsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _switchTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Проекты',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Календарь',
          ),

          NavigationDestination(
            icon: Icon(Icons.insert_chart_outlined),
            selectedIcon: Icon(Icons.insert_chart),
            label: 'Отчёты',
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

// ── ВКЛАДКА ГЛАВНАЯ ──────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final Function(int) onSwitchTab;

  const _HomeTab({required this.onSwitchTab});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  // Ближайшие мероприятия — загружаем при открытии
  int _projectsCount = 0;
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadQuickStats();
  }

  Future<void> _loadQuickStats() async {
    // Можно добавить загрузку счётчиков позже
    setState(() => _statsLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    final roleName = user?.role == 'admin'
        ? 'Администратор'
        : user?.role == 'teacher'
        ? 'Руководитель'
        : 'Ученик';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── КАРТОЧКА ПРИВЕТСТВИЯ ─────────────────────
          Card(
            color: const Color(0xFF1565C0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    radius: 28,
                    child: Text(
                      user?.displayName.isNotEmpty == true
                          ? user!.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Добро пожаловать!',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          user?.displayName ?? 'Пользователь',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            roleName,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── БЫСТРЫЕ ДЕЙСТВИЯ ─────────────────────────
          const Text(
            'Быстрые действия',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Первая строка
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.folder_outlined,
                  label: 'Все проекты',
                  color: Colors.blue,
                  onTap: () => widget.onSwitchTab(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'Календарь',
                  color: Colors.green,
                  onTap: () => widget.onSwitchTab(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Вторая строка
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.bar_chart_outlined,
                  label: 'Отчёты',
                  color: Colors.orange,
                  onTap: () => widget.onSwitchTab(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.person_outlined,
                  label: 'Профиль',
                  color: Colors.purple,
                  onTap: () => widget.onSwitchTab(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── ПОДСКАЗКИ ПО РОЛЯМ ────────────────────────
          _buildRoleHint(user?.role ?? 'student'),
          const SizedBox(height: 16),

          // ── О ПРИЛОЖЕНИИ ─────────────────────────────
          Card(
            elevation: 0,
            color: Colors.blue.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.blue.shade100),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFF1565C0)),
                      SizedBox(width: 8),
                      Text(
                        'О приложении',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Система управления проектной деятельностью '
                        'школьников. Позволяет вести каталог проектов, '
                        'отслеживать статусы, хранить материалы и '
                        'планировать мероприятия.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleHint(String role) {
    String hint;
    IconData icon;
    Color color;

    switch (role) {
      case 'admin':
        hint = 'У вас права администратора: вы можете создавать, '
            'редактировать и удалять любые проекты, '
            'управлять мероприятиями и просматривать отчёты.';
        icon = Icons.admin_panel_settings_outlined;
        color = Colors.red;
        break;
      case 'teacher':
        hint = 'У вас права руководителя: вы можете создавать '
            'и редактировать проекты, добавлять мероприятия '
            'в календарь и просматривать отчёты.';
        icon = Icons.school_outlined;
        color = Colors.orange;
        break;
      default:
        hint = 'Вы можете просматривать каталог проектов, '
            'следить за расписанием мероприятий '
            'и просматривать свои проекты в профиле.';
        icon = Icons.person_outlined;
        color = Colors.blue;
    }

    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hint,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ВИДЖЕТ БЫСТРОГО ДЕЙСТВИЯ ─────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}