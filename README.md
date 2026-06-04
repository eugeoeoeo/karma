# Karma — AI-Powered Personal Growth, Reflection & Virtue Journal

**Karma** is a cross-platform mobile application designed to help users reflect on their character development, track intentions (wishes), log blessings, and explore their life story. Powered by a local-first AI system, it provides a safe space for personal improvement and mentorship without claiming supernatural certainty.

---

## 🚀 Key Features

*   **🎙️ Voice Logging:** Log your actions through real-time speech-to-text with animated recording previews and automated semantic analysis.
*   **🌟 Virtue Development Map:** Track progress across 12 default virtues (Discipline, Kindness, Wisdom, etc.) with a dynamic radar chart display.
*   **🎯 Intentions Tracker:** Set personal development intentions, filter by *Active* or *Completed*, and visualize completion progress.
*   **🙏 Blessing Journal:** Record unexpected or expected blessings, evaluate significance levels, and resolve gratitude obligations.
*   **🧠 Deep Reflections:** Generate Daily, Weekly, Monthly, or Yearly summaries using AI analysis (with local keyword fallbacks if offline).
*   **📖 Poetic Life Story:** Synthesize your logged activities and virtues into beautiful, unfolding narrative chapters.
*   **🦉 AI Mentor:** Chat with a context-aware guide who references your virtue strengths and evolution.
*   **🌀 Soul Avatar Evolution:** Watch your profile avatar evolve through 5 distinct spiritual growth stages (from Seeker to Enlightened) based on your virtue levels.

---

## 🛠️ Tech Stack & Architecture

### Backend (`/backend`)
*   **Runtime:** Node.js + TypeScript
*   **Framework:** Express.js
*   **ORM:** Prisma
*   **Database:** Supabase (PostgreSQL) with connection pooling
*   **AI Integration:** Google Gemini 2.0 Flash Lite (with optimized output limits and token fallback guards)

### Mobile Client (`/mobile`)
*   **Framework:** Flutter (Android & iOS support)
*   **State Management:** Riverpod
*   **Navigation:** GoRouter
*   **Local Caching:** Hive
*   **API Client:** Dio (with JWT rotation interceptors)

---

## 📦 Getting Started

### 1. Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (Pre-installed at `C:\flutter`)
*   [Node.js](https://nodejs.org/) (LTS version)
*   [Android Studio](https://developer.android.com/studio) (With Android SDK and command-line tools installed)

---

### 2. Backend Installation & Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Set up your `.env` variables:
   Create a `.env` file inside `/backend` with the following variables:
   ```properties
   PORT=3000
   NODE_ENV=development
   DATABASE_URL="postgresql://postgres.epyjtxcaphicrtykrgsp:Angelo--022406101306@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres"
   GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
   JWT_SECRET="YOUR_JWT_SECRET"
   JWT_REFRESH_SECRET="YOUR_JWT_REFRESH_SECRET"
   ```
4. Synchronize the database schema with Supabase:
   ```bash
   npx prisma db push --accept-data-loss
   ```
5. Seed the default virtues:
   ```bash
   npm run db:seed
   ```
6. Start the local server:
   ```bash
   npm run dev
   ```

---

### 3. Mobile Installation & Run
1. Navigate to the mobile directory:
   ```bash
   cd mobile
   ```
2. Download packages:
   ```bash
   flutter pub get
   ```
3. Configure your API endpoint in `/mobile/.env`:
   ```properties
   API_URL=http://10.0.2.2:3000/api
   ```
   *(Use `10.0.2.2` if running on the Android Emulator, your computer's local IP if testing on a physical device, or your live hosted API URL).*
4. Run the app:
   - Make sure your simulator/device is open.
   - Run the command:
     ```bash
     flutter run
     ```
   - Alternatively, open `/mobile` in **Android Studio** and click the green **Play** button!

---

## 🔒 Production Build & Sign (APK-Ready)

To generate a signed, production-ready release build for distribution or Google Play Store:
1. Ensure your `mobile/android/key.properties` configuration lists the correct keystore path and passwords.
2. Build the files:
   - **For testing / manual install (.apk):**
     ```bash
     flutter build apk --release
     ```
   - **For Google Play Store upload (.aab):**
     ```bash
     flutter build appbundle --release
     ```
3. Locate the finished artifacts inside `build/app/outputs/`.
