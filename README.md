# Due - Your Academic Timeline, Automated

<div align="center">
  <h3>An intelligent academic scheduling assistant powered by Google Gemini</h3>
  <p><strong>Track:</strong> Quality Education (SDG 4)</p>
</div>

---

## 📖 Overview

**Due** is a Flutter-based mobile application designed to help university students manage their academic deadlines effectively. By leveraging Google Gemini AI, the app automatically extracts assignments, exam dates, and crucial deadlines from course syllabus PDFs and synchronizes them directly to Google Calendar.

### The Problem

University students face a "deadline fragmentation" crisis:
- ⚠️ **Manual Entry Error**: Transferring dates from PDFs to calendars is tedious and error-prone
- 📅 **Missed Deadlines**: Important dates get buried in text-heavy documents
- 😰 **Academic Stress**: The constant anxiety of "forgetting something" contributes to burnout

### Our Solution

**Due** acts as a bridge between static documents and dynamic scheduling:
1. **Upload**: Student uploads a course outline (PDF/Image)
2. **Analyze**: Google Gemini 1.5 Pro parses the document and extracts key dates
3. **Sync**: User reviews extracted events and syncs to Google Calendar

---

## 🎯 SDG Alignment: Goal 4 (Quality Education)

Due directly supports **SDG 4: Quality Education** (Target 4.4: Skills for employment and effective learning environments).

By automating academic organization, we:
- Remove the barrier of poor time management
- Allow students to focus mental energy on quality learning
- Foster a more supportive and efficient educational environment

---

## 🏗️ Technical Architecture

### Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **AI Engine** | Google Gemini 1.5 Pro | PDF/Image parsing and date extraction |
| **Calendar Integration** | Google Calendar API | Event synchronization |
| **Frontend** | Flutter | Cross-platform mobile UI |
| **Backend & Auth** | Firebase | Authentication & file storage |

### Architecture Flow

```
[User App (Flutter)] 
    ↓
[Upload PDF] 
    ↓
[Firebase Storage] 
    ↓
[Gemini API Analysis] 
    ↓
[Structured JSON Response] 
    ↓
[Google Calendar API] 
    ↓
[User Calendar Updated ✓]
```

---

## 🚀 Key Features

### Phase 1 - UI & Navigation (✅ Completed)
- ✅ PDF/Image upload interface
- ✅ Complete screen navigation system
- ✅ Home dashboard with statistics
- ✅ Course list screen
- ✅ Result/event review screen
- ✅ Settings screen
- ✅ Calendar sync interface
- ✅ Mock data service (4 complete courses with 33+ events)
- ✅ Event filtering and sorting
- ✅ Priority-based color coding
- 🔄 Gemini AI integration (Next Phase)
- 🔄 Google Calendar API (Next Phase)

### Phase 2 - Scalability
- 📤 **Group Sync**: Class representative uploads once, generates course code
- 👥 Students join using course code (no re-upload needed)

### Phase 3 - Advanced AI
- 🧠 **Study Plan Generation**: Auto-schedule study blocks before exams
- ⚖️ **Balanced Revision Timetable**: Based on topic complexity and weightage

---

## ✨ Completed Features

### Navigation & UI
- **Onboarding Screen**: Welcome flow for new users
- **Home Dashboard**: 
  - 4 stat cards (courses, events, weekly deadlines, priorities)
  - Upcoming deadlines list with urgency indicators
  - Course overview cards with quick stats
  - Navigation to all app sections
- **Course Management**:
  - View all courses with detailed information
  - Navigate to specific course events
  - Display instructor, semester, and statistics
- **Event Management**:
  - Filter by type (Assignment, Exam, Quiz, Project, etc.)
  - Sort by date, priority, or type
  - Select/deselect events for calendar sync
  - Color-coded priority and urgency system
- **Settings Screen**:
  - Account management section
  - Calendar preferences
  - Theme and language options
  - Data management
  - Sign out functionality

### Mock Data System
- **4 Complete University Courses**:
  - CS101: Introduction to Computer Science (7 events)
  - CS201: Data Structures & Algorithms (8 events)
  - SE301: Software Engineering Principles (9 events)
  - DB202: Database Management Systems (9 events)
- **33+ Realistic Academic Events** with:
  - Detailed descriptions and requirements
  - Proper weightage percentages (5%-40%)
  - Specific locations and submission methods
  - Varied due dates across Spring 2026 semester

### Design System
- **Glassmorphism UI**: Modern frosted glass aesthetic
- **Dark Theme**: Optimized for reduced eye strain
- **Color-Coded Priorities**:
  - 🔴 High Priority (≥40% weightage)
  - 🟡 Medium Priority (20-39% weightage)
  - 🟢 Low Priority (<20% weightage)
- **Urgency Indicators**:
  - 🔴 Critical (due in ≤3 days)
  - 🟡 Warning (due in 4-7 days)
  - 🟢 Normal (due in >7 days)

---

## 📦 Installation & Setup

### Prerequisites
- Flutter SDK (^3.10.7)
- Dart SDK
- Android Studio / Xcode (for emulators)
- Firebase account (for backend services)
- Google Cloud account (for Gemini API access)

### Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd due
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

---

## 📱 Current Project Structure

```
due/
├── lib/
│   ├── main.dart                      # App entry point with routing
│   ├── screens/
│   │   ├── onboarding_screen.dart     # Welcome/intro screen
│   │   ├── home_screen.dart           # Dashboard with stats
│   │   ├── upload_screen.dart         # PDF/Image upload
│   │   ├── result_screen.dart         # Event review & selection
│   │   ├── calendar_sync_screen.dart  # Calendar sync settings
│   │   ├── course_list_screen.dart    # All courses view
│   │   └── settings_screen.dart       # App settings
│   ├── models/
│   │   ├── academic_event.dart        # Event data model
│   │   └── course_info.dart           # Course data model
│   ├── services/
│   │   └── mock_data_service.dart     # Simulated data for UI testing
│   ├── utils/
│   │   ├── constants.dart             # App-wide constants
│   │   └── date_formatter.dart        # Date utility functions
│   └── widgets/
│       ├── custom_buttons.dart        # Reusable button components
│       ├── event_card.dart            # Event display card
│       ├── glass_container.dart       # Glassmorphism container
│       ├── empty_state.dart           # Empty state component
│       └── info_banner.dart           # Info banner component
├── android/                           # Android-specific files
├── test/                              # Unit tests
└── pubspec.yaml                       # Dependencies
```

---

## 🔧 Configuration (To Be Completed)

### Google Services Setup
1. **Gemini API**
   - Create project in Google Cloud Console
   - Enable Vertex AI API / Gemini API
   - Generate API key

2. **Google Calendar API**
   - Enable Google Calendar API in Cloud Console
   - Configure OAuth 2.0 credentials
   - Add authorized redirect URIs

3. **Firebase**
   - Create Firebase project
   - Add Android/iOS apps
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Enable Firebase Authentication and Storage

---

## 🎨 Key Innovations

### 1. No-Template Extraction
Unlike regex-based parsers, Due uses **semantic understanding** via Gemini. It works on:
- Tables
- Bullet lists
- Paragraph-based descriptions

### 2. Weightage Awareness
The AI extracts importance context:
- "Final Exam (40%)" vs "Quiz (5%)"
- Enables future priority-based study planning

### 3. Flexible Date Parsing
Handles various formats:
- "5th Jan", "01/05", "Week 3"
- Normalizes to ISO 8601 for calendar sync

---

## 📊 Success Metrics

| Metric | Target |
|--------|--------|
| **Extraction Accuracy** | >90% for standard syllabi |
| **Time Saved** | <5 minutes (vs ~2 hours manual) |
| **User Retention** | Return rate at next semester |

---

## 🤝 Contributing

This project is currently in **basic setup phase**. Contributions will be welcomed once the core functionality is established.

---

## 📄 License

TBD

---

## 👥 Team

**Track**: Quality Education (SDG 4)  
**Event**: [Insert Hackathon/Event Name]

---

## 📞 Support

For questions or issues, please contact [Insert Contact Information]

---

<div align="center">
  <p><strong>Due</strong> - Because deadlines shouldn't be a surprise 📅✨</p>
</div>
