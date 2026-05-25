import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _events => _db.collection('events');

  // -------------------------------------------------------
  // Создать мероприятие
  // -------------------------------------------------------
  Future<String> createEvent(EventModel event) async {
    final docRef = await _events.add(event.toMap());
    return docRef.id;
  }

  // -------------------------------------------------------
  // Получить все мероприятия
  // -------------------------------------------------------
  Future<List<EventModel>> getEvents() async {
    try {
      final snapshot = await _events
          .orderBy('eventDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => EventModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // -------------------------------------------------------
  // Получить мероприятия за конкретный месяц
  // -------------------------------------------------------
  Future<List<EventModel>> getEventsByMonth(int year, int month) async {
    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);

      final snapshot = await _events
          .where('eventDate',
          isGreaterThanOrEqualTo: start.toIso8601String())
          .where('eventDate', isLessThan: end.toIso8601String())
          .orderBy('eventDate')
          .get();

      return snapshot.docs
          .map((doc) => EventModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // -------------------------------------------------------
  // Получить ближайшие мероприятия (от сегодня)
  // -------------------------------------------------------
  Future<List<EventModel>> getUpcomingEvents({int limit = 5}) async {
    try {
      final now = DateTime.now();
      final snapshot = await _events
          .where('eventDate',
          isGreaterThanOrEqualTo: now.toIso8601String())
          .orderBy('eventDate')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => EventModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // -------------------------------------------------------
  // Обновить мероприятие
  // -------------------------------------------------------
  Future<void> updateEvent(EventModel event) async {
    await _events.doc(event.id).update(event.toMap());
  }

  // -------------------------------------------------------
  // Удалить мероприятие
  // -------------------------------------------------------
  Future<void> deleteEvent(String eventId) async {
    await _events.doc(eventId).delete();
  }
}