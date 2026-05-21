class AppConstants {
  // Роли пользователей
  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher';
  static const String roleAdmin = 'admin';

  // Статусы проектов
  static const String statusIdea = 'idea';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusOnContest = 'on_contest';
  static const String statusArchived = 'archived';

  // Направления проектов
  static const List<String> directions = [
    'Техническое',
    'Естественно-научное',
    'Гуманитарное',
    'Социальное',
    'Художественное',
    'Математическое',
    'Экологическое',
    'Иное',
  ];

  // Типы мероприятий
  static const String eventTypeOlympiad = 'olympiad';
  static const String eventTypeContest = 'contest';
  static const String eventTypeDefense = 'defense';
  static const String eventTypeTrip = 'trip';
  static const String eventTypeOther = 'other';

  // Отображаемые названия статусов
  static const Map<String, String> statusNames = {
    'idea': 'Идея',
    'in_progress': 'В разработке',
    'completed': 'Завершён',
    'on_contest': 'На конкурсе',
    'archived': 'Архив',
  };

  // Отображаемые названия типов мероприятий
  static const Map<String, String> eventTypeNames = {
    'olympiad': 'Олимпиада',
    'contest': 'Конкурс',
    'defense': 'Защита проектов',
    'trip': 'Выездное мероприятие',
    'other': 'Другое',
  };

  // Отображаемые названия ролей
  static const Map<String, String> roleNames = {
    'student': 'Ученик',
    'teacher': 'Руководитель',
    'admin': 'Администратор',
  };
}