import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/listing.dart';
import '../../providers/listings/listings_provider.dart';

/// Listing detail screen with full property information
class ListingDetailScreen extends ConsumerStatefulWidget {
  final String listingId;

  const ListingDetailScreen({
    super.key,
    required this.listingId,
  });

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));
    final isLiked = ref.watch(isListingLikedProvider(widget.listingId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: listingAsync.when(
        data: (listing) {
          if (listing == null) {
            return _buildNotFound();
          }
          return _buildContent(listing, isLiked);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.home_outlined,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'Property not found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Listing listing, bool isLiked) {
    return Stack(
      children: [
        // Scrollable content
        CustomScrollView(
          slivers: [
            // Image gallery
            SliverToBoxAdapter(
              child: _buildImageGallery(listing),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Title and location
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        listing.city,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (listing.averageRating != null) ...[
                        const Spacer(),
                        const Icon(
                          Icons.star,
                          size: 18,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${listing.averageRating!.toStringAsFixed(1)} (${listing.reviewCount} reviews)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick stats
                  _buildQuickStats(listing),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'About this place',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Amenities
                  if (listing.amenities.isNotEmpty) ...[
                    const Text(
                      'Amenities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAmenities(listing.amenities),
                    const SizedBox(height: 24),
                  ],

                  // Host info
                  _buildHostInfo(listing),
                  const SizedBox(height: 24),

                  // Location map placeholder
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLocationCard(listing),

                  // Bottom padding for booking bar
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),

        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: _GlassButton(
            icon: Icons.arrow_back,
            onTap: () => context.pop(),
          ),
        ),

        // Like button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: _GlassButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            iconColor: isLiked ? Colors.red : Colors.white,
            onTap: () {
              ref.read(toggleLikeProvider(widget.listingId))();
            },
          ),
        ),

        // Share button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 64,
          child: _GlassButton(
            icon: Icons.share_outlined,
            onTap: () {
              // TODO: Implement share
            },
          ),
        ),

        // Contact host bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildContactBar(listing),
        ),
      ],
    );
  }

  Widget _buildImageGallery(Listing listing) {
    final images = listing.images;

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          images.isEmpty
              ? Container(
                  color: AppColors.backgroundLight,
                  child: const Center(
                    child: Icon(
                      Icons.home_outlined,
                      size: 64,
                      color: AppColors.textLight,
                    ),
                  ),
                )
              : PageView.builder(
                  controller: _imageController,
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // TODO: Open full screen gallery
                      },
                      child: CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.backgroundLight,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.backgroundLight,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    );
                  },
                ),

          // Page indicator
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentImageIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),

          // Image counter
          if (images.isNotEmpty)
            Positioned(
              bottom: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Listing listing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.bed_outlined,
            value: '${listing.bedrooms}',
            label: 'Bedrooms',
          ),
          _divider(),
          _StatItem(
            icon: Icons.bathtub_outlined,
            value: '${listing.bathrooms}',
            label: 'Bathrooms',
          ),
          _divider(),
          _StatItem(
            icon: Icons.people_outline,
            value: '${listing.maxGuests}',
            label: 'Guests',
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.borderLight,
    );
  }

  Widget _buildAmenities(List<String> amenities) {
    final amenityIcons = {
      'WiFi': Icons.wifi,
      'Wi-Fi': Icons.wifi,
      'Kitchen': Icons.kitchen,
      'Pool': Icons.pool,
      'Parking': Icons.local_parking,
      'AC': Icons.ac_unit,
      'Air Conditioning': Icons.ac_unit,
      'TV': Icons.tv,
      'Washer': Icons.local_laundry_service,
      'Gym': Icons.fitness_center,
      'Garden': Icons.yard,
      'BBQ': Icons.outdoor_grill,
      'Fireplace': Icons.fireplace,
      'Jacuzzi': Icons.hot_tub,
      'Hot Tub': Icons.hot_tub,
      'Balcony': Icons.balcony,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenities.map((amenity) {
        final icon = amenityIcons[amenity] ?? Icons.check_circle_outline;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                amenity,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHostInfo(Listing listing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryOrange,
            backgroundImage: listing.hostPhotoURL != null
                ? CachedNetworkImageProvider(listing.hostPhotoURL!)
                : null,
            child: listing.hostPhotoURL == null
                ? Text(
                    listing.hostName?.isNotEmpty == true
                        ? listing.hostName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hosted by ${listing.hostName ?? 'Host'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(
                      Icons.verified,
                      size: 14,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Verified Host',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              // TODO: Start chat with host
            },
            child: const Text('Message'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Listing listing) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: AppColors.textLight.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              listing.city,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap to view on map',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactBar(Listing listing) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            border: const Border(
              top: BorderSide(color: AppColors.borderLight),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Price row
              Row(
                children: [
                  Text(
                    '\$${listing.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    ' / night',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Contact ${listing.hostName ?? 'Host'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Contact buttons row
              Row(
                children: [
                  // WhatsApp button (only if host has WhatsApp)
                  if (listing.hostHasWhatsApp &&
                      listing.hostPhone != null &&
                      listing.hostPhone!.isNotEmpty) ...[
                    Expanded(
                      child: _ContactButton(
                        icon: Icons.chat,
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () => _openWhatsApp(listing),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Call button (only if host has phone)
                  if (listing.hostPhone != null &&
                      listing.hostPhone!.isNotEmpty) ...[
                    Expanded(
                      child: _ContactButton(
                        icon: Icons.phone,
                        label: 'Call',
                        color: AppColors.primaryOrange,
                        onTap: () => _makePhoneCall(listing),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Message button (always available)
                  Expanded(
                    child: _ContactButton(
                      icon: Icons.message,
                      label: 'Message',
                      color: AppColors.primaryDark,
                      onTap: () => _startChat(listing),
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

  Future<void> _openWhatsApp(Listing listing) async {
    final phone = listing.hostPhone;
    if (phone == null || phone.isEmpty) {
      _showNoPhoneDialog();
      return;
    }

    // Format phone number and open WhatsApp
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final message = Uri.encodeComponent(
      'Hi! I\'m interested in your property "${listing.title}" on Triply Stays.',
    );
    final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone?text=$message');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(Listing listing) async {
    final phone = listing.hostPhone;
    if (phone == null || phone.isEmpty) {
      _showNoPhoneDialog();
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final phoneUrl = Uri.parse('tel:$cleanPhone');

    if (await canLaunchUrl(phoneUrl)) {
      await launchUrl(phoneUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make phone call')),
        );
      }
    }
  }

  void _startChat(Listing listing) {
    // Navigate to messages screen or start a new chat
    context.push('/messages'); // For now, go to messages
    // TODO: Implement direct chat with host
  }

  void _showNoPhoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Unavailable'),
        content: const Text(
          'This host hasn\'t provided a phone number. Try sending them a message instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    this.iconColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Contact button with icon and label
class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
