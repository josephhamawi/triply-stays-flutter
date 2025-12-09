/// Chatbot Content Data
///
/// Predefined Q&A content for the Smart FAQ Chatbot

/// Topic model
class ChatbotTopic {
  final String id;
  final String title;
  final String icon;
  final String description;
  final int order;

  const ChatbotTopic({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.order,
  });
}

/// Question model
class ChatbotQuestion {
  final String id;
  final String topicId;
  final String question;
  final String answer;
  final List<String> keywords;
  final List<String> relatedQuestions;
  final List<String> contextPages;
  final String? actionLabel;
  final String? actionRoute;
  final int order;

  const ChatbotQuestion({
    required this.id,
    required this.topicId,
    required this.question,
    required this.answer,
    this.keywords = const [],
    this.relatedQuestions = const [],
    this.contextPages = const [],
    this.actionLabel,
    this.actionRoute,
    this.order = 0,
  });
}

/// Predefined topics
const List<ChatbotTopic> chatbotTopics = [
  ChatbotTopic(
    id: 'getting-started',
    title: 'Getting Started',
    icon: '🚀',
    description: 'Learn the basics of using Triply Stays',
    order: 1,
  ),
  ChatbotTopic(
    id: 'listings',
    title: 'Listings & Search',
    icon: '🏡',
    description: 'Find and explore vacation rentals',
    order: 2,
  ),
  ChatbotTopic(
    id: 'account',
    title: 'Account & Profile',
    icon: '👤',
    description: 'Manage your account settings',
    order: 3,
  ),
  ChatbotTopic(
    id: 'features',
    title: 'Features & Tools',
    icon: '⭐',
    description: 'Discover app features',
    order: 4,
  ),
];

/// Predefined questions and answers
const List<ChatbotQuestion> chatbotQuestions = [
  // Getting Started
  ChatbotQuestion(
    id: 'how-to-register',
    topicId: 'getting-started',
    question: 'How do I create an account?',
    answer: '''Creating an account is easy! Here's how:

1. Tap the "Sign In" button on the home screen
2. Choose "Create Account" or sign up with Google/Apple
3. Enter your email and create a password
4. Verify your email address
5. Complete your profile

You can also sign in with your Google or Apple account for faster registration.''',
    keywords: ['register', 'sign up', 'account', 'create', 'new user'],
    relatedQuestions: ['how-to-login', 'verify-email'],
    contextPages: ['login', 'register'],
    actionLabel: 'Go to Sign Up',
    actionRoute: '/login',
    order: 1,
  ),

  ChatbotQuestion(
    id: 'how-to-login',
    topicId: 'getting-started',
    question: 'How do I sign in to my account?',
    answer: '''To sign in to your account:

1. Tap "Sign In" on the home screen
2. Enter your email and password
3. Or use "Sign in with Google" or "Sign in with Apple"
4. Tap "Sign In" to access your account

Forgot your password? Tap "Forgot Password" to reset it.''',
    keywords: ['login', 'sign in', 'password', 'access'],
    relatedQuestions: ['how-to-register', 'forgot-password'],
    contextPages: ['login'],
    order: 2,
  ),

  ChatbotQuestion(
    id: 'verify-email',
    topicId: 'getting-started',
    question: 'How do I verify my email address?',
    answer: '''To verify your email:

1. Check your inbox for a verification email from Triply Stays
2. Click the verification link in the email
3. If you don't see it, check your spam folder
4. You can request a new verification email from your profile

Email verification helps secure your account and enables all features.''',
    keywords: ['verify', 'email', 'confirmation', 'validate'],
    relatedQuestions: ['how-to-register', 'how-to-login'],
    order: 3,
  ),

  ChatbotQuestion(
    id: 'forgot-password',
    topicId: 'getting-started',
    question: 'I forgot my password. How do I reset it?',
    answer: '''To reset your password:

1. Go to the Sign In screen
2. Tap "Forgot Password"
3. Enter your email address
4. Check your email for a reset link
5. Click the link and create a new password

The reset link expires in 24 hours. If you don't receive it, check your spam folder.''',
    keywords: ['forgot', 'password', 'reset', 'recover'],
    relatedQuestions: ['how-to-login'],
    order: 4,
  ),

  // Listings & Search
  ChatbotQuestion(
    id: 'how-to-search',
    topicId: 'listings',
    question: 'How do I search for listings?',
    answer: '''To search for vacation rentals:

1. Use the search bar on the home screen
2. Enter a location, city, or country
3. Tap the filter icon to refine your search
4. Filter by:
   - Price range
   - Property type
   - Amenities
   - Number of bedrooms/guests
5. View results in grid or map view

Pro tip: Save your favorite searches for quick access later!''',
    keywords: ['search', 'find', 'browse', 'filter', 'listings'],
    relatedQuestions: ['filter-listings', 'save-favorites'],
    contextPages: ['home', 'search'],
    order: 1,
  ),

  ChatbotQuestion(
    id: 'filter-listings',
    topicId: 'listings',
    question: 'How do I filter search results?',
    answer: '''To filter listings:

1. Tap the filter icon on the search bar
2. Available filters include:
   - **Price**: Set min and max price
   - **Property Type**: Apartment, house, villa, etc.
   - **Amenities**: WiFi, pool, parking, etc.
   - **Location**: Country and city
   - **Capacity**: Number of guests
3. Tap "Apply Filters" to see results
4. Use "Clear Filters" to reset

You can combine multiple filters to find the perfect place!''',
    keywords: ['filter', 'refine', 'amenities', 'price', 'type'],
    relatedQuestions: ['how-to-search', 'map-view'],
    order: 2,
  ),

  ChatbotQuestion(
    id: 'contact-host',
    topicId: 'listings',
    question: 'How do I contact a host?',
    answer: '''To contact a host:

1. Open the listing you're interested in
2. Scroll down to find the host section
3. Tap "Message Host" or "Contact"
4. Write your message with:
   - Your travel dates
   - Number of guests
   - Any questions about the property
5. Send your message

Hosts typically respond within 24 hours. You can check your messages in the Messages tab.''',
    keywords: ['contact', 'host', 'message', 'inquire', 'ask'],
    relatedQuestions: ['how-to-book', 'messaging'],
    contextPages: ['listing-detail'],
    order: 3,
  ),

  ChatbotQuestion(
    id: 'save-favorites',
    topicId: 'listings',
    question: 'How do I save listings to favorites?',
    answer: '''To save a listing to favorites:

1. Find a listing you like
2. Tap the heart icon on the listing card
3. The listing is now saved to your favorites
4. Access favorites from your profile or the Favorites tab

You can save unlimited listings and organize them for your trip planning!''',
    keywords: ['save', 'favorite', 'heart', 'wishlist', 'bookmark'],
    relatedQuestions: ['how-to-search'],
    order: 4,
  ),

  ChatbotQuestion(
    id: 'map-view',
    topicId: 'listings',
    question: 'How do I use the map view?',
    answer: '''To use map view:

1. Go to the home screen
2. Tap the map icon or "Map View" toggle
3. See all listings plotted on the map
4. Tap a marker to see listing details
5. Zoom in/out to explore different areas
6. Tap a listing card to view full details

Map view helps you find properties in your preferred location!''',
    keywords: ['map', 'view', 'location', 'area', 'markers'],
    relatedQuestions: ['how-to-search', 'filter-listings'],
    order: 5,
  ),

  // Account & Profile
  ChatbotQuestion(
    id: 'edit-profile',
    topicId: 'account',
    question: 'How do I edit my profile?',
    answer: '''To edit your profile:

1. Go to the Profile tab
2. Tap the edit icon or "Edit Profile"
3. You can update:
   - Profile photo
   - Name
   - Bio
   - Phone number
   - Location
4. Tap "Save" to update your profile

A complete profile helps build trust with hosts and guests!''',
    keywords: ['edit', 'profile', 'update', 'photo', 'bio'],
    relatedQuestions: ['upload-photo', 'verify-phone'],
    contextPages: ['profile'],
    order: 1,
  ),

  ChatbotQuestion(
    id: 'upload-photo',
    topicId: 'account',
    question: 'How do I upload a profile photo?',
    answer: '''To upload a profile photo:

1. Go to your Profile
2. Tap on your profile picture or the camera icon
3. Choose "Take Photo" or "Choose from Library"
4. Crop and adjust your photo
5. Tap "Save"

Tips for a great profile photo:
- Use a clear, recent photo of yourself
- Smile! It helps build trust
- Ensure good lighting''',
    keywords: ['photo', 'picture', 'avatar', 'image', 'upload'],
    relatedQuestions: ['edit-profile'],
    order: 2,
  ),

  ChatbotQuestion(
    id: 'become-host',
    topicId: 'account',
    question: 'How do I become a host?',
    answer: '''To become a host and list your property:

1. Go to your Profile
2. Tap "Add Listing" or "Become a Host"
3. Follow the listing creation wizard:
   - Add property details
   - Upload photos
   - Set your price
   - Add amenities
   - Set availability
4. Submit for review

Your listing will be reviewed and published within 24-48 hours!''',
    keywords: ['host', 'list', 'property', 'rent', 'landlord'],
    relatedQuestions: ['create-listing', 'edit-profile'],
    actionLabel: 'Create Listing',
    actionRoute: '/create-listing',
    order: 3,
  ),

  ChatbotQuestion(
    id: 'delete-account',
    topicId: 'account',
    question: 'How do I delete my account?',
    answer: '''To delete your account:

1. Go to Profile > Settings
2. Scroll to "Account"
3. Tap "Delete Account"
4. Confirm your decision

**Please note:**
- This action cannot be undone
- All your data will be permanently deleted
- Active bookings must be completed first
- Contact support if you need help''',
    keywords: ['delete', 'remove', 'close', 'account', 'deactivate'],
    relatedQuestions: ['edit-profile'],
    order: 4,
  ),

  // Features & Tools
  ChatbotQuestion(
    id: 'messaging',
    topicId: 'features',
    question: 'How does messaging work?',
    answer: '''The messaging feature allows you to communicate directly with hosts and guests:

1. Access Messages from the bottom navigation
2. All your conversations appear here
3. Tap a conversation to open it
4. Send text messages and photos
5. Get notifications for new messages

Tips:
- Be clear about your dates and needs
- Respond promptly to increase booking chances
- Keep all communication within the app for security''',
    keywords: ['message', 'chat', 'communication', 'inbox', 'conversation'],
    relatedQuestions: ['contact-host', 'notifications'],
    contextPages: ['messages'],
    order: 1,
  ),

  ChatbotQuestion(
    id: 'notifications',
    topicId: 'features',
    question: 'How do I manage notifications?',
    answer: '''To manage your notifications:

1. Go to Profile > Settings
2. Tap "Notifications"
3. Toggle notifications for:
   - New messages
   - Booking updates
   - Price alerts
   - Promotions
4. You can enable/disable push notifications

Make sure to enable important notifications so you don't miss booking inquiries!''',
    keywords: ['notifications', 'alerts', 'push', 'settings'],
    relatedQuestions: ['messaging'],
    order: 2,
  ),

  ChatbotQuestion(
    id: 'create-listing',
    topicId: 'features',
    question: 'How do I create a listing?',
    answer: '''To create a new listing:

1. Go to Profile or tap "+" button
2. Tap "Create Listing"
3. Follow the steps:
   - **Basic Info**: Title, description, property type
   - **Location**: Address, city, country
   - **Details**: Bedrooms, bathrooms, max guests
   - **Amenities**: WiFi, parking, pool, etc.
   - **Photos**: Upload at least 5 high-quality photos
   - **Pricing**: Set nightly rate and availability
4. Review and submit

High-quality photos and detailed descriptions get more bookings!''',
    keywords: ['create', 'listing', 'add', 'property', 'new'],
    relatedQuestions: ['become-host', 'edit-listing'],
    actionLabel: 'Create Listing',
    actionRoute: '/create-listing',
    order: 3,
  ),

  ChatbotQuestion(
    id: 'pricing',
    topicId: 'features',
    question: 'How does pricing work?',
    answer: '''Pricing on Triply Stays:

**For Guests:**
- Prices shown are per night
- Total includes: nightly rate × nights + service fee
- No hidden fees

**For Hosts:**
- Set your nightly rate
- Add weekend/holiday rates
- Offer discounts for longer stays
- Smart pricing suggestions available

You can negotiate directly with hosts through messaging for special rates!''',
    keywords: ['price', 'cost', 'rate', 'fee', 'payment'],
    relatedQuestions: ['create-listing', 'contact-host'],
    order: 4,
  ),

  ChatbotQuestion(
    id: 'how-to-book',
    topicId: 'features',
    question: 'How do I book a listing?',
    answer: '''To book a vacation rental:

1. Find a listing you like
2. Select your dates
3. Enter number of guests
4. Tap "Request to Book" or "Book Now"
5. Message the host to confirm details
6. Complete payment when approved

**Booking Tips:**
- Read reviews carefully
- Check the cancellation policy
- Message the host with questions first
- Verify all details before confirming''',
    keywords: ['book', 'reserve', 'booking', 'reservation', 'confirm'],
    relatedQuestions: ['contact-host', 'pricing'],
    order: 5,
  ),
];

/// Search through questions
List<ChatbotQuestion> searchQuestions(String query, {int limit = 10}) {
  if (query.isEmpty) return [];

  final lowerQuery = query.toLowerCase();
  final queryWords = lowerQuery.split(' ').where((w) => w.isNotEmpty).toList();

  // Score each question
  final scoredQuestions = chatbotQuestions.map((q) {
    double score = 0;

    // Check question text
    final lowerQuestion = q.question.toLowerCase();
    if (lowerQuestion.contains(lowerQuery)) {
      score += 10;
    }

    // Check keywords
    for (final keyword in q.keywords) {
      if (lowerQuery.contains(keyword.toLowerCase())) {
        score += 5;
      }
      for (final word in queryWords) {
        if (keyword.toLowerCase().contains(word)) {
          score += 2;
        }
      }
    }

    // Check answer
    final lowerAnswer = q.answer.toLowerCase();
    for (final word in queryWords) {
      if (lowerAnswer.contains(word)) {
        score += 1;
      }
    }

    return MapEntry(q, score);
  }).where((entry) => entry.value > 0).toList();

  // Sort by score descending
  scoredQuestions.sort((a, b) => b.value.compareTo(a.value));

  return scoredQuestions.take(limit).map((e) => e.key).toList();
}

/// Get questions for a topic
List<ChatbotQuestion> getQuestionsForTopic(String topicId) {
  return chatbotQuestions
      .where((q) => q.topicId == topicId)
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));
}

/// Get related questions
List<ChatbotQuestion> getRelatedQuestions(ChatbotQuestion question) {
  return question.relatedQuestions
      .map((id) => chatbotQuestions.firstWhere(
            (q) => q.id == id,
            orElse: () => question,
          ))
      .where((q) => q.id != question.id)
      .toList();
}

/// Get contextual questions for a page
List<ChatbotQuestion> getContextualQuestions(String pageName) {
  return chatbotQuestions
      .where((q) => q.contextPages.contains(pageName))
      .take(3)
      .toList();
}
