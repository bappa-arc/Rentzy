class User {
  final int userId;
  final String name;
  final String email;
  final String? phone;
  final String? photo;
  final double? lat;
  final double? long;
  final String? token;

  User({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.photo,
    this.lat,
    this.long,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      userId: json['user_id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      photo: json['photo'] as String?,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      long: json['long'] != null ? (json['long'] as num).toDouble() : null,
      token: token ?? json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'photo': photo,
      'lat': lat,
      'long': long,
      'token': token,
    };
  }
}

class Owner {
  final String name;
  final String? phone;
  final String? photo;

  Owner({
    required this.name,
    this.phone,
    this.photo,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      name: json['name'] as String,
      phone: json['phone'] as String?,
      photo: json['photo'] as String?,
    );
  }
}

class Rating {
  final int? ratingId;
  final String userName;
  final String? userPhoto;
  final int rating;
  final String? review;
  final String? createdAt;

  Rating({
    this.ratingId,
    required this.userName,
    this.userPhoto,
    required this.rating,
    this.review,
    this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    return Rating(
      ratingId: json['rating_id'] as int?,
      userName: userJson != null ? userJson['name'] as String : 'Anonymous',
      userPhoto: userJson != null ? userJson['photo'] as String? : null,
      rating: json['rating'] as int,
      review: json['review'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class Property {
  final int propertyId;
  final int ownerId;
  final Owner owner;
  final String title;
  final String description;
  final double price;
  final String propertyType;
  final String furnishing;
  final List<String> amenities;
  final String address;
  final String city;
  final double lat;
  final double long;
  final bool isAvailable;
  final double? distance;
  final List<String> images;
  final double rating;
  final int ratingsCount;
  final List<Rating> ratings;
  final String? createdAt;

  Property({
    required this.propertyId,
    required this.ownerId,
    required this.owner,
    required this.title,
    required this.description,
    required this.price,
    required this.propertyType,
    required this.furnishing,
    required this.amenities,
    required this.address,
    required this.city,
    required this.lat,
    required this.long,
    required this.isAvailable,
    this.distance,
    required this.images,
    required this.rating,
    required this.ratingsCount,
    this.ratings = const [],
    this.createdAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    final amenitiesList = (json['amenities'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final imagesList = (json['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    
    final ratingsRaw = json['ratings'] as List<dynamic>?;
    final ratingsList = ratingsRaw != null
        ? ratingsRaw.map((r) => Rating.fromJson(r as Map<String, dynamic>)).toList()
        : <Rating>[];

    return Property(
      propertyId: json['property_id'] as int,
      ownerId: json['owner_id'] as int,
      owner: Owner.fromJson(json['owner'] as Map<String, dynamic>),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      propertyType: json['property_type'] as String,
      furnishing: json['furnishing'] as String? ?? 'unfurnished',
      amenities: amenitiesList,
      address: json['address'] as String,
      city: json['city'] as String,
      lat: (json['lat'] as num).toDouble(),
      long: (json['long'] as num).toDouble(),
      isAvailable: json['is_available'] as bool? ?? true,
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      images: imagesList,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: json['ratings_count'] as int? ?? 0,
      ratings: ratingsList,
      createdAt: json['created_at'] as String?,
    );
  }
}
