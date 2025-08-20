class CalendarEvent {
  final String id;
  final String policyId;
  final String title;
  final String eventType; // Corresponds to 'category' from the server
  final DateTime date;    // Corresponds to 'eventDate' from the server

  CalendarEvent({
    required this.id,
    required this.policyId,
    required this.title,
    required this.eventType,
    required this.date,
  });

  /// Creates a CalendarEvent object from a JSON map.
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id']?.toString() ?? '',
      policyId: json['policyId']?.toString() ?? '',
      title: json['title']?.toString() ?? '제목 없음',
      eventType: json['category']?.toString() ?? '미분류',
      // The server sends a date string like "2025-08-20", so we parse it.
      date: DateTime.tryParse(json['eventDate'] ?? '') ?? DateTime.now(),
    );
  }
}
