import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  // Dart server base URL
  static const String baseUrl = 'http://localhost:8000/api';

  // Helper for headers
  static Map<String, String> _headers([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Login
  static Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String;
        final userJson = data['user'] as Map<String, dynamic>;
        return User.fromJson(userJson, token: token);
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Register
  static Future<User?> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? photo,
    double? lat,
    double? long,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'photo': photo,
          'lat': lat,
          'long': long,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String;
        final userJson = data['user'] as Map<String, dynamic>;
        return User.fromJson(userJson, token: token);
      }
      return null;
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  // Fetch properties with filters
  static Future<List<Property>> getProperties({
    double? lat,
    double? long,
    double? radius,
    String? type,
    String? city,
    String? query,
    String? furnishing,
    List<String>? amenities,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (lat != null && long != null) {
        queryParams['lat'] = lat.toString();
        queryParams['long'] = long.toString();
        if (radius != null) {
          queryParams['radius'] = radius.toString();
        }
      }
      if (type != null && type.isNotEmpty && type != 'all') {
        queryParams['type'] = type;
      }
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }
      if (furnishing != null && furnishing.isNotEmpty && furnishing != 'all') {
        queryParams['furnishing'] = furnishing;
      }
      if (amenities != null && amenities.isNotEmpty) {
        queryParams['amenities'] = amenities.join(',');
      }

      final uri = Uri.parse('$baseUrl/properties').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['properties'] as List<dynamic>;
        return list.map((item) => Property.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('GetProperties error: $e');
      return [];
    }
  }

  // Fetch specific property details
  static Future<Property?> getPropertyDetail(int propertyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/$propertyId'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Property.fromJson(data);
      }
      return null;
    } catch (e) {
      print('GetPropertyDetail error: $e');
      return null;
    }
  }

  // List a new property (Protected)
  static Future<bool> createProperty({
    required String token,
    required String title,
    required String description,
    required double price,
    required String propertyType,
    required String furnishing,
    required List<String> amenities,
    required String address,
    required String city,
    required double lat,
    required double long,
    required List<String> images,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/properties'),
        headers: _headers(token),
        body: jsonEncode({
          'title': title,
          'description': description,
          'price': price,
          'property_type': propertyType,
          'furnishing': furnishing,
          'amenities': amenities,
          'address': address,
          'city': city,
          'lat': lat,
          'long': long,
          'images': images,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('CreateProperty error: $e');
      return false;
    }
  }

  // Add rating and review (Protected)
  static Future<bool> addRating({
    required String token,
    required int propertyId,
    required int rating,
    required String review,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/properties/$propertyId/ratings'),
        headers: _headers(token),
        body: jsonEncode({
          'rating': rating,
          'review': review,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('AddRating error: $e');
      return false;
    }
  }
}
