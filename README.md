# SplitSmart

**Split Bills, The Smart Way**

SplitSmart is a mobile application that helps groups track shared expenses, manage debts, and settle payments — making bill splitting simple, transparent, and stress-free.

----------
## Install on iPhone 

Want to try the app without setting up a development environment?

**Download the IPA:** [Download SplitSmart](https://drive.google.com/file/d/1XIT52NNvodUHxhtPLtPxxqj5egIMU3Kv/view?usp=sharing)

**How to sideload on iOS (step-by-step tutorial):** [Watch the tutorial](https://youtu.be/hqJcPvHUn40?si=mrzGZWiPwItJ2eKw)

> Sideloading is required to install the app on iPhone since it is not available on the App Store. Follow the tutorial above for instructions.

----------
## Run from Source Code

### Prerequisites

Make sure you have the following installed:

-   [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.0 or higher)
-   [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
-   Android Emulator or a physical device
-   [Git](https://git-scm.com/)

### Step 1 — Clone the repository

```bash
git clone https://github.com/chrztyn/6ADET-SplitSmart-App.git
cd splitsmart
```

### Step 2 — Install dependencies

```bash
flutter pub get
```

### Step 3 — Set up environment variables

Create a `.env` file in the root of the project and add your Supabase credentials:

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Step 4 — Run the app

**On an emulator or connected device:**

```bash
flutter run
```

**To run on a specific device:**

```bash
flutter devices         
flutter run -d <device_id>
```

### Step 5 — Build APK (optional)

If you want to build your own APK:

```bash
flutter build apk --release
```

The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`

----------
## Tech Stack

-   Framework: Flutter (Dart)
-   Backend: Supabase
-   Authentication: Supabase Auth + Google OAuth
-   Database: PostgreSQL (via Supabase)
-   Storage: Supabase Storage
-   State Management: Provider

----------
## Team

-   Lapuz, Mary Micah — Frontend UI
-   Quiambao, Maxene — Frontend UI
-   Yunun, Christine Mae — Backend + Connection
-   Payawal, Kyle Eishley — Connection
-   Domingo, Jasmeen Clarisse — Documentation

----------

