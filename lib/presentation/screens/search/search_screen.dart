import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/repositories/listing_repository.dart';
import '../../providers/listings/listings_provider.dart';
import '../../widgets/listing/listing_card.dart';

/// Search screen with filters
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _showFilters = false;
  RangeValues _priceRange = const RangeValues(0, 1000);
  int _minBedrooms = 0;
  int _minBathrooms = 0;
  int _minGuests = 0;

  @override
  void initState() {
    super.initState();
    // Listen for text changes to update clear button visibility
    _searchController.addListener(() {
      setState(() {});
    });
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final currentFilter = ref.read(listingFilterProvider);
    ref.read(listingFilterProvider.notifier).state = currentFilter.copyWith(
      searchQuery: _searchController.text,
      minPrice: _priceRange.start > 0 ? _priceRange.start : null,
      maxPrice: _priceRange.end < 1000 ? _priceRange.end : null,
      minBedrooms: _minBedrooms > 0 ? _minBedrooms : null,
      minBathrooms: _minBathrooms > 0 ? _minBathrooms : null,
      minGuests: _minGuests > 0 ? _minGuests : null,
    );
    setState(() => _showFilters = false);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _priceRange = const RangeValues(0, 1000);
      _minBedrooms = 0;
      _minBathrooms = 0;
      _minGuests = 0;
    });
    ref.read(listingFilterProvider.notifier).state = const ListingFilter(country: 'LB');
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Modern pill-shaped search bar
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Gradient orb
                        Container(
                          width: 56,
                          height: 56,
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: const Alignment(-0.3, -0.3),
                                colors: [
                                  const Color(0xFF4ECDC4), // Teal/cyan
                                  const Color(0xFF2D8B7A), // Darker teal
                                  const Color(0xFF1A5F52), // Deep teal
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4ECDC4).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        // Search input
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                            cursorColor: AppColors.primaryOrange,
                            decoration: InputDecoration(
                              hintText: 'Just ask...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 16,
                              ),
                            ),
                            onSubmitted: (_) => _applyFilters(),
                          ),
                        ),
                        // Clear button (shows when text is entered)
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey.shade500,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                              setState(() {});
                            },
                          ),
                        // Filter button
                        GestureDetector(
                          onTap: () => setState(() => _showFilters = !_showFilters),
                          child: Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _showFilters
                                  ? AppColors.primaryOrange
                                  : Colors.transparent,
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: _showFilters
                                  ? Colors.white
                                  : Colors.grey.shade500,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filters panel
                  if (_showFilters) ...[
                    const SizedBox(height: 16),
                    _buildFiltersPanel(),
                  ],
                ],
              ),
            ),

            // Results
            Expanded(
              child: listingsAsync.when(
                data: (listings) {
                  if (listings.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 120),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      return ListingCard(
                        listing: listing,
                        onTap: () => context.push('/listing/${listing.id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryOrange,
                  ),
                ),
                error: (error, _) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price range
        const Text(
          'Price Range',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 1000,
          divisions: 20,
          activeColor: AppColors.primaryOrange,
          labels: RangeLabels(
            '\$${_priceRange.start.round()}',
            '\$${_priceRange.end.round()}',
          ),
          onChanged: (values) => setState(() => _priceRange = values),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${_priceRange.start.round()}/night',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              '\$${_priceRange.end.round()}/night',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Room filters
        Row(
          children: [
            Expanded(
              child: _buildCounterFilter(
                label: 'Bedrooms',
                value: _minBedrooms,
                onChanged: (v) => setState(() => _minBedrooms = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCounterFilter(
                label: 'Bathrooms',
                value: _minBathrooms,
                onChanged: (v) => setState(() => _minBathrooms = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCounterFilter(
                label: 'Guests',
                value: _minGuests,
                onChanged: (v) => setState(() => _minGuests = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _clearFilters,
                child: const Text('Clear'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _applyFilters,
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterFilter({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.remove,
                  size: 18,
                  color: value > 0 ? AppColors.textPrimary : AppColors.textLight,
                ),
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              Text(
                value == 0 ? 'Any' : '$value+',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => onChanged(value + 1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _clearFilters,
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}
