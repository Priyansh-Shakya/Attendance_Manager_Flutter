# 📚 Attendance Manager

A powerful and intuitive personal attendance management application for Android, built with Flutter. Track your academic attendance across multiple sessions with flexible configuration, real-time statistics, and predictive planning tools.

---

## 🎯 Overview

**Attendance Manager** is a comprehensive attendance tracking solution designed for students and educators who need reliable, flexible attendance management. Unlike traditional attendance apps that struggle with unpredictable holidays and absences, this app **empowers users to dynamically compensate for missed days**, making attendance tracking accurate and stress-free.

### Key Highlights
- ✅ **Multiple Session Management** – Create and manage multiple academic sessions simultaneously
- 📅 **Flexible Schedule Configuration** – Set custom working days per week (1-7 days)
- 📊 **Real-Time Statistics** – Track attendance percentage with visual progress indicators
- 🎮 **Planning Mode** – Simulate future attendance and test different scenarios
- 🌟 **Smart Holiday Compensation** – Remove days for holidays/leaves and dynamically adjust your attendance
- 📱 **Dual Attendance Modes** – Day-based or Class-based tracking
- 🔔 **Smart Notifications** – Daily reminders and attendance warnings

---

## 💡 The Problem We Solve

Most attendance apps fail to handle **unpredictable holidays, personal leaves, and special events**. Users are forced to either:
- Lose attendance due to legitimate absences
- Manually calculate adjusted statistics
- Abandon the app entirely

**Attendance Manager solves this** by letting you:
1. **Mark holidays/leaves dynamically** – Remove specific days from your attendance calculation
2. **Instant compensation** – See updated attendance percentages immediately
3. **Plan ahead** – Test how future attendance impacts your overall percentage

---

## 📱 Features

### 1. **Session Management**
- Create multiple academic sessions with custom date ranges
- Set session name, duration, and working days per week
- Edit and delete sessions seamlessly
- Auto-save selected session

### 2. **Flexible Attendance Marking**
- **Calendar View** – Intuitive month/week calendar interface
- Mark attendance by day (Monday-Friday or custom days)
- Visual distinction between:
  - ✅ Present days (marked)
  - ❌ Absent days (unmarked)
  - 🔒 Future days (locked until reached)
  - ⚪ Weekends (not counted)

### 3. **Dual Attendance Modes**

#### Day-Based Mode
- Track attendance on a daily basis
- Simple checkbox for each day
- Perfect for lectures or daily classes

#### Class-Based Mode
- Define number of classes/lectures per day
- Mark individual class attendance
- Bulk select/deselect all classes for a day
- Detailed class-level reporting

### 4. **Statistics Dashboard**
- **Attendance Percentage** – Visual progress bar showing current attendance
- **Working Days Count** – Total planned working days (adjusted)
- **Present/Absent Days** – Breakdown of marked attendance
- **Target Tracking** – Visual indicators when below/above target
- **Real-Time Updates** – Statistics refresh instantly

### 5. **Smart Holiday/Leave Management**
The app's unique **Adjustment System**:
- Define number of holidays/leaves/absences
- Automatically removes days from total calculation
- Adjusts both present and absent counts proportionally
- Example:
  - Total working days: 100
  - Remove 5 days (holidays): 95 days effective
  - Attendance recalculated instantly

### 6. **Planning Mode (Test Screen)**
- Simulate future attendance scenarios
- **Set any future day as "present day"** to see what-if scenarios
- Temporarily adjust attendance marking
- **Reset changes** – All changes are temporary; original data untouched
- Perfect for:
  - Planning the rest of your semester
  - Understanding required attendance for target
  - Testing different scenarios

### 7. **Customizable Targets**
- Set target attendance percentage (e.g., 75%)
- Real-time alerts when below target
- Visual color coding:
  - 🟢 Green – Meeting target
  - 🔴 Red – Below target

### 8. **Notifications**
- Daily reminder notifications to mark attendance
- Attendance warning alerts when below target
- Customizable notification time
- Per-session notification settings

### 9. **Professional Dark Theme**
- Eye-friendly dark interface
- Modern card-based UI design
- Smooth animations and transitions
- Consistent navigation

---

## 🎮 How to Use

### Getting Started
1. **Create a Session**
   - Click the "+" button on home screen
   - Enter session name (e.g., "Sem-1 2025-26")
   - Select date range (by date or month)
   - Set working days (1-7 per week)
   - Define classes per day
   - Set target attendance percentage

2. **Mark Attendance**
   - Go to **Calendar** tab
   - Click days to mark present/absent
   - Checkmarks appear instantly
   - View weeks organized by month

3. **Check Statistics**
   - Go to **Stats** tab
   - See real-time attendance percentage
   - View working days count
   - Check present/absent breakdown

4. **Compensate for Holidays**
   - Go to **Settings** → Click adjustment icon
   - Enter number of days to remove
   - Statistics adjust automatically
   - Click "Restore Original" to undo

5. **Plan Ahead**
   - Go to **Test** tab (Planning Mode)
   - Click "Set Present Day" to pick a future date
   - Temporarily mark attendance as if it's that date
   - See how your percentage changes
   - Click "Reset Changes" to revert (original data safe)

6. **Switch Attendance Mode**
   - Calendar screen top-right icon toggles mode
   - 📅 Calendar icon = Day-based
   - 📊 Grid icon = Class-based (if configured)

---

## 🏗️ Tech Stack

- **Frontend:** Flutter (Dart)
- **Local Database:** Hive (NoSQL)
- **State Management:** Stateful Widgets
- **Notifications:** Awesome Notifications
- **Storage:** SharedPreferences (for settings)

---

## 📊 Data Structure

### Sessions
- Session name, duration (start/end dates)
- Active working days per week
- Target attendance percentage
- Classes per day (if class-based)
- Creation date

### Attendance Records
- Session ID, date, attendance status
- Classes present (for class-based mode)
- Automatically linked to sessions

### Settings
- Notifications enabled/disabled
- Notification time
- Adjustment/compensation values
- Selected session preference

---

## 🎨 User Interface

### Screens
1. **Home** – Session list with quick access
2. **Calendar** – Month/week view for marking attendance
3. **Statistics** – Attendance breakdown and percentage
4. **Planning (Test)** – Future attendance simulation
5. **Settings** – Notification and compensation settings

### Design Features
- **Dark Theme** – Optimized for battery and eye comfort
- **Responsive Layout** – Adapts to different screen sizes
- **Haptic Feedback** – Vibrations for user actions
- **Color Coding** – Green (present), Red (absent), Cyan (dates), Pink (weekends)

---

## ⚙️ Installation & Setup

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / Xcode (for emulator/device)

### For End Users
Download from **Google Play Store** (coming soon)

### For Development
This is a personal project under development. Source code access is limited to the developer.

**Internal Build Instructions** (for development only):
```bash
flutter pub get
flutter pub run build_runner build
flutter run
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  hive: ^2.x.x
  hive_flutter: ^1.x.x
  awesome_notifications: ^0.x.x
  shared_preferences: ^2.x.x
  collection: ^1.x.x
```

---

## 🚀 Future Enhancements

- [ ] Cloud backup and sync (Firebase)
- [ ] Export statistics to PDF/CSV
- [ ] Sharing sessions with classmates
- [ ] Predictive attendance analytics
- [ ] Dark/Light theme toggle
- [ ] Multi-language support
- [ ] iOS app release
- [ ] Web dashboard

---

## 📝 License

All rights reserved. © 2026 Attendance Manager. This application and its contents are proprietary and intended for commercial distribution on the Google Play Store.

---

## 💬 Feedback & Support

Have suggestions or found a bug? Contact us:
- Email: [priyanshartshakya@gmail.com]
- In-app feedback form (coming soon)

---

## 🙏 Credits

Built with ❤️ using Flutter and Dart.

---

**Happy Tracking! 📊✨**
