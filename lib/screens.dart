import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'providers.dart';

// Main navigation screen with bottom navigation
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);
    final tabs = ref.watch(visibleTabsProvider);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(selectedTab),
          child: IndexedStack(
            index: selectedTab,
            children: [
              const HostelListScreen(),
              const MapScreen(),
              const SavedHostelsScreen(),
              if (tabs.last == 'dashboard') const ManagerDashboardScreen() else const ProfileScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedTab,
          onDestinationSelected: (index) {
            ref.read(selectedTabProvider.notifier).state = index;
            if (index == 0) {
              ref.invalidate(hostelsProvider);
              ref.invalidate(favoritesProvider);
              ref.invalidate(favoriteHostelsProvider);
            } else if (index == 2) {
              ref.invalidate(favoritesProvider);
              ref.invalidate(favoriteHostelsProvider);
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: selectedTab == 0 ? const Color(0xFF2E7D32).withValues(alpha: 0.1) : Colors.transparent,
                ),
                child: const Icon(Icons.explore_outlined),
              ),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.explore, color: Color(0xFF2E7D32)),
              ),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: selectedTab == 1 ? const Color(0xFF1976D2).withValues(alpha: 0.1) : Colors.transparent,
                ),
                child: const Icon(Icons.map_outlined),
              ),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF1976D2).withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.map, color: Color(0xFF1976D2)),
              ),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: selectedTab == 2 ? const Color(0xFFD32F2F).withValues(alpha: 0.1) : Colors.transparent,
                ),
                child: const Icon(Icons.favorite_outline),
              ),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.favorite, color: Color(0xFFD32F2F)),
              ),
              label: 'Saved',
            ),
            NavigationDestination(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: selectedTab == 3 ? const Color(0xFF2E7D32).withValues(alpha: 0.1) : Colors.transparent,
                ),
                child: tabs.last == 'dashboard' ? const Icon(Icons.dashboard_outlined) : const Icon(Icons.person_outline),
              ),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                ),
                child: tabs.last == 'dashboard' 
                  ? const Icon(Icons.dashboard, color: Color(0xFF2E7D32))
                  : const Icon(Icons.person, color: Color(0xFF2E7D32)),
              ),
              label: tabs.last == 'dashboard' ? 'Dashboard' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// Airbnb-style hostel list screen
class HostelListScreen extends ConsumerWidget {
  const HostelListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredHostels = ref.watch(filteredHostelsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(hostelsProvider);
          ref.invalidate(favoritesProvider);
          ref.invalidate(favoriteHostelsProvider);
        },
        child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 100,
            backgroundColor: const Color(0xFFD7E5D2),
            foregroundColor: Colors.black87,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            elevation: 4,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Makerere Hostel Finder',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFD7E5D2),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => _showFilterBottomSheet(context, ref),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SearchBar(
                hintText: 'Search hostels...',
                leading: const Icon(Icons.search),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              ),
            ),
          ),
          // Quick filter chips row (price bands, distance, amenities)
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _QuickFilterChip(
                    label: 'Under UGX 100K',
                    keyName: 'under_100k',
                    provider: selectedPriceBandsProvider,
                  ),
                  _QuickFilterChip(
                    label: 'UGX 100K - 200K',
                    keyName: '100_200k',
                    provider: selectedPriceBandsProvider,
                  ),
                  _QuickFilterChip(
                    label: 'Above UGX 200K',
                    keyName: 'above_200k',
                    provider: selectedPriceBandsProvider,
                  ),
                  const SizedBox(width: 12),
                  _QuickFilterChip(
                    label: 'Under 1km',
                    keyName: 'under_1km',
                    provider: selectedDistanceBandsProvider,
                  ),
                  _QuickFilterChip(
                    label: '1-2km',
                    keyName: '1_2km',
                    provider: selectedDistanceBandsProvider,
                  ),
                  _QuickFilterChip(
                    label: '2-5km',
                    keyName: '2_5km',
                    provider: selectedDistanceBandsProvider,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final hostel = filteredHostels[index];
                  return HostelCard(hostel: hostel);
                },
                childCount: filteredHostels.length,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const FilterBottomSheet(),
    );
  }
}

// Airbnb-style hostel card
class HostelCard extends ConsumerStatefulWidget {
  final Hostel hostel;

  const HostelCard({super.key, required this.hostel});

  @override
  ConsumerState<HostelCard> createState() => _HostelCardState();
}

class _HostelCardState extends ConsumerState<HostelCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.asData?.value.contains(widget.hostel.id) ?? false;
    final km = _computeDistanceKm(widget.hostel.latitude, widget.hostel.longitude);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: InkWell(
              onTapDown: (_) {
                _animationController.forward();
              },
              onTapUp: (_) {
                _animationController.reverse();
              },
              onTapCancel: () {
                _animationController.reverse();
              },
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => 
                        HostelDetailScreen(hostelId: widget.hostel.id),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: child,
                        ),
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel with distance badge
            Stack(
              children: [
                SizedBox(
                  height: 220,
                  child: widget.hostel.imageUrls.isNotEmpty
                      ? PageView.builder(
                          itemCount: widget.hostel.imageUrls.length,
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: CachedNetworkImage(
                                  imageUrl: widget.hostel.imageUrls[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.grey[200]!,
                                          Colors.grey[300]!,
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.grey[200]!,
                                          Colors.grey[300]!,
                                        ],
                                      ),
                                    ),
                                    child: const Icon(Icons.image_not_supported, 
                                      size: 48, color: Colors.grey),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF2E7D32).withValues(alpha: 0.1),
                                const Color(0xFF2E7D32).withValues(alpha: 0.2),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.home_outlined,
                              size: 64,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                ),
                // Distance badge
                if (km != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${km.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Favorite button
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          key: ValueKey(isFavorite),
                          color: isFavorite ? Colors.red : Colors.grey[600],
                        ),
                      ),
                      onPressed: () async {
                        final user = ref.read(currentUserProvider);
                        if (user != null) {
                          await ref.read(favoritesServiceProvider).toggleFavorite(
                            user.id,
                            widget.hostel.id,
                          );
                          // Optimistic UI refresh
                          ref.invalidate(favoritesProvider);
                          ref.invalidate(favoriteHostelsProvider);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.hostel.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (widget.hostel.rating != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          widget.hostel.rating!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${widget.hostel.reviewCount} reviews)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    widget.hostel.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Amenities chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.hostel.amenities.take(3).map((amenity) {
                      return Chip(
                        label: Text(
                          amenity,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'UGX ${NumberFormat('#,###').format(widget.hostel.price)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            TextSpan(
                              text: ' / month',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.hostel.isAvailable
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.hostel.isAvailable ? 'Available' : 'Full',
                          style: TextStyle(
                            color: widget.hostel.isAvailable ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ))));
  }
}

double? _computeDistanceKm(double lat, double lng) {
  try {
    const campus = ll.LatLng(0.3350, 32.5680);
    final d = const ll.Distance();
    return d.as(ll.LengthUnit.Kilometer, campus, ll.LatLng(lat, lng));
  } catch (_) {
    return null;
  }
}

// Filter bottom sheet
class FilterBottomSheet extends ConsumerWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceRange = ref.watch(priceRangeProvider);
    final selectedAmenities = ref.watch(selectedAmenitiesProvider);
    final commonAmenities = ref.watch(commonAmenitiesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(priceRangeProvider.notifier).state =
                          const RangeValues(0, 10000000);
                      ref.read(selectedAmenitiesProvider.notifier).state = [];
                    },
                    child: const Text('Clear all'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Price range
                    Text(
                      'Price Range (UGX)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    RangeSlider(
                      values: priceRange,
                      min: 0,
                      max: 10000000,
                      divisions: 20,
                      labels: RangeLabels(
                        NumberFormat('#,###').format(priceRange.start),
                        NumberFormat('#,###').format(priceRange.end),
                      ),
                      onChanged: (values) {
                        ref.read(priceRangeProvider.notifier).state = values;
                      },
                    ),
                    const SizedBox(height: 30),
                    // Amenities
                    Text(
                      'Amenities',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: commonAmenities.map((amenity) {
                        final isSelected = selectedAmenities.contains(amenity);
                        return FilterChip(
                          label: Text(
                            amenity,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                          selectedColor: const Color(0xFF2E7D32),
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            final current = [...selectedAmenities];
                            if (selected) {
                              current.add(amenity);
                            } else {
                              current.remove(amenity);
                            }
                            ref.read(selectedAmenitiesProvider.notifier).state = current;
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Detailed hostel screen
class HostelDetailScreen extends ConsumerWidget {
  final String hostelId;

  const HostelDetailScreen({super.key, required this.hostelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostelAsync = ref.watch(hostelProvider(hostelId));
    final reviewsAsync = ref.watch(reviewsProvider(hostelId));

    return Scaffold(
      body: hostelAsync.when(
        data: (hostel) {
          if (hostel == null) {
            return const Center(child: Text('Hostel not found'));
          }
          return _buildHostelDetail(context, ref, hostel, reviewsAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildHostelDetail(BuildContext context, WidgetRef ref, Hostel hostel, AsyncValue<List<Review>> reviewsAsync) {
    return CustomScrollView(
      slivers: [
        // Image gallery app bar
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          actions: [
            Consumer(
              builder: (context, ref, child) {
                final currentUser = ref.watch(currentUserProvider);
                final isOwner = currentUser?.id == hostel.createdBy;
                
                if (isOwner) {
                  return PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final shouldDelete = await _showDeleteConfirmationDialog(context, hostel.name);
                        if (shouldDelete == true && context.mounted) {
                          await _deleteHostelFromDetail(context, ref, hostel.id);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Listing'),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: hostel.imageUrls.isNotEmpty
                ? PageView.builder(
                    itemCount: hostel.imageUrls.length,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: hostel.imageUrls[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.home, size: 80),
                  ),
          ),
        ),
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hostel.name,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (hostel.rating != null)
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  hostel.rating!.toStringAsFixed(1),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${hostel.reviewCount} reviews)',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'UGX ${NumberFormat('#,###').format(hostel.price)}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          'per month',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Description
                Text(
                  'About this hostel',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hostel.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                // Amenities
                Text(
                  'Amenities',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: hostel.amenities.map((amenity) {
                    return Chip(
                      label: Text(
                        amenity,
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // Contact info
                Text(
                  'Contact Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hostel.contactInfo,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                // Location & directions
                Text(
                  'Location & Directions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 160,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: ll.LatLng(hostel.latitude, hostel.longitude),
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.mukhostel.mukhostelapp',
                        ),
                        MarkerLayer(markers: [
                          Marker(
                            point: ll.LatLng(hostel.latitude, hostel.longitude),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openDirections(hostel.latitude, hostel.longitude),
                    icon: const Icon(Icons.directions),
                    label: const Text('Get Directions'),
                  ),
                ),
                const SizedBox(height: 20),
                // Reviews section
                Text(
                  'Reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                reviewsAsync.when(
                  data: (reviews) => reviews.isEmpty
                      ? const Text('No reviews yet')
                      : Column(
                          children: reviews.take(5).map((review) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            review.userName,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(5, (index) {
                                            return Icon(
                                              index < review.rating ? Icons.star : Icons.star_border,
                                              color: Colors.amber,
                                              size: 16,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(review.comment),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat.yMMMd().format(review.createdAt),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error loading reviews: $error'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickFilterChip extends ConsumerWidget {
  final String label;
  final String keyName;
  final StateProvider<Set<String>> provider;

  const _QuickFilterChip({required this.label, required this.keyName, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(provider);
    final isSelected = selected.contains(keyName);
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2E7D32),
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
        selectedColor: const Color(0xFF2E7D32),
        checkmarkColor: Colors.white,
        onSelected: (v) {
          final current = {...ref.read(provider)};
          if (v) {
            current.add(keyName);
          } else {
            current.remove(keyName);
          }
          ref.read(provider.notifier).state = current;
        },
      ),
    );
  }
}

Future<bool?> _showDeleteConfirmationDialog(BuildContext context, String hostelName) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Delete Listing'),
        content: Text(
          'Are you sure you want to delete "$hostelName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}

Future<void> _deleteHostelFromDetail(BuildContext context, WidgetRef ref, String hostelId) async {
  try {
    final hostelService = ref.read(hostelServiceProvider);
    await hostelService.deleteHostel(hostelId);
    
    // Refresh the hostels list
    ref.invalidate(hostelsProvider);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hostel deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate back to dashboard
      Navigator.of(context).pop();
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting hostel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _openDirections(double lat, double lng) async {
  // Prefer maps:// on Android; fall back to https
  final mapsUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
  final httpsUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking');
  if (await canLaunchUrl(mapsUri)) {
    await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    return;
  }
  await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
}

// Saved hostels screen
class SavedHostelsScreen extends ConsumerWidget {
  const SavedHostelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedHostels = ref.watch(favoriteHostelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Hostels'),
        centerTitle: true,
      ),
      body: savedHostels.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No saved hostels yet'),
                  SizedBox(height: 8),
                  Text('Start exploring to save your favorites!'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(favoritesProvider);
                ref.invalidate(favoriteHostelsProvider);
              },
              child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedHostels.length,
              itemBuilder: (context, index) {
                return HostelCard(hostel: savedHostels[index]);
              },
              ),
            ),
    );
  }
}

// Manager dashboard screen
class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends ConsumerState<ManagerDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  
  final List<String> _selectedAmenities = [];
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commonAmenities = ref.watch(commonAmenitiesProvider);
    final hostelService = ref.watch(hostelServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Existing Listings Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Listings',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer(
                        builder: (context, ref, child) {
                          final managerHostels = ref.watch(managerHostelsProvider);
                          
                          if (managerHostels.isEmpty) {
                            return const Text('No listings yet. Create your first listing below!');
                          }
                          
                          return Column(
                            children: managerHostels.map((hostel) => Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: hostel.imageUrls.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: hostel.imageUrls.first,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.home),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.home),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.home),
                                    ),
                                title: Text(
                                  hostel.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('UGX ${NumberFormat('#,###').format(hostel.price)}/month'),
                                    Text(
                                      hostel.isAvailable ? 'Available' : 'Full',
                                      style: TextStyle(
                                        color: hostel.isAvailable ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'delete') {
                                      final shouldDelete = await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext dialogContext) {
                                          return AlertDialog(
                                            title: const Text('Delete Listing'),
                                            content: Text(
                                              'Are you sure you want to delete "${hostel.name}"? This action cannot be undone.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(dialogContext).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(dialogContext).pop(true),
                                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      
                                      if (shouldDelete == true) {
                                        try {
                                          final hostelService = ref.read(hostelServiceProvider);
                                          await hostelService.deleteHostel(hostel.id);
                                          
                                          // Refresh the hostels list
                                          ref.invalidate(hostelsProvider);
                                          ref.invalidate(managerHostelsProvider);
                                          
                                          // Force immediate refresh
                                          await Future.delayed(const Duration(milliseconds: 100));
                                          ref.refresh(hostelsProvider);
                                          ref.refresh(managerHostelsProvider);
                                          
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Hostel deleted successfully'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error deleting hostel: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HostelDetailScreen(hostelId: hostel.id),
                                    ),
                                  );
                                },
                              ),
                            )).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Add New Listing Form
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Listing',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
            
            // Basic Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Hostel Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter hostel name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (UGX per month)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter price';
                        }
                        if (int.tryParse(value!) == null) {
                          return 'Please enter valid price';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Location
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Search address or place (e.g., "Makerere Senior Common Room")',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () async {
                            final query = _addressController.text.trim();
                            if (query.isEmpty) return;
                            final pos = await hostelService.geocodeAddress(query);
                            if (mounted) {
                              if (pos != null) {
                                _latController.text = pos.latitude.toStringAsFixed(6);
                                _lngController.text = pos.longitude.toStringAsFixed(6);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No results. Try a more specific address.')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push<ll.LatLng?>(
                            MaterialPageRoute(builder: (_) => const MapPickerScreen()),
                          );
                          if (result != null) {
                            _latController.text = result.latitude.toStringAsFixed(6);
                            _lngController.text = result.longitude.toStringAsFixed(6);
                            final addr = await hostelService.reverseGeocode(result.latitude, result.longitude);
                            if (addr != null) {
                              _addressController.text = addr;
                            }
                          }
                        },
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: const Text('Pick on map'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Required';
                              }
                              if (double.tryParse(value!) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Required';
                              }
                              if (double.tryParse(value!) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Information',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter contact information';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Amenities
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amenities',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: commonAmenities.map((amenity) {
                        final isSelected = _selectedAmenities.contains(amenity);
                        return FilterChip(
                          label: Text(
                            amenity,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                          selectedColor: const Color(0xFF2E7D32),
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAmenities.add(amenity);
                              } else {
                                _selectedAmenities.remove(amenity);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Images
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Images',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add Photos'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_selectedImages.isNotEmpty) ...[
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_selectedImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(
                          child: Text('No images selected'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Submit button
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _submitHostel,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Hostel'),
              ),
            ),
          ],
        ),
      ),
    )])))])));
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    
    setState(() {
      _selectedImages.addAll(images.map((image) => File(image.path)));
    });
  }

  Future<void> _submitHostel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Not logged in');

      // Create hostel
      final hostel = Hostel(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: double.parse(_latController.text.trim()),
        longitude: double.parse(_lngController.text.trim()),
        price: int.parse(_priceController.text.trim()),
        amenities: _selectedAmenities,
        contactInfo: _contactController.text.trim(),
        imageUrls: [], // Will be updated after upload
        isAvailable: true,
        createdBy: user.id,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        rating: null,
        reviewCount: 0,
      );

      final hostelService = ref.read(hostelServiceProvider);
      final hostelId = await hostelService.createHostel(hostel);

      // Upload images
      final imageUrls = <String>[];
      for (final image in _selectedImages) {
        final url = await hostelService.uploadImage(image, hostelId);
        imageUrls.add(url);
      }

      // Update hostel with image URLs
      if (imageUrls.isNotEmpty) {
        await hostelService.updateHostel(hostelId, {
          'image_urls': imageUrls,
        });
      }

      if (mounted) {
        // Refresh all hostel-related providers
        ref.invalidate(hostelsProvider);
        ref.invalidate(managerHostelsProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hostel created successfully!')),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _latController.clear();
    _lngController.clear();
    _contactController.clear();
    setState(() {
      _selectedAmenities.clear();
      _selectedImages.clear();
    });
  }


}

// Map screen
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const _makerereUniversity = ll.LatLng(0.3350, 32.5680);
  
  @override
  Widget build(BuildContext context) {
    final hostelsAsync = ref.watch(hostelsProvider);
    final favoriteHostels = ref.watch(favoriteHostelsProvider);
    final favoriteIds = favoriteHostels.map((h) => h.id).toSet();
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostels Map'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              // Center on Makerere University
            },
            tooltip: 'Center on Makerere University',
          ),
        ],
      ),
      body: hostelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading hostels: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(hostelsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (hostels) => FlutterMap(
          options: MapOptions(
            initialCenter: _makerereUniversity,
            initialZoom: 13,
            minZoom: 10,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.mukhostel.mukhostelapp',
            ),
            MarkerLayer(
              markers: [
                // Makerere University marker
                Marker(
                  point: _makerereUniversity,
                  child: const Icon(
                    Icons.school,
                    color: Colors.blue,
                    size: 32,
                  ),
                ),
                // Hostel markers
                ...hostels.map((hostel) {
                  final isFavorite = favoriteIds.contains(hostel.id);
                  final isOwned = currentUser?.id == hostel.createdBy;
                  
                  return Marker(
                    point: ll.LatLng(hostel.latitude, hostel.longitude),
                    child: GestureDetector(
                      onTap: () => _showHostelBottomSheet(context, ref, hostel, isFavorite),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isOwned 
                            ? Colors.green 
                            : (isFavorite ? Colors.red : Colors.orange),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isOwned 
                            ? Icons.business 
                            : (isFavorite ? Icons.favorite : Icons.home),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHostelBottomSheet(BuildContext context, WidgetRef ref, Hostel hostel, bool isFavorite) {
    const campus = ll.LatLng(0.3350, 32.5680);
    final distance = const ll.Distance().as(ll.LengthUnit.Kilometer, campus, ll.LatLng(hostel.latitude, hostel.longitude));
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Image carousel or placeholder
              SizedBox(
                height: 200,
                child: hostel.imageUrls.isNotEmpty
                  ? PageView.builder(
                      itemCount: hostel.imageUrls.length,
                      itemBuilder: (context, index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: hostel.imageUrls[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.error, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.home, size: 64, color: Colors.grey),
                    ),
              ),
              const SizedBox(height: 16),
              
              // Title and favorite button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hostel.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final currentFavoriteHostels = ref.watch(favoriteHostelsProvider);
                      final currentFavoriteIds = currentFavoriteHostels.map((h) => h.id).toSet();
                      final isCurrentlyFavorite = currentFavoriteIds.contains(hostel.id);
                      
                      return IconButton(
                        onPressed: () async {
                          final favoritesService = ref.read(favoritesServiceProvider);
                          final currentUser = ref.read(currentUserProvider);
                          if (currentUser != null) {
                            try {
                              await favoritesService.toggleFavorite(currentUser.id, hostel.id);
                              // Force refresh all related providers
                              ref.invalidate(favoritesProvider);
                              ref.invalidate(favoriteHostelsProvider);
                              ref.invalidate(hostelsProvider);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error updating favorites: $e')),
                                );
                              }
                            }
                          }
                        },
                        icon: Icon(
                          isCurrentlyFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isCurrentlyFavorite ? Colors.red : Colors.grey,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Distance and price
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${distance.toStringAsFixed(1)} km from campus',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'UGX ${NumberFormat('#,###').format(hostel.price)}/month',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Description
              if (hostel.description.isNotEmpty) ...[
                Text(
                  hostel.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              
              // Amenities
              if (hostel.amenities.isNotEmpty) ...[
                Text(
                  'Amenities',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: hostel.amenities.map((amenity) => Chip(
                    label: Text(
                      amenity,
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  )).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openDirections(hostel.latitude, hostel.longitude),
                      icon: const Icon(Icons.directions),
                      label: const Text('Directions'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => HostelDetailScreen(hostelId: hostel.id),
                          ),
                        );
                      },
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDirections(double lat, double lng) async {
    // Prefer geo: URI for native maps; fall back to https Google Maps
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    final httpsUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking');
    
    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // If all fails, try the simple geo URI without query
      try {
        final simpleGeoUri = Uri.parse('geo:$lat,$lng');
        await launchUrl(simpleGeoUri, mode: LaunchMode.externalApplication);
      } catch (e2) {
        // Handle error silently or show user feedback if needed
      }
    }
  }
}

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  ll.LatLng center = const ll.LatLng(0.3350, 32.5680);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop<ll.LatLng>(center);
            },
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
              onPositionChanged: (pos, _) {
                final c = pos.center;
                setState(() {
                  center = c;
                });
                            },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mukhostel.mukhostelapp',
              ),
            ],
          ),
          const IgnorePointer(
            child: Center(
              child: Icon(Icons.location_pin, size: 48, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// Profile screen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final user = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: userProfile.when(
        data: (profile) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: profile?.avatarUrl != null
                      ? CachedNetworkImageProvider(profile!.avatarUrl!)
                      : null,
                  child: profile?.avatarUrl == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  profile?.name ?? 'Unknown User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile?.email ?? '',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Chip(
                  label: Text(profile?.role ?? 'student'),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 32),
                // Add more profile options here
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
