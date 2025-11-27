import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/listing.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/listings/listings_provider.dart';
import '../../providers/messaging/messaging_provider.dart';

/// A beautiful listing card with glassmorphism effects
class ListingCard extends ConsumerStatefulWidget {
  final Listing listing;
  final VoidCallback? onTap;
  final bool showLikeButton;

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.showLikeButton = true,
  });

  @override
  ConsumerState<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends ConsumerState<ListingCard> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = ref.watch(isListingLikedProvider(widget.listing.id));
    final images = widget.listing.images;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section with page indicator
                Stack(
                  children: [
                    // Image carousel
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: images.isEmpty
                          ? Container(
                              color: AppColors.backgroundLight,
                              child: const Icon(
                                Icons.home_outlined,
                                size: 64,
                                color: AppColors.textLight,
                              ),
                            )
                          : PageView.builder(
                              controller: _pageController,
                              itemCount: images.length,
                              onPageChanged: (index) {
                                setState(() => _currentImageIndex = index);
                              },
                              itemBuilder: (context, index) {
                                return CachedNetworkImage(
                                  imageUrl: images[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: AppColors.backgroundLight,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryOrange,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: AppColors.backgroundLight,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      size: 48,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Like button with glass effect and likes count
                    if (widget.showLikeButton)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _GlassLikeButton(
                          isLiked: isLiked,
                          likesCount: widget.listing.likesCount,
                          onTap: () {
                            ref.read(toggleLikeProvider(widget.listing.id))();
                          },
                        ),
                      ),

                    // Category badge
                    if (widget.listing.category != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _GlassBadge(text: widget.listing.category!),
                      ),

                    // Page indicators
                    if (images.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length,
                            (index) => Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
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

                    // Price badge
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: _GlassPriceBadge(price: widget.listing.price),
                    ),
                  ],
                ),

                // Content section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.listing.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.listing.city,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Stats row
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.bed_outlined,
                            value: '${widget.listing.bedrooms}',
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            icon: Icons.bathtub_outlined,
                            value: '${widget.listing.bathrooms}',
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            icon: Icons.people_outline,
                            value: '${widget.listing.maxGuests}',
                          ),
                          const Spacer(),
                          // Rating
                          if (widget.listing.averageRating != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.listing.averageRating!
                                      .toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      // Contact buttons row
                      if (widget.listing.hostPhone != null &&
                          widget.listing.hostPhone!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Phone call button
                            Expanded(
                              child: _ContactButton(
                                icon: Icons.phone_outlined,
                                label: 'Call',
                                color: AppColors.primaryOrange,
                                onTap: () => _launchPhone(widget.listing.hostPhone!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // WhatsApp button
                            Expanded(
                              child: _ContactButton(
                                icon: Icons.chat,
                                label: 'WhatsApp',
                                color: const Color(0xFF25D366),
                                onTap: () => _launchWhatsApp(widget.listing.hostPhone!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // In-app Message button
                            Expanded(
                              child: _ContactButton(
                                icon: Icons.chat_bubble_outline,
                                label: 'Message',
                                color: const Color(0xFF007AFF),
                                onTap: () => _startConversation(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    // Remove any non-digit characters for WhatsApp
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _startConversation() async {
    final listing = widget.listing;

    // Check if user is authenticated
    final authState = ref.read(authNotifierProvider);
    if (authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to message the host')),
      );
      return;
    }

    // Don't message yourself
    if (listing.hostId == authState.user!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is your own listing')),
      );
      return;
    }

    // Start conversation
    final conversation = await ref.read(messagingNotifierProvider.notifier).startConversation(
      otherUserId: listing.hostId,
      otherUserName: listing.hostName ?? 'Host',
      otherUserPhotoUrl: listing.hostPhotoURL,
      listingId: listing.id,
      listingTitle: listing.title,
      listingImageUrl: listing.images.isNotEmpty ? listing.images.first : null,
    );

    if (conversation != null && mounted) {
      context.push('/chat/${conversation.id}');
    }
  }
}

/// Glass effect like button with likes count
class _GlassLikeButton extends StatelessWidget {
  final bool isLiked;
  final int likesCount;
  final VoidCallback onTap;

  const _GlassLikeButton({
    required this.isLiked,
    required this.likesCount,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.white,
                  size: 20,
                ),
                if (likesCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    likesCount > 999 ? '${(likesCount / 1000).toStringAsFixed(1)}k' : '$likesCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass category badge
class _GlassBadge extends StatelessWidget {
  final String text;

  const _GlassBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass price badge
class _GlassPriceBadge extends StatelessWidget {
  final double price;

  const _GlassPriceBadge({required this.price});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '\$${price.toStringAsFixed(0)}/night',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Stat chip for bedrooms/bathrooms/guests
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;

  const _StatChip({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Contact button for call/WhatsApp
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
