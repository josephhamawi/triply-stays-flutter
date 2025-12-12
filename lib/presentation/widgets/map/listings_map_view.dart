import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/city_coordinates.dart';
import '../../../domain/entities/listing.dart';
import '../../providers/auth/auth_provider.dart';
import '../guest_prompt_dialog.dart';

/// Map view displaying listings with markers using OpenStreetMap
/// Matches web app behavior: uses city coordinates directly
class ListingsMapView extends ConsumerStatefulWidget {
  final List<Listing> listings;

  const ListingsMapView({
    super.key,
    required this.listings,
  });

  @override
  ConsumerState<ListingsMapView> createState() => _ListingsMapViewState();
}

class _ListingsMapViewState extends ConsumerState<ListingsMapView> {
  final MapController _mapController = MapController();
  Listing? _selectedListing;
  // Track offsets for listings to prevent marker overlap
  Map<String, LatLng> _listingCoordinatesCache = {};

  @override
  void didUpdateWidget(ListingsMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listings != widget.listings) {
      _computeListingCoordinates();
      _fitBounds();
    }
  }

  @override
  void initState() {
    super.initState();
    _computeListingCoordinates();
  }

  /// Compute coordinates for all listings, adding offsets for same-city listings
  void _computeListingCoordinates() {
    _listingCoordinatesCache = {};
    final cityCount = <String, int>{};

    for (final listing in widget.listings) {
      final city = listing.city.toLowerCase().trim();
      final count = cityCount[city] ?? 0;
      cityCount[city] = count + 1;

      final baseCoords = getCityCoordinates(listing.city);

      // Add a small offset for each additional listing in the same city
      // Using a spiral pattern to spread markers
      if (count > 0) {
        final angle = count * 0.8; // radians
        final radius = 0.003 + (count * 0.001); // ~300m + 100m per listing
        final offsetLat = radius * math.cos(angle);
        final offsetLng = radius * math.sin(angle);
        _listingCoordinatesCache[listing.id] = LatLng(
          baseCoords.latitude + offsetLat,
          baseCoords.longitude + offsetLng,
        );
      } else {
        _listingCoordinatesCache[listing.id] = baseCoords;
      }

      if (kDebugMode) {
        final coords = _listingCoordinatesCache[listing.id]!;
        debugPrint('Map: Listing "${listing.title}" city="${listing.city}" count=$count -> coords=(${coords.latitude}, ${coords.longitude})');
      }
    }
  }

  void _fitBounds() {
    if (widget.listings.isEmpty) return;

    final coordinates = widget.listings
        .map((l) => _getListingCoordinates(l))
        .toList();

    final bounds = calculateBounds(coordinates);
    if (bounds != null) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  /// Get coordinates for a listing from cache
  /// Uses pre-computed coordinates with offsets for same-city listings
  LatLng _getListingCoordinates(Listing listing) {
    return _listingCoordinatesCache[listing.id] ?? getCityCoordinates(listing.city);
  }

  List<Marker> _buildMarkers() {
    return widget.listings.map((listing) {
      final position = _getListingCoordinates(listing);
      final priceColor = Color(getPriceColor(listing.price));

      return Marker(
        point: position,
        width: 40,
        height: 50,
        child: GestureDetector(
          onTap: () => setState(() => _selectedListing = listing),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priceColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '\$${listing.price.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              CustomPaint(
                size: const Size(10, 6),
                painter: _TrianglePainter(color: priceColor),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: lebanonCenter,
              initialZoom: defaultZoom,
              onTap: (_, __) => setState(() => _selectedListing = null),
            ),
            children: [
              // OpenStreetMap tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.triplystays.app',
              ),
              // Markers
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
        ),

        // Map controls
        Positioned(
          right: 16,
          bottom: _selectedListing != null ? 190 : 16,
          child: Column(
            children: [
              _MapControlButton(
                icon: Icons.add,
                onTap: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(
                    _mapController.camera.center,
                    currentZoom + 1,
                  );
                },
              ),
              const SizedBox(height: 8),
              _MapControlButton(
                icon: Icons.remove,
                onTap: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(
                    _mapController.camera.center,
                    currentZoom - 1,
                  );
                },
              ),
              const SizedBox(height: 8),
              _MapControlButton(
                icon: Icons.my_location,
                onTap: _fitBounds,
              ),
            ],
          ),
        ),

        // Legend
        Positioned(
          left: 16,
          top: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Price Range',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                _LegendItem(color: Color(0xFFFB8500), label: '<\$100'),
                SizedBox(height: 4),
                _LegendItem(color: Color(0xFFeab308), label: '\$100-\$300'),
                SizedBox(height: 4),
                _LegendItem(color: Color(0xFFef4444), label: '>\$300'),
              ],
            ),
          ),
        ),

        // Results count
        Positioned(
          left: 16,
          bottom: _selectedListing != null ? 190 : 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${widget.listings.length} ${widget.listings.length == 1 ? 'listing' : 'listings'}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),

        // Selected listing card
        if (_selectedListing != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _ListingPreviewCard(
              listing: _selectedListing!,
              onTap: () {
                final isGuest = ref.read(isGuestProvider);
                if (isGuest) {
                  GuestPromptDialog.show(
                    context,
                    message: 'Sign up to view listing details and connect with property owners.',
                  );
                } else {
                  context.push('/listing/${_selectedListing!.id}');
                }
              },
              onClose: () => setState(() => _selectedListing = null),
            ),
          ),
      ],
    );
  }
}

/// Triangle painter for marker pointer
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapControlButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ListingPreviewCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _ListingPreviewCard({
    required this.listing,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 140,
                height: 160,
                child: listing.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: listing.images.first,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.backgroundLight,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.backgroundLight,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      )
                    : Container(
                        color: AppColors.backgroundLight,
                        child: const Icon(Icons.image, size: 48),
                      ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${listing.city}${listing.country.isNotEmpty ? ', ${listing.country}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Details
                    Row(
                      children: [
                        _PropertyDetail(icon: Icons.bed_outlined, value: '${listing.bedrooms}'),
                        const SizedBox(width: 12),
                        _PropertyDetail(icon: Icons.bathtub_outlined, value: '${listing.bathrooms}'),
                        const SizedBox(width: 12),
                        _PropertyDetail(icon: Icons.people_outline, value: '${listing.maxGuests}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Price
                    Text(
                      '\$${listing.price.toInt()}/night',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyDetail extends StatelessWidget {
  final IconData icon;
  final String value;

  const _PropertyDetail({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
