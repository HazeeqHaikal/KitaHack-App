# Collaborator Guide - Due Project

Welcome! This guide will help you clone, set up, and contribute to the Due project.

---

## 📋 Prerequisites

Before you start, make sure you have:
- [ ] Git installed ([Download Git](https://git-scm.com/downloads))
- [ ] Flutter SDK 3.38.6+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- [ ] A GitHub account
- [ ] A code editor (VS Code recommended)
- [ ] Android Studio or Xcode (for mobile testing)

---

## 🚀 Getting Started

### Step 1: Clone the Repository

```bash
# Navigate to where you want to store the project
cd C:\your\preferred\directory

# Clone the repository
git clone https://github.com/HazeeqHaikal/KitaHack-App.git

# Navigate into the project folder
cd KitaHack-App
```

### Step 2: Verify Flutter Installation

```bash
# Check if Flutter is properly installed
flutter doctor

# Make sure you see green checkmarks for:
# ✓ Flutter
# ✓ Android toolchain (for Android development)
# ✓ VS Code or Android Studio
```

### Step 3: Install Dependencies

```bash
# Install all required packages
flutter pub get

# You should see: "Got dependencies!"
```

### Step 4: Set Up API Keys

The app requires API keys to function. Follow these steps:

1. **Copy the environment template:**
   ```bash
   copy .env.example .env
   ```

2. **Get your API keys:**
   - **Gemini API**: Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - **Google Calendar API**: Visit [Google Cloud Console](https://console.cloud.google.com/)
   - **Firebase** (optional): Visit [Firebase Console](https://console.firebase.google.com/)

3. **Edit the `.env` file:**
   ```bash
   notepad .env
   ```
   
   Add your keys:
   ```
   GEMINI_API_KEY=your_gemini_api_key_here
   GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
   GOOGLE_CLIENT_SECRET=your_client_secret_here
   ```

4. **For detailed setup instructions**, see [SETUP_GUIDE.md](SETUP_GUIDE.md)

### Step 5: Run the App

```bash
# For Windows Desktop
flutter run -d windows

# For Android Emulator (start emulator first)
flutter run

# For connected Android device
flutter run -d <device-id>
```

---

## 🔄 Git Workflow for Collaboration

### Understanding Branches

- **`main`** - Production-ready code (protected)
- **Feature branches** - Your work in progress

### Daily Workflow

#### 1. Always Start with Latest Code

```bash
# Make sure you're on the main branch
git checkout main

# Pull the latest changes
git pull origin main
```

#### 2. Create a Feature Branch

```bash
# Create a new branch for your feature
git checkout -b feature/your-feature-name

# Examples:
# git checkout -b feature/add-dark-theme
# git checkout -b fix/calendar-sync-bug
# git checkout -b docs/update-readme
```

**Branch naming conventions:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Adding tests

#### 3. Make Your Changes

Edit files, add features, fix bugs, etc.

#### 4. Check What Changed

```bash
# See which files you modified
git status

# See detailed changes
git diff
```

#### 5. Stage Your Changes

```bash
# Stage specific files
git add path/to/file.dart

# Or stage all changes
git add .

# Check staged files
git status
```

#### 6. Commit Your Changes

```bash
# Commit with a descriptive message
git commit -m "Add calendar event color coding feature"
```

**Good commit message examples:**
- ✅ `"Fix Google Sign-In OAuth flow timeout"`
- ✅ `"Add priority-based event filtering"`
- ✅ `"Update README with installation steps"`
- ❌ `"Fixed stuff"` (too vague)
- ❌ `"Changes"` (not descriptive)

#### 7. Push Your Branch

```bash
# Push your feature branch to GitHub
git push origin feature/your-feature-name

# If it's your first push on this branch, use:
git push -u origin feature/your-feature-name
```

#### 8. Create a Pull Request

1. Go to [GitHub repository](https://github.com/HazeeqHaikal/KitaHack-App)
2. You'll see a yellow banner: "Compare & pull request"
3. Click it and fill in:
   - **Title**: Brief description (e.g., "Add calendar event color coding")
   - **Description**: What you changed and why
   - **Screenshots**: If UI changed
4. Click "Create pull request"
5. Wait for code review and approval

---

## 🔧 Common Git Commands

### Checking Status

```bash
# See current branch and modified files
git status

# See commit history
git log --oneline

# See all branches
git branch -a
```

### Switching Branches

```bash
# Switch to an existing branch
git checkout branch-name

# Create and switch to a new branch
git checkout -b new-branch-name
```

### Updating Your Branch

```bash
# If main branch has new changes while you're working:
git checkout main
git pull origin main
git checkout feature/your-feature-name
git merge main

# Resolve any conflicts if they occur
```

### Undoing Changes

```bash
# Discard changes in a specific file (before commit)
git checkout -- path/to/file.dart

# Unstage a file (keep changes)
git reset HEAD path/to/file.dart

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes) - BE CAREFUL!
git reset --hard HEAD~1
```

### Stashing Changes

```bash
# Save work temporarily without committing
git stash

# View stashed changes
git stash list

# Apply stashed changes
git stash apply

# Apply and remove from stash
git stash pop
```

---

## 📝 Code Style Guidelines

### Flutter/Dart Best Practices

1. **Format your code before committing:**
   ```bash
   flutter format .
   ```

2. **Check for issues:**
   ```bash
   flutter analyze
   ```

3. **Follow naming conventions:**
   - Classes: `PascalCase` (e.g., `CalendarService`)
   - Variables/functions: `camelCase` (e.g., `getUserEvents`)
   - Constants: `lowerCamelCase` or `SCREAMING_SNAKE_CASE`
   - Files: `snake_case.dart` (e.g., `calendar_service.dart`)

4. **Add comments for complex logic:**
   ```dart
   // Good: Explains WHY, not just WHAT
   // Filter events within 7 days to show urgent deadlines only
   final urgentEvents = events.where((e) => 
     e.date.difference(DateTime.now()).inDays <= 7
   ).toList();
   ```

5. **Keep functions small and focused:**
   - One function = one responsibility
   - Prefer 20-30 lines max per function

### Project-Specific Guidelines

- **Debug prints are OK** (we'll remove them before production)
- **Use existing widgets** in `lib/widgets/` folder
- **Follow the established folder structure**:
  ```
  lib/
  ├── screens/      # UI screens
  ├── services/     # API and business logic
  ├── models/       # Data models
  ├── widgets/      # Reusable UI components
  └── utils/        # Helper functions
  ```

---

## 🐛 Troubleshooting

### "Permission denied" when pushing

```bash
# Make sure you're authenticated
# Option 1: Use GitHub Desktop
# Option 2: Set up SSH keys (https://docs.github.com/en/authentication)
# Option 3: Use GitHub CLI (gh auth login)
```

### Merge Conflicts

When you see conflict markers in your files:

```dart
<<<<<<< HEAD
// Your changes
=======
// Someone else's changes
>>>>>>> main
```

**To resolve:**
1. Edit the file manually
2. Choose which code to keep (or combine both)
3. Remove the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
4. Save the file
5. Stage and commit:
   ```bash
   git add path/to/conflicted/file.dart
   git commit -m "Resolve merge conflict in calendar service"
   ```

### Branch is Behind Main

```bash
# Update your branch with latest main
git checkout main
git pull origin main
git checkout your-branch
git merge main
```

### Accidentally Committed to Main

```bash
# Create a new branch from current state
git checkout -b feature/my-changes

# Reset main to remote state
git checkout main
git reset --hard origin/main

# Continue working on your feature branch
git checkout feature/my-changes
```

---

## 📞 Getting Help

### Before Asking for Help

1. **Check existing documentation:**
   - [README.md](README.md) - Project overview
   - [SETUP_GUIDE.md](SETUP_GUIDE.md) - Detailed setup
   - This file - Collaboration workflow

2. **Search for error messages:**
   - Google the error
   - Check [Stack Overflow](https://stackoverflow.com/)
   - Check [Flutter documentation](https://flutter.dev/docs)

3. **Use Flutter tools:**
   ```bash
   flutter doctor -v    # Verbose health check
   flutter clean        # Clear build cache
   flutter pub get      # Reinstall dependencies
   ```

### When You Need Help

**Open a GitHub Issue:**
1. Go to: https://github.com/HazeeqHaikal/KitaHack-App/issues
2. Click "New Issue"
3. Include:
   - What you were trying to do
   - Exact error message
   - Steps to reproduce
   - Output of `flutter doctor -v`
   - Your branch name

**Or contact the team directly:**
- Check repository for contact information
- Use team communication channels

---

## ✅ Pre-Commit Checklist

Before pushing your code, verify:

- [ ] Code runs without errors: `flutter run`
- [ ] Code is formatted: `flutter format .`
- [ ] No analysis issues: `flutter analyze`
- [ ] Meaningful commit messages
- [ ] No API keys or secrets in code
- [ ] Tested on at least one device/emulator
- [ ] Updated documentation if needed

---

## 🎯 Quick Reference

### First Time Setup
```bash
git clone https://github.com/HazeeqHaikal/KitaHack-App.git
cd KitaHack-App
flutter pub get
copy .env.example .env
# Add your API keys to .env
flutter run
```

### Daily Workflow
```bash
git checkout main
git pull origin main
git checkout -b feature/my-new-feature
# Make changes
git add .
git commit -m "Descriptive message"
git push origin feature/my-new-feature
# Create pull request on GitHub
```

### Before Committing
```bash
flutter format .
flutter analyze
git status
git add .
git commit -m "Your message"
```

---

## 🚀 Next Steps

1. **Clone the repository** and get it running locally
2. **Explore the codebase** - start with `lib/main.dart`
3. **Pick a task** - check GitHub Issues or ask the team
4. **Make your first contribution** - even fixing a typo counts!
5. **Ask questions** - no question is too small

---

<div align="center">
  <h3>Welcome to the team! 🎉</h3>
  <p>Happy coding! If you run into any issues, don't hesitate to ask.</p>
  <p>
    <a href="README.md">Main README</a> •
    <a href="SETUP_GUIDE.md">Setup Guide</a> •
    <a href="https://github.com/HazeeqHaikal/KitaHack-App">GitHub Repo</a>
  </p>
</div>
