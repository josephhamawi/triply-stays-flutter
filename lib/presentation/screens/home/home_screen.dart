import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/countries_data.dart';
import '../../../domain/repositories/listing_repository.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/listings/listings_provider.dart';
import '../../providers/notifications/notification_provider.dart';
import '../../providers/welcome_toast_provider.dart';
import '../../widgets/common/liquid_orb.dart';
import '../../widgets/guest_prompt_dialog.dart';
import '../../widgets/listing/listing_card.dart';
import '../../widgets/map/listings_map_view.dart';
import '../../widgets/welcome_toast.dart';

/// Home screen with listings grid and search
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showFloatingSearch = false;
  bool _isSearchExpanded = false;
  bool _showFilters = false;
  RangeValues _priceRange = const RangeValues(0, 1000);
  int _minBedrooms = 0;
  int _minBathrooms = 0;
  int _minGuests = 0;

  // View mode: 'grid' or 'map'
  String _viewMode = 'grid';

  // Country and city filters
  String? _selectedCountry;
  String? _selectedCity;
  List<String> _availableCities = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() => setState(() {}));

    // Show welcome toast if requested (after sign-in/sign-up)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeToastIfNeeded();
    });
  }

  void _showWelcomeToastIfNeeded() {
    final shouldShow = ref.read(welcomeToastProvider);
    if (shouldShow) {
      final user = ref.read(authNotifierProvider).user;
      final firstName = user?.firstName ?? user?.displayName?.split(' ').first ?? '';

      // Show the welcome toast
      WelcomeToastService.showWelcome(context, firstName, user?.id);

      // Mark as shown
      ref.read(welcomeToastProvider.notifier).markShown();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_showFloatingSearch) {
      setState(() => _showFloatingSearch = true);
    } else if (_scrollController.offset <= 100 && _showFloatingSearch) {
      setState(() => _showFloatingSearch = false);
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _searchFocusNode.requestFocus();
        });
      } else {
        _searchFocusNode.unfocus();
        _searchController.clear();
        _clearFilters();
      }
    });
  }

  void _applySearch() {
    ref.read(listingFilterProvider.notifier).state = ListingFilter(
      searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
      minPrice: _priceRange.start > 0 ? _priceRange.start : null,
      maxPrice: _priceRange.end < 1000 ? _priceRange.end : null,
      minBedrooms: _minBedrooms > 0 ? _minBedrooms : null,
      minBathrooms: _minBathrooms > 0 ? _minBathrooms : null,
      minGuests: _minGuests > 0 ? _minGuests : null,
      country: _selectedCountry,
      city: _selectedCity,
    );
  }

  Future<void> _loadCitiesForCountry(String countryCode) async {
    final repository = ref.read(listingRepositoryProvider);
    final cities = await repository.getCitiesForCountry(countryCode);
    if (mounted) {
      setState(() {
        _availableCities = cities;
      });
    }
  }

  void _onCountryChanged(String? countryCode) {
    setState(() {
      _selectedCountry = countryCode;
      _selectedCity = null;
      _availableCities = [];
    });
    if (countryCode != null) {
      _loadCitiesForCountry(countryCode);
    }
    _applySearch();
  }

  void _onCityChanged(String? city) {
    setState(() {
      _selectedCity = city;
    });
    _applySearch();
  }

  void _clearFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 1000);
      _minBedrooms = 0;
      _minBathrooms = 0;
      _minGuests = 0;
      _selectedCountry = null;
      _selectedCity = null;
      _availableCities = [];
    });
    ref.read(listingFilterProvider.notifier).state = const ListingFilter();
  }

  String _getInitial(dynamic user) {
    if (user?.displayName?.isNotEmpty == true) {
      return user!.displayName![0].toUpperCase();
    }
    if (user?.email?.isNotEmpty == true) {
      return user!.email[0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final listingsAsync = ref.watch(listingsProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App bar with search
              _buildAppBar(authState),

              // Search bar (hidden when scrolling)
              SliverToBoxAdapter(
                child: AnimatedOpacity(
                  opacity: _showFloatingSearch ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _showFloatingSearch ? 0 : null,
                    child: _showFloatingSearch ? const SizedBox.shrink() : _buildSearchBar(),
                  ),
                ),
              ),

              // Categories
              SliverToBoxAdapter(
                child: categories.when(
                  data: (cats) => _buildCategories(cats, selectedCategory),
                  loading: () => const SizedBox(height: 60),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // View Toggle
              SliverToBoxAdapter(
                child: _buildViewToggle(),
              ),

              // Section title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    _viewMode == 'map' ? 'Properties on Map' : 'Available Properties',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              // Listings (Grid or Map)
              listingsAsync.when(
                data: (listings) {
                  if (listings.isEmpty) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(),
                    );
                  }

                  // Map View
                  if (_viewMode == 'map') {
                    return SliverFillRemaining(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        child: ListingsMapView(listings: listings),
                      ),
                    );
                  }

                  // Grid View
                  return SliverPadding(
                    padding: const EdgeInsets.only(bottom: 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final listing = listings[index];
                          return ListingCard(
                            listing: listing,
                            onTap: () {
                              final isGuest = ref.read(isGuestProvider);
                              if (isGuest) {
                                GuestPromptDialog.show(
                                  context,
                                  message: 'Sign up to view listing details and connect with property owners.',
                                );
                              } else {
                                context.push('/listing/${listing.id}');
                              }
                            },
                          );
                        },
                        childCount: listings.length,
                      ),
                    ),
                  );
                },
                loading: () => SliverFillRemaining(
                  child: _buildLoadingState(),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: _buildErrorState(error.toString()),
                ),
              ),
            ],
          ),

          // Floating search removed - search bar now just disappears when scrolling
        ],
      ),
    );
  }

  Widget _buildAppBar(authState) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      toolbarHeight: 70,
      backgroundColor: AppColors.primaryOrange,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Logo - smaller and aligned left
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              'assets/images/logo/triply-stays-logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
          // Notification button with badge
          _NotificationButton(
            unreadCount: unreadCount.valueOrNull ?? 0,
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
          // Profile button with photo
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: authState.user?.photoUrl != null &&
                        authState.user!.photoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: authState.user!.photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.white,
                          child: Center(
                            child: Text(
                              _getInitial(authState.user),
                              style: const TextStyle(
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.white,
                          child: Center(
                            child: Text(
                              _getInitial(authState.user),
                              style: const TextStyle(
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.white,
                        child: Center(
                          child: Text(
                            _getInitial(authState.user),
                            style: const TextStyle(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          // Modern pill-shaped search bar with liquid orb
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
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
                // Liquid animated orb
                GestureDetector(
                  onTap: _toggleSearch,
                  child: Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(8),
                    child: LiquidOrb(
                      size: 40,
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Search input or hint text
                Expanded(
                  child: _isSearchExpanded
                      ? TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                          cursorColor: AppColors.primaryOrange,
                          decoration: InputDecoration(
                            hintText: 'Search properties...',
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
                          onSubmitted: (_) => _applySearch(),
                          onChanged: (_) => _applySearch(),
                        )
                      : GestureDetector(
                          onTap: _toggleSearch,
                          child: Container(
                            color: Colors.transparent,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'Search destinations, properties...',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                ),
                // Clear button (when searching)
                if (_isSearchExpanded && _searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _applySearch();
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
            const SizedBox(height: 12),
            _buildFiltersPanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _viewMode = 'grid'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _viewMode == 'grid' ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _viewMode == 'grid'
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.grid_view_rounded,
                        size: 18,
                        color: _viewMode == 'grid'
                            ? AppColors.primaryOrange
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Grid View',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _viewMode == 'grid' ? FontWeight.w600 : FontWeight.w500,
                          color: _viewMode == 'grid'
                              ? AppColors.primaryOrange
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _viewMode = 'map'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _viewMode == 'map' ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _viewMode == 'map'
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 18,
                        color: _viewMode == 'map'
                            ? AppColors.primaryOrange
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Map View',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _viewMode == 'map' ? FontWeight.w600 : FontWeight.w500,
                          color: _viewMode == 'map'
                              ? AppColors.primaryOrange
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersPanel() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Country and City filters
          Row(
            children: [
              // Country dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Country',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedCountry,
                          hint: const Text('All', style: TextStyle(fontSize: 13)),
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                          dropdownColor: Colors.white,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Countries', style: TextStyle(color: AppColors.textPrimary)),
                            ),
                            ...countries.map((country) => DropdownMenuItem<String>(
                              value: country.code,
                              child: Text('${country.flag} ${country.name}', style: const TextStyle(color: AppColors.textPrimary)),
                            )),
                          ],
                          onChanged: _onCountryChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // City dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'City',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedCity,
                          hint: const Text('All', style: TextStyle(fontSize: 13)),
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                          dropdownColor: Colors.white,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Cities', style: TextStyle(color: AppColors.textPrimary)),
                            ),
                            ..._availableCities.map((city) => DropdownMenuItem<String>(
                              value: city,
                              child: Text(city, style: const TextStyle(color: AppColors.textPrimary)),
                            )),
                          ],
                          onChanged: _onCityChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
            onChanged: (values) {
              setState(() => _priceRange = values);
              _applySearch();
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${_priceRange.start.round()}/night',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                '\$${_priceRange.end.round()}/night',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Room filters
          Row(
            children: [
              Expanded(
                child: _buildCounterFilter(
                  label: 'Bedrooms',
                  value: _minBedrooms,
                  onChanged: (v) {
                    setState(() => _minBedrooms = v);
                    _applySearch();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCounterFilter(
                  label: 'Bathrooms',
                  value: _minBathrooms,
                  onChanged: (v) {
                    setState(() => _minBathrooms = v);
                    _applySearch();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCounterFilter(
                  label: 'Guests',
                  value: _minGuests,
                  onChanged: (v) {
                    setState(() => _minGuests = v);
                    _applySearch();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Clear button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _clearFilters,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryOrange,
                side: const BorderSide(color: AppColors.primaryOrange),
              ),
              child: const Text('Clear Filters'),
            ),
          ),
        ],
      ),
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
            fontSize: 11,
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
              GestureDetector(
                onTap: value > 0 ? () => onChanged(value - 1) : null,
                child: Container(
                  width: 28,
                  height: 32,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: value > 0 ? AppColors.textPrimary : AppColors.textLight,
                  ),
                ),
              ),
              Text(
                value == 0 ? 'Any' : '$value+',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(value + 1),
                child: Container(
                  width: 28,
                  height: 32,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategories(List<String> categories, String? selected) {
    // Category icons
    final categoryIcons = {
      'Apartment': Icons.apartment,
      'Villa': Icons.villa,
      'House': Icons.home,
      'Chalet': Icons.cabin,
      'Cabin': Icons.cabin,
      'Studio': Icons.weekend,
      'Condo': Icons.domain,
      'Treehouse': Icons.park,
      'Caravan': Icons.rv_hookup,
      'Tent': Icons.holiday_village,
      'Van': Icons.airport_shuttle,
      'Loft': Icons.roofing,
    };

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.length + 1, // +1 for "All" option
        itemBuilder: (context, index) {
          if (index == 0) {
            // All category
            final isSelected = selected == null;
            return _CategoryChip(
              icon: Icons.grid_view,
              label: 'All',
              isSelected: isSelected,
              onTap: () {
                ref.read(selectedCategoryProvider.notifier).state = null;
                ref.read(listingFilterProvider.notifier).state =
                    ref.read(listingFilterProvider).copyWith(category: null);
              },
            );
          }

          final category = categories[index - 1];
          final isSelected = selected?.toLowerCase() == category.toLowerCase();

          return _CategoryChip(
            icon: categoryIcons[category] ?? Icons.home,
            label: category,
            isSelected: isSelected,
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = category;
              ref.read(listingFilterProvider.notifier).state =
                  ref.read(listingFilterProvider).copyWith(category: category);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primaryOrange,
          ),
          SizedBox(height: 16),
          Text(
            'Loading properties...',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load properties',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(listingsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 80,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No properties found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Category chip with icon
class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryOrange : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryOrange
                  : AppColors.borderLight,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? Colors.white : AppColors.primaryOrange,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Notification button with unread badge
class _NotificationButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationButton({
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
