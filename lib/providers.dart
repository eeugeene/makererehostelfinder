import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';
import 'services.dart';

// Service providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final hostelServiceProvider = Provider<HostelService>((ref) => HostelService());
final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());
final favoritesServiceProvider = Provider<FavoritesService>((ref) => FavoritesService());
final userServiceProvider = Provider<UserService>((ref) => UserService());

// Auth providers
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value.session?.user;
});

// User profile provider
final userProfileProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
  return ref.watch(userServiceProvider).watchUserProfile(user.id);
});

// Hostels providers
final hostelsProvider = StreamProvider<List<Hostel>>((ref) {
  // auto refresh on invalidation
  return ref.watch(hostelServiceProvider).watchHostels();
});

final hostelProvider = StreamProvider.family<Hostel?, String>((ref, hostelId) {
  // stream all hostels, pick the one matching id, or null if not present
  return ref
      .watch(hostelServiceProvider)
      .watchHostels()
      .map((list) {
        try {
          return list.firstWhere((h) => h.id == hostelId);
        } catch (_) {
          return null;
        }
      });
});

// Reviews provider
final reviewsProvider = StreamProvider.family<List<Review>, String>((ref, hostelId) {
  return ref.watch(reviewServiceProvider).watchReviews(hostelId);
});

// Favorites providers
final favoritesProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
  return ref.watch(favoritesServiceProvider).watchFavoriteIds(user.id);
});

final favoriteHostelsProvider = Provider<List<Hostel>>((ref) {
  final favoritesIdsAsync = ref.watch(favoritesProvider);
  final hostelsAsync = ref.watch(hostelsProvider);
  final ids = favoritesIdsAsync.asData?.value ?? const <String>[];
  final allHostels = hostelsAsync.asData?.value ?? const <Hostel>[];
  return allHostels.where((h) => ids.contains(h.id)).toList();
});

// Manager's own hostels
final managerHostelsProvider = Provider<List<Hostel>>((ref) {
  final user = ref.watch(currentUserProvider);
  final hostelsAsync = ref.watch(hostelsProvider);
  final allHostels = hostelsAsync.asData?.value ?? const <Hostel>[];
  
  if (user == null) return <Hostel>[];
  
  return allHostels.where((h) => h.createdBy == user.id).toList();
});

// Search and filter providers
final searchQueryProvider = StateProvider<String>((ref) => '');
final priceRangeProvider = StateProvider<RangeValues>((ref) => const RangeValues(0, 10000000));
final selectedAmenitiesProvider = StateProvider<List<String>>((ref) => []);

// Discrete filter bands inspired by the provided designs
final selectedPriceBandsProvider = StateProvider<Set<String>>((ref) => <String>{});
final selectedDistanceBandsProvider = StateProvider<Set<String>>((ref) => <String>{});

// Campus location for distance calculations (Makerere University approximate coords)
const makerereCampus = ll.LatLng(0.3350, 32.5680);
final _distanceEngineProvider = Provider<ll.Distance>((ref) => const ll.Distance());

double _distanceKm(ll.Distance engine, double lat, double lng) {
  return engine.as(ll.LengthUnit.Kilometer, makerereCampus, ll.LatLng(lat, lng));
}

final filteredHostelsProvider = Provider<List<Hostel>>((ref) {
  final hostels = ref.watch(hostelsProvider).asData?.value ?? [];
  final searchQuery = ref.watch(searchQueryProvider);
  final priceRange = ref.watch(priceRangeProvider);
  final selectedAmenities = ref.watch(selectedAmenitiesProvider);
  final priceBands = ref.watch(selectedPriceBandsProvider);
  final distanceBands = ref.watch(selectedDistanceBandsProvider);
  final engine = ref.watch(_distanceEngineProvider);

  return hostels.where((hostel) {
    // Search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      if (!hostel.name.toLowerCase().contains(query) &&
          !hostel.description.toLowerCase().contains(query)) {
        return false;
      }
    }

    // Price range slider filter
    if (hostel.price < priceRange.start || hostel.price > priceRange.end) {
      return false;
    }

    // Discrete price bands (any-match)
    if (priceBands.isNotEmpty) {
      final under100 = hostel.price < 100000 && priceBands.contains('under_100k');
      final between100And200 =
          hostel.price >= 100000 && hostel.price <= 200000 && priceBands.contains('100_200k');
      final above200 = hostel.price > 200000 && priceBands.contains('above_200k');
      if (!(under100 || between100And200 || above200)) return false;
    }

    // Amenities filter
    if (selectedAmenities.isNotEmpty) {
      final hasAllAmenities = selectedAmenities.every((amenity) =>
          hostel.amenities.contains(amenity));
      if (!hasAllAmenities) return false;
    }

    // Distance bands from campus (any-match)
    if (distanceBands.isNotEmpty) {
      final km = _distanceKm(engine, hostel.latitude, hostel.longitude);
      final under1 = km < 1.0 && distanceBands.contains('under_1km');
      final oneToTwo = km >= 1.0 && km <= 2.0 && distanceBands.contains('1_2km');
      final twoToFive = km > 2.0 && km <= 5.0 && distanceBands.contains('2_5km');
      if (!(under1 || oneToTwo || twoToFive)) return false;
    }

    return true;
  }).toList();
});

// Common amenities provider
final commonAmenitiesProvider = Provider<List<String>>((ref) {
  return [
    'WiFi',
    'Hot Water',
    'Security',
    'Meals',
    'Parking',
    'Laundry',
    'Study Room',
    'Kitchen',
    'Generator',
    'Cleaning Service',
    'CCTV',
    'Fridge',
    'TV Room',
    'Garden',
    'Balcony',
  ];
});

// UI state providers
final isLoadingProvider = StateProvider<bool>((ref) => false);
final selectedTabProvider = StateProvider<int>((ref) => 0);

// Role-aware tab index mapping
final visibleTabsProvider = Provider<List<String>>((ref) {
  final profile = ref.watch(userProfileProvider).asData?.value;
  // Tabs: home, map, saved, profile/manager
  if (profile?.role == 'manager') {
    return ['home', 'saved', 'map', 'dashboard'];
  }
  return ['home', 'saved', 'map', 'profile'];
});

// Removed custom RangeValues to avoid conflict with Flutter's RangeValues