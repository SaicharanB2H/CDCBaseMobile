# CDC MailBase Portal

A centralized mobile application built with Flutter that helps students track placement drives, stay updated on company eligibility, and manage their interview schedules efficiently.

## Features

- 📅 **Unified Calendar & Timeline**: Keep track of upcoming selection processes, tests, and interviews in an easy-to-read calendar or timeline feed.
- 🏢 **Company Profiles**: Detailed information about visiting companies, including job descriptions, CTC, and selection process stages.
- 🔄 **Real-Time Synchronization**: Pulls the latest placement updates, emails, and shortlists directly from the backend via Supabase.
- 🕵️‍♂️ **Anonymous Login**: Allows users to explore the app as a guest without needing to link an email or create an account.
- 🚀 **In-App Updates**: Automatically checks for new releases on startup and prompts the user to download the latest version.

## Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/) & Dart
- **Backend / Database**: [Supabase](https://supabase.com/)
- **Icons**: Lucide Icons
- **State Management & Routing**: Stateful Widgets / Native Flutter Routing

## Getting Started

Follow these instructions to get a copy of the project up and running on your local machine.

### Prerequisites

- Flutter SDK (latest version)
- Android Studio / VS Code
- A Supabase account and project

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/CDC.git
   cd CDC/CDCBaseMobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment**
   Ensure your Supabase URL and Anon Key are correctly set up in the app (typically inside an environment file or directly in the initialization logic).

4. **Run the app**
   ```bash
   flutter run
   ```

## Build for Release

To generate an APK for Android, run:

```bash
flutter build apk --release
```

The compiled APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.