import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart' as ll;

import 'models.dart';
import 'supabase_config.dart';

final supabase = Supabase.instance.client;

class AuthService {
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    final resp = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await _ensureProfileForCurrentUser();
    return resp;
  }

  Future<AuthResponse> signUpWithEmail(String email, String password, String name, String role) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': role},
    );
    
    if (response.user != null) {
      // Create user profile with chosen role
      await _createUserProfile(response.user!, name, role);
    }
    
    return response;
  }

  Future<bool> signInWithGoogle() async {
    // Note: This requires additional setup for Google OAuth in Supabase
    final ok = await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.mukhostelapp://login-callback/',
    );
    await _ensureProfileForCurrentUser();
    return ok;
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;
  
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  Future<void> _createUserProfile(User user, String name, String role) async {
    final userProfile = AppUser(
      id: user.id,
      name: name,
      email: user.email ?? '',
      role: role,
      createdAt: DateTime.now().toUtc(),
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
    );

    await supabase.from('profiles').upsert(userProfile.toJson());
  }

  Future<void> syncCurrentUserProfile() async {
    await _ensureProfileForCurrentUser();
  }

  Future<void> _ensureProfileForCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final metadataRole = (user.userMetadata?['role'] as String?)?.toLowerCase() ?? 'student';
    final name = (user.userMetadata?['name'] as String?) ?? (user.email ?? '');
    final existing = await supabase
        .from('profiles')
        .select('id, role')
        .eq('id', user.id)
        .maybeSingle();
    if (existing == null) {
      await _createUserProfile(user, name, metadataRole);
    } else {
      if ((existing['role'] as String?)?.toLowerCase() != metadataRole) {
        await supabase.from('profiles').update({
          'role': metadataRole,
          'name': name,
          'email': user.email,
        }).eq('id', user.id);
      }
    }
  }

  Future<void> forceSetRole(String role) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    // Update auth metadata role
    await supabase.auth.updateUser(UserAttributes(data: {'role': role}));
    // Ensure profile reflects role
    final existing = await supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (existing == null) {
      await _createUserProfile(user, user.email ?? '', role);
    } else {
      await supabase
          .from('profiles')
          .update({'role': role})
          .eq('id', user.id);
    }
  }
}

class HostelService {
  Future<List<Hostel>> getHostels({
    int? minPrice,
    int? maxPrice,
    List<String>? amenities,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    var query = supabase.from('hostels').select('*');

    if (minPrice != null) {
      query = query.gte('price', minPrice);
    }
    if (maxPrice != null) {
      query = query.lte('price', maxPrice);
    }
    if (amenities != null && amenities.isNotEmpty) {
      query = query.contains('amenities', amenities);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => Hostel.fromJson(json)).toList();
  }

  // Geocoding with Nominatim (OpenStreetMap) – free, usage-limited
  Future<ll.LatLng?> geocodeAddress(String query) async {
    final uri = Uri.parse('https://nominatim.openstreetmap.org/search'
        '?format=json&limit=1&q=${Uri.encodeComponent(query)}');
    final res = await http.get(uri, headers: {
      'User-Agent': 'mukhostelapp/1.0 (contact: example@example.com)'
    });
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data is List && data.isNotEmpty) {
        final item = data.first;
        final lat = double.tryParse(item['lat'] ?? '');
        final lon = double.tryParse(item['lon'] ?? '');
        if (lat != null && lon != null) {
          return ll.LatLng(lat, lon);
        }
      }
    }
    return null;
  }

  Future<String?> reverseGeocode(double lat, double lon) async {
    final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2&lat=$lat&lon=$lon');
    final res = await http.get(uri, headers: {
      'User-Agent': 'mukhostelapp/1.0 (contact: example@example.com)'
    });
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final display = data['display_name'] as String?;
      return display;
    }
    return null;
  }

  Stream<List<Hostel>> watchHostels() {
    return supabase
        .from('hostels')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Hostel.fromJson(json)).toList());
  }

  Future<Hostel?> getHostel(String id) async {
    final response = await supabase
        .from('hostels')
        .select('*')
        .eq('id', id)
        .single();
    
    return Hostel.fromJson(response);
  }

  Future<String> createHostel(Hostel hostel) async {
    final response = await supabase
        .from('hostels')
        .insert(hostel.toJson())
        .select('id')
        .single();
    
    return response['id'] as String;
  }

  Future<void> updateHostel(String id, Map<String, dynamic> updates) async {
    await supabase
        .from('hostels')
        .update({...updates, 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  Future<void> deleteHostel(String id) async {
    // First, get the hostel to access image URLs
    final hostelResponse = await supabase
        .from('hostels')
        .select('image_urls')
        .eq('id', id)
        .single();
    
    final imageUrls = List<String>.from(hostelResponse['image_urls'] ?? []);
    
    // Delete all associated images
    for (final imageUrl in imageUrls) {
      try {
        await deleteImage(imageUrl);
      } catch (e) {
        // Continue deleting other images even if one fails
        // Log error silently - could use a proper logging service in production
      }
    }
    
    // Delete the hostel record
    await supabase.from('hostels').delete().eq('id', id);
  }

  Future<String> uploadImage(File imageFile, String hostelId) async {
    final bytes = await imageFile.readAsBytes();
    final fileExt = imageFile.path.split('.').last;
    final fileName = '${const Uuid().v4()}.$fileExt';
    final filePath = 'hostels/$hostelId/$fileName';

    await supabase.storage
        .from(SupabaseConfig.imagesBucket)
        .uploadBinary(filePath, bytes);

    return supabase.storage
        .from(SupabaseConfig.imagesBucket)
        .getPublicUrl(filePath);
  }

  Future<String> uploadImageFromBytes(Uint8List bytes, String fileName, String hostelId) async {
    final filePath = 'hostels/$hostelId/$fileName';

    await supabase.storage
        .from(SupabaseConfig.imagesBucket)
        .uploadBinary(filePath, bytes);

    return supabase.storage
        .from(SupabaseConfig.imagesBucket)
        .getPublicUrl(filePath);
  }

  Future<void> deleteImage(String imageUrl) async {
    // Extract file path from URL
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;
    final filePath = pathSegments.skip(pathSegments.indexOf('object') + 2).join('/');
    
    await supabase.storage
        .from(SupabaseConfig.imagesBucket)
        .remove([filePath]);
  }
}

class ReviewService {
  Future<List<Review>> getReviews(String hostelId) async {
    final response = await supabase
        .from('reviews')
        .select('*')
        .eq('hostel_id', hostelId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Review.fromJson(json)).toList();
  }

  Stream<List<Review>> watchReviews(String hostelId) {
    return supabase
        .from('reviews')
        .stream(primaryKey: ['id'])
        .eq('hostel_id', hostelId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Review.fromJson(json)).toList());
  }

  Future<void> createReview(Review review) async {
    await supabase.from('reviews').insert(review.toJson());
    
    // Update hostel rating and review count
    await _updateHostelRating(review.hostelId);
  }

  Future<void> updateReview(String id, Map<String, dynamic> updates) async {
    final review = await supabase
        .from('reviews')
        .select('hostel_id')
        .eq('id', id)
        .single();
    
    await supabase
        .from('reviews')
        .update({...updates, 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
    
    // Update hostel rating
    await _updateHostelRating(review['hostel_id']);
  }

  Future<void> deleteReview(String id) async {
    final review = await supabase
        .from('reviews')
        .select('hostel_id')
        .eq('id', id)
        .single();
    
    await supabase.from('reviews').delete().eq('id', id);
    
    // Update hostel rating
    await _updateHostelRating(review['hostel_id']);
  }

  Future<void> _updateHostelRating(String hostelId) async {
    final reviews = await supabase
        .from('reviews')
        .select('rating')
        .eq('hostel_id', hostelId);

    if (reviews.isEmpty) {
      await supabase
          .from('hostels')
          .update({
            'rating': null,
            'review_count': 0,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', hostelId);
      return;
    }

    final ratings = (reviews as List).map((r) => r['rating'] as int).toList();
    final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;

    await supabase
        .from('hostels')
        .update({
          'rating': avgRating,
          'review_count': ratings.length,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', hostelId);
  }
}

class FavoritesService {
  Future<List<String>> getFavoriteIds(String userId) async {
    final response = await supabase
        .from('favorites')
        .select('hostel_id')
        .eq('user_id', userId);

    return (response as List).map((item) => item['hostel_id'] as String).toList();
  }

  Stream<List<String>> watchFavoriteIds(String userId) {
    return supabase
        .from('favorites')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map((item) => item['hostel_id'] as String).toList());
  }

  Future<void> toggleFavorite(String userId, String hostelId) async {
    final existing = await supabase
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('hostel_id', hostelId);

    if (existing.isEmpty) {
      // Add to favorites
      await supabase.from('favorites').insert({
        'user_id': userId,
        'hostel_id': hostelId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } else {
      // Remove from favorites
      await supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('hostel_id', hostelId);
    }
  }

  Future<List<Hostel>> getFavoriteHostels(String userId) async {
    final response = await supabase
        .from('favorites')
        .select('hostel_id, hostels(*)')
        .eq('user_id', userId);

    return (response as List)
        .map((item) => Hostel.fromJson(item['hostels']))
        .toList();
  }
}

class UserService {
  Future<AppUser?> getUserProfile(String userId) async {
    final response = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();

    return response != null ? AppUser.fromJson(response) : null;
  }

  Stream<AppUser?> watchUserProfile(String userId) {
    return supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => data.isNotEmpty ? AppUser.fromJson(data.first) : null);
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    await supabase
        .from('profiles')
        .update(updates)
        .eq('id', userId);
  }
}