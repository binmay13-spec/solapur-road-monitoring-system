# 🛣️ Smart Road Monitoring System

A full-stack Smart City Road Monitoring System for detecting, reporting, and resolving road infrastructure issues.

## 🏗️ Architecture

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Flutter App  │───▶│  Flask API   │───▶│   Supabase   │
│ (Citizen/     │    │  (Backend)   │    │  (Database)  │
│  Worker)      │    │              │    │              │
└──────────────┘    │  + Firebase  │    └──────────────┘
                    │  + Roboflow  │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │ Admin Web    │
                    │ Dashboard    │
                    └──────────────┘
```

## 🔑 Features

### Citizen App
- 📱 Report road issues (pothole, water logging, obstruction, etc.)
- 📸 Image capture via camera/gallery
- 📍 Automatic GPS location capture
- 🗺️ Live map with issue markers
- 📊 Report tracking with status timeline
- 🔔 Push notifications for status updates

### Worker App
- 📋 View and manage assigned tasks
- 🗺️ Google Maps navigation to issue locations
- ✅ Task completion with proof photo
- 🕐 Attendance system with face photo + GPS

### Admin Dashboard (Web)
- 📊 Analytics with charts (reports/hour, category distribution)
- 🗺️ Live map with heatmap layer
- 👷 Worker management and attendance logs
- 📝 Report assignment to workers
- 💬 Support ticket system

### AI Detection
- 🤖 Roboflow integration for road issue detection
- Detects: pothole, water_logging, road_obstruction, broken_streetlight, garbage

## 🚀 Quick Start

### 1. Backend Setup

```bash
cd backend

# Copy environment variables
cp .env.example .env

# Edit .env with your credentials:
# - SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
# - FIREBASE_SERVICE_ACCOUNT_PATH
# - ROBOFLOW_API_KEY

# Install dependencies
pip install -r requirements.txt

# Run the server
python app.py
```

### 2. Database Setup
1. Go to your Supabase dashboard → SQL Editor
2. Run the SQL from `database/schema.sql`
3. Create storage buckets: `report-images`, `completion-images`, `attendance-photos`

### 3. Flutter App Setup

```bash
cd flutter_app

# Install dependencies
flutter pub get

# Update backend URL in lib/app_config.dart

# Add Firebase config files:
# - android/app/google-services.json
# - ios/Runner/GoogleService-Info.plist

# Run the app
flutter run
```

### 4. Admin Dashboard
The admin dashboard is served at `http://localhost:5000/admin/`

## 📁 Project Structure

```
smart_road_monitor/
├── backend/                    # Flask API
│   ├── app.py                 # Entry point
│   ├── config.py              # Configuration
│   ├── services/              # Business logic
│   ├── routes/                # API endpoints
│   ├── middleware/            # Auth middleware
│   ├── utils/                 # Logger, retry
│   └── static/admin/         # Admin dashboard
├── database/
│   └── schema.sql            # Supabase migration
### 5. Google Sign-In (Android)
To enable Google Sign-In on Android, you must register your SHA-1 fingerprint in the Firebase Console:
1. Generate the SHA-1 fingerprint:
   ```bash
   cd flutter_app/android
   ./gradlew signingReport
   ```
2. Copy the `SHA1` from the `debug` or `release` variant.
3. Paste it in Firebase Console → Project Settings → Android App → SHA certificate fingerprints.
4. Download the updated `google-services.json` and place it in `flutter_app/android/app/`.

## ☁️ Deployment (Render)

When deploying the backend to Render:

1. **Environment Variables**:
   - `FLASK_ENV`: set to `production` (Crucial for security!).
   - `SECRET_KEY`: Set to a long, random string.
   - `FIREBASE_SERVICE_ACCOUNT_JSON`: Paste the entire content of your Firebase service account JSON here.
   - `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`: Your Supabase credentials.
   - `ROBOFLOW_API_KEY`: Your Roboflow key.

2. **FCM v1 API**: 
   The app uses the modern FCM v1 API. Ensure your Firebase Service Account has the "Firebase Messaging Admin" role.

## 📁 Project Structure

```
smart_road_monitor/
├── backend/                    # Flask API (Python)
│   ├── app.py                 # Entry point
│   ├── config.py              # Configuration & Environment loading
│   ├── services/              # Business logic (Supabase, FCM v1, AI)
│   ├── routes/                # API endpoints (Auth, Reports, Worker)
│   ├── middleware/            # Firebase Token Auth middleware
│   ├── utils/                 # Logger, retry logic
│   └── static/admin/         # Admin dashboard (Served locally)
├── database/
│   └── schema.sql            # Supabase tables, RLS & Triggers
└── flutter_app/                # Mobile App (Dart/Flutter)
    └── lib/
        ├── main.dart          # App entry & Provider setup
        ├── models/            # JSON Data models
        ├── services/          # API, Auth, & Storage
        ├── screens/           # UI Components
        └── theme/             # Color palette & styling
```

## 📋 Requirements

- Python 3.12+
- Flutter 3.24+
- Firebase project with Auth & Cloud Messaging enabled
- Supabase project with Storage buckets created
- Roboflow account (optional, for AI)

## 📄 License

MIT License
