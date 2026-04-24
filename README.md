# Personal Finance Tracker

A Flutter personal finance app for tracking expenses, managing budgets, monitoring savings goals, and viewing monthly spending insights through a clean dashboard.

## Overview

This project helps users build a simple personal finance workflow in one app:

- add, edit, and delete expenses
- organize spending by category
- set monthly income and budgets
- track savings goals and progress
- view dashboard insights and charts
- sign in locally with saved session support
- customize appearance with light/dark mode and color themes

The app uses local SQLite storage, BLoC state management, and a responsive Flutter UI that works across mobile, desktop, and web targets supported by Flutter.

## Screenshots

Add your screenshots inside:

```text
assets/screenshots/
```

Recommended file names:

- `auth.png`
- `home.png`
- `dashboard.png`
- `profile.png`

Then this section will work automatically:

| Authentication | Home |
|------|------|
| ![](assets/screenshots/auth.png) | ![](assets/screenshots/home.png) |

| Dashboard | Profile |
|-----------|---------|
| ![](assets/screenshots/dashboard.png) | ![](assets/screenshots/profile.png) |

## Features

### Expense Tracking

- Add expenses with amount, category, date, and note
- Edit existing expenses
- Delete expenses with undo feedback
- Browse expenses by selected month
- Move between historical months and the current month

### Budget Management

- Create overall or category-based budgets
- Set budget limits with active date ranges
- Track budget usage and remaining balance
- Monitor budget status with progress indicators

### Savings Goals

- Create savings goals with target amount and deadline
- Update saved amount over time
- View progress, remaining amount, and monthly saving pace

### Dashboard and Insights

- Monthly finance snapshot
- Spending by category pie chart
- Daily spending bar chart
- Smart insights based on spending patterns
- Income vs spending overview

### Authentication and Profile

- Local sign up / sign in flow
- Persistent session restore
- Profile settings with display name, photo path/URL, and preferred currency
- Password hashing with salt before local storage

### Themes and Appearance

- Light mode
- Dark mode
- System theme mode
- Multiple color palettes
- Responsive page widths for larger screens

## Tech Stack

- **Flutter**
- **Dart**
- **flutter_bloc** for state management
- **sqflite** for local database storage
- **fl_chart** for data visualization
- **google_fonts** for typography
- **font_awesome_flutter** for icons
- **crypto** for password hashing

## Project Structure

```text
lib/
  bloc/         # Auth, finance, and theme state logic
  data/         # SQLite database helper and auth repository
  models/       # App data models
  screens/      # Main app screens
  theme/        # Global theme configuration
  utils/        # Helpers and insight generation
  widgets/      # Reusable UI sections
```

## Getting Started

### Prerequisites

- Flutter SDK installed
- Dart SDK included with Flutter
- Android Studio, VS Code, or another Flutter-compatible IDE

### Installation

```bash
git clone https://github.com/your-username/your-repo.git
cd tracker
flutter pub get
```

### Run the App

```bash
flutter run
```

## Build Commands

### Android APK

```bash
flutter build apk
```

### Windows

```bash
flutter build windows
```

### Web

```bash
flutter build web
```

## Useful Development Commands

```bash
dart format lib
flutter analyze
flutter test
```

## Current Screens

- Authentication
- Overview / Home
- Dashboard
- Add Expense
- Manage Budgets
- Manage Savings Goals
- Profile
- Appearance Settings

## Notes

- Data is currently stored locally on the device using SQLite.
- Authentication is local to the app and not connected to a cloud backend.
- The project is structured so cloud sync, notifications, OCR, exports, and more advanced analytics can be added later.

## Future Improvements

- Cloud sync with Firebase or Supabase
- Real online authentication
- Notifications and reminders
- CSV/PDF export
- Receipt scanning and OCR
- Recurring transactions
- Multi-currency conversion
- More advanced analytics and reports

## Author

Built as a Flutter personal finance tracking project focused on clean UI, local persistence, and practical budgeting features.
