# Story-002: Add Listing Feature

**Status:** Approved
**Priority:** P0
**Epic:** Host Features
**Estimate:** Large
**Created:** 2024-11-27

---

## Story

**As a** host user
**I want to** create a new property listing from the mobile app
**So that** I can list my vacation rental property and reach potential guests

---

## Background

This is a **brownfield** feature - the Flutter app connects to the existing Firebase backend used by the React web app. The listing creation must:
- Use the same Firestore `listings` collection schema
- Match the web app's `EditListingModal.js` functionality
- Support all required fields from the existing data model

### Reference Implementation
- **Web App Form**: `/MVP-vacation-rental/src/components/EditListingModal.js`
- **PRD Section**: 4.3 Host Features - Create Listing (P0)
- **Firestore Collection**: `listings/{listingId}`

---

## Acceptance Criteria

- [ ] User can navigate to "Add Listing" from My Listings screen or profile
- [ ] Multi-step form collects all required listing information
- [ ] User can upload up to 10 images for the listing
- [ ] Images are stored in Firebase Storage under `listings/{listingId}/`
- [ ] Form validates required fields before submission
- [ ] Listing is saved to Firestore with `status: 'pending'` for review
- [ ] User sees success confirmation after submission
- [ ] New listing appears in "My Listings" screen
- [ ] Form loads categories, views, and amenities from Firestore settings

---

## Tasks

### Task 1: Update Listing Entity & Model
- [ ] Add missing fields to `lib/domain/entities/listing.dart`:
  - `view` (String?) - mountain, sea, city, etc.
  - `rules` (String?) - house rules
  - `livingRooms` (int) - number of living rooms
  - `beds` (int) - total beds count
  - `location` (String?) - Google Maps link
- [ ] Update `lib/data/models/listing_model.dart` with Firestore serialization
- [ ] Update `copyWith()` method with new fields

### Task 2: Create Settings Repository
- [ ] Create `lib/domain/repositories/settings_repository.dart` interface
- [ ] Create `lib/data/repositories/firebase_settings_repository.dart`
- [ ] Implement `getAppSettings()` to fetch from `settings/appSettings`:
  - `categories` (List<String>)
  - `views` (List<String>)
  - `amenities` (List<String>)
- [ ] Create settings provider in `lib/presentation/providers/settings/`

### Task 3: Implement Listing Repository Create Method
- [ ] Add `createListing(Listing listing)` to `ListingRepository` interface
- [ ] Implement in `FirebaseListingRepository`:
  - Generate new document ID
  - Set `hostId` from current user
  - Set `hostName`, `hostPhone`, `hostHasWhatsApp` from user profile
  - Set `status: 'pending'`
  - Set `createdAt` timestamp
  - Initialize `likesCount`, `views` to 0
- [ ] Add `updateListing(Listing listing)` method for future edit support

### Task 4: Create Image Upload Service
- [ ] Create `lib/data/services/image_upload_service.dart`
- [ ] Implement `uploadListingImages(String listingId, List<File> images)`:
  - Upload to `listings/{listingId}/{filename}`
  - Return list of download URLs
  - Support progress callback
- [ ] Add image compression before upload (max 1920px width)
- [ ] Handle upload errors gracefully

### Task 5: Create Add Listing Screen UI
- [ ] Create `lib/presentation/screens/listing/add_listing_screen.dart`
- [ ] Implement multi-step form with PageView:
  - **Step 1: Basic Info** - Title, description, category, view
  - **Step 2: Location** - Country, city, Google Maps link
  - **Step 3: Details** - Price, bedrooms, bathrooms, livingRooms, beds, maxGuests
  - **Step 4: Amenities** - Multi-select from settings + custom
  - **Step 5: Images** - Upload up to 10 photos
  - **Step 6: Rules** - House rules (optional)
  - **Step 7: Review** - Preview and submit
- [ ] Add progress indicator showing current step
- [ ] Implement "Save Draft" functionality
- [ ] Add form validation with error messages

### Task 6: Create Form State Management
- [ ] Create `lib/presentation/providers/listing/add_listing_provider.dart`
- [ ] Implement `AddListingNotifier` with StateNotifier:
  - Form data state
  - Current step tracking
  - Validation state
  - Loading/error states
- [ ] Handle image selection and preview
- [ ] Implement draft save/restore

### Task 7: Integrate Navigation
- [ ] Add FAB or button to My Listings screen for "Add Listing"
- [ ] Add navigation to Add Listing screen
- [ ] Handle successful creation - navigate back with refresh
- [ ] Handle cancellation with confirmation dialog

### Task 8: Countries & Cities Data
- [ ] Create `lib/data/services/country_city_service.dart`
- [ ] Implement country list with codes and flags
- [ ] Implement city loading per country (can use static data or API)
- [ ] Match web app's country/city selection behavior

---

## Dev Notes

### Firestore Listing Document Schema (from web app)
```javascript
{
  title: String,           // Required
  description: String,     // Required
  country: String,         // Country code, default "LB"
  city: String,           // Required
  location: String,       // Google Maps link (optional)
  price: Number,          // Required - per night USD
  category: String,       // Required - from settings
  view: String,           // Required - from settings
  amenities: Array,       // String array
  images: Array,          // URL strings
  rules: String,          // House rules (optional)
  bedrooms: Number,       // Required
  bathrooms: Number,      // Required
  livingRooms: Number,    // Optional, default 0
  beds: Number,           // Required
  maxGuests: Number,      // Required
  hostId: String,         // Firebase Auth UID
  hostName: String,       // From user profile
  hostPhone: String,      // From user profile
  hostHasWhatsApp: Boolean,
  status: String,         // "pending", "active", "inactive", "draft"
  createdAt: Timestamp,
  likesCount: Number,     // Default 0
  views: Number           // Default 0
}
```

### Image Upload Path
```
Firebase Storage: listings/{listingId}/{imageName}
```

### Settings Document (`settings/appSettings`)
```javascript
{
  categories: ["House", "Apartment", "Villa", "Cabin", "Chalet", ...],
  views: ["Mountain", "Sea", "City", "Garden", "Pool", ...],
  amenities: ["WiFi", "Pool", "Kitchen", "AC", "Parking", ...]
}
```

---

## Testing

### Unit Tests
- [ ] Listing entity field additions
- [ ] ListingModel serialization/deserialization
- [ ] Form validation logic
- [ ] Settings repository

### Widget Tests
- [ ] Add Listing screen renders correctly
- [ ] Form navigation between steps
- [ ] Validation error display
- [ ] Image picker integration

### Integration Tests
- [ ] Full listing creation flow
- [ ] Image upload to Firebase Storage
- [ ] Listing appears in My Listings after creation

---

## Dev Agent Record

### Agent Model Used
-

### Debug Log References
-

### Completion Notes
-

### File List
-

### Change Log
-

---

## Out of Scope
- Edit existing listings (separate story)
- Listing moderation/approval workflow
- Pricing calendar/availability
- Instant booking settings
