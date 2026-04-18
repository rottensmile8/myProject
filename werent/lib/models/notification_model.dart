class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // success, error, info
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['_id'] is Map
          ? (json['_id']['\$oid'] ?? '')
          : (json['_id'] ?? '')), // 🐛 FIXED: MongoDB ObjectId parsing"
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
