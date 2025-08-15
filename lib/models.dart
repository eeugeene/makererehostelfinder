class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'student' | 'manager'
  final DateTime createdAt;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'created_at': createdAt.toUtc().toIso8601String(),
    'avatar_url': avatarUrl,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    name: (json['name'] ?? '') as String,
    email: (json['email'] ?? '') as String,
    role: (json['role'] ?? 'student') as String,
    createdAt: DateTime.tryParse(json['created_at'] ?? '')?.toUtc() ?? DateTime.now().toUtc(),
    avatarUrl: json['avatar_url'] as String?,
  );
}

class Hostel {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final int price;
  final List<String> amenities;
  final String contactInfo;
  final List<String> imageUrls;
  final bool isAvailable;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? rating;
  final int reviewCount;

  const Hostel({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.price,
    required this.amenities,
    required this.contactInfo,
    required this.imageUrls,
    required this.isAvailable,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.rating,
    required this.reviewCount,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'price': price,
    'amenities': amenities,
    'contact_info': contactInfo,
    'image_urls': imageUrls,
    'is_available': isAvailable,
    'created_by': createdBy,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'rating': rating,
    'review_count': reviewCount,
  };

  factory Hostel.fromJson(Map<String, dynamic> json) => Hostel(
    id: json['id'] as String,
    name: (json['name'] ?? '') as String,
    description: (json['description'] ?? '') as String,
    latitude: ((json['latitude']) ?? 0).toDouble(),
    longitude: ((json['longitude']) ?? 0).toDouble(),
    price: (json['price'] ?? 0) as int,
    amenities: List<String>.from((json['amenities'] ?? []) as List),
    contactInfo: (json['contact_info'] ?? '') as String,
    imageUrls: List<String>.from((json['image_urls'] ?? []) as List),
    isAvailable: (json['is_available'] ?? true) as bool,
    createdBy: (json['created_by'] ?? '') as String,
    createdAt: DateTime.tryParse(json['created_at'] ?? '')?.toUtc() ?? DateTime.now().toUtc(),
    updatedAt: DateTime.tryParse(json['updated_at'] ?? '')?.toUtc() ?? DateTime.now().toUtc(),
    rating: (json['rating'] as num?)?.toDouble(),
    reviewCount: (json['review_count'] ?? 0) as int,
  );
}

class Review {
  final String id;
  final String hostelId;
  final String userId;
  final String userName;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Review({
    required this.id,
    required this.hostelId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'hostel_id': hostelId,
    'user_id': userId,
    'user_name': userName,
    'rating': rating,
    'comment': comment,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as String,
    hostelId: (json['hostel_id'] ?? '') as String,
    userId: (json['user_id'] ?? '') as String,
    userName: (json['user_name'] ?? '') as String,
    rating: (json['rating'] ?? 0) as int,
    comment: (json['comment'] ?? '') as String,
    createdAt: DateTime.tryParse(json['created_at'] ?? '')?.toUtc() ?? DateTime.now().toUtc(),
    updatedAt: DateTime.tryParse(json['updated_at'] ?? '')?.toUtc() ?? DateTime.now().toUtc(),
  );
}

