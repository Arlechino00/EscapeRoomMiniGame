# Escape Room (Godot 4 GDExtension)

A first-person escape room prototype built with Godot 4 and C++ (GDExtension). This project features a custom inventory system, save management, and real-time Firebase analytics.

## 🚀 Features
- **C++ Core:** High-performance systems for Inventory, Saving, and Analytics handled via GDExtension.
- **Firebase Analytics:** Tracks puzzle progress, mistakes, and solve times in Firestore.
- **Puzzle Systems:** Includes Pipe, Cable, and Switch (Levers) puzzles with randomized questions.
- **Persistence:** Items and puzzle states persist across scene transitions and saves.

## 🛠 Tech Stack
- **Engine:** [Godot 4.x](https://godotengine.org/)
- **Language:** C++17 (GDExtension), GDScript
- **Database:** Firebase Firestore
- **Build System:** CMake / CLion

## ⚙️ Setup

### 1. Firebase Configuration
1. Create a Firebase project and enable **Firestore Database**.
2. Create a `.env` file in the `project/` directory based on `.env.example`:
   ```env
   FIREBASE_API_KEY=your_api_key
   FIREBASE_PROJECT_ID=your_project_id
   ```
3. For local data export, download your Service Account Key from Firebase Console as `firebase_credentials.json` and place it in the root directory.

### 2. Building the Project (CLion)
1. Open the project in CLion.
2. Ensure the `godot-cpp` submodule is initialized.
3. Build the `EscapeRoomExt` target. The DLL will automatically be copied to `project/bin/windows/`.
4. Open the `project/` folder in Godot 4.

## 📊 Analytics & Reporting
The project includes a Python tool to export Firestore data to CSV for visualization (e.g., in Looker Studio).
1. Install dependencies: `pip install firebase-admin pandas`
2. Run the export: `python export_analytics.py`
3. Data will be saved to `analytics_report.csv`.

## 🔒 Security
- **Do not commit** `.env` or `firebase_credentials.json`. They are ignored by `.gitignore`.
- Build artifacts in `out/` and `cmake-build-*/` are also ignored.
