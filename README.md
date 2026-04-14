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
└── flutter_app/
    └── lib/
        ├── main.dart          # App entry
        ├── models/            # Data models
        ├── services/          # API & auth
        ├── screens/
        │   ├── auth/          # Login, register
        │   ├── citizen/       # Citizen screens
        │   └── worker/        # Worker screens
        └── theme/             # Color palette
```

## 🎨 Color Palette

| Color       | Hex       | Usage           |
|-------------|-----------|-----------------|
| Primary     | `#77B6EA` | Main actions    |
| Background  | `#E8EEF2` | Page background |
| Cards       | `#C7D3DD` | Card borders    |
| Secondary   | `#D6C9C9` | Accents         |
| Text        | `#37393A` | Body text       |

## 🔗 API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/auth/login` | No | Firebase login |
| GET | `/auth/profile` | Yes | Get profile |
| POST | `/report` | Yes | Submit report |
| GET | `/reports` | Yes | List reports |
| POST | `/assign` | Admin | Assign worker |
| POST | `/attendance` | Worker | Log attendance |
| GET | `/worker/tasks` | Worker | Get tasks |
| GET | `/admin/dashboard` | Admin | Analytics |

## 📋 Requirements

- Python 3.9+
- Flutter 3.2+
- Firebase project with Auth enabled
- Supabase project
- Roboflow account (optional, for AI)

## 📄 License

MIT License
