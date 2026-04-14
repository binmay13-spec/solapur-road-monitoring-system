// NEW FILE — Data Models
// User, Report, Worker, and Attendance models

// ============================================================
// USER MODEL
// ============================================================

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final String? fcmToken;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.fcmToken,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'citizen',
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      fcmToken: json['fcm_token'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'avatar_url': avatarUrl,
        'fcm_token': fcmToken,
      };

  bool get isCitizen => role == 'citizen';
  bool get isWorker => role == 'worker';
  bool get isAdmin => role == 'admin';
}

// ============================================================
// REPORT MODEL
// ============================================================

class ReportModel {
  final String id;
  final String userId;
  final String category;
  final String? description;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String? address;
  final String status;
  final String? assignedWorkerId;
  final Map<String, dynamic>? aiDetectionResult;
  final String? completionImageUrl;
  final String? completionRemarks;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? user; // Joined user data

  ReportModel({
    required this.id,
    required this.userId,
    required this.category,
    this.description,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.status,
    this.assignedWorkerId,
    this.aiDetectionResult,
    this.completionImageUrl,
    this.completionRemarks,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      category: json['category'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address'],
      status: json['status'] ?? 'pending',
      assignedWorkerId: json['assigned_worker_id'],
      aiDetectionResult: json['ai_detection_result'],
      completionImageUrl: json['completion_image_url'],
      completionRemarks: json['completion_remarks'],
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'])
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      user: json['users'],
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'category': category,
        'description': description,
        'image_url': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  String get categoryLabel => category.replaceAll('_', ' ').split(' ').map(
      (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w,
    ).join(' ');

  String get statusLabel => status.replaceAll('_', ' ').split(' ').map(
      (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w,
    ).join(' ');

  bool get isPending => status == 'pending';
  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
}

// ============================================================
// WORKER MODEL
// ============================================================

class WorkerModel {
  final String workerId;
  final String name;
  final String? phone;
  final String status;
  final int totalTasksCompleted;
  final int currentTaskCount;

  WorkerModel({
    required this.workerId,
    required this.name,
    this.phone,
    required this.status,
    this.totalTasksCompleted = 0,
    this.currentTaskCount = 0,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      workerId: json['worker_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      status: json['status'] ?? 'offline',
      totalTasksCompleted: json['total_tasks_completed'] ?? 0,
      currentTaskCount: json['current_task_count'] ?? 0,
    );
  }

  bool get isAvailable => status == 'available';
  bool get isBusy => status == 'busy';
  bool get isOffline => status == 'offline';
}

// ============================================================
// ATTENDANCE MODEL
// ============================================================

class AttendanceModel {
  final String id;
  final String workerId;
  final DateTime? loginTime;
  final DateTime? logoutTime;
  final String? loginPhoto;
  final String? logoutPhoto;
  final double? latitude;
  final double? longitude;
  final String date;

  AttendanceModel({
    required this.id,
    required this.workerId,
    this.loginTime,
    this.logoutTime,
    this.loginPhoto,
    this.logoutPhoto,
    this.latitude,
    this.longitude,
    required this.date,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      workerId: json['worker_id'] ?? '',
      loginTime: json['login_time'] != null
          ? DateTime.tryParse(json['login_time'])
          : null,
      logoutTime: json['logout_time'] != null
          ? DateTime.tryParse(json['logout_time'])
          : null,
      loginPhoto: json['login_photo'],
      logoutPhoto: json['logout_photo'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      date: json['date'] ?? '',
    );
  }

  bool get isLoggedIn => loginTime != null && logoutTime == null;
  bool get isLoggedOut => logoutTime != null;
}

// ============================================================
// NOTIFICATION MODEL
// ============================================================

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? reportId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.reportId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? '',
      reportId: json['report_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
