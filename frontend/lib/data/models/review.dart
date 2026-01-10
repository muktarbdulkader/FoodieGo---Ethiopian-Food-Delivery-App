/// Review Model
class Review {
  final String id;
  final String oderId;
  final String foodId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.oderId,
    required this.foodId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.images = const [],
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? '',
      oderId: json['order']?.toString() ?? '',
      foodId: json['food']?.toString() ?? '',
      userId:
          json['user']?['_id']?.toString() ?? json['user']?.toString() ?? '',
      userName: json['user']?['name'] ?? 'Anonymous',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
