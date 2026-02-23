# Predictive Urban Issue Management System (Urban AI)

A full-stack, AI-powered civic issue management system designed to transform urban governance from reactive to proactive. Citizens can report infrastructure problems—such as road damage, waste overflow, and streetlight failures—which are then automatically analyzed by machine learning models to ensure efficient routing, priority scoring, and resource allocation.

## 🚀 Key Features

- **AI-Powered Diagnostics**: Automatic classification using MobileNetV2 (images) and TF-IDF+SVM (text).
- **Smart Duplicate Detection**: Prevents redundant data by merging similar reports within geographic clusters.
- **Dynamic Priority Scoring**: Automatically ranks issues based on severity, population impact, and risk.
- **Predictive Analytics**: Hotspot forecasting using Prophet to anticipate where issues will arise.
- **Optimized Resource Allocation**: Mathematical modeling (PuLP) to assign crews to the most critical tasks.
- **Premium Dashboards**: Detailed views for both citizens and administrators with real-time tracking and AI evidence.
- **Demo Mode**: Manual coordinate entry for testing geographic scenarios without physical movement.

## 🛠️ Technology Stack

| Layer | Technologies |
|-------|--------------|
| **Frontend** | Flutter (Mobile & Web), Google Fonts (Outfit), Dio |
| **Backend** | FastAPI (Python), SQLAlchemy ORM, PostgreSQL (Supabase) |
| **Machine Learning** | TensorFlow/Keras, Scikit-learn, Prophet, PuLP |
| **Utilities** | Perceptual Hashing (ImageHash), Geopy |

## 📁 Project Structure

```
urban-ai-system/
├── backend_fastapi/          # FastAPI backend server
│   ├── app/
│   │   ├── main.py           # API entry point & static file serving
│   │   ├── models/           # Database schemas (User, Issue, Crew, etc.)
│   │   ├── routes/           # API endpoints
│   │   └── services/         # ML Engines (Classification, Optimization, etc.)
│   └── uploads/              # Storage for citizen-reported evidence photos
├── frontend_flutter/         # Flutter mobile & web application
│   ├── lib/                  # UI screens, models, and service layers
├── ml_training/              # ML model training scripts and saved assets
└── PROJECT_TRACKING.md       # Current development status and roadmap
```

## ⚙️ Setup & Installation

### 1. Backend Setup (FastAPI)

1. **Navigate to the backend directory**:
   ```bash
   cd backend_fastapi
   ```
2. **Create and activate a virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   ```
3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```
4. **Configure Environment**:
   Create a `.env` file in `backend_fastapi/` (use `.env.example` as a template).
   ```bash
   DATABASE_URL=postgresql://user:pass@host:port/dbname
   SECRET_KEY=your_secret_key_here
   ```
5. **Run the server**:
   ```bash
   uvicorn app.main:app --reload
   ```
   - API Docs: `http://localhost:8000/docs`

### 2. Frontend Setup (Flutter)

1. **Navigate to the frontend directory**:
   ```bash
   cd frontend_flutter
   ```
2. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```
3. **Configure API Endpoint**:
   Ensure `lib/services/api_service.dart` points to your backend:
   ```dart
   static const String baseUrl = 'http://localhost:8000';
   ```
4. **Run the application**:
   ```bash
   flutter run
   ```

## 👥 Contributors

- **SELVAM MARILYN** (2201112040)
- **DHINESH S** (2201212002)
- **MUTHUKUMARAN A S** (2201112030)

**Supervisor**: Dr. P. Maragathavalli, Department of Information Technology, PTU.

## 📜 License & Academic Context

Developed as part of academic coursework at **Puducherry Technological University**. All rights reserved.
