enum DonationCategory {
  brecho, // Roupas e Calçados
  materiais, // Madeira, Vidro, Paletes, etc.
}

enum DonationStatus {
  scheduled, // Agendado
  received, // Recebido e Baixado pelo Monitor
  cancelled,
}

extension DonationCategoryExtension on DonationCategory {
  String get label {
    switch (this) {
      case DonationCategory.brecho:
        return 'Roupas e Calçados (Brechó)';
      case DonationCategory.materiais:
        return 'Outros Materiais Circulares';
    }
  }

  String get shortLabel {
    switch (this) {
      case DonationCategory.brecho:
        return 'Brechó';
      case DonationCategory.materiais:
        return 'Materiais';
    }
  }

  String get iconEmoji {
    switch (this) {
      case DonationCategory.brecho:
        return '👕';
      case DonationCategory.materiais:
        return '🪵';
    }
  }
}

class DonationScheduleModel {
  final String id;
  final String donorUserId;
  final String donorName;
  final String donorPhone;
  final String donorEmail;
  final String title;
  final String description;
  final DonationCategory category;
  final DateTime scheduledDate;
  final String scheduledTimeSlot; // ex: "09:00 - 11:00", "14:00 - 16:00"
  final String? imageUrl;
  final DonationStatus status;
  final DateTime createdAt;
  final DateTime? receivedAt;
  final String? receivedByAdminId;

  const DonationScheduleModel({
    required this.id,
    required this.donorUserId,
    required this.donorName,
    required this.donorPhone,
    required this.donorEmail,
    required this.title,
    required this.description,
    required this.category,
    required this.scheduledDate,
    required this.scheduledTimeSlot,
    this.imageUrl,
    this.status = DonationStatus.scheduled,
    required this.createdAt,
    this.receivedAt,
    this.receivedByAdminId,
  });

  bool get isScheduled => status == DonationStatus.scheduled;
  bool get isReceived => status == DonationStatus.received;

  DonationScheduleModel copyWith({
    String? id,
    String? donorUserId,
    String? donorName,
    String? donorPhone,
    String? donorEmail,
    String? title,
    String? description,
    DonationCategory? category,
    DateTime? scheduledDate,
    String? scheduledTimeSlot,
    String? imageUrl,
    DonationStatus? status,
    DateTime? createdAt,
    DateTime? receivedAt,
    String? receivedByAdminId,
  }) {
    return DonationScheduleModel(
      id: id ?? this.id,
      donorUserId: donorUserId ?? this.donorUserId,
      donorName: donorName ?? this.donorName,
      donorPhone: donorPhone ?? this.donorPhone,
      donorEmail: donorEmail ?? this.donorEmail,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTimeSlot: scheduledTimeSlot ?? this.scheduledTimeSlot,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      receivedAt: receivedAt ?? this.receivedAt,
      receivedByAdminId: receivedByAdminId ?? this.receivedByAdminId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donor_user_id': donorUserId,
      'donor_name': donorName,
      'donor_phone': donorPhone,
      'donor_email': donorEmail,
      'title': title,
      'description': description,
      'category': category.name,
      'scheduled_date': scheduledDate.toIso8601String(),
      'scheduled_time_slot': scheduledTimeSlot,
      'image_url': imageUrl,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'received_at': receivedAt?.toIso8601String(),
      'received_by_admin_id': receivedByAdminId,
    };
  }

  factory DonationScheduleModel.fromJson(Map<String, dynamic> json) {
    return DonationScheduleModel(
      id: json['id'] as String,
      donorUserId: json['donor_user_id'] as String,
      donorName: json['donor_name'] as String,
      donorPhone: json['donor_phone'] as String,
      donorEmail: json['donor_email'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: DonationCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => DonationCategory.brecho,
      ),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledTimeSlot: json['scheduled_time_slot'] as String,
      imageUrl: json['image_url'] as String?,
      status: DonationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DonationStatus.scheduled,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      receivedAt: json['received_at'] != null
          ? DateTime.tryParse(json['received_at'] as String)
          : null,
      receivedByAdminId: json['received_by_admin_id'] as String?,
    );
  }
}
