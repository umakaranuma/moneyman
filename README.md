# Finzo

A Flutter application for managing personal finances and taking notes, with all data stored locally using Hive.

## Features

- 💰 **Money Management**
  - Track income and expenses
  - View total balance, income, and expenses
  - Categorize transactions
  - Filter transactions by type
  - Add, edit, and delete transactions

- 📝 **Notes Management**
  - Create, edit, and delete notes
  - Color-coded notes
  - Quick access to recent notes

- 💾 **Local Storage**
  - All data stored locally using Hive
  - No backend or login required
  - Fast and efficient data access

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                  # Data models
│   ├── transaction.dart     # Transaction model
│   └── note.dart           # Note model
├── services/                # Business logic & data services
│   └── storage_service.dart # Hive storage service
├── screens/                 # UI screens
│   ├── home_screen.dart                    # Main dashboard
│   ├── transactions_screen.dart            # Transactions list
│   ├── add_edit_transaction_screen.dart    # Add/Edit transaction
│   ├── notes_screen.dart                   # Notes list
│   └── add_edit_note_screen.dart           # Add/Edit note
├── widgets/                 # Reusable widgets
│   ├── transaction_card.dart # Transaction card widget
│   └── note_card.dart       # Note card widget
├── utils/                   # Utilities & helpers
│   ├── constants.dart       # App constants
│   └── helpers.dart         # Helper functions
└── theme/                   # Theme configuration
    └── app_theme.dart       # App theme settings
```

## Getting Started

### Prerequisites

- Flutter SDK (3.10.4 or higher)
- Dart SDK

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

## Dependencies

- **hive**: ^2.2.3 - Fast, lightweight NoSQL database
- **hive_flutter**: ^1.1.0 - Flutter integration for Hive
- **intl**: ^0.19.0 - Internationalization and date formatting

## Usage

### Adding a Transaction

1. Tap the floating action button on the Transactions screen
2. Select Income or Expense
3. Enter title, amount, category, and date
4. Optionally add a description
5. Tap "Add" to save

### Adding a Note

1. Tap the floating action button on the Notes screen
2. Enter title and content
3. Select a color (optional)
4. Tap "Save Note" to save

### Viewing Statistics

The home screen displays:
- Total balance
- Total income
- Total expenses
- Recent transactions
- Recent notes

## Data Storage

All data is stored locally on the device using Hive. No internet connection or backend is required. Data persists across app restarts.

## License

This project is for personal use.
