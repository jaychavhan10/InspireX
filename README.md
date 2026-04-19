# InspireX 🚀

**AI-powered Idea Bidding & Investment Platform**

A Flutter application that connects innovators with investors through an intelligent bidding system powered by machine learning.

---

## ✨ Features

### 💡 Core Functionality
- **Idea Marketplace**: Submit and discover innovative ideas across multiple categories (AI, Food, Blockchain, IoT, Healthcare, Automobile, Sustainability)
- **Smart Bidding System**: Real-time bidding with AI-suggested pricing based on idea potential
- **Live Bidding Tabs**: Upcoming, Ongoing, and Completed bids tracking
- **Admin Dashboard**: Verify ideas and investor profiles with approval workflow

### 🤖 AI & ML Features
- **Automated Summaries**: TextRank-powered summary generation from idea overview text
- **Sentiment Analysis**: Classify ideas as Positive/Negative/Neutral with confidence scores
- **Similarity Scoring**: Compare ideas to avoid duplicates and find related concepts  
- **AI Rating System**: Predict idea potential (0-5 star rating)
- **Dynamic Insights**: ML data fetched per-card and displayed with color-coded badges

### 🎨 User Experience
- **Material Design 3**: Modern UI with color scheme customization
- **Smooth Animations**: Custom fade + slide page transitions (400ms duration)
- **Dark Mode**: Full dark/light theme support with real-time toggle
- **Responsive Design**: Works on mobile, tablet, and web platforms
- **Search & Filter**: Find ideas by category with real-time search
- **Leaderboard**: Top investors ranking and profile system

### 🔐 Authentication & Authorization
- **Firebase Auth**: Secure email/password authentication
- **Role-Based Access**: Different UI/features for users vs admins
- **Profile Management**: User profiles with bidding history

### 📊 Real-time Features
- **Live Firestore Integration**: Real-time database updates
- **Idea Status Tracking**: Approved ideas with timestamps
- **Bidding History**: Complete bid tracking and management
- **Image Storage**: Firebase Storage for avatars and media

---

## 🛠️ Tech Stack

### Frontend
| Technology | Purpose |
|------------|---------|
| **Flutter 3.8+** | Cross-platform framework (iOS, Android, Web, Windows) |
| **Dart** | Programming language |
| **Material Design 3** | UI guidelines and components |
| **Google Fonts** | Custom typography (Plus Jakarta Sans) |
| **Image Picker** | User avatar and media selection |

### Backend & Database
| Service | Purpose |
|---------|---------|
| **Firebase Authentication** | User login/signup/account management |
| **Cloud Firestore** | Real-time NoSQL database |
| **Firebase Storage** | Image and file storage |
| **Firebase Core** | Firebase initialization and configuration |

### ML Pipeline (External)
| Component | Purpose |
|-----------|---------|
| **Flask Backend** | REST API for ML processing |
| **TextRank** | Automatic summarization algorithm |
| **VADER** | Sentiment analysis |
| **TF-IDF** | Similarity scoring |

---

## 📁 Project Structure

```
inspire_x/
├── lib/
│   ├── main.dart                           # App entry point & theme setup
│   ├── theme_manager.dart                  # Dark/light theme management
│   ├── screens/
│   │   ├── login_screen.dart              # Firebase authentication
│   │   ├── home_screen.dart               # Main feed with trending ideas
│   │   ├── search_screen.dart             # Search & category filtering
│   │   ├── idea_detail_screen.dart        # Full idea details with bidding CTA
│   │   ├── idea_bidding_screen.dart       # Bidding interface
│   │   ├── all_bidding_screen.dart        # Upcoming/Ongoing/Completed tabs
│   │   ├── leaderboard_screen.dart        # Top investors ranking
│   │   ├── my_ideas_screen.dart           # User's submitted ideas
│   │   ├── profile_screen.dart            # User profile & settings
│   │   ├── notifications_screen.dart      # Bid notifications
│   │   ├── admin_home_screen.dart         # Admin dashboard
│   │   ├── admin_verify_ideas_screen.dart # Approve/reject ideas
│   │   ├── admin_verify_profiles_screen.dart # Verify investor profiles
│   │   └── submit_idea_screen.dart        # Submit new ideas
│   ├── services/
│   │   └── ml_service.dart                # ML backend integration (HTTP)
│   ├── utils/
│   │   └── transitions.dart               # Smooth page animations (SmoothPageRoute)
│   └── generated/
│       └── ... (generated code)
├── android/                               # Android-specific configuration
├── ios/                                   # iOS-specific configuration
├── web/                                   # Web platform files
├── windows/                               # Windows platform files
├── linux/                                 # Linux platform files
├── macos/                                 # macOS platform files
├── pubspec.yaml                          # Dependencies & configuration
├── analysis_options.yaml                 # Lint rules
└── README.md                             # This file
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter 3.8+** - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart 3.0+** - Comes with Flutter
- **Git** - [Install Git](https://git-scm.com/)
- **Firebase Account** - [Create Account](https://firebase.google.com/)

### Step 1: Clone Repository
```bash
git clone https://github.com/YOUR_USERNAME/InspireX.git
cd InspireX
```

### Step 2: Get Flutter Dependencies
```bash
flutter pub get
```

### Step 3: Setup Firebase
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "InspireX"
3. Add Android app:
   - Package name: `com.example.inspire_x` (from `android/app/build.gradle`)
   - Download `google-services.json`
   - Place in `android/app/`
4. Add iOS app:
   - Bundle ID: `com.example.inspireX`
   - Download `GoogleService-Info.plist`
   - Open Xcode and add file to Runner
5. Enable services in Firebase Console:
   - ✓ Authentication (Email/Password)
   - ✓ Cloud Firestore
   - ✓ Storage

### Step 4: Configure ML Backend (Optional)
Edit `lib/services/ml_service.dart` and update the base URL:
```dart
const String baseUrl = 'http://192.168.1.7:5000'; // Change to your ML backend URL
```

### Step 5: Run the App
```bash
flutter run
```

Or select a specific platform:
```bash
flutter run -d chrome                  # Web
flutter run -d windows                 # Windows
flutter run -d macOS                   # macOS
```

---

## 📱 Key Screens

| Screen | Features | Users |
|--------|----------|-------|
| **Login** | Email/password auth, signup | All |
| **Home** | Trending ideas, ML summaries, smooth transitions | User/Investor |
| **Search** | Category filter, real-time search, sentiment badges | User/Investor |
| **Idea Detail** | Full description, ML insights, bidding CTA | User/Investor |
| **Bidding** | Place/manage bids, AI price suggestion | Investor |
| **Leaderboard** | Top investors ranking | All |
| **Profile** | User settings, bidding history, dark mode toggle | User |
| **My Ideas** | Submitted ideas, approval status | Innovator |
| **Admin Dashboard** | Approve ideas, verify profiles | Admin |

---

## 🎯 Core Features In Detail

### ML Insights on Idea Cards

Each discover card displays intelligent insights:

```
┌─────────────────────────────────┐
│ Rahul Sharma                    │  (Contributor)
│ AI-Powered Meal Planning System │  (Title)
│ Create personalized meal plans... │ (ML Summary - Italic)
│                                  │
│ ⭐ 4.5  😊 Positive  👍 245     │ (Star Rating | Sentiment | Likes)
│                                  │
│ [Food]  [Patented]              │ (Category & Patent Tags)
│                                  │
│ Base Price: ₹50,000             │ (Pricing Info)
│ [Interested? Start Bidding]      │ (CTA Button)
└─────────────────────────────────┘
```

**Sentiment Color Coding:**
- 🟢 **Green** (#10B981): Positive sentiment (score ≥ 0.05)
- 🔴 **Red** (#EF4444): Negative sentiment (score ≤ -0.05)
- 🟡 **Amber** (#FBBF24): Neutral sentiment

### Smooth Page Transitions

All navigation uses custom `SmoothPageRoute`:
- **Duration**: 400ms
- **Animation**: Fade (opacity 0→1) + Slide (from right)
- **Curve**: EaseInOut for natural deceleration
- **Helper**: `navigateSmoothly()` function in `lib/utils/transitions.dart`

Example usage:
```dart
navigateSmoothly(context, IdeaDetailScreen(...));
```

### Dark Mode Support

Toggle in navigation drawer:
- **Light Theme**: Clean white backgrounds with indigo accents
- **Dark Theme**: Dark blue surface (#0F172A) with proper contrast
- **Real-time**: Changes apply across all screens instantly
- **Persistent**: Theme preference saved in `ThemeManager`

---

## 🔑 Dependencies

```yaml
# UI & Design
google_fonts: ^6.2.1          # Custom fonts (Plus Jakarta Sans)
cupertino_icons: ^1.0.8       # iOS style icons

# Firebase & Backend
firebase_auth: ^4.17.0        # Authentication
firebase_core: ^2.30.0        # Firebase initialization
cloud_firestore: ^4.15.0      # Real-time database
firebase_storage: ^11.7.0     # File & image storage

# Media & Utilities
image_picker: ^1.1.2          # Image selection from gallery/camera
http: ^1.6.0                  # HTTP client for ML API calls
```

---

## 🔐 Security Best Practices

### Firebase Rules
```javascript
// Firestore Rules (update in Firebase Console)
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /approved_ideas/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == resource.data.userId;
    }
  }
}
```

### Environment Security
- ✓ Never commit `google-services.json` with real keys
- ✓ Use `.gitignore` to exclude sensitive files
- ✓ Validate inputs server-side
- ✓ Use HTTPS for API calls
- ✓ Never hardcode API keys in code

---

## 🌐 API Integration

### ML Backend Endpoint

```http
POST http://192.168.1.7:5000/process
Content-Type: application/json

{
  "text": "Detailed problem statement or overview text"
}

Response:
{
  "summary": "Auto-generated summary of the idea",
  "rating": 4.2,
  "sentiment": "Positive",
  "sentiment_score": 0.75,
  "similarity_score": 0.85
}
```

**Implementation:** See `lib/services/ml_service.dart`

---

## 🚧 Future Enhancements

- [ ] Video pitch support for ideas
- [ ] Real-time chat between investor and founder
- [ ] Payment gateway integration (Razorpay/Stripe)
- [ ] Advanced analytics dashboard for creators
- [ ] Milestone tracking for funded ideas
- [ ] Push notifications for bids/messages
- [ ] Automated contract generation
- [ ] Advanced filtering and sorting
- [ ] User reputation system
- [ ] Idea collaboration features

---

## 🤝 Contributing

We welcome contributions! Here's how to help:

1. **Fork the repository**
   ```bash
   github.com/YOUR_USERNAME/InspireX/fork
   ```

2. **Create feature branch**
   ```bash
   git checkout -b feature/YourFeatureName
   ```

3. **Make your changes**
   - Follow existing code style
   - Test on multiple platforms
   - Update documentation

4. **Commit with clear message**
   ```bash
   git commit -m "feat: Add YourFeatureDescription"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/YourFeatureName
   ```

6. **Open Pull Request**
   - Describe changes clearly
   - Reference any related issues
   - Include screenshots for UI changes

---

## 📝 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 InspireX Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

---

## 👨‍💼 Team & Contact

**Project Lead**
- Name: [Your Name]
- GitHub: [@YOUR_USERNAME](https://github.com/YOUR_USERNAME)
- Email: your.email@example.com
- LinkedIn: [Your LinkedIn]

**Questions?**
- 📧 Email Support
- 🐛 [Report Issues](https://github.com/YOUR_USERNAME/InspireX/issues)
- 💬 [Discussions](https://github.com/YOUR_USERNAME/InspireX/discussions)

---

## 🙏 Acknowledgments

- **Flutter Team** - Amazing cross-platform framework
- **Firebase** - Robust backend infrastructure
- **Material Design 3** - Beautiful design guidelines
- **Google Fonts** - Typography excellence
- **Open Source Community** - Inspiration and support

---

## 📊 Project Stats

- ✨ **12+ Screens** with smooth animations
- 🤖 **3 ML Features** (Summary, Sentiment, Similarity)
- 🎨 **Dark Mode** fully supported
- 🔥 **Real-time** Firestore updates
- 📱 **Multi-platform** (iOS, Android, Web, Windows, Linux, macOS)

---

## 🎯 Quick Links

- [Issues & Feature Requests](https://github.com/YOUR_USERNAME/InspireX/issues)
- [Discussions & Q&A](https://github.com/YOUR_USERNAME/InspireX/discussions)
- [Flutter Docs](https://flutter.dev/docs)
- [Firebase Docs](https://firebase.google.com/docs)
- [Material Design 3](https://m3.material.io/)

---

**Made with ❤️ by the InspireX Team | Happy Innovating! 🚀**
