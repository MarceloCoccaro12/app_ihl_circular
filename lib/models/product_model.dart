enum ProductCategory {
  artesanato, // Feito por Nossos Assistidos (teto R$ 50,00)
  brecho, // Garimpo Solidário (Brechó)
  materiais, // Outros Materiais Circulares (vidro, madeira, paletes)
}

enum ProductStatus {
  available,
  reserved,
  sold,
}

extension ProductCategoryExtension on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.artesanato:
        return 'Feito por Nossos Assistidos';
      case ProductCategory.brecho:
        return 'Garimpo Solidário (Brechó)';
      case ProductCategory.materiais:
        return 'Outros Materiais Circulares';
    }
  }

  String get shortLabel {
    switch (this) {
      case ProductCategory.artesanato:
        return 'Artesanato PcD';
      case ProductCategory.brecho:
        return 'Brechó';
      case ProductCategory.materiais:
        return 'Materiais Circulares';
    }
  }

  String get iconEmoji {
    switch (this) {
      case ProductCategory.artesanato:
        return '🎨';
      case ProductCategory.brecho:
        return '👕';
      case ProductCategory.materiais:
        return '🪵';
    }
  }
}

class ProductModel {
  final String id;
  final String title;
  final String description;
  final ProductCategory category;
  final double price; // Artesanato tem teto estrito de R$ 50,00
  final String imageUrl;
  final String? authorPcd; // Obrigatório para Artesanato (ex: "João M.")
  final String? conditionOrSize; // Ex: "Tamanho G • Ótimo estado", "Lote com 2 paletes"
  final ProductStatus status;

  // Controle de Reserva (168h = 7 dias)
  final String? reservedByUserId;
  final String? reservedByName;
  final DateTime? reservedAt;
  final DateTime? expiresAt;

  // Baixa / Venda Presencial no Balcão do IHL
  final DateTime? soldAt;
  final String? buyerUserId;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.authorPcd,
    this.conditionOrSize,
    this.status = ProductStatus.available,
    this.reservedByUserId,
    this.reservedByName,
    this.reservedAt,
    this.expiresAt,
    this.soldAt,
    this.buyerUserId,
  });

  bool get isAvailable => status == ProductStatus.available;
  bool get isReserved => status == ProductStatus.reserved;
  bool get isSold => status == ProductStatus.sold;

  // Impacto Social: R$ 50,00 financiam 1 hora de terapia clínica de reabilitação PcD
  double get therapyHours => price / 50.0;

  // Duração restante da reserva
  Duration get timeRemaining {
    if (expiresAt == null) return Duration.zero;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }

  bool get isExpired {
    if (status != ProductStatus.reserved || expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  String get formattedCountdown {
    if (status != ProductStatus.reserved || expiresAt == null) {
      return '';
    }
    final remaining = timeRemaining;
    if (remaining.inSeconds <= 0) {
      return 'Expirado (disponível para liberação)';
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (days > 0) {
      return '$days dias e $hours horas';
    } else if (hours > 0) {
      return '$hours h $minutes m $seconds s';
    } else {
      return '$minutes m $seconds s';
    }
  }

  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    ProductCategory? category,
    double? price,
    String? imageUrl,
    String? authorPcd,
    String? conditionOrSize,
    ProductStatus? status,
    String? reservedByUserId,
    String? reservedByName,
    DateTime? reservedAt,
    DateTime? expiresAt,
    DateTime? soldAt,
    String? buyerUserId,
    bool clearReservation = false,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      authorPcd: authorPcd ?? this.authorPcd,
      conditionOrSize: conditionOrSize ?? this.conditionOrSize,
      status: status ?? (clearReservation ? ProductStatus.available : this.status),
      reservedByUserId: clearReservation ? null : (reservedByUserId ?? this.reservedByUserId),
      reservedByName: clearReservation ? null : (reservedByName ?? this.reservedByName),
      reservedAt: clearReservation ? null : (reservedAt ?? this.reservedAt),
      expiresAt: clearReservation ? null : (expiresAt ?? this.expiresAt),
      soldAt: soldAt ?? this.soldAt,
      buyerUserId: buyerUserId ?? this.buyerUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'price': price,
      'image_url': imageUrl,
      'author_pcd': authorPcd,
      'condition_or_size': conditionOrSize,
      'status': status.name,
      'reserved_by_user_id': reservedByUserId,
      'reserved_by_name': reservedByName,
      'reserved_at': reservedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'sold_at': soldAt?.toIso8601String(),
      'buyer_user_id': buyerUserId,
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: ProductCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ProductCategory.brecho,
      ),
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      authorPcd: json['author_pcd'] as String?,
      conditionOrSize: json['condition_or_size'] as String?,
      status: ProductStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ProductStatus.available,
      ),
      reservedByUserId: json['reserved_by_user_id'] as String?,
      reservedByName: json['reserved_by_name'] as String?,
      reservedAt: json['reserved_at'] != null
          ? DateTime.tryParse(json['reserved_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      soldAt: json['sold_at'] != null
          ? DateTime.tryParse(json['sold_at'] as String)
          : null,
      buyerUserId: json['buyer_user_id'] as String?,
    );
  }
}
