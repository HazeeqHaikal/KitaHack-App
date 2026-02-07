# Due - Your Academic Timeline, Automated

<div align="center">
  <h3>An intelligent academic scheduling assistant powered by Google Gemini AI</h3>
  <p><strong>Track:</strong> Quality Education (SDG 4)</p>
  <p>
    <img src="https://img.shields.io/badge/Flutter-3.38.6-blue?logo=flutter" alt="Flutter Version">
    <img src="https://img.shields.io/badge/Dart-3.10.7-blue?logo=dart" alt="Dart Version">
    <img src="https://img.shields.io/badge/Google%20Gemini-2.5%20Pro-orange" alt="Gemini AI">
    <img src="https://img.shields.io/badge/Status-Production%20Ready-green" alt="Status">
  </p>
</div>

---

## 📖 Overview

**Due** is a fully-functional Flutter mobile application that helps university students manage their academic deadlines through AI-powered automation. By leveraging Google Gemini 2.5 Pro, Firebase, and Google Calendar APIs, the app transforms static course syllabi into dynamic, synchronized calendar events.

### The Problem

University students face a "deadline fragmentation" crisis:
- ⚠️ **Manual Entry Error**: Transferring dates from PDFs to calendars is tedious and error-prone
- 📅 **Missed Deadlines**: Important dates get buried in text-heavy documents
- 😰 **Academic Stress**: The constant anxiety of "forgetting something" contributes to burnout

### Our Solution

**Due** acts as an intelligent bridge between static documents and dynamic scheduling:
1. **📤 Upload**: Student uploads a course syllabus (PDF/Image) via file picker
2. **🤖 Analyze**: Google Gemini 2.5 Pro parses the document and extracts dates, assignments, and exams
3. **📋 Review**: User reviews extracted events with filtering and priority sorting
4. **📅 Sync**: Selected events sync to Google Calendar with customizable reminders

---

## 🎯 SDG Alignment: Goal 4 (Quality Education)

Due directly supports **SDG 4: Quality Education** (Target 4.4: Skills for employment and effective learning environments).

By automating academic organization, we:
- ✅ Remove the barrier of poor time management
- ✅ Allow students to focus mental energy on quality learning
- ✅ Foster a more supportive and efficient educational environment
- ✅ Reduce student stress and academic burnout

---

## 🏗️ Technical Architecture

### Technology Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **AI Engine** | Google Gemini API | 2.5 Pro | PDF/Image parsing and structured data extraction |
| **Calendar Integration** | Google Calendar API | v3 | OAuth2 flow and event synchronization |
| **Frontend** | Flutter | 3.38.6 | Cross-platform mobile UI (Android/iOS/Windows) |
| **Backend & Auth** | Firebase | Core 3.6.0 | Authentication & cloud file storage |
| **State Management** | Local State | StatefulWidget | Component-level state management |
| **File Handling** | FilePicker | 8.1.4 | Cross-platform file selection |
| **HTTP Client** | Dio | 5.7.0 | API communication with retry logic |

### Architecture Flow

```
[User App (Flutter)] 
    ↓ Upload PDF
[File Picker (10MB limit, PDF/JPG/PNG)]
    ↓
[Firebase Storage (Optional)]
    ↓ syllabi/{userId}/{timestamp}_{filename}
[Gemini 2.5 Pro API]
    ↓ Structured JSON Response
[CourseInfo Model with AcademicEvents]
    ↓ User Review & Selection
[Google Calendar API (OAuth2)]
    ↓ Event Creation with Reminders
[User Calendar Updated ✓]
```

### Data Flow

1. **File Selection**: `FilePicker.platform.pickFiles()` with validation
2. **Optional Upload**: Firebase Storage with progress monitoring
3. **AI Analysis**: Gemini API with structured prompt engineering
4. **JSON Parsing**: Extract course details, events, priorities, weightages
5. **User Review**: Filter by type/priority, select events to sync
6. **OAuth Flow**: Google Sign-In with calendar read/write scopes
7. **Event Sync**: Create calendar events with color coding and multi-reminders

---

## 🚀 Features

### ✅ Phase 1 - Complete Implementation

#### Core Functionality
- ✅ **PDF/Image Upload**: File picker with validation (PDF, JPG, PNG up to 10MB)
- ✅ **Gemini AI Analysis**: Real-time multimodal document processing
- ✅ **Structured Extraction**: Course name, instructor, events, deadlines, weightages
- ✅ **Google Calendar Sync**: OAuth2 authentication and event creation
- ✅ **Firebase Storage**: Optional cloud backup of uploaded files
- ✅ **Environment Configuration**: Secure API key management via .env

#### User Interface
- ✅ **Onboarding Screen**: Welcome flow for new users
- ✅ **Authentication**: 
  - Email/password registration and login
  - Google Sign-In integration
  - **Guest Mode**: Continue without account (anonymous authentication)
  - Password reset functionality
- ✅ **Home Dashboard**: 
  - Stats overview (courses, events, weekly deadlines, priorities)
  - Upcoming deadlines with urgency indicators
  - Quick navigation to all features
- ✅ **Upload Screen**: 
  - File selection with drag-and-drop support
  - Real-time processing status
  - Error handling and validation feedback
- ✅ **Result Screen**:
  - Event review with extracted information
  - Filter by type (Assignment, Exam, Quiz, Project, Lab, etc.)
  - Sort by date, priority, or type
  - Multi-select for calendar sync
- ✅ **Calendar Sync Screen**:
  - Google account authentication
  - Calendar selection from user's calendars
  - Multiple reminder configuration (1-7 days before)
  - Sync status and error handling
  - Batch event deletion for cleanup
- ✅ **Course List Screen**: View all courses with statistics
- ✅ **Settings Screen**: Account management, preferences, data management
- ✅ **Profile Management**: Update display name and email via Firebase

#### Design System
- ✅ **Glassmorphism UI**: Modern frosted glass aesthetic
- ✅ **Dark Theme**: Optimized for reduced eye strain
- ✅ **Color-Coded Priorities**:
  - 🔴 High Priority (≥40% weightage) → Red calendar events
  - 🟡 Medium Priority (20-39% weightage) → Yellow calendar events
  - 🟢 Low Priority (<20% weightage) → Green calendar events
- ✅ **Urgency Indicators**:
  - 🔴 Critical (due in ≤3 days)
  - 🟡 Warning (due in 4-7 days)
  - 🟢 Normal (due in >7 days)

#### Development Tools
- ✅ **Mock Data Service**: Comprehensive test data with 4 sample courses (442 lines)
- ✅ **Debug Logging**: Extensive console output for troubleshooting
- ✅ **Error Recovery**: Retry logic (3 attempts) for API calls

### 🎨 Phase 2 - UI Implemented (Mock Functionality)

These features have **complete UI implementations** but currently use mock data instead of live AI/API integration:

- 🎨 **Study Allocator Screen** (487 lines)
  - UI: Complete study session planning interface
  - Status: Generates mock study blocks, no actual calendar integration
  - Future: Will use AI to find free calendar slots automatically

- 🎨 **Task Breakdown Screen** (547 lines)
  - UI: Complete task management and breakdown interface
  - Status: Mock AI task generation based on event type
  - Future: Will use Gemini to intelligently break down assignments

- 🎨 **Resource Finder Screen** (613 lines)
  - UI: Complete resource search and filtering interface
  - Status: Mock YouTube/web resources displayed
  - Future: Will integrate real search APIs for study materials

### 🔄 Phase 3 - Future Enhancements

- 📤 **Group Sync**: Class representative uploads once, generates shareable course code
- 👥 **Code-Based Join**: Students join using course code (no re-upload needed)
- 🔔 **Smart Notifications**: Progressive reminders based on event priority
- 📊 **Analytics Dashboard**: Track completion rates and study patterns

### 🧠 Phase 4 - Advanced AI Features

- 📚 **Study Plan Generation**: Auto-schedule study blocks before exams
- ⚖️ **Balanced Revision**: Timetable based on topic complexity and weightage
- 🎯 **Personalized Recommendations**: Adapt to student's productivity patterns
- 📈 **Progress Tracking**: Milestone completion and deadline adherence

---

## 📦 Installation & Setup

### Prerequisites
- **Flutter SDK**: 3.38.6 ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Dart SDK**: 3.10.7 (included with Flutter)
- **Android Studio** or **Xcode** (for emulators)
- **Google Cloud Account** (for API access)
- **Firebase Account** (for backend services - optional)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/HazeeqHaikal/KitaHack-App.git
   cd due
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API keys** (see [Setup Guide](#-api-configuration-required))
   ```bash
   # Copy the example environment file
   cp .env.example .env
   # Edit .env and add your API keys
   notepad .env
   ```

4. **Run the app**
   ```bash
   # For Windows Desktop
   flutter run -d windows
   
   # For Android Emulator
   flutter run -d emulator
   
   # For connected Android device
   flutter run -d <device-id>
   ```

5. **Build release APK** (Android)
   ```bash
   flutter build apk --release
   # Output: build/app/outputs/flutter-apk/app-release.apk (~50MB)
   ```

---

## 🔧 API Configuration (REQUIRED)

The app **requires API keys** to function. Follow the [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed instructions.

### Required Services

#### 1. Google Gemini API (Required)
```bash
# Get your API key from:
https://makersuite.google.com/app/apikey

# Add to .env file:
GEMINI_API_KEY=your_gemini_api_key_here
```

#### 2. Google Calendar API (Required)
```bash
# Steps:
1. Go to: https://console.cloud.google.com/
2. Create new project or select existing
3. Enable "Google Calendar API"
4. Configure OAuth Consent Screen
5. Create OAuth 2.0 Client ID (Web application)
6. Add to .env:
GOOGLE_CLIENT_ID=your_client_id_here.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_client_secret_here
```

#### 3. Firebase (Optional)
Firebase is used for optional file storage and authentication. The app will work without it in limited capacity.

```bash
# Steps:
1. Go to: https://console.firebase.google.com/
2. Create new project
3. Add Android app with package: com.example.due
4. Download google-services.json → android/app/
5. Enable Authentication (Google provider + Anonymous)
6. Enable Storage with test mode rules
```

### Configuration Files

```
due/
├── .env                          # YOUR API keys (create from .env.example)
├── .env.example                  # Template for API keys
├── SETUP_GUIDE.md                # Detailed setup instructions
└── android/
    └── app/
        └── google-services.json  # Firebase config (optional)
```

**⚠️ Important**: You must create your own `.env` file by copying `.env.example` and adding your API keys. The `.env` file is excluded from version control for security.

**🔐 Security Note**: The included SETUP_GUIDE.md contains example credentials for demonstration purposes. These should be replaced with your own credentials for production use.

---

## 📱 Project Structure

```
due/
├── lib/
│   ├── main.dart                      # App entry with Firebase/dotenv initialization
│   ├── config/
│   │   └── api_config.dart            # Centralized API key management
│   ├── screens/
│   │   ├── onboarding_screen.dart     # Welcome/intro screen
│   │   ├── login_screen.dart          # Email/Google/Guest authentication
│   │   ├── register_screen.dart       # User registration
│   │   ├── forgot_password_screen.dart # Password reset
│   │   ├── home_screen.dart           # Dashboard with stats
│   │   ├── upload_screen.dart         # File picker + Gemini analysis
│   │   ├── result_screen.dart         # Event review & selection
│   │   ├── calendar_sync_screen.dart  # Google OAuth + event sync
│   │   ├── course_list_screen.dart    # All courses view
│   │   ├── event_detail_screen.dart   # Individual event details
│   │   ├── settings_screen.dart       # App settings
│   │   ├── study_allocator_screen.dart # Study planning (UI complete, mock data)
│   │   ├── task_breakdown_screen.dart  # Task management (UI complete, mock data)
│   │   └── resource_finder_screen.dart # Resource search (UI complete, mock data)
│   ├── services/
│   │   ├── gemini_service.dart        # Gemini 2.5 Pro API integration
│   │   ├── firebase_service.dart      # Firebase Storage + Auth
│   │   ├── calendar_service.dart      # Google Calendar API + OAuth
│   │   └── mock_data_service.dart     # Test data (4 sample courses, 442 lines)
│   ├── models/
│   │   ├── academic_event.dart        # Event data model
│   │   └── course_info.dart           # Course data model
│   ├── utils/
│   │   ├── constants.dart             # App-wide constants
│   │   └── date_formatter.dart        # Date utility functions
│   └── widgets/
│       ├── custom_buttons.dart        # Reusable button components
│       ├── event_card.dart            # Event display card
│       ├── glass_container.dart       # Glassmorphism container
│       ├── empty_state.dart           # Empty state component
│       └── info_banner.dart           # Info banner component
├── android/                           # Android-specific configuration
├── windows/                           # Windows desktop support
├── test/
│   └── widget_test.dart               # Basic smoke test
├── .env.example                       # Environment variable template
├── SETUP_GUIDE.md                     # Comprehensive setup documentation
└── pubspec.yaml                       # Dependencies (17 total packages)
```

---

## 🎨 Key Innovations

### 1. No-Template Extraction
Unlike regex-based parsers, Due uses **semantic understanding** via Gemini 2.5 Pro:
- ✅ Works with tables, bullet lists, paragraphs
- ✅ Handles unstructured syllabi layouts
- ✅ Extracts context (exam vs assignment vs quiz)

### 2. Weightage-Aware Prioritization
The AI extracts importance context automatically:
- "Final Exam (40%)" → High priority, red calendar event
- "Quiz 1 (5%)" → Low priority, green calendar event
- Enables intelligent reminder scheduling

### 3. Flexible Date Parsing
Gemini handles various date formats:
- "January 5th, 2026"
- "05/01/2026"
- "Week 3 Monday"
- Normalizes to ISO 8601 for universal calendar compatibility

### 4. Multi-Modal Input Support
- 📄 PDF documents
- 🖼️ JPG/PNG images
- 📱 Mobile camera captures (future)

### 5. Graceful Degradation
- Firebase optional (app works without it)
- Guest mode for users without accounts
- Error handling with user-friendly messages
- Retry logic (3 attempts) for API calls
- Offline mode considerations (future)

---

## 📊 Success Metrics

| Metric | Target | Current Status |
|--------|--------|----------------|
| **Extraction Accuracy** | >90% for standard syllabi | Testing phase |
| **Time Saved** | <5 minutes (vs ~2 hours manual) | ✅ Achieved |
| **API Response Time** | <30 seconds for analysis | ✅ Average 15-25s |
| **User Retention** | Return rate at next semester | Deployment pending |
| **Build Size** | <60MB APK | ✅ 50.1MB (release) |

---

## 🔐 Security & Privacy

- ✅ **Environment Variables**: API keys stored in .env (excluded from git)
- ✅ **OAuth 2.0**: Secure Google authentication flow
- ✅ **Firebase Anonymous Auth**: Guest mode for privacy-conscious users
- ✅ **HTTPS Only**: All API communication encrypted
- ⚠️ **Firebase Rules**: Currently in test mode (update for production)
- ⚠️ **OAuth Consent**: Requires Google Cloud verification for public release

### Privacy Considerations
- No user data stored on external servers (unless Firebase opted in)
- Calendar access limited to read/write events only
- Uploaded files can be processed locally (Firebase optional)
- No analytics or tracking implemented
- Guest mode operates with anonymous authentication

---

## 🐛 Troubleshooting

### Common Issues

**1. "Gemini API key not found"**
```bash
# Solution: Create .env file from template
copy .env.example .env
# Edit .env and add: GEMINI_API_KEY=your_key_here
# Restart the app
```

**2. "Google Sign-In failed"**
```bash
# Solution: Check OAuth credentials
# Ensure GOOGLE_CLIENT_ID in .env matches Google Cloud Console
# Add authorized redirect URIs in OAuth consent screen
```

**3. "Firebase initialization failed"**
```bash
# This is OK if you're not using Firebase
# App will continue without file storage in limited mode
# To fix: Add google-services.json to android/app/
```

**4. Build errors**
```bash
# Run flutter clean and reinstall dependencies
flutter clean
flutter pub get
flutter run
```

### Debug Mode
The app includes extensive debug logging. Check console output for:
- API request/response details
- File upload progress
- Calendar sync operations
- Error stack traces

---

## 🧪 Testing

### Current Test Coverage
The project currently includes basic test infrastructure:
- ✅ Smoke test for onboarding screen
- ⚠️ Limited coverage - comprehensive tests planned for future releases

### Manual Testing Checklist
- [ ] File picker selects PDF/JPG/PNG files
- [ ] 10MB file size limit enforced
- [ ] Gemini analysis extracts events correctly
- [ ] Result screen shows extracted events
- [ ] Filter and sort functions work
- [ ] Google Sign-In OAuth flow completes
- [ ] Guest mode authentication works
- [ ] Calendar list displayed from user's account
- [ ] Events sync to selected calendar
- [ ] Reminders configured correctly
- [ ] Color coding applied (high=red, medium=yellow, low=green)

### Running Tests
```bash
# Run existing widget tests
flutter test

# Generate coverage report
flutter test --coverage

# Analyze code quality
flutter analyze
```

---

## 📈 Development Status

### ✅ Completed (Production Ready)
- [x] Complete UI/UX implementation (14 screens)
- [x] Gemini AI integration with structured extraction
- [x] Firebase Storage and Authentication (Email, Google, Anonymous)
- [x] Google Calendar API with OAuth2
- [x] File picker with validation
- [x] Event filtering and sorting
- [x] Multi-reminder system
- [x] Priority-based color coding
- [x] Guest mode (anonymous authentication)
- [x] Profile management
- [x] Batch event deletion
- [x] Environment configuration
- [x] Error handling and retry logic
- [x] Release APK build (50.1MB)
- [x] Mock data service for testing
- [x] Phase 2/3 UI mockups (study allocator, task breakdown, resource finder)

### 🎨 UI Complete (Mock Functionality)
- [x] Study session allocator UI
- [x] Task breakdown interface UI
- [x] Resource finder UI
- [ ] Connect to live AI/API backends

### 🔄 Future Development
- [ ] Group sync with course codes
- [ ] Live study session generation
- [ ] AI-powered task breakdown
- [ ] Real resource search APIs
- [ ] Smart notifications
- [ ] Analytics dashboard
- [ ] Comprehensive test suite
- [ ] Camera capture for syllabi

### ⚠️ Known Issues (Non-Critical)
- Debug print statements throughout codebase (normal for development)
- Minimal test coverage (1 basic test)
- Timezone hardcoded to 'America/New_York' (marked as TODO)
- Android cmdline-tools missing (only needed for CI/CD)
- Production signing keys not configured (Play Store requirement)

### 🚀 Roadmap
- [ ] **Q1 2026**: Beta testing with university students
- [ ] **Q2 2026**: Complete Phase 2 AI features (study allocator, task breakdown)
- [ ] **Q3 2026**: Group sync and course code sharing
- [ ] **Q4 2026**: Analytics dashboard and progress tracking

---

## 🤝 Contributing

This project is currently in **production-ready phase** for core features. Contributions are welcome!

### How to Contribute
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter format` before committing
- Run `flutter analyze` to check for issues
- Add comments for complex logic
- Keep debug prints for development (will be removed for production)

---

## 📄 License

This project is part of a hackathon submission. License to be determined.

---

## 👥 Team

**Track**: Quality Education (SDG 4)  
**Repository**: [github.com/HazeeqHaikal/KitaHack-App](https://github.com/HazeeqHaikal/KitaHack-App)  
**Build**: v1.0.0 (50.1MB Release APK)

---

## 🙏 Acknowledgments

- **Google Gemini AI** for powerful multimodal document understanding
- **Firebase** for reliable cloud infrastructure
- **Flutter Team** for excellent cross-platform framework
- **HazeeqHaikal** for project development and implementation

---

## 📞 Support

For setup issues or questions:
1. Check [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed configuration steps
2. Review troubleshooting section above
3. Ensure .env file is created from .env.example with your API keys
4. Open an issue on GitHub with:
   - Error message
   - Flutter doctor output
   - Steps to reproduce

---

<div align="center">
  <h3>📅 Due - Because deadlines shouldn't be a surprise ✨</h3>
  <p><strong>Built with ❤️ using Flutter & Google Gemini AI</strong></p>
  <p>
    <a href="SETUP_GUIDE.md">Setup Guide</a> •
    <a href="https://github.com/HazeeqHaikal/KitaHack-App">GitHub Repository</a> •
    <a href="#-installation--setup">Quick Start</a>
  </p>
</div>
