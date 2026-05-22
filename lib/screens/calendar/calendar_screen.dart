import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Календарь мероприятий', style: TextStyle(fontSize: 18)),
          Text('Модуль 5', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}