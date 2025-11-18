# FixIt - Handyman Service App 🔧

A Flutter mobile application connecting skilled handymen with customers for various home service needs in Kandy, Sri Lanka. FixIt provides a seamless dual-sided platform for both service providers and customers.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Status](https://img.shields.io/badge/Status-In%20Development-yellow)](https://github.com)

---

## 📱 App Overview

**FixIt** bridges the gap between skilled handymen and customers seeking reliable home services. With separate interfaces for customers and service providers, the app ensures a tailored experience for both user types.

### Current Version: `0.4.0 (Alpha)`
**Progress**: ~40% Complete | **Status**: 🚧 Active Development

---

## ✨ Implemented Features

### 🎨 Authentication & Onboarding
- ✅ **Splash Screen** - Branded loading experience
- ✅ **Login Screen** - Email/password authentication UI
- ✅ **Register Screen** - New user registration flow
- ✅ **Role Selection** - Choose between Customer/Handyman

### 👤 Customer Features
- ✅ **Home Dashboard** - Beautiful overview with service categories
- ✅ **Emergency Toggle** - Quick access for urgent services
- ✅ **Service Browsing** - 8+ categories (Plumbing, Electrical, Carpentry, etc.)
- ✅ **Search Functionality** - Search bar for services and handymen
- ✅ **Service Details** - Detailed view of each service category
- ✅ **Handyman Profiles** - View professional profiles with ratings
- ✅ **Booking Interface** - Bottom sheet for booking requests
- ✅ **Reviews Display** - Read handyman reviews and ratings
- ✅ **Profile Management** - View and edit customer profile
- ✅ **Bottom Navigation** - Intuitive tab-based navigation

### 🔧 Handyman Features
- ✅ **Home Dashboard** - Job requests and earnings overview
- ✅ **Availability Toggle** - Set online/offline status
- ✅ **Job Requests Feed** - Real-time incoming job requests
- ✅ **Bookings List** - View upcoming and completed jobs
- ✅ **Job Details Sheet** - Detailed view of customer requests
- ✅ **Accept/Decline Jobs** - Quick action buttons for requests
- ✅ **Stats Dashboard** - Track completed jobs and earnings
- ✅ **Profile Management** - Edit handyman profile and services
- ✅ **Bottom Navigation** - Easy access to all features

### 🎯 Shared Components
- ✅ **Custom Widgets** - Reusable buttons, text fields, cards
- ✅ **Color Theme** - Consistent purple-based brand colors
- ✅ **Data Models** - User, Handyman, Booking, JobRequest, ServiceCategory
- ✅ **Responsive UI** - Works on various screen sizes
- ✅ **Material Design** - Modern, clean interface

---

## 🚧 In Development & Planned Features

### ⚠️ Priority: Backend Integration
- [ ] REST API setup with SQL Server
- [ ] JWT authentication implementation
- [ ] User registration/login APIs
- [ ] Real data fetching and synchronization
- [ ] CRUD operations for all entities

### 📅 Booking Management System
- [ ] Complete bookings screen with filters
- [ ] Real-time booking status tracking
- [ ] Cancel/reschedule functionality
- [ ] Mark jobs as complete
- [ ] Booking history with date filters
- [ ] Notifications for status changes

### 💬 Real-time Chat System
- [ ] One-on-one messaging between customer and handyman
- [ ] Text and image messaging
- [ ] Online/offline status indicators
- [ ] Message notifications
- [ ] Chat history
- [ ] Firebase or Socket.io integration

### 🗺️ Maps & Location Services
- [ ] Google Maps integration
- [ ] Show handyman location on map
- [ ] Real-time location tracking
- [ ] Distance calculation
- [ ] Address autocomplete
- [ ] Navigation to service location

### 💳 Payment Integration
- [ ] Payment gateway setup (Stripe/PayPal/Local)
- [ ] Add payment method screen
- [ ] Secure payment processing
- [ ] Payment history
- [ ] Invoice generation
- [ ] Multiple payment options (Card, Cash, Digital Wallet)
- [ ] Refund handling

### 🔔 Notification System
- [ ] Firebase Cloud Messaging setup
- [ ] Push notifications for bookings
- [ ] In-app notification center
- [ ] Mark as read/unread
- [ ] Notification preferences
- [ ] Email notifications
- [ ] SMS alerts

### 🔍 Advanced Search & Filters
- [ ] Filter by price range
- [ ] Filter by rating (1-5 stars)
- [ ] Filter by distance/location
- [ ] Filter by availability
- [ ] Sort options (price, rating, distance)
- [ ] Search history
- [ ] Save favorite searches

### ⭐ Rating & Review System
- [ ] Submit review after job completion
- [ ] Rate handyman (1-5 stars with half-stars)
- [ ] Write detailed review
- [ ] Edit/delete own reviews
- [ ] Report inappropriate reviews
- [ ] Review moderation system

### 🚨 Emergency Services Enhancement
- [ ] Priority handyman listing
- [ ] Emergency pricing structure
- [ ] Fast-track booking flow
- [ ] Instant notifications to available handymen
- [ ] Emergency service badges

### 🛠️ Additional Handyman Features
- [ ] Portfolio/gallery of previous work
- [ ] Service area selection
- [ ] Custom pricing management
- [ ] Calendar integration
- [ ] Detailed earnings dashboard
- [ ] Payout request system
- [ ] Tax document generation

### 👥 Additional Customer Features
- [ ] Favorite handymen list
- [ ] Booking reminders
- [ ] Service recommendations based on history
- [ ] Multiple saved addresses
- [ ] Emergency contacts
- [ ] Service history analytics

### 🎨 Polish & UX Improvements
- [ ] Smooth animations and transitions
- [ ] Skeleton loaders for async data
- [ ] Pull-to-refresh functionality
- [ ] Infinite scroll for lists
- [ ] Image optimization
- [ ] Custom app icon and splash screen
- [ ] Onboarding tutorial for new users

### 🔐 Security & Quality
- [ ] Comprehensive input validation
- [ ] Error handling and user feedback
- [ ] Loading states for all async operations
- [ ] Empty state designs
- [ ] Offline mode support
- [ ] Local data caching
- [ ] Security best practices (encryption, secure storage)

---

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **UI**: Material Design 3 with custom theming
- **State Management**: StatefulWidget (planned upgrade to Provider/Riverpod)

### Backend (Planned)
- **Database**: SQL Server
- **API**: REST API with JWT authentication
- **Real-time**: Firebase Realtime Database / Socket.io
- **Storage**: Cloud storage for images
- **Notifications**: Firebase Cloud Messaging

### Third-party Services (Planned)
- **Maps**: Google Maps API
- **Payment**: Stripe / PayPal / Local payment gateways
- **Analytics**: Firebase Analytics
- **Crash Reporting**: Firebase Crashlytics

---

## 📋 Prerequisites

Before running this project, ensure you have:

- Flutter SDK 3.0 or higher
- Dart SDK 3.x
- Android Studio or VS Code with Flutter extensions
- Git
- For iOS: Xcode (Mac only)
- For Android: Android SDK

---

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/fixit-app.git
cd fixit_app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
# Check connected devices
flutter devices

# Run on default device
flutter run

# Run on specific device
flutter run -d <device_id>

# Run in release mode (better performance)
flutter run --release
```

### 4. Build for Production
```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires Mac)
flutter build ios --release
```

---

## 📁 Project Structure

```
fixit_app/
├── lib/
│   ├── main.dart                           # App entry point
│   │
│   ├── models/                             # Data models
│   │   ├── booking_model.dart
│   │   ├── handyman_model.dart
│   │   ├── job_request_model.dart
│   │   ├── service_category_model.dart
│   │   └── user_model.dart
│   │
│   ├── screens/                            # All app screens
│   │   ├── splash_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── role_selection_screen.dart
│   │   │
│   │   ├── home/
│   │   │   ├── customer_home_screen.dart
│   │   │   ├── handyman_home_screen.dart
│   │   │   └── all_categories_screen.dart
│   │   │
│   │   ├── bookings/
│   │   │   ├── bookings_screen.dart
│   │   │   └── handyman_bookings_screen.dart
│   │   │
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   └── edit_profile_screen.dart
│   │   │
│   │   ├── notifications/
│   │   │   └── notifications_screen.dart
│   │   │
│   │   ├── search/
│   │   │   ├── search_screen.dart
│   │   │   └── handyman_search_screen.dart
│   │   │
│   │   ├── services/
│   │   │   └── service_detail_screen.dart
│   │   │
│   │   └── handyman/
│   │       └── handyman_detail_screen.dart
│   │
│   ├── widgets/                            # Reusable UI components
│   │   ├── booking_bottom_sheet.dart
│   │   ├── booking_card.dart
│   │   ├── category_card.dart
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── handyman_card.dart
│   │   ├── job_request_card.dart
│   │   ├── job_request_details_bottom_sheet.dart
│   │   └── search_bar_widget.dart
│   │
│   └── utils/                              # Utilities and constants
│       ├── colors.dart
│       └── constants.dart
│
├── assets/                                 # Images, fonts, icons
│   ├── images/
│   └── fonts/
│
├── android/                                # Android-specific files
├── ios/                                    # iOS-specific files
├── pubspec.yaml                            # Dependencies
├── .gitignore
└── README.md
```

---

## 🎨 Design System

### Color Palette
```dart
Primary: Deep Purple (#673AB7)
Secondary: Purple Accent (#7C4DFF)
Success: Green (#4CAF50)
Error: Red (#F44336)
Warning: Orange (#FF9800)
Background: Light Grey (#F5F5F5)
Text Dark: #212121
Text Light: #757575
```

### Key UI Components
- Custom gradient headers
- Bottom sheet modals for details
- Card-based layouts
- Badge notifications
- Floating action buttons
- Smooth page transitions

---

## 📊 Development Progress

### Overall Progress: ~40% Complete

| Feature Category | Status | Completion |
|-----------------|--------|-----------|
| UI/UX Design | ✅ Complete | 100% |
| Authentication Flow | ✅ Complete | 100% |
| Customer Features | ✅ Complete | 90% |
| Handyman Features | ✅ Complete | 90% |
| Backend Integration | ❌ Not Started | 0% |
| Booking Management | 🚧 In Progress | 20% |
| Chat System | ❌ Not Started | 0% |
| Payment Integration | ❌ Not Started | 0% |
| Maps & Location | ❌ Not Started | 0% |
| Notifications | ❌ Not Started | 0% |

---

## 🗺️ Development Roadmap

### Phase 1: Backend Integration (2-3 weeks) - NEXT
- [ ] Set up SQL Server database
- [ ] Create REST API endpoints
- [ ] Implement JWT authentication
- [ ] Connect app to real backend
- [ ] Test all CRUD operations

### Phase 2: Core Features (3-4 weeks)
- [ ] Complete booking management flow
- [ ] Implement payment gateway
- [ ] Add basic notification system
- [ ] Fix any UI overflow issues

### Phase 3: Real-time Features (2-3 weeks)
- [ ] Integrate Firebase for chat
- [ ] Add Google Maps integration
- [ ] Implement real-time tracking
- [ ] Push notifications setup

### Phase 4: Enhancement & Polish (2-3 weeks)
- [ ] Rating and review system
- [ ] Advanced search filters
- [ ] Emergency service optimization
- [ ] Performance optimization
- [ ] Animations and transitions

### Phase 5: Testing & Launch (2 weeks)
- [ ] Comprehensive testing
- [ ] Bug fixes
- [ ] App Store submission
- [ ] Play Store submission
- [ ] Marketing materials

**Estimated Total Time to MVP**: 11-15 weeks

---

## 🐛 Known Issues

### Current Issues
- [ ] Minor UI overflow on some screens (edge cases)
- [ ] Mock data being used (needs backend)
- [ ] No persistent login (token storage needed)
- [ ] Images not optimized

### Planned Fixes
- Implement proper responsive layouts
- Connect to real database
- Add secure token storage
- Optimize image loading

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the project
2. Create your feature branch
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. Commit your changes
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```
4. Push to the branch
   ```bash
   git push origin feature/AmazingFeature
   ```
5. Open a Pull Request

### Coding Standards
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Write clear, descriptive commit messages
- Add comments for complex logic
- Test on both Android and iOS before submitting
- Keep widgets small and reusable
- Use meaningful variable names

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team


- Dhanushka - Develope
- Enidu -     UI/UX Developer  https://github.com/EniduM
- Jadu -      QA/Test engineer 
- Shahima -   Scrum Master

- Open to contributors!

---

## 📞 Contact & Support

- **GitHub**: [Dhanu45-sketch](https://github.com/Dhanu45-sketch)
- **Email**: dhanushkasachintha@gmail.com
- **Project Link**: [https://github.com/Dhanu45-sketch/fixit-app](https://github.com/Dhanu45-sketch/fixit-app)
- **Issues**: [Report bugs](https://github.com/Dhanu45-sketch/fixit-app/issues)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design for UI/UX guidelines
- The Flutter community for packages and support
- All contributors and testers

---

## 📱 Screenshots

*Screenshots coming soon...*

---

## 💡 Learning Resources

If you're new to the technologies used:
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)
- [Provider State Management](https://pub.dev/packages/provider)

---

**Made with ❤️ in Kandy, Sri Lanka**

**Status**: 🚧 In Active Development | **Version**: 0.4.0 (Alpha) | **Last Updated**: November 2025
