# Zytexa HRM Mobile App 📱

A modern, feature-rich Human Resource Management mobile application built with Flutter. Seamlessly manage attendance, view timesheets, and stay motivated with daily inspirational quotes.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Dart](https://img.shields.io/badge/Dart-3.x-green)
![Android](https://img.shields.io/badge/Android-API%2021%2B-green)
![iOS](https://img.shields.io/badge/iOS-12.0%2B-lightgrey)
![License](https://img.shields.io/badge/License-MIT-yellow)

## ✨ Features Overview

### 🔐 Secure Authentication
- JWT-based secure login system
- Persistent authentication with secure storage
- Role-based access control
- Automatic token refresh and session management

### 🏠 Enhanced Home Dashboard
- **Real-time Work Timer** with circular progress indicator
- **Enhanced Profile Display** with avatar support and fallbacks
- **Daily Inspirational Quotes** with automatic midnight refresh
- **Activity Summary** showing totals after clock-out
- **Quick Action Buttons** for seamless clock in/out and breaks

### ⏰ Smart Attendance Management
- **One-tap Clock In/Out** functionality
- **Intelligent Break Tracking** with duration calculation  
- **Real-time Session Monitoring** with live timer updates
- **10-hour Daily Limit** with visual feedback and warnings
- **IST Timezone Support** with proper local time display

### 📊 Professional Timesheet
- **14-day Attendance History** with detailed timeline view
- **Precise Time Display** showing clock in/out in IST format
- **Work & Break Duration** calculations with visual indicators
- **Status Indicators** (ON TIME, PARTIAL, LATE) with color coding
- **Auto-refresh** on new attendance entries

### 👤 Complete Profile Management
- **Employee Profile** with personal information display
- **Avatar Management** with image upload support
- **Company Information** integration
- **Secure Logout** with session cleanup

### 🎯 Additional Premium Features
- **Daily Quote System** with automatic refresh and variety
- **Company Details** with contact information and culture
- **Menu Navigation** with organized feature access
- **Responsive Material Design** across all screen sizes
- **Smooth Animations** and professional transitions

## 📱 Screenshots

| Home Screen | Timesheet | Profile | Login |
|-------------|-----------|---------|-------|
| ![Home](screenshots/home.png) | ![Timesheet](screenshots/timesheet.png) | ![Profile](screenshots/profile.png) | ![Login](screenshots/login.png) |

## 🛠 Tech Stack

### Core Technologies
- **Flutter 3.x** - Cross-platform mobile framework
- **Dart 3.x** - Modern programming language
- **Material Design 3** - Google's latest design system

### Key Dependencies
- **http** - API communication and REST client
- **flutter_secure_storage** - Encrypted local storage for tokens
- **go_router** - Advanced navigation and routing
- **percent_indicator** - Beautiful progress displays
- **google_fonts** - Professional typography (Nunito)

### Architecture
- **Clean Architecture** with separation of concerns
- **Repository Pattern** for data management
- **State Management** with StatefulWidget and proper lifecycle
- **Service Layer** for API communication
- **Model Layer** for data structures

## 🚀 Quick Start

### Prerequisites
- **Flutter SDK** 3.10.0 or higher
- **Dart SDK** 3.0.0 or higher  
- **Android Studio** or **VS Code** with Flutter extensions
- **Android device/emulator** (API 21+) or **iOS device/simulator** (iOS 12.0+)

### Installation Guide

#### 1. Clone Repository

git clone https://github.com/AnuvabNayak/hrm_frontend.git
cd hrm_frontend


#### 2. Install Flutter Dependencies
Get all dependencies
flutter pub get

Verify Flutter installation
flutter doctor


#### 3. Configure API Endpoints
Update the base URL in your service files to match your backend:

**lib/services/auth_service.dart:**
class AuthService {
static const String baseUrl = "http://YOUR-SERVER-IP:8000"; // Update this

// For local development:
// Android Emulator: "http://10.0.2.2:8000"
// iOS Simulator: "http://localhost:8000"
// Physical Device: "http://YOUR-PC-IP:8000"
}


#### 4. Run the Application
List available devices:
flutter devices
Run on Android:
flutter run -d android


### Key Components

#### 🏠 Home Screen Features
- **Real-time Timer**: Updates every second during work sessions
- **Progress Indicator**: Visual representation of daily work progress  
- **Quote Display**: Daily motivational content with elegant typography
- **Activity Cards**: Work duration, break duration, and session status
- **Action Buttons**: Clock in/out, start/stop break functionality

#### 📊 Timesheet Functionality  
- **14-day History**: Comprehensive attendance records
- **Smart Filtering**: Shows only days with actual work sessions
- **Time Formatting**: Professional time display in 12-hour format
- **Status Calculation**: Automatic ON TIME/PARTIAL status determination
- **Refresh Logic**: Auto-updates when new entries are added

#### 👤 Profile Integration
- **Avatar Display**: Profile pictures with fallback to initials
- **Employee Data**: Name, email, phone, employee code display
- **Company Integration**: Seamless company information access
- **Settings Access**: Profile updates and preferences

Build APK:
flutter build apk --release
Install APK for testing:
flutter install

Clean build files:
flutter clean
flutter pub get
Reset Flutter cache:
flutter doctor





