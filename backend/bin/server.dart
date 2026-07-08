import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

// PostgreSQL connection
late final Connection conn;

void main(List<String> args) async {
  // Connect to PostgreSQL
  try {
    print('Connecting to PostgreSQL on port 5433...');
    conn = await Connection.open(
      Endpoint(
        host: '127.0.0.1',
        port: 5433,
        database: 'postgres',
        username: 'bappa',
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable,
      ),
    );
    print('Successfully connected to PostgreSQL.');
  } catch (e) {
    print('Error connecting to database: $e');
    exit(1);
  }

  // Create Router
  final router = Router();

  // Auth Endpoints
  router.post('/api/auth/register', _registerHandler);
  router.post('/api/auth/login', _loginHandler);

  // Properties Endpoints
  router.get('/api/properties', _getPropertiesHandler);
  router.get('/api/properties/<id>', _getPropertyDetailHandler);
  router.post('/api/properties', _createPropertyHandler);
  router.post('/api/properties/<id>/ratings', _createRatingHandler);

  // Middleware pipeline
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  // Start Server
  final port = int.tryParse(args.isNotEmpty ? args[0] : '') ?? 8000;
  final server = await io.serve(handler, '0.0.0.0', port);
  print('Server listening on port ${server.port}');
}

// CORS Middleware
Middleware corsHeaders() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization, X-Requested-With',
        });
      }
      final response = await innerHandler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization, X-Requested-With',
      });
    };
  };
}

// Utility to hash password
String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  return sha256.convert(bytes).toString();
}

// Utility to generate a simple base64 session token
String _generateToken(int userId, String email) {
  final payload = {
    'user_id': userId,
    'email': email,
    'exp': DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
  };
  return base64Url.encode(utf8.encode(jsonEncode(payload)));
}

// Utility to verify token and get user_id
int? _getUserIdFromRequest(Request request) {
  final authHeader = request.headers['Authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) return null;
  final token = authHeader.substring(7);
  try {
    final decoded = utf8.decode(base64Url.decode(token));
    final json = jsonDecode(decoded) as Map<String, dynamic>;
    final exp = json['exp'] as int?;
    if (exp != null && DateTime.now().millisecondsSinceEpoch > exp) {
      return null; // Expired
    }
    return json['user_id'] as int?;
  } catch (_) {
    return null;
  }
}

// Helper to safely parse double from dynamic PostgreSQL values
double? _toDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString());
}

// Response helpers
Response _jsonResponse(Map<String, dynamic> data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'Content-Type': 'application/json'},
  );
}

Response _errorResponse(String message, {int statusCode = 400}) {
  return _jsonResponse({'error': message}, statusCode: statusCode);
}

// --- Route Handlers ---

// Register User
Future<Response> _registerHandler(Request request) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final name = data['name'] as String?;
    final email = data['email'] as String?;
    final password = data['password'] as String?;
    final phone = data['phone'] as String?;
    final photo = data['photo'] as String? ?? '';
    final lat = double.tryParse(data['lat']?.toString() ?? '') ?? null;
    final long = double.tryParse(data['long']?.toString() ?? '') ?? null;

    if (name == null || name.isEmpty || email == null || email.isEmpty || password == null || password.isEmpty) {
      return _errorResponse('Name, email, and password are required.');
    }

    // Check if email already exists
    final checkResult = await conn.execute(
      Sql.named('SELECT user_id FROM users WHERE email = @email'),
      parameters: {'email': email},
    );
    if (checkResult.isNotEmpty) {
      return _errorResponse('Email is already registered.');
    }

    // Insert user
    final passwordHash = _hashPassword(password);
    final insertResult = await conn.execute(
      Sql.named(
        'INSERT INTO users (name, email, password, phone, photo, lat, long) '
        'VALUES (@name, @email, @password, @phone, @photo, @lat, @long) '
        'RETURNING user_id, name, email, phone, photo, lat, long, created_at'
      ),
      parameters: {
        'name': name,
        'email': email,
        'password': passwordHash,
        'phone': phone,
        'photo': photo,
        'lat': lat,
        'long': long,
      },
    );

    final row = insertResult.first.toColumnMap();
    final userId = row['user_id'] as int;
    final token = _generateToken(userId, email);

    return _jsonResponse({
      'token': token,
      'user': {
        'user_id': userId,
        'name': row['name'],
        'email': row['email'],
        'phone': row['phone'],
        'photo': row['photo'],
        'lat': _toDouble(row['lat']),
        'long': _toDouble(row['long']),
        'created_at': (row['created_at'] as DateTime?)?.toIso8601String(),
      }
    }, statusCode: 201);
  } catch (e) {
    return _errorResponse('Server error: $e', statusCode: 500);
  }
}

// Login User
Future<Response> _loginHandler(Request request) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final email = data['email'] as String?;
    final password = data['password'] as String?;

    if (email == null || email.isEmpty || password == null || password.isEmpty) {
      return _errorResponse('Email and password are required.');
    }

    final result = await conn.execute(
      Sql.named('SELECT * FROM users WHERE email = @email'),
      parameters: {'email': email},
    );

    if (result.isEmpty) {
      return _errorResponse('Invalid email or password.', statusCode: 401);
    }

    final row = result.first.toColumnMap();
    final dbPassword = row['password'] as String;
    final inputPasswordHash = _hashPassword(password);

    if (dbPassword != inputPasswordHash) {
      return _errorResponse('Invalid email or password.', statusCode: 401);
    }

    final userId = row['user_id'] as int;
    final token = _generateToken(userId, email);

    return _jsonResponse({
      'token': token,
      'user': {
        'user_id': userId,
        'name': row['name'],
        'email': row['email'],
        'phone': row['phone'],
        'photo': row['photo'],
        'lat': _toDouble(row['lat']),
        'long': _toDouble(row['long']),
        'created_at': (row['created_at'] as DateTime?)?.toIso8601String(),
      }
    });
  } catch (e) {
    return _errorResponse('Server error: $e', statusCode: 500);
  }
}

// Get Properties with advanced location filtering and amenities
Future<Response> _getPropertiesHandler(Request request) async {
  try {
    final params = request.url.queryParameters;

    final userLat = double.tryParse(params['lat'] ?? '');
    final userLong = double.tryParse(params['long'] ?? '');
    final radius = double.tryParse(params['radius'] ?? '5.0'); // default 5km

    final type = params['type']; // 'rent' or 'sale'
    final city = params['city'];
    final query = params['query'];
    final furnishing = params['furnishing'];
    final amenitiesParam = params['amenities']; // Comma-separated: "WiFi,AC"

    // Construct Query
    String selectSql = 'SELECT p.*, u.name as owner_name, u.phone as owner_phone, u.photo as owner_photo';
    String fromSql = ' FROM properties p JOIN users u ON p.owner_id = u.user_id';
    List<String> conditions = [];
    Map<String, dynamic> queryParams = {};

    if (userLat != null && userLong != null) {
      // Calculate spherical law of cosines distance in km
      selectSql += ', (6371 * acos(cos(radians(@userLat)) * cos(radians(p.lat::double precision)) * '
          'cos(radians(p.long::double precision) - radians(@userLong)) + '
          'sin(radians(@userLat)) * sin(radians(p.lat::double precision)))) as distance';
      conditions.add('(6371 * acos(cos(radians(@userLat)) * cos(radians(p.lat::double precision)) * '
          'cos(radians(p.long::double precision) - radians(@userLong)) + '
          'sin(radians(@userLat)) * sin(radians(p.lat::double precision)))) <= @radius');
      queryParams['userLat'] = userLat;
      queryParams['userLong'] = userLong;
      queryParams['radius'] = radius;
    } else {
      selectSql += ', NULL as distance';
    }

    if (type != null && type.isNotEmpty) {
      conditions.add('p.property_type = @type');
      queryParams['type'] = type;
    }

    if (city != null && city.isNotEmpty) {
      conditions.add('p.city ILIKE @city');
      queryParams['city'] = '%$city%';
    }

    if (furnishing != null && furnishing.isNotEmpty) {
      conditions.add('p.furnishing = @furnishing');
      queryParams['furnishing'] = furnishing;
    }

    if (query != null && query.isNotEmpty) {
      conditions.add('(p.title ILIKE @query OR p.description ILIKE @query OR p.address ILIKE @query)');
      queryParams['query'] = '%$query%';
    }

    // Combine conditions
    String whereSql = conditions.isEmpty ? '' : ' WHERE ' + conditions.join(' AND ');
    String orderSql = ' ORDER BY p.created_at DESC';

    if (userLat != null && userLong != null) {
      orderSql = ' ORDER BY distance ASC';
    }

    final sqlStr = selectSql + fromSql + whereSql + orderSql;
    final results = await conn.execute(Sql.named(sqlStr), parameters: queryParams);

    List<Map<String, dynamic>> properties = [];
    for (final row in results) {
      final pMap = row.toColumnMap();
      final pId = pMap['property_id'] as int;

      // Get images for this property
      final imgResult = await conn.execute(
        Sql.named('SELECT image_url FROM property_images WHERE property_id = @pId'),
        parameters: {'pId': pId},
      );
      final images = imgResult.map((imgRow) => imgRow[0] as String).toList();

      // Get average rating
      final ratingResult = await conn.execute(
        Sql.named('SELECT COALESCE(AVG(rating), 0) as avg_rating, COUNT(rating) as count_rating FROM ratings WHERE property_id = @pId'),
        parameters: {'pId': pId},
      );
      final ratingMap = ratingResult.first.toColumnMap();
      final avgRating = _toDouble(ratingMap['avg_rating']) ?? 0.0;
      final totalRatings = (ratingMap['count_rating'] as num?)?.toInt() ?? 0;

      final amenitiesStr = pMap['amenities'] as String? ?? '';
      final amenitiesList = amenitiesStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      // Client-side filter for required amenities if supplied
      if (amenitiesParam != null && amenitiesParam.isNotEmpty) {
        final reqAmenities = amenitiesParam.split(',').map((e) => e.trim().toLowerCase());
        final hasAll = reqAmenities.every((req) => amenitiesList.map((a) => a.toLowerCase()).contains(req));
        if (!hasAll) continue;
      }

      properties.add({
        'property_id': pId,
        'owner_id': pMap['owner_id'],
        'owner': {
          'name': pMap['owner_name'],
          'phone': pMap['owner_phone'],
          'photo': pMap['owner_photo'],
        },
        'title': pMap['title'],
        'description': pMap['description'],
        'price': _toDouble(pMap['price']),
        'property_type': pMap['property_type'],
        'furnishing': pMap['furnishing'],
        'amenities': amenitiesList,
        'address': pMap['address'],
        'city': pMap['city'],
        'lat': _toDouble(pMap['lat']),
        'long': _toDouble(pMap['long']),
        'is_available': pMap['is_available'],
        'distance': _toDouble(pMap['distance']),
        'images': images,
        'rating': avgRating,
        'ratings_count': totalRatings,
        'created_at': (pMap['created_at'] as DateTime?)?.toIso8601String(),
      });
    }

    return _jsonResponse({'properties': properties});
  } catch (e) {
    return _errorResponse('Server error: $e', statusCode: 500);
  }
}

// Get Specific Property Details
Future<Response> _getPropertyDetailHandler(Request request, String id) async {
  try {
    final propertyId = int.tryParse(id);
    if (propertyId == null) return _errorResponse('Invalid property ID.');

    final result = await conn.execute(
      Sql.named(
        'SELECT p.*, u.name as owner_name, u.phone as owner_phone, u.photo as owner_photo, u.email as owner_email '
        'FROM properties p JOIN users u ON p.owner_id = u.user_id '
        'WHERE p.property_id = @propertyId'
      ),
      parameters: {'propertyId': propertyId},
    );

    if (result.isEmpty) {
      return _errorResponse('Property not found.', statusCode: 404);
    }

    final pMap = result.first.toColumnMap();

    // Fetch images
    final imgResult = await conn.execute(
      Sql.named('SELECT image_url FROM property_images WHERE property_id = @propertyId'),
      parameters: {'propertyId': propertyId},
    );
    final images = imgResult.map((row) => row[0] as String).toList();

    // Fetch ratings & reviews with user details
    final ratingResult = await conn.execute(
      Sql.named(
        'SELECT r.*, u.name as r_name, u.photo as r_photo '
        'FROM ratings r JOIN users u ON r.user_id = u.user_id '
        'WHERE r.property_id = @propertyId ORDER BY r.created_at DESC'
      ),
      parameters: {'propertyId': propertyId},
    );

    List<Map<String, dynamic>> ratings = [];
    double ratingSum = 0.0;
    for (final rRow in ratingResult) {
      final rMap = rRow.toColumnMap();
      final rate = rMap['rating'] as int;
      ratingSum += rate;
      ratings.add({
        'rating_id': rMap['rating_id'],
        'user': {
          'name': rMap['r_name'],
          'photo': rMap['r_photo'],
        },
        'rating': rate,
        'review': rMap['review'],
        'created_at': (rMap['created_at'] as DateTime?)?.toIso8601String(),
      });
    }

    final avgRating = ratings.isEmpty ? 0.0 : ratingSum / ratings.length;

    final amenitiesStr = pMap['amenities'] as String? ?? '';
    final amenitiesList = amenitiesStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final propertyDetail = {
      'property_id': propertyId,
      'owner_id': pMap['owner_id'],
      'owner': {
        'name': pMap['owner_name'],
        'phone': pMap['owner_phone'],
        'photo': pMap['owner_photo'],
        'email': pMap['owner_email'],
      },
      'title': pMap['title'],
      'description': pMap['description'],
      'price': _toDouble(pMap['price']),
      'property_type': pMap['property_type'],
      'furnishing': pMap['furnishing'],
      'amenities': amenitiesList,
      'address': pMap['address'],
      'city': pMap['city'],
      'lat': _toDouble(pMap['lat']),
      'long': _toDouble(pMap['long']),
      'is_available': pMap['is_available'],
      'images': images,
      'rating': avgRating,
      'ratings_count': ratings.length,
      'ratings': ratings,
      'created_at': (pMap['created_at'] as DateTime?)?.toIso8601String(),
    };

    return _jsonResponse(propertyDetail);
  } catch (e) {
    return _errorResponse('Server error: $e', statusCode: 500);
  }
}

// Create Property Listing (Protected)
Future<Response> _createPropertyHandler(Request request) async {
  try {
    final userId = _getUserIdFromRequest(request);
    if (userId == null) {
      return _errorResponse('Unauthorized.', statusCode: 401);
    }

    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final title = data['title'] as String?;
    final description = data['description'] as String? ?? '';
    final price = double.tryParse(data['price']?.toString() ?? '');
    final propertyType = data['property_type'] as String? ?? 'rent';
    final furnishing = data['furnishing'] as String? ?? 'unfurnished';
    final amenities = data['amenities'] as List<dynamic>? ?? []; // Array in JSON
    final address = data['address'] as String?;
    final city = data['city'] as String?;
    final lat = double.tryParse(data['lat']?.toString() ?? '') ?? 37.7749;
    final long = double.tryParse(data['long']?.toString() ?? '') ?? -122.4194;
    final imageUrls = data['images'] as List<dynamic>? ?? [];

    if (title == null || title.isEmpty || price == null || address == null || address.isEmpty || city == null || city.isEmpty) {
      return _errorResponse('Title, price, address, and city are required fields.');
    }

    final amenitiesStr = amenities.map((e) => e.toString().trim()).join(',');

    // Insert property
    final insertResult = await conn.execute(
      Sql.named(
        'INSERT INTO properties (owner_id, title, description, price, property_type, furnishing, amenities, address, city, lat, long, is_available) '
        'VALUES (@ownerId, @title, @description, @price, @propertyType, @furnishing, @amenities, @address, @city, @lat, @long, true) '
        'RETURNING property_id'
      ),
      parameters: {
        'ownerId': userId,
        'title': title,
        'description': description,
        'price': price,
        'propertyType': propertyType,
        'furnishing': furnishing,
        'amenities': amenitiesStr,
        'address': address,
        'city': city,
        'lat': lat,
        'long': long,
      },
    );

    final newPropertyId = insertResult.first[0] as int;

    // Insert images
    for (final imgUrl in imageUrls) {
      if (imgUrl.toString().isNotEmpty) {
        await conn.execute(
          Sql.named('INSERT INTO property_images (property_id, image_url) VALUES (@propertyId, @imageUrl)'),
          parameters: {
            'propertyId': newPropertyId,
            'imageUrl': imgUrl.toString(),
          },
        );
      }
    }

    return _jsonResponse({'property_id': newPropertyId, 'message': 'Property listed successfully.'}, statusCode: 201);
  } catch (e) {
    return _errorResponse('Server error: $e', statusCode: 500);
  }
}

// Create Rating / Review (Protected)
Future<Response> _createRatingHandler(Request request, String id) async {
  try {
    final userId = _getUserIdFromRequest(request);
    if (userId == null) {
      return _errorResponse('Unauthorized.', statusCode: 401);
    }

    final propertyId = int.tryParse(id);
    if (propertyId == null) return _errorResponse('Invalid property ID.');

    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final rating = int.tryParse(data['rating']?.toString() ?? '');
    final review = data['review'] as String? ?? '';

    if (rating == null || rating < 1 || rating > 5) {
      return _errorResponse('Rating is required and must be between 1 and 5.');
    }

    // Verify property exists
    final checkResult = await conn.execute(
      Sql.named('SELECT property_id FROM properties WHERE property_id = @propertyId'),
      parameters: {'propertyId': propertyId},
    );
    if (checkResult.isEmpty) {
      return _errorResponse('Property not found.', statusCode: 404);
    }

    // Insert rating
    await conn.execute(
      Sql.named('INSERT INTO ratings (user_id, property_id, rating, review) VALUES (@userId, @propertyId, @rating, @review)'),
      parameters: {
        'userId': userId,
        'propertyId': propertyId,
        'rating': rating,
        'review': review,
      },
    );

    return _jsonResponse({'message': 'Rating added successfully.'}, statusCode: 201);
  } catch (e) {
    return _errorResponse('Server error: $e', statusCode: 500);
  }
}
